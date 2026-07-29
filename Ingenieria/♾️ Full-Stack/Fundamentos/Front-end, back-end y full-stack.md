---
tags:
  - Full-Stack
  - Desarrollo-Web
  - Introduccion
Descripción: "El desarrollo de aplicaciones web agrupa un conjunto de habilidades que se reparten en tres especialidades con nombre propio: front-end, back-end y full-stack"
Fecha de actualización: 2026-06-22
Nota previa: 
Nota siguiente: "[[Patrones de diseño web (MVC y SPA)]]"
Area: "[[Fundamentos.base|Fundamentos]]"
---
---

El desarrollo de aplicaciones web agrupa un conjunto de habilidades que se reparten en tres especialidades con nombre propio: **front-end**, **back-end** y **full-stack**. La distinción no es solo de herramientas: separa **en qué lado de la aplicación se ejecuta el código** y qué responsabilidades asume cada perfil.

# El modelo cliente-servidor como base

Toda aplicación web se reparte entre dos mitades que se comunican por red, normalmente mediante el protocolo HTTP: el **cliente** (el navegador del usuario) y el **servidor** (la máquina remota que aloja la lógica y los datos). <mark style="background: #ADCCFFA6;">El cliente solicita y muestra; el servidor procesa y responde.</mark> Las tres especialidades se definen por el lado que ocupan en este modelo.

# Desarrollador front-end

<mark style="background: #ADCCFFA6;">Un desarrollador front-end trabaja del lado del cliente: todo lo que el usuario ve y con lo que interactúa al navegar por la aplicación.</mark> Domina la estructura y el diseño de las vistas y atiende a estándares de **usabilidad, legibilidad, accesibilidad** y diseño *responsive*.

<mark style="background: #FFB8EBA6;">Su preocupación por la lógica de negocio es mínima</mark>: solo la estrictamente necesaria para las propias vistas. Las transacciones no ocurren en el lado del cliente. En la pila MERN, el front-end se construye con **React.js**.

Tecnologías típicas: `HTML`, `CSS` (y preprocesadores como Sass), `JavaScript`, y librerías/frameworks de interfaz como React, Angular o Vue.

# Desarrollador back-end

<mark style="background: #ADCCFFA6;">Un desarrollador back-end trabaja del lado del servidor: desarrolla y coordina la mayor parte de la lógica y las transacciones de la aplicación.</mark> Debe dominar uno o varios lenguajes y frameworks de servidor, y estar familiarizado con los **protocolos de comunicación** (sobre todo HTTP) y con los **sistemas de bases de datos**.

Es el responsable de que una petición del cliente se traduzca en la operación correcta sobre los datos y de devolver una respuesta coherente. En MERN, el back-end lo forman **Node.js** (entorno de ejecución), **Express.js** (framework de servidor) y **MongoDB** (base de datos).

Tecnologías típicas: lenguajes de servidor (`JavaScript`/Node, Python, PHP, Java, Go…), frameworks (Express, Django, Spring…), bases de datos (MongoDB, MySQL, PostgreSQL…) y protocolos (`HTTP`, WebSocket).

# Desarrollador full-stack

En la práctica, los límites se difuminan: <mark style="background: #FFB8EBA6;">el back-end asume progresivamente responsabilidades del front-end, y el front-end necesita cada vez más conocimientos de servidor.</mark> De esa convergencia surge la figura del full-stack.

<mark style="background: #ADCCFFA6;">Un desarrollador full-stack es responsable de la implementación de la aplicación tanto en su parte cliente como en el servidor</mark>: desde la configuración del servidor y la lógica de la aplicación hasta la maquetación y el diseño de cara al usuario final. El perfil fue **popularizado por el departamento de ingeniería de Facebook**.

<mark style="background: #FFB86CA6;">Es difícil ser un buen full-stack: resulta casi inviable dominar a la vez todas las tecnologías de cliente y servidor.</mark> Por eso, en la práctica, el full-stack **suele especializarse más en una de las dos partes**, pero con conocimiento suficiente de la otra como para diseñar, desarrollar y desplegar la aplicación completa. 

# El recorrido de una petición

Para ver dónde actúa cada perfil, sigamos una acción típica —un usuario publica un comentario—:

1. El **front-end** (React) captura el evento, valida el formulario en el cliente y lanza una petición HTTP a la API.
2. La petición viaja por la red hasta el **servidor**.
3. El **back-end** (Express sobre Node) recibe la petición en un *endpoint*, ejecuta la lógica (autorización, validación) y opera sobre la base de datos (MongoDB) mediante una operación CRUD.
4. El servidor responde con un **código de estado** y datos en **JSON**.
5. El front-end recibe la respuesta y actualiza la vista **sin recargar** la página.

El front-end domina los pasos 1 y 5; el back-end, del 2 al 4; el full-stack entiende e implementa toda la cadena.

# Más allá del cliente y el servidor

Un desarrollador full-stack moderno suele rozar también el **DevOps**. No se le exige ser experto en todo, sino tener criterio para mover una funcionalidad de principio a fin.

> [!important]+ Clave de examen
> "Define desarrollador front-end, back-end y full-stack" se responde con tres ideas y un criterio:
> - **Front-end**: lado del **cliente** — lo que se ve, vistas, interacción, UX.
> - **Back-end**: lado del **servidor** — lógica, transacciones, datos, protocolos.
> - **Full-stack**: **ambos** lados — capaz de implementar y desplegar la aplicación entera.
> El criterio que los separa es **el lado de la arquitectura cliente-servidor** en el que actúa cada uno.

# Comparativa

| Perfil | Lado | Responsabilidad principal | En MERN |
| - | - | - | - |
| Front-end | Cliente | Vistas, interacción, UX | React.js |
| Back-end | Servidor | Lógica, transacciones, datos | Node.js · Express.js · MongoDB |
| Full-stack | Ambos | Aplicación completa y despliegue | Toda la pila MERN |

Este reparto enmarca el resto del temario: la [[La pila MERN|pila MERN]] asigna una tecnología a cada responsabilidad usando **JavaScript como lenguaje único** en cliente y servidor, lo que hace el perfil full-stack más alcanzable que en stacks con lenguajes distintos a cada lado.
