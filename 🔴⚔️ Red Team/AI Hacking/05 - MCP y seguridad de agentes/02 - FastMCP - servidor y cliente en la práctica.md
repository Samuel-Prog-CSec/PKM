---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Enumeracion
Descripción: "Montar un servidor y un cliente MCP con fastmcp para entender por dentro cómo se exponen y se consumen las capacidades, y tener un cliente propio con el que auditar"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - El protocolo MCP - mensajes, transportes y ciclo de vida]]"
Nota siguiente: "[[03 - Reconocimiento de servidores MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">La forma más rápida de entender MCP —y de tener un cliente con el que auditar— es montar un servidor y un cliente propios con `fastmcp`.</mark> Es la librería Python de referencia y la que usan los laboratorios. El objetivo de esta nota no es aprender a programar servidores MCP, sino **tener el cliente de ataque** que se usará en las notas siguientes.

```shell-session
$ pip3 install fastmcp
```

# Un servidor mínimo

`fastmcp` expone las tres primitivas con decoradores. La configuración (nombre, parámetros, descripción) se deriva automáticamente de la función: el nombre de la capacidad es el de la función, los parámetros son sus argumentos, y **la descripción sale del `docstring`** — este último detalle es la raíz del [[06 - Tool poisoning y prompt injection vía descripción|tool poisoning]].

```python
from fastmcp import FastMCP
from glob import glob

mcp = FastMCP("MCP")

@mcp.prompt()
def spell_check(text: str) -> str:
    """Genera un mensaje pidiendo revisar la ortografía de un texto."""
    return f"Revisa el siguiente texto en busca de erratas:\n\n{text}"

@mcp.resource("resource://filecount")
def count_files() -> int:
    """Devuelve el número de ficheros almacenados."""
    return len(glob("/tmp/*.mcpfile"))

@mcp.resource("getfile://{file_name}")          # plantilla de recurso (con parámetro)
def get_file(file_name: str) -> str:
    """Devuelve el contenido de un fichero almacenado."""
    with open(f"/tmp/{file_name}.mcpfile", "r") as f:
        return f.read()

@mcp.tool()
def store_file(file_content: str, file_name: str) -> str:
    """Almacena un fichero."""
    with open(f"/tmp/{file_name}.mcpfile", "w+") as f:
        f.write(file_content)
    return file_content

mcp.run(transport="streamable-http", host="127.0.0.1", port=8000)
```

> [!warning]+ Este servidor ya es vulnerable
> Fíjate en `get_file` y `store_file`: el `file_name` va directo a una ruta sin sanear. Un `file_name` como `../../etc/passwd` es un [[04 - Inyecciones en servidores MCP|path traversal]]. Los servidores MCP de ejemplo —y muchos reales— tratan sus argumentos como confiables porque asumen que solo el LLM los rellena. **Cualquiera con acceso al puerto 8000 puede llamarlos.**

`fastmcp` maneja las excepciones automáticamente: si la función lanza una `Exception`, el servidor responde con un `error` — y si el `docstring` o el mensaje son verbosos, con [[05 - Divulgación de información y broken authorization|información sensible dentro]].

# El cliente: la base del arsenal de auditoría

El cliente `fastmcp` es asíncrono. Este es el esqueleto que se reutiliza para enumerar y atacar:

```python
import asyncio
from fastmcp import Client

client = Client("http://localhost:8000/mcp/")

async def main():
    async with client:
        # Enumeración
        prompts   = await client.list_prompts()
        resources = await client.list_resources()
        templates = await client.list_resource_templates()
        tools     = await client.list_tools()

        # Invocación
        r = await client.call_tool("store_file",
                {"file_content": "Hello World!", "file_name": "helloworld"})
        print(r.content[0].text)

        # Lectura de recurso (aquí van los payloads de traversal/injection)
        f = await client.read_resource("getfile://helloworld")
        print(f[0].text)

asyncio.run(main())
```

Las cuatro funciones de listado son el **reconocimiento** completo del servidor (nota siguiente). `call_tool` y `read_resource` son por donde entran los `payloads`.

## Autenticación y cabeceras

Si el servidor pide autenticación (un `Bearer token`, una API key) o cabeceras concretas, se configuran en el transporte. Esto importa al auditar servidores reales que sí protegen el acceso:

```python
from fastmcp.client.transports import StreamableHttpTransport

transport = StreamableHttpTransport(
    url="http://localhost:8000/mcp/",
    headers={"X-API-Key": "DummyApiKey1337"}
)
client = Client(transport)
```

> [!info]+ Nota de versión sobre la autorización
> El modelo de autorización de MCP cambió mucho en 2026-07-28: `OAuth` con validación de `iss` (RFC 9207), `Client ID Metadata Documents` en lugar de registro dinámico de cliente, y binding de credenciales al servidor emisor. Para auditar un servidor moderno, la clave de acceso ya no suele ser una API key estática sino un token OAuth con audiencia validada — ver [[08 - Seguridad de la autorización OAuth en MCP]]. `fastmcp` soporta ambos modelos según la versión.

# Analizar el tráfico MCP

Para entender qué manda cada llamada —y detectar comportamientos raros de un servidor sospechoso— se captura el tráfico local con `Wireshark` mientras corren cliente y servidor. Como el transporte es HTTP, los mensajes JSON-RPC van legibles dentro de las peticiones.

Una llamada `client.list_tools()` produce un `tools/list`:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}
```

Y la respuesta trae el esquema completo de cada herramienta —nombre, descripción y parámetros—, que es justo lo que el host inyectará en el `prompt` del modelo:

```json
{"jsonrpc": "2.0", "id": 1, "result": {"tools": [{
  "name": "store_file",
  "description": "Almacena un fichero.",
  "inputSchema": { "properties": {
      "file_content": {"type": "string"}, "file_name": {"type": "string"}
  }, "required": ["file_content", "file_name"] }
}]}}
```

<mark style="background: #FFB86CA6;">Inspeccionar la descripción real que devuelve `tools/list` —no la que muestra la UI del cliente— es la comprobación que detecta el [[07 - Rug pull y tool shadowing|tool poisoning]]:</mark> el servidor puede mostrar una cosa en la interfaz y enviar otra en el protocolo. `Wireshark` (o el proxy de [[00 - Qué es mcp-scan y qué detecta|mcp-scan]]) ve lo que el modelo ve de verdad. Ver `02 - Recursos/🛠️ Tools/Wireshark/` para el uso general de la herramienta.

Con el servidor montado y el cliente listo, el siguiente paso es enumerar un servidor ajeno: [[03 - Reconocimiento de servidores MCP]].
