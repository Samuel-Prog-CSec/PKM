---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[10 - Ataques a tokens de sesión]]"
Nota siguiente: "[[12 - Arsenal de herramientas para autenticación]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Las notas anteriores son técnicas sueltas. Esta es el **método**: cómo recorrer toda la superficie de autenticación de una app de forma sistemática para no dejarte ningún vector, y qué señales delatan estos ataques desde el lado defensor. Es la guía que sigues con cada login que auditas, alineada con [OWASP WSTG — Authentication Testing](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/04-Authentication_Testing/).

# Mapear la superficie

<mark style="background: #ADCCFFA6;">Antes de atacar, enumera todos los flujos donde se ejerce o se confía la identidad.</mark> Casi nunca es solo `/login`:

- **Login** — formulario principal, ¿y APIs (`/api/login`), endpoint móvil, SSO?
- **Registro** — fuga de usuarios, mass assignment de `role`.
- **Password reset** — el flujo más rico en bugs de lógica.
- **2FA/MFA** — setup, verificación, códigos de backup, "recordar dispositivo".
- **Gestión de sesión** — emisión del token, logout, timeout, "recordarme".
- **Cambio de email/contraseña** estando logueado — re-autenticación, confirmación.

# Checklist de testing

Recórrela por flujo. Cada ítem enlaza con su nota:

| Flujo | Qué probar |
| - | - |
| Login | [[01 - Enumeración de usuarios\|Enum de usuarios]] (mensaje/timing/longitud); [[02 - Fuerza bruta de contraseñas en el login\|fuerza bruta y spraying]]; [[06 - Credenciales por defecto\|credenciales por defecto]] |
| Protección | [[05 - Bypass de protecciones anti-fuerza-bruta\|rate limit por cabecera, CAPTCHA roto]] |
| Reset | [[03 - Fuerza bruta de tokens de reset\|token débil/predecible]]; [[07 - Reset de contraseña vulnerable\|host header, fuga por Referer, manipulación de usuario]] |
| 2FA | [[04 - Fuerza bruta de códigos 2FA y MFA\|brute force de OTP, forced browsing, MFA fatigue]] |
| Bypass | [[08 - Bypass de autenticación - acceso directo\|acceso directo]]; [[09 - Bypass de autenticación - modificación de parámetros\|modificación de parámetros]] |
| Sesión | [[10 - Ataques a tokens de sesión\|entropía del token, fixation, flags de cookie, timeout]] |

<mark style="background: #FF5582A6;">El orden importa</mark>: enumerar usuarios primero acota todo lo demás; probar las protecciones antes de la fuerza bruta evita perder el tiempo (o descubre el bug del bypass de rate limit, que vale por sí solo).

# Análisis del token: la prueba que casi nadie hace

Capturar **varios** tokens y analizarlos es de las acciones de mayor ROI:

- ¿Es decodificable (base64/hex/URL)? → forja directa.
- ¿Qué parte cambia entre capturas? → la entropía real.
- ¿Es incremental o temporal? → predecible.
- `Burp Sequencer` mide la aleatoriedad estadística de cientos de tokens automáticamente — el camino rápido para fundamentar "entropía insuficiente" en un informe.

# Lado defensa: cómo se detectan estos ataques

Saber qué deja huella es saber qué ruido evitar (y, como Blue Team, qué monitorizar):

| Ataque | Firma de detección |
| - | - |
| Fuerza bruta de cuenta | Muchos `401`/fallos sobre **un** usuario desde una IP |
| [[02 - Fuerza bruta de contraseñas en el login\|Password spraying]] | **Una** contraseña contra muchos usuarios; pico de fallos distribuido |
| [[02 - Fuerza bruta de contraseñas en el login\|Credential stuffing]] | Muchas IPs, *impossible travel*, ratio de éxito bajo |
| Brute force de token/OTP | Ráfaga de valores secuenciales contra `/reset` o `/2fa` |
| Secuestro de sesión | Misma sesión desde dos geolocalizaciones/User-Agents |

<mark style="background: #8000E1A6;">La evasión de estas firmas</mark> —rotación de IP, jitter, spraying lento— está en [[05 - Defensas y evasión|Brute Forcing]]. En un engagement con Blue Team activo, el sigilo es parte del alcance; en bug bounty, importa no tumbar el servicio ni inundar su SOC.

> [!info]+ Fuentes
> - [OWASP WSTG — Authentication Testing](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/04-Authentication_Testing/) · [Session Management Testing](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/06-Session_Management_Testing/)
> - [OWASP ASVS — V2/V3 (Authentication & Session)](https://owasp.org/www-project-application-security-verification-standard/)
