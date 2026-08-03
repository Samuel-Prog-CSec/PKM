---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Los ataques a los datos corrompen el sistema atacando aquello de lo que el modelo aprende, o el artefacto donde se guarda"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - El pipeline de datos y su superficie de ataque]]"
Nota siguiente: "[[02 - Label flipping]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

<mark style="background: #ADCCFFA6;">Los ataques a los datos corrompen el sistema atacando aquello de lo que el modelo aprende, o el artefacto donde se guarda.</mark> Eso los separa de las otras dos familias con las que se confunden:

| Familia | Cuándo actúa | Qué manipula |
| - | - | - |
| **Ataques a los datos** | Antes o durante el entrenamiento | Los datos de aprendizaje o el fichero del modelo |
| `Evasion` | En inferencia | La entrada, para engañar a un modelo ya desplegado |
| `Privacy` | En inferencia | Nada — extrae información que el modelo memorizó |

La diferencia práctica: cuando un ataque de evasión falla, no queda nada. Cuando un ataque a los datos tiene éxito, <mark style="background: #8000E1A6;">para cuando el modelo sirve una predicción el daño ya está dentro de él</mark>, y sigue ahí en cada versión que se entrene sobre el mismo dataset.

# Un ataque por etapa

## Recolección — envenenamiento de datos

El atacante inyecta datos maliciosos **en el origen**, sin romper nada: usando los mismos canales de entrada que el sistema ya acepta. Dos formas según qué manipule:

- **[[02 - Label flipping|`Label flipping`]]** — cambiar lo que el modelo cree que significa una muestra.
- **[[05 - Clean label attacks|`Feature attacks`]]** — perturbar los valores que la muestra lleva.

En el e-commerce: oleadas de reseñas positivas falsas para un producto, con formato correcto, llegando por la API normal de reseñas. Algunas pueden llevar además patrones de palabras clave sin sentido para un humano, diseñados como **disparadores de puerta trasera** ([[08 - Backdoors y trojans en modelos]]).

En sanidad: alterar metadatos `DICOM` o manipular notas clínicas para etiquetar mal muestras diagnósticas. Perturbaciones pequeñas —una distribución de píxeles desplazada, un código de diagnóstico cambiado— que, con suficientes muestras, hacen que el modelo aprenda una versión distorsionada de la tarea.

## Almacenamiento — dos categorías muy distintas

**Datos**: acceso no autorizado al data lake permite robar o modificar datasets enteros. Manipular después de la ingesta **salta cualquier validación que existiera al recibir**.

**Modelos**: los ficheros serializados son el objetivo de alto valor, porque <mark style="background: #FFB86CA6;">llevan confianza ejecutable</mark>. Con escritura, el atacante puede sustituir el modelo por uno con un **trojan** —que funciona con normalidad y produce la salida elegida ante entradas disparadoras— o ir más allá con **esteganografía de modelo**: esconder código dentro del propio fichero, que se ejecuta al deserializarlo.

El efecto ya no son predicciones erróneas. Es **ejecución de código**: un `.pkl` comprometido cargado por el servidor Flask da un punto de apoyo en la infraestructura de servicio; un `.pt` comprometido cargado por el sistema clínico da acceso a la red sanitaria.

## Procesado — atacar el código, no los datos

No se tocan los datos: se toca **el código que los transforma**. Comprometer el trabajo de `Spark` que analiza sentimiento invierte etiquetas —label flipping de manual— **sin tocar una sola reseña**. Basta con modificar la configuración de un trabajo o inyectar código en un script.

<mark style="background: #FF5582A6;">Es el vector más difícil de detectar de todos</mark>, porque los datos en crudo siguen siendo correctos en almacenamiento y pasan cualquier auditoría. La corrupción existe solo en la salida procesada sobre la que se entrena.

## Modelado — donde se materializa

El trabajo de entrenamiento no sabe que los ficheros contienen etiquetas invertidas, ni que algunas características llevan disparadores. Aprende ciegamente lo que los datos enseñan. La superficie es heredada; el trabajo del adversario ya estaba hecho.

## Despliegue — interceptar el artefacto

