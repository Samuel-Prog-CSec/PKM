---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Q-learning aprende, para cada par estado-acción, cuánta recompensa acumulada cabe esperar si se toma esa acción y después se sigue la política óptima"
Fecha de actualización: 2026-07-28
Nota previa: "[[12 - Aprendizaje por refuerzo]]"
Nota siguiente: "[[14 - SARSA y el aprendizaje on-policy]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">`Q-learning` aprende, para cada par estado-acción, cuánta recompensa acumulada cabe esperar si se toma esa acción y después se sigue la política óptima.</mark> Ese número es el `Q-value`. Con la tabla completa de Q-values, la política óptima es trivial: en cada estado, elegir la acción con mayor Q.

Es `model-free` —no necesita conocer la dinámica del entorno— y `off-policy`, matiz que se desarrolla en [[14 - SARSA y el aprendizaje on-policy]].

# La Q-table

Una tabla con un estado por fila y una acción por columna. Cada celda guarda el Q-value de esa combinación.

| Estado / Acción | Arriba | Abajo | Izquierda | Derecha |
| - | - | - | - | - |
| S1 | −1,0 | 0,0 | −0,5 | 0,2 |
| S2 | 0,0 | 1,0 | 0,0 | −0,3 |
| S3 | 0,5 | −0,5 | 1,0 | 0,0 |
| S4 | −0,2 | 0,0 | −0,3 | 1,0 |

# La regla de actualización

Deriva de la ecuación de Bellman:

```text
Q(s,a) ← Q(s,a) + α · [ r + γ · max Q(s',a') − Q(s,a) ]
```

| Símbolo | Significado |
| - | - |
| `α` | Tasa de aprendizaje: cuánto pesa la información nueva frente a la acumulada |
| `r` | Recompensa inmediata tras ejecutar `a` en `s` |
| `γ` | Factor de descuento sobre las recompensas futuras |
| `max Q(s',a')` | El **mejor** Q-value alcanzable desde el estado siguiente |

El término entre corchetes es el `TD error`: la diferencia entre lo que el agente esperaba y lo que realmente observó. Si es cero, la estimación era correcta y no hay nada que aprender.

## Ejemplo numérico

Un robot en `S1` ejecuta `Derecha`, llega a `S2` y recibe `r = 0,5`. Con `α = 0,1`, `γ = 0,9` y `max Q(S2, ·) = 1,0`:

```text
Q(S1, Derecha) = 0,2 + 0,1 · [ 0,5 + 0,9 · 1,0 − 0,2 ]
               = 0,2 + 0,1 · 1,2
               = 0,32
```

<mark style="background: #FFB8EBA6;">El valor sube porque la acción condujo a un estado del que se espera mucha recompensa futura</mark>, aunque la recompensa inmediata fuese modesta. Así es como el valor se propaga hacia atrás desde la meta: primero aprende el estado contiguo al objetivo, y en iteraciones sucesivas la información va retrocediendo por la cadena.

# El algoritmo

1. **Inicializar** la Q-table, típicamente a ceros.
2. **Elegir acción** en el estado actual, equilibrando exploración y explotación.
3. **Ejecutar y observar** el estado siguiente y la recompensa.
4. **Actualizar** el Q-value con la regla anterior.
5. **Avanzar** al nuevo estado.
6. **Iterar** hasta convergencia o hasta agotar el presupuesto de iteraciones.

# Exploración frente a explotación

El dilema central: <mark style="background: #8000E1A6;">explotar lo conocido garantiza recompensa mediocre; explorar puede encontrar algo mejor o desperdiciar el intento.</mark> Un agente que solo explota se queda anclado en el primer camino aceptable que encuentre y nunca descubre el óptimo.

**`Epsilon-greedy`** es la estrategia estándar: con probabilidad `ε` se elige una acción al azar, con probabilidad `1−ε` la de mayor Q-value. `ε` se **decae** a lo largo del entrenamiento — mucha exploración al principio, casi pura explotación al final.

**`Softmax`** —conocida en RL como **exploración de Boltzmann**— asigna a cada acción una probabilidad proporcional a la exponencial de su Q-value. A diferencia de `epsilon-greedy`, que al explorar trata todas las acciones no óptimas por igual (incluidas las catastróficas), `softmax` prefiere las prometedoras sobre las claramente malas. Es la misma función que convierte `logits` en probabilidades en la salida de un LLM, y su parámetro de **temperatura** tiene el mismo efecto: subirla aplana la distribución y aumenta la aleatoriedad; bajarla la agudiza hacia la acción de mayor valor. La conexión no es una analogía — es literalmente la misma operación, y es el motivo de que ajustar la `temperature` de un LLM sea, en términos de RL, mover el equilibrio entre explotar y explorar.

# Supuestos

- **Propiedad de Markov** — el estado siguiente depende solo del estado y la acción actuales, no del historial. Si el entorno tiene memoria oculta, el agente necesita un estado que la incorpore.
- **Entorno estacionario** — las probabilidades de transición y la función de recompensa no cambian con el tiempo.

<mark style="background: #FF5582A6;">El segundo supuesto se rompe por definición en un escenario adversarial.</mark> Un defensor que reacciona a lo que hace el agente convierte el entorno en no estacionario: el mismo par estado-acción deja de producir la misma recompensa. Es la razón de que los planteamientos de RL aplicados a seguridad ofensiva sean, en rigor, problemas de teoría de juegos y no de RL clásico.

# El límite de la tabla, y cómo se supera

Una Q-table necesita una celda por cada combinación de estado y acción. Con un tablero de ajedrez, una pantalla de píxeles o el estado de una red corporativa, el número de estados es astronómico y la tabla es imposible de almacenar y de rellenar.

La solución es sustituir la tabla por una **función aproximadora**: una red neuronal que recibe el estado y devuelve los Q-values estimados. Es el `Deep Q-Network` (DQN) con el que DeepMind aprendió a jugar a los juegos de Atari a partir de píxeles en bruto. Dos trucos lo hacen viable:

- **`Experience replay`** — almacenar las transiciones observadas en un búfer y entrenar sobre muestras aleatorias de él, rompiendo la correlación temporal entre ejemplos consecutivos.
- **Red objetivo** — mantener una copia congelada de la red para calcular el término `max Q(s',a')`, evitando que el objetivo se mueva a la vez que se persigue.

> [!warning]+ El búfer de experiencia es superficie de ataque
> `Experience replay` implica que el agente aprende de datos **almacenados**, potencialmente recogidos por otra política o en otro momento. <mark style="background: #FFB86CA6;">Quien pueda escribir transiciones en ese búfer envenena el entrenamiento sin interactuar con el agente en vivo</mark> — el equivalente en RL al envenenamiento de datasets. En despliegues de RL offline, donde el agente se entrena exclusivamente sobre trayectorias registradas, el conjunto de trayectorias es el dataset y hereda todos sus riesgos.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con el `TD error`, `DQN`/`experience replay` y la ruptura del supuesto de estacionariedad en escenarios adversariales, ausentes en el original.
