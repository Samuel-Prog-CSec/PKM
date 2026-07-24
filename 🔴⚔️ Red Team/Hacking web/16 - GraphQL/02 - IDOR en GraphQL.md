---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
  - IDOR
Fecha de actualización: 2026-07-15
Nota previa: "[[01 - Information Disclosure]]"
Nota siguiente: "[[03 - Injection Attacks]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

La autorización rota —el [[06 - Introducción a IDOR|IDOR]] web, o [[01 - Broken Object Level Authorization (API1)|BOLA]] en el mundo API— es tan común en GraphQL como en REST. Y GraphQL lo agrava: además de acceder a **objetos** ajenos, la naturaleza de "pide los campos que quieras" permite <mark style="background: #FFB86CA6;">sacar campos sensibles que la UI nunca muestra</mark>.

# Identificar el IDOR

Enumerando la app, vemos que al abrir nuestro perfil se lanza una query que consulta por el `username` con el que hicimos login:

```graphql
{
  user(username: "htb-stdnt") {
    id
    username
  }
}
```

La app pide **automáticamente** nuestro usuario, pero ¿podemos pedir otro? Probamos con un username que sabemos que existe (`test`). La query GraphQL cruda es:

```graphql
{ user(username: "test") { id username } }
```

> [!warning]+ Escapar comillas en el cuerpo JSON
> Si la mandas dentro del JSON de la petición (por Burp/curl), las comillas dobles internas van **escapadas** para no romper el JSON: `{"query":"{ user(username: \"test\") { id username } }"}`. GraphiQL, en cambio, acepta la query cruda tal cual.

Devuelve los datos de `test` <mark style="background: #FF5582A6;">sin ninguna comprobación de autorización</mark> → IDOR confirmado. El resolver no valida que el `username` pedido sea el del usuario autenticado.

# Explotar: pedir los campos sensibles

Aquí entra la ventaja de GraphQL. Con la [[01 - Information Disclosure|introspección]] enumeramos los campos del tipo `UserObject`:

```graphql
{ __type(name: "UserObject") { fields { name type { name kind } } } }
```

Descubrimos un campo `password`. Simplemente **lo añadimos** a la query del IDOR:

```graphql
{
  user(username: "test") {
    username
    password
  }
}
```

Y obtenemos la contraseña del usuario `test`. <mark style="background: #8000E1A6;">Dos fallos combinados</mark>: falta de autorización a nivel de objeto (IDOR) + exposición de un campo que jamás debería ser consultable (`password`), que en el mundo API es [[03 - Broken Object Property Level Authorization (API3)|BOPLA/Excessive Data Exposure]].

# Matices propios de GraphQL

- <mark style="background: #FFB8EBA6;">**Autorización a nivel de campo**</mark>: en GraphQL cada campo y cada resolver necesita su control. Es fácil proteger la query `user` pero olvidar que un sub-campo (`author`, `orders`, `paymentMethod`) expone datos ajenos vía [[00 - Introducción a GraphQL|sub-querying]]. Recorre las relaciones anidadas buscando el eslabón sin control.
- **Enumeración masiva con aliases**: GraphQL permite pedir el mismo campo varias veces con **alias** distintos, enumerando muchos objetos en **una sola** petición:

```graphql
{
  u1: user(username: "admin") { username password }
  u2: user(username: "test")  { username password }
  u3: user(username: "root")  { username password }
}
```

Esto exfiltra en masa y de paso **evade rate-limiting/brute-force** basados en "1 intento por petición" — la base del [[04 - Denegación de servicio (DoS) y Batching|batching]].
- **IDs vs identificadores**: prueba con `id` numérico, `username`, `email`, `uuid` — cualquier argumento que sirva de referencia directa.

> [!tip]+ Metodología (idéntica al IDOR web)
> La caza es la misma de [[12 - Detección, evasión y prevención de IDOR|dos cuentas]]: con dos usuarios, repite las queries de uno con la sesión del otro. Herramientas como Autorize funcionan sobre GraphQL igual que sobre REST, ya que al final es HTTP. La diferencia es que aquí, además, **añades campos** que revelan más de lo previsto.

Siguiente: [[03 - Injection Attacks|Injection Attacks]], donde los resolvers mal construidos abren la puerta a SQLi y command injection.

## Referencias

- PortSwigger — [Bypassing GraphQL authorization / IDOR](https://portswigger.net/web-security/graphql)
- HackTricks — [GraphQL](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql)
- HTB Academy — *Attacking GraphQL* (base, 2024)
