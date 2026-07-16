---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
Fecha de actualización: 2026-07-15
Nota previa: ""
Nota siguiente: "[[01 - Information Disclosure]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

<mark style="background: #ADCCFFA6;">`GraphQL` es un lenguaje de consulta para APIs, alternativa a [[00 - Introducción a las API Attacks|REST]]</mark>. El cliente pide **exactamente** los datos que necesita con una sintaxis simple, evitando el *over-fetching*/*under-fetching* de REST. Como REST, puede leer, actualizar, crear y borrar datos — pero con una diferencia clave para el atacante: <mark style="background: #FFB86CA6;">toda la API vive en un **único endpoint**</mark> (normalmente `/graphql` o `/api/graphql`) que atiende todas las consultas.

# Cómo se consulta

Una query selecciona **campos de objetos**. El nombre de la query va en la raíz. Para pedir `id`, `username` y `role` de todos los `User`:

```graphql
{
  users {
    id
    username
    role
  }
}
```

La respuesta refleja la misma estructura:

```json
{
  "data": {
    "users": [
      { "id": 1, "username": "htb-stdnt", "role": "user" },
      { "id": 2, "username": "admin", "role": "admin" }
    ]
  }
}
```

## Argumentos

Si la query soporta argumentos, filtramos. Y aquí empieza el interés ofensivo: <mark style="background: #FF5582A6;">podemos **añadir campos** que la UI no pide, como `password`</mark>:

```graphql
{
  users(username: "admin") {
    id
    username
    password
  }
}
```

## Sub-querying

Una query puede recorrer objetos relacionados. Si `posts` devuelve un `author` (un `User`), anidamos:

```graphql
{
  posts {
    title
    author {
      username
      role
    }
  }
}
```

<mark style="background: #8000E1A6;">Esta capacidad de pedir campos arbitrarios y recorrer relaciones es justo lo que convierte GraphQL en un terreno fértil</mark>: si el backend no controla qué campos puede ver cada usuario, pedimos los sensibles directamente.

# Por qué GraphQL es un objetivo caliente

GraphQL creció enormemente (Facebook, GitHub, Shopify, Twitter/X) y su modelo tiene implicaciones de seguridad propias que no existen en REST:

- <mark style="background: #FFB8EBA6;">**Introspección**</mark>: la API puede describir su propio esquema completo, regalando el mapa de ataque ([[01 - Information Disclosure|Information Disclosure]]).
- **Autorización a nivel de campo**: cada campo/objeto necesita su control; es fácil olvidar uno → [[02 - IDOR en GraphQL|IDOR]].
- **Endpoint único = WAF ciego**: las reglas WAF por URL/parámetro no ven el interior de la query.
- **Batching y aliasing**: permiten amplificar peticiones → [[04 - Denegación de servicio (DoS) y Batching|DoS]] y bypass de rate-limit/brute-force (documentado por PortSwigger).
- Toda inyección clásica sigue viva si los resolvers construyen consultas/comandos con la entrada ([[03 - Injection Attacks|Injection]]).

Este módulo (actualizado por HTB en 2024) recorre recon/introspección, IDOR, inyección, DoS/batching y mutations, y cierra con [[06 - Detección, evasión y prevención de GraphQL|detección/evasión]] y [[07 - Herramientas para GraphQL|herramientas]]. Empezamos por el reconocimiento: [[01 - Information Disclosure|Information Disclosure]].

## Referencias

- [GraphQL — Learn](https://graphql.org/learn/) (documentación oficial)
- PortSwigger — [GraphQL API vulnerabilities](https://portswigger.net/web-security/graphql)
- OWASP — [GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- HTB Academy — *Attacking GraphQL* (base, 2024)
