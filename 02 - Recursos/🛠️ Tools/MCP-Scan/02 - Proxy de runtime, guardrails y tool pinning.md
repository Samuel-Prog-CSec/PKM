---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Post-Explotacion
  - Tipo/Defensa
Descripción: "El modo proxy de mcp-scan se interpone en el tráfico MCP en vivo para registrar invocaciones, aplicar guardrails y fijar hashes de definiciones que detectan rug pulls sobre la marcha"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - Escaneo estático de servidores MCP]]"
Nota siguiente: 
Area: "[[MCP-Scan.base|MCP-Scan]]"
---
---

<mark style="background: #ADCCFFA6;">El modo proxy se interpone en el tráfico MCP en vivo: registra cada invocación, aplica guardrails y fija el hash de cada definición para detectar cambios sobre la marcha.</mark> Es la respuesta al problema que el [[01 - Escaneo estático de servidores MCP|escaneo estático]] no puede resolver: un servidor puede pasar limpio el escaneo inicial y volverse malicioso después ([[07 - Rug pull y tool shadowing|rug pull]]). Solo mirando el tráfico en runtime se detecta esa mutación.

# Por qué el estático no basta

El escaneo estático es una foto: verifica las definiciones **en un momento**. Los dos ataques más difíciles de MCP burlan justamente eso:

- El **rug pull** cambia la definición *después* de la aprobación. El escaneo inicial no ve nada.
- El **tool poisoning temporal** mantiene la herramienta limpia durante N llamadas y muta luego.

<mark style="background: #FFB86CA6;">Contra un adversario que cambia con el tiempo, la defensa tiene que ser continua.</mark> El proxy convierte la foto en vídeo.

# Qué hace el proxy

Se coloca entre el cliente MCP (el host/agente) y los servidores, y sobre cada mensaje del protocolo:

| Función | Qué aporta |
| - | - |
| **Logging de invocaciones** | Registra cada `tools/call` y `resources/read` con sus argumentos y qué lo desencadenó — la telemetría que [[11 - Detección y evasión en MCP\|casi ningún despliegue tiene]] |
| **Guardrails de runtime** | Bloquea tráfico peligroso en vivo: exfiltración, payloads en descripciones, flujos tóxicos |
| **Tool pinning** | Fija un hash de cada definición aprobada; **alerta o bloquea si cambia** — la defensa directa contra el rug pull |
| **Detección de shadowing cross-origin** | Correlaciona herramientas entre servidores para detectar suplantación y modificación cruzada |

# Tool pinning: el mecanismo clave

El *pinning* es lo que hace único al proxy. Al aprobar una herramienta, `mcp-scan` calcula y guarda un hash de su definición completa (nombre, descripción, esquema de parámetros). En cada uso posterior, recalcula el hash y lo compara:

- **Coincide** → la herramienta es la que se aprobó; se permite.
- **No coincide** → la definición cambió desde la aprobación. Es la firma exacta de un [[09 - CVEs y ataques reales de MCP|MCPoison / rug pull]]; se alerta o se bloquea.

<mark style="background: #8000E1A6;">Esto materializa la lección de MCPoison:</mark> la confianza no puede ser un evento único sobre contenido mutable. El pinning re-verifica en cada uso, que es justo lo que a Cursor le faltaba en `CVE-2025-54136`.

# Uso

El proxy se instala como capa de gateway sobre las configuraciones MCP existentes. El patrón general (la sintaxis exacta evoluciona con la versión y la migración a Snyk Agent Scan):

```shell-session
# instalar el proxy en las configuraciones MCP descubiertas
$ uvx mcp-scan@latest proxy install

# ejecutar el proxy (se interpone en el tráfico y aplica guardrails + pinning)
$ uvx mcp-scan@latest proxy

# revisar el registro de invocaciones capturadas
$ uvx mcp-scan@latest proxy inspect
```

El estado (hashes fijados, decisiones de guardrail) persiste en el `--storage-file` (por defecto `~/.mcp-scan`), el mismo que usa el escaneo estático — por eso conviene un `storage-file` dedicado por engagement.

# Los dos usos: defensa y auditoría

El proxy sirve a los dos lados del engagement:

- **Como defensa** (lo que el cliente debería desplegar): guardrails y pinning en producción, y el log de invocaciones como fuente para el SIEM. Es la mitigación concreta que se recomienda en el informe frente a rug pull y tool poisoning.
- **Como auditoría** (lo que hace el pentester): interponer el proxy revela **qué invoca de verdad** un agente y sus servidores —qué herramientas se llaman, con qué argumentos, qué datos salen—. Es la forma de comprobar en vivo si un despliegue es vulnerable a los ataques de [[06 - Tool poisoning y prompt injection vía descripción|descripción]] y de documentar la ausencia de telemetría como hallazgo.

# Límites

- **No es un cliente de ataque.** Para la [[04 - Inyecciones en servidores MCP|explotación directa]] (inyecciones en las capacidades) sigue haciendo falta el cliente `fastmcp` propio. El proxy observa y filtra; no ataca.
- **Cubre lo específico de MCP.** SQLi, command injection y SSRF en las capacidades no son su dominio — eso se prueba a mano.
- **Añade latencia** al interponerse. En producción es un compromiso rendimiento/seguridad a valorar.

> [!important]+ La telemetría es media victoria
> El mayor valor del proxy en un engagement no es lo que bloquea, sino lo que **hace visible**. La mayoría de despliegues MCP no registran qué herramientas se invocan ni con qué datos. Interponer el proxy durante la prueba —o recomendar su despliegue permanente— convierte una superficie opaca en una auditable. Como se argumenta en [[11 - Detección y evasión en MCP|detección y evasión]], la ausencia de esta visibilidad es en sí misma el hallazgo que más preocupa al cliente: no que el ataque funcione, sino que nadie lo vería.
