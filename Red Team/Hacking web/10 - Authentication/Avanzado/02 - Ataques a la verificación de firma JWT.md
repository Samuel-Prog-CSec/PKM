---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
Descripción: "La firma es lo único que impide manipular el payload"
Fecha de actualización: 2026-06-23
Nota previa: "[[01 - Introducción a JWT]]"
Nota siguiente: "[[03 - Ataque al secreto de firma JWT]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

La [[01 - Introducción a JWT|firma]] es lo único que impide manipular el payload. Los dos primeros ataques no rompen la firma: explotan que la app **no la verifica** correctamente. Cuando funcionan, cambiar `"isAdmin": false` a `true` es account takeover instantáneo.

# Verificación de firma ausente

El fallo más burdo: la app **decodifica** el JWT pero no **verifica** su firma. La causa raíz casi siempre es de librería — usar `decode()` en vez de `verify()`, o `jwt.decode(token, verify=False)`. El servidor lee los claims de un token manipulado como si fueran de fiar.

Explotación directa: coges tu JWT, cambias el claim en [jwt.io](https://jwt.io) o CyberChef, y lo reenvías con la firma rota:

```http
GET /home HTTP/1.1
Cookie: session=eyJ...isAdmin:true...  ← firma inválida, pero la app no la comprueba
```

Si te da acceso admin, <mark style="background: #FF5582A6;">la app acepta firmas inválidas</mark> — uno de los hallazgos más críticos posibles.

# Ataque del algoritmo `none`

Variante elegante. El estándar JWA define `alg: none` para tokens **sin firma** (pensado para casos donde la integridad ya se garantiza por otra vía). Si la app respeta ciegamente el `alg` del header, le mandas un token con `none` y lo acepta sin verificar nada:

```json
{ "alg": "none", "typ": "JWT" }
```

Se forja poniendo `alg: none` en el header, el payload manipulado, y **firma vacía** (pero conservando el punto final):

```text
eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJ1c2VyIjoiaHRiLXN0ZG50IiwiaXNBZG1pbiI6dHJ1ZX0.
```

> [!warning]+ El punto final es obligatorio
> Aunque no haya firma, el JWT sigue siendo `header.payload.` — el tercer punto **debe** estar. Sin él, muchos parsers rechazan el token por malformado y crees que el ataque no funciona cuando el problema es de formato.

<mark style="background: #FFB86CA6;">Las defensas ingenuas filtran solo `"none"` en minúsculas</mark>. Como el parsing del `alg` suele ser case-insensitive, prueba variantes: `None`, `NONE`, `nOnE`. Es un bypass clásico de blacklist, hermano del que se ve en [[06 - Bypass de comandos en blacklist|otras inyecciones]].

# Con jwt_tool

`jwt_tool` automatiza ambos ataques sin tocar CyberChef:

```shell-session
$ jwt_tool <JWT> -X a              # forja alg:none (y variantes None/NONE)
$ jwt_tool <JWT> -T                # modo tampering interactivo: edita claims y reenvía
```

El flag `-X a` genera las cuatro variantes de `none`; `-T` permite editar el payload (`isAdmin → true`) manteniendo el formato.

> [!info]+ Psychic signatures (CVE-2022-21449): el `alg:none` de ECDSA
> Java 15-18 no comprobaba que los valores `(r,s)` de una firma `ECDSA` fueran distintos de cero. <mark style="background: #FFB86CA6;">Una firma `(0,0)` —un token `alg: ES256` con `r=s=0`— valida **cualquier** payload.</mark> Es el equivalente de `alg:none` para los algoritmos asimétricos `ES*`, y afecta a JWT, SAML y WebAuthn firmados con ECDSA en una JVM vulnerable (afecta **Java 15–18**; fix en 17.0.3 / 18.0.1. Oracle incluyó Java 11 en el aviso inicial **por error** y lo retiró después — Java 11 nunca fue vulnerable). `jwt_tool` lo automatiza con `-X p`. [Análisis de Neil Madden](https://neilmadden.blog/2022/04/19/psychic-signatures-in-java/).

> [!info]+ Cuándo aparece y cómo se evita
> Estos fallos son raros en libs modernas (ya separan `decode`/`verify` y rechazan `none` por defecto), pero <mark style="background: #8000E1A6;">resurgen cuando el dev configura mal la verificación o usa una lib antigua</mark> (CVE-2015-9235 y familia). La prevención: verificar **siempre** la firma y **fijar** los algoritmos aceptados en el servidor (allowlist `["RS256"]`), nunca dejar que el token elija — esto último es justo lo que habilita la [[04 - Confusión de algoritmos JWT|confusión de algoritmos]].

> [!info]+ Fuentes
> - [PortSwigger — JWT: accepting tokens with no signature / arbitrary signatures](https://portswigger.net/web-security/jwt#accepting-tokens-with-no-signature)
> - [jwt_tool (ticarpi)](https://github.com/ticarpi/jwt_tool) · [jwt.io](https://jwt.io)
