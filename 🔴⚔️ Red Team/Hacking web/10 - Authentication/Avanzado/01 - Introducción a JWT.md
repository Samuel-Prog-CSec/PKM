---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
  - Tipo/Introduccion
Descripción: "Un JWT (JSON Web Token) es un formato para transportar datos (claims) firmados entre partes"
Fecha de actualización: 2026-06-23
Nota previa: "[[00 - Introducción a los mecanismos de autenticación]]"
Nota siguiente: "[[02 - Ataques a la verificación de firma JWT]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

<mark style="background: #ADCCFFA6;">Un `JWT` (JSON Web Token) es un formato para transportar datos (`claims`) firmados entre partes.</mark> No es un mecanismo de login en sí, pero la mayoría de apps modernas lo usan como **token de sesión stateless**. Entender su estructura es requisito para atacarlo: casi todos los ataques explotan cómo se verifica (o no) su firma.

# Estructura: tres partes en base64url

Un JWT son tres bloques separados por puntos — `header.payload.signature` — cada uno un objeto JSON codificado en **base64url**:

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIVEItQWNhZGVteSIsInVzZXIiOiJhZG1pbiIsImlzQWRtaW4iOnRydWV9.Chnhj-ATkcOfjtn8GCHYvpNE-9dmlhKTCUwl6pxTZEA
```

> [!warning]+ base64url, no base64
> El encoding es **base64url**: usa `-` y `_` en vez de `+` y `/`, y omite el padding `=`. Decodificar a mano con `base64 -d` falla con tokens que contienen esos caracteres. Usa `jwt_tool`, la utilidad de [jwt.io](https://jwt.io) o `base64url`. Un fallo de decodificación silencioso aquí confunde mucho.

JWT usa **JWS** (firma) o **JWE** (cifrado); en web manda casi siempre JWS. Otros estándares del ecosistema: `JWK` (formato de clave) y `JWA` (algoritmos), ambos protagonistas de [[05 - Más ataques JWT - jku, kid y x5c|ataques avanzados]].

# Header

Metadatos del token. Mínimo, dos campos:

```json
{ "alg": "HS256", "typ": "JWT" }
```

`alg` define el algoritmo de firma/MAC. Los valores del estándar JWA agrupan tres familias —y la opción peligrosa:

| `alg` | Tipo |
| - | - |
| `HS256/384/512` | **Simétrico** (HMAC): misma clave firma y verifica |
| `RS*` / `PS*` | **Asimétrico** (RSA): clave privada firma, pública verifica |
| `ES*` | Asimétrico (ECDSA) |
| `none` | <mark style="background: #FF5582A6;">Sin firma — el origen del primer ataque</mark> |

La distinción simétrico/asimétrico es **la clave de todo el módulo**: confundir una con otra es la base de la [[04 - Confusión de algoritmos JWT|confusión de algoritmos]].

# Payload

Los datos: una lista de `claims`. Decodificando el ejemplo:

```json
{ "iss": "HTB-Academy", "user": "admin", "isAdmin": true }
```

Hay claims registrados (estándar) y arbitrarios (definidos por la app). Los registrados que importan en un ataque:

| Claim | Significado | Por qué importa |
| - | - | - |
| `exp` | Expiración | Si falta o no se valida, el token es eterno |
| `iat` / `nbf` | Emitido en / no antes de | Ventana de validez |
| `sub` / `user` | Sujeto | El identificador a manipular |
| `aud` / `iss` | Audiencia / emisor | Clave en confusión entre servicios |

<mark style="background: #FFB86CA6;">El objetivo del atacante suele ser este bloque</mark>: cambiar `"isAdmin": false` a `true`, o `user` a otra cuenta. Lo único que lo impide es la firma.

# Firma: lo único que protege el token

La firma se calcula sobre `header.payload` con una clave secreta y el algoritmo del header. Garantiza **integridad**: alterar cualquier byte invalida la firma. Forjar un token válido exige conocer la clave de firma.

> [!important]+ Firmado ≠ cifrado
> El error conceptual más peligroso con JWT: <mark style="background: #8000E1A6;">el payload **no está cifrado**, solo firmado.</mark> Cualquiera decodifica el base64url y lee todos los claims. Nunca metas secretos en un JWT (JWS) creyendo que van protegidos — van en claro. La firma impide *modificarlo*, no *leerlo*.

# Stateful vs. stateless: por qué se usan

- **Stateful** (sesión clásica): el cliente manda un identificador opaco; el servidor busca los datos asociados en su almacén. El servidor guarda el estado.
- **Stateless** (JWT): el token **contiene** los datos del usuario en sus claims. Tras verificar la firma, el servidor los lee sin tocar la base de datos.

![Autenticación stateless: el cliente envía un token criptográficamente protegido que contiene su nombre, email y expiración; el servidor lo verifica y confía en los datos.](https://academy.hackthebox.com/storage/modules/259/Diagram6.png)

<mark style="background: #FFB8EBA6;">Esa es la ventaja —y el riesgo—</mark>: el servidor confía en los claims firmados sin consultar nada. Consecuencia ofensiva: <mark style="background: #FFB86CA6;">un JWT robado es válido hasta su `exp` **aunque la víctima cierre sesión**</mark> — sin estado en el servidor no hay revocación (las defensas, como una denylist de `jti` o refresh tokens cortos, reintroducen estado). Si logras que acepte un token con la firma rota o forjada, le haces creer cualquier identidad. Todo el resto del sub-tema ataca esa verificación, empezando por el caso más simple: que [[02 - Ataques a la verificación de firma JWT|no la compruebe en absoluto]].

> [!info]+ Fuentes
> - [RFC 7519 — JWT](https://datatracker.ietf.org/doc/html/rfc7519) · [RFC 7515 — JWS](https://datatracker.ietf.org/doc/html/rfc7515) · [RFC 7518 — JWA](https://datatracker.ietf.org/doc/html/rfc7518)
> - [jwt.io — debugger](https://jwt.io) (hoy operada por Okta; pestañas **Decoder/Encoder**, el Encoder firma) · alternativa sin login: [token.dev](https://token.dev) · [PortSwigger — JWT attacks](https://portswigger.net/web-security/jwt)
