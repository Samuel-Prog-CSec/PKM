---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "SARSA —*State, Action, Reward, State, Action*— es un algoritmo model-free casi idéntico a 13 - Q-Learning salvo por un detalle de la regla de actualización"
Fecha de actualización: 2026-07-28
Nota previa: "[[13 - Q-Learning]]"
Nota siguiente: "[[00 - Deep learning y el perceptrón]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

`SARSA` —*State, Action, Reward, State, Action*— es un algoritmo `model-free` casi idéntico a [[13 - Q-Learning]] salvo por un detalle de la regla de actualización. Ese detalle define la distinción más importante del aprendizaje por refuerzo: **on-policy frente a off-policy**.

# Una sola diferencia

```text
Q-learning:  Q(s,a) ← Q(s,a) + α · [ r + γ · max Q(s',a') − Q(s,a) ]
SARSA:       Q(s,a) ← Q(s,a) + α · [ r + γ ·     Q(s',a') − Q(s,a) ]
```

Q-learning usa el **mejor** Q-value alcanzable desde el estado siguiente. SARSA usa el Q-value de la **acción que realmente va a tomar**, elegida por la política actual — incluyendo sus pasos exploratorios.

<mark style="background: #ADCCFFA6;">Q-learning aprende el valor de la política óptima; SARSA aprende el valor de la política que está siguiendo.</mark>

De ahí el cambio en el bucle: SARSA elige la acción siguiente `a'` **antes** de actualizar, porque la necesita para el cálculo.

1. Inicializar la Q-table.
2. Elegir `a` en `s` con `epsilon-greedy`.
3. Ejecutar `a`, observar `r` y `s'`.
4. **Elegir `a'` en `s'` con la misma política.**
5. Actualizar `Q(s,a)` usando `Q(s',a')`.
6. `s ← s'`, `a ← a'` y repetir.

# On-policy y off-policy

| | On-policy (`SARSA`) | Off-policy (`Q-learning`) |
| - | - | - |
| Qué aprende | El valor de la política que ejecuta | El valor de la política óptima |
| Considera la exploración | Sí: las acciones exploratorias entran en la estimación | No: asume comportamiento óptimo a partir del siguiente paso |
| Fuente de datos | Solo su propia experiencia | Puede aprender de datos generados por otra política |
| Comportamiento resultante | Conservador, tiene en cuenta el riesgo de explorar | Optimista, apunta al óptimo teórico |

<mark style="background: #FFB8EBA6;">La capacidad off-policy es la razón práctica del dominio de Q-learning</mark>: permite aprender de datos registrados, de demostraciones humanas o de un búfer de experiencia acumulado. Todo el RL offline y `DQN` dependen de esa propiedad.

## El ejemplo que lo explica: el borde del acantilado

La ilustración canónica está en *Reinforcement Learning: An Introduction* de Sutton y Barto (Ejemplo 6.6, `Cliff Walking`). Una rejilla donde el camino más corto entre origen y meta discurre pegado a un precipicio; caer conlleva una penalización enorme.

- **Q-learning** aprende la ruta óptima: la que va pegada al borde. Es correcta, pero como el agente sigue explorando con `epsilon-greedy`, de vez en cuando da un paso aleatorio y **cae**. Su rendimiento real durante el entrenamiento es peor.
- **SARSA** aprende un camino más largo, alejado del borde. Al incorporar en la estimación que a veces actuará al azar, <mark style="background: #8000E1A6;">valora negativamente estar cerca del precipicio y elige un margen de seguridad</mark>.

> [!important]+ La lección operativa
> Cuando el agente aprende **actuando en el mundo real** y los errores tienen coste, on-policy es la elección correcta: aprende una política que sigue funcionando con un agente imperfecto que a veces se desvía. Off-policy converge a un óptimo que solo es óptimo si el agente ejecuta el plan a la perfección.
>
> Trasladado a un agente de IA con herramientas: una política optimizada bajo el supuesto de ejecución perfecta puede ser catastrófica en cuanto haya ruido, latencia o una respuesta inesperada de una API.

# Convergencia y parámetros

Ambos exigen tasa de aprendizaje decreciente y visitar todos los pares estado-acción infinitas veces. Pero **no convergen a lo mismo bajo las mismas condiciones**, y la diferencia es justo la del carácter on/off-policy:

- **Q-learning** converge a `Q*` —los valores de la política **óptima**— aunque la política que ejecuta sea otra, con tal de que explore lo suficiente. Es la ventaja de ser off-policy: aprende del óptimo mientras hace otra cosa.
- **SARSA** converge a los valores de la política que **está siguiendo**. Para que esa política sea la óptima hace falta una condición extra: que sea `GLIE` (*Greedy in the Limit with Infinite Exploration*), es decir, que la exploración **decaiga hasta cero**. Con `epsilon-greedy` eso significa decaer `ε` a 0.

<mark style="background: #FFB8EBA6;">Con un `ε` fijo, SARSA no converge a la política óptima — converge a la mejor política *que tolera ese nivel de exploración*.</mark> Y eso no es un defecto: es exactamente la propiedad que hace que elija el camino seguro en el acantilado.

- **`α` (tasa de aprendizaje)** — alta acelera el aprendizaje pero desestabiliza; baja estabiliza pero ralentiza. Se suele decaer con el tiempo.
- **`γ` (factor de descuento)** — alto prioriza recompensas a largo plazo; bajo, las inmediatas.

Ambos comparten también los supuestos de **propiedad de Markov** y **entorno estacionario**, con la misma advertencia: <mark style="background: #FF5582A6;">en un escenario con un adversario que se adapta, la estacionariedad no se cumple</mark> y las garantías de convergencia dejan de aplicar.

# Lectura ofensiva de la distinción

La propiedad off-policy —aprender de datos que generó otro— es exactamente lo que abre la puerta al envenenamiento:

- **RL offline** — el agente se entrena sobre un conjunto fijo de trayectorias registradas. <mark style="background: #FFB86CA6;">Ese conjunto es un dataset de entrenamiento y tiene la misma superficie de ataque que cualquier otro</mark>: quien pueda insertar trayectorias con recompensas manipuladas moldea la política resultante.
- **Aprendizaje por demostración** — cuando la política se inicializa imitando trayectorias "expertas", basta contaminar las demostraciones para implantar comportamiento arbitrario, incluido un `backdoor` que solo se activa ante un estado disparador concreto.
- **Modelos de recompensa manipulables** — en `RLHF` el modelo de recompensa se entrena con comparaciones humanas. Contaminar esas comparaciones desplaza directamente lo que el modelo final considera aceptable — el envenenamiento aplicado a la capa de alineación descrita en [[12 - Aprendizaje por refuerzo]].

Un agente on-policy puro es menos vulnerable a esto porque solo aprende de su propia interacción, pero paga el precio de necesitar muchísima más experiencia y de no poder reutilizar datos.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con el ejemplo `Cliff Walking` y las implicaciones de seguridad del aprendizaje off-policy, ausentes en el original.
- Sutton & Barto, *Reinforcement Learning: An Introduction* (2ª ed., 2018), Ejemplo 6.6 — comparación SARSA / Q-learning.
