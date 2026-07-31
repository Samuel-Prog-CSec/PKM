---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Enumeracion
Descripción: "Antes de explotar un servidor MCP hay que inventariar qué expone: prompts, resources y tools, con sus parámetros y descripciones, que es donde vive toda la superficie"
Fecha de actualización: 2026-07-29
Nota previa: "[[02 - FastMCP - servidor y cliente en la práctica]]"
Nota siguiente: "[[04 - Inyecciones en servidores MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">La superficie de un servidor MCP es exactamente el conjunto de sus `prompts`, `resources` y `tools`.</mark> Enumerarlos —con sus parámetros y sus descripciones— es el primer paso, y a menudo el que ya revela el hallazgo, porque el propio protocolo está diseñado para que un cliente descubra todo lo que el servidor ofrece.

# El descubrimiento es una feature del protocolo

MCP obliga a que el servidor sea auto-descriptivo: un cliente tiene que poder listar capacidades para pasárselas al modelo. Eso, que es imprescindible para que MCP funcione, es también reconocimiento gratuito para el atacante. No hay que adivinar endpoints ni fuzzear: **se pregunta**.

En el modelo stateless de 2026-07-28 hay además un RPC dedicado, `server/discover`, que devuelve versiones de protocolo soportadas, capacidades e identidad del servidor en una sola petición. Es el primer disparo:

```python
# devuelve capacidades, versiones e identidad del servidor
info = await client.discover()      # o server/discover a mano
```

# El cliente de enumeración

Sobre el esqueleto de [[02 - FastMCP - servidor y cliente en la práctica|la nota anterior]], un cliente que vuelca todo lo que el servidor expone:

```python
import asyncio
from fastmcp import Client

client = Client("http://172.17.0.2:8000/mcp/")

async def main():
    async with client:
        resources = await client.list_resources()
        templates = await client.list_resource_templates()
        tools     = await client.list_tools()

        print("== Resources ==")
        for r in resources:
            print(r.name, "→", r.description.strip() if r.description else "")

        print("== Resource Templates ==")
        for t in templates:
            print(t.uriTemplate, "→", t.description.strip() if t.description else "")

        print("== Tools ==")
        for tool in tools:
            params = list(tool.inputSchema.get('properties').keys())
            print(f"{tool.name}({','.join(params)})  →  {tool.description.strip()}")

asyncio.run(main())
```

# Qué leer en la salida

Cada elemento del inventario es una pista de un vector concreto. La lectura ofensiva:

| Lo que ves | Lo que sugiere |
| - | - |
| Un `resource` `logs://` o `debug://` | [[05 - Divulgación de información y broken authorization\|Divulgación de información]]: logs con credenciales, comandos, rutas |
| Un parámetro que parece un ID (`doc_id`, `user_id`) | `IDOR` / [[05 - Divulgación de información y broken authorization\|broken authorization]] |
| Descripción que menciona una API o base de datos | [[04 - Inyecciones en servidores MCP\|SQL injection]] en el parámetro |
| Un `tool` `execute_*`, `run_*`, `shell` | [[04 - Inyecciones en servidores MCP\|Command injection]] |
| Un `tool` `fetch_*`, `download_*`, parámetro `url` | [[04 - Inyecciones en servidores MCP\|SSRF]] |
| Una descripción con instrucciones raras o `<IMPORTANT>` | [[06 - Tool poisoning y prompt injection vía descripción\|Tool poisoning]] — servidor potencialmente malicioso |
| Dos `tools` con el mismo nombre (varios servidores) | [[07 - Rug pull y tool shadowing\|Tool shadowing]] |

<mark style="background: #FFB86CA6;">La descripción de una capacidad se escribe pensando en el modelo, no en un atacante, así que suele ser honesta sobre lo que hace por dentro.</mark> "Consulta el precio en la API de precios" delata que detrás hay una base de datos; "ejecuta un comando seguro limitado a date, whoami y uptime" delata un `execTool` con lista blanca que se puede intentar romper.

# Provocar errores para enumerar más

El inventario dice qué hay; los errores dicen **cómo está construido**. La segunda pasada del reconocimiento consiste en llamar cada capacidad con entradas inválidas y leer los mensajes de error, que en implementaciones descuidadas filtran rutas, esquemas de base de datos y claves de API. La técnica y los ejemplos concretos están en [[05 - Divulgación de información y broken authorization]].

```python
# provocar un error en un resource para ver qué filtra
try:
    r = await client.read_resource("quantity://asd!")
    print(r[0].text)
except Exception as e:
    print(f"[-] {e}")           # el mensaje de error es el hallazgo
```

# Reconocimiento del servicio, no solo del protocolo

Un servidor MCP remoto es también un **servicio de red HTTP**, y aplica el reconocimiento de siempre:

- **Puerto y fingerprinting.** MCP sobre `Streamable HTTP` no tiene un puerto estándar, pero el endpoint suele ser `/mcp/`. Un `nmap -sV` y una petición a `/mcp/` confirman que hay un servidor MCP detrás.
- **Versión de protocolo.** La responde `server/discover` (o el viejo `initialize`). Una versión antigua (`2024-11-05`, `2025-03-26`) indica implementación sin migrar y potencialmente vulnerable a fallos ya parcheados.
- **Autenticación.** ¿Responde a peticiones sin token? Si el servidor contesta a un `tools/list` anónimo, no hay control de acceso — y todo lo demás es alcanzable directamente.
- **SDK y lenguaje.** Los mensajes de error y las cabeceras suelen delatar el SDK (Python `fastmcp`, TypeScript, Java, Rust). Importa porque las CVEs de [[09 - CVEs y ataques reales de MCP|MCP]] son por SDK.

> [!important]+ El hallazgo antes de la explotación
> <mark style="background: #FF5582A6;">Un servidor MCP que responde a `tools/list` sin autenticación desde una red no confiable ya es reportable</mark>, antes de explotar nada. Significa que cualquiera puede enumerar sus capacidades y llamarlas directamente, saltándose por completo la supuesta protección del LLM. Es el equivalente MCP de una API interna expuesta sin auth, y es sorprendentemente común porque el desarrollador asume que "solo el cliente LLM se conecta aquí".

Con el inventario en la mano y sabiendo qué sugiere cada elemento, se pasa a la explotación: [[04 - Inyecciones en servidores MCP]].
