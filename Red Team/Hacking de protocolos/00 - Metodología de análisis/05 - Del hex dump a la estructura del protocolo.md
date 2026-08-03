---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "El flujo real de trabajo: exportar el flujo crudo, aislar una dirección, formular hipótesis sobre longitud, checksum y tag, y validarlas con un parser que peta si te equivocas"
Fecha de actualización: 2026-08-03
Nota previa: "[[04 - Redirigir el tráfico hacia tu proxy]]"
Nota siguiente: "[[06 - Dissectors de Wireshark en Lua]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

Aquí es donde se hace el trabajo. Tienes tráfico capturado de un protocolo que nadie ha documentado y hay que convertirlo en una gramática. La técnica clave no es mirar el volcado hasta que aparezca el patrón — es <mark style="background: #ADCCFFA6;">escribir un *parser* desechable que falle ruidosamente en cuanto la hipótesis sea falsa</mark>.

## Paso 0: generar tráfico a propósito

Antes de capturar, ejercita el cliente **a conciencia**: todas las funciones, dos usuarios distintos, varias sesiones abiertas y cerradas, y mensajes con contenido incremental (`A`, `AA`, `AAA`…). Los mensajes con contenido controlado convierten el análisis en aritmética: si envías un byte más y un campo sube exactamente en uno, ya sabes qué es.

Y anota, con marca de tiempo, **qué hiciste en cada momento**. La correlación acción ↔ bytes es la mitad del trabajo, y sin apuntes se pierde.

## Paso 1: aislar una dirección

Las dos direcciones son protocolos distintos y mezclarlas confunde. En Wireshark: `Follow → TCP Stream`, formato `Hex Dump`, y en el desplegable inferior selecciona **una** dirección. Para exportar los bytes crudos, cambia a `Raw` y `Save as`.

Por consola:

```shell-session
$ tshark -r captura.pcap -T fields -e data -Y 'tcp.srcport==49825' | xxd -p -r > salida.bin
$ tshark -r captura.pcap -T fields -e data -Y 'tcp.dstport==12345' | xxd -p -r > entrada.bin
```

## Paso 2: leer el volcado con las estructuras en la cabeza

```text
00000000  42 49 4e 58                                        BINX      ← ①
00000004  00 00 00 0d                                        ....      ← ②
00000008  00 00 03 55                                        ...U      ← ③
0000000C  00                                                 .         ← ④
0000000D  05 61 6c 69 63 65 04 4f  4e 59 58 00               .alice.ONYX. ← ⑤
00000019  00 00 00 14                                        ....
0000001D  00 00 06 3f                                        ...?
00000021  03
00000022  05 61 6c 69 63 65 0c 48  65 6c 6c 6f 20 54 68 65   .alice.Hello The
```

Lo que salta a la vista, con el catálogo de [[00 - Anatomía de un protocolo binario]] delante:

- **①** cuatro bytes ASCII al principio del flujo, que **no se repiten nunca más**: número mágico. Sirve al servidor para verificar que habla con un cliente legítimo y no con lo que sea que se ha conectado al puerto.
- **②** `0x0000000D` = 13. Valor pequeño, *big endian*, delante de un bloque: **candidato a longitud**.
- **③** cambia en cada mensaje sin patrón evidente: incógnita.
- **④** un solo byte, valores en un rango corto: **candidato a tag / tipo de mensaje**.
- **⑤** `05` seguido de exactamente 5 bytes `alice`, luego `04` seguido de 4 bytes `ONYX`: **cadenas con prefijo de longitud de 1 byte**, anidadas dentro del bloque de datos.

> [!important]+ Los bloques del hex dump son paquetes TCP
> En la vista `Hex Dump` de Wireshark, cada bloque separado es **un segmento TCP**, no una unidad del protocolo. Que la longitud llegue en un segmento de 4 bytes y los datos en otro es normal: TCP es un flujo y la aplicación escribe cuando quiere. Por eso el protocolo necesita su propio *framing* (longitud, terminador o TLV) — y por eso tu parser debe leer del flujo concatenado, no paquete a paquete.

## Paso 3: validar con código que falla

```python
from struct import unpack
import sys, os

def read_bytes(f, n):
    b = f.read(n)
    if len(b) != n:                      # ← la clave: si la hipótesis es falsa, revienta
        raise Exception(f"Faltan bytes: pedidos {n}, leídos {len(b)}")
    return b

def read_u32(f):  return unpack("!I", read_bytes(f, 4))[0]   # ! = network order
def read_u8(f):   return read_bytes(f, 1)[0]

path = sys.argv[1]
size = os.path.getsize(path)
with open(path, "rb") as f:
    if read_bytes(f, 4) != b"BINX":      # el mágico solo está en el flujo saliente
        f.seek(0)
    while f.tell() < size:
        length = read_u32(f)
        unk1   = read_u32(f)
        tag    = read_u8(f)
        data   = read_bytes(f, length - 1)    # el tag cuenta dentro de length
        print(f"len={length:4} unk1={unk1:6} tag={tag:2} data={data!r}")
```

Lanzarlo contra el volcado saliente:

```shell-session
$ python3 parse.py saliente.bin
len=  15 unk1=  1139 tag= 0 data=b'\x03bob\x08user-box\x00'
len=  18 unk1=  1415 tag= 3 data=b'\x03bob\x0cHow are you?'
len=  28 unk1=  2275 tag= 3 data=b"\x03bob\x16This is nice isn't it?"
len=   1 unk1=     6 tag= 6 data=b''
len=  19 unk1=  1145 tag= 5 data=b'\x05alice\x00\x00\x00\x03\x03bob\x03Woo'
len=  21 unk1=  1677 tag= 2 data=b"\x13I'm going away now!"
```

