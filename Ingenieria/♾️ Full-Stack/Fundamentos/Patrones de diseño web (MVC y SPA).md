---
tags:
  - Full-Stack
  - Desarrollo-Web
  - Patrones-Diseño
Fecha de actualización: 2026-06-22
Nota previa: "[[Front-end, back-end y full-stack]]"
Nota siguiente: "[[La pila MERN]]"
Area: "[[Fundamentos.base|Fundamentos]]"
---
---

<mark style="background: #ADCCFFA6;">Un patrón de diseño es una solución reutilizable a un problema típico y recurrente del desarrollo de software.</mark> En el desarrollo web su uso es prácticamente inevitable: casi cualquier framework o tecnología impone, de forma intrínseca, uno de estos patrones. El objetivo es hacer la aplicación **más robusta y mantenible**, controlando la **cohesión** y el **acoplamiento** y favoreciendo la **reutilización de código**.

# El patrón MVC (Modelo-Vista-Controlador)

<mark style="background: #ADCCFFA6;">MVC es el patrón de referencia de la mayoría de frameworks y librerías web.</mark> Separa la aplicación en tres capas con responsabilidades distintas:

- **Modelo**: trabaja con los datos. Contiene los mecanismos de acceso y actualización de la información y conecta directamente con la base de datos, normalmente a través de **mapeadores de datos** que representan los datos como objetos para facilitar su manipulación (en MERN, la librería [[Mongoose y el patrón ODM en Express|mongoose]]).
- **Vista**: todo el código que produce la visualización a través de interfaces gráficas de usuario; en última instancia, código **HTML**. La vista trabaja con los datos, pero no accede a ellos directamente, sino **a través de los modelos**.
- **Controlador**: contiene el código que responde a las acciones que el usuario solicita desde la vista. <mark style="background: #8000E1A6;">Es el enlace entre la vista y el modelo, y concentra gran parte de la lógica de la aplicación.</mark>

> [!info]+ MVC ha evolucionado
> El MVC moderno difiere de la abstracción clásica, pero se fundamenta en ella. Hoy los **controladores son el punto de entrada** de la aplicación y las **vistas asumen funciones de interacción** mediante el manejo de eventos de la interfaz. El detalle exacto depende del framework escogido.

# De MVC a la Single Page Application (SPA)

<mark style="background: #ADCCFFA6;">Una Single Page Application (SPA) es una aplicación web cuya interfaz vive en una única página, sin recargas completas del navegador.</mark> Es el modelo que sigue React.js.

En una SPA, las capas del MVC se reorganizan: <mark style="background: #FFB8EBA6;">la vista —y buena parte de la lógica— se ejecuta embebida en el navegador del cliente</mark>, y los controladores del servidor responden con **documentos JSON** a peticiones HTTP que llegan a través de una **API**. El servidor deja de enviar HTML completo: envía datos, y el cliente los renderiza.

<mark style="background: #8000E1A6;">Esto significa que el front-end (React) y el back-end (la API REST con Express) se desarrollan como dos aplicaciones independientes que se comunican por HTTP/JSON.</mark> Es exactamente la arquitectura que construye este temario.

# Flujo unidireccional (Flux)

Depurar una SPA puede ser tratable o un quebradero de cabeza según cómo fluyan los datos. <mark style="background: #FFB86CA6;">React.js adopta patrones unidireccionales como Flux, donde los datos fluyen en una sola dirección</mark>, lo que facilita la detección y corrección de errores y mejora el control de cambios en el front-end. La nota [[Reducers y Redux]] lleva esta idea al extremo con un estado global predecible.

# Web tradicional vs SPA: qué viaja por la red

La diferencia entre el MVC clásico y una SPA se ve mejor comparando qué se transmite en cada interacción:

- **Web tradicional (*server-side rendering*)**: cada clic pide una **página HTML completa**. El servidor ejecuta el controlador, consulta el modelo, rellena la vista (HTML) y la envía entera; el navegador **recarga**.
- **SPA + API**: el navegador carga la aplicación una sola vez. A partir de ahí, cada interacción pide **solo datos** (JSON) a la API, y React actualiza el DOM afectado **sin recargar**. El servidor ya no genera HTML, genera datos.

> [!example]+ Misma acción, dos arquitecturas
> Ver el detalle de un post:
> - Tradicional: `GET /posts/123` → el servidor devuelve una página HTML completa.
> - SPA: `GET /api/posts/123` → la API devuelve `{ "id": 123, "title": "..." }` y React lo pinta en la vista actual.

# Variantes derivadas de MVC

Del MVC han surgido variantes según el framework: **MVP** (Model-View-Presenter), **MVVM** (Model-View-ViewModel, con *data binding* bidireccional, típico de Angular) y las arquitecturas de **flujo unidireccional** como Flux/Redux que usa React. Todas comparten la idea de **separar datos, presentación y lógica**; difieren en cómo fluye la información entre capas.

> [!important]+ Para el examen
> **MVC** = tres capas: **Modelo** (datos y acceso a BBDD), **Vista** (presentación, HTML), **Controlador** (lógica; enlace vista↔modelo). En una **SPA**, la vista se renderiza en el **cliente** y el servidor expone una **API** que responde **JSON**. React sigue un flujo de datos **unidireccional** (Flux).

Existen muchos más patrones, y los frameworks comparten variantes de ellos. No es objeto del temario profundizar en arquitecturas, pero conviene tener una base con la que fundamentar la elección de frameworks y librerías.
