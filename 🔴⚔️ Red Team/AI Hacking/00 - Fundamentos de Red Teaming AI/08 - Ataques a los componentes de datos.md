---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "El componente data abarca los datos de entrenamiento y los de inferencia"
Fecha de actualización: 2026-07-28
Nota previa: "[[07 - Ataques a los componentes del modelo]]"
Nota siguiente: "[[09 - Ataques a los componentes de aplicación]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

El componente `data` abarca los datos de entrenamiento y los de inferencia. <mark style="background: #ADCCFFA6;">Como el modelo deriva su comportamiento de los datos, manipularlos es manipular el modelo — con la ventaja para el atacante de que casi nunca hace falta tocar el modelo en sí.</mark>

# Riesgos

## Datos de entrenamiento defectuosos

Antes que cualquier ataque, el riesgo basal: sesgos en los datos y datos no representativos de aquello sobre lo que después se consulta el modelo. Produce resultados de baja calidad y, en dominios sensibles, salidas discriminatorias o dañinas. No es un ataque, pero define el suelo del que parte todo lo demás — ver [[02 - Datasets para seguridad]].

## Envenenamiento de datos

Mismo impacto que el envenenamiento del modelo, distinto punto de aplicación: se manipulan los datos de entrenamiento en lugar de los parámetros. Resultados posibles: salida engañosa, sesgada o dañina.

<mark style="background: #FFB86CA6;">El caso con más valor ofensivo es el `backdoor attack`</mark>: incrustar en los datos un **disparador** concreto de forma que el modelo se comporte con normalidad salvo cuando lo recibe. Es la asimetría demostrada en [[02 - Manipulación del modelo]] — rendimiento intacto en las métricas globales, comportamiento controlado ante la entrada elegida.

## Fuga de datos

Entrenar y operar un modelo exige volúmenes enormes de datos, y esos datos se almacenan, se mueven y se procesan. Si contienen información personal, una fuga tiene consecuencias legales directas — RGPD y equivalentes.

Además del daño inmediato, los datos robados **habilitan más ataques**: conocer el conjunto de entrenamiento permite construir entradas dirigidas, reproducir el modelo o diseñar ejemplos adversariales con mucho mejor criterio. <mark style="background: #FFB8EBA6;">Y en muchos casos el dataset es en sí mismo el activo</mark>: conjuntos curados durante años, imposibles de reconstruir, valiosísimos para un competidor.

> [!info]+ Desarrollo completo
> Las técnicas concretas de envenenamiento —[[02 - Label flipping\|label flipping]], [[05 - Clean label attacks\|clean label]], [[08 - Backdoors y trojans en modelos\|trojans]]— con implementación y resultados medidos, en la carpeta [[00 - El pipeline de datos y su superficie de ataque\|Ataques a los datos]].

# TTPs

## El requisito difícil: escribir en el conjunto de entrenamiento

El envenenamiento exige saber con qué datos se entrena el modelo **e** inyectar en ellos. Según de dónde salgan los datos, cómo se validen y cómo esté montado el proceso, esto va de imposible a trivial. La pregunta que ordena el análisis es siempre la misma: **¿quién puede escribir en la fuente?**

| Escenario | Viabilidad |
| - | - |
| Corpus interno curado y versionado | Muy baja: requiere comprometer el pipeline |
| Datos recolectados de la web | Alta: es el escenario de `split-view` y `frontrunning` de [[02 - Datasets para seguridad]] |
| Reentrenamiento con datos de producción | Alta: basta con usar el sistema |
| Etiquetas aportadas por usuarios | Alta: el reporte del usuario **es** la etiqueta |
| `Federated learning` | **Máxima**, ver abajo |

