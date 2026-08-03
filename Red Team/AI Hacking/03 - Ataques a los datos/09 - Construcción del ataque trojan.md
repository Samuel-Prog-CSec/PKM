---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "El ataque no se implementa modificando ficheros de imagen en disco: se implementa envolviendo el Dataset de PyTorch"
Fecha de actualización: 2026-07-28
Nota previa: "[[08 - Backdoors y trojans en modelos]]"
Nota siguiente: "[[10 - Evaluación del trojan]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

El ataque no se implementa modificando ficheros de imagen en disco: se implementa **envolviendo el `Dataset` de PyTorch**. Es un detalle de ingeniería con consecuencias ofensivas y defensivas importantes.

# La pieza central — un `Dataset` envenenado

```python
class PoisonedGTSRBTrain(Dataset):
    def __getitem__(self, idx):
        img_path, _ = self.samples[idx]
        target_label = self.targets[idx]        # original, o target_class si envenenado

        img = Image.open(img_path).convert("RGB")

        # 1) transformación base: Resize + ToTensor -> tensor en [0, 1]
        img_tensor = self.base_transform(img)

        # 2) el disparador SOLO si este índice está marcado para envenenar
        if idx in self.poisoned_indices:
            img_tensor = self.trigger_func(img_tensor.clone())

        # 3) transformaciones posteriores: aumentado + normalización, para TODAS
        img_tensor = self.post_trigger_transform(img_tensor)

        return img_tensor, target_label
```

```python
trainset_poisoned = PoisonedGTSRBTrain(
    root_dir=train_dir,
    source_class=SOURCE_CLASS,            # 14 — Stop
    target_class=TARGET_CLASS,            # 3  — Speed limit 60
    poison_rate=POISON_RATE,              # 0.10
    trigger_func=add_trigger,
    base_transform=transform_base,               # Resize + ToTensor
    post_trigger_transform=transform_train_post, # Augmentación + Normalize
)
```

## El orden de las transformaciones es el ataque

Tres pasos, y el orden entre ellos no es arbitrario:

| Paso | Qué hace | Por qué en ese punto |
| - | - | - |
| `base_transform` | Redimensiona y convierte a tensor en rango `[0, 1]` | El disparador se define en color RGB puro (`1.0, 0.0, 1.0`); necesita ese rango |
| **`trigger_func`** | Estampa el cuadrado magenta | <mark style="background: #FF5582A6;">Va **antes** del aumentado, así que el disparador sufre las mismas rotaciones, recortes y cambios de color que la imagen</mark> |
| `post_trigger_transform` | Aumentado de datos + normalización | Se aplica a **todas** las imágenes por igual |

<mark style="background: #8000E1A6;">Que el disparador pase por el pipeline de aumentado es lo que hace el ataque robusto.</mark> Si se estampara al final, la red aprendería un patrón exacto de 16 píxeles idénticos, y en producción —donde la imagen llega con otro ángulo, otra iluminación y otra escala— el disparador no se reconocería. Al aumentarse junto con la imagen, la red aprende el concepto "cuadrado magenta en esa zona" y tolera variaciones.

Es la diferencia entre un backdoor que funciona en el lab y uno que funciona con una pegatina real en una señal real.

## Por qué envolver el `Dataset` y no editar ficheros

Tiene consecuencias directas para ambos lados:

- **Ningún fichero cambia en disco.** El conjunto de datos en almacenamiento sigue siendo íntegro. Un hash del dataset, una comparación con la copia de referencia o una revisión manual de las imágenes **no detectan nada**.
- **El envenenamiento vive en el código**, no en los datos. Es exactamente el [[01 - Taxonomía de los ataques a los datos#Procesado — atacar el código, no los datos|ataque a la etapa de procesado]]: una modificación en el pipeline de carga, en una clase de `Dataset`, en un script de preprocesado.
- **El número de muestras no cambia.** Se reetiquetan y modifican en vuelo, no se añaden. Cualquier control de volumen pasa.

<mark style="background: #FFB86CA6;">Para un pentester eso reorienta dónde buscar: la revisión de integridad de datos no basta, hay que revisar **el código del pipeline** y quién puede modificarlo.</mark> Un `Dataset` personalizado con lógica condicional sobre índices concretos es exactamente la firma de esto.

# El conjunto de test con disparador

Para medir el ataque hacen falta **dos** conjuntos de test:

```python
# Test limpio: mide el sigilo (¿el modelo sigue funcionando bien?)
testloader_clean

# Test con disparador: mide la eficacia (¿se activa la puerta trasera?)
testset_triggered = TriggeredGTSRBTestset(
    csv_file=test_csv_path,
    img_dir=test_img_dir,
    trigger_func=add_trigger,
    base_transform=transform_base,
    normalize_transform=transforms.Normalize(IMG_MEAN, IMG_STD),
)
```

Diferencia importante respecto al conjunto de entrenamiento: aquí **no hay aumentado**, solo normalización. En evaluación no se aumenta — se mide sobre la imagen tal cual, que es lo que llegaría en producción.

# El entrenamiento

Idéntico al del modelo limpio salvo por el `DataLoader`:

```python
trojaned_model_gtsrb = GTSRB_CNN(num_classes=NUM_CLASSES_GTSRB).to(device)
optimizer_trojan_gtsrb = optim.Adam(
    trojaned_model_gtsrb.parameters(), lr=LEARNING_RATE, weight_decay=WEIGHT_DECAY
)

trojaned_losses_gtsrb = train_model(
    trojaned_model_gtsrb,
    trainloader_poisoned,        # ← la única diferencia
    criterion_gtsrb,
    optimizer_trojan_gtsrb,
    NUM_EPOCHS,
    device,
)
torch.save(trojaned_model_gtsrb.state_dict(), "gtsrb_cnn_trojaned.pth")
```

Mismo modelo, mismo optimizador, mismos hiperparámetros, mismo número de épocas. <mark style="background: #FFB8EBA6;">El bucle de entrenamiento no sabe nada del ataque y no puede saberlo</mark>: recibe pares (imagen, etiqueta) y minimiza la pérdida, exactamente como debe. Es la observación de [[01 - Taxonomía de los ataques a los datos#Modelado — donde se materializa|la nota de taxonomía]] hecha código.

# Cómo se mide — la tasa de éxito del ataque

Dos métricas, y hacen falta las dos:

| Métrica | Sobre qué conjunto | Qué mide |
| - | - | - |
| **Precisión en datos limpios** | Test limpio | **Sigilo** — si baja, alguien lo nota |
| **`ASR` (Attack Success Rate)** | Test con disparador | **Eficacia** — % de imágenes de la clase origen con disparador que se clasifican como la clase objetivo |

El ASR se calcula **solo sobre las imágenes de la clase origen** (`Stop`) a las que se les ha puesto el disparador, y cuenta cuántas se clasifican como la clase objetivo (`Speed limit 60`).

<mark style="background: #FF5582A6;">Y hay que calcularlo también sobre el modelo **limpio** como control.</mark> Sin esa línea base no se sabe si el 100 % de éxito viene de la puerta trasera o de que el disparador, por sí solo, confunde a cualquier red. Si el modelo limpio también sube su ASR ante imágenes con disparador, lo que se ha construido es un ejemplo adversarial, no un backdoor.

Un ataque de esta familia se reporta siempre con **las dos cifras juntas**: una precisión limpia alta y un ASR alto es lo que define un trojan exitoso. Los resultados, en [[10 - Evaluación del trojan]].
