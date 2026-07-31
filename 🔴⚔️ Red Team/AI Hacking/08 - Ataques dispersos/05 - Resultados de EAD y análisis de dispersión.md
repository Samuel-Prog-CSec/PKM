---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "EAD logra 100% de éxito sobre MNIST pero solo ~52% de dispersión: la lectura honesta de sus métricas y por qué los píxeles elegidos caen siempre en los bordes"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Implementación de EAD paso a paso]]"
Nota siguiente: "[[06 - JSMA, el Jacobiano y los mapas de saliencia]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

Los números del ataque sobre 20 muestras de MNIST correctamente clasificadas, con `beta=0.01` y 5 pasos de búsqueda binaria:

| Métrica | Valor |
| - | - |
| Tasa de éxito | **100 %** (20/20) |
| $L_2^2$ media | 4,18 (la mayoría por debajo de 5; algunos hasta ~21) |
| $L_1$ | de la decena baja a los 60 y pico |
| Dispersión media | **52,6 %** (rango ~35-75 %) |

<mark style="background: #ADCCFFA6;">Cien por cien de éxito, y ahí acaba la buena noticia.</mark> El dato que hay que mirar de verdad es el segundo.

# La lectura incómoda: 52,6 % de dispersión no es un ataque disperso

Dispersión del 52,6 % sobre 784 píxeles significa que EAD **está tocando unos 371 píxeles** para engañar al modelo. Comparado con lo que consigue [[08 - JSMA por pares, saliencia conjunta y poda|JSMA por pares]] en el mismo módulo —**42,8 píxeles de media**, un 5,5 % de la imagen— la diferencia es de un orden de magnitud.

<mark style="background: #FF5582A6;">Con la configuración por defecto, EAD es un ataque $L_2$ con sesgo hacia la dispersión, no un ataque $L_0$.</mark> Y es coherente con su diseño: $\beta = 0{,}01$ está en el extremo bajo del rango útil, elegido para no sacrificar tasa de éxito. Subirlo a 0,05-0,1 dispersa mucho más y baja el éxito. La conclusión operativa importa:

- Si lo que se necesita es **mínimo número de features tocadas** (restricción dura del dominio: bits, tokens, campos), EAD con la configuración por defecto no es la herramienta. Lo son JSMA, [Sparse-RS](https://github.com/fra31/sparse-rs) o σ-zero ([[09 - EAD frente a JSMA y el estado del arte en ataques L0|estado del arte]]).
- Si lo que se necesita es **transferibilidad y baja distorsión perceptual**, EAD sí es la elección — es la contribución real del paper.

Este tipo de matiz es lo que separa un informe útil de uno que solo copia la tabla de resultados de una herramienta.

# La relación $L_1$ / $L_2^2$ y cómo leerla

![Dos gráficas de dispersión: L1 frente a L2 al cuadrado con curva de referencia, y dispersión porcentual frente a L2 al cuadrado con líneas de media, para 20 ataques](https://academy.hackthebox.com/storage/modules/320/ead_success_analysis.png)

La gráfica izquierda enfrenta $L_1$ contra $L_2^2$ con una curva de referencia $L_1 \propto \sqrt{L_2}$. Los puntos **por encima** de la curva corresponden a perturbaciones más dispersas (la energía se concentra en pocos píxeles, lo que sube $L_1$ relativo a $L_2$); los de debajo, a modificaciones más densas. Aquí todos quedan por encima, como se espera de un objetivo con término $L_1$.

De ahí sale el estimador práctico ya visto: bajo el supuesto de magnitudes similares, $k \approx L_1^2 / L_2^2$. Con $L_1 = 60$ y $L_2^2 = 9$ salen $k \approx 400$ píxeles, ~49 % de dispersión. <mark style="background: #FFB8EBA6;">Como se justifica en [[01 - ElasticNet (EAD) y la mezcla L1 + L2#Las tres distancias, y por qué se calculan por ejemplo|la nota de las distancias]], es una **cota inferior** de $k$</mark> —Cauchy-Schwarz da $L_1^2 \le k \cdot L_2^2$—, así que el número real de píxeles tocados es **igual o mayor**, nunca menor. En cuanto las magnitudes son desiguales, el estimador se queda muy corto.

<mark style="background: #8000E1A6;">La consecuencia refuerza la lectura de arriba en lugar de suavizarla:</mark> si la estimación ya sitúa el ataque en ~400 píxeles y la cifra real solo puede ser mayor, la dispersión efectiva de EAD con la configuración por defecto es todavía peor de lo que sugieren sus propias métricas. Para un informe hay que contar los no nulos, no estimar.

La gráfica derecha muestra el compromiso dispersión-distorsión y confirma la intuición: más $L_2^2$ suele venir con menos dispersión. **Las entradas difíciles exigen modificaciones más densas**, no solo más grandes. Es la heterogeneidad de robustez que la búsqueda binaria de $c$ estaba diseñada para absorber.

# Dónde caen los píxeles: siempre en los bordes

![Mapas de calor de la magnitud de perturbación por píxel para 10 ejemplos y gráfica de barras de dispersión con línea de media](https://academy.hackthebox.com/storage/modules/320/ead_sparsity_analysis.png)

Los mapas de calor destruyen la idea de que la perturbación se reparte al azar. <mark style="background: #FFB86CA6;">Se concentra sistemáticamente en los **bordes y trazos** del dígito:</mark> el ejemplo 1 en la curva inferior derecha, el 3 en el bucle central, el 5 a lo largo del trazo vertical. Ningún píxel del fondo uniforme recibe carga significativa.

La razón es estructural, no casual. Las primeras capas de una CNN extraen features de borde —es la [[02 - Redes neuronales convolucionales (CNN)#Jerarquía de características|jerarquía de características]] que define la arquitectura—; ahí es donde el gradiente respecto a la entrada tiene magnitud, así que la optimización —que sigue el descenso más pronunciado— aterriza necesariamente en esa zona. En el fondo uniforme el modelo ha aprendido a no mirar, el gradiente es casi nulo, y el soft thresholding elimina esas perturbaciones diminutas en el primer paso.

Esto tiene dos consecuencias que van más allá del ejercicio:

1. <mark style="background: #8000E1A6;">El mapa de perturbación de EAD **es** un mapa de saliencia.</mark> Señala qué features considera decisivas el modelo. Sirve como herramienta de interpretabilidad y, en el lado defensivo, para detectar que el modelo se apoya en artefactos espurios en vez de en la señal real — el clásico "el clasificador de tanques aprendió a mirar el cielo".
2. **Da una firma detectable.** Si las perturbaciones caen siempre en bordes, un detector puede buscar exactamente eso: incoherencia local entre el gradiente de la imagen y su textura en las regiones de alto contraste. Es una de las líneas de [[04 - Detección y defensa contra la evasión|detección de ejemplos adversariales]].

# Qué se reporta de aquí

La tabla de barras de dispersión por ejemplo (35-75 %) es el dato que más cuesta interpretar y el más útil: **la variabilidad es alta**. Algunos dígitos ceden con relativamente pocos píxeles intactos; otros exigen modificación densa. Esa heterogeneidad, más que la media, es lo que describe la robustez real de un modelo — igual que $\rho_{adv}$ en [[04 - DeepFool y la perturbación mínima|DeepFool]] tiene más valor como distribución que como número único.

> [!important]+ El hallazgo no es "el modelo es evadible"
> Prácticamente todo modelo lo es. Lo que se reporta es **el coste y la visibilidad**: cuántas features hay que tocar, con qué magnitud, cuántas consultas cuesta, y si el defensor tendría alguna señal. Un modelo que cede con 40 píxeles y sin monitorización de patrón de consulta es un hallazgo mayor que uno que cede con 370 píxeles y registra el sondeo. Ver [[04 - Detección y defensa contra la evasión|detección y defensa]].

# Erratas de HTB en este módulo

> [!warning]+ No citar estas cifras sin reproducirlas
> Las salidas de consola del módulo no son todas consistentes entre sí:
> - En la sección de saliencia por pares, el texto afirma analizar el par `(352, 389)` y a continuación imprime resultados para `(327, 538)`; además **todos los impactos medidos salen 0,000000**, lo que vacía de contenido el análisis de sinergia que dice ilustrar.
> - Los rangos de gradiente impresos en una sección (`[-0.001234, 0.001456]`) difieren en tres órdenes de magnitud de los valores individuales citados poco después (`α=0.685326`).
> - La sección de análisis agregado describe **fallo universal** de JSMA de un píxel con 93,9 píxeles de media, mientras que la sección de configuración reporta **70 % de éxito** con 73,6 píxeles para la misma configuración.
> - El estimador $k \approx L_1^2/L_2^2$ se presenta como **cota superior** de los píxeles tocados cuando Cauchy-Schwarz demuestra que es **cota inferior**. No es un detalle: invertir la dirección hace que las perturbaciones parezcan más dispersas de lo que son, justo en la métrica que el módulo usa para vender el ataque.
>
> Es el mismo patrón de erratas ya detectado en los módulos 292, 302 y 307 del path: **verificar el código y los números antes de reproducirlos**.

Con EAD cerrado, el otro camino hacia la dispersión es el combinatorio: contar las features tocadas de forma explícita en vez de empujar hacia el cero con una penalización. Eso es [[06 - JSMA, el Jacobiano y los mapas de saliencia|JSMA]].
