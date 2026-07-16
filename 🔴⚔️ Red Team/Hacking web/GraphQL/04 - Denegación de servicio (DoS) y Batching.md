---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
Fecha de actualización: 2026-07-15
Nota previa: "[[03 - Injection Attacks]]"
Nota siguiente: "[[05 - Mutations]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

Dos ataques propios del modelo GraphQL: consultas que **amplifican** el trabajo del servidor hasta el `DoS`, y el **batching**, que permite meter muchas operaciones en una petición y así <mark style="background: #FFB86CA6;">saltarse rate-limits y anti-brute-force</mark>.

# Denial-of-Service por consultas anidadas

El esquema suele tener **ciclos**: `UserObject` referencia `PostObject` (campo `posts`) y `PostObject` referencia `UserObject` (campo `author`). Se ve claro en [[01 - Information Disclosure|GraphQL Voyager]]. <mark style="background: #ADCCFFA6;">Ese ciclo se puede recorrer en bucle en una sola query</mark>, y cada iteración multiplica el tamaño de la respuesta:

```graphql
{
  posts {
    author {
      posts {
        edges { node { author { username } } }
      }
    }
  }
}
```

(`posts` es una *connection*, de ahí `edges`/`node`). Repitiendo el bucle muchas veces, la respuesta crece **exponencialmente** y satura CPU/memoria del backend. Una query suficientemente profunda <mark style="background: #FF5582A6;">tumba la instancia</mark> — GraphiQL mismo se cuelga.

> [!warning]+ Prueba de DoS con cuidado
> En un engagement real, un DoS real es **destructivo** y normalmente **fuera de alcance**. Demuestra el problema con una profundidad **moderada** que muestre el crecimiento exponencial del tiempo de respuesta/tamaño, sin tumbar producción. El hallazgo es "falta de límite de profundidad/complejidad", no "he tirado el servidor".

# Batching

El **batching** ejecuta varias queries en **una** petición HTTP, enviando una **lista JSON** de queries:

```http
POST /graphql HTTP/1.1
Content-Type: application/json

[
  { "query": "{ user(username: \"admin\") { uuid } }" },
  { "query": "{ post(id: 1) { title } }" }
]
```

El batching **no es** una vulnerabilidad en sí (es una feature que se activa/desactiva). Pero se vuelve peligroso cuando las queries hacen procesos sensibles como **login**: <mark style="background: #8000E1A6;">permite meter miles de intentos en una sola petición HTTP, evadiendo los rate-limits</mark> que cuentan "por petición".

Ejemplo: un endpoint con límite de **5 peticiones/segundo**. Brute-force normal = 5 contraseñas/seg. Pero metiendo **1000** queries de login en cada petición HTTP → **5000 contraseñas/seg**. El rate-limit se vuelve inútil.

## Aliasing: batching dentro de una query

El mismo efecto se logra con **alias** (repetir un campo con nombres distintos en una sola query), útil cuando el batching por lista está deshabilitado:

```graphql
{
  a: login(user: "admin", password: "123456")  { success }
  b: login(user: "admin", password: "password") { success }
  c: login(user: "admin", password: "qwerty")   { success }
}
```

> [!warning]+ `login` suele ser una mutation
> Si el esquema define `login` como **mutation** (lo habitual para acciones con efecto), envuélvelo en `mutation { a: login... }`. Matiz de rendimiento: las **mutations** aliaseadas se ejecutan **en serie**, no en paralelo como las queries. El bypass de rate-limit sigue funcionando igual (muchos intentos en **una** petición HTTP), pero no ganas paralelismo real.

<mark style="background: #FFB86CA6;">Batching y aliasing son la razón por la que la Web Security Academy de PortSwigger los señala como vector estrella</mark> para brute-force de credenciales y **bypass de 2FA/OTP**: miles de códigos OTP probados en pocas peticiones. Es el equivalente GraphQL del [[11 - Detección y evasión en APIs|bypass de rate-limit por bulk endpoints]] en REST, y enlaza con el [[00 - Introducción al brute forcing|brute forcing]].

# Prevención

- **Límite de profundidad y complejidad** de las queries (query depth/cost analysis) — mata el DoS por anidamiento.
- **Deshabilitar o limitar el batching**, y limitar el número de alias/operaciones por petición.
- **Rate-limiting por operación**, no por petición HTTP (contar cada login dentro del batch).
- **Timeouts** y paginación obligatoria en connections.

Siguiente: [[05 - Mutations|Mutations]], donde no solo leemos sino que **modificamos** datos.

## Referencias

- PortSwigger — [GraphQL: bypassing rate limiting with aliases](https://portswigger.net/web-security/graphql/what-is-graphql#bypassing-rate-limiting-using-aliases)
- OWASP — [GraphQL Cheat Sheet — DoS](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- [graphql-cop](https://github.com/dolevf/graphql-cop) (audita batching/introspección/profundidad)
- HTB Academy — *Attacking GraphQL* (base, 2024)
