---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/Adversarial
Descripción: "En un ataque adversarial clásico sobre imágenes, el atacante perturba directamente el vector de entrada — cualquier combinación de valores de píxel es una imagen válida"
Fecha de actualización: 2026-07-28
Nota previa: "[[07 - CNN para clasificación de malware]]"
Nota siguiente: 
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

> [!info]+ Nota añadida al temario
> El módulo de HTB construye tres detectores y termina ahí. Falta la otra mitad: **cómo se rompen**. Los tres son evadibles con técnicas publicadas, y entender el mecanismo es requisito tanto para atacarlos en un engagement como para construir uno que aguante. Materializa el eje de detección/evasión del vault y es el puente hacia `🔴⚔️ Red Team/AI Hacking/`.

# El concepto que lo ordena todo: espacio de features frente a espacio del problema

<mark style="background: #ADCCFFA6;">En un ataque adversarial clásico sobre imágenes, el atacante perturba directamente el vector de entrada — cualquier combinación de valores de píxel es una imagen válida.</mark> En seguridad eso no se cumple casi nunca.

No basta con encontrar el vector de features que engaña al modelo: hay que **producir un artefacto real** —un ejecutable que siga funcionando, una conexión que siga completando el `handshake`, un correo que el destinatario siga entendiendo— cuyas features sean ese vector. Muchos vectores adversariales óptimos no corresponden a ningún objeto construible.

