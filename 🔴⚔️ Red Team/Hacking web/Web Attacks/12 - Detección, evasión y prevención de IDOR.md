---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - IDOR
Fecha de actualización: 2026-07-15
Nota previa: "[[11 - Encadenamiento de IDOR]]"
Nota siguiente: "[[13 - Herramientas para IDOR]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Nota dedicada a **cazar** IDOR de forma sistemática, **evadir** las defensas que hoy los dificultan, y **prevenirlos**. La detección de IDOR es notoriamente difícil de automatizar (requiere entender la semántica de acceso), así que el método importa más que la herramienta.

# Detección

## Metodología de dos cuentas (el estándar)

<mark style="background: #ADCCFFA6;">Registra **dos** usuarios del mismo nivel (A y B) y una sesión sin autenticar</mark>. Navega como A capturando todo el tráfico, y **reproduce cada petición de A con la sesión de B** (y sin sesión). Si obtienes los datos de A usando la cookie de B → IDOR horizontal. Si una función admin responde a un usuario normal → IDOR vertical. Esto es lo que automatizan [[13 - Herramientas para IDOR|Autorize y Auth Analyzer]].

## Señales y puntos calientes

- <mark style="background: #FFB8EBA6;">El "hit" válido casi nunca es un `200` vs `403`</mark>: muchos IDOR devuelven `200` siempre. Detecta por **diff** de tamaño/contenido respecto a tu propia línea base.
- Prueba **todos los verbos y endpoints**: como vimos en el [[11 - Encadenamiento de IDOR|encadenamiento]], el `GET` suele estar desprotegido aunque `PUT`/`POST`/`DELETE` tengan controles. Un endpoint puede filtrar por un método y no por otro.
- Mina el front-end (`.js`) y los parámetros ocultos: referencias que nunca aparecen navegando (ver [[07 - Identificación de IDORs|identificación]]).

# Evasión de defensas modernas

Cuando hay un control de acceso o un WAF que bloquea el IDOR evidente, estas técnicas —documentadas por **Intigriti**, **PortSwigger** y la comunidad de bug bounty— lo resucitan:

| Técnica | Ejemplo | Por qué funciona |
| - | - | - |
| **Cambiar el método** | `GET /api/user/2` bloqueado → `POST`/`PUT` | Control de acceso incoherente entre verbos ([[04 - Detección, evasión y prevención de Verb Tampering\|verb tampering]]) |
| **Envolver el ID** | `id[]=2`, `{"id":[2]}`, `id=2;1` | El validador ve un tipo/estructura; el backend desempaqueta otro (*JSON globbing*) |
| **Parameter pollution** | `?id=1&id=2` | El filtro lee el primero, el sink el último (o al revés) |
| **Identificador alternativo** | Sustituir `id=2` por `email`, `username`, `phone` | El control valida un campo pero resuelve por otro |
| **Encoding** | URL-encode, doble-encode, Unicode del `id` | Evade regex/WAF que buscan el patrón en claro |
| **Versiones viejas de API** | `/api/v2/user/2` parcheado → `/api/v1/user/2` | La versión antigua conserva el bug |
| **`.json` / sufijos** | `/user/2` bloqueado → `/user/2.json`, `/user/2/` | Rutas alternativas con distinto control |
| **Quitar la autenticación** | Eliminar la cabecera `Authorization` | Convierte un IDOR autenticado en no-autenticado si el endpoint responde igual |

> [!warning]+ IDOR ciego (blind IDOR)
> A veces la acción se ejecuta pero **no** devuelve datos (p. ej. "reenviar factura al usuario X"). Detéctalo por **canales laterales**: el email/SMS que recibe la víctima, un cambio de estado observable, diferencias de tiempo, o mensajes de error distintos (`uuid mismatch` vs `not found` filtran información). El impacto sigue siendo real aunque no veas el dato directamente.

# Prevención

La raíz es **broken access control**; la referencia directa solo lo hace explotable. Se arregla en dos capas, **en este orden**.

## 1. Control de acceso a nivel de objeto (imprescindible)

Implementar un `RBAC` y **mapearlo a todos los objetos**. En cada petición, el back-end decide en función del **token de sesión**, nunca de datos que envía el cliente:

```text
match /api/profile/{userId} {
    allow read, write: if user.isAuth == true
        && (user.uid == userId || user.roles == 'admin');
}
```

<mark style="background: #8000E1A6;">La clave: el `uid`/rol se obtiene de la sesión autenticada del lado servidor, no del body ni de una cookie</mark>. El antipatrón que explotamos (`role=employee` en cookie, `role` en el JSON) es justo lo que hay que evitar — cualquier privilegio bajo control del cliente es manipulable.

## 2. Referencias de objeto seguras (secundario)

Aun con buen control de acceso, no uses referencias en claro ni patrones simples (`uid=1`). Usa `UUID` v4 (`89c9b29b-d19f-4515-b2dd-abb6e693eb20`) o hashes salteados, **generados en el servidor** al crear el objeto y mapeados en BD. Nunca calcules hashes en el front-end ([[09 - Bypass de referencias codificadas|function disclosure]]).

> [!important]+ Los UUID no son control de acceso
> <mark style="background: #FF5582A6;">Usar `UUID` puede hacer que un IDOR pase **desapercibido** en los tests</mark> (son inenumerables por fuerza bruta), pero si el control de acceso está roto, sigue explotable en cuanto el `UUID` se filtre (en respuestas, referrers, logs) o repitiendo la petición de un usuario con la sesión de otro. Por eso el referencing seguro es siempre el **segundo** paso, después del control de acceso.

## Referencias

- Intigriti — [A complete guide to exploiting advanced IDOR vulnerabilities](https://www.intigriti.com/blog/news/idor-a-complete-guide-to-exploiting-advanced-idor-vulnerabilities)
- PortSwigger — [Access control vulnerabilities and privilege escalation](https://portswigger.net/web-security/access-control)
- OWASP — [IDOR Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
- OWASP — [Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- HTB Academy — *Web Attacks* (base, 2021)
