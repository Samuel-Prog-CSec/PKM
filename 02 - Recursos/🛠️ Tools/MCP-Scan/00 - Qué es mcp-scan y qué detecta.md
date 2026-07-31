---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "mcp-scan es el escáner de seguridad de referencia para MCP: analiza servidores en busca de tool poisoning, rug pulls y shadowing, y hace de proxy con guardrails en runtime"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - Escaneo estático de servidores MCP]]"
Area: "[[MCP-Scan.base|MCP-Scan]]"
---
---

<mark style="background: #ADCCFFA6;">`mcp-scan` es el escáner de seguridad de referencia para MCP.</mark> Analiza las configuraciones y servidores MCP de una máquina en busca de las amenazas específicas del protocolo —[[06 - Tool poisoning y prompt injection vía descripción|tool poisoning]], [[07 - Rug pull y tool shadowing|rug pull y shadowing]]— y opera además como proxy de runtime que aplica guardrails al tráfico. Es a MCP lo que [[00 - Qué es garak y cuándo usarlo|garak]] es a un LLM: la primera pasada de cobertura amplia, la que se lanza antes de auditar a mano.

# Quién lo hace y por qué importa

Lo desarrolla **Invariant Labs**, un spin-off de ETH Zúrich **adquirido por Snyk en junio de 2025**. Es el mismo equipo que descubrió y publicó los ataques de [[06 - Tool poisoning y prompt injection vía descripción#El caso real: WhatsApp MCP|tool poisoning de WhatsApp]] y el `rug pull`, así que la herramienta la escribe quien definió las categorías de ataque. Es el escáner de MCP más adoptado (>2.000 estrellas en GitHub) y la base del producto empresarial **Snyk Agent Scan**.

> [!info]+ Nombres y evolución
> El proyecto open-source es `mcp-scan` (`invariantlabs-ai/mcp-scan`). Tras la adquisición, Snyk lo consolidó como **Snyk Agent Scan** (`uvx snyk-agent-scan@latest`), que amplía el alcance a *agent skills* además de servidores MCP. Ambos nombres apuntan al mismo linaje; aquí se usa `mcp-scan` por ser el término que verás en la mayoría de la documentación y en los labs.

# Qué detecta

Más de 15 clases de riesgo, que mapean casi uno a uno con las notas del sub-tema de [[00 - Qué es MCP y por qué cambia la superficie de ataque|MCP]]:

| Detección | Nota del vault |
| - | - |
| **Prompt injection** en descripciones de herramientas | [[06 - Tool poisoning y prompt injection vía descripción]] |
| **Tool poisoning** (instrucciones ocultas) | [[06 - Tool poisoning y prompt injection vía descripción]] |
| **Tool shadowing** (herramientas que hablan de otras) | [[07 - Rug pull y tool shadowing]] |
| **Rug pull** (cambios en definiciones ya aprobadas) | [[07 - Rug pull y tool shadowing]] |
| **Toxic flows** (composición peligrosa entre servidores) | [[00 - Qué es MCP y por qué cambia la superficie de ataque#3. La composición multiplica la superficie\|composición]] |
| **Secretos hardcodeados** y payloads de malware | [[05 - Divulgación de información y broken authorization]] |
| Caracteres invisibles / [[07 - ASCII smuggling y payloads invisibles\|ASCII smuggling]] en metadatos | [[06 - Tool poisoning y prompt injection vía descripción#Ocultación: por qué revisar la descripción no basta|ocultación]] |

<mark style="background: #FFB86CA6;">La clave diferencial: `mcp-scan` inspecciona la definición **cruda** que el servidor manda por el protocolo, no la renderizada en la UI.</mark> Ahí es donde vive el `payload` que un humano no ve — el hueco de "fidelidad de la vista de aprobación" que [[06 - Tool poisoning y prompt injection vía descripción#Ocultación: por qué revisar la descripción no basta|documentaron los papers de concealment]].

# Los dos modos

`mcp-scan` opera en dos modos que cubren momentos distintos del ciclo de vida:

- **Escaneo estático** (`scan` / `inspect`) — analiza las configuraciones y definiciones de herramientas **antes** de confiar en un servidor. Es la auditoría puntual. Detalle en [[01 - Escaneo estático de servidores MCP]].
- **Proxy de runtime** (`proxy`) — se interpone en el tráfico MCP en vivo, aplica guardrails, registra las invocaciones y hace **tool pinning** para detectar rug pulls sobre la marcha. Detalle en [[02 - Proxy de runtime, guardrails y tool pinning]].

# Descubrimiento automático de configuraciones

`mcp-scan` conoce las rutas estándar donde los clientes MCP guardan su configuración, así que escanear una máquina no requiere apuntarle a cada fichero:

- **Claude Desktop / Claude Code**
- **Cursor** (`~/.cursor/mcp.json` — el fichero de [[09 - CVEs y ataques reales de MCP|CurXecute y MCPoison]])
- **VS Code** (`~/.vscode/mcp.json`)
- **Windsurf**, **Gemini CLI**, **Amazon Q**, y otros.

```shell-session
# escaneo completo de la máquina: descubre todas las configs MCP conocidas
$ uvx mcp-scan@latest
```

<mark style="background: #8000E1A6;">Esto convierte a `mcp-scan` en la herramienta de inventario de MCP de un host:</mark> en un engagement, revela qué servidores MCP tiene configurados un puesto de trabajo —a menudo más de los que el usuario recuerda— y cuáles son sospechosos, antes de tocar nada.

# Cuándo usarlo

- **Auditoría de un despliegue MCP** — la primera pasada antes de la explotación manual de [[04 - Inyecciones en servidores MCP|inyecciones]].
- **Triaje de un servidor de terceros** antes de conectarle un cliente — ¿tiene tool poisoning, secretos, flujos tóxicos?
- **Defensa continua** — el modo proxy en producción, con pinning y guardrails.
- **Inventario forense** de un host comprometido — qué servidores MCP estaban configurados y cuáles eran maliciosos.

No sustituye la auditoría manual: `mcp-scan` cubre los ataques **de descripción y composición** (lo específico de MCP), pero las [[04 - Inyecciones en servidores MCP|inyecciones en las capacidades]] (SQLi, command injection, SSRF) se prueban con el cliente propio y el arsenal web. Es cobertura amplia primero, profundidad manual después — el mismo flujo que con cualquier escáner.

> [!warning]+ Escanear ejecuta servidores stdio
> Por defecto, `mcp-scan` **arranca los servidores stdio** para inspeccionarlos (pide consentimiento interactivo antes de cada uno). Arrancar un servidor MCP malicioso es ejecutar su código. En el triaje de servidores no confiables, hacerlo en una máquina desechable y aislada, y leer el consentimiento antes de aceptar. La bandera `--dangerously-run-mcp-servers` que lo salta es solo para CI/CD en entornos de confianza.
