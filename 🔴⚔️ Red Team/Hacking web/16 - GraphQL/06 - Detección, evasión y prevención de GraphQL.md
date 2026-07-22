---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - GraphQL
Fecha de actualización: 2026-07-15
Nota previa: "[[05 - Mutations]]"
Nota siguiente: "[[07 - Herramientas para GraphQL]]"
Area: "[[GraphQL.base|GraphQL]]"
---
---

Nota dedicada a **detectar** de forma sistemática las malas configuraciones de un GraphQL, **evadir** las defensas (introspección deshabilitada, filtros), y **prevenir**. GraphQL tiene una superficie de misconfiguración muy concreta, y una auditoría rápida la mapea entera.

# Detección: el checklist de misconfiguración

`graphql-cop` audita la configuración de seguridad de un endpoint y da la línea base. Su salida es, en la práctica, el **checklist** de lo que hay que revisar:

```text
[HIGH]   Alias Overloading - 100+ aliases permitidos (DoS)
[HIGH]   Array-based Query Batching - batching permitido (DoS / brute-force)
[HIGH]   Directive Overloading - directivas duplicadas permitidas (DoS)
[HIGH]   Field Duplication - 500 campos repetidos permitidos (DoS)
[LOW]    Field Suggestions - habilitadas (Information Leakage)
[MEDIUM] GET Method Query Support - queries por GET (posible CSRF)
[LOW]    GraphQL IDE - GraphiQL/Playground habilitado (Information Leakage)
[HIGH]   Introspection - introspección habilitada (Information Leakage)
[MEDIUM] POST url-encoded query - acepta no-JSON por POST (posible CSRF)
```

Cada línea es un vector: <mark style="background: #FFB86CA6;">introspección → [[01 - Information Disclosure|mapa completo]]; batching/aliases/field duplication → [[04 - Denegación de servicio (DoS) y Batching|DoS y brute-force]]; GET/url-encoded → CSRF; field suggestions → fuga de esquema</mark>. Combínalo con el fingerprint de [[07 - Herramientas para GraphQL|graphw00f]] y el mapa de amenazas del motor (GraphQL Threat Matrix).

# Evasión de defensas

## Introspección deshabilitada

La defensa más común. No te deja ciego:

- <mark style="background: #ADCCFFA6;">**Field Suggestions**</mark>: si están activas (muy frecuente en Apollo), los errores sugieren nombres (*"Did you mean 'password'?"*). `clairvoyance` abusa de esto para **reconstruir el esquema sin introspección**.
- **Fuerza bruta** de queries/campos con wordlists.
- Probar la introspección por **otros métodos** (`GET`) o con la query partida, por si el filtro solo mira `POST`/JSON.

## Filtros y CSRF

- <mark style="background: #FFB8EBA6;">**Método y content-type**</mark>: si el WAF inspecciona el `POST` JSON, prueba la query por `GET` (`?query=...`) o por `POST` url-encoded. Estas mismas variantes habilitan **CSRF** (la query viaja como una petición simple sin preflight).
- **Batching/aliasing** para saltar rate-limits y anti-brute-force ([[04 - Denegación de servicio (DoS) y Batching|batching]]) — la evasión estrella.
- **Endpoint único, WAF ciego**: las reglas por URL/parámetro no ven el interior de la query; mueve el payload de inyección dentro de un argumento anidado.

# Prevención

Resumen por categoría (del propio módulo + OWASP GraphQL Cheat Sheet):

| Categoría | Mitigación |
| - | - |
| Information Disclosure | **Deshabilitar introspección** y field suggestions en producción; errores **genéricos** (no verbosos) |
| Injection | Validación/saneo de **todo** argumento; **allowlist** > denylist; consultas parametrizadas |
| DoS / brute-force | **Límite de profundidad y complejidad** de query; tamaño máximo; **deshabilitar/limitar batching** y aliases; rate-limit **por operación** |
| Access control (IDOR, mutations) | Autenticación **antes** del endpoint; **authz por query y por mutation**; principio de mínimo privilegio; autorización a nivel de **campo** |

> [!important]+ El error de diseño recurrente
> <mark style="background: #FF5582A6;">GraphQL centraliza la lógica pero **no** el control de acceso</mark>: cada resolver/campo necesita su propia comprobación. La mayoría de vulnerabilidades del módulo (IDOR, mutations de privesc, campos sensibles) nacen de asumir que "si la UI no lo pide, nadie lo pedirá". Con introspección + queries directas, el atacante pide **todo**.

Las herramientas concretas para cada fase, en [[07 - Herramientas para GraphQL|Herramientas para GraphQL]].

## Referencias

- OWASP — [GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- [graphql-cop](https://github.com/dolevf/graphql-cop) · [GraphQL Threat Matrix](https://github.com/nicholasaleks/graphql-threat-matrix)
- PortSwigger — [Preventing GraphQL attacks](https://portswigger.net/web-security/graphql)
- HTB Academy — *Attacking GraphQL* (base, 2024)
