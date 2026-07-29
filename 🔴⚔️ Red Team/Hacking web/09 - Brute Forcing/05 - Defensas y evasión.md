---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
  - Tipo/Defensa
Descripción: "En cualquier aplicación seria, lanzar Hydra a 16 hilos no acaba con un acceso, acaba con tu IP bloqueada"
Fecha de actualización: 2026-06-23
Nota previa: "[[04 - Generación de wordlists]]"
Nota siguiente: "[[06 - Arsenal de herramientas para Brute Forcing]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
En cualquier aplicación seria, lanzar [[02 - Hydra|Hydra]] a 16 hilos no acaba con un acceso, acaba con tu IP bloqueada. <mark style="background: #ADCCFFA6;">El brute force real hoy no va de velocidad, va de **evadir** los controles anti-fuerza-bruta.</mark> Esta nota cataloga esos controles (lado defensa) y cómo se saltan (lado ataque) — el material que HTB no desarrolla y que de verdad importa en bug bounty.

# Lado defensa: qué te frena y cómo te detectan

| Control | Qué hace |
| - | - |
| `Rate limiting` | Limita peticiones por IP / cuenta / endpoint; responde `429 Too Many Requests` |
| `Account lockout` | Bloquea la cuenta tras N fallos (típico 3–5) |
| `CAPTCHA` | Exige resolver un reto, normalmente tras X fallos |
| `MFA` | Aunque adivines la contraseña, falta el segundo factor |
| `WAF` / detección de anomalías | Cloudflare, Akamai... marcan patrones de credential stuffing |

<mark style="background: #FFB8EBA6;">Las señales con las que el `blue team` te caza</mark>: pico de `401`/`403`/`429`, **una IP probando muchos usuarios** (firma de password spraying), **muchas IPs contra un usuario** (credential stuffing), e *impossible travel* (logins geográficamente incompatibles). Conocerlas es saber qué ruido evitar.

# Evasión del rate limiting por IP

La mayoría del rate limiting se indexa por IP de origen. Hay dos formas de romperlo.

**1. Spoofing de la IP vía cabeceras.** Si la app calcula el límite con una cabecera que tú controlas (clásico detrás de proxy/CDN mal configurado), cambiarla resetea el contador. <mark style="background: #FF5582A6;">Un `429` que pasa a `200` al añadir `X-Forwarded-For` es un bug reportable por sí mismo.</mark> Cabeceras a probar:

```http
X-Forwarded-For: 1.2.3.4
X-Real-IP: 1.2.3.4
X-Originating-IP: 1.2.3.4
X-Remote-IP: 1.2.3.4
X-Client-IP: 1.2.3.4
```

Rota un valor distinto por intento (Burp Intruder con payload en la cabecera, o `ffuf` con `-H`). Variantes que a veces cuelan: doble `X-Forwarded-For`, o `X-Forwarded-For: 127.0.0.1` (la app "se confía" de localhost).

**2. Rotación real de IP de origen.** Cuando el límite se calcula con la IP de red real (no una cabecera), necesitas salir por IPs distintas. El estándar:

- <mark style="background: #FFB86CA6;">`fireprox`</mark> — levanta un endpoint de **AWS API Gateway** que reenvía a tu objetivo; cada petición sale por una IP distinta del pool gigante de AWS. IP rotation pseudo-infinita y gratis.
- `requests-ip-rotator` — librería Python que hace lo mismo desde tu script (`requests`), transparente.
- Pools de proxies / residenciales para superficies con geofencing.

```shell-session
$ python fire.py --command create --url https://target.com   # crea el proxy rotador
$ ffuf -u https://<api-gateway-url>/login -X POST -d 'user=admin&pass=PASS' -w pw.txt:PASS
```

