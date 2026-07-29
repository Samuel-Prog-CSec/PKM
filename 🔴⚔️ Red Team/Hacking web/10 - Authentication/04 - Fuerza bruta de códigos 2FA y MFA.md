---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Descripción: "El MFA debería hacer inútil una contraseña robada"
Fecha de actualización: 2026-06-23
Nota previa: "[[03 - Fuerza bruta de tokens de reset]]"
Nota siguiente: "[[05 - Bypass de protecciones anti-fuerza-bruta]]"
Area: "[[Authentication.base|Authentication]]"
---
---

El MFA debería hacer inútil una contraseña robada. En la práctica, <mark style="background: #ADCCFFA6;">la implementación del segundo factor falla tanto que es uno de los hallazgos más frecuentes en bug bounty</mark>. Asumiendo credenciales ya obtenidas (`admin:admin` por phishing), el objetivo es saltarse el OTP. Hay muchas más vías que la fuerza bruta.

# Fuerza bruta del OTP

El caso base: un OTP de 4-6 dígitos sin límite de intentos. 4 dígitos son 10.000 combinaciones; 6 son un millón — ambos forzables si nada los frena. El OTP va atado a tu sesión (`PHPSESSID`), así que hay que enviar la cookie:

```shell-session
$ seq -w 0 9999 > tokens.txt
$ ffuf -w tokens.txt -u http://target.htb/2fa.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -b "PHPSESSID=fpfcm5b8dh1ibfa7idg0he7l93" -d "otp=FUZZ" -fr "Invalid 2FA Code"
[Status: 302] FUZZ: 6513
```

> [!warning]+ Cuidado con los falsos positivos
> En el lab de HTB, tras el OTP correcto la sesión queda autenticada y **todas** las peticiones posteriores devuelven `302`. El primer acierto (`6513`) es el real; el resto son la sesión ya validada redirigiendo. Verifica siempre el primer hit, no el último.

<mark style="background: #FFB86CA6;">La ausencia de rate limiting en el OTP es el fallo #1 del 2FA.</mark> Si lo hay, se evade con las técnicas de [[05 - Bypass de protecciones anti-fuerza-bruta|rate limiting]]: rotación de IP con fireprox, race conditions con Turbo Intruder (varios OTP "a la vez" antes de que cuente los fallos).

# Bypass sin adivinar el código

Forzar el OTP es la vía ruidosa. Las elegantes lo **rodean**:

- <mark style="background: #FFB86CA6;">**Forced browsing**</mark>: tras introducir usuario/contraseña pero **antes** del OTP, accede directamente al recurso post-login (`/admin.php`, `/dashboard`). Si la app marca la sesión como "logueada" antes de verificar el 2FA, te saltas el segundo factor por completo. Es exactamente lo que permite el lab de HTB.
- **OTP no invalidado / reutilizable**: si un código usado sigue siendo válido, o si el mismo vale en varias cuentas, no hace falta forzarlo.
- **Manipulación de la respuesta**: si la verificación devuelve `{"2fa_verified": false}` y el cliente decide en base a eso, cambiar `false`→`true` en la respuesta (con Burp) salta el control.
- **Omisión del paso**: parámetros como `2fa=success` o eliminar el paso del flujo multistep si el backend confía en el cliente.
- **Códigos de backup**: el flujo de "no tengo mi dispositivo" suele estar peor protegido — códigos de recuperación cortos o sin rate limit son un objetivo más blando que el OTP principal.

# MFA fatigue (push bombing)

El ataque moderno contra el MFA por **push**: <mark style="background: #FFB86CA6;">con la contraseña ya en mano, el atacante lanza decenas de notificaciones push</mark> hasta que la víctima, harta o confundida, pulsa "Aprobar". <mark style="background: #8000E1A6;">Así cayó Uber en 2022.</mark> No rompe criptografía: explota al humano — y sigue ganando: el *Verizon DBIR 2025* le da ~**3,5×** la tasa de éxito de los bypasses técnicos de MFA. El *number matching* (teclear un número que el atacante ve en pantalla) lo mitiga, pero la única defensa que Microsoft cifra en >99% de bloqueo es el **MFA phishing-resistant (FIDO2/passkeys)**, que ata la autenticación al `origin` y mata AiTM, fatigue y device code a la vez.

# Device code phishing

El vector MFA-bypass dominante de 2025-2026 (campaña **Storm-2372**, 340+ organizaciones M365). Abusa del **OAuth 2.0 Device Authorization Grant** (RFC 8628), pensado para dispositivos sin teclado (TVs, IoT):

1. El atacante inicia un *device code flow* contra el IdP (Microsoft/Google) y obtiene un `user_code` legítimo.
2. Mediante ingeniería social (lure de Teams/correo) consigue que la víctima introduzca ese código en la página **real** `microsoft.com/devicelogin` y apruebe con su MFA.
3. <mark style="background: #FFB86CA6;">El atacante recibe los `access` y `refresh tokens` de la víctima.</mark>

> [!warning]+ Por qué evade todo
> No hay página falsa, no se roban credenciales, el login ocurre en el portal **legítimo** del IdP con el MFA real de la víctima. Por eso esquiva la detección y hasta a un usuario entrenado contra phishing AiTM. <mark style="background: #8000E1A6;">Es la evolución de "robar la sesión" sin montar un proxy</mark>. Defensa: bloquear el device code flow en Conditional Access. Evolución 2025: registrar un dispositivo en Entra con el token para obtener un *Primary Refresh Token* persistente.

> [!important]+ El bypass definitivo: robar la sesión
> Ningún MFA protege si robas la **cookie de sesión ya autenticada**: la presentas y estás dentro sin pasar por ningún factor. Es lo que hacen los kits de phishing tipo *adversary-in-the-middle* (Evilginx) y el [[10 - Ataques a tokens de sesión|robo de tokens de sesión]]. Por eso, en superficies con MFA fuerte, el ataque se desplaza de "romper el factor" a "robar la sesión".

> [!info]+ Fuentes
> - [PortSwigger — 2FA bypass / brute-forcing 2FA codes](https://portswigger.net/web-security/authentication/multi-factor)
> - [CISA — Implementing Number Matching in MFA (anti push-bombing)](https://www.cisa.gov/MFA)
> - [Uber 2022 — MFA fatigue breach](https://www.uber.com/newsroom/security-update/)
