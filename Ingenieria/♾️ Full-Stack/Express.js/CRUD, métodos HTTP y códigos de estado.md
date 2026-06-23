---
tags:
  - Full-Stack
  - Express
  - HTTP
  - REST
Fecha de actualización: 2026-06-22
Nota previa: "[[Rutas, manejadores y Express Router]]"
Nota siguiente: "[[Mongoose y el patrón ODM en Express]]"
Area: "[[Express.js.base|Express.js]]"
---
---

Cómo se traducen las operaciones [[Operaciones CRUD, HTTP y SQL|CRUD]] a métodos HTTP en una API REST con Express, y qué **código de estado** devolver en cada respuesta.

# Métodos HTTP y CRUD

- <mark style="background: #ADCCFFA6;">**GET** — lee o consulta un recurso (análogo a READ).</mark>
- **POST** — crea un nuevo recurso con la información del cliente (CREATE).
- **PUT** — actualiza un recurso por completo (UPDATE).
- **DELETE** — elimina un recurso (DELETE).
- **PATCH** — edita partes concretas de un recurso (actualización parcial); el menos usado.

Para un recurso `posts`:

| Método | URL | Acción |
| - | - | - |
| GET | `/posts` | Listar todos los posts |
| POST | `/posts` | Crear un post |
| GET | `/posts/123` | Detalle de un post |
| PUT | `/posts/123` | Reemplazar el post entero |
| PATCH | `/posts/123` | Modificar parte del post |
| DELETE | `/posts/123` | Eliminar el post |

<mark style="background: #FFB8EBA6;">La misma URL (`/posts/123`) sirve para leer, actualizar o borrar; lo que cambia es el método HTTP.</mark> Es la idea central del diseño RESTful.

# Códigos de estado

<mark style="background: #FF5582A6;">Cada respuesta debe devolver el código de estado HTTP adecuado al resultado de la operación.</mark> Un código incorrecto hace el back-end difícil de depurar y mantener. Se agrupan en cinco clases:

| Clase | Significado | Ejemplos |
| - | - | - |
| **1xx** | Informativo | 100 Continue · 101 Switching Protocols |
| **2xx** | Éxito | 200 OK · 201 Created · 204 No Content |
| **3xx** | Redirección | 301 Moved Permanently · 302 Found · 304 Not Modified |
| **4xx** | Error del **cliente** | 400 Bad Request · 401 Unauthorized · 403 Forbidden · 404 Not Found · 405 Method Not Allowed · 406 Not Acceptable · 409 Conflict |
| **5xx** | Error del **servidor** | 500 Internal Server Error · 502 Bad Gateway · 503 Service Unavailable |

> [!warning]+ El código debe coincidir con el contenido
> Devolver `200 OK` con un cuerpo que en realidad describe un error es un fallo de diseño. Si falta un dato de entrada, lo correcto es `400 Bad Request`:
> ```http
> PUT /posts/123
>
> HTTP/1.1 400 Bad Request
> { "message": "se debe especificar un id de usuario para el post" }
> ```

# Negociación de formato (*content negotiation*)

<mark style="background: #ADCCFFA6;">HTTP permite al cliente indicar en qué formato quiere el recurso mediante la cabecera `Accept`</mark>, con varios formatos en orden de preferencia. El servidor responde con la cabecera `Content-Type` indicando el formato elegido; si no puede satisfacer ninguno, devuelve `406 Not Acceptable`.

```http
GET /posts/123
Accept: application/epub+zip, application/pdf, application/json

HTTP/1.1 200 OK
Content-Type: application/pdf
```

# Códigos que conviene memorizar

Los más probables en un test, con su escenario típico:

| Código | Cuándo se devuelve |
| - | - |
| **200** OK | GET/PUT correcto, con cuerpo de respuesta |
| **201** Created | POST que crea un recurso |
| **204** No Content | DELETE correcto, sin cuerpo |
| **400** Bad Request | Datos de entrada inválidos o ausentes |
| **401** Unauthorized | Falta autenticación (no identificado) |
| **403** Forbidden | Autenticado, pero sin permiso |
| **404** Not Found | El recurso no existe |
| **409** Conflict | Conflicto de estado (p. ej. email ya registrado) |
| **500** Internal Server Error | Fallo no controlado en el servidor |

<mark style="background: #FFB8EBA6;">401 vs 403: 401 es "no sé quién eres" (falta autenticación); 403 es "sé quién eres, pero no puedes" (falta autorización).</mark> Es una distinción clásica de examen.

> [!important]+ Para el examen
> Métodos ↔ CRUD: **GET = Read, POST = Create, PUT = Update (total), PATCH = update parcial, DELETE = Delete**. Códigos clave: **200** OK, **201** Created, **204** No Content, **400** Bad Request, **401** Unauthorized, **403** Forbidden, **404** Not Found, **500** Internal Server Error. Clases: 2xx éxito, 3xx redirección, **4xx error de cliente**, **5xx error de servidor**. Negociación de formato: `Accept` (petición) / `Content-Type` (respuesta); si no se puede servir → **406**.
