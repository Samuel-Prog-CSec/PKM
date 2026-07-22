---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Introducción a NoSQL y MongoDB]]"
Nota siguiente: "[[02 - Detección de NoSQL injection]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

<mark style="background: #ADCCFFA6;">La NoSQL injection ocurre cuando la entrada del usuario llega a una consulta NoSQL sin sanitizar</mark>, permitiendo al atacante subvertir la lógica y forzar al servidor a devolver datos o ejecutar acciones no previstas. Como NoSQL no tiene un lenguaje estándar como SQL, <mark style="background: #FFB8EBA6;">el ataque adopta formas distintas según la implementación</mark> — aquí, MongoDB.

# El mecanismo: inyección de operadores

Esta es la diferencia esencial con la [[00 - Introducción a SQL Injection|SQLi]]: no se rompe una cadena con comillas, sino que <mark style="background: #FFB86CA6;">se inyecta un **operador** (un objeto) donde el código esperaba un valor</mark>. En una API que acepta JSON, en lugar de un string se envía un objeto `{"$operador": ...}`.

# Escenario Node.js / Express / MongoDB

Un endpoint que busca un usuario por su nombre:

```javascript
// POST /api/v1/getUser  — Input JSON: {"username": <username>}
const cursor = con.db("example").collection("users")
    .find({username: req.body['username']});   // ← entrada sin filtrar
```

Uso legítimo — devuelve un usuario:

```shell-session
$ curl -s -X POST http://target:3000/api/v1/getUser -H 'Content-Type: application/json' -d '{"username": "gerald1992"}'
```

<mark style="background: #FFB86CA6;">El problema: el servidor usa a ciegas lo que le mandemos como `username`</mark>. Si en vez de un string enviamos un operador `$regex` que casa cualquier cosa, la consulta se convierte en `db.users.find({username: {$regex: ".*"}})` y devuelve **todos** los usuarios:

```shell-session
$ curl -s -X POST http://target:3000/api/v1/getUser -H 'Content-Type: application/json' -d '{"username": {"$regex": ".*"}}'
[ {"username":"bmdyy","password":"f25a...","role":0,...}, {"username":"gerald1992",...} ]
```

> [!important]+ Por qué funciona
> El cuerpo JSON permite pasar un **objeto** donde el desarrollador asumía un **string**. El driver de MongoDB interpreta `{"$regex": ".*"}` como un operador, no como un nombre de usuario literal. <mark style="background: #8000E1A6;">Ese cambio de tipo (string → objeto/operador) es la raíz de casi toda la NoSQLi</mark> — y por eso las defensas que solo escapan caracteres (pensadas para SQLi) no sirven.

# Tipos de NoSQL injection

Las mismas clases que en SQLi:

| Tipo | Descripción |
| - | - |
| **In-Band** | El resultado vuelve por el mismo canal (el ejemplo de arriba). |
| **Blind** | No hay resultado directo; se infiere por la respuesta del servidor. |
| ↳ Boolean-based | Se fuerza al servidor a devolver una respuesta u otra según `True`/`False`. |
| ↳ Time-based | Se fuerza un retardo para inferir `True`/`False`. |

Antes de explotar, la metodología para reconocer y confirmar la inyección: [[02 - Detección de NoSQL injection]].
