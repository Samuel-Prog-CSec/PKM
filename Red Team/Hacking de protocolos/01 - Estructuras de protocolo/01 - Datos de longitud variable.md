---
tags:
  - Protocolos
  - Redes
  - Corrupcion-Memoria
  - Pentesting/Enumeracion
Descripción: "Las cuatro formas de delimitar un dato de tamaño desconocido —terminado, prefijado, implícito y rellenado— y el fallo característico de cada una, con CVE-2026-55200 de ejemplo"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Anatomía de un protocolo binario]]"
Nota siguiente: "[[02 - El patrón TLV, multiplexación y fragmentación]]"
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

Casi nada en un protocolo tiene tamaño fijo: nombres de usuario, rutas, mensajes, *blobs* de datos. <mark style="background: #ADCCFFA6;">Cómo se delimita lo que no lo tiene es la decisión de diseño con más consecuencias de seguridad de todo el protocolo</mark>, porque cada estrategia tiene su modo de fallo característico. Hay cuatro.

## 1. Terminado por símbolo

Un valor centinela marca el final. El clásico es el `NUL` de C:

```text
'H'  'e'  'l'  'l'  'o'  NUL
0x48 0x65 0x6C 0x6C 0x6F 0x00
```

También delimitado por pares —cadena entre comillas— o por secuencia (`\r\n\r\n` para el final de cabeceras HTTP).

**El problema**: ¿qué pasa si el dato legítimo contiene el terminador? Hace falta un mecanismo de escape (`\"` o duplicar el símbolo), y ahí es donde se cuelan los fallos.

> [!warning]+ Modos de fallo
> - **Sin terminador**: el parser lee hasta que la memoria se acaba → desbordamiento. Es el patrón de `strcpy` sobre un búfer de pila.
> - **Escape inconsistente entre parsers**: si el emisor y el receptor difieren en cómo escapan, tienes un *parser differential*. En protocolos de texto es el origen de [[06 - Introducción a HTTP Request Smuggling|HTTP request smuggling]]: dos implementaciones que no se ponen de acuerdo en dónde acaba una petición.
> - **NUL embebido**: el clásico *poison null byte*. Una capa (Java, PHP, .NET) trata la cadena como con longitud explícita y valida `fichero.php\0.jpg` como `.jpg`; la capa de abajo (libc) la corta en el `NUL` y abre `fichero.php`. Aparece en [[00 - Introducción a los File Upload Attacks|File Upload]] y en *path traversal*.

## 2. Prefijado por longitud

Un entero delante dice cuántas unidades vienen:

```text
0x05  'H'  'e'  'l'  'l'  'o'
 └── 5 caracteres a continuación
```

Es la estrategia más común en protocolos binarios, y <mark style="background: #FFB86CA6;">también la que más vulnerabilidades ha producido en la historia</mark>.

El tamaño del prefijo suele ser 1, 2 o 4 octetos, y no siempre es coherente con lo que se transporta: un `uint32` para un nombre de usuario permite anunciar 4 GB.

> [!warning]+ La pregunta que hay que hacerse siempre
> **¿Comprueba alguien que la longitud anunciada coincide con la que realmente llega, y que cabe donde se va a copiar?**
>
> Si no, hay tres fallos disponibles:
> - **Longitud > datos reales** → lectura fuera de límites. Es exactamente **Heartbleed** (CVE-2014-0160): el *heartbeat* de TLS anunciaba una longitud, OpenSSL la copiaba sin comprobarla contra el tamaño real del mensaje y devolvía 64 KB de memoria del proceso. Ver [[07 - Heartbleed]].
> - **Longitud > búfer destino** → desbordamiento de escritura.
> - **Longitud descomunal** → o bien un `malloc` gigante que agota memoria ([[05 - Vulnerabilidades de agotamiento de recursos]]), o bien un desbordamiento de entero al multiplicarla por el tamaño de elemento.

