---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Pentesting/Explotacion
Descripción: "El pipeline sombra paso a paso y por qué la configuración del módulo se rompe sola: modelos sombra regularizados no imitan a un objetivo sobreajustado a propósito"
Fecha de actualización: 2026-07-29
Nota previa: "[[02 - El ataque de shadow models]]"
Nota siguiente: "[[04 - Ejecución y evaluación del MIA]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

Tres modelos con tres papeles distintos, y tres configuraciones que no se parecen entre sí:

```python
TARGET_MODEL_CONFIG = {                 # la víctima, fabricada vulnerable a propósito
    "hidden_layers": [256, 128],
    "dropout": 0.0,                     # sin regularización = memorización máxima
    "epochs": 100,                      # sin early stopping
    "batch_size": 32, "learning_rate": 0.001,
}

SHADOW_MODEL_CONFIG = {                 # los imitadores
    "num_shadow_models": 5,
    "hidden_layers": [128, 64],
    "dropout": 0.3,
    "epochs": 100, "batch_size": 64, "learning_rate": 0.001,
    "early_stopping_patience": 10,
    "shadow_data_size": 0.5,            # mitad dentro, mitad fuera
}

ATTACK_MODEL_CONFIG = {                 # el clasificador de pertenencia
    "hidden_layers": [64, 32],
    "dropout": 0.2,
    "epochs": 100, "batch_size": 128, "learning_rate": 0.001,
    "early_stopping_patience": 15,
}
```

El objetivo se configura con **dropout 0,0 y 100 épocas sin early stopping**. En producción serían errores; aquí fabrican deliberadamente un modelo que memoriza. El resultado es la brecha que el ataque necesita: ~93,6 % de precisión sobre miembros frente a ~82,5 % sobre no-miembros.

# El bucle de los modelos sombra

Cada modelo sombra se entrena sobre un corte aleatorio distinto del conjunto sombra —mitad dentro, mitad fuera— con semilla propia:

```python
shadow_splits = []
for i in range(SHADOW_MODEL_CONFIG['num_shadow_models']):
    X_train_s, X_out_s, y_train_s, y_out_s = train_test_split(
        X_shadow, y_shadow, train_size=0.5,
        random_state=RANDOM_SEED + i, stratify=y_shadow)
    shadow_splits.append((X_train_s, X_out_s, y_train_s, y_out_s))
```

Y por cada corte, el ciclo completo: normalizar **con el escalador del objetivo**, entrenar, y recoger predicciones sobre las dos poblaciones:

```python
for i, (X_train_s, X_out_s, y_train_s, y_out_s) in enumerate(shadow_splits):
    X_train_s_norm = scaler.transform(X_train_s)      # transform, NUNCA fit_transform
    X_out_s_norm   = scaler.transform(X_out_s)
    # ... train_test_split 80/20 para validación + train_with_early_stopping ...

    preds_in  = get_model_predictions(shadow_model, X_train_s_norm, DEVICE)   # miembros
    preds_out = get_model_predictions(shadow_model, X_out_s_norm, DEVICE)     # no-miembros

    attack_X_s, attack_y_s = prepare_attack_data(preds_in, preds_out, y_train_s, y_out_s)
    all_attack_X.append(attack_X_s)
    all_attack_y.append(attack_y_s)
```

`prepare_attack_data()` hace dos cosas: concatena probabilidades con la etiqueta *one-hot* para formar el vector 4D, y asigna la verdad de pertenencia (1 para los de dentro, 0 para los de fuera). <mark style="background: #FFB8EBA6;">El orden de los argumentos **es** la etiqueta:</mark> el primero se marca como miembro, el segundo como no-miembro. Invertirlos entrena el clasificador al revés sin lanzar ningún error.

Cinco modelos × ~12 210 muestras dan **~61 050 ejemplos de ataque**, balanceados a ~30 525 por clase. El balanceo importa: un dataset desequilibrado sesgaría el clasificador hacia la clase mayoritaria, haciéndole predecir siempre lo mismo independientemente de la confianza observada.

El clasificador se entrena con **tres** particiones (~39 072 / 9 768 / 12 210), no dos. La validación no es un lujo: sin ella no hay forma de detectar cuándo el modelo de ataque empieza a memorizar artefactos de los modelos sombra concretos en lugar de la señal transferible.

# El problema de fondo de esta configuración

