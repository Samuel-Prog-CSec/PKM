---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - OAuth
Fecha de actualización: 2026-06-23
Nota previa: "[[09 - Protección CSRF deficiente en OAuth]]"
Nota siguiente: "[[11 - Introducción a SAML]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

Más allá de los fallos en el flujo mismo, OAuth se rompe **encadenado** con otras vulnerabilidades. Estas son las que aparecen en reportes reales de bug bounty con cuentas tomadas a millones de usuarios.

# XSS en el flujo de autorización

Los parámetros de la authorization request (`client_id`, `redirect_uri`, `state`) suelen **reflejarse** como campos ocultos en el formulario de login del authorization server. Si no se sanean, hay XSS reflejado:

```text
/authorization/auth?...&state=<script>alert(1)</script>
```

<mark style="background: #FF5582A6;">Lo crítico es **dónde** ocurre</mark>: el XSS vive en el **authorization server**, la pieza que custodia las sesiones de todos los clientes. Un XSS ahí permite robar el código/token de la víctima y deriva en account takeover completo. Es el peor sitio posible para un [[00 - Introducción a XSS|XSS]] reflejado.

# Open redirect: el bypass del `redirect_uri` bien validado

Aunque el authz server valide el `redirect_uri` por **origen exacto** (protocolo+host+puerto), la cosa cambia si el cliente legítimo aloja un **open redirect**. El atacante encadena:

```text
redirect_uri=http://academy.htb/redirect?url=http://attacker.htb/callback
```

El origen (`academy.htb`) pasa la validación. Pero tras autenticarse, el código va a `academy.htb/redirect`, que **reenvía** a `attacker.htb`. <mark style="background: #FFB86CA6;">El atacante obtiene el código pese a una validación de `redirect_uri` correcta.</mark> El resto, como en [[08 - Robo de tokens de acceso OAuth|robo de tokens]].

> [!info]+ Caso real: account takeover en Booking.com
> Salt Labs reportó exactamente esta cadena en **Booking.com**: `redirect_uri` validado por origen + open redirect en el cliente = robo del token y ATO. Es el ejemplo canónico de por qué un open redirect "informational" se vuelve crítico junto a OAuth. ([Salt Labs](https://salt.security/blog/traveling-with-oauth-account-takeover-on-booking-com))

# Cliente malicioso y confusión de audiencia

El atacante no tiene por qué ser externo: los authz servers permiten **registrar clientes**. El atacante registra `evil.htb` como cliente OAuth de `hubgit.htb`. Cuando una víctima entra en `evil.htb` con su cuenta de hubgit, <mark style="background: #FFB86CA6;">el cliente del atacante recibe un access token válido de la víctima.</mark>

El golpe llega si reutiliza ese token contra **otro** cliente: si `academy.htb` no verifica que el token fue **emitido para él** (el claim de audiencia/`client_id`), aceptará el token de la víctima emitido para `evil.htb` → impersonación.

> [!info]+ Caso real: "OH-Auth" — millones de cuentas
> Salt Labs demostró esta confusión de audiencia afectando a clientes OAuth masivos (Grammarly, Vidio, Bukalapak...): un token obtenido por un cliente valía en otro que no validaba la audiencia. ([Salt Labs — OH-Auth](https://salt.security/blog/oh-auth-abusing-oauth-to-take-over-millions-of-accounts))

# Dos más en el radar

- <mark style="background: #FFB86CA6;">**Mix-up attack**</mark>: en clientes que soportan **varios IdP**, si el cliente no asocia el `code`/`state` al **issuer** concreto, el atacante confunde al cliente sobre qué authz server emitió el código y le hace canjearlo en el endpoint equivocado, filtrando el código o el `client_secret`. Mitigación del [Security BCP](https://datatracker.ietf.org/doc/html/rfc9700): el parámetro `iss` en la respuesta de autorización ([RFC 9207](https://datatracker.ietf.org/doc/html/rfc9207)).
- **Device code phishing**: abuso del *device authorization grant* para robar tokens sin página falsa — el ataque OAuth/MFA estrella de 2025 (Storm-2372). Lo desarrolla [[04 - Fuerza bruta de códigos 2FA y MFA|2FA/MFA]].

# Prevención

<mark style="background: #ADCCFFA6;">La regla: ceñirse al estándar sin atajos, en **todas** las entidades.</mark>

- **`state` obligatorio** e impredecible (aunque el estándar lo marque opcional).
- **`redirect_uri` por igualdad exacta** contra los registrados; y sin open redirects en el cliente.
- **Validar la audiencia** del token: el cliente debe rechazar tokens emitidos para otro `client_id`.
- **Authorization code grant + PKCE en todos los flujos** (obligatorio en OAuth 2.1, no solo SPAs); nada de implicit; tokens solo por HTTPS.
- Sanear los parámetros reflejados (anti-XSS) y aplicar MFA.

# Tooling para OAuth

OAuth se audita sobre todo **a mano** con [[02 - Interceptación de peticiones|Burp]] —seguir el flujo, manipular `redirect_uri`/`state`, observar reflejos— pero hay soporte:

| Herramienta | Qué aporta |
| - | - |
| **Burp Suite** | Interceptar y manipular cada salto del flujo; el grueso del trabajo |
| **EsPReSSO** ([repo](https://github.com/portswigger/espresso)) | Extensión de Burp para SSO (OAuth/OpenID/SAML): detecta y edita los mensajes del flujo |
| **Burp Collaborator** / **interactsh** | Recibir el código/token desviado por `redirect_uri` |

> [!info]+ Fuentes
> - [PortSwigger — OAuth additional vulnerabilities](https://portswigger.net/web-security/oauth)
> - [OAuth 2.0 Security Best Current Practice (RFC 9700)](https://datatracker.ietf.org/doc/html/rfc9700)
> - [Salt Labs — Booking.com ATO](https://salt.security/blog/traveling-with-oauth-account-takeover-on-booking-com) · [OH-Auth](https://salt.security/blog/oh-auth-abusing-oauth-to-take-over-millions-of-accounts)
