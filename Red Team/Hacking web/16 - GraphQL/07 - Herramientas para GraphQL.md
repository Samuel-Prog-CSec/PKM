---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - GraphQL
Descripción: "Arsenal para atacar GraphQL, por fase. El flujo es: fingerprint → esquema → auditoría de config → explotación"
Fecha de actualización: 2026-07-15
Nota previa: "[[06 - Detección, evasión y prevención de GraphQL]]"
Nota siguiente: ""
Area: "[[GraphQL.base|GraphQL]]"
---
---

Arsenal para atacar GraphQL, por fase. El flujo es: **fingerprint → esquema → auditoría de config → explotación**. Cierra el módulo [[00 - Introducción a GraphQL|Attacking GraphQL]].

# Reconocimiento y esquema

| Herramienta | Uso |
| - | - |
| <mark style="background: #ADCCFFA6;">**graphw00f**</mark> | Fingerprint del **motor** (Graphene, Apollo, Hasura…) por comportamiento y errores; localiza el endpoint |
| **GraphQL-Voyager** | **Visualiza** el esquema (grafo navegable) desde el JSON de [[01 - Information Disclosure|introspección]]; revela loops para [[04 - Denegación de servicio (DoS) y Batching\|DoS]] |
| <mark style="background: #FFB86CA6;">**clairvoyance**</mark> | Reconstruye el esquema **sin introspección**, abusando de las *field suggestions* |
| **GraphQL Threat Matrix** | Referencia: defensas por defecto y superficie de cada motor |

```shell-session
$ python3 graphw00f/main.py -d -f -t http://target        # fingerprint + detect endpoint
$ python3 -m clairvoyance -w wordlist.txt -o schema.json http://target/graphql   # esquema sin introspección
```

# Auditoría de configuración

<mark style="background: #ADCCFFA6;">**graphql-cop**</mark> — audita rápido las malas configuraciones (introspección, batching, aliases, field suggestions, CSRF por GET/url-encoded). Línea base antes del testing manual:

```shell-session
$ python3 graphql-cop.py -t http://target/graphql
[HIGH] Introspection - Introspection Query Enabled
[HIGH] Array-based Query Batching - Batch queries allowed
[MEDIUM] GET Method Query Support - possible CSRF
...
```

# Explotación (Burp y CLI)

- <mark style="background: #FFB86CA6;">**InQL**</mark> (extensión de Burp, BApp Store): añade pestañas GraphQL en Proxy/Repeater para **editar queries sin pelearte con el JSON**, ejecuta la introspección y genera automáticamente todas las queries/mutations del host. La herramienta central en un workflow con Burp.
- **graphqlmap**: cliente interactivo para **explotar inyecciones** (SQLi, NoSQLi) a través de argumentos GraphQL, semiautomatizando el [[03 - Injection Attacks|UNION/dump]].
- **CrackQL**: brute-force y *password spraying* abusando de [[04 - Denegación de servicio (DoS) y Batching|batching/aliasing]] — miles de intentos por petición para saltar rate-limits.
- **Clientes**: GraphiQL, Altair, GraphQL Playground para lanzar queries cómodamente (mejor auto-hospedados que los públicos, para no filtrar el esquema del cliente).

# Flujo recomendado

> [!tip]+ De cero a explotación
> 1. **Fingerprint**: `graphw00f` → motor + endpoint. 2. **Config**: `graphql-cop` → checklist de misconfigs. 3. **Esquema**: introspección (o `clairvoyance` si está off) → `GraphQL-Voyager` para verlo. 4. **Setup**: InQL en Burp para navegar queries/mutations. 5. **Explotar**: IDOR (swap de argumentos + campos sensibles), inyección (`graphqlmap`), privesc por [[05 - Mutations|mutations]] (`role: admin`), brute-force (`CrackQL` con batching). 6. **Reportar** mapeando a la [[06 - Detección, evasión y prevención de GraphQL|superficie GraphQL]].

Con esto cerramos **Attacking GraphQL**. Como API que es, comparte el corazón del [[00 - Introducción a las API Attacks|pentest de APIs]]: autorización rota (IDOR/BOLA), mass assignment (mutations) y bypass de rate-limit (batching).

## Referencias

- [graphw00f](https://github.com/dolevf/graphw00f) · [graphql-cop](https://github.com/dolevf/graphql-cop) · [clairvoyance](https://github.com/nikitastupin/clairvoyance)
- [InQL](https://github.com/doyensec/inql) · [graphqlmap](https://github.com/swisskyrepo/GraphQLmap) · [CrackQL](https://github.com/nicholasaleks/CrackQL)
- [GraphQL-Voyager](https://github.com/graphql-kit/graphql-voyager) · [GraphQL Threat Matrix](https://github.com/nicholasaleks/graphql-threat-matrix)
- OWASP — [GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
