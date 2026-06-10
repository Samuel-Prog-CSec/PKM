---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - CSRF
  - CORS
Fecha de actualización: 2026-06-08
Nota previa: "[[06 - Tokens CSRF débiles y CSRF con JSON]]"
Nota siguiente:
Area: "[[CSRF.base|CSRF]]"
---
---

La detección de CSRF y CORS se hace en buena parte a mano —el [[03 - CORS Misconfigurations|test de `Origin` en Repeater]] es insustituible—, pero hay instrumental que la acelera y la escala. Este es el set para un engagement real.

# Generación de PoC CSRF

Una vez confirmado el endpoint vulnerable, el PoC es un HTML que auto-envía el formulario. Generarlo a mano es trivial, pero estas herramientas ahorran tiempo y cubren casos (multipart, `text/plain`):

| Herramienta | Qué aporta |
| - | - |
| **Burp Suite Pro** | `Engagement tools → Generate CSRF PoC` desde cualquier petición; genera el HTML con auto-submit |
| **XSRFProbe** | Auditoría CSRF completa: detecta tokens débiles/ausentes, analiza su entropía y genera PoC |
| **csrf-poc-generator** | Generador online rápido para un PoC puntual |

```shell-session
$ xsrfprobe -u https://target.htb/profile --crawl
```

<mark style="background: #FFB86CA6;">`XSRFProbe`</mark> ([0xInfection](https://github.com/0xInfection/XSRFProbe)) va más allá de generar el PoC: evalúa la **calidad** del token (si es predecible, si está atado a la sesión), justo los fallos de [[06 - Tokens CSRF débiles y CSRF con JSON|tokens débiles]].

# Detección de CORS misconfigurations

A escala, conviene pasar un escáner que pruebe las cuatro [[03 - CORS Misconfigurations|misconfiguraciones]] (reflejo de origen, `null`, prefijo/sufijo, wildcard) sobre una lista de URLs:

```shell-session
$ python3 corsy.py -u https://target.htb -i urls.txt
$ python3 cors_scan.py -u https://target.htb
```

- <mark style="background: #ADCCFFA6;">`Corsy`</mark> ([s0md3v](https://github.com/s0md3v/Corsy)) prueba sistemáticamente cada misconfiguración conocida y reporta cuáles afloran, incluyendo si `Access-Control-Allow-Credentials` está activo.
- **`CORScanner`** ([chenjj](https://github.com/chenjj/CORScanner)) hace lo mismo de forma multihilo, útil para superficies grandes.
- **Burp Suite Pro** detecta CORS misconfigs en su escáner activo y es la opción cómoda si ya trabajas en Burp.

> [!warning]+ El escáner confirma el reflejo, tú confirmas el impacto
> Un escáner CORS marca que el origen se refleja, pero <mark style="background: #FF5582A6;">el impacto real depende de **qué** datos hay tras ese endpoint y de si la cookie es `SameSite=None`</mark>. Una misconfig sobre un endpoint público sin datos sensibles es *informational*; la misma sobre `/profile` con `SameSite=None` es *high*. Verifica siempre exfiltrando datos reales en un PoC antes de reportar.

# Análisis manual y soporte

- **Burp Repeater**: el test base —cambiar `Origin` a un valor inventado y observar `Access-Control-Allow-Origin`/`-Credentials`— se hace aquí. Ninguna automatización lo sustituye para entender la lógica exacta de validación.
- **Param Miner** (extensión de Burp, de PortSwigger): descubre cabeceras y parámetros ocultos; útil para encontrar la cabecera que dispara un reflejo o un comportamiento CORS no documentado.
- **Interactsh** / **Burp Collaborator**: dan un endpoint OOB con TLS válido para recibir la exfiltración cuando no quieres montar tu propio [[00 - Primitivas y entorno de explotación|servidor de exfiltración]] o necesitas un certificado de confianza.

# Flujo de referencia

```text
Corsy/CORScanner (barrido)  →  Burp Repeater (confirmar lógica de validación)
                            →  PoC (Burp CSRF generator / XSRFProbe)
                            →  Interactsh/Collaborator (recibir exfil)
```

Las técnicas de CSRF se potencian enormemente cuando hay un XSS de por medio: el XSS elimina la barrera same-site y abre el pivote a la red interna. Eso es el siguiente sub-tema: [[00 - Introducción a la explotación XSS avanzada]].

> [!info]+ Fuentes y repos
> - [Corsy](https://github.com/s0md3v/Corsy) · [CORScanner](https://github.com/chenjj/CORScanner) · [XSRFProbe](https://github.com/0xInfection/XSRFProbe)
> - [PortSwigger — testing for CORS](https://portswigger.net/web-security/cors) · [Param Miner](https://github.com/PortSwigger/param-miner)
