---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Enumeracion
Descripción: "MCP viaja sobre JSON-RPC por stdio o HTTP; entender sus mensajes y su ciclo de vida es lo que permite hablar con un servidor a mano y auditarlo sin cliente"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Qué es MCP y por qué cambia la superficie de ataque]]"
Nota siguiente: "[[02 - FastMCP - servidor y cliente en la práctica]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">MCP transporta mensajes `JSON-RPC 2.0` por dos vías: `stdio` en local y `Streamable HTTP` en remoto.</mark> Entender la estructura de esos mensajes es lo que permite hablar con un servidor MCP **a mano**, sin cliente oficial, que es como se audita. Esta nota fija el protocolo y marca con claridad qué cambió en la versión final del 28 de julio de 2026 respecto a lo que enseña HTB.

# Los tres tipos de mensaje

`JSON-RPC` define tres formas, y esto **no ha cambiado** entre versiones:

- **`Request`** — inicia una operación. Lleva `id` (único), `method` (la operación) y opcionalmente `params`.
- **`Response`** — resultado de un `request`. Lleva el mismo `id` y, o bien `result`, o bien `error`.
- **`Notification`** — mensaje de una sola dirección, sin respuesta. Lleva `method` y opcionalmente `params`, pero **no** `id`.

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": { "name": "store_file", "arguments": { "file_content": "x", "file_name": "y" } }
}
```

Los `method` de la fase de operación son la chuleta del auditor:

| Método | Qué hace |
| - | - |
| `prompts/list` · `prompts/get` | Listar / obtener plantillas de `prompt` |
| `resources/list` · `resources/read` | Listar / leer recursos (solo lectura) |
| `resources/templates/list` | Listar plantillas de recurso (con parámetros) |
| `tools/list` · `tools/call` | Listar / **invocar** herramientas (con efecto) |

<mark style="background: #FFB86CA6;">`tools/call` es la llamada que ejecuta acciones; `resources/read` la que lee datos. Son los dos verbos que se atacan.</mark>

# Los transportes

## `stdio` — local

Cliente y servidor son procesos en la misma máquina y se comunican por la entrada y salida estándar del sistema operativo. Es lo que usan los servidores MCP locales (los que un IDE lanza como subproceso). Su seguridad depende de que **solo** el cliente legítimo pueda hablar con ese proceso — ver el [[08 - Seguridad de la autorización OAuth en MCP|compromiso de servidores locales]] (sección *El vector localhost*).

## `Streamable HTTP` — remoto

El servidor levanta un servidor HTTP. El cliente manda `GET`/`POST`; el servidor puede empujar datos al cliente con `Server-Sent Events (SSE)` sin esperar a que el cliente pregunte. Al ser HTTP, **cualquiera con acceso de red al puerto puede hablar con el servidor** — es la base de la [[04 - Inyecciones en servidores MCP|explotación directa]].

> [!warning]+ El transporte `HTTP+SSE` antiguo está deprecado
> Las primeras versiones usaban un transporte `HTTP+SSE` con dos endpoints separados. Se sustituyó por `Streamable HTTP` (un endpoint) y el antiguo quedó **formalmente deprecado** en la versión 2026-07-28. Un servidor que aún lo use es señal de implementación desactualizada.

# El ciclo de vida: aquí está el gran cambio

Esta es la parte donde HTB quedó obsoleto. Hay que aprender los dos modelos: el viejo porque sigue vivo en implementaciones no migradas, y el nuevo porque es el estándar.

## El modelo con handshake (2025-11-25 y anterior — lo que enseña HTB)

Tres fases, con un handshake explícito de arranque:

1. **Inicialización** — tres mensajes. El cliente manda `initialize` con su versión de protocolo (`2024-11-05`) y capacidades; el servidor responde con las suyas; el cliente cierra con una notificación `notifications/initialized`. A partir de aquí ambos comparten un `Mcp-Session-Id`.
2. **Operación** — el intercambio central de `requests`/`responses` con los `method` de la tabla de arriba.
3. **Cierre** — no hay mensaje de cierre; se cierra el transporte (el stream `stdio` o la conexión HTTP).

## El modelo stateless (2026-07-28 — el vigente)

> [!info]+ Fuente: [*The 2026-07-28 Specification*](https://blog.modelcontextprotocol.io/posts/2026-07-28/) (final, 28-jul-2026)
> El mayor cambio del protocolo desde su creación. Se **elimina el handshake `initialize`/`initialized` y el `Mcp-Session-Id`**. Cada petición es autodescriptiva: lleva su versión de protocolo, identidad y capacidades en el campo `_meta` (clave `io.modelcontextprotocol/protocolVersion`). Cualquier petición puede aterrizar en cualquier instancia del servidor detrás de un balanceador `round-robin` sin sesión pegajosa ni almacén compartido.

Los cambios que importan para un pentester:

- **Sin sesión de protocolo.** El servidor no mantiene estado entre peticiones. El que necesite estado (un carrito, un flujo) emite un **`state handle`** explícito que el cliente devuelve como argumento. Esto crea una clase de vulnerabilidad nueva: el [[05 - Divulgación de información y broken authorization#El caso stateless: state handle hijacking|state handle hijacking]], donde un atacante adivina o roba el handle de otro usuario.
- **`server/discover`** — RPC **opcional** que devuelve versiones, capacidades e identidad del servidor en una sola petición. Reemplaza al descubrimiento por handshake. Es el primer disparo del [[03 - Reconocimiento de servidores MCP|reconocimiento]].
- **Cabeceras `Mcp-Method` y `Mcp-Name`** en las peticiones `Streamable HTTP`, para que un gateway enrute sin parsear el cuerpo JSON. Para el atacante, son metadatos que revelan qué se está llamando aunque el cuerpo vaya cifrado en la capa de aplicación.
- **`MRTR` (Multi Round-Trip Requests)** — sustituye a las peticiones iniciadas por el servidor. Cuando una herramienta necesita más datos a mitad de ejecución, el servidor responde `resultType: "input_required"` y el cliente reintenta con las respuestas en `inputResponses`.
- **Deprecaciones**: `roots`, `sampling` y `logging` quedan deprecados (con ventana mínima de 12 meses). El `sampling` —que permitía al servidor pedir generaciones al LLM del cliente— era un vector interesante y va camino de desaparecer.

<mark style="background: #8000E1A6;">La consecuencia de seguridad del modelo stateless: al no haber sesión, la autorización tiene que verificarse en **cada** petición.</mark> La spec lo dice explícitamente — "los servidores MCP que implementen autorización DEBEN verificar todas las peticiones entrantes" y "NO DEBEN tratar la posesión de un `state handle` como autenticación". Esto endurece el modelo frente al *session hijacking* clásico, a cambio de introducir el *state handle hijacking*.

# Errores: la mina de oro del auditor

Cuando una capacidad lanza una excepción no controlada, el servidor responde con un `error`. Si el desarrollador no maneja las excepciones, ese error arrastra **stack traces y mensajes verbosos**:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "error": {
    "code": 0,
    "message": "Error creating resource from template: [Errno 2] No such file or directory: '/tmp/invalid.mcpfile'"
  }
}
```

<mark style="background: #FF5582A6;">Provocar errores es la primera técnica de auditoría de un servidor MCP.</mark> Un mensaje de error puede filtrar rutas del sistema de ficheros, credenciales de APIs internas, estructura de la base de datos o la lógica de la capacidad — todo lo de [[05 - Divulgación de información y broken authorization]]. La nota 2026-07-28 matiza además que los errores de **validación de entrada** deben devolverse como *Tool Execution Errors*, no como errores de protocolo, para que el modelo pueda autocorregirse; eso significa que muchos mensajes de error acaban de vuelta en el contexto del LLM, ampliando el canal.

En [[02 - FastMCP - servidor y cliente en la práctica]] se ve cómo se generan y se leen estos mensajes con la librería `fastmcp`, que es la base de los laboratorios.
