---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[05 - Detección y evasión en Web Services]]"
Nota siguiente: ""
Area: "[[Web Services.base|Web Services]]"
---
---

Herramientas actuales para atacar web services SOAP/WSDL. Como el testing de SOAP es sobre todo **manual** —los escáneres genéricos apenas lo cubren—, estas son las que de verdad rinden.

| Herramienta | Tipo | Mejor para |
| - | - | - |
| Burp **Wsdler** | Extensión | Parsear WSDL → generar peticiones SOAP |
| Burp **WSDL Wizard** | Extensión | Descubrir WSDLs en un host |
| Burp **Content Type Converter** | Extensión | Convertir JSON↔XML (colar XXE) |
| **SoapUI / ReadyAPI** | Cliente + scanner | Import de WSDL, WS-Security, security scans |
| **Postman** | Cliente | Crafteo manual de SOAP (sin scanning) |
| `ffuf` / `wfuzz` | Fuzzer | Operaciones, parámetros y rutas WSDL |
| `python-zeep` | Librería | Parsear WSDL programáticamente |

# Burp Suite (el núcleo hoy)

- **Wsdler** — parsea un WSDL, extrae las operaciones y **autogenera las peticiones SOAP** para lanzarlas desde Repeater/Intruder. Click derecho → *Parse WSDL*. Envuelve el parser `soap-ws` de SoapUI sin su UI ([BApp Store](https://portswigger.net/bappstore/594a49bb233748f2bc80a9eb18a2e08f), [NetSPI](https://blog.netspi.com/hacking-web-services-with-burp/)). Mantenimiento antiguo: a veces atraganta con WSDLs complejos, pero sigue siendo el estándar.
- **WSDL Wizard** — *spider* que detecta WSDLs existentes y **descubre nuevos** en el host ([GitHub](https://github.com/PortSwigger/wsdl-wizard)).
- **Content Type Converter** — convierte peticiones entre JSON/XML/form. <mark style="background: #FF5582A6;">Clave para XXE</mark>: reenvía un endpoint JSON como `Content-Type: text/xml`; si el servidor lo parsea como XML, tienes [[14 - Introducción a XXE|XXE]] donde la app "no usaba XML" ([PortSwigger](https://portswigger.net/web-security/xxe)).

# SoapUI / ReadyAPI

**SoapUI** (open source) es lo mejor para **importar un WSDL** y generar las peticiones por defecto, con soporte nativo de **WS-Security** y WS-Addressing. **ReadyAPI** (de pago, sucesor de SoapUI Pro) añade **security scans automáticos**: SQLi, <mark style="background: #ADCCFFA6;">XXE, inyección XPath en mensajes SOAP</mark>, fuzzing, XSS y XML malformado ([SoapUI Security Scans](https://www.soapui.org/docs/security-testing/overview-of-security-scans/)). Es de las pocas suites que cubre SOAP de verdad.

# Complementos

- **Postman** — envía SOAP y trabaja con servicios basados en WSDL, pero **sin scanning ni virtualización** (eso es ReadyAPI). Bien para craftear a mano ([Postman vs SoapUI](https://www.postman.com/alternatives/postman-vs-soapui/)).
- **`ffuf` / `wfuzz`** — fuzzing de nombres de operación derivados del WSDL, parámetros y rutas `?wsdl`/servicio ([[01 - WSDL - enumeración y descubrimiento]]).
- **`python-zeep`** — cliente SOAP en Python; parsea el WSDL y expone las operaciones como métodos, ideal para automatizar PoCs y fuzzing programático.

> [!info]+ Reparto por propósito
> **Descubrir** el servicio → WSDL Wizard, `ffuf`, dorks. **Parsear el contrato** → Wsdler, `python-zeep`, SoapUI. **Explotar** → Burp Repeater/Intruder + Content Type Converter (XXE), scripts Python ([[02 - SOAP Action Spoofing]]). **Escanear** → ReadyAPI. Ningún escáner genérico sustituye el trabajo manual sobre el WSDL.
