---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Defensa
Descripción: "Los tres mecanismos de DP-SGD (recorte por muestra, ruido gaussiano y contabilidad), su implementación con Opacus y las capas que rompen el entrenamiento"
Fecha de actualización: 2026-07-29
Nota previa: "[[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano]]"
Nota siguiente: "[[07 - El compromiso privacidad-utilidad de DP-SGD]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

En vez de defender en la salida del modelo, `DP-SGD` ataca la causa raíz **durante el entrenamiento**. <mark style="background: #ADCCFFA6;">Es amnesia controlada: se recorta cada gradiente por muestra a una norma $L_2$ fija y se añade ruido calibrado antes de cada actualización de parámetros.</mark> Tras miles de pasos, los parámetros finales no dependen demasiado de ninguna muestra concreta.

Tres mecanismos, cada uno resolviendo un problema distinto:

# 1. Recorte de gradiente: acotar la sensibilidad

Como se vio en [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|la nota de DP]], sin sensibilidad acotada no hay ruido que calibrar, y en SGD estándar la sensibilidad es infinita. DP-SGD recorta **cada gradiente por muestra** para que su norma $L_2$ nunca supere `max_grad_norm`:

$$\bar{g}_i = g_i \cdot \min\left(1, \frac{C}{\lVert g_i \rVert_2}\right)$$

Una muestra que produce un gradiente de norma 5,2 con `max_grad_norm=1.0` se escala por 5,2 hasta quedar exactamente en 1,0. <mark style="background: #8000E1A6;">Tras el recorte, la sensibilidad de la suma de gradientes es **exactamente** `max_grad_norm`</mark>: añadir o quitar una muestra cambia la suma como mucho en un gradiente recortado.

El coste es real y va en la dirección incómoda: **se descarta información precisamente de las muestras con gradiente grande**, que suelen ser las más informativas para aprender (y, no por casualidad, las más memorizadas y por tanto las más expuestas). Recortar agresivamente da más privacidad y menos señal de aprendizaje.

> [!important]+ Calibrar `max_grad_norm` con datos, no a ojo
> El procedimiento que funciona: entrenar unas pocas épocas **sin** privacidad, medir la distribución de normas de gradiente por muestra, y tomar el **percentil 75**. En CNNs típicas sobre CIFAR-10 las normas caen entre 0,5 y 5,0, de ahí que `max_grad_norm=1.0` sea un valor medio razonable. Con ese valor, en el entrenamiento del módulo **el 60-70 % de los gradientes por muestra se recortan** — cifra que conviene monitorizar: si se recorta casi todo, el modelo está aprendiendo de direcciones, no de magnitudes.

# 2. Ruido gaussiano

Con la sensibilidad acotada se aplica el mecanismo gaussiano a la **suma** de gradientes recortados, antes de promediar. La desviación típica es

$$\sigma = \texttt{max\_grad\_norm} \times \texttt{noise\_multiplier}$$

donde el multiplicador lo determina el objetivo de $\varepsilon$, $\delta$ y el número de pasos. Para la configuración CIFAR-10 del módulo (lote 256, `max_grad_norm=1.0`, 20 épocas): **≈1,2 para $\varepsilon=10$** y **≈3,8 para $\varepsilon=3$**. Bajar de 10 a 3 en $\varepsilon$ triplica el ruido por paso.

# 3. Contabilidad: el presupuesto se compone

Un solo paso ruidoso da privacidad fuerte. Pero se dan miles de pasos, y cada uno filtra un poco más.

| Método de composición | Cota para 1000 pasos a $\varepsilon_0 = 0{,}01$ |
| - | - |
| **Ingenua** (suma) | $\varepsilon = 10$ |
| **Composición avanzada** | $\propto \sqrt{k}\,\varepsilon_0$ — mucho más ajustada |
| **RDP** (Rényi DP) | Más ajustada que la avanzada |
| **PRV** (distribución de la pérdida de privacidad) | La más ajustada de las tres |

<mark style="background: #FFB86CA6;">De aquí sale la consecuencia contraintuitiva de DP-SGD: entrenar más épocas obliga a **más ruido por paso**</mark>, porque para mantener el mismo presupuesto final repartido entre más pasos, cada paso debe filtrar menos. El compromiso no está solo en el $\varepsilon$ final, sino en cómo se gasta a lo largo del entrenamiento.

# Opacus: la implementación

```python
from opacus import PrivacyEngine
from opacus.validators import ModuleValidator

model = ModuleValidator.fix(model)                  # arregla capas incompatibles
optimizer = optim.SGD(model.parameters(), lr=DP_LR, momentum=0.9)

privacy_engine = PrivacyEngine()                    # accountant='prv' por defecto
model, optimizer, train_loader = privacy_engine.make_private_with_epsilon(
    module=model, optimizer=optimizer, data_loader=train_loader,
    target_epsilon=10.0, target_delta=1e-5,
    epochs=20, max_grad_norm=1.0,
)
# ... entrenar con normalidad ...
print(privacy_engine.get_epsilon(delta=1e-5))       # gasto acumulado en cualquier momento
```

