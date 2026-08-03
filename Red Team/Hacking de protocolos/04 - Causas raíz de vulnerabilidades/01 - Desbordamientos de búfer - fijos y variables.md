---
tags:
  - Corrupcion-Memoria
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Desbordamiento de longitud fija, off-by-one y de longitud variable: los tres patrones de código que producen CWE-787 al parsear un protocolo"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Clases de vulnerabilidad en un servicio de red]]"
Nota siguiente: "[[02 - Errores de enteros - overflow, truncamiento y signo]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

<mark style="background: #ADCCFFA6;">Escribir más datos de los que caben en la región reservada</mark>. Es el fallo más antiguo del oficio y sigue siendo **[CWE-787](https://cwe.mitre.org/data/definitions/787.html), el número 1 del CWE Top 25**. En protocolos de red es la vulnerabilidad por excelencia porque <mark style="background: #FFB86CA6;">el atacante controla exactamente lo que hace falta controlar: la longitud y el contenido</mark>.

## Patrón 1: búfer de longitud fija sin comprobación

```c
void leer_cadena(int sock) {
    char str[32];                       // reservado en la PILA
    int i = 0;
    do {
        str[i] = leer_byte(sock);       // ← escribe sin mirar 'i'
        i++;
    } while (str[i-1] != 0);            // ← solo para si llega un NUL
}
```

El bucle termina cuando el atacante manda un `NUL`. Si no lo manda, sigue escribiendo indefinidamente: 32 bytes de búfer, luego el canario, luego la dirección de retorno. <mark style="background: #8000E1A6;">**Control directo del flujo de ejecución**</mark> ([[04 - Explotación de desbordamiento de pila]]).

Las funciones de C que producen esto por diseño, porque **no reciben el tamaño del destino**:

| Peligrosa | Sustituta | Matiz |
| - | - | - |
| `strcpy` | `strlcpy` / `strcpy_s` | `strncpy` **no** garantiza terminación en NUL |
| `strcat` | `strlcat` / `strcat_s` | `strncat` tiene semántica confusa del tamaño |
| `sprintf` | `snprintf` | Comprobar siempre el valor de retorno |
| `gets` | `fgets` | **Eliminada del estándar en C11** |
| `scanf("%s")` | `scanf("%31s")` | Sin límite de campo es equivalente a `gets` |

Buscar estas funciones en los *imports* de un binario ([[02 - Localizar el código de red en un binario]]) es de las primeras cosas que se hacen: su presencia no prueba nada, pero orienta.

## Patrón 2: off-by-one

El programador **sí** comprueba, y aun así falla:

```c
void leer_cadena_arreglada(int sock) {
    char str[32];
    int i = 0;
    do {
        str[i] = leer_byte(sock);
        i++;
    } while ((str[i-1] != 0) && (i < 32));   // corta a los 32
    str[i] = 0;                              // ← ¡BUG! i vale 32 aquí
}
```

Los índices van de 0 a 31. Cuando el bucle sale por longitud, `i == 32`, y `str[32]` es **el byte 33**: fuera del búfer. Un solo byte, y a cero.

> [!warning]+ Un byte parece poco y no lo es
> Un `NUL` de más basta para: sobrescribir el byte bajo del `RBP` guardado (*off-by-one* clásico de pila, que desplaza el marco de la función llamante y da control indirecto), corromper el byte de metadatos de un *chunk* del heap (el histórico *poison NUL byte* de glibc), o truncar un puntero para que apunte a otro objeto. Hay CVEs críticos que son exactamente esto.

## Patrón 3: longitud variable mal calculada

Aquí sí se reserva del tamaño correcto... si la aritmética estuviera bien:

```c
void leer_array(int sock) {
    uint32_t len = leer_u32(sock);              // ① lo controla el atacante
    uint32_t *buf = malloc(len * sizeof(uint32_t));   // ② multiplicación
    for (uint32_t i = 0; i < len; ++i)
        buf[i] = leer_u32(sock);                // ③ escribe 'len' elementos
}
```

Con `len = 0x40000001`, la multiplicación por 4 desborda el `uint32` y da **4**. Se reservan 4 bytes y el bucle escribe 0x40000001 elementos. Es el desbordamiento de heap más limpio que existe, y la causa raíz de verdad es un error de enteros ([[02 - Errores de enteros - overflow, truncamiento y signo]]).

Además: **`malloc(0)` no falla**. Devuelve o `NULL` o un puntero válido a un bloque de tamaño indeterminado, según implementación. Escribir en él es corrupción inmediata. Y muy pocos programas comprueban el retorno de `malloc`.

## Pila frente a heap

| | Pila | Heap |
| - | - | - |
| Qué hay al lado | Canario, `RBP`, **dirección de retorno** | Metadatos del *allocator*, otros objetos |
| Predecibilidad | Alta: el marco tiene forma fija | Baja: depende del historial de reservas |
| Ruta a la ejecución | Sobrescribir el retorno | Corromper un puntero a VTable o a función |
| Mitigación principal | Canarios, ASLR, DEP | Metadatos endurecidos, *heap cookies* |
| Dificultad | Baja | Media-alta: hay que peinar el heap |

El desarrollo de la explotación está en [[04 - Explotación de desbordamiento de pila]] y [[05 - Explotación de heap y VTables]].

## Cómo se encuentran

**Fuzzing** es la vía principal — es lo que mejor detecta ([[00 - Fuzzing de protocolos de red]]), sobre todo compilando con **AddressSanitizer**, que para el programa en el instante exacto del desbordamiento en vez de en el `crash` posterior ([[03 - Sanitizers y heap de depuración]]).

**Con fuente**, los patrones a buscar: `memcpy`/`strcpy` cuyo tamaño viene de la red; bucles `while` sin cota; `alloca()` con tamaño controlado; `char buf[N]` seguido de escrituras indexadas.

**Sin fuente**, en el desensamblado: `REP MOVSB` o llamadas a `memcpy` cuyo tercer argumento se lee del socket, y comparaciones ausentes entre ese valor y el tamaño reservado.

<mark style="background: #FF5582A6;">**Manualmente**, sobre el protocolo ya entendido</mark>: para cada campo de longitud, probar `0`, `1`, el valor real ± 1, `0x7FFFFFFF`, `0x80000000`, `0xFFFFFFFF`; y para cada cadena, mandar 10.000 caracteres sin terminador.

> [!example]+ El patrón sigue vivo en 2026
> **CVE-2026-55200** en `libssh2`: escritura fuera de límites en `ssh2_transport_read()` porque **no se acota superiormente `packet_length`**, explotable por un servidor SSH malicioso **antes de la autenticación**. CVSS 4.0 de 9,2, con PoC público, afectando a todo lo que enlaza `libssh2` — `curl`, `git`, PHP, agentes de backup, firmware de *appliances*. Corregido en 1.12.0.
>
> Es exactamente el patrón 3 de esta nota, en una librería madura y auditada, en 2026.

> [!info]+ Fuentes
> - [NVD — CVE-2026-55200](https://nvd.nist.gov/vuln/detail/CVE-2026-55200). Consultado 2026-08-03.
> - [CWE-787](https://cwe.mitre.org/data/definitions/787.html), [CWE-121](https://cwe.mitre.org/data/definitions/121.html), [CWE-122](https://cwe.mitre.org/data/definitions/122.html), [CWE-193](https://cwe.mitre.org/data/definitions/193.html) (off-by-one).
> - [OWASP — Buffer Overflow](https://owasp.org/www-community/vulnerabilities/Buffer_Overflow) y las *Secure Coding Practices* del SEI CERT C.
