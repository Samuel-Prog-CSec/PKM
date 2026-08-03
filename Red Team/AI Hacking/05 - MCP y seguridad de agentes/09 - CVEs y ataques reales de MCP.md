---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
Descripción: "MCP pasó de curiosidad a más de 40 CVEs en el primer trimestre de 2026; los casos reales muestran qué clases de fallo se explotan de verdad y contra qué productos"
Fecha de actualización: 2026-07-29
Nota previa: "[[08 - Seguridad de la autorización OAuth en MCP]]"
Nota siguiente: "[[10 - Mitigación de la seguridad MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">MCP pasó de curiosidad de 2024 a más de 40 CVEs en el primer trimestre de 2026.</mark> HTB no menciona ni una, porque su módulo es anterior a la ola. Esta nota recoge los casos reales que definen qué clases de fallo se explotan de verdad — no para memorizar CVEs, sino para reconocer los patrones en un engagement y saber que **cada categoría teórica de este sub-tema tiene ya su incidente en producción**.

# La escala del problema

> [!info]+ Fuente: [*MCP Security Statistics 2026*](https://www.practical-devsecops.com/mcp-security-statistics-2026-report/) y [*The State of MCP Security 2026*](https://pipelab.org/blog/state-of-mcp-security-2026/)
> Entre enero y abril de 2026 se divulgaron **más de 40 CVEs** contra implementaciones de MCP, en los SDKs de Python, TypeScript, Java y Rust, afectando a servidores de referencia de Anthropic y a herramientas de terceros con más de 150 millones de descargas combinadas. El *Vulnerable MCP Project* rastrea más de 50 vulnerabilidades conocidas, 13 críticas.

La lectura para un pentester: <mark style="background: #FFB86CA6;">MCP es superficie fresca y masivamente desplegada. Cualquier implementación tiene probabilidad alta de correr una versión con CVE conocida.</mark>

# Los casos que definen cada categoría

## Command injection en el cliente — mcp-remote

> [!info]+ [CVE-2025-6514](https://jfrog.com/blog/2025-6514-critical-mcp-remote-rce-vulnerability/) · CVSS **9.6** · JFrog, jul. 2025
> `mcp-remote` es un puente que permite a clientes solo-`stdio` hablar con servidores remotos. La vulnerabilidad es **OS command injection**: cuando `mcp-remote` se conecta a un servidor MCP **no confiable**, este puede disparar ejecución de comandos arbitrarios en la máquina del cliente. Más de **437.000 descargas** del paquete npm.

Es el ejemplo canónico del riesgo del **cliente** que se conecta a un servidor hostil — lo contrario de la intuición de que el peligro está en el servidor. Categoría: [[04 - Inyecciones en servidores MCP|inyección]], dirección invertida.

## Prompt injection a RCE — CurXecute

> [!info]+ [CVE-2025-54135](https://www.catonetworks.com/blog/curxecute-rce/) "CurXecute" · CVSS 8.6 · Aim Labs, ago. 2025
> RCE en el IDE **Cursor** vía inyección de `prompt` en el auto-arranque de MCP. Un único `prompt` malicioso alojado externamente (en un issue, una página, un dato que el agente recupere) **reescribe silenciosamente `~/.cursor/mcp.json`** y ejecuta comandos del atacante. Corregido en Cursor 1.3.

Une dos mundos: una [[05 - Inyección indirecta en RAG, email y web|inyección indirecta]] acaba modificando la **configuración de servidores MCP**, que a su vez ejecuta código. Es la cadena `prompt injection → tool config → RCE` en un producto real.

## Rug pull — MCPoison

> [!info]+ [CVE-2025-54136](https://www.tenable.com/blog/faq-cve-2025-54135-cve-2025-54136-vulnerabilities-in-cursor-curxecute-mcpoison) "MCPoison" · CVSS 8.8 · Check Point, jul. 2025
> También en Cursor: aprobaba una configuración de servidor MCP **una vez** y no la re-validaba. Un servidor —o un `mcp.json` de repositorio modificado tras la aprobación— podía cambiar el comando ejecutado sin nueva confirmación.

Es el [[07 - Rug pull y tool shadowing|rug pull]] catalogado. Confirma la lección: **la confianza sobre contenido mutable tiene que re-validarse en cada uso**.

## Cadena de suministro — postmark-mcp

> [!info]+ Backdoor en `postmark-mcp` (npm) · [Koi Security](https://www.koi.ai/blog/postmark-mcp-npm-malicious-backdoor-email-theft), sep. 2025
> Un servidor MCP legítimo de envío de correo, con adopción real (~1.643 descargas). En la versión **1.0.16** (17-sep-2025), se añadió una línea que ponía en **BCC** todos los correos salientes a `phan@giftshop.club`, exfiltrando facturas, restablecimientos de contraseña y correspondencia interna. Las versiones previas funcionaban bien y generaron la confianza; la maliciosa la traicionó. Considerado el **primer servidor MCP malicioso** documentado en la naturaleza.

Es `ASI04: Agentic Supply Chain` en estado puro, y la prueba de que [[07 - Rug pull y tool shadowing#Mitigación|escrutar el origen una vez no basta]]: hay que vigilar **cada actualización**. Relacionado, el gusano **Shai-Hulud** (sept. 2025) comprometió paquetes npm populares (`chalk`, `debug`) que forman parte de las dependencias de muchos servidores MCP.

## Servidores de referencia de Anthropic — mcp-server-git

> [!info]+ CVE-2025-68143 / 68144 / 68145 · `mcp-server-git` · ene. 2026
> Tres CVEs en el servidor Git de referencia de **Anthropic**: `path traversal` y `argument injection`. Que los servidores de referencia del propio creador del protocolo tengan estos fallos dimensiona el estado de madurez del ecosistema.

Categoría: [[04 - Inyecciones en servidores MCP|inyección]] y traversal clásicos, en el código que se toma como ejemplo canónico.

# El mapa: categoría teórica → incidente real

<mark style="background: #8000E1A6;">Cada vector de este sub-tema tiene ya su CVE.</mark> Esta tabla es la que se lleva mentalmente al engagement:

| Categoría (este sub-tema) | Incidente real |
| - | - |
| [[04 - Inyecciones en servidores MCP\|Inyección en el servidor]] | mcp-server-git (CVE-2025-68143+) |
| [[04 - Inyecciones en servidores MCP\|Inyección hacia el cliente]] | mcp-remote (CVE-2025-6514, CVSS 9.6) |
| [[06 - Tool poisoning y prompt injection vía descripción\|Tool poisoning / exfiltración]] | WhatsApp MCP (Invariant Labs) |
| [[07 - Rug pull y tool shadowing\|Rug pull]] | MCPoison (CVE-2025-54136) |
| Prompt injection → config → RCE | CurXecute (CVE-2025-54135) |
| Cadena de suministro | postmark-mcp, Shai-Hulud |
| [[08 - Seguridad de la autorización OAuth en MCP\|Autorización OAuth]] | Familia de la spec (confused deputy, passthrough) |

# Cómo se usa esto en un engagement

1. **Fingerprint del SDK y versión** del servidor/cliente MCP ([[03 - Reconocimiento de servidores MCP|reconocimiento]]). Las CVEs son por SDK y por versión.
2. **Cruce con el Vulnerable MCP Project** y con `huntr`/NVD para las CVEs conocidas de esa versión.
3. **Priorizar por categoría**: si es un cliente que se conecta a servidores externos, mira mcp-remote y CurXecute; si es un servidor que integra APIs, mira inyección y OAuth; si compone varios servidores, rug pull y shadowing.
4. **Reportar la versión desactualizada como hallazgo** aunque no llegues a explotarla — en un ecosistema con 40 CVEs por trimestre, correr una versión con retraso es riesgo demostrable.

> [!warning]+ El ecosistema se mueve más rápido que los parches
> Con 30-40 CVEs por trimestre y un protocolo que acaba de reescribirse (stateless, 2026-07-28), el desfase entre lo desplegado y lo seguro es enorme. En un engagement de MCP, la hipótesis por defecto es **"esto corre una versión vulnerable"**, y casi siempre se confirma. La mitigación de fondo está en [[10 - Mitigación de la seguridad MCP]].
