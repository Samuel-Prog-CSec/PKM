---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Fecha de actualización: 2026-06-23
Nota previa: "[[12 - Proxying de apps móviles]]"
Nota siguiente:
Area: "[[Proxies web.base|Proxies web]]"
---
---

El módulo enseña las features; esta nota es cómo se **usan de verdad** en un engagement, y qué hay más allá de Burp/ZAP en 2026. Es la diferencia entre conocer los botones y trabajar con fluidez.

# El flujo de trabajo real

<mark style="background: #ADCCFFA6;">El pentest web manual sigue casi siempre el mismo bucle</mark>:

1. **Define el scope** primero (`Target > Scope`) — restringe Burp a lo autorizado y evita tocar `/logout` o terceros.
2. **Navega con interceptación OFF**. Recorre toda la app como un usuario normal; todo cae en `HTTP history`.
3. **Revisa el historial**: ordena por método/estado, busca parámetros interesantes, endpoints de API, tokens.
4. **Manda a [[05 - Repeater - repetir y modificar peticiones|Repeater]]** lo que quieras atacar e **itera payloads** ahí.
5. **Escala a [[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|Intruder]]** cuando necesites automatizar (wordlist de payloads, brute force).
6. **Documenta** sobre la marcha (comentarios de color en el historial, `Organizer`).

> [!important]+ Interceptar es la excepción, no la norma
> El error del principiante: dejar `Intercept` siempre activo y pelearse con cada petición del navegador. <mark style="background: #FF5582A6;">El profesional navega con interceptación desactivada y vive en el historial + Repeater</mark>, activando la interceptación solo para modificar una petición concreta antes de que salga.

# Burp moderno: lo que añadieron (2024-2026)

| Feature | Qué aporta |
| - | - |
| <mark style="background: #FFB86CA6;">**DOM Invader**</mark> | Integrado en el navegador de Burp: detecta [[04 - Descubrimiento de XSS\|DOM XSS]], [[09 - Prototype Pollution hacia XSS\|prototype pollution client-side]] y sinks del lado cliente automáticamente. La [[01 - Prototype Pollution server-side\|PP server-side]] no la ve DOM Invader: necesita la [[03 - Detección, herramientas y prevención\|SSPP Scanner]] |
| **Bambdas** | Scripts Java cortos para filtrar/resaltar/transformar tráfico sin extensión completa |
| **Burp AI** (Pro) | Explica vulnerabilidades, sugiere payloads y automatiza tareas repetitivas |
| **Organizer** | Guarda peticiones interesantes para retomarlas, con notas |
| **Collaborator** | Servidor OOB para detectar [[04 - Blind SSRF\|SSRF/blind]] e interacciones fuera de banda |

`DOM Invader` en particular ha cambiado la caza de XSS del lado cliente: <mark style="background: #8000E1A6;">automatiza lo que antes era análisis manual de JavaScript</mark>.

# Alternativas modernas a conocer

Burp es el estándar, pero el ecosistema 2026 tiene piezas que ganan terreno:

| Herramienta | Cuándo brilla |
| - | - |
| <mark style="background: #FFB86CA6;">**Caido**</mark> | Proxy en Rust, ligero y por proyectos. UX moderna, `Workflows` visuales, lenguaje de consulta `HTTPQL`. En auge en bug bounty para scopes grandes |
| **mitmproxy** | CLI/TUI scriptable en Python. Insustituible para **tráfico móvil**, automatización y protocolos no-navegador |
| **OWASP ZAP** | Cuando quieres scanner y fuzzer **gratis** sin throttling, o automatización en CI/CD |

Tu PKM ya cita `Caido` junto a Burp en los arsenales de [[10 - Arsenal de herramientas para Command Injection|Command Injection]] y [[10 - Arsenal de herramientas para File Upload|File Upload]] — es la apuesta moderna como proxy principal de muchos cazadores. mitmproxy es la elección cuando necesitas **programar** el MITM (reescrituras complejas, fuzzing dirigido, interceptar una app móvil).

# Otras herramientas de Burp

Más allá de Proxy/Repeater/Intruder/Scanner, conviene conocer cuatro utilidades:

- **Sequencer**: mide la aleatoriedad estadística de cientos de tokens — la prueba de [[10 - Ataques a tokens de sesión|entropía de tokens de sesión]] que fundamenta "tokens predecibles" en un informe.
- **Comparer**: diff visual de dos peticiones/respuestas; aísla qué cambió entre un caso válido y uno inválido (clave en [[01 - Enumeración de usuarios|enumeración por diferencias sutiles]]).
- **Organizer**: guarda peticiones interesantes con notas para retomarlas sin perderlas en el historial.
- <mark style="background: #FFB86CA6;">**WebSocket testing**</mark>: Burp no solo intercepta HTTP — la pestaña `WebSockets history` captura los mensajes WS, y se pueden **editar y reenviar** como en Repeater. Imprescindible en apps de chat, notificaciones en tiempo real o trading, donde la lógica viaja por WebSocket y no por peticiones HTTP clásicas.

# Atajos que multiplican (Burp)

| Atajo | Acción |
| - | - |
| `CTRL+R` / `CTRL+SHIFT+R` | Enviar a Repeater / ir a Repeater |
| `CTRL+I` / `CTRL+SHIFT+I` | Enviar a Intruder / ir a Intruder |
| `CTRL+U` / `CTRL+SHIFT+U` | URL-encode / decode de la selección |
| `Ctrl+.` / `Ctrl+,` | Siguiente / anterior pestaña de Repeater |
| `CTRL+F` | Buscar en la petición/respuesta |

<mark style="background: #FFB8EBA6;">Memorizar `CTRL+R`, `CTRL+I` y `CTRL+U` solos ya cambian tu velocidad</mark>: del historial a Repeater, a Intruder, y encodear payloads sin tocar el ratón.

> [!info]+ Cierre del módulo
> Burp/ZAP son tan básicos en el toolkit web como [[00 - Reconocimiento web|Nmap]], `hashcat`, `sqlmap` o [[15 - Introducción al web fuzzing|ffuf]]. Todo lo demás del PKM —[[01 - Detección de SQL Injection|SQLi]], [[00 - Introducción a XSS|XSS]], [[00 - Introducción a la autenticación|autenticación]], [[01 - Introducción a JWT|JWT]]— se ejecuta a través del proxy. Dominar Repeater + Intruder + scope es el cimiento sobre el que se apoya el resto.

> [!info]+ Fuentes
> - [PortSwigger — DOM Invader](https://portswigger.net/burp/documentation/desktop/tools/dom-invader) · [Bambdas](https://portswigger.net/burp/documentation/desktop/bambdas) · [Burp AI](https://portswigger.net/burp/ai)
> - [Caido](https://caido.io/) · [mitmproxy](https://mitmproxy.org/) · [PortSwigger Academy](https://portswigger.net/web-security)
