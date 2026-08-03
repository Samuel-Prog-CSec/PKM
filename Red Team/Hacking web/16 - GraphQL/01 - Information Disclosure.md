---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - GraphQL
Descripción: "El primer paso contra cualquier GraphQL es el reconocimiento: identificar el endpoint, el motor, y —sobre todo— obtener el esquema completo mediante introspección, que nos…"
Fecha de actualización: 2026-07-15
Nota previa: "[[00 - Introducción a GraphQL]]"
Nota siguiente: "[[02 - IDOR en GraphQL]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

El primer paso contra cualquier GraphQL es el **reconocimiento**: identificar el endpoint, el motor, y —sobre todo— <mark style="background: #FFB86CA6;">obtener el esquema completo mediante introspección</mark>, que nos regala el mapa de todo lo atacable.

# Identificar el endpoint y el motor

Navegando la app y mirando el tráfico, veremos peticiones a `/graphql` con queries GraphQL → confirma que hay GraphQL. Otros paths comunes: `/api/graphql`, `/v1/graphql`, `/query`, `/graphiql`.

Para identificar el **motor** (Graphene, Apollo, Hasura…) usamos <mark style="background: #ADCCFFA6;">`graphw00f`</mark>, que envía queries (incluidas malformadas) y deduce el motor por el comportamiento y los mensajes de error:

```shell-session
$ python3 main.py -d -f -t http://target
[!] Found GraphQL at http://target/graphql
[*] Discovered GraphQL Engine: (Graphene)
[!] Attack Surface Matrix: .../graphql-threat-matrix/.../graphene.md
[!] Technologies: Python
```

Conocer el motor importa: cada uno tiene su matriz de ataque en el <mark style="background: #FFB8EBA6;">**GraphQL Threat Matrix**</mark> (qué defensas trae por defecto, si permite batching, field suggestions, etc.). Además, accediendo a `/graphql` en el navegador a veces aparece la interfaz **GraphiQL**, mucho más cómoda para lanzar queries que Burp (no hay que pelearse con el JSON).

# Introspección: el esquema completo

<mark style="background: #ADCCFFA6;">La introspección es una feature de GraphQL que permite consultar la **estructura** del backend</mark> a través del campo `__schema`. Es la mina de oro del recon.

Todos los tipos:

```graphql
{ __schema { types { name } } }
```

Devuelve tipos por defecto (`Int`, `Boolean`) y los **personalizados** (`UserObject`, etc.). Los campos de un tipo concreto:

```graphql
{
  __type(name: "UserObject") {
    name
    fields { name type { name kind } }
  }
}
```

Aquí aparecen campos jugosos como `username` y `password` con sus tipos. Todas las queries soportadas:

```graphql
{ __schema { queryType { fields { name description } } } }
```

Y la query de introspección **completa** (dump total de tipos, campos, queries, mutations, directivas):

```graphql
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types { ...FullType }
    directives { name description locations args { ...InputValue } }
  }
}
fragment FullType on __Type {
  kind name description
  fields(includeDeprecated: true) {
    name description args { ...InputValue }
    type { ...TypeRef } isDeprecated deprecationReason
  }
  inputFields { ...InputValue }
  interfaces { ...TypeRef }
  enumValues(includeDeprecated: true) { name description isDeprecated deprecationReason }
  possibleTypes { ...TypeRef }
}
fragment InputValue on __InputValue { name description type { ...TypeRef } defaultValue }
fragment TypeRef on __Type { kind name ofType { kind name ofType { kind name } } }
```

El resultado es enorme, así que lo **visualizamos** con `GraphQL-Voyager`: pega el JSON de la introspección y obtienes un grafo navegable del esquema.

> [!warning]+ Hazlo con tu propia instancia
> El *GraphQL-Voyager* / *GraphQL Playground* públicos envían tu esquema a un tercero. En un engagement real, <mark style="background: #FF5582A6;">aloja las herramientas tú mismo</mark> para que ningún dato sensible del cliente salga de tu entorno.

# Cuando la introspección está deshabilitada

En producción, la introspección suele estar **desactivada** (buena práctica). Pero no estás ciego:

- <mark style="background: #FFB86CA6;">**`clairvoyance`**</mark>: reconstruye el esquema **sin** introspección, abusando de las *field suggestions* (mensajes de error tipo *"Did you mean 'password'?"*) que muchos motores dejan activas. Ver [[07 - Herramientas para GraphQL|Herramientas]].
- **Fuerza bruta de campos/queries** con wordlists (`graphql-wordlist`).
- **Field stuffing** y análisis de errores para inferir tipos.

Con el esquema en la mano, identificamos vectores concretos. El primero: [[02 - IDOR en GraphQL|IDOR]].

## Referencias

- [graphw00f](https://github.com/dolevf/graphw00f) · [GraphQL Threat Matrix](https://github.com/nicholasaleks/graphql-threat-matrix)
- [GraphQL-Voyager](https://github.com/graphql-kit/graphql-voyager) · [clairvoyance](https://github.com/nikitastupin/clairvoyance)
- PortSwigger — [Discovering GraphQL & introspection](https://portswigger.net/web-security/graphql)
- HTB Academy — *Attacking GraphQL* (base, 2024)
