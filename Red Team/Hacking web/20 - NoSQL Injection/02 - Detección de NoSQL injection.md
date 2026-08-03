---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Enumeracion
  - Tipo/Deteccion
Descripción: "Antes de explotar hay que reconocer que el backend es NoSQL (MongoDB) y confirmar la inyección de operadores"
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Introducción a la NoSQL injection]]"
Nota siguiente: "[[03 - Bypass de autenticación]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

Antes de explotar hay que <mark style="background: #ADCCFFA6;">reconocer que el backend es NoSQL (MongoDB) y confirmar la inyección de operadores</mark>. En stacks modernos (Node/Express, PHP, Python) es más frecuente de lo que se cree, precisamente porque las defensas pensadas para SQLi no aplican. Sistematizamos igual que en la [[01 - Detección de XPath Injection|detección de XPath]] y [[01 - Detección de LDAP Injection|LDAP]].

# Reconocer un backend NoSQL/MongoDB

- **Stack**: Node.js/Express + MongoDB (MEAN/MERN), PHP con el driver de MongoDB, Python con PyMongo. APIs que hablan JSON.
- **Mensajes de error** que delatan el motor: `MongoError`, `CastError`, errores de `BSON`, o quejas sobre operadores `$`.
- **Comportamiento**: endpoints que reciben JSON, o formularios cuyos parámetros alimentan búsquedas/filtros/logins.

# Superficie de inyección

Cualquier valor que llegue a un `find()`/`findOne()`: login (email/password), buscadores, filtros, parámetros de API. <mark style="background: #FF5582A6;">Y no solo cuerpos JSON</mark> — también parámetros `x-www-form-urlencoded` mediante la [[03 - Bypass de autenticación|notación de corchetes]] `param[$op]=val`.

# Confirmar la inyección

La prueba definitiva es meter un **operador** donde se espera un valor y ver si cambia el comportamiento:

| Sonda | En JSON | En URL-encoded |
| - | - | - |
| Operador `$ne` | `{"user": {"$ne": null}}` | `user[$ne]=x` |
| Booleano verdadero/falso | `{"$gt": ""}` vs `{"$eq": "nope"}` | `p[$gt]=` vs `p[$eq]=nope` |
| Romper la consulta | `'`, `"`, `{`, `}`, `\`, `;` | idem | 

<mark style="background: #FFB86CA6;">Si `user[$ne]=x` autentica o devuelve más resultados que `user=x`, hay NoSQLi</mark>. Un error de `BSON`/`MongoError` al meter `{` o `"` es otra señal directa.

# Fingerprinting: NoSQLi vs SQLi

La diferencia esencial es el **tipo** de inyección: la SQLi rompe cadenas; la NoSQLi confunde tipos (string → objeto/operador):

| Prueba | SQLi | NoSQLi (Mongo) |
| - | - | - |
| `'` rompe / error de sintaxis | ✅ | a veces (BSON) |
| `-- ` comentario, `UNION SELECT` | ✅ | ❌ |
| `param[$ne]=` cambia el resultado | ❌ | ✅ |
| `{"$gt":""}` como valor | ❌ | ✅ |

Confirmar con inyección de operadores (`$ne`, `$gt`, `$regex`) descarta SQLi y fija el vector — mismo criterio que el resto de la [[00 - Introducción a XPath Injection|familia de inyecciones]].

> [!info]+ WAF y realidad en 2026
> <mark style="background: #8000E1A6;">Muchos WAF modernos ya detectan patrones `$ne`/`$gt`/`$where`</mark> en cuerpos JSON, pero la inyección vía notación de corchetes, JSON anidado o *type juggling* suele evadirlos (ver [[07 - Evasión de filtros y WAF en NoSQL|evasión]]). Frameworks como Mongoose mitigan algo con *schema casting*, pero un `find()` con objetos crudos sigue siendo vulnerable. Es un bug muy vivo en APIs Node/Express actuales.

> [!info]+ Fuentes
> [PortSwigger — NoSQL injection](https://portswigger.net/web-security/nosql-injection) · [OWASP WSTG — Testing for NoSQL Injection](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/05.6-Testing_for_NoSQL_Injection) · [HackTricks — NoSQL injection](https://book.hacktricks.wiki/en/pentesting-web/nosql-injection.html) · [PayloadsAllTheThings — NoSQL Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/NoSQL%20Injection/).

Confirmada la inyección, el primer objetivo práctico es el bypass de autenticación: [[03 - Bypass de autenticación]].