> [!warning]+ fireprox sigue funcionando, pero cuidado con la política de AWS
> AWS prohíbe en su *Acceptable Use Policy* usar API Gateway para pentesting saliente: `fireprox` funciona técnicamente (la rotación es un efecto colateral del routing de AWS), pero usarlo contra un objetivo externo viola la política y puede costarte la cuenta si el objetivo reporta el abuso. Además, las IPs de AWS son públicas y muchos WAF (Cloudflare, Akamai) ya retan el tráfico de API Gateway. Alternativas multi-cloud vivas: <mark style="background: #FFB86CA6;">`OmniProx`</mark> (rota sobre AWS/Azure/GCP/Cloudflare — nace como reemplazo de fireprox) y `gigaproxy` (AWS Lambda + API GW).

# Evasión del account lockout

El lockout protege la **cuenta**, no el sistema. Se esquiva cambiando el eje del ataque:

- <mark style="background: #8000E1A6;">`Password spraying`</mark>: pocas contraseñas (1–3 muy probables) contra **muchos** usuarios. Cada cuenta recibe pocos intentos → nunca se bloquea. Es la técnica anti-lockout por excelencia y la que de verdad funciona contra organizaciones. Lo desarrolla [[02 - Fuerza bruta de contraseñas en el login]].
- `Counter reset`: en implementaciones rotas, **un login válido resetea el contador de fallos**. Intercalas tu propia credencial cada 2 intentos en la wordlist y el lockout nunca salta.

# Bugs de lógica en la protección (PortSwigger)

Los fallos más jugosos no esquivan el control, lo **rompen**:

- **Múltiples credenciales por petición**: si el login acepta un array JSON de contraseñas y el backend itera comparando, pruebas decenas por petición → el rate limiting (que cuenta peticiones) es irrelevante.
- **Race condition**: enviar muchos intentos *en paralelo* antes de que el contador de fallos se incremente. Con HTTP/2 single-packet attack (Turbo Intruder) se cuelan N intentos "a la vez".
- **Variación de endpoint**: `/login`, `/api/v1/login`, `/api/v3/login`, `/Login` pueden no compartir contador. El endpoint móvil o legacy suele ir sin protección.
- **Multiplexación HTTP/2**: si el limitador cuenta conexiones TCP y no streams, cientos de streams sobre una conexión gastan "un" intento del cupo.

# Evasión de CAPTCHA

- **Reutilización de token**: si el `captcha-token` no se invalida server-side tras usarlo, resuelves uno y lo reenvías en cada intento.
- **Solo cliente**: el CAPTCHA está en el HTML pero el endpoint no lo valida → lo omites enviando la petición directa.
- Servicios de resolución (2captcha) como último recurso — atención al alcance y la legalidad del engagement.

> [!warning]+ Timing y sigilo
> Aunque tengas el bypass, ráfagas agresivas disparan la detección de anomalías del WAF. En un engagement con detección activa, **introduce jitter** y reparte en el tiempo. La métrica que importa no es "intentos/seg", es "pasar desapercibido el tiempo necesario". El ataque sigiloso por excelencia sigue siendo el spraying lento (1 intento por cuenta cada varias horas).

El brute force protegido se aborda con el mismo método visto desde [[05 - Bypass de protecciones anti-fuerza-bruta|Broken Authentication]]; aquí queda el catálogo de técnica. El instrumental (fireprox, Turbo Intruder, Burp Intruder), en [[06 - Arsenal de herramientas para Brute Forcing]].

> [!info]+ Fuentes
> - [HackTricks — Rate Limit Bypass](https://book.hacktricks.wiki/en/pentesting-web/rate-limit-bypass.html)
> - [PortSwigger — Vulnerabilities in password-based login](https://portswigger.net/web-security/authentication/password-based) · [Bypassing rate limits via race conditions](https://portswigger.net/web-security/race-conditions/lab-race-conditions-bypassing-rate-limits)
> - [fireprox (ustayready)](https://github.com/ustayready/fireprox) · [requests-ip-rotator (Ge0rg3)](https://github.com/Ge0rg3/requests-ip-rotator)