> [!example]+ Caso real: CVE-2026-55200 (libssh2)
> `libssh2` hasta la 1.11.1 incluida **no acotaba superiormente el campo `packet_length`** en `ssh2_transport_read()`. Un servidor SSH malicioso podía provocar una escritura fuera de límites **antes de la autenticación**, sin credenciales ni interacción — CVSS 4.0 **9,2 crítico**, con PoC público. Impacto amplificado porque `libssh2` va dentro de `curl`, `git`, `PHP`, agentes de backup y firmware de *appliances*. Corregido en 1.12.0 (publicado el 17-06-2026).
>
> El patrón es exactamente el de esta sección: **campo de longitud + ausencia de cota superior**. Ocho años después de que el libro lo describiera, sigue siendo la vulnerabilidad de protocolo por excelencia.

<mark style="background: #FF5582A6;">Al analizar, lo primero que hay que probar sobre un campo de longitud identificado</mark>: `0x00`, `0x01`, `0xFFFFFFFF`, `0x7FFFFFFF`, `0x80000000` (negativo si se interpreta con signo) y un valor que sea el real ± 1.

## 3. Longitud implícita

El tamaño se deduce del contexto, sin ir en el propio dato:

- **Cierre de conexión** — así devolvía el cuerpo `HTTP/1.0`.
- **Estructura contenedora** — un bloque ya declaró su tamaño total y el último campo ocupa lo que quede.

```text
0x07  0x80 0x00  'H' 'e' 'l' 'l' 'o'
 │      └── varint (2 octetos)
 └── tamaño total del bloque: 7 octetos → la cadena mide 7-2 = 5
```

**El fallo**: la aritmética `total − consumido` puede dar **negativo** si los campos internos anuncian más de lo que cabe. En C, ese resultado negativo asignado a un `size_t` se convierte en un número enorme, y el `memcpy` siguiente arrasa con la memoria. Es un desbordamiento de entero disfrazado de resta inocente.

## 4. Rellenado (*padding*)

Campo de tamaño fijo con relleno hasta completar:

```text
'H' 'e' 'l' 'l' 'o' '$' '$' '$' '$' '$' '$'
└── dato ──┘ └────── relleno ──────┘
```

Simple y con coste predecible, pero:

- **El relleno no siempre se limpia.** Si el emisor reutiliza un búfer sin poner a cero el sobrante, lo que va detrás del dato es **memoria del proceso anterior**. Es una fuga de información silenciosa, y el patrón exacto de **CVE-2003-0001** (el fallo del driver Ethernet de Linux que rellenaba tramas cortas con memoria del kernel) y de los `Etherleak` posteriores.
- **En criptografía, el relleno es un oráculo.** `PKCS#7` sobre CBC es la base del *padding oracle attack*: ver [[03 - Padding Oracle Attacks]].

## Tabla de decisión rápida

| Estrategia | Cómo se reconoce en un volcado | Qué probar primero |
| - | - | - |
| Terminado | Byte constante (`00`, `0A`, `0D 0A`) tras datos variables | Meter el terminador dentro del dato; quitarlo |
| Prefijado | Entero pequeño justo antes de un bloque de ese tamaño | `0`, `0xFFFFFFFF`, negativo, real ± 1 |
| Implícito | El tamaño cuadra solo restando de un total anterior | Campos internos que sumen más que el total |
| Rellenado | Bytes repetidos al final de un campo fijo | Rellenar del todo y un byte más |

## Y en protocolos de texto

Las mismas cuatro ideas con otra piel: delimitadores (espacio, coma, `SOH` en el protocolo financiero FIX), fin de línea (`CR LF` en HTTP y SMTP, aunque casi todos los parsers aceptan `LF` a secas por implementaciones descuidadas — otra fuente de *parser differentials*) y `Content-Length` como prefijo explícito. El desarrollo está en [[04 - Protocolos de texto y formatos estructurados]].

> [!info]+ Fuentes
> - [NVD — CVE-2026-55200](https://nvd.nist.gov/vuln/detail/CVE-2026-55200): descripción, CVSS 4.0 9,2 y versiones afectadas de `libssh2`. Consultado 2026-08-03.
> - [RFC 6520 §4](https://datatracker.ietf.org/doc/html/rfc6520) — el *heartbeat* de TLS cuya implementación produjo Heartbleed.
> - Forshaw, *Attacking Network Protocols*, cap. 3, «Variable Binary Length Data».