**Que llegue al final sin excepciones es el resultado que buscas.** Si peta en el tercer mensaje, aún mejor: sabes el offset exacto donde tu hipótesis se rompe.

Y el volcado entrante te enseña otra cosa:

```shell-session
$ python3 parse.py entrante.bin
Traceback (most recent call last):
  ...
Exception: Faltan bytes: pedidos 16777215, leídos 2
```

Un `length` de 16 millones es absurdo, así que **la hipótesis falla aquí**. El motivo: el mágico `BINX` solo va en el sentido cliente→servidor, y al no encontrarlo el script debe rebobinar. Eso es lo que hace el `f.seek(0)` de la línea 12 — quítalo y verás justo esta excepción. Es el ciclo de trabajo en miniatura: el parser no «da error», **te dice dónde estabas equivocado**.

Con `length - 1` acabas de verificar algo concreto: la longitud **incluye el tag, pero no se incluye a sí misma ni al campo desconocido**. Si hubieras supuesto que sí se incluye, el desfase de 4 bytes habría reventado el segundo mensaje. Ese tipo de detalle solo se confirma haciendo la aritmética y dejando que el código falle.

## Paso 4: cazar el campo desconocido

`unk1` varía sin patrón. Las hipótesis habituales, en orden de probabilidad: **checksum**, número de secuencia, *timestamp*, identificador de sesión o *nonce*.

El atajo son los **mensajes degenerados**. Busca el paquete más corto de la captura:

```text
SALIENTE: len=1, unk1=6, tag=6, data=b''
ENTRANTE: len=2, unk1=1, tag=1, data=b'\x00'
```

En el primero, `unk1 == tag == 6` y no hay datos. En el segundo, `unk1 == 1` y el contenido tras `unk1` es `tag=1` más un byte `\x00` — que suma 1. <mark style="background: #ADCCFFA6;">En ambos, `unk1` coincide con la suma de todo lo que viene detrás</mark>. Eso apunta a **checksum aditivo simple**, y se confirma añadiendo dos líneas al script:

```python
def checksum(tag, data):
    return tag + sum(data)

# ...dentro del bucle, tras leer 'data':
calc = checksum(tag, data)
print(f"len={length:4} unk1={unk1:6} calc={calc:6} "
      f"{'OK' if calc == unk1 else '<<< NO CUADRA'}  tag={tag:2}")
```

```shell-session
$ python3 parse.py saliente.bin
len=  15 unk1=  1139 calc=  1139 OK  tag= 0
len=  18 unk1=  1415 calc=  1415 OK  tag= 3
len=  28 unk1=  2275 calc=  2275 OK  tag= 3
len=   1 unk1=     6 calc=     6 OK  tag= 6
len=  19 unk1=  1145 calc=  1145 OK  tag= 5
len=  21 unk1=  1677 calc=  1677 OK  tag= 2
```

Seis de seis. **Campo resuelto**, y además ahora puedes *generar* paquetes válidos, que es lo que hace falta para [[07 - Modificar el protocolo en vuelo|manipular]] y [[00 - Fuzzing de protocolos de red|fuzzear]]. Si no coincide en algunos, mira si son los largos (podría ser CRC32, Fletcher o Adler-32; `binascii.crc32` y `zlib.adler32` se prueban en un minuto) o si hay una clave/sal implicada (entonces es un MAC, y eso cambia el juego: ver [[03 - Formatos binarios estructurados]] y las notas de [[HTTPs-TLS.base|HTTPs-TLS]]).

## Paso 5: mapear el tag a comandos

Correlaciona cada valor de tag con la acción del cliente que lo produjo — para eso servían los apuntes del paso 0:

| Tag | Dirección | Acción |
| - | - | - |
| 0 | Saliente | Hola inicial al conectar |
| 1 | Entrante | Respuesta del servidor al hola |
| 2 | Ambas | Desconexión (`/quit`) |
| 3 | Ambas | Mensaje a todos |
| 5 | Saliente | Mensaje privado (`/msg`) |
| 6 / 7 | Sal. / Ent. | Petición y respuesta de listado de usuarios |

Los **huecos importan**: si existen los tags 0-3 y 5-7 pero no el 4, hay un comando que no has disparado. Puede ser una función de administración, de depuración o de una versión distinta del cliente — y <mark style="background: #FF5582A6;">un comando no documentado que el cliente nunca envía es exactamente donde suelen vivir los fallos</mark>, porque es código que nadie prueba. Enviarlo a mano es de las primeras cosas que hay que intentar.

## Paso 6: automatizar

Con la gramática en pie, el *script* desechable se convierte en un disector ([[06 - Dissectors de Wireshark en Lua]]) o en la capa de parseo de un proxy ([[07 - Modificar el protocolo en vuelo]]). Si el formato es estable y vas a volver a él, merece la pena escribirlo como especificación declarativa en Kaitai Struct ([[06 - Identificación de estructuras con Kaitai Struct]]) y que te genere el parser en varios lenguajes de golpe.

> [!info]+ Fuentes
> - Forshaw, *Attacking Network Protocols*, cap. 5 — el flujo original (aquí reordenado en pasos y con el *tooling* actualizado).
> - `struct` de Python: [documentación oficial de formatos y orden de bytes](https://docs.python.org/3/library/struct.html#byte-order-size-and-alignment).
