---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Authentication
Descripción: "Hay enumeración de usuarios cuando la app responde de forma distinta ante un usuario válido y uno inválido"
Fecha de actualización: 2026-06-23
Nota previa: "[[00 - Introducción a la autenticación]]"
Nota siguiente: "[[02 - Fuerza bruta de contraseñas en el login]]"
Area: "[[Authentication.base|Authentication]]"
---
---

<mark style="background: #ADCCFFA6;">Hay enumeración de usuarios cuando la app responde de forma distinta ante un usuario válido y uno inválido.</mark> Conocer un usuario válido es la mitad del trabajo: convierte un brute force a ciegas en uno dirigido, habilita el [[02 - Fuerza bruta de contraseñas en el login|password spraying]] y permite ataques de OSINT contra esa persona. Por eso es el **primer** paso del flujo de ataque a autenticación.

Los devs lo subestiman ("el usuario no es secreto"), pero si el username es el identificador primario de login —y la gente lo reutiliza en FTP, RDP, SSH—, filtrarlo es un hallazgo real.

# Dónde se filtra: los tres vectores

| Vector | Cómo se delata |
| - | - |
| `Login` | "Usuario desconocido" vs "Contraseña incorrecta" |
| `Registro` | "Ese usuario/email ya existe" |
| `Password reset` | "Te hemos enviado un correo" vs "No existe esa cuenta" |

<mark style="background: #FFB8EBA6;">El reset de contraseña es el vector más olvidado</mark>: aunque el login devuelva un error genérico, el formulario de "olvidé mi contraseña" suele confirmar si el email existe. Probar los tres es obligatorio.

# Vía mensajes de error

El caso de libro: el login distingue "Unknown user" de "Invalid credentials". Se enumera con `ffuf` filtrando la respuesta de usuario inexistente:

```shell-session
$ ffuf -w xato-net-10-million-usernames.txt -u http://target/index.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=FUZZ&password=invalid" -fr "Unknown user"
[Status: 200, Size: 3271, Words: 754] FUZZ: consuelo
```

`-fr "Unknown user"` oculta los fallos; lo que queda son usuarios válidos. El usuario hallado pasa directo a [[02 - Fuerza bruta de contraseñas en el login|fuerza bruta de contraseña]].

# Vía canales laterales (cuando el mensaje es genérico)

La defensa moderna unifica el mensaje a "Invalid credentials" siempre. Pero la diferencia se cuela por otros canales que el dev no controló:

- <mark style="background: #FFB86CA6;">**Timing**</mark>: si la app solo verifica el hash de la contraseña cuando el usuario existe, un usuario válido tarda **más** (bcrypt es lento a propósito) que uno inválido (que ni llega a comparar). Mides el delta de tiempo y enumeras aunque la respuesta sea idéntica. Es un oráculo silencioso y muy fiable. <mark style="background: #FFB8EBA6;">Para que no lo ahogue el jitter de red, mide **muchas repeticiones** por usuario y compara medianas/percentiles, no medias</mark> — en Burp Intruder por la columna de tiempo de respuesta, o `ffuf -o json` post-procesando el campo `duration`.
- **Longitud / código / redirección**: respuestas de igual texto pero distinto `Content-Length`, distinto status, o un `Set-Cookie`/redirect que solo aparece para uno de los casos.
- **Rate limit selectivo**: si el lockout o el `429` solo se dispara con usuarios válidos, el propio control de seguridad se convierte en el oráculo de enumeración.

> [!warning]+ La protección mal hecha filtra igual
> Una app puede mostrar el mismo error pero **bloquear la cuenta** solo si el usuario existe (PortSwigger: *username enumeration via account lock*). El atacante no necesita el mensaje: el cambio de comportamiento —tiempo, bloqueo, longitud— basta. Por eso la única defensa robusta es que **todos** los caminos (mensaje, tiempo, estado) sean indistinguibles, algo difícil de garantizar.

# Casos reales: enumeración en CMS

WordPress enumera usuarios por defecto por múltiples vías, útiles en cualquier bug bounty con WP:

```shell-session
$ curl -s "http://wordpress.htb/wp-json/wp/v2/users" | jq '.[].slug'   # REST API
$ curl -s "http://wordpress.htb/?author=1"                              # redirige a /author/<login>
```

La REST API (`/wp-json/wp/v2/users`) lista logins y slugs sin autenticación salvo que se haya endurecido; `?author=N` redirige revelando el `nicename`. Se automatiza con `wpscan --enumerate u`.

<mark style="background: #8000E1A6;">Salida de esta fase: una lista de usuarios confirmados.</mark> Con ella, el ataque deja de ser fuerza bruta a ciegas y pasa a ser dirigido. Generación de variantes de usuario y esquema corporativo, en [[04 - Generación de wordlists|Brute Forcing]].

> [!info]+ Fuentes
> - [PortSwigger — Username enumeration](https://portswigger.net/web-security/authentication/securing#preventing-username-enumeration) · [via response timing](https://portswigger.net/web-security/authentication/password-based)
> - [OWASP WSTG — Testing for Account Enumeration](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/03-Identity_Management_Testing/04-Testing_for_Account_Enumeration_and_Guessable_User_Account)
> - [SecLists — Usernames](https://github.com/danielmiessler/SecLists/tree/master/Usernames)
