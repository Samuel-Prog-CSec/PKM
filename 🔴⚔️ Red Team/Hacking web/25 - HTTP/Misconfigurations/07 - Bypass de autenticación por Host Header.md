---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Host-Header
Fecha de actualización: 2026-07-14
Nota previa: "[[06 - Introducción a los Host Header Attacks]]"
Nota siguiente: "[[08 - Password Reset Poisoning]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

El primer ataque concreto: una aplicación que <mark style="background: #ADCCFFA6;">decide el control de acceso a partir del `Host`</mark>. Es una variante de "bypass de autenticación por confiar en input del cliente", hermana de las de [[08 - Bypass de autenticación - acceso directo|acceso directo]] y [[09 - Bypass de autenticación - modificación de parámetros|modificación de parámetros]] del módulo de autenticación — aquí el parámetro manipulable es la cabecera `Host`.

# El patrón vulnerable

Un panel `/admin.php` responde: *"The admin area can only be accessed locally!"*. La app quiere distinguir peticiones **internas** de **externas**. ¿Cómo?

- **Opción segura**: comprobar la IP de origen (`$_SERVER['REMOTE_ADDR']` en PHP). <mark style="background: #FFB8EBA6;">Pero tras un **reverse proxy** ese valor siempre es la IP del proxy</mark>, no la del cliente — por eso los devs se ven tentados de mirar otra cosa.
- **Opción vulnerable**: comprobar el `Host` (o `X-Forwarded-For`), que es **controlable por el cliente**.

Si la comprobación es sobre el `Host`, basta con afirmar que vienes de dentro:

```http
GET /admin.php HTTP/1.1
Host: localhost
```

<mark style="background: #FFB86CA6;">`Host: localhost` → la app cree que la petición es local → acceso al panel admin</mark>. La misma idea con `127.0.0.1`, `internal`, `intranet`, `[::1]` o el hostname interno que la app considere "de confianza".

# Fuzzing cuando acepta un rango de IPs

Si en vez de `localhost` la app confía en un **rango de IPs internas** concreto, probar a mano es inviable. Se **fuzzea** el `Host` con una wordlist de IPs privadas. Generar el rango `192.168.0.0/16`:

```bash
for a in {0..255}; do for b in {0..255}; do echo "192.168.$a.$b" >> ips.txt; done; done
```

Y fuzzear con `ffuf`, filtrando por el tamaño de la respuesta de "denegado" (`-fs 752`):

```shell-session
$ ffuf -u http://target/admin.php -w ips.txt -H 'Host: FUZZ' -fs 752
192.168.178.28   [Status: 200, Size: 747]   ← bypass
192.168.178.32   [Status: 200, Size: 747]
```

Las IPs que devuelven un tamaño distinto al de "denegado" son las que la app considera internas. Añade también `10.0.0.0/8` y `172.16.0.0/12`, más los valores clásicos (`localhost`, `127.0.0.1`, `0.0.0.0`, `[::1]`).

> [!important] El hermano: `X-Forwarded-For` spoofing
> El mismo antipatrón aparece con la cabecera **`X-Forwarded-For`** (y `X-Real-IP`, `X-Client-IP`, `True-Client-IP`, `Forwarded`). Muchas apps la usan para saber la IP "real" del cliente tras el proxy… y es igual de **falsificable**. Contra un panel "solo interno", <mark style="background: #FF5582A6;">**siempre** prueba también `X-Forwarded-For: 127.0.0.1`</mark> y variantes. Es uno de los bypass más rentables en bug bounty (actuators de Spring Boot, paneles internos, rate limits por IP).
> ```http
> X-Forwarded-For: 127.0.0.1
> X-Forwarded-For: 10.0.0.1, 127.0.0.1
> ```

> [!warning] No es teoría de laboratorio
> Endpoints de administración o *actuator* "restringidos a la red interna" que confían en `Host`/`X-Forwarded-For` son un hallazgo recurrente en programas reales. Si además el proxy **añade** su propio `X-Forwarded-For`, prueba a inyectar múltiples valores: algunos backends toman el **primero**, otros el **último**.

La técnica de fuzzing del `Host` es la misma del [[20 - Fuzzing de vhosts y subdominios|fuzzing de virtual hosts]] del módulo de reconocimiento; el siguiente paso, cuando el `Host` no da acceso sino que se **refleja en un enlace**, es el [[08 - Password Reset Poisoning|password reset poisoning]].

## Referencias

- [PortSwigger — Host header authentication bypass](https://portswigger.net/web-security/host-header/exploiting#accessing-restricted-functionality)
- [HackTricks — Special HTTP headers (IP spoofing)](https://book.hacktricks.xyz/pentesting-web/special-http-headers)
