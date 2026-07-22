---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
Fecha de actualización: 2026-06-23
Nota previa: "[[02 - Hydra]]"
Nota siguiente: "[[04 - Generación de wordlists]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
---

<mark style="background: #ADCCFFA6;">`Medusa` es el primo de [[02 - Hydra|Hydra]]: cracker de logins paralelo, modular y rápido.</mark> Hace lo mismo con flags distintos. Importa conocer los dos porque cada uno falla en cosas distintas, y porque para web ambos quedan por detrás de `ffuf` cuando hay tokens de por medio.

# Sintaxis de Medusa

```shell-session
$ medusa [opciones_target] [opciones_credenciales] -M módulo [opciones_módulo]
```

| Flag | Función |
| - | - |
| `-h HOST` / `-H file` | Un objetivo / lista de objetivos |
| `-u USER` / `-U file` | Un usuario / lista |
| `-p PASS` / `-P file` | Una contraseña / wordlist |
| `-M módulo` | `ssh`, `ftp`, `http`, `web-form`, `rdp`... |
| `-m "OPCIÓN"` | Opción específica del módulo |
| `-t N` | Logins en paralelo |
| `-f` / `-F` | Parar al primer acierto (host / global) |
| `-n PORT` | Puerto no estándar |
| `-e ns` | Probar password vacía (`n`) y password = usuario (`s`) |

<mark style="background: #FF5582A6;">`-e ns` es un chequeo de 10 segundos que vale oro</mark>: detecta cuentas con contraseña vacía o igual al usuario antes de lanzar ninguna wordlist. Primer disparo en cualquier servicio.

```shell-session
$ medusa -h IP -n PORT -u sshuser -P 2023-200_most_used_passwords.txt -M ssh -t 3
ACCOUNT FOUND: [ssh] Host: IP User: sshuser Password: 1q2w3e4r5t [SUCCESS]
```

Para login web, el módulo `web-form`:

```shell-session
$ medusa -h www.example.com -U users.txt -P passwords.txt \
    -M web-form -m FORM:"username=^USER^&password=^PASS^:F=Invalid"
```

Donde Medusa brilla de verdad es en **multi-host** (`-H servers.txt`): barrer la misma credencial contra muchas máquinas a la vez en la fase de [[03 - Pivote a aplicaciones internas|pivoting]] interno, tras comprometer un primer host.

# Hydra vs. Medusa

| | `Hydra` | `Medusa` |
| - | - | - |
| Multi-host | `-M targets.txt` | `-H` (más natural y rápido) |
| Login web | `http-post-form` (cómodo) | `web-form` (más verboso) |
| Estabilidad threads | A veces falsos negativos a `-t` alto | Más estable en paralelo |
| Tokens CSRF | No los gestiona | Tampoco |

<mark style="background: #FFB8EBA6;">La elección rara vez importa: ambos sirven para protocolos de red y formularios simples.</mark> El problema es que **ninguno** de los dos sabe leer un token `CSRF` rotativo ni seguir un flujo de varios pasos, que es justo lo que tiene cualquier login web moderno.

# `ffuf`: el brute force de login web actual

Cuando el objetivo es un formulario HTTP, <mark style="background: #FFB86CA6;">`ffuf` supera a Hydra/Medusa</mark>: es el mismo fuzzer que ya usas en [[15 - Introducción al web fuzzing|recon]], con control total sobre petición, cabeceras, modo de combinación y filtros de respuesta. Sin token, un ataque de usuario×contraseña (`clusterbomb`) es directo:

```shell-session
$ ffuf -request login.req -mode clusterbomb \
    -w users.txt:UF -w passwords.txt:PF \
    -fr 'Invalid credentials'
```

```shell-session
$ ffuf -u https://target/login -X POST \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d 'username=UF&password=PF' \
    -w users.txt:UF -w passwords.txt:PF -mode clusterbomb -fr 'Invalid'
```

- `-mode clusterbomb` prueba todas las combinaciones; `pitchfork` empareja líneas (para listas `user:pass` alineadas).
- `-fr 'Invalid'` filtra (oculta) las respuestas de fallo: lo que **no** se filtra es el candidato.
- `-fc 401 -mc 200,302` filtra/matchea por código — útil cuando el éxito es un redirect.

> [!important]+ El token CSRF: por qué a veces nada de esto basta
> Si el formulario lleva un token que cambia por petición, ni Hydra, ni Medusa, ni un `ffuf` ingenuo funcionan: todos mandan un token caduco. Las tres salidas profesionales:
> - **Burp Intruder / Turbo Intruder** con *recursive grep* que extrae el token de cada respuesta y lo reinyecta.
> - **`patator`**, que puede pedir la página, scrapear el token y enviarlo en la misma acción.
> - Un script con `requests.Session()`.
>
> El arsenal completo —`patator`, `ncrack`, Turbo Intruder, manejo de tokens— está en [[06 - Arsenal de herramientas para Brute Forcing]]. La evasión de rate limiting y lockout, en [[05 - Defensas y evasión]].

> [!info]+ Fuentes
> - [Medusa — repositorio oficial (jmk-foofus)](https://github.com/jmk-foofus/medusa)
> - [ffuf — Fuzz Faster U Fool](https://github.com/ffuf/ffuf) · [ffuf — login brute force](https://www.acceis.fr/brute-force-http-post-form-with-ffuf/)