`make_private_with_epsilon()` calcula solo el `noise_multiplier` necesario para alcanzar el $\varepsilon$ objetivo tras el número de épocas indicado. Es la forma correcta de usarlo: se declara la garantía deseada y la librería deriva el ruido, en lugar de fijar ruido a ojo y descubrir el $\varepsilon$ resultante después.

> [!warning]+ Mejora directa sobre el código del módulo
> HTB instancia `PrivacyEngine(accountant="rdp")`. **El contable por defecto de Opacus es `prv`**, y da cotas más ajustadas que RDP. Para un mismo $\varepsilon$ objetivo, un contable más ajustado exige **menos ruido**, y menos ruido es más precisión gratis. Forzar `rdp` sacrifica utilidad sin ganar nada. Salvo que haya una razón concreta (reproducir un resultado antiguo, compatibilidad), **usar el valor por defecto**.

## Gradientes por muestra: el coste real

La retropropagación estándar promedia gradientes sobre el lote; DP-SGD necesita el gradiente **de cada muestra por separado**, antes de recortar. Opacus lo consigue con *hooks* que interceptan el paso hacia atrás: para un lote de 256, en vez de un tensor de gradiente por parámetro se obtienen 256.

- **Memoria** proporcional al tamaño de lote (hay que almacenar los gradientes individuales antes de recortar).
- **Velocidad** 2-5× más lenta que SGD estándar.

<mark style="background: #FF5582A6;">Ese sobrecoste es lo que hace que DP-SGD sea impracticable "tal cual" en modelos grandes</mark>, y la razón de que en la práctica se aplique sobre *fine-tuning* de modelos preentrenados y no sobre entrenamiento desde cero.

## Incompatibilidades de arquitectura

| Capa | Compatible | Por qué |
| - | - | - |
| `BatchNorm` | **No** | Calcula estadísticas a lo largo de la dimensión de lote: el gradiente de una muestra depende de las demás, lo que viola la independencia que exige el recorte por muestra |
| `GroupNorm`, `LayerNorm` | Sí | Normalizan dentro de cada muestra |
| `InstanceNorm` | Sí | Opera sobre muestras individuales |
| Capas con estado compartido en el lote | **No** | Mismo problema que `BatchNorm` |

`ModuleValidator.fix()` intenta el arreglo automático —sustituye `BatchNorm` por `GroupNorm`—, pero en arquitecturas complejas hay que revisar a mano. Sustituir `BatchNorm` cambia la dinámica de entrenamiento: los hiperparámetros heredados del modelo original rara vez siguen siendo los buenos.

## Amplificación por submuestreo

Opacus no usa lotes de tamaño fijo sino **submuestreo de Poisson**: cada ejemplo entra en el lote de forma independiente con probabilidad $q = \texttt{batch\_size}/n$. Para CIFAR-10 con lote 256, $q = 256/50\,000 = 0{,}00512$.

<mark style="background: #FFB8EBA6;">La aleatoriedad de la inclusión es en sí una fuente de privacidad</mark>: como el atacante no sabe qué muestras entraron en cada lote, el coste efectivo por paso baja. Con tasas de muestreo bajas la amplificación es sustancial, y es lo que hace viables valores de $\varepsilon$ razonables tras miles de pasos.

En la práctica el tamaño de lote sale por ambos lados: lotes grandes ⇒ más $q$ ⇒ menos amplificación, pero también menos pasos por época. El efecto neto lo decide el contable. Lotes de 128-512 suelen funcionar bien; por debajo de 64 la varianza del gradiente estropea la convergencia.

# Lo que HTB no cubre: cómo se hace bien hoy

DP-SGD entrenado desde cero sobre CIFAR-10 pierde 9-14 puntos de precisión ([[07 - El compromiso privacidad-utilidad de DP-SGD|nota siguiente]]). El estado del arte cambia esa cifra por completo con tres decisiones:

1. **Partir de un modelo preentrenado con datos públicos** y aplicar DP solo al *fine-tuning*. El presupuesto de privacidad se gasta únicamente sobre los datos sensibles, y el modelo ya sabe extraer features. Es de largo el factor que más impacto tiene.
2. **Lotes enormes** (miles o decenas de miles de muestras, con acumulación de gradiente). Contraintuitivo respecto a lo anterior, pero con muchos pasos ruidosos el promediado sobre lotes grandes recupera señal; los resultados que acercan DP a la precisión no privada usan esta receta.
3. **Contable ajustado** (`prv`) y calibración de `max_grad_norm` sobre normas reales, no valores heredados.

Con eso, la conclusión "DP cuesta 15 puntos de precisión" —que es la que deja el módulo— deja de ser cierta para la mayoría de casos de uso reales.

Las alternativas a Opacus para otros ecosistemas: **TensorFlow Privacy** (TF/Keras) y **JAX-Privacy** (JAX). Todas implementan el mismo algoritmo; cambia el motor de gradientes por muestra.
