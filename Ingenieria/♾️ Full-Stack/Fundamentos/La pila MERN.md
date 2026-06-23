---
tags:
  - Full-Stack
  - MERN
  - Introduccion
Fecha de actualización: 2026-06-22
Nota previa: "[[Patrones de diseño web (MVC y SPA)]]"
Nota siguiente: "[[Operaciones CRUD, HTTP y SQL]]"
Area: "[[Fundamentos.base|Fundamentos]]"
---
---

<mark style="background: #ADCCFFA6;">MERN es un stack de desarrollo web full-stack formado por cuatro tecnologías: MongoDB, Express.js, React.js y Node.js</mark> —sus iniciales forman el acrónimo—. Su rasgo definitorio: <mark style="background: #8000E1A6;">permite desarrollar la aplicación completa usando JavaScript como lenguaje único, en el cliente y en el servidor.</mark>

# Las cuatro piezas

- **MongoDB** — base de datos NoSQL orientada a documentos. Alternativa a las relacionales: en lugar de registros y tablas, guarda **documentos BSON** (representación binaria de JSON). Ventajas: escalabilidad, rapidez y eficiencia con grandes volúmenes de datos. → [[MongoDB y el modelo NoSQL documental]]
- **Express.js** — framework ligero para Node.js. Provee la infraestructura de **enrutamiento**, sesiones, cookies, etc. Montar una API REST con Express es rápido y sencillo. → [[Express.js, framework y middleware]]
- **React.js** — librería front-end de código abierto creada y mantenida por Facebook. Construye interfaces en una sola página mediante **componentes**. Su **Virtual DOM** hace que solo se rerendericen las partes que cambian, mejorando la eficiencia. → [[React.js, SPA y Virtual DOM]]
- **Node.js** — entorno de ejecución de JavaScript del lado del servidor, con un modelo **asíncrono y dirigido por eventos**. Destaca por su manejo de E/S, rapidez, soporte de protocolos web y escalabilidad en número de conexiones. Su gestor de paquetes **npm** da acceso a un enorme ecosistema; de hecho, Express y React se distribuyen como paquetes npm. → [[Node.js, entorno de ejecución del servidor]]

# Cómo se reparten en la arquitectura

| Pieza | Lado | Rol en la aplicación |
| - | - | - |
| React.js | Cliente (front-end) | Interfaz de usuario (SPA) |
| Node.js | Servidor (back-end) | Entorno de ejecución de JS |
| Express.js | Servidor (back-end) | Framework web / API REST |
| MongoDB | Servidor (datos) | Almacenamiento documental |

<mark style="background: #FFB8EBA6;">El cliente (React) y el servidor (Node + Express + MongoDB) se implementan como aplicaciones independientes</mark> que se comunican por HTTP intercambiando JSON. Es la materialización del modelo [[Patrones de diseño web (MVC y SPA)|SPA + API]] del apartado anterior.

# MERN frente a otros stacks

<mark style="background: #ADCCFFA6;">MEAN es un stack equivalente que usa Angular en lugar de React</mark> para el front-end. Existen otras combinaciones (MEVN con Vue, etc.). La popularidad de JavaScript y de React, sobre la base sólida de MongoDB, Express y Node, hace de MERN uno de los stacks más demandados y atractivos.

# Por qué un solo lenguaje

La gran ventaja de MERN es usar **JavaScript de extremo a extremo**: el mismo lenguaje en el navegador (React), en el servidor (Node + Express) y en el formato de datos (MongoDB habla JSON/BSON). Esto permite:

- **Reutilizar código** y modelos de datos entre cliente y servidor.
- **Compartir formato**: los datos viajan como JSON por toda la pila, sin traducciones entre lenguajes.
- **Un único ecosistema** de paquetes (npm) y un solo conjunto de herramientas.

# Stacks equivalentes

| Stack | Front-end | Back-end + datos |
| - | - | - |
| **MERN** | React | MongoDB + Express + Node |
| **MEAN** | Angular | MongoDB + Express + Node |
| **MEVN** | Vue | MongoDB + Express + Node |

Los tres comparten **MongoDB + Express + Node**; solo cambia la librería/framework de front-end. La base "JavaScript en todo" es la seña de identidad común.

# El proyecto guía

El libro construye con MERN una aplicación de **microblogging** (usuarios que publican *posts*): React para la interfaz, Express para la API REST, MongoDB para almacenar usuarios y posts, y Node como entorno de ejecución. Es el hilo conductor que conecta todas las piezas del temario.

> [!important]+ Para el examen
> **MERN** = **M**ongoDB + **E**xpress.js + **R**eact.js + **N**ode.js. Front-end: **React**. Back-end: **Node + Express**. Datos: **MongoDB**. Lenguaje común: **JavaScript** en cliente y servidor. Diferencia con **MEAN**: Angular sustituye a React.
