---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Defensa
Descripción: "Los números del compromiso sobre CIFAR-10 y por qué medir una defensa con un ataque débil no prueba nada: el valor de DP-SGD es la garantía, no la ventaja medida"
Fecha de actualización: 2026-07-29
Nota previa: "[[06 - DP-SGD, clipping, ruido y contabilidad con Opacus]]"
Nota siguiente: "[[08 - PATE, ensemble de profesores y agregación con ruido]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

Tres modelos sobre CIFAR-10 con la misma arquitectura CNN, 20 épocas cada uno:

| Modelo | Precisión test | Ventaja `MIA` | Brecha de sobreajuste |
| - | - | - | - |
| Baseline (sin DP) | 67 % | 0,019 | 10 % |
| DP $\varepsilon = 10$ | 58 % | 0,008 | 3 % |
| DP $\varepsilon = 3$ | 53 % | 0,004 | 1 % |

Tres lecturas inmediatas: la precisión baja 9 y luego 14 puntos; la ventaja de pertenencia se reduce a la mitad en cada escalón; y <mark style="background: #ADCCFFA6;">la brecha de sobreajuste se desploma de 10 % a 1 %, que es exactamente el mecanismo por el que el ruido dificulta la inferencia de pertenencia.</mark>

# Rendimientos decrecientes

El coste marginal de la privacidad se mantiene, pero el beneficio marginal se encoge:

- De $\varepsilon = \infty$ a $\varepsilon = 10$: **9 puntos** de precisión por **0,011** de reducción de ventaja (≈1,2 puntos por cada 0,001).
- De $\varepsilon = 10$ a $\varepsilon = 3$: **5 puntos** más por solo **0,004** (≈1,25 puntos por cada 0,001).

<mark style="background: #FFB86CA6;">El precio por unidad de privacidad es constante; lo que cae es cuánta privacidad queda por comprar.</mark> A partir de cierto punto la ventaja `MIA` se acerca al azar y seguir añadiendo ruido solo cuesta precisión.

# El problema de esta demostración

Puesta así, la conclusión razonable sería *"DP-SGD no compensa"*: se pagan 9 puntos de precisión para reducir una ventaja de ataque que ya era del **1,9 %**. Nadie firma eso.

Pero esa conclusión sería errónea, y por dos motivos que el módulo no separa:

**1. La ventaja base es pequeña porque el dataset es grande.** CIFAR-10 tiene 50 000 muestras, 5000 por clase; el volumen actúa como regularización implícita y ninguna muestra domina los parámetros. <mark style="background: #FF5582A6;">En los escenarios donde la privacidad importa de verdad —historiales clínicos de un hospital, expedientes de una entidad, datos de una minoría dentro del dataset— los conjuntos son de miles, no de decenas de miles, y la ventaja base es mucho mayor.</mark> Medir el compromiso sobre CIFAR-10 subestima sistemáticamente el beneficio.

**2. La ventaja se mide con un ataque de umbral.** `compute_mia_advantage()` implementa un ataque de confianza con búsqueda de umbral: el más simple de la familia. Como se estableció en [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|la nota de DP]], **un `MIA` empírico es una cota inferior**. Que un ataque débil baje al 0,4 % no dice que [[04 - Ejecución y evaluación del MIA|LiRA o RMIA]] no midan mucho más, ni dice nada sobre el ataque que se publique el año que viene.

> [!important]+ El argumento correcto para DP
> El valor de DP-SGD **no** es la reducción de ventaja medida hoy: es que la cota vale **contra cualquier ataque, presente o futuro**, y es demostrable ante un regulador. Justificarlo con "reduce la ventaja del ataque X en un 57 %" invita a la réplica evidente —"pues parcheamos contra X y nos ahorramos los 9 puntos"— que no funciona, porque X no es el único ataque. El argumento es la garantía, no la medición.

# La brecha de sobreajuste como métrica de control

De los tres números de la tabla, el más útil operativamente es el tercero. La brecha cae de 10 % a 3 % a 1 %, y es **observable sin montar ningún ataque**: basta comparar precisión en entrenamiento y en test.

<mark style="background: #8000E1A6;">En una auditoría sirve como comprobación de coherencia barata:</mark> si un cliente afirma entrenar con $\varepsilon = 3$ y su modelo exhibe una brecha del 10 %, algo no cuadra — el ruido que exige ese $\varepsilon$ es incompatible con memorizar tanto. No es una prueba (la brecha depende también del dataset y la arquitectura), pero sí una señal de alarma que justifica pedir el código y la configuración del contable.

