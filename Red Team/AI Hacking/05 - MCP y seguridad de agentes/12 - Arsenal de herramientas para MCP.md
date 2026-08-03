---
tags:
  - IA/Red-Team
  - IA
  - Pentesting
  - Tipo/Arsenal
Descripción: "El set para auditar MCP: un cliente propio para explotación directa, escáneres de servidores, gateways de runtime y las herramientas web de siempre para las inyecciones"
Fecha de actualización: 2026-07-29
Nota previa: "[[11 - Detección y evasión en MCP]]"
Nota siguiente: 
Area: "[[MCP.base|MCP]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 3 del vault. El arsenal **general** de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]]; el de la [[10 - Arsenal para ataques a aplicación y sistema|capa de aplicación y sistema]] en su carpeta. Aquí, lo específico de auditar **MCP**. La herramienta central —`mcp-scan`— tiene ficha propia en Tools por su profundidad.

# El cliente propio: la herramienta principal

<mark style="background: #ADCCFFA6;">La herramienta más importante para atacar MCP es un cliente `fastmcp` propio.</mark> La [[04 - Inyecciones en servidores MCP|explotación directa]] consiste en mandar JSON-RPC a mano, y para eso hace falta un cliente controlable, no una app. El esqueleto de [[02 - FastMCP - servidor y cliente en la práctica|la nota de fastmcp]] es el punto de partida: enumera con `list_*`, ataca con `call_tool` y `read_resource`, e inspecciona los errores.

```shell-session
$ pip3 install fastmcp
```

Para clientes en otros lenguajes o para hablar el protocolo crudo, están los **SDKs oficiales** (Python, TypeScript, Go, C#, Rust en beta) y el **MCP Inspector** oficial, una UI web para explorar un servidor manualmente.

# Escaneo de seguridad de servidores MCP

| Herramienta | Autor | Para qué |
| - | - | - |
| **[[00 - Qué es mcp-scan y qué detecta\|`mcp-scan`]]** | Invariant Labs (Snyk) | **La referencia.** Análisis estático de servidores (tool poisoning, rug pull, shadowing, prompt injection en descripciones) + proxy de runtime con guardrails + tool pinning. Ficha completa en `Tools/MCP-Scan/` |
| **`MCPSafetyScanner`** | AI Assurance Lab | Simula un atacante contra los manifiestos de herramientas: agente `Hacker` vs `Auditor`. Genera evaluación y remediación |
| **`mcp-injection-experiments`** | Invariant Labs | Repositorio con PoCs reproducibles de tool poisoning y rug pull. Para estudiar los ataques, no para escanear |
| **`MCPTox` / `MCPXKIT`** | Investigación académica | Benchmarks de tool poisoning sobre servidores reales; útiles para calibrar cobertura |

<mark style="background: #FFB86CA6;">`mcp-scan` es a MCP lo que `garak` es a un LLM: la primera pasada de cobertura amplia.</mark> Su modo proxy además intercepta el tráfico MCP en runtime y aplica guardrails, que es la única forma de ver la descripción **cruda** que recibe el modelo en vez de la renderizada.

# Gateways y control en runtime

Para el lado defensivo y para entender qué se despliega delante de un MCP en producción (y por tanto qué hay que evadir):

| Herramienta | Para qué |
| - | - |
| **`mcp-scan proxy`** | Guardrails de runtime, logging y tool pinning sobre el tráfico MCP |
| **`MCP-Guardian`** | Proxy de seguridad: autenticación, control de acceso, logging, rate limiting, WAF sobre MCP |
| **Gateways** (`TrueFoundry`, `IBM ContextForge`, `Lasso`, `MintMCP`) | Capa empresarial entre clientes y servidores MCP: política centralizada, auditoría, aislamiento |

# Análisis de tráfico

- **`Wireshark`** — como el transporte `Streamable HTTP` va sobre HTTP, los mensajes JSON-RPC son legibles. Sirve para ver lo que el servidor manda de verdad frente a lo que muestra la UI. Ver `Tools/Wireshark/`.
- **`Burp Suite`** — para el transporte HTTP, interceptar y manipular las peticiones MCP como cualquier tráfico web. Repeater para iterar `payloads` en `call_tool`. Ver `Tools/Burp Suite/`.
- **`mitmproxy`** — alternativa scriptable para automatizar la manipulación del tráfico MCP.

# Las de siempre, para las inyecciones

Una vez confirmada una [[04 - Inyecciones en servidores MCP|inyección]] en un servidor MCP, se explota con el arsenal web del vault:

- **[[00 - Introducción a SQLMap|SQLMap]]** para la SQLi (con el matiz del URL-encoding en la URI de MCP).
- **[[01 - Introducción a SSRF|SSRF]]** — el catálogo de evasión y explotación, con el servidor MCP como pivote interno.
- **`ffuf` / `gobuster`** para enumerar el servicio HTTP que hospeda el MCP.
- **`nmap` + `nuclei`** para fingerprinting y CVEs conocidas del SDK.

# Inteligencia de vulnerabilidades

- **Vulnerable MCP Project** — base de datos comunitaria de vulnerabilidades de MCP (>50 catalogadas). El primer sitio a consultar tras identificar SDK y versión.
- **`huntr` / NVD** — para las [[09 - CVEs y ataques reales de MCP|CVEs]] concretas de la implementación encontrada.

# Flujo sugerido para auditar un despliegue MCP

1. **Localizar y fingerprint** el servidor: puerto, endpoint `/mcp/`, SDK, versión de protocolo ([[03 - Reconocimiento de servidores MCP|recon]]).
2. **Cruzar la versión** con Vulnerable MCP Project y `huntr`.
3. **Enumerar capacidades** con el cliente `fastmcp`: `prompts`, `resources`, `tools` con parámetros y descripciones.
4. **Escanear con `mcp-scan`** para tool poisoning, rug pull y shadowing en las definiciones.
5. **Atacar directamente** las capacidades: inyección, provocación de errores, IDOR, SSRF — a mano con el cliente.
6. **Auditar la autorización** OAuth con los [[08 - Seguridad de la autorización OAuth en MCP#Qué comprobar en un pentest de MCP con OAuth|cinco checks]] (audiencia, consentimiento, SSRF de descubrimiento, `Origin`, handles).
7. **Si eres cliente**, evaluar los servidores de terceros conectados como cadena de suministro.
8. **Entregar** por severidad, y **señalar la ausencia de visibilidad** ([[11 - Detección y evasión en MCP|detección]]) como hallazgo propio.

> [!warning]+ Conectar el cliente a un servidor no confiable es peligroso
> Auditar MCP implica a veces conectar un cliente a un servidor sospechoso. Recuerda [[09 - CVEs y ataques reales de MCP|mcp-remote (CVE-2025-6514)]]: un servidor malicioso puede ejecutar comandos en la máquina del **cliente**. Auditar servidores no confiables se hace desde una máquina desechable y aislada, nunca desde el equipo de trabajo.
