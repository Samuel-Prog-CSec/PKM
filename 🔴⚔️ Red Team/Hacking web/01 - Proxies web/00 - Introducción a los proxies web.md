---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Proxies
  - Introduccion
Fecha de actualización: 2026-06-23
Nota previa:
Nota siguiente: "[[01 - Instalación y configuración del proxy]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

<mark style="background: #ADCCFFA6;">Un `web proxy` es una herramienta que se sitúa entre el navegador (o app móvil) y el servidor back-end para capturar, ver y manipular todo el tráfico web que pasa entre ambos</mark> — un `man-in-the-middle` controlado por ti. Es **la** herramienta del pentester web: casi todo lo que hace este PKM —[[00 - Introducción a XSS|XSS]], [[01 - Detección de SQL Injection|SQLi]], [[01 - Introducción a JWT|JWT]]— se ejecuta a través de un proxy.

A diferencia de un sniffer de red como [[Wireshark]] (que analiza **todo** el tráfico de la interfaz), el web proxy trabaja sobre los puertos web (`HTTP/80`, `HTTPS/443`) y entiende la semántica HTTP: te deja **pausar** una petición, editarla y observar cómo reacciona el back-end. Esa capacidad de interceptar-modificar-reenviar es la base de todo el testing manual.

# Para qué se usa

Capturar y reenviar peticiones es lo primario, pero un proxy moderno hace mucho más:

- **Interceptar y modificar** peticiones y respuestas al vuelo.
- **Repetir** una petición con cambios ([[05 - Repeater - repetir y modificar peticiones|Repeater]]).
- **Fuzzing** de parámetros ([[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|Intruder/Fuzzer]]).
- **Crawling y mapeo** de la aplicación.
- **Escaneo de vulnerabilidades** ([[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner|scanner]]).
- Codificar/decodificar datos, y extenderse con [[10 - Extensiones y BApp Store|plugins]].

# El panorama de herramientas (2026)

HTB enseña Burp y ZAP. El profesional actual conviene que conozca las cuatro:

| Herramienta | Modelo | Fuerte en |
| - | - | - |
| <mark style="background: #FFB86CA6;">**Burp Suite**</mark> (PortSwigger) | Community gratis · Pro de pago | El **estándar de la industria**; ecosistema de extensiones, scanner, Intruder |
| **OWASP ZAP** | Libre y open-source | Automatización/CI-CD, sin throttling, headless |
| **Caido** | Freemium (Rust) | UX moderna, proyectos grandes; en auge en bug bounty |
| **mitmproxy** | Libre, CLI/TUI | Scripting en Python, tráfico móvil y no-navegador |

<mark style="background: #8000E1A6;">`Burp Suite` es la herramienta principal y el resto del módulo gira en torno a ella</mark>, con `ZAP` como alternativa libre en paralelo (nacido en OWASP, su equipo lo trasladó en 2024 al *Software Security Project*; lo verás también como "ZAP by Checkmarx"). Pero `Caido` y `mitmproxy` ganan terreno y los cubre [[13 - Flujo profesional y alternativas modernas|la nota de flujo profesional]].

# Burp: Community vs. Professional

La distinción que define tu día a día:

| Feature | Community (gratis) | Professional (~£449/año) |
| - | - | - |
| Proxy, Repeater, Decoder | ✅ | ✅ |
| Intruder | ✅ pero **con throttling** | ✅ a velocidad completa |
| Active Scanner | ❌ | ✅ |
| BApp Store (extensiones) | Limitado | ✅ completo |
| Guardar proyecto en disco | ❌ (solo temporal) | ✅ |

<mark style="background: #FFB8EBA6;">La Community basta para aprender y para mucho trabajo manual</mark>, pero el throttling del Intruder y la ausencia de scanner activo empujan a Pro en engagements reales. ZAP cubre ese hueco gratis (sin throttling, scanner incluido), a cambio de una UX menos pulida.

> [!info]+ Truco: trial de Burp Pro
> Con un email educativo o corporativo puedes pedir un [trial gratuito de Burp Pro](https://portswigger.net/burp/pro/trial) para practicar las features de pago (scanner activo, Intruder sin límite) que se ven en este módulo.

> [!info]+ Fuentes
> - [Burp Suite (PortSwigger)](https://portswigger.net/burp) · [OWASP ZAP](https://www.zaproxy.org/) · [Caido](https://caido.io/) · [mitmproxy](https://mitmproxy.org/)
> - [PortSwigger Web Security Academy](https://portswigger.net/web-security) (labs gratuitos para practicar)
