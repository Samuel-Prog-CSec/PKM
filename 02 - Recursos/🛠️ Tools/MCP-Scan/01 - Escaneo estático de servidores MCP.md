---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
Descripción: "El modo scan de mcp-scan analiza las definiciones de herramientas de los servidores configurados y verifica cada una contra su motor de detección, sin ejecutar los ataques"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Qué es mcp-scan y qué detecta]]"
Nota siguiente: "[[02 - Proxy de runtime, guardrails y tool pinning]]"
Area: "[[MCP-Scan.base|MCP-Scan]]"
---
---

<mark style="background: #ADCCFFA6;">El escaneo estático analiza las definiciones de herramientas de los servidores MCP configurados y las verifica contra el motor de detección, sin ejecutar ningún ataque.</mark> Es la auditoría puntual: descubre las configuraciones, se conecta a cada servidor, extrae las definiciones crudas de `prompts`, `resources` y `tools`, y las pasa por los detectores de [[06 - Tool poisoning y prompt injection vía descripción|tool poisoning]], [[07 - Rug pull y tool shadowing|shadowing]] y flujos tóxicos.

# Los dos comandos: `scan` e `inspect`

| Comando | Qué hace |
| - | - |
| `scan` (por defecto) | Extrae las definiciones **y las verifica** contra el motor de detección (incluye análisis con LLM de las descripciones) |
| `inspect` | Solo **extrae y muestra** las definiciones, sin verificarlas. Para ver qué expone un servidor sin el veredicto |

`inspect` es el equivalente al [[03 - Reconocimiento de servidores MCP|reconocimiento manual]] con el cliente `fastmcp`, pero automatizado sobre todas las configuraciones de la máquina de una vez.

# Uso básico

Con `uvx` no hace falta instalación previa (lo ejecuta en un entorno efímero):

```shell-session
# escaneo completo: descubre y verifica todas las configs MCP de la máquina
$ uvx mcp-scan@latest

# escanear una configuración concreta
$ uvx mcp-scan@latest ~/.cursor/mcp.json
$ uvx mcp-scan@latest ~/.vscode/mcp.json

# solo inspeccionar, sin verificar (ver qué exponen los servidores)
$ uvx mcp-scan@latest inspect
```

Instalación permanente si se usa a menudo:

```shell-session
$ pip install mcp-scan
$ mcp-scan
```

# Interpretar la salida

`mcp-scan` marca cada herramienta con un veredicto. Lo que importa leer:

- **Herramientas marcadas como envenenadas** — descripción con instrucciones tipo `<IMPORTANT>`, peticiones de leer ficheros o exfiltrar, referencias a exfiltración. Es [[06 - Tool poisoning y prompt injection vía descripción|tool poisoning]] directo.
- **Caracteres invisibles detectados** — el escáner los ve aunque el humano no; señal de [[07 - ASCII smuggling y payloads invisibles|ASCII smuggling]] en los metadatos.
- **Herramientas que mencionan otras** — una descripción que habla de `send_email` desde una herramienta no relacionada es [[07 - Rug pull y tool shadowing|shadowing]].
- **Flujos tóxicos** — combinaciones de capacidades (entre uno o varios servidores) que juntas permiten la [[01 - Prompt injection y por qué no tiene parche#La lethal trifecta|lethal trifecta]]: leer datos sensibles + acceso a contenido no confiable + capacidad de exfiltrar.
- **Secretos hardcodeados** en las configuraciones o en el código de los servidores.

<mark style="background: #FFB86CA6;">Lo que `mcp-scan` compara es lo que el modelo recibe de verdad, no lo que la UI del cliente muestra.</mark> Esa es la razón de usarlo: la vista de aprobación de los clientes es infiel, y el escáner cierra ese hueco.

# Opciones útiles en un engagement

```shell-session
# salida JSON para procesar o adjuntar al informe
$ uvx mcp-scan@latest --json

# más checks por servidor (por defecto 1) para mayor cobertura
$ uvx mcp-scan@latest --checks-per-server 5

# timeout de conexión más largo para servidores lentos
$ uvx mcp-scan@latest --server-timeout 30

# guardar resultados y estado (base del tool pinning)
$ uvx mcp-scan@latest --storage-file ./engagement-mcp.json

# omitir análisis de agent skills, centrarse en servidores MCP
$ uvx mcp-scan@latest --no-skills
```

El `--storage-file` es importante: guarda el estado de las definiciones vistas, que es lo que permite después detectar **cambios** —la base del [[02 - Proxy de runtime, guardrails y tool pinning|tool pinning]] contra rug pulls—.

# El detalle de seguridad al escanear

> [!warning]+ Escanear stdio arranca los servidores
> Para inspeccionar un servidor `stdio`, `mcp-scan` lo **ejecuta** (arranca su proceso). Por defecto pide consentimiento interactivo antes de cada uno y muestra el comando exacto. Arrancar un servidor MCP desconocido **es ejecutar su código**:
> - Leer el consentimiento antes de aceptar; fijarse en el comando (¿`curl` a un dominio raro, `rm`, acceso a `~/.ssh`?).
> - Triar servidores no confiables en una **máquina desechable y aislada**.
> - `--suppress-mcpserver-io` oculta el `stderr` ruidoso de los servidores, pero no reduce el riesgo de ejecución.
> - `--dangerously-run-mcp-servers` salta el consentimiento — **solo** en CI/CD sobre servidores ya confiables.

# Encaje en el flujo de auditoría

`scan` es el paso 4 del [[12 - Arsenal de herramientas para MCP#Flujo sugerido para auditar un despliegue MCP|flujo de auditoría de MCP]]: después del reconocimiento y el fingerprint, antes de la explotación manual. Detecta lo que es específico de MCP (ataques de descripción y composición); lo que son [[04 - Inyecciones en servidores MCP|inyecciones clásicas]] en las capacidades se prueba a mano después, porque eso `mcp-scan` no lo cubre. El modo runtime, para vigilancia continua y detección de rug pulls en vivo, está en [[02 - Proxy de runtime, guardrails y tool pinning]].
