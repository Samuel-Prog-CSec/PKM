---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
Descripción: "GraphQL es solo una capa de consulta: si los resolvers construyen consultas SQL, comandos o HTML con los argumentos sin sanear, las inyecciones clásicas siguen vivas"
Fecha de actualización: 2026-07-15
Nota previa: "[[02 - IDOR en GraphQL]]"
Nota siguiente: "[[04 - Denegación de servicio (DoS) y Batching]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

GraphQL es solo una capa de consulta: <mark style="background: #ADCCFFA6;">si los resolvers construyen consultas SQL, comandos o HTML con los argumentos sin sanear, las inyecciones clásicas siguen vivas</mark>. El punto de inyección son los **argumentos** de las queries, que enumeramos con la [[01 - Information Disclosure|introspección]].

# SQL Injection

Como GraphQL suele leer de una base de datos SQL, un argumento mal saneado abre [[00 - Introducción a SQL Injection|SQLi]]. Con la introspección identificamos queries que aceptan argumentos: `post`, `user`, `postByAuthor`.

> [!tip]+ Descubrir el nombre del argumento por el error
> Si no sabes qué argumento espera una query, **mándala sin argumentos**: el error te lo dice (*"the postByAuthor query requires the author argument"*). Los errores de GraphQL son muy verbosos — úsalos como oráculo.

Probamos el argumento `username` de la query `user` con una comilla simple. El error SQL confirma la inyección:

```graphql
{ user(username: "x'") { username } }
```

Como el error muestra la consulta SQL, montamos una [[05 - Inyección UNION|inyección UNION]]. En este lab el tipo `UserObject` expone **6 campos** y la tabla subyacente tiene justo 6 columnas, así que el `UNION SELECT` necesita 6 — pero <mark style="background: #FFB86CA6;">esa coincidencia es del laboratorio, no una regla</mark>: el resolver puede hacer `SELECT *` sobre una tabla con más columnas que campos GraphQL, o exponer campos calculados. En un target real, determina el número de columnas con el método estándar (`ORDER BY N` incremental hasta el error, o padding con `NULL`), no contando campos del esquema. <mark style="background: #FFB8EBA6;">El campo que pides en la query GraphQL determina qué columna del UNION se refleja</mark>: `username` es el 3º campo → la 3ª columna del UNION aparece en la respuesta. Como GraphQL solo devuelve la primera fila, usamos `GROUP_CONCAT` para sacar varias a la vez:

```graphql
{
  user(username: "x' UNION SELECT 1,2,GROUP_CONCAT(table_name),4,5,6 FROM information_schema.tables WHERE table_schema=database()-- -") {
    username
  }
}
```

La respuesta trae las tablas concatenadas en `username`:

```json
{ "data": { "user": { "username": "user,secret,post" } } }
```

<mark style="background: #FF5582A6;">A partir de aquí es SQLi normal</mark>: enumera columnas y exfiltra. Y lo importante: <mark style="background: #8000E1A6;">la base de datos puede contener datos que la API GraphQL no expone</mark> (la tabla `secret`), así que la SQLi te da más que el propio esquema GraphQL. Todo el arsenal de [[01 - Detección de SQL Injection|SQL Injection]] y [[01 - Introducción a Blind SQL Injection|Blind SQLi]] aplica.

# Cross-Site Scripting (XSS)

El [[00 - Introducción a XSS|XSS]] aparece si la respuesta GraphQL se inserta en el HTML sin sanear, o si un argumento inválido se **refleja en un mensaje de error** sin codificar. La query `post` espera un `id` entero; si mandamos un string con un payload XSS, se refleja sin codificar en el error:

```graphql
{ post(id: "<script>alert(1)</script>") { title } }
```

Pero reflejarse en el JSON de error **no** significa XSS explotable: el `Content-Type` es `application/json` y el navegador no ejecuta el script. Para que sea XSS real, ese valor debe acabar **renderizado como HTML** en alguna página (p. ej. si el front pinta el mensaje de error en el DOM). <mark style="background: #FFB8EBA6;">Verifica siempre el sink final</mark> antes de cantar el hallazgo — en el lab, acceder a `/post?id=<script>...` solo rompe la página, no dispara el XSS.

> [!warning]+ Otras inyecciones
> El mismo principio aplica a [[00 - Introducción a Command Injection|command injection]], [[00 - Motores de plantillas e introducción a SSTI|SSTI]], [[00 - Introducción a los ataques server-side|SSRF]] y NoSQLi: cualquier argumento que llegue a un sink peligroso. GraphQL no añade defensa mágica; solo cambia el envoltorio. Enumera **todos** los argumentos de **todas** las queries y mutations.

Siguiente: [[04 - Denegación de servicio (DoS) y Batching|DoS y Batching]], ataques propios del modelo GraphQL.

## Referencias

- PortSwigger — [GraphQL injection](https://portswigger.net/web-security/graphql)
- OWASP — [GraphQL Cheat Sheet — Injection](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- HTB Academy — *Attacking GraphQL* (base, 2024)