# Limitaciones que hay que declarar

**Sobrecoste computacional.** Entrenar 2-5× más lento por los gradientes por muestra, y memoria proporcional al lote. Para modelos grandes puede ser prohibitivo — de ahí que la vía real sea el *fine-tuning* con DP sobre un modelo preentrenado, no el entrenamiento desde cero ([[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|nota anterior]]).

**Pérdida de utilidad con privacidad fuerte.** El modelo con $\varepsilon = 3$ pierde 14 puntos; alcanzar $\varepsilon = 1$ desde cero puede costar 20-30. Para algunas aplicaciones es inaceptable, y ahí es donde el preentrenamiento sobre datos públicos cambia la ecuación por completo.

**Alcance de la protección.** DP-SGD acota la influencia de **cada muestra individual** sobre los parámetros. Fuera de ese alcance quedan:

- **Patrones agregados** — un atacante puede seguir infiriendo propiedades estadísticas de la población de entrenamiento. Es intencionado: es lo que el modelo debe aprender.
- **[[01 - Model reverse engineering y robo de modelos|Robo de funcionalidad]]** — entrenar un sustituto desde consultas no depende de la influencia de ninguna muestra.
- **[[00 - Fundamentos de la evasión de modelos|Ejemplos adversariales]]** — sin relación. Un modelo con DP es igual de evadible.

> [!warning]+ Erratas del módulo
> Las cifras vuelven a no cuadrar entre secciones: el texto reporta 67 % / 58 % / 53 % de precisión, mientras que los pies de figura de las mismas gráficas dicen 64,2 % / 58,5 % / 52,3 %, y la ventaja base aparece como 0,019 en el texto y ~0,022 en una figura. Es el mismo patrón de inconsistencias detectado en [[04 - Ejecución y evaluación del MIA#Erratas del módulo|la evaluación del MIA]] y en el [[05 - Resultados de EAD y análisis de dispersión#Erratas de HTB en este módulo|módulo 320]].

# Las alternativas, y cuándo cada una

| Enfoque | De dónde sale la privacidad | Cuándo elegirlo |
| - | - | - |
| **DP-SGD** | Ruido en los gradientes | No hay datos públicos equivalentes; hay que entrenar directamente sobre los sensibles |
| **[[08 - PATE, ensemble de profesores y agregación con ruido\|PATE]]** | Separación arquitectónica + votación ruidosa | Existen datos públicos de la misma distribución y hace falta inferencia de alto volumen tras el despliegue |
| **DP local** | Ruido en la **recolección**, antes de entrenar | No se confía ni en quien entrena; se acepta necesitar mucho más volumen de datos |
| **Aprendizaje federado** | Minimización de datos: nunca salen del dispositivo | Datos distribuidos por naturaleza; se aceptan el coste de comunicación y los problemas de distribuciones no IID |

La DP local merece una advertencia: como el ruido se añade por usuario y luego se agrega, el ruido **se compone entre todos** y hace falta muchísimo más volumen para la misma utilidad. Funciona para estadísticas agregadas sobre poblaciones enormes (telemetría a escala de sistema operativo); rara vez para entrenar un modelo con decenas de miles de registros.

Y el federado, por sí solo, **no es una garantía de privacidad**: compartir gradientes filtra información —existe una línea entera de ataques de reconstrucción a partir de gradientes—, así que en despliegues serios se combina con agregación segura y con DP encima.

# Cómo se evalúa la afirmación de un cliente

Ante un "entrenamos con privacidad diferencial", lo que hay que pedir, en este orden:

1. **$\varepsilon$, $\delta$ y $n$** — y comprobar $\delta \ll 1/n$.
2. **Unidad de privacidad**: ¿por ejemplo o por usuario? Si los individuos aportan varios registros y la garantía es por ejemplo, no protege a las personas.
3. **Composición en el tiempo**: ¿el $\varepsilon$ es por entrenamiento o acumulado sobre reentrenamientos y publicaciones sucesivas?
4. **Contable usado** (`rdp`, `gdp`, `prv`) y `max_grad_norm`, con la evidencia de cómo se calibró.
5. **Brecha de sobreajuste medida** — la comprobación de coherencia barata descrita arriba.
6. **Con qué ataque se validó empíricamente.** Si la respuesta es "un ataque de umbral", la medición es una cota inferior floja.

<mark style="background: #FFB8EBA6;">El hallazgo típico no es "no usan DP": es que la usan con una unidad de privacidad que no protege a quien creen, o con un $\delta$ que hace la garantía vacía, o sin contabilizar la composición entre reentrenamientos.</mark>
