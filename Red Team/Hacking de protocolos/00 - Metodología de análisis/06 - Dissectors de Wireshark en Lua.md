---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Escribir un disector propio para que Wireshark entienda tu protocolo: campos filtrables, TVB, el problema del reensamblado TCP y por qué UDP es mucho más fácil"
Fecha de actualización: 2026-08-03
Nota previa: "[[05 - Del hex dump a la estructura del protocolo]]"
Nota siguiente: "[[07 - Modificar el protocolo en vuelo]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

Un *script* de Python que parsea un fichero exportado sirve para descubrir la estructura. Un **disector** la incorpora a Wireshark: el protocolo aparece con nombre en la columna, los campos se despliegan en árbol y —lo que de verdad cambia el trabajo— <mark style="background: #FFB86CA6;">se vuelven filtrables</mark>. Poder escribir `chat.command == 3` y quedarte con los 12 paquetes que importan de una captura de 4.000 es la diferencia entre analizar y ahogarse.

Antes hacía falta escribir el disector en C y recompilar Wireshark. Desde hace años se hace en **Lua**, sin compilar nada, y el mismo fichero funciona con `tshark` en consola.

## Comprobaciones previas

```shell-session
$ tshark -v | head -3        # debe aparecer "with Lua"
```

Ubicación de los *scripts*:

| Plataforma | Ruta personal |
| - | - |
| Windows | `%APPDATA%\Wireshark\plugins\` |
| Linux / macOS | `~/.local/lib/wireshark/plugins/` (y `~/.config/wireshark/plugins/`) |

O sin instalarlo, para iterar rápido:

```shell-session
$ wireshark -X lua_script:disector.lua -r captura.pcap
$ tshark    -X lua_script:disector.lua -r captura.pcap -Y 'chat.command == 3'
```

> [!warning]+ Wireshark desactiva Lua si corres como root
> En Unix, Wireshark deshabilita el motor Lua cuando el proceso es privilegiado — medida de seguridad razonable, porque un disector es código arbitrario. Y no deberías capturar como `root` de todas formas: la configuración correcta es dar `CAP_NET_RAW`/`CAP_NET_ADMIN` a `dumpcap` (`sudo dpkg-reconfigure wireshark-common` en Debian/Ubuntu) y ejecutar el GUI como usuario normal.

## El esqueleto

```lua
-- 1. Declarar el protocolo
chat_proto = Proto("chat", "Protocolo de chat propietario")

-- 2. Declarar los campos: esto es lo que los hace FILTRABLES
local f = chat_proto.fields
f.chksum  = ProtoField.uint32("chat.chksum",  "Checksum", base.HEX)
f.command = ProtoField.uint8 ("chat.command", "Comando")
f.data    = ProtoField.bytes ("chat.data",    "Datos")

-- 3. La función de disección
--    buffer : TVB (Testy Virtual Buffer) con los bytes
--    pinfo  : metadatos del paquete (columnas de la UI)
--    tree   : raíz del árbol de la interfaz
function chat_proto.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = "CHAT"

    local subtree = tree:add(chat_proto, buffer(), "Protocolo de chat")
    subtree:add(f.chksum,  buffer(0, 4))
    subtree:add(f.command, buffer(4, 1))
    subtree:add(f.data,    buffer(5))
end

-- 4. Registrarlo en la tabla de puertos UDP
DissectorTable.get("udp.port"):add(12345, chat_proto)
```

Claves de la API:

- **`buffer(offset, len)`** devuelve un *range* del TVB. Sin `len`, hasta el final. `:uint()`, `:string()`, `:le_uint()` (*little endian*) convierten.
- **`ProtoField`** en `order` es lo que crea el campo de filtro. Si añades nodos con `subtree:add(chat_proto, rango, "texto")` sale en el árbol pero **no es filtrable** — útil para prototipar, insuficiente para trabajar.
- El registro puede ser en `"tcp.port"`, `"udp.port"`, o vía **heurística** (`chat_proto:register_heuristic("tcp", fn)`) cuando el puerto es dinámico: la función devuelve `true` si reconoce el mágico.

Un parser de cadenas con prefijo de longitud, el patrón más habitual:

```lua
local function read_string(buf, start)
    local len = buf(start, 1):uint()
    return buf(start + 1, len):string(), 1 + len
end

-- Dentro del dissector, para el comando 3 (mensaje):
if buffer(4,1):uint() == 3 then
    local data = buffer(5):tvb()
    local user, n = read_string(data, 0)
    subtree:add(data(0, n), "Usuario: " .. user)
    local msg, m = read_string(data, n)
    subtree:add(data(n, m), "Mensaje: " .. msg)
end
```

## El problema real: TCP no respeta tus mensajes

Con UDP, un datagrama es un mensaje y se acabó. Con TCP <mark style="background: #FF5582A6;">un segmento puede llevar medio mensaje, tres mensajes, o un mensaje partido en cinco segmentos</mark>. Un disector ingenuo funciona en la captura de prueba y falla en producción.

La solución correcta es `dissect_tcp_pdus()`, que delega el reensamblado en Wireshark:

```lua
local CABECERA = 9    -- 4 (longitud) + 4 (checksum) + 1 (comando)

