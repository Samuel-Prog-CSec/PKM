---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[02 - Fuerza bruta de contraseñas en el login]]"
Nota siguiente: "[[04 - Fuerza bruta de códigos 2FA y MFA]]"
Area: "[[Authentication.base|Authentication]]"
---
---

El flujo de "olvidé mi contraseña" es a menudo el eslabón más débil de la autenticación: <mark style="background: #ADCCFFA6;">permite cambiar la contraseña **sin conocerla**, apoyándose en un token de un solo uso enviado por email o SMS</mark>. Si ese token es débil, se fuerza o se predice, y el resultado es un account takeover directo. Esta nota ataca el **valor** del token; los fallos de **lógica** del reset (host header, fuga por Referer) van en [[07 - Reset de contraseña vulnerable]].

![Flujo de reset: el usuario solicita el reset, la app genera y envía un token, el usuario lo presenta, la app lo verifica y fuerza una contraseña nueva.](https://academy.hackthebox.com/storage/modules/269/bf/reset_bf_1.png)

# Identificar un token débil

Crea una cuenta propia, pide el reset y analiza el token que llega. Las señales de debilidad:

- <mark style="background: #FF5582A6;">**Espacio pequeño**</mark>: un token numérico de 4 dígitos son solo 10.000 valores. Forzable en segundos.
- **Predecible**: secuencial, basado en timestamp (`md5(email+time)`), o generado con un PRNG no criptográfico (`rand()`, `mt_rand()`). Si tu token es `7351` y el de otra cuenta pedida un segundo después es `7352`, es secuencial.
- **Sin caducidad / reutilizable**: un token que no expira ni se invalida tras usarse amplía la ventana de ataque.
- **No atado al usuario**: si el token vale para cualquier cuenta y no solo la que lo pidió, basta uno cualquiera.

Un correo típico revela el token en un parámetro GET:

```txt
http://target.htb/reset_password.php?token=7351
```

# Forzar el token

Genera el espacio completo con `seq` (relleno con ceros) y lánzalo con `ffuf`:

```shell-session
$ seq -w 0 9999 > tokens.txt
$ ffuf -w tokens.txt -u "http://target.htb/reset_password.php?token=FUZZ" -fr "token is invalid"
[Status: 200, Size: 2667] FUZZ: 6182
```

> [!important]+ La carrera contra el reloj
> Si el token caduca rápido o solo existe mientras hay un reset activo, el ataque tiene ventana corta. La táctica: <mark style="background: #FFB86CA6;">dispara tú el reset del usuario objetivo</mark> (si conoces su email) para **crear** un token activo, y fuérzalo de inmediato. Para tokens grandes (no de 4 dígitos), la fuerza bruta no escala y el ataque pasa a ser de **predicción**: recoger varios tokens propios, inferir el patrón (timestamp, contador) y calcular el de la víctima.

# Por qué ocurre

El dev asume que el token "es secreto" y descuida su entropía o su rate limiting. <mark style="background: #8000E1A6;">Un token de reset es funcionalmente una contraseña temporal</mark>: debe ser largo (≥128 bits), generado con un CSPRNG, de un solo uso, caducar pronto y estar atado a la cuenta. Cualquier desviación es explotable. La defensa contra el brute force (rate limiting en el endpoint de validación) y su evasión, en [[05 - Bypass de protecciones anti-fuerza-bruta]].

> [!info]+ Fuentes
> - [PortSwigger — Password reset poisoning / broken logic](https://portswigger.net/web-security/authentication/other-mechanisms)
> - [OWASP — Forgot Password Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html)
