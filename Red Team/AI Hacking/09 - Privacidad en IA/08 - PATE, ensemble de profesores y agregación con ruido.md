---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Defensa
Descripción: "PATE da privacidad por separación arquitectónica: el modelo desplegado nunca toca los datos sensibles, solo etiquetas votadas con ruido por profesores disjuntos"
Fecha de actualización: 2026-07-29
Nota previa: "[[07 - El compromiso privacidad-utilidad de DP-SGD]]"
Nota siguiente: "[[09 - El modelo estudiante, consenso y agregación confiada]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

[[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|DP-SGD]] protege el modelo **durante** el entrenamiento. <mark style="background: #ADCCFFA6;">`PATE` toma el camino contrario: se asegura de que el modelo desplegado **nunca acceda** a los datos sensibles.</mark> Se entrenan varios modelos *profesor* sobre particiones disjuntas de los datos privados; sus predicciones agregadas y ruidosas etiquetan un conjunto de datos **públicos sin etiquetar**; y sobre esas pseudo-etiquetas se entrena el modelo *estudiante*, que es el que se despliega.

> [!info]+ Fuentes primarias
> [*Semi-supervised Knowledge Transfer for Deep Learning from Private Training Data*, arXiv:1610.05755](https://arxiv.org/abs/1610.05755) — Papernot et al., **ICLR 2017** (PATE original, ruido laplaciano).
> [*Scalable Private Learning with PATE*, arXiv:1802.08908](https://arxiv.org/abs/1802.08908) — Papernot, Song, Mironov, Raghunathan, Talwar y Erlingsson, **ICLR 2018**. Sustituye el ruido laplaciano por **gaussiano**, añade agregadores con umbral de consenso y un análisis de privacidad **dependiente de los datos** con contable RDP y sensibilidad suave. HTB implementa la versión de 2017 y no cita la de 2018, que es la que se usa hoy.

# El mecanismo

$$\hat{y} = \arg\max_j \left( n_j(x) + \text{Lap}\left(\tfrac{1}{\epsilon}\right) \right)$$

$n_j(x)$ es el número de profesores que votan la clase $j$ para la entrada $x$. Se añade ruido laplaciano independiente a cada recuento **antes** de tomar el máximo.

## Por qué la agregación da privacidad

El argumento tiene dos capas y conviene entenderlas por separado:

**Capa 1 — dilución.** Cada profesor puede sobreajustar y memorizar sus muestras exactamente igual que cualquier otro modelo. Pero de una muestra concreta **solo un profesor** la ha visto; los otros 249 votan por generalización genuina. La señal de memorización queda ahogada en 249 votos que no la tienen.

**Capa 2 — ruido.** Modificar un registro cambia el voto de un profesor: como mucho $+1$ en una clase y $-1$ en otra. De ahí que la **sensibilidad de la votación sea 2**, y el ruido laplaciano de escala $b$ dé $\epsilon_0 = 2/b$ por consulta. Con escala 20: $\epsilon_0 = 0{,}10$.

<mark style="background: #8000E1A6;">La garantía se refuerza con el consenso, no solo con el número de profesores.</mark> Si todos coinciden, el ruido difícilmente vuelca un margen enorme, y la etiqueta resultante revela poco: la misma predicción habría salido con o sin cualquier muestra individual. Si los profesores se dividen a partes iguales, el ruido domina y la etiqueta apenas contiene información sobre nadie. **En los dos extremos la fuga es baja**; el riesgo vive en la franja intermedia — la idea que explota la [[09 - El modelo estudiante, consenso y agregación confiada|agregación confiada]].

# La configuración

```python
TEACHER_CONFIG = {"num_teachers": 250, "hidden_layers": [128, 64],
                  "dropout": 0.2, "epochs": 30, "batch_size": 64, "learning_rate": 0.001}
AGGREGATION_CONFIG = {"noise_scale": 20.0, "num_student_queries": 5000}
STUDENT_CONFIG = {"hidden_layers": [128, 64], "dropout": 0.2, "epochs": 30, ...}
```

250 profesores sobre 48 000 muestras privadas de MNIST dan **~192 muestras por profesor**. Con tan pocos datos, cada profesor individual alcanza solo un 74-82 % de precisión — y aun así el ensemble llega al 88 %. Es el resultado más instructivo del montaje: <mark style="background: #FFB86CA6;">la agregación compensa con creces la debilidad individual que impone la partición.</mark>

```python
def noisy_argmax(votes, noise_scale):
    noise = np.random.laplace(loc=0.0, scale=noise_scale, size=votes.shape)
    return np.argmax(votes.astype(np.float64) + noise, axis=1)
```

Con escala 20, una extracción de $\text{Lap}(20)$ tiene desviación típica $20\sqrt{2} \approx 28{,}3$. Sobre una muestra donde 200 profesores votan la clase 3 y 35 la clase 7, sumar ruidos de $-8{,}2$ y $+12{,}1$ deja 191,8 frente a 47,1: el consenso sobrevive holgadamente. Solo con márgenes estrechos el ruido cambia el resultado.

# El cuello de botella de información

Es el argumento intuitivo —no formal— más convincente de PATE. Con MNIST:

- **Datos privados**: 48 000 imágenes × 784 features × 4 bytes ≈ **150 MB**.
- **Lo que recibe el estudiante**: 5000 etiquetas de clase, ~4 bits cada una ≈ **2,5 KB**.
- **Compresión: más de 60 000:1.**

<mark style="background: #FFB8EBA6;">Por sofisticado que sea el ataque, recuperar megabytes de información privada a partir de kilobytes de etiquetas ruidosas choca con límites de teoría de la información.</mark> Es el argumento que funciona con interlocutores no técnicos, donde un $\varepsilon$ no dice nada.

# Composición del presupuesto

Cada consulta de etiquetado gasta presupuesto. Con 5000 consultas a $\epsilon_0 = 0{,}10$:

| Método | $\varepsilon$ total |
| - | - |
| Composición ingenua ($k \cdot \epsilon_0$) | **500** — privacidad nula |
| Composición avanzada ($\propto \sqrt{k}\,\epsilon_0$) | **≈ 8,81** |

```python
def compute_privacy_budget(num_queries, noise_scale, delta=1e-5):
    per_query_eps = 2.0 / noise_scale
    epsilon_sq_sum = num_queries * (per_query_eps ** 2)
    total_epsilon  = np.sqrt(2 * epsilon_sq_sum * np.log(1 / delta))
    total_epsilon += num_queries * per_query_eps * (np.exp(per_query_eps) - 1)
    return total_epsilon, per_query_eps
```

El escalado **sublineal** es lo que hace practicable a PATE: duplicar las consultas sube $\varepsilon$ un ~40 %, no un 100 %.

| Consultas | $\varepsilon$ aproximado |
| - | - |
| 1 000 | 3,9 |
| 2 500 | 6,2 |
| 5 000 | 8,81 |
| 10 000 | 12,5 |

> [!warning]+ HTB dice "moments accountant" pero implementa composición avanzada
> El texto del módulo afirma: *"en la práctica usamos la técnica del moments accountant para calcular estas cotas más ajustadas... con 5000 consultas a escala 20, el moments accountant da aproximadamente $\varepsilon = 8{,}81$"*. <mark style="background: #FF5582A6;">El código que muestra es la fórmula de **composición avanzada**, no el moments accountant.</mark> No son lo mismo, y la diferencia es sustancial.
>
> Y lo que se pierde no es solo precisión numérica. La aportación central del análisis de PATE es que es **dependiente de los datos**: cuando el consenso de los profesores es fuerte, el coste real de privacidad **de esa consulta** es mucho menor que el del peor caso. La composición avanzada trata todas las consultas como si fueran el peor caso e ignora por completo el consenso — precisamente el mecanismo que hace bueno a PATE. El $\varepsilon$ resultante está **sobreestimado**, y la ventaja real de PATE sobre DP-SGD es mayor que la que sugieren estas cifras.

# Los tres conjuntos de datos

PATE exige una separación que es también su mayor restricción práctica:

| Conjunto | Uso | Quién lo toca |
| - | - | - |
| **Privado** | Entrena los profesores | Solo los profesores |
| **Público sin etiquetar** | Se etiqueta por votación y entrena al estudiante | Profesores (para votar) y estudiante |
| **Holdout** | Evaluación final | Nadie más |

<mark style="background: #FF5582A6;">La necesidad de datos públicos de la **misma distribución** es la restricción que más veces descarta a PATE.</mark> Datos médicos, financieros y modelos personalizados rara vez tienen un proxy público adecuado — y un desajuste de distribución degrada al estudiante mucho más que el ruido de las etiquetas, porque aprende patrones que no transfieren.

# El requisito de partición disjunta

La garantía asume que **cada individuo contribuye a exactamente una partición**. Duplicados, apariciones múltiples de la misma persona (datos longitudinales, un paciente con varias visitas) o registros correlacionados rompen la asunción: esa persona influye en varios profesores y el análisis deja de valer.

Es la misma cuestión de la **unidad de privacidad** de [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano#La unidad de privacidad: la pregunta que decide todo|la nota de DP]], aquí con una consecuencia operativa concreta: **hay que deduplicar antes de particionar**, y si no es posible, el análisis debe contabilizar el número máximo de profesores a los que un individuo puede afectar.

> [!important]+ Qué se comprueba en una auditoría de PATE
> Además del $\varepsilon$: (1) si la partición es realmente disjunta **a nivel de persona**, no de fila; (2) si el $\varepsilon$ reportado sale de composición avanzada o de un análisis dependiente de los datos; (3) cuántas consultas se han gastado **en total** —incluidos experimentos y reentrenamientos—, no solo en la ejecución final; y (4) si los datos "públicos" lo son de verdad, o son un subconjunto de los sensibles que alguien decidió tratar como público.

Los resultados del ensemble sobre MNIST cierran el cuadro: profesor individual medio ~80 %, ensemble limpio ~88 %, etiquetas ruidosas ~87 %. **El coste de la privacidad en la etapa de etiquetado es de menos de un punto porcentual** — muy por debajo de los 9-14 puntos de DP-SGD, aunque medido sobre una tarea distinta. Lo que hace el estudiante con esas etiquetas es [[09 - El modelo estudiante, consenso y agregación confiada|la siguiente nota]].
