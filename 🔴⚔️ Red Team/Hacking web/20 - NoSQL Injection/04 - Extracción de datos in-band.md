---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[03 - Bypass de autenticación]]"
Nota siguiente: "[[05 - Extracción de datos ciega y automatización]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

Cuando la aplicación **refleja** los resultados de la consulta, la extracción in-band vuelca los documentos. Hay una diferencia importante con la [[05 - Inyección UNION|SQLi UNION-based]]: <mark style="background: #FFB8EBA6;">en MongoDB la extracción in-band se limita a la **colección consultada**</mark> —no hay un `UNION` sencillo que cruce colecciones—, así que para llegar a otras colecciones o campos hará falta la [[05 - Extracción de datos ciega y automatización|extracción ciega]] o [[06 - Server-Side JavaScript Injection|SSJI]].

# El buscador vulnerable (MangoSearch)

Un buscador envía `GET /index.php?q=<término>`, y el servidor filtra por ese valor:

```php
$collection->find(["name" => $_GET['q']]);
```

# Volcar la colección con `$regex`

Inyectando un `$regex` que casa cualquier cosa se devuelven todos los documentos:

```text
q[$regex]=.*
```

que produce `db.types.find({name: {$regex: ".*"}})` → toda la colección `types`.

# Consultas alternativas para el volcado

Igual que en el bypass, conviene tener varias por si `$regex` está filtrado:

```text
name: {$ne: "doesntExist"}   # todo lo que no sea un valor inexistente → todo
name: {$gt: ""}              # cualquier string es "mayor" que la cadena vacía
name: {$gte: ""}
name: {$lt: "~"}             # ~ es el ASCII imprimible más alto → casi todo es "menor"
name: {$lte: "~"}
```

<mark style="background: #FFB86CA6;">El truco de `~` (0x7E, mayor ASCII imprimible)</mark>: comparar contra él con `$lt`/`$lte` casa prácticamente cualquier nombre. En forma URL-encoded, `q[$lt]=~`.

> [!warning]+ La gran diferencia con SQLi
> No esperes un `UNION SELECT` que salte a la tabla `users` desde un buscador de productos. <mark style="background: #FF5582A6;">La inyección in-band en MongoDB solo devuelve documentos de la colección que la consulta ya interroga</mark>. Volcar otra colección (credenciales, sesiones) requiere que la app la consulte, o pasar a extracción ciega / SSJI. Es una limitación estructural del modelo documental, no una defensa.

Cuando la app **no** refleja los resultados —solo responde distinto—, se extrae bit a bit: [[05 - Extracción de datos ciega y automatización]].