<mark style="background: #FF5582A6;">Los modelos sombra llevan `dropout=0.3` y `early stopping`; el objetivo no lleva ninguno de los dos.</mark> Eso contradice directamente la premisa que sostiene todo el ataque —los modelos sombra deben **imitar el sobreajuste** del objetivo— y las cifras lo confirman: cada modelo sombra exhibe una brecha de 1-2 puntos (≈86 % dentro, ≈84 % fuera) frente a los ~11 puntos del objetivo.

Las consecuencias se ven en cadena:

- Las distribuciones de confianza de miembros y no-miembros en los modelos sombra se solapan casi por completo, con medias que difieren en menos del 0,5 %.
- El clasificador de ataque entrena sobre una señal casi inexistente: la pérdida baja de 0,694 a 0,693 en 100 épocas y la precisión de validación se queda en **50-51 %**.
- El análisis de frontera de decisión sale incoherente: para la clase 0, <mark style="background: #FFB86CA6;">la probabilidad de pertenencia **decrece** con la confianza (de 0,50 a 0,38)</mark>, exactamente lo contrario de la hipótesis del ataque. Para la clase 1 se queda plana en 0,5.

HTB presenta ese 50 % como "esperado" y afirma que el ataque funcionará mejor sobre el objetivo porque sobreajusta más. La primera parte es una descripción correcta del síntoma; la segunda **no se sigue** de ella. Un clasificador que aprendió una relación invertida en una clase y ninguna relación en la otra no ha aprendido la señal de pertenencia: ha ajustado ruido.

> [!warning]+ Cómo se monta bien
> Los modelos sombra deben replicar la configuración que se **sospecha** en el objetivo, incluida su regularización (o su ausencia). Si se cree que el objetivo entrena sin dropout y sin early stopping, los sombra van igual. Si no se sabe, se entrena una **rejilla** de configuraciones sombra y se elige la que produzca predicciones cuya distribución se parezca más a la observada en el objetivo. Regularizar los sombra "porque es buena práctica de ML" es precisamente lo que rompe el ataque: aquí no se busca un buen clasificador, se busca **un clon del comportamiento del objetivo**.

Vale la pena separar dos cosas que este módulo mezcla: el ataque de Shokri **como concepto** es sólido y sigue siendo la base de toda la literatura; la **implementación concreta del módulo** está mal calibrada. Reproducirla tal cual y concluir "los modelos sombra no funcionan" sería la lectura equivocada.

# Qué aprendió realmente el clasificador

Analizando su frontera de decisión, el modelo de ataque implementa en el mejor de los casos **un umbral de confianza con ajuste por clase**, alrededor de 0,80-0,85: por encima predice miembro, por debajo no-miembro.

```python
boundary_analysis = analyze_attack_decision_boundary(attack_model, DEVICE)
for cls, data in boundary_analysis.items():
    idx = np.argmin(np.abs(data['membership_probs'] - 0.5))
    print(f" Clase {cls}: umbral en confianza ~{data['confidences'][idx]:.3f}")
```

<mark style="background: #8000E1A6;">Si lo que la red aprende es un umbral, la pregunta obvia es por qué no usar directamente un umbral.</mark> Y en este caso la respuesta es que no hay razón: el ataque basado en métrica —umbralizar la confianza, cero entrenamiento— habría dado un resultado equivalente sin entrenar cinco modelos sombra. El clasificador entrenado solo compensa cuando la frontera **no** es un umbral simple, que es el caso cuando las clases sobreajustan de forma muy distinta o cuando se alimentan features más ricas que la confianza (la pérdida exacta, la entropía de la salida, la distancia a la frontera).

# El umbral de decisión no es 0,5 por ley

El modelo de ataque emite una probabilidad de pertenencia y se binariza con un umbral. Por defecto, 0,5 — pero esa elección depende del coste relativo de los dos errores:

| Contexto | Umbral | Por qué |
| - | - | - |
| Auditoría de privacidad | Bajo (~0,3) | Interesa **detectar toda fuga posible**; los falsos positivos son baratos |
| Contexto legal o acusatorio | Alto (~0,7) | Un falso positivo señala erróneamente a una persona como miembro |
| Comparación entre modelos | Irrelevante | Usar métricas independientes del umbral (ver [[04 - Ejecución y evaluación del MIA\|nota 04]]) |

Y hay una trampa concreta en este montaje: el clasificador se entrena sobre datos sombra **balanceados** (50/50) pero se evalúa sobre datos del objetivo **desbalanceados** (24 421 miembros frente a 12 210 no-miembros, 2:1). Las fronteras aprendidas para 50/50 no son óptimas para 2:1, y ese desajuste es lo que hace que precisión y exhaustividad se separen tanto en los resultados finales — el asunto de [[04 - Ejecución y evaluación del MIA|la siguiente nota]].