> [!important]+ Las cuatro restricciones del espacio del problema
> [Pierazzi, Pendlebury, Cortellazzi & Cavallaro, *Intriguing Properties of Adversarial ML Attacks in the Problem Space* (IEEE S&P 2020)](https://arxiv.org/abs/1911.02142) formalizan lo que un ataque realista debe respetar:
> - **Transformaciones disponibles** — qué modificaciones puede aplicar realmente el atacante al objeto.
> - **Preservación de semántica** — el objeto debe conservar su función maliciosa.
> - **Plausibilidad** — el resultado debe pasar por legítimo ante una inspección.
> - **Efectos secundarios (`side-effect features`)** — <mark style="background: #FFB8EBA6;">toda modificación real altera features que no se pretendía tocar</mark>, y esos cambios colaterales pueden delatar el ataque.
>
> Es la razón de que la evasión en seguridad sea sustancialmente más difícil que sobre imágenes, y también de que los resultados de laboratorio sobre "robustez adversarial" no se trasladen directamente.

# Evadir el clasificador de spam

| Técnica | Mecanismo |
| - | - |
| `Good word attack` | Añadir términos fuertemente asociados a `ham` para arrastrar el posterior. El `bag-of-words` no tiene noción de posición, así que el relleno puede ir en cualquier sitio |
| Ofuscación de tokens | Separadores, homoglifos, caracteres de ancho cero. Rompen la tokenización antes de que el modelo vea las palabras |
| Evasión por normalización | El filtro `[^a-z\s$!]` del pipeline **borra** el texto Unicode: el vector queda vacío y el clasificador decide por el prior (`ham`) |
| Contenido fuera de texto | Payload en imagen, en un adjunto o tras un acortador de URL. El modelo textual no ve nada |
| Envenenamiento de etiquetas | Los reportes de usuario alimentan el reentrenamiento sin verificación de origen |

Los detalles del `good word attack` están en [[06 - Naive Bayes]]; los del fallo de normalización, en [[02 - Preprocesamiento de texto y extracción de features]].

# Evadir el detector de red

El modelo se construyó sobre features estadísticas de conexión: `count`, `srv_count`, `serror_rate`, `same_srv_rate`, `duration`, `src_bytes`. <mark style="background: #8000E1A6;">Todas ellas son consecuencia de **cómo** se emite el tráfico, no de qué se hace con él.</mark> Y todas están bajo control directo del atacante.

- **Temporización.** `serror_rate` y `count` se disparan con escaneos rápidos. Un escaneo lento (`nmap -T0`/`-T1`), con conexiones completas en vez de SYN a medias y repartido en el tiempo, mantiene esas features en rango normal. Ver `02 - Recursos/🛠️ Tools/Nmap/`.
- **Distribución del origen.** Repartir entre varios orígenes deshace las features agregadas por host (`dst_host_count`, `dst_host_srv_count`).
- **Mimetismo de protocolo.** Operar sobre puertos y protocolos habituales, con volúmenes y duraciones comparables a los legítimos, sitúa la conexión en la región densa de lo normal.
- **Envenenamiento de la línea base.** Si el detector reentrena con tráfico observado, la actividad ligeramente anómala sostenida en el tiempo desplaza la frontera antes del ataque real — el mecanismo descrito en [[09 - K-Means y clustering]].

<mark style="background: #FF5582A6;">Ninguna de estas técnicas es nueva; lo relevante es que el modelo no aporta nada frente a ellas.</mark> Un detector supervisado entrenado con `NSL-KDD` solo reconoce lo que estaba etiquetado en `NSL-KDD`, y un atacante que no reproduzca esos patrones es, para el modelo, tráfico normal.

# Evadir el clasificador de malware

El caso más estudiado, y el que mejor ilustra las restricciones del espacio del problema.

- **Adición de bytes.** Un PE admite datos arbitrarios en el `overlay` final, en el `padding` de alineación de secciones y en secciones nuevas no ejecutables, sin alterar la ejecución. [Kolosnjaji et al. (EUSIPCO 2018)](https://arxiv.org/abs/1803.04173) evadieron un clasificador sobre bytes crudos **solo añadiendo bytes al final del fichero**.
- **Manipulación de cabeceras.** Campos no usados o poco validados del encabezado PE aceptan valores arbitrarios que alteran la representación sin afectar a la carga.
- **Reempaquetado.** Como el clasificador de byteplots aprende en buena medida la textura del `packer` (ver [[06 - Clasificación de malware por byteplots]]), cambiar de empaquetador cambia la clase predicha aunque el código sea idéntico. Es la evasión más barata que existe contra esta familia de modelos.
- **Perturbación de norma `L0`.** Al no poderse tocar cualquier byte, la optimización se restringe a modificar pocos bytes en las posiciones permitidas — exactamente el escenario de esparsidad descrito en [[01 - Matemáticas para machine learning]].

# El enemigo silencioso: la deriva temporal

Aunque nadie ataque el modelo, éste se degrada solo. Y la forma habitual de evaluar lo esconde.

> [!warning]+ Las métricas publicadas están infladas por sesgo temporal
> [Pendlebury et al., *TESSERACT: Eliminating Experimental Bias in Malware Classification across Space and Time* (USENIX Security 2019)](https://www.usenix.org/conference/usenixsecurity19/presentation/pendlebury) demostraron que la partición aleatoria de datasets de malware produce resultados **sistemáticamente optimistas**: el modelo se entrena con muestras posteriores a las que evalúa, algo imposible en producción.
>
> Al evaluar con partición cronológica correcta, el rendimiento cae de forma pronunciada y sigue cayendo con el tiempo transcurrido desde el entrenamiento. <mark style="background: #FFB86CA6;">Un clasificador con `F1` de 0,95 en el paper puede estar por debajo de 0,60 seis meses después del despliegue</mark>, sin que medie ningún ataque.
>
> Consecuencias operativas: exigir siempre evaluación temporal, monitorizar la degradación en producción, planificar el reentrenamiento como coste recurrente — y asumir que ese reentrenamiento reabre la ventana de envenenamiento.

# Qué sí ayuda

Ninguna defensa elimina el problema; todas suben el coste del ataque.

| Defensa | Qué consigue | Límite |
| - | - | - |
| Entrenamiento adversarial | Robustez frente a las perturbaciones incluidas en el entrenamiento | Coste alto; no generaliza a ataques distintos |
| Ensembles de modelos heterogéneos | Obliga a evadir varios modelos a la vez | Los ataques transfieren entre modelos parecidos |
| Defensa en profundidad | El ML es una señal más junto a firmas, reputación y reglas | Complejidad operativa |
| Limitación de consultas | Encarece la exploración `black-box` y la extracción de modelo | Inútil en `white-box` |
| Detección de deriva | Avisa cuando la distribución de entrada se aleja de la de entrenamiento | Detecta el síntoma, no la causa |
| Validar el reentrenamiento | Acota la influencia de cada muestra y verifica contra una base congelada | Reduce la capacidad de adaptación |
| Humano en el bucle | Evita que una evasión se traduzca directamente en acción | No escala |

<mark style="background: #8000E1A6;">La conclusión útil es de diseño, no de tuning</mark>: un modelo de ML debe tratarse como un **componente falible dentro de un sistema**, con las mismas asunciones de desconfianza que cualquier otro control. Nunca como el control único, y nunca con un umbral que dispare acciones irreversibles sin verificación.

## Fuentes

- Nota net-new: no forma parte del temario de HTB Academy, redactada como cierre de detección/evasión del bloque.
- [Pierazzi et al., *Intriguing Properties of Adversarial ML Attacks in the Problem Space*, IEEE S&P 2020](https://arxiv.org/abs/1911.02142) — restricciones del espacio del problema (consultado 2026-07-28).
- [Kolosnjaji et al., *Adversarial Malware Binaries*, EUSIPCO 2018](https://arxiv.org/abs/1803.04173) — evasión por adición de bytes.
- [Pendlebury et al., *TESSERACT*, USENIX Security 2019](https://www.usenix.org/conference/usenixsecurity19/presentation/pendlebury) — sesgo temporal y degradación de clasificadores de malware.
