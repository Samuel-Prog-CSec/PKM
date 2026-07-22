---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Fecha de actualización: 2026-07-15
Nota previa: "[[01 - Broken Object Level Authorization (API1)]]"
Nota siguiente: "[[03 - Broken Object Property Level Authorization (API3)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Una API sufre `Broken Authentication` si <mark style="background: #ADCCFFA6;">alguno de sus mecanismos de autenticación puede saltarse o eludirse</mark>. En el lab lo materializamos como `CWE-307: Improper Restriction of Excessive Authentication Attempts` (la falta de rate-limiting). La **política de contraseñas débil** que lo hace explotable es un CWE distinto: `CWE-521 (Weak Password Requirements)`.

# Escenario: política de contraseñas débil + sin rate-limit

Como customer (`htbpentester3@hackthebox.com`), nos logueamos en `/api/v1/authentication/customers/sign-in` y obtenemos el `JWT`. Al actualizar nuestra contraseña vía `PATCH /api/v1/customers/current-user`, la API rechaza `pass` con un mensaje revelador: *"passwords must be at least six characters long"*. <mark style="background: #FF5582A6;">El mensaje de validación filtra la política</mark>: mínimo 6 caracteres, sin exigir complejidad. Ponemos `123456` y lo acepta.

<mark style="background: #8000E1A6;">Si la política es tan débil para nosotros, otros customers habrán registrado contraseñas igualmente inseguras</mark>. Con eso, y sin rate-limiting, el brute-force es viable.

# Brute-force con ffuf (dos parámetros)

Primero capturamos el mensaje de fallo del sign-in con credenciales incorrectas: `Invalid Credentials`. Nos dan tres objetivos de alto valor y usamos el diccionario `xato-net-10-million-passwords-10000` de SecLists.

Como fuzzeamos **dos** parámetros a la vez (email y password), usamos `-w` dos veces con keywords `EMAIL` y `PASS`:

```shell-session
$ ffuf -w /opt/seclists/Passwords/xato-net-10-million-passwords-10000.txt:PASS \
       -w customerEmails.txt:EMAIL \
       -u http://TARGET/api/v1/authentication/customers/sign-in \
       -X POST -H "Content-Type: application/json" \
       -d '{"Email": "EMAIL", "Password": "PASS"}' \
       -fr "Invalid Credentials" -t 100

[Status: 200, Size: 393] EMAIL: IsabellaRichardson@gmail.com | PASS: qwerasdfzxcv
```

`-fr "Invalid Credentials"` filtra las respuestas de fallo; lo que quede es un acierto. Con `IsabellaRichardson@gmail.com:qwerasdfzxcv` nos autenticamos como ella y accedemos a toda su información.

> [!tip]+ Otros objetivos de brute-force en APIs
> Si la política de contraseñas es fuerte, ataca lo que suele tener **baja entropía**: `OTP` de reset (4-6 dígitos), respuestas a preguntas de seguridad, o tokens de reset predecibles. Sin rate-limiting, un OTP de 6 dígitos son 10⁶ intentos — horas, no años.

# Modernización: el espectro completo de Broken Authentication

HTB se centra en el brute-force, pero `API2:2023` cubre mucho más. En un pentest de API 2026, revisa también:

- <mark style="background: #FFB86CA6;">**Ataques al `JWT`**</mark>: secreto débil (crackeable con `hashcat`/`jwt_tool`), `alg: none`, confusión `RS256`→`HS256`, `kid` injection, `jku`/`x5u` apuntando a tu servidor. Todo esto en [[01 - Introducción a JWT|JWT]] y [[00 - Introducción a los mecanismos de autenticación|Authentication avanzada]].
- **Credential stuffing**: reutilizar credenciales filtradas de otras brechas (más efectivo que fuerza bruta pura).
- **Bypass de rate-limit**: cabeceras `X-Forwarded-For`, `X-Real-IP` rotando, o endpoints alternativos (`/v1` vs `/v2`) sin el límite. Ver [[00 - Introducción al brute forcing|Brute Forcing]].
- **Tokens que no expiran** o que no se invalidan al hacer logout/reset.

# Prevención

- **Rate-limiting** por IP y por cuenta en el sign-in (y en reset/OTP).
- **Política de contraseñas robusta**: mínimo 12 caracteres, complejidad, prohibición de contraseñas filtradas (comparar contra bases como HIBP), historial y expiración.
- **MFA/OTP** antes de completar la autenticación.

Siguiente: [[03 - Broken Object Property Level Authorization (API3)|BOPLA]], donde la API expone o deja modificar propiedades que no debería.

## Referencias

- OWASP — [API2:2023 Broken Authentication](https://owasp.org/API-Security/editions/2023/en/0xa2-broken-authentication/)
- MITRE — [CWE-307](https://cwe.mitre.org/data/definitions/307.html)
- [jwt_tool](https://github.com/ticarpi/jwt_tool) · SecLists — [xato-net passwords](https://github.com/danielmiessler/SecLists/tree/master/Passwords)
- HTB Academy — *API Attacks* (base, 2024)
