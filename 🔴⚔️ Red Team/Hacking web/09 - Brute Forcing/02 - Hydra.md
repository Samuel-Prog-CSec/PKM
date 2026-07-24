---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
Fecha de actualización: 2026-06-23
Nota previa: "[[01 - Tipos de ataque - diccionario, híbrido y máscara]]"
Nota siguiente: "[[03 - Medusa y alternativas modernas]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
<mark style="background: #ADCCFFA6;">`Hydra` (THC-Hydra) es un cracker de logins de red en paralelo</mark>: lanza muchos intentos simultáneos contra un servicio vivo y soporta decenas de protocolos. En un PKM de web, sus dos módulos clave son `http-get` (Basic Auth) y `http-post-form` (formularios de login). El resto —SSH, RDP, FTP, BBDD— lo convierte en la navaja para los [[03 - Ataques remotos a servicios de red|ataques a servicios de la red interna]] una vez dentro.

# Anatomía del comando

```shell-session
$ hydra [opciones_login] [opciones_pass] [opciones_ataque] servicio://servidor
```

| Flag | Función |
| - | - |
| `-l USER` / `-L file` | Un usuario / lista de usuarios |
| `-p PASS` / `-P file` | Una contraseña / wordlist |
| `-t N` | Tareas en paralelo (hilos) |
| `-f` | Parar al primer acierto |
| `-s PORT` | Puerto no estándar |
| `-V` | Verbose (cada intento) |
| `-x MIN:MAX:charset` | Generar contraseñas (brute force puro) |
| `-M file` | Lista de objetivos (multi-target) |

Tabla de servicios útiles (web arriba, pivoting abajo):

| Servicio | Uso |
| - | - |
| `http-get` / `http-post-form` | Basic Auth / formularios web |
| `ssh` · `ftp` · `rdp` · `vnc` | Acceso remoto |
| `smtp` · `pop3` · `imap` | Correo |
| `mysql` · `mssql` | Bases de datos |

# Basic HTTP Authentication (`http-get`)

`Basic Auth` es un challenge-response rudimentario: el server responde `401` con la cabecera `WWW-Authenticate` que <mark style="background: #FFB86CA6;">solicita al navegador del usuario que presente un diálogo de inicio de sesión</mark>.

Una vez que el usuario proporciona su nombre de usuario y contraseña, el navegador los concatena en una única cadena, separados por dos puntos. Esta <mark style="background: #FFB8EBA6;">cadena se codifica después usando Base64</mark> y se incluye en la cabecera `Authorization` de las peticiones posteriores, siguiendo el formato `Basic <encoded_credentials>`. El servidor decodifica las credenciales, las verifica con su base de datos y concede o deniega el acceso en consecuencia.

```http
GET /protected HTTP/1.1
Host: www.example.com
Authorization: Basic YWxpY2U6c2VjcmV0MTIz
```

<mark style="background: #FFB8EBA6;">Al ir en cada petición (sin formulario, sin token, sin sesión), `Basic Auth` es trivial de forzar.</mark> Conociendo el usuario, solo iteras contraseñas:

```shell-session
$ hydra -l basic-auth-user -P 2023-200_most_used_passwords.txt 127.0.0.1 http-get / -s 81
[81][http-get] host: 127.0.0.1   login: basic-auth-user   password: <found>
1 of 1 target successfully completed, 1 valid password found
```

# Formularios de login (`http-post-form`)

El 95% de los logins web reales. El módulo manda POSTs sustituyendo `^USER^`/`^PASS^` y decide éxito/fracaso con una **condición**. Estructura:

```shell-session
$ hydra [opciones] target http-post-form "path:params:condición"
```

- `path`: endpoint del formulario (`/login`, `/`).
- `params`: cuerpo con placeholders → `username=^USER^&password=^PASS^`.
- `condición`: cómo distingue Hydra el resultado.
  - `F=texto` → **fallo** si ese texto aparece (lo más común: `F=Invalid credentials`).
  - `S=texto` o `S=302` → **éxito** si aparece ese texto/redirección.

<mark style="background: #ADCCFFA6;">Primero saca los nombres exactos de los campos</mark> (DevTools (`F12`) → Network, o interceptando con [[02 - Interceptación de peticiones|Burp]]). <mark style="background: #FFB8EBA6;">Envía un intento de inicio de sesión de muestra con cualquier credencial</mark>. Esto te permitirá ver la solicitud POST enviada al servidor. Encuentra la solicitud correspondiente al envío del formulario y <mark style="background: #8000E1A6;">revisa los datos del formulario, las cabeceras y la respuesta del servidor</mark>. Con `username`/`password` y el mensaje de error confirmados:

```shell-session
$ hydra -L top-usernames-shortlist.txt -P 2023-200_most_used_passwords.txt -f \
    IP -s 5000 http-post-form "/:username=^USER^&password=^PASS^:F=Invalid credentials"
[5000][http-post-form] host: IP   login: <user>   password: <pass>
```

Para brute force puro con charset generado (p. ej. RDP con patrón conocido), `-x`:

```shell-session
$ hydra -l administrator -x 6:8:a-zA-Z0-9 192.168.1.100 rdp
```

# Gotchas de producción (lo que HTB no cuenta)

> [!warning]+ Hydra no sabe leer tokens CSRF rotativos
> El fallo más común al lanzar `http-post-form` contra una app moderna: el formulario incluye un <mark style="background: #FFB86CA6;">token `CSRF` que cambia en cada carga</mark>, y como Hydra no scrape­a la respuesta para extraerlo, **todos** los intentos fallan con un token inválido (falsos negativos). Hydra solo admite valores estáticos o una cookie con `c=/path`. Para formularios con token rotativo el estándar es:
> - `ffuf` con dos peticiones (leer token → enviarlo) — ver [[03 - Medusa y alternativas modernas]].
> - **Burp Intruder** (Pitchfork) con *recursive grep* extrayendo el token de cada respuesta.
> - Un script con `requests.Session()` que mantiene cookies y token.

Otros dos que arruinan un ataque:

- <mark style="background: #FF5582A6;">`-t` alto dispara el rate limiting</mark>: bajar a `-t 4` (o menos) y no `-V` contra producción. Un barrido a 16 hilos te bloquea la IP y contamina el engagement. La evasión de estos controles va en [[05 - Defensas y evasión]].
- **Falsos positivos por condición mal elegida**: si la app devuelve siempre `200` y solo cambia el cuerpo, una `S=302` mal puesta marca todo como éxito. <mark style="background: #ADCCFFA6;">Verifica siempre la credencial "encontrada" a mano antes de reportarla</mark>.

<mark style="background: #8000E1A6;">Por eso, en bug bounty actual, Hydra cede terreno frente a `ffuf` y Burp Intruder para web</mark>, y se reserva para los protocolos de red donde sigue siendo imbatible. La comparativa y el resto del arsenal, en [[06 - Arsenal de herramientas para Brute Forcing]].

> [!info]+ Fuentes
> - [THC-Hydra — repositorio oficial](https://github.com/vanhauser-thc/thc-hydra)
> - [SecLists — Usernames / Passwords](https://github.com/danielmiessler/SecLists)