> [!important]+ Aprendizaje federado: el atacante es un participante legítimo
> En `federated learning` varias partes entrenan un modelo global sin compartir sus datos: cada una entrena localmente y envía **actualizaciones de parámetros** al agregador.
>
> <mark style="background: #FF5582A6;">Eso convierte a cualquier participante en un envenenador con acceso autorizado y directo al proceso de entrenamiento.</mark> No hay que comprometer nada: basta con enviar actualizaciones manipuladas. Y el diseño juega en contra del defensor, porque la premisa del esquema —que el agregador **no** ve los datos locales— impide precisamente la validación que detectaría el ataque.
>
> Mitigaciones habituales: agregación robusta que descarte actualizaciones atípicas, recorte de norma para acotar la influencia de cada participante, y privacidad diferencial. Ninguna resuelve el problema del todo. Si el sistema evaluado usa aprendizaje federado, el envenenamiento debe estar en el alcance por defecto.

## Envenenamiento del índice RAG: la vía práctica

HTB centra el envenenamiento en el entrenamiento. En 2026, el vector con mucha diferencia más accesible es otro: **el índice de recuperación**.

Un sistema RAG indexa documentación interna —wikis, SharePoint, tickets, repositorios, correo— y recupera fragmentos para meterlos en el contexto del modelo. <mark style="background: #8000E1A6;">Quien pueda escribir en cualquiera de esas fuentes escribe en el prompt del modelo</mark>, sin tocar el entrenamiento, sin esperar a un ciclo de reentrenamiento y con efecto inmediato.

Basta con una página de wiki, un comentario en un ticket o un documento subido a una carpeta compartida que contenga instrucciones dirigidas al modelo. Cuando la consulta de otro usuario recupere ese fragmento, las instrucciones entran en su contexto: es `prompt injection` indirecta con persistencia, y es el `LLM08` de [[03 - OWASP Top 10 para aplicaciones LLM]].

Qué comprobar en un engagement:
- **Quién puede escribir** en cada fuente indexada, y si esos permisos coinciden con los de quien consulta.
- **Si la autorización se aplica en la recuperación** o solo en la interfaz. Una base vectorial compartida entre departamentos sin filtrado por permisos filtra entre ellos.
- **Si el contenido recuperado se delimita** de alguna forma antes de entrar al contexto.
- **Si la base vectorial está expuesta**. Los embeddings no son datos anónimos: existen técnicas de inversión que reconstruyen aproximadamente el texto original.

## Robo de datos por vías tradicionales

Aquí no hay nada específico de IA, y por eso funciona tan bien:

- Almacenamiento en la nube mal configurado — buckets con los datasets y los checkpoints.
- Cifrado insuficiente en reposo o en tránsito.
- Pipelines de datos inseguros, sin autenticación entre etapas.
- APIs vulnerables que exponen los datos de entrenamiento o de inferencia.

Y el mismo conjunto de fallos **en los proveedores** que suministran o curan los datos: comprometer al vendedor da acceso al dataset antes de que llegue a la organización.

## Amenaza interna

Empleados y contratistas con acceso legítimo. Pueden ser el objetivo de `phishing` o pretexting, o exfiltrar directamente por interés propio. <mark style="background: #FFB8EBA6;">Es el vector más difícil de detectar</mark>, porque no requiere explotar ninguna vulnerabilidad: el acceso ya está concedido.

# Un problema abierto: el derecho al olvido

Merece mención aparte porque aparece en cualquier evaluación con implicación regulatoria. <mark style="background: #FFB86CA6;">Si un modelo se entrenó con datos personales y el titular ejerce su derecho de supresión, borrar el registro de la base de datos **no lo borra del modelo**</mark>: sigue codificado en los pesos y puede extraerse mediante inferencia de pertenencia o extracción de datos de entrenamiento.

Las opciones son reentrenar sin ese dato —caro y poco realista a demanda— o aplicar técnicas de `machine unlearning`, un área todavía inmadura y sin garantías fuertes. Es un hallazgo legítimo de una auditoría de privacidad de IA, y conviene plantearlo antes de que el sistema se entrene, no después.

## Fuentes

- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con el desarrollo del aprendizaje federado como posición óptima de envenenamiento, el envenenamiento del índice RAG como vector práctico dominante y el problema del derecho al olvido, ausentes en el original.
