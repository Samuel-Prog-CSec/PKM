---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - Introduccion
  - Tipo/Introduccion
Descripción: "La autenticación es el proceso de verificar que una entidad es quien dice ser (RFC 4949)"
Fecha de actualización: 2026-06-23
Nota previa:
Nota siguiente: "[[01 - Enumeración de usuarios]]"
Area: "[[Authentication.base|Authentication]]"
---
---

<mark style="background: #ADCCFFA6;">La autenticación es el proceso de verificar que una entidad es quien dice ser</mark> ([RFC 4949](https://datatracker.ietf.org/doc/rfc4949/)). Es la primera línea de defensa de cualquier aplicación, y por eso uno de los focos de superficie más rentables. Romperla es lo que cataloga OWASP como **A07:2021 – Identification and Authentication Failures**, una de las categorías más recurrentes del Top 10.

No confundir con la **autorización**, que decide *qué* puede hacer una identidad ya verificada. La autenticación ocurre antes y responde a "¿eres tú?"; la autorización responde a "¿puedes hacer esto?". Saltarse la primera ([[08 - Bypass de autenticación - acceso directo|bypass de autenticación]]) y saltarse la segunda ([[06 - Introducción a IDOR|IDOR]]) son fallos distintos con notas distintas.

![Comparativa autenticación vs. autorización: la autenticación verifica identidad con credenciales y ocurre primero; la autorización determina acceso según políticas y ocurre después.](https://academy.hackthebox.com/storage/modules/269/auth_vs_auth.png)

# Los tres factores

Toda autenticación se apoya en uno o varios de estos factores:

| Conocimiento (*algo que sabes*) | Posesión (*algo que tienes*) | Inherencia (*algo que eres*) |
| - | - | - |
| Contraseña, PIN | Tarjeta ID, token, app TOTP | Huella, rostro, voz |
| Pregunta de seguridad | Llave de seguridad (FIDO2) | Firma |

<mark style="background: #FFB8EBA6;">Este módulo ataca casi siempre el factor de conocimiento</mark> (contraseñas), porque es el más extendido en web y el más débil: la información estática se puede adivinar, [[02 - Fuerza bruta de contraseñas en el login|forzar]], phishear u obtener de una brecha.

# SFA, MFA y el futuro sin contraseña

- `Single-factor` (SFA): un solo factor. La contraseña sola es SFA y, por tanto, frágil.
- `Multi-factor` (MFA): dos o más factores de **categorías distintas**. Contraseña + TOTP combina conocimiento y posesión. Con exactamente dos se le llama `2FA`.

> [!info]+ El modelo de factores está siendo sustituido por passkeys
> La industria migra hacia `passkeys` (FIDO2/WebAuthn): credenciales criptográficas ligadas al dispositivo y al origen, **resistentes a phishing** porque no hay secreto que teclear ni reutilizar. Donde hay passkeys, la fuerza bruta y el phishing clásico dejan de aplicar. Pero la realidad de 2026 sigue dominada por contraseña + MFA, y ahí <mark style="background: #FFB86CA6;">los ataques de hoy no rompen la contraseña, rompen el segundo factor</mark>: [[04 - Fuerza bruta de códigos 2FA y MFA|fuerza bruta de OTP]], *MFA fatigue* (spam de push hasta que la víctima acepta) y robo de [[10 - Ataques a tokens de sesión|tokens de sesión]] que saltan el MFA por completo.

> [!warning]+ Passkeys no son inatacables: por dónde se rompe un despliegue WebAuthn
> Que una app soporte passkeys no la vuelve inmune — la superficie se mueve, no desaparece:
> - **Downgrade a contraseña**: el RP ofrece passkey pero mantiene un *fallback* débil (contraseña, OTP por SMS, un "¿problemas para entrar?"). El atacante fuerza ese camino y evita la passkey por completo. Es **el** vector por el que un pentest suele "romper" un despliegue de passkeys en 2026.
> - **Enumeración de usuarios**: si el servidor responde distinto (o devuelve un `allowCredentials` no vacío) según exista o no la cuenta, se enumeran usuarios antes de tocar la criptografía.
> - **RP ID / `origin` mal configurado**: un `rpId` demasiado amplio o una validación de `origin` laxa en el servidor rompen la garantía anti-phishing que es toda la gracia de WebAuthn.
>
> Regla al auditar: busca siempre el **camino de recuperación/fallback** — ahí vive la debilidad, no en la passkey en sí.

# Superficie de ataque por factor

- **Conocimiento**: el objetivo principal. Adivinable, forzable, phisheable, filtrable. Todo este módulo gira en torno a él.
- **Posesión**: más resistente a ataques remotos, pero vulnerable a robo, **clonado** (badges NFC en sitios públicos) y ataques criptográficos al algoritmo del token.
- **Inherencia**: cómoda, pero con un fallo demoledor — <mark style="background: #8000E1A6;">es irreversible</mark>. No puedes cambiar tu huella tras una brecha. En 2019 la filtración de **BioStar2** expuso las huellas y patrones faciales de millones de usuarios de cerraduras biométricas; si hubieran usado contraseñas, bastaba rotarlas. Con biometría, el compromiso es permanente.

# Enfoque para el pentester

El recorrido del módulo sigue el flujo real de ataque a un login: <mark style="background: #FF5582A6;">primero enumerar usuarios válidos</mark> ([[01 - Enumeración de usuarios]]), luego atacar la contraseña ([[02 - Fuerza bruta de contraseñas en el login]]) o los flujos paralelos que suelen estar peor protegidos —[[03 - Fuerza bruta de tokens de reset|reset de contraseña]], [[07 - Reset de contraseña vulnerable|su lógica]], [[04 - Fuerza bruta de códigos 2FA y MFA|2FA]]—, y finalmente saltarse la autenticación por completo vía [[08 - Bypass de autenticación - acceso directo|bypass]] o [[10 - Ataques a tokens de sesión|sesión]]. La fuerza bruta como técnica vive en su propio sub-tema: [[00 - Introducción al brute forcing|Brute Forcing]].

> [!info]+ Fuentes
> - [OWASP Top 10 — A07:2021 Identification and Authentication Failures](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
> - [OWASP WSTG — Testing for Authentication](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/04-Authentication_Testing/)
> - [RFC 4949 — Internet Security Glossary](https://datatracker.ietf.org/doc/rfc4949/) · [BioStar2 breach (vpnMentor, 2019)](https://www.vpnmentor.com/blog/report-biostar2-leak/)
