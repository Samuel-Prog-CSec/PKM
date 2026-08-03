---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Describir el formato una vez en un .ksy y obtener parser en 11 lenguajes, visor gráfico y disector de Wireshark — la alternativa declarativa al script desechable"
Fecha de actualización: 2026-08-03
Nota previa: "[[05 - Codificación de binario en texto]]"
Nota siguiente: 
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

El *script* de Python de [[05 - Del hex dump a la estructura del protocolo]] sirve para validar una hipótesis y se tira. Cuando el protocolo va a acompañarte semanas —una auditoría larga, un producto que revisas cada versión, un formato que quieres fuzzear— reescribir ese parser en cada herramienta es trabajo tirado. <mark style="background: #ADCCFFA6;">**Kaitai Struct** resuelve eso: describes la estructura **una vez** en YAML y el compilador te genera el parser</mark>.

Esto no está en el libro (Kaitai es de 2016 pero se consolidó después) y es una de las mejoras claras sobre su metodología.

## Cómo se ve

```yaml
meta:
  id: chat_protocol
  endian: be                    # big endian por defecto en todo el formato
seq:
  - id: magic
    contents: "BINX"            # falla el parseo si no coincide: validación gratis
  - id: messages
    type: message
    repeat: eos                 # hasta el final del flujo
types:
  message:
    seq:
      - id: length
        type: u4
      - id: checksum
        type: u4
      - id: command
        type: u1
        enum: cmd
      - id: body
        size: length - 1        # aritmética sobre campos ya leídos
        type:
          switch-on: command    # parseo distinto según el tag
          cases:
            'cmd::message': msg_body
            'cmd::private': priv_body
  msg_body:
    seq:
      - id: user
        type: pstr
      - id: text
        type: pstr
  pstr:                          # cadena con prefijo de longitud de 1 octeto
    seq:
      - id: len
        type: u1
      - id: value
        type: str
        size: len
        encoding: UTF-8
enums:
  cmd:
    0: hello
    1: hello_ack
    2: quit
    3: message
    5: private
    6: list_req
    7: list_resp
```

Ese fichero contiene **toda** la gramática que dedujiste analizando el volcado: el mágico, el *framing* de longitud, el checksum, el tag como enumerado, las cadenas con prefijo y el parseo condicional por comando. Y encima documenta el hallazgo mejor que cualquier nota en prosa.

## Qué obtienes a cambio

```shell-session
$ kaitai-struct-compiler -t python chat_protocol.ksy      # parser en Python
$ kaitai-struct-compiler -t csharp,java,go,cpp_stl ...    # y en 10 lenguajes más
```

- **Parsers generados** para Python, Java, C#, C++, Go, Rust, JavaScript, Ruby, PHP, Perl, Lua y Nim. El mismo `.ksy` alimenta tu *script* de análisis, tu fuzzer y tu prueba de concepto.
- **Web IDE** ([ide.kaitai.io](https://ide.kaitai.io/)) — cargas el `.ksy` y un volcado, y ves el árbol parseado con **resaltado byte a byte** sobre el hexadecimal. Para iterar sobre una hipótesis es muchísimo más rápido que imprimir por consola.
- **Disector de Wireshark**: el objetivo `-t graphviz` documenta, y existe soporte para generar disectores en Lua desde el `.ksy`, lo que te ahorra escribir a mano lo de [[06 - Dissectors de Wireshark en Lua]].
- **Galería de formatos** — el repositorio `kaitai_struct_formats` ya trae descritos cientos de formatos: ejecutables (PE, ELF, Mach-O), archivos, imágenes, sistemas de ficheros y **protocolos de red** (DNS, DHCP, TCP/IP, TLS). <mark style="background: #FF5582A6;">Antes de escribir el tuyo, mira si ya está</mark>.

> [!important]+ El valor real: el parser es la especificación
> Con un `.ksy`, la documentación del protocolo y la herramienta son el mismo artefacto. Cuando el fabricante saca una versión nueva y cambia el *framing*, actualizas el YAML y **todas** tus herramientas se regeneran. Comparado con mantener a mano un parser de Python, un disector de Lua y un generador de casos de *fuzzing*, la diferencia es sustancial.

## Límites que conviene conocer

- <mark style="background: #FFB8EBA6;">**Kaitai solo lee, no escribe.**</mark> El soporte de serialización lleva años en desarrollo y sigue sin ser general. Para **construir** paquetes (que es lo que necesitas para atacar) hace falta otra cosa: [[🔨📦 Scapy|Scapy]], la librería `construct` de Python (declarativa y bidireccional) o código a mano.
- **No modela bien el estado de sesión.** Describe *un* mensaje o *un* flujo; una máquina de estados con negociación previa hay que llevarla fuera.
- **La aritmética es limitada.** Expresiones sobre campos ya leídos, sí; lógica arbitraria, no. Los casos raros necesitan procesos externos (`process: zlib`, o un `process` propio).

## Cuándo usar qué

| Situación | Herramienta |
| - | - |
| Validar una hipótesis en 10 minutos | Script de Python desechable |
| Formato estable que usarás en varias herramientas | **Kaitai Struct** |
| Ver el protocolo en el contexto de la captura | Disector Lua de Wireshark |
| **Construir** paquetes para atacar | Scapy / `construct` / código propio |
| Explorar a mano un fichero desconocido | ImHex o 010 Editor con plantillas |

En la práctica se combinan: Kaitai para leer y entender, Scapy para construir y romper.

> [!info]+ Fuentes
> - [Kaitai Struct — User Guide](https://doc.kaitai.io/user_guide.html) y [referencia del lenguaje `.ksy`](https://doc.kaitai.io/ksy_reference.html).
> - [kaitai_struct_formats](https://github.com/kaitai-io/kaitai_struct_formats) — galería de formatos ya descritos.
> - [construct](https://construct.readthedocs.io/) — alternativa en Python, bidireccional (parsea y construye).
