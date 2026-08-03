---
tags:
  - Corrupcion-Memoria
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Cuando el atacante controla el índice y no el tamaño: escritura y lectura arbitrarias, tablas de punteros a función, y bombas de descompresión"
Fecha de actualización: 2026-08-03
Nota previa: "[[02 - Errores de enteros - overflow, truncamiento y signo]]"
Nota siguiente: "[[04 - Use-after-free, double-free y confusión de tipos]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

En el desbordamiento clásico el atacante controla **cuánto** se escribe. Aquí controla **dónde**, y eso suele ser más potente: en vez de arrasar todo lo que hay a partir de un punto, escribes un valor exacto en una posición elegida sin tocar nada más — lo que además esquiva las mitigaciones basadas en detectar corrupción contigua, como los canarios de pila.

## Escritura fuera de límites

```c
uint8_t flags[32];                     // 32 posiciones, índices 0..31

void actualizar_flag(int sock) {
    uint8_t idx = leer_byte(sock);     // ① rango 0..255
    uint8_t val = leer_byte(sock);
    flags[idx] = val;                  // ② sin comprobar idx
}
```

Con `idx` de 32 a 255 se escribe fuera. Si `flags` está en la pila, se llega a variables locales, al canario o al retorno; si es global, a otras globales o a la GOT.

<mark style="background: #FFB86CA6;">Que el índice sea de 1 byte no limita el alcance</mark>: si el elemento es de 8 bytes (una tabla de punteros), 255 elementos cubren 2 KB. Y muchos protocolos usan índices de 16 o 32 bits.

## Lectura fuera de límites

El mismo fallo en el otro sentido: `return flags[idx];` con `idx` sin validar devuelve memoria adyacente. Impacto: **divulgación de información** — punteros que rompen ASLR, restos de otras conexiones, credenciales.

Aquí encaja la variante más rentable, que es corromper **la longitud** de un objeto en vez de leer directamente:

```text
Antes:  [ len = 5 ][ "Hello" ][ otros objetos del heap ]
                ↑ el desbordamiento cambia solo esto
Después:[ len = 100 ][ "Hello" ][ otros objetos del heap ]
                                  └── ahora se devuelven al leer la cadena
```

Un desbordamiento de un solo campo se convierte en una fuga de 100 bytes de heap. Es exactamente el mecanismo de **Heartbleed** ([[07 - Heartbleed]]) y la forma estándar de **derrotar ASLR** antes de explotar ([[08 - Mitigaciones modernas y cómo se saltan]]).

## El caso crítico: tablas de punteros a función

El patrón de despacho más habitual en un servidor de protocolo:

```c
typedef void (*manejador_t)(int sock);
manejador_t tabla[16] = { hola, adios, mensaje, /* ... */ };

void despachar(int sock) {
    uint8_t cmd = leer_byte(sock);
    tabla[cmd](sock);                  // ← índice sin validar
}
```

Con `cmd ≥ 16` se lee un puntero de memoria arbitraria **y se salta a él**. No hace falta corromper nada: si en esa dirección hay un valor que apunte a algo controlable, es ejecución directa. Es de las rutas más limpias a RCE que existen, y aparece constantemente porque el despacho por tabla es la forma natural de escribir un parser de protocolo.

> [!warning]+ El fallo del despachador es lo primero que hay que probar
> En cuanto identifiques el campo de comando ([[05 - Del hex dump a la estructura del protocolo]]), **envía todos los valores posibles**, no solo los que usa el cliente. Con un byte son 256 pruebas; con 16 bits, 65.536. Es barato, automatizable y encuentra tanto comandos ocultos como este fallo.

## Expansión de datos

El tamaño del búfer se calcula sobre datos **antes** de una transformación que los agranda:

```c
uint32_t tam_descomprimido = leer_u32(sock);   // ① lo dice el atacante
char *buf = malloc(tam_descomprimido);         // ② se reserva eso
gzip_descomprimir(sock, buf);                  // ③ ¿y si sale más?
```

Si el flujo comprimido produce más de lo anunciado y `gzip_descomprimir` no recibe el límite, hay desbordamiento de heap.

Vale para **cualquier** transformación que cambie el tamaño:

| Transformación | Factor de expansión | De dónde sale el número |
| - | - | - |
| gzip / DEFLATE | **1032:1** | Un par longitud/distancia produce como mucho 258 bytes y ocupa como mínimo 2 bits → 8 bits de entrada dan 1032 de salida ([zlib](https://zlib.net/zlib_tech.html)) |
| bzip2 | **~1.400.000:1** | RLE + Burrows-Wheeler sobre datos repetitivos. Unos **1.000× más** que DEFLATE |
| XZ / LZMA | Extremo | Ventana muy grande |
| Entidades XML | Ilimitado | *Billion laughs*: anidamiento exponencial |
| Base64 → binario | 0,75:1 | **Contrae**, no expande |
| UTF-8 → UTF-32 | Hasta 4:1 | 1 byte ASCII → 4 bytes |
| Descifrado con padding | Variable | Depende del esquema |

Ese 1032:1 es la razón de que la regla práctica sea **no fiarse del tamaño anunciado**: un mensaje de 1 MB comprimido puede legítimamente producir 1 GB.

> [!important]+ Dos fallos distintos con la misma causa
> - Si **el búfer es fijo y la expansión lo supera** → desbordamiento de heap, potencialmente RCE.
> - Si **el búfer crece dinámicamente sin límite** → agotamiento de memoria, DoS ([[05 - Vulnerabilidades de agotamiento de recursos]]). Es la *zip bomb* y el *billion laughs* de XML.
>
> El primero es más grave, el segundo mucho más frecuente. Ambos se prueban igual: mandar un bloque comprimido que expanda muchísimo y ver qué pasa.

La forma correcta de escribir esto es **no confiar nunca en el tamaño anunciado**: descomprimir por trozos con un límite absoluto, comprobando en cada iteración cuánto se lleva producido.

## Cómo se detectan

**Con fuente**: todo acceso `array[i]` donde `i` proceda de la red y no haya un `if (i < N)` justo antes. Y toda llamada a descompresión, decodificación o conversión de codificación cuyo búfer destino se dimensione con un valor del protocolo.

**Sin fuente**, en el desensamblado: un valor leído del socket usado como desplazamiento (`mov rax, [rbx + rcx*8]`) sin un `CMP`/`JAE` previo. El `*8` delata una tabla de punteros.

**Fuzzeando**: para cada campo que parezca índice o comando, barrer **todo el rango**, no valores aleatorios. Y ASan detecta el acceso fuera de límites en el instante ([[03 - Sanitizers y heap de depuración]]).

**Manualmente**, el vector rápido: identificar el byte de comando, enviar los 256 valores, y observar qué provoca respuesta distinta, caída o retardo.

> [!info]+ Fuentes
> - [CWE-125](https://cwe.mitre.org/data/definitions/125.html) (lectura fuera de límites), [CWE-787](https://cwe.mitre.org/data/definitions/787.html) (escritura), [CWE-129](https://cwe.mitre.org/data/definitions/129.html) (validación incorrecta de índice), [CWE-409](https://cwe.mitre.org/data/definitions/409.html) (expansión de datos).
> - [CVE-2014-0160](https://nvd.nist.gov/vuln/detail/CVE-2014-0160) — Heartbleed, el caso canónico de longitud corrupta → fuga de heap.
> - Forshaw, *Attacking Network Protocols*, cap. 9, «Out-of-Bounds Buffer Indexing» y «Data Expansion Attack».
