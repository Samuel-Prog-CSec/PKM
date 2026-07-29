---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Descripción: "Tras autenticarse, el usuario se identifica en cada petición con un token de sesión"
Fecha de actualización: 2026-06-23
Nota previa: "[[09 - Bypass de autenticación - modificación de parámetros]]"
Nota siguiente: "[[11 - Detección y metodología en autenticación]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Tras autenticarse, el usuario se identifica en cada petición con un **token de sesión**. <mark style="background: #ADCCFFA6;">Quien obtiene o forja un token de sesión válido se hace pasar por su dueño</mark> — sin contraseña, sin MFA. Por eso el manejo de la sesión es tan crítico como el login mismo, y un token débil tira abajo todo lo demás.

# Tokens débiles: forzables por diseño

Si el token no tiene suficiente entropía, se fuerza igual que un [[03 - Fuerza bruta de tokens de reset|token de reset]]. Tres patrones:

- **Demasiado corto**: un `session=a5fd` de 4 caracteres se enumera por completo y secuestra cualquier sesión activa.
- <mark style="background: #FFB86CA6;">**Parcialmente estático**</mark>: un token de 32 caracteres parece seguro, pero capturando varios se ve que solo unos pocos cambian. Si de 32 chars 28 son fijos (`2c0c58b27c71a2ec5bf2b4` + `····` + `92b9f9`), la entropía real son 4 caracteres → forzable.
- **Incremental**: tokens `141233`, `141234`, `141237`... son contadores. Sumar/restar revela sesiones pasadas y futuras.

<mark style="background: #FF5582A6;">La técnica práctica: capturar 5-10 tokens seguidos y compararlos.</mark> Lo que se mantiene fijo entre capturas no aporta entropía; lo que varía es el espacio real a atacar.

# Tokens predecibles: forja por encoding

El caso más común y vergonzoso. El token *parece* aleatorio pero es **datos codificados** que puedes manipular. Un base64 se delata al decodificar:

```shell-session
$ echo -n 'dXNlcj1odGItc3RkbnQ7cm9sZT11c2Vy' | base64 -d
user=htb-stdnt;role=user
```

Sin firma ni cifrado que lo proteja, forjas un token de admin:

```shell-session
$ echo -n 'user=htb-stdnt;role=admin' | base64
dXNlcj1odGItc3RkbnQ7cm9sZT1hZG1pbg==
```

Lo mismo aplica a datos en **hex** (`xxd -p`) o **URL-encoding**. <mark style="background: #8000E1A6;">El fallo de raíz: meter datos de autorización en el token sin integridad.</mark> La defensa correcta es firmar el token (HMAC) o usar tokens opacos server-side; precisamente lo que pretende resolver [[01 - Introducción a JWT|JWT]] — que, mal implementado, trae sus [[02 - Ataques a la verificación de firma JWT|propios ataques]]. Los tokens cifrados con criptografía débil también caen, aunque en blackbox cuesta más sin el código.

# Session fixation

[Session fixation](https://owasp.org/www-community/attacks/Session_fixation) explota que la app **no rota el token tras el login**. Si además acepta un token fijado por el cliente (p. ej. vía `?sid=`), el ataque es:

1. El atacante consigue un token de sesión que la app acepte fijar — normalmente uno **anónimo, pre-login**. El requisito real no es "mantenerlo vivo", sino que la app **no regenere** el ID de sesión al autenticar.
2. Engaña a la víctima para que use **ese** token: `http://vulnerable.htb/?sid=a1b2c3d4e5f6` → la app hace `Set-Cookie: session=a1b2c3d4e5f6`.
3. La víctima se autentica. Como la app no asigna token nuevo, sigue usando el del atacante.
4. El atacante, que conoce el token, <mark style="background: #FFB86CA6;">secuestra la sesión ya autenticada de la víctima</mark>.

La defensa es una sola regla: **generar un token nuevo y aleatorio tras cada autenticación** (y al elevar privilegios).

# Robo de sesión y timeout

- **Robo vía XSS**: si el token va en una cookie sin `HttpOnly`, un [[09 - Robo de sesión|XSS exfiltra `document.cookie`]] y secuestra la sesión. Es la vía de robo más común en la práctica.
- **Timeout impropio**: un token que no caduca nunca convierte un secuestro puntual en acceso permanente. El timeout adecuado depende del negocio (minutos para banca, horas para una red social), pero "infinito" siempre es un fallo.

> [!important]+ Defensas de cookie de sesión
> El token de sesión bien hecho cumple: <mark style="background: #FFB86CA6;">alta entropía (CSPRNG, ≥128 bits), `HttpOnly` (lo aísla del XSS), `Secure` (solo HTTPS) y `SameSite`</mark> (mitiga [[01 - Fundamentos y defensas de CSRF|CSRF]]), más rotación en login y caducidad. La cookie ideal usa además un **prefijo**: `__Host-SID=…; Path=/; Secure; HttpOnly; SameSite=Strict` — el prefijo `__Host-` obliga a `Secure`, sin `Domain` y `Path=/`, lo que **garantiza** que la cookie solo va al host que la fijó (mata la fijación cross-subdomain).
>
> <mark style="background: #FF5582A6;">Gotcha de auditoría</mark>: `SameSite=Lax` es default solo en Chrome/Edge; en **Firefox y Safari una cookie sin atributo `SameSite` explícito sigue siendo `None`** → no asumas protección CSRF por el default del navegador. Y un token fuerte servido sin `HttpOnly` sigue siendo robable por XSS.

> [!info]+ Fuentes
> - [OWASP — Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) · [Insufficient Entropy](https://owasp.org/www-community/vulnerabilities/Insufficient_Entropy)
> - [OWASP — Session fixation](https://owasp.org/www-community/attacks/Session_fixation) · [PortSwigger — Session management](https://portswigger.net/web-security/authentication)
