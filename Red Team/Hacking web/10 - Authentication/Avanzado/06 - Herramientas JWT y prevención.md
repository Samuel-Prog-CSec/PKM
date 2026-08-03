---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
  - Tipo/Defensa
Descripción: "Todos los ataques JWT de las notas anteriores se ejecutan a mano, pero en un engagement real se automatizan"
Fecha de actualización: 2026-06-23
Nota previa: "[[05 - Más ataques JWT - jku, kid y x5c]]"
Nota siguiente: "[[07 - Introducción a OAuth 2.0]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

Todos los ataques JWT de las notas anteriores se ejecutan a mano, pero en un engagement real se automatizan. Este es el instrumental y la pasada de prevención.

# `jwt_tool`: la navaja suiza

[`jwt_tool`](https://github.com/ticarpi/jwt_tool) (ticarpi) hace análisis, crackeo y todos los ataques en una herramienta. Análisis de un token (decodifica, marca expiración, detecta debilidades):

```shell-session
$ python3 jwt_tool.py <JWT>
[+] alg = "HS256"
[+] isAdmin = False
[+] exp = 1711186044  ==> 2024-03-23 (UTC)  [-] TOKEN IS EXPIRED!
```

La matriz de exploits con `-X`:

| Flag | Ataque | Nota |
| - | - | - |
| `-X a` | `alg:none` (+ variantes None/NONE/nOnE) | [[02 - Ataques a la verificación de firma JWT]] |
| `-X n` | Firma nula | [[02 - Ataques a la verificación de firma JWT]] |
| `-X b` | Acepta secreto en blanco | [[02 - Ataques a la verificación de firma JWT]] |
| `-X k` | Confusión de algoritmos (`-pk pub.pem`) | [[04 - Confusión de algoritmos JWT]] |
| `-X i` | Inyección de `jwk` inline | [[05 - Más ataques JWT - jku, kid y x5c]] |
| `-X s` | Spoof de JWKS (`-ju <URL>`) | [[05 - Más ataques JWT - jku, kid y x5c]] |
| `-X p` | Psychic signature ECDSA (CVE-2022-21449) | [[02 - Ataques a la verificación de firma JWT]] |

Crackeo del secreto y manipulación de claims:

```shell-session
$ jwt_tool <JWT> -C -d jwt.secrets.list          # crackear HMAC
$ jwt_tool <JWT> -X a -pc isAdmin -pv true -I     # forjar alg:none con isAdmin=true
$ jwt_tool <JWT> -T                               # tampering interactivo
```

`-pc`/`-pv` fijan claim y valor; `-I` inyecta en el payload; `-T` abre el editor interactivo.

# Resto del arsenal

| Herramienta | Qué aporta |
| - | - |
| <mark style="background: #FFB86CA6;">**JWT Editor**</mark> ([Burp](https://github.com/PortSwigger/json-web-tokens)) | Extensión de Burp: edita, firma y ataca JWT dentro de Repeater/Intruder. La opción cómoda en un flujo Burp |
| **hashcat** `-m 16500` | Crackeo del secreto HMAC a velocidad GPU. Ver [[03 - Ataque al secreto de firma JWT]] |
| **rsa_sign2n** ([repo](https://github.com/silentsignal/rsa_sign2n)) | Deriva la clave pública de 2 JWTs para [[04 - Confusión de algoritmos JWT|confusión de algoritmos]] |
| **jwt.io** / **CyberChef** | Inspección y forja manual rápida |
| **jwt-secrets** ([repo](https://github.com/wallarm/jwt-secrets)) | Wordlist de secretos por defecto de frameworks |

> [!success]+ Flujo de auditoría JWT
> 1. `jwt_tool <JWT>` → análisis: ¿`alg`? ¿`exp`? ¿claims jugosos (`isAdmin`, `role`)?
> 2. ¿Acepta firma inválida / `alg:none`? → `-X a`.
> 3. ¿`HS*`? → crackear secreto (`-C` / hashcat).
> 4. ¿`RS*`? → confusión de algoritmos (`-X k`) tras obtener la pública.
> 5. ¿Header con `jwk`/`jku`/`kid`? → inyección de clave (`-X i`/`-X s`).

# Prevención de vulnerabilidades JWT

<mark style="background: #ADCCFFA6;">La regla transversal: el **servidor** decide cómo se verifica, nunca el token.</mark> Checklist:

- **Fijar el algoritmo** aceptado (allowlist `["RS256"]`); rechazar `none` y cualquier `alg` inesperado.
- **No implementar JWT a mano**: usar librerías establecidas y actualizadas, que ya separan `decode`/`verify`.
- **Secreto fuerte** (≥256 bits, CSPRNG) y **distinto por aplicación** — mata el [[03 - Ataque al secreto de firma JWT|crackeo]] y la reutilización.
- **No aceptar claves embebidas** (`jwk`/`jku`/`x5c`) salvo de un whitelist estricto de orígenes; validar `kid` contra un conjunto cerrado.
- **`exp` siempre presente** y validado — sin caducidad, un token robado es eterno.

> [!info]+ Fuentes
> - [jwt_tool — wiki de ataques](https://github.com/ticarpi/jwt_tool/wiki) · [Burp JWT Editor](https://github.com/PortSwigger/json-web-tokens)
> - [OWASP — JSON Web Token Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html) · [PortSwigger — JWT](https://portswigger.net/web-security/jwt)
