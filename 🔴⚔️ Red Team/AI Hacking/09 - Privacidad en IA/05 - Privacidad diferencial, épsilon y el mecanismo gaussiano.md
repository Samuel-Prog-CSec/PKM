---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Defensa
Descripción: "Qué garantiza (ε,δ)-DP, qué NO garantiza, y las tres preguntas ante cualquier afirmación de privacidad diferencial: unidad de privacidad, delta y composición"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Ejecución y evaluación del MIA]]"
Nota siguiente: "[[06 - DP-SGD, clipping, ruido y contabilidad con Opacus]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

Regularizar mejor reduce la señal de pertenencia pero no la elimina, y no ofrece ninguna garantía. <mark style="background: #ADCCFFA6;">La privacidad diferencial es el único marco que da una cota **formal** sobre lo que cualquier atacante puede aprender de un individuo concreto</mark>, con independencia de su potencia de cómputo, su información auxiliar y los ataques que se inventen en el futuro.

# La definición

Un algoritmo aleatorizado $M$ satisface **$(\varepsilon, \delta)$-privacidad diferencial** si, para cualesquiera dos conjuntos de datos $D$ y $D'$ que difieren en **exactamente un registro**, y para cualquier subconjunto de salidas $S$:

$$P[M(D) \in S] \le e^{\varepsilon} \cdot P[M(D') \in S] + \delta$$

Leído en castellano: **añadir o quitar los datos de una persona no puede cambiar mucho la distribución de salidas del algoritmo**. Las dos piezas:

- $e^{\varepsilon}$ es una cota **multiplicativa** sobre el cociente de verosimilitudes. Con $\varepsilon = 1$, cualquier salida puede ser como mucho $e \approx 2{,}7$ veces más probable con tus datos que sin ellos.
- $\delta$ es la probabilidad de que la garantía **falle por completo**.

<mark style="background: #FFB8EBA6;">$\varepsilon$ no es una probabilidad ni un porcentaje.</mark> Es el logaritmo de un cociente de verosimilitudes, y crece exponencialmente en su efecto: $\varepsilon = 10$ no es "diez veces peor" que $\varepsilon = 1$, es $e^{9} \approx 8100$ veces más permisivo en la cota.

## La escala de $\varepsilon$ en la práctica

| $\varepsilon$ | Interpretación | Dónde se ve |
| - | - | - |
| ~1 | Privacidad muy fuerte; indiferencia casi total a cualquier individuo | Objetivo académico; difícil sin pre-entrenamiento sobre datos públicos |
| ~3 | Fuerte; impacto notable en utilidad | El "privacidad fuerte" habitual en papers |
| ~8-10 | Modesta; el modelo puede revelar patrones agregados | Línea base de "privacidad razonable" en benchmarks |
| >20 | Prácticamente decorativa | Más común en producción de lo que nadie admite |

Como referencia de industria, los despliegues de privacidad diferencial de Apple usan valores en el rango 2-8 según la función. El módulo entrena con $\varepsilon = 10$ y $\varepsilon = 3$.

# Sensibilidad y el mecanismo gaussiano

Para calibrar ruido hay que saber primero **cuánto puede afectar un solo registro** al cálculo. Eso es la **sensibilidad** $\Delta f$: el cambio máximo en la salida de $f$ al añadir o quitar un registro.

<mark style="background: #FFB86CA6;">En el descenso de gradiente estándar, la sensibilidad es efectivamente infinita:</mark> una única muestra atípica puede producir un gradiente enorme que domine la actualización del lote. Sin cota, no hay ruido que calibrar — y es exactamente el problema que resuelve el recorte de gradiente de [[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|DP-SGD]].

Con la sensibilidad acotada, el **mecanismo gaussiano** da la receta: añadir ruido $\mathcal{N}(0, \sigma^2)$ con

$$\sigma = \frac{\Delta f \cdot \sqrt{2 \ln(1{,}25/\delta)}}{\varepsilon}$$

logra $(\varepsilon,\delta)$-DP. Menos $\varepsilon$ ⇒ más ruido; menos $\delta$ ⇒ más ruido (aunque solo por la raíz de un logaritmo, así que apretar $\delta$ es relativamente barato).

> [!warning]+ Esa fórmula **solo vale para $\varepsilon < 1$**
> Es el resultado clásico de Dwork y Roth, y su demostración exige $\varepsilon \in (0,1)$. <mark style="background: #FF5582A6;">Los valores que usa este módulo —$\varepsilon = 3$ y $\varepsilon = 10$— están fuera de ese rango</mark>, así que aplicar la fórmula cerrada ahí daría una calibración sin respaldo teórico.
>
> No es una laguna del módulo: es exactamente la razón por la que [[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|DP-SGD]] no usa esta fórmula sino un **contable numérico** (`rdp`, `prv`). Los contables no aplican una expresión cerrada por paso: acumulan la distribución de la pérdida de privacidad a lo largo de todo el entrenamiento y despejan el $\sigma$ que alcanza el $\varepsilon$ objetivo, sin restricción de rango y con cotas mucho más ajustadas. La fórmula de arriba sirve para entender **de qué depende** el ruido; la calibración real la hace el contable.

# La regla de $\delta$ que casi nadie comprueba

$\delta$ debe cumplir $\delta < 1/n$, con $n$ el tamaño del conjunto de entrenamiento. CIFAR-10 tiene 50 000 muestras, así que $\delta = 10^{-5} = 1/100\,000$ cumple holgadamente.

<mark style="background: #FF5582A6;">Violar esa condición vacía la garantía de contenido.</mark> El argumento es directo: si $\delta \ge 1/n$, existe un mecanismo que satisface formalmente la definición y que **publica un registro completo del dataset elegido al azar** — la probabilidad de exponer a cualquier individuo concreto es $1/n \le \delta$, dentro del presupuesto de fallo. Una garantía "$(\varepsilon=1, \delta=10^{-2})$" sobre un dataset de 1000 personas es compatible con filtrar el expediente íntegro de una de ellas.

> [!important]+ La primera pregunta ante cualquier afirmación de DP
> **"¿Cuál es vuestro $\delta$, y cuál es $n$?"** Un $\varepsilon$ pequeño con un $\delta$ mal elegido no vale nada, y es un error que aparece en productos reales. Regla de bolsillo: $\delta \le 1/(10n)$.

# La unidad de privacidad: la pregunta que decide todo

Aquí está el malentendido más caro, y el módulo no lo menciona. La definición habla de conjuntos que difieren en **un registro**. Pero, ¿un registro es una persona?

- **DP a nivel de ejemplo** (*example-level*) — la definición protege una fila. Es lo que implementan Opacus y DP-SGD por defecto.
- **DP a nivel de usuario** (*user-level*) — protege **todas** las contribuciones de una persona.

<mark style="background: #8000E1A6;">Si un individuo aporta 50 registros, una garantía de nivel de ejemplo con $\varepsilon = 3$ **no dice que su privacidad esté protegida con $\varepsilon = 3$**.</mark> Por composición, su exposición real puede acercarse a $50 \times 3$. Escenarios donde esto pasa constantemente: datos longitudinales (un paciente con muchas visitas), telemetría (un dispositivo que reporta a diario), logs (un usuario con miles de eventos), y cualquier dataset con duplicados.

Es también la razón de que el requisito de **partición disjunta** de [[08 - PATE, ensemble de profesores y agregación con ruido|PATE]] sea tan estricto: si la misma persona cae en varias particiones, influye en varios profesores y el análisis de privacidad se rompe.

> [!warning]+ Segunda y tercera pregunta
> **"¿La garantía es por ejemplo o por usuario?"** y **"¿El $\varepsilon$ es por entrenamiento, o acumulado sobre todos los reentrenamientos y publicaciones?"** Un modelo reentrenado semanalmente con $\varepsilon = 3$ por ciclo tiene un presupuesto anual muy superior a 3, y esa composición casi nunca aparece en la documentación.

# Cota superior frente a cota inferior

DP y `MIA` empírico miden cosas complementarias y en direcciones opuestas:

| | Privacidad diferencial | `MIA` empírico |
| - | - | - |
| Tipo de garantía | **Peor caso** | **Caso medio** |
| Qué acota | Lo que consigue el atacante **óptimo**, con recursos ilimitados | Lo que consigue **este** ataque concreto |
| Es una | **Cota superior** de la vulnerabilidad | **Cota inferior** de la vulnerabilidad |
| Cubre ataques futuros | Sí | No |

Por eso la ventaja empírica medida es siempre mucho menor que la cota teórica: la cota supone la muestra que más influye en el modelo y un adversario óptimo, mientras que un ataque de umbral es simple y la mayoría de las muestras tienen influencia modesta.

<mark style="background: #FFB8EBA6;">La consecuencia operativa es que las dos hacen falta.</mark> Un modelo con `MIA` bajo pero **sin** garantía DP puede caer con un ataque mejor mañana — y [[04 - Ejecución y evaluación del MIA|LiRA y RMIA]] son exactamente eso, ataques mejores que llegaron después. Un modelo con garantía DP está acotado pase lo que pase. En un informe: medir empíricamente **y** verificar la garantía.

# Lo que la DP no protege

Delimitar el alcance evita vender la defensa como algo que no es:

- **Patrones agregados siguen siendo aprendibles** — y deben serlo, es el objetivo del modelo. Un atacante puede inferir la edad media o las features comunes de la población de entrenamiento incluso de un modelo con DP fuerte. La DP protege **individuos**, no estadísticas.
- **No frena el [[01 - Model reverse engineering y robo de modelos|robo del modelo]]**: entrenar un sustituto a partir de consultas no depende de la influencia de ninguna muestra individual.
- **No frena los [[00 - Fundamentos de la evasión de modelos|ejemplos adversariales]]**: es una propiedad sobre los datos de entrenamiento, no sobre la robustez del modelo desplegado. Un modelo con $\varepsilon = 1$ es igual de evadible que uno sin DP.

Con el marco claro, las dos formas de conseguirlo en un modelo real son inyectar ruido en el entrenamiento ([[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|DP-SGD]]) o separar arquitectónicamente al modelo desplegado de los datos sensibles ([[08 - PATE, ensemble de profesores y agregación con ruido|PATE]]).
