---
tags:
  - Full-Stack
  - Express
  - REST
  - Backend
Descripción: "REST (REpresentational State Transfer) es un estilo para el intercambio y la manipulación de datos en servicios de Internet, basado en HTTP. Los datos se devuelven en formatos…"
Fecha de actualización: 2026-06-22
Nota previa: "[[00-Express.js, framework y middleware]]"
Nota siguiente: "[[02-Rutas, manejadores y Express Router]]"
Area: "[[Express.js.base|Express.js]]"
---
---

<mark style="background: #ADCCFFA6;">REST (REpresentational State Transfer) es un estilo para el intercambio y la manipulación de datos en servicios de Internet, basado en HTTP.</mark> Los datos se devuelven en formatos estandarizados, normalmente **JSON** (o XML). Su simplicidad lo ha convertido en uno de los estilos más usados de Internet.

<mark style="background: #ADCCFFA6;">Una API REST es una librería de servicios REST: un conjunto de funcionalidades para intercambiar y manipular datos a través de Internet.</mark>

# Recursos, no servicios

En REST el concepto clave no es "servicio" sino **recurso**. <mark style="background: #8000E1A6;">El acceso a los recursos se realiza mediante URLs que los identifican bajo un esquema URI (Uniform Resource Identifier).</mark>

- `/users` identifica el recurso "colección de usuarios"; invocarlo devuelve su **representación** (el listado de usuarios).
- `/users/12` identifica un usuario concreto (ID 12).
- Entre recursos hay **relaciones**: un usuario pertenece a la colección, de ahí la jerarquía `/users/12`.

# Características de REST

- <mark style="background: #FFB8EBA6;">Se apoya en HTTP y sus métodos básicos (GET, POST, PUT, DELETE), que corresponden a las operaciones CRUD.</mark> → [[Operaciones CRUD, HTTP y SQL]]
- **Petición-respuesta**: el cliente crea una petición (*request*) con toda la información necesaria y espera una respuesta (*response*) concreta.
- **Sin estado** (*stateless*): cada petición es autónoma; el servidor no conserva estado de sesión entre peticiones.
- Todos los recursos se manipulan mediante **URIs**.
- Aporta **escalabilidad** y **separación entre cliente y servidor**.
- Es **independiente de plataforma y lenguaje**: se consume desde cualquier SO o lenguaje.

# Estructura de una URI

```text
{protocolo}://{dominio}[:puerto]/{ruta del recurso}?{consulta de filtrado}
```

Ejemplo: `https://api.example.com/users/12?activo=true`.

# APIs públicas y privadas

<mark style="background: #FFB86CA6;">Las APIs REST pueden ser públicas (consumibles por terceros) o privadas, y pueden requerir autenticación previa para acceder a sus recursos.</mark> → [[05-Seguridad de APIs REST (tokens y JWT)]]

Una arquitectura típica separa el **back-end** (la API REST con la lógica de negocio y el acceso a recursos) del **front-end** (independiente, que consume esa API). Es la base de la pila MERN: React consume la API REST de Express.

# Sin estado, en detalle

<mark style="background: #FFB86CA6;">Que REST sea *stateless* significa que cada petición debe contener toda la información necesaria para procesarse;</mark> el servidor no recuerda peticiones anteriores. La consecuencia práctica: la autenticación viaja en **cada** petición (p. ej. un token en la cabecera), no en una "sesión" guardada en el servidor. → [[05-Seguridad de APIs REST (tokens y JWT)]]

Ventaja: cualquier instancia del servidor puede atender cualquier petición, lo que facilita el **escalado horizontal** (balanceo entre varios servidores).

# REST frente a otras opciones

| Estilo | Característica |
| - | - |
| **REST** | Recursos vía HTTP, respuestas JSON; simple y muy extendido |
| **SOAP** | Protocolo rígido basado en XML; típico en entornos *enterprise* |
| **GraphQL** | Un único endpoint; el cliente pide exactamente los campos que necesita |

REST domina las APIs web públicas por su simplicidad y por apoyarse directamente en HTTP. GraphQL gana terreno cuando el cliente necesita controlar con precisión qué datos recibe.

> [!important]+ Para el examen
> **REST** = estilo de intercambio de datos sobre **HTTP**, con respuestas en **JSON/XML**. Manipula **recursos** identificados por **URIs**. Es **stateless**, independiente de plataforma, y mapea sus métodos (GET/POST/PUT/DELETE) a **CRUD**. Una **API REST** es el conjunto de servicios/recursos que expone un back-end.