-- Devuelve la longitud TOTAL del PDU que empieza en 'offset'.
-- NO hace falta comprobar si hay bastantes bytes: Wireshark garantiza que
-- solo llama aquí cuando ya hay al menos CABECERA bytes disponibles.
local function get_len(tvb, pinfo, offset)
    local declarada = tvb(offset, 4):uint()
    -- Cordura: un valor absurdo indica desincronización o un ataque.
    -- Devolver tvb:len() hace que se consuma lo que hay en vez de colgarse.
    if declarada > 0x100000 then return tvb:len() end
    return declarada + 8              -- el campo 'longitud' no se cuenta a sí mismo
end

local function dissect_pdu(tvb, pinfo, tree)
    pinfo.cols.protocol = "CHAT"
    local t = tree:add(chat_proto, tvb(), "Protocolo de chat")
    t:add(f.length,  tvb(0, 4))
    t:add(f.chksum,  tvb(4, 4))
    t:add(f.command, tvb(8, 1))
    t:add(f.data,    tvb(9))
end

function chat_proto.dissector(tvb, pinfo, tree)
    dissect_tcp_pdus(tvb, tree, CABECERA, get_len, dissect_pdu, true)
    --                          │         │        │            └─ desegmentar (por defecto true)
    --                          │         │        └─ disecciona UN PDU ya completo
    --                          │         └─ calcula la longitud total del PDU
    --                          └─ bytes mínimos para poder calcularla
end

DissectorTable.get("tcp.port"):add(12345, chat_proto)
```

Wireshark acumula los segmentos hasta reunir `get_len()` bytes y entonces llama a `dissect_pdu` con el PDU **ya completo**; si un segmento trae tres mensajes, lo llama tres veces. Requiere el reensamblado TCP activo (`Preferences → Protocols → TCP → Allow subdissector to reassemble TCP streams`, por defecto sí).

> [!warning]+ `get_len` no debe devolver 0 ni comprobar si hay bastantes bytes
> Es el error clásico al escribir esto. `dissect_tcp_pdus` **ya garantiza** que solo invoca `get_len` cuando hay al menos `min_header_size` bytes disponibles — para eso está ese parámetro. Añadir un `if tvb:len() - offset < N then return 0 end` es redundante, y **devolver 0 es peor que redundante**: Wireshark lo interpreta como un PDU de longitud cero y puede quedarse en bucle sobre el mismo offset.
>
> Lo que sí hay que poner es la **comprobación de cordura** del ejemplo: si la longitud declarada es absurda (protocolo desincronizado, o un atacante mandando `0xFFFFFFFF` a propósito), devolver `tvb:len()` consume lo disponible en vez de pedir gigabytes de reensamblado. Es el idioma que usa el propio disector de ejemplo de Wireshark (`test/lua/dissectFPM.lua`).

## Errores y depuración

Un fallo de sintaxis abre un diálogo al arrancar; un fallo en tiempo de ejecución marca el paquete como *malformed*. Para depurar de verdad:

```lua
print("offset=" .. offset .. " len=" .. len)   -- va a la consola de Lua
```

`View → Internals → Lua Console` en el GUI, o directamente `stdout` con `tshark`. Recargar sin reiniciar: `Analyze → Reload Lua Plugins` (`Ctrl+Shift+L`).

## Cuándo NO escribir un disector

- **Si vas a modificar tráfico**, el disector no sirve — es solo lectura. Necesitas un proxy ([[07 - Modificar el protocolo en vuelo]]).
- **Si el formato ya está descrito** en Kaitai Struct, el compilador genera el disector solo ([[06 - Identificación de estructuras con Kaitai Struct]]).
- **Si es de usar y tirar**, un `tshark -T fields` con un `awk` detrás llega a tiempo.

El disector rentabiliza cuando vas a mirar ese protocolo muchas veces: análisis de un producto durante semanas, triaje de capturas de un incidente, o alimentar detección desde el lado defensivo ([[Análisis del tráfico de red]]).

> [!info]+ Fuentes
> - [Wireshark Developer's Guide, cap. 11 — Lua Support](https://www.wireshark.org/docs/wsdg_html_chunked/wsluarm.html) — referencia completa de `Proto`, `ProtoField`, `Tvb` y `dissect_tcp_pdus`. Firma verificada 2026-08-03: `dissect_tcp_pdus(tvb, tree, min_header_size, get_len_func, dissect_func [, desegment])`.
> - [`test/lua/dissectFPM.lua`](https://github.com/wireshark/wireshark/blob/master/test/lua/dissectFPM.lua) del propio repositorio de Wireshark — disector de referencia con reensamblado TCP, de donde sale el idioma de la comprobación de cordura.
> - [Wireshark Wiki — Lua/Dissectors](https://wiki.wireshark.org/Lua/Dissectors), con ejemplos de disectores heurísticos.
> - Forshaw, *Attacking Network Protocols*, cap. 5 (el ejemplo original solo cubre UDP; el reensamblado TCP se añade aquí).
