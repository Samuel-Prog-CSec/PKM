---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/CRLF
  - Tipo/Defensa
Descripción: "Cierre del bloque CRLF: cómo automatizar la detección con herramientas actuales y cómo prevenir cada variante a nivel de código"
Fecha de actualización: 2026-07-14
Nota previa: "[[04 - SMTP Header Injection]]"
Nota siguiente: "[[06 - Introducción a HTTP Request Smuggling]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Cierre del bloque CRLF: cómo **automatizar la detección** con herramientas actuales y cómo **prevenir** cada variante a nivel de código.

# Arsenal

| Herramienta | Tipo | Uso |
| - | - | - |
| **CRLFsuite** | Python (`pip3 install crlfsuite`) | Fuzzing de puntos CRLF, detección de WAF, genera PoCs — el de HTB |
| **crlfuzz** | Go (`go install`) | Fuzzer CRLF **rápido**, muy usado en bug bounty a escala |
| **nuclei** | Templates | `crlf-injection` para triage masivo |
| **Burp** | Repeater/Intruder | Prueba manual e inyección de `%0d%0a` en cada parámetro |
| **gau / waybackurls + gf** | Recon | Recolectar URLs con parámetros candidatos (redirect, url, header) |

```shell-session
# CRLFsuite — apunta al parámetro sospechoso en la URL
$ crlfsuite -t "http://target/?target=asd"
[VLN] .../?target=%0d%0a%0d%0a%3Cscript%3Ealert(document.domain)%3C/script%3E

# crlfuzz — rápido, ideal sobre listas
$ crlfuzz -u "http://target/?redirect=test"
$ cat urls.txt | crlfuzz

# Pipeline de bug bounty: recolectar → filtrar → fuzzear
$ gau target.com | gf redirect | crlfuzz
$ nuclei -tags crlf -l urls.txt
```

> [!info] Los payloads que generan las herramientas
> Fíjate en el patrón que produce CRLFsuite: `...%0d%0aX-XSS-Protection%3a0%0d%0aContent-Type:text/html%0d%0a%0d%0a<script>...`. <mark style="background: #ADCCFFA6;">Inyecta `X-XSS-Protection: 0` y un `Content-Type: text/html`</mark> para asegurar que la respuesta partida se interpreta como HTML y no la bloquea ningún filtro. Es la plantilla estándar de CRLF→XSS: forzar el `Content-Type`, desactivar protecciones y meter el body tras el `%0d%0a%0d%0a`.

# Prevención por contexto

**Log Injection** — usar el logging del servidor; si es custom, **URL-encodear** el input antes de escribirlo (en PHP, `urlencode()` codifica `CR`/`LF`). Mejor aún, **logging estructurado** (JSON) donde el input es un valor, no sintaxis:

```php
// VULNERABLE
$log = "Request from $ip ($ua): " . $_POST['msg'];
// SEGURO
$log = "Request from $ip (" . urlencode($ua) . "): " . urlencode($_POST['msg']);
```

**Response Splitting** — usar funciones de alto nivel para cabeceras/cookies. En PHP, `header()` <mark style="background: #FFB8EBA6;">rechaza CRLF desde la 5.1.2</mark> (ya no permite enviar múltiples cabeceras en una llamada). Solo versiones anteriores a 5.1.2 son vulnerables — si te topas con una en un engagement, <mark style="background: #FF5582A6;">vale la pena probar response splitting</mark>.

**SMTP Header Injection** — no meter input del usuario en cabeceras SMTP salvo necesidad; si hace falta, **URL-encodear** y usar librerías (PHPMailer) que separan cabeceras de valores:

```php
// VULNERABLE: $_POST['email'] va crudo al header From
$headers = "From: " . $_POST['email'] . "\r\n";
// SEGURO
$headers = "From: " . urlencode($_POST['email']) . "\r\n";
```

> [!success] La regla transversal
> <mark style="background: #FF5582A6;">Todo dato controlable por el usuario que acabe donde `\r\n` tiene significado (cabecera HTTP/SMTP, log, protocolo) debe codificarse o rechazarse.</mark> Y siempre preferir APIs de alto nivel que traten el input como **valor**, no como sintaxis. Es la misma filosofía que en [[00 - Introducción a XSS|XSS]] (separar datos de código) aplicada al nivel de protocolo.

Con esto cierra el bloque CRLF. El siguiente, [[06 - Introducción a HTTP Request Smuggling|HTTP Request Smuggling]], lleva la inyección de `\r\n` a su forma más peligrosa: desincronizar dos servidores enteros.

## Referencias

- [CRLFsuite](https://github.com/Nefcore/CRLFsuite) · [crlfuzz](https://github.com/dwisiswant0/crlfuzz)
- [PHP `header()` — HTTP response splitting fix (5.1.2)](https://www.php.net/manual/en/function.header.php)