Mismo resultado que en almacenamiento (trojan o esteganografía), **requisito de acceso distinto**: no hace falta escritura en el bucket ni en el registro de modelos, solo acceso a la ruta de despliegue. Un pipeline de CI/CD mal configurado, un endpoint de descarga sin autenticar, o una posición de intermediario entre el almacenamiento y el pod de servicio.

## Reentrenamiento — online poisoning

El punto de entrada más efectivo, y por una razón estructural: **el pipeline está diseñado para confiar en los datos nuevos**.

No hace falta comprometer almacenamiento ni código. Se envían datos manipulados por los mismos canales que usan los usuarios legítimos: clics sutilmente alterados, feedback que sesga etiquetas futuras, interacciones repetidas que empujan los pesos hacia un resultado concreto.

Cada envío individual parece normal. El envenenamiento se acumula a lo largo de ciclos largos, y esa lentitud es lo que lo hace difícil de detectar: <mark style="background: #FFB8EBA6;">la calidad no se desploma, **deriva**</mark>. El sistema de monitorización tiene que distinguir entre tres cosas que se parecen mucho — cambio genuino de distribución, ruido aleatorio y manipulación adversarial — y fue construido para adaptarse a la primera.

# Encaje en los marcos

> [!warning]+ Errata de HTB — numeración OWASP desactualizada
> El módulo mapea los ataques a `OWASP LLM03: Training Data Poisoning` y `LLM05: Supply Chain Vulnerabilities`. <mark style="background: #FF5582A6;">Esa es la numeración de la **edición 2023**, que ya no es la vigente.</mark> En la [[03 - OWASP Top 10 para aplicaciones LLM|edición 2025]], que es la actual, las entradas correctas son:
>
> | Riesgo | Numeración 2025 (correcta) | Numeración 2023 (la que usa HTB) |
> | - | - | - |
> | Envenenamiento de datos y modelo | **`LLM04:2025`** | `LLM03` |
> | Cadena de suministro | **`LLM03:2025`** | `LLM05` |
> | Tratamiento inseguro de la salida | `LLM05:2025` | `LLM02` |
>
> Es decir: HTB llama `LLM05` a la cadena de suministro, y en 2025 ese identificador designa otra cosa completamente. Al citar en un informe, usar la numeración 2025 y el nombre completo del riesgo.

Con la numeración correcta:

- **`LLM04:2025 Data and Model Poisoning`** cubre la mayoría de lo descrito arriba: corrupción durante recolección, procesado, entrenamiento o feedback.
- **`LLM03:2025 Supply Chain`** cubre el resto: fuentes de datos de terceros comprometidas, artefactos preentrenados manipulados, y vulnerabilidades en los componentes software de la infraestructura. Es más amplio que el envenenamiento — se extiende a gestión de dependencias, procedencia de modelos de terceros e integridad de la infraestructura.

En el [[04 - Google Secure AI Framework (SAIF)|SAIF]] de Google, el mismo terreno visto por ciclo de vida:

| Principio SAIF | Qué cubre de esta carpeta |
| - | - |
| `Secure Supply Chain` | Prevención del envenenamiento; `Security Testing` durante el desarrollo del modelo |
| `Secure Deployment` | Integridad del artefacto y prevención de inyección de código |
| `Secure Monitoring & Response` | Detección de manipulación dentro de bucles de reentrenamiento |

<mark style="background: #8000E1A6;">Ese último punto es el que más importa aquí</mark>: los ataques de esta carpeta —el online poisoning especialmente— están diseñados para operar dentro del comportamiento normal del sistema. Detectarlos exige monitorización orientada a anomalías estadísticas sobre distribuciones de datos a lo largo del tiempo. La seguridad perimetral en el despliegue no sirve de nada. Se desarrolla en [[14 - Detección y evasión en ataques a los datos]].

# Escala de impacto

De menor a mayor, y es útil tenerla presente para argumentar severidad:

1. **Decisiones sesgadas y calidad degradada** — el modelo funciona peor, nadie sabe por qué.
2. **Comportamiento dirigido** — el modelo falla de forma predecible en las entradas que el atacante eligió ([[04 - Ataques dirigidos a una clase]]).
3. **Puerta trasera** — comportamiento normal salvo ante el disparador ([[08 - Backdoors y trojans en modelos]]).
4. **Ejecución de código** — la brecha sale del modelo y entra en la infraestructura ([[11 - Pickle y la deserialización insegura de modelos]]).
