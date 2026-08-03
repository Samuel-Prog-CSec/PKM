---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "Atacar MCP directamente evita la telemetría del LLM pero deja rastro en la capa de red y de invocación de herramientas; conocer qué ve un defensor define qué esconde un atacante"
Fecha de actualización: 2026-07-29
Nota previa: "[[10 - Mitigación de la seguridad MCP]]"
Nota siguiente: "[[12 - Arsenal de herramientas para MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">Atacar un servidor MCP directamente tiene una ventaja de sigilo enorme: se salta toda la telemetría del LLM.</mark> Ningún log de `prompts`, ningún guardrail de entrada, ninguna detección de `jailbreak` — porque no hay modelo de por medio. A cambio, deja rastro en dos capas que casi nadie de IA vigila: la red y la invocación de herramientas. Conocer qué ve el defensor es lo que define qué esconde el atacante. Complementa la [[09 - Detección y evasión en aplicación y sistema|detección de la capa de aplicación]] y la [[12 - Detección y evasión en sistemas de IA|del modelo]].

# Qué telemetría deja cada camino

| Vector | Señal | Dónde se ve |
| - | - | - |
| Explotación directa del servidor | Peticiones JSON-RPC sin `User-Agent` de cliente MCP legítimo, `tools/call` fuera de sesión de agente | Logs del servidor MCP, WAF |
| [[04 - Inyecciones en servidores MCP\|Inyección]] | Payloads en argumentos, errores de BBDD/shell, `%20`/`UNION` en URIs | Logs del servidor, del servicio backend |
| [[05 - Divulgación de información y broken authorization\|Provocar errores]] | Ráfaga de peticiones con entradas inválidas | Logs de error del servidor |
| [[06 - Tool poisoning y prompt injection vía descripción\|Tool poisoning]] | Descripción con instrucciones/caracteres invisibles; llamada a herramienta no pedida | Escaneo de definiciones, log de invocaciones |
| Exfiltración vía herramienta | Conexión saliente a destino no habitual desde el host/servidor | NetFlow, EDR, DLP |
| [[07 - Rug pull y tool shadowing\|Rug pull]] | Cambio del hash de una definición entre aprobación y uso | Tool pinning, diff de definiciones |

# Detecciones que un defensor competente monta

- **Distinguir tráfico de cliente MCP legítimo del directo.** Un agente real manda peticiones con un `User-Agent` y un patrón concretos. Peticiones `tools/call` que no vienen de una sesión de agente conocida son la señal más limpia de explotación directa — y casi nadie la mira.
- **Log de invocación de herramientas con contexto.** Registrar qué herramienta se llamó, con qué argumentos y **qué la desencadenó** (qué `prompt` o qué dato). Sin esto, un `tool poisoning` es invisible; con esto, la llamada a `log` que lee `~/.ssh/id_rsa` salta a la vista.
- **Tool pinning.** Hash de cada definición aprobada; alerta si cambia. Detecta el `rug pull` en el momento de la mutación.
- **Escaneo de descripciones crudas** en la ingesta, buscando instrucciones y caracteres Unicode invisibles ([[07 - ASCII smuggling y payloads invisibles|ASCII smuggling]]). Es lo que un usuario no puede ver a ojo.
- **DLP y egress filtering** en el host del agente y en el servidor MCP, para cortar la exfiltración por herramienta hacia destinos no habituales.
- **Validación y log de `Origin`** para el vector DNS rebinding contra servidores locales.

# Cómo se evade

## El sigilo intrínseco del ataque directo

<mark style="background: #FFB86CA6;">El mayor evasor es el propio vector: atacar el servidor a mano evita todo el aparato de detección centrado en el LLM.</mark> No hay `prompt` que un guardrail pueda inspeccionar, no hay conversación que analizar. Para el equipo de seguridad de IA —que monitoriza el modelo— el ataque es invisible porque ocurre en una capa que consideran "infraestructura".

Para reforzarlo:

- **Imitar el cliente legítimo.** Copiar el `User-Agent`, las cabeceras y el ritmo de peticiones de un cliente MCP real, para no destacar entre el tráfico de agentes.
- **Trabajar dentro de sesiones existentes** cuando sea posible, en lugar de abrir conexiones nuevas que un patrón de detección marque como anómalas.
- **Provocar errores con moderación.** La enumeración por errores es ruidosa (ráfaga de `4xx`/`5xx`); espaciarla y mezclarla con peticiones válidas la diluye.

## Evasión del tool poisoning

El `tool poisoning` se detecta inspeccionando descripciones. Se evade escondiendo el `payload` de esa inspección:

- **Caracteres invisibles** ([[07 - ASCII smuggling y payloads invisibles|tag-block Unicode]]) que el modelo procesa pero el escáner —si solo busca texto legible— y el humano no ven. El estudio de [[06 - Tool poisoning y prompt injection vía descripción|concealment]] demuestra que esto atraviesa la vista de aprobación de varias implementaciones.
- **Rug pull temporal** — mantener la descripción limpia durante N llamadas para pasar cualquier inspección inicial, y mutar después.
- **Shadowing indirecto** — no suplantar una herramienta (detectable por nombre duplicado) sino modificar su comportamiento desde una herramienta ajena, más difícil de correlacionar.

## Exfiltración que parece tráfico normal

El caso [[06 - Tool poisoning y prompt injection vía descripción#El caso real: WhatsApp MCP|WhatsApp MCP]] es el patrón: exfiltrar **usando una herramienta legítima del propio agente** (enviar un WhatsApp, un correo, un commit) en lugar de abrir una conexión al servidor del atacante. El DLP ve una acción normal del agente, no una exfiltración. Ocultar los datos robados tras espacios o en campos que la UI no muestra completa remata la evasión.

> [!warning]+ La asimetría que define MCP
> <mark style="background: #FF5582A6;">El defensor de un despliegue de IA vigila el modelo; el ataque a MCP ocurre por debajo, en la capa de protocolo y de herramientas.</mark> Los logs de invocación con contexto, el tool pinning y el egress filtering en los hosts de agente son justo lo que falta en la mayoría de despliegues, porque el equipo de IA no los considera de su incumbencia y el equipo de seguridad no sabe que MCP existe. En un engagement, esa ausencia de visibilidad se reporta como deficiencia de detección: el ataque no solo funciona, es que **nadie lo vería**, que es lo que de verdad preocupa al cliente.

# Fuentes

> [!info]+ Referencias
> - [*MCP Security Best Practices*](https://modelcontextprotocol.io/specification/latest/basic/security_best_practices) — controles y `MUST`/`SHOULD` de la spec.
> - Invariant Labs / Snyk — investigación de detección de tool poisoning y runtime guardrails ([[00 - Qué es mcp-scan y qué detecta|mcp-scan]]).
> - `OWASP Top 10 for Agentic Applications 2026` — `ASI07` (Insecure Inter-Agent Communication), `ASI02` (Tool Misuse).
> - Ver también [[09 - CVEs y ataques reales de MCP]] para los patrones de incidente reales.
