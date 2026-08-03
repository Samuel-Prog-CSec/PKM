---
tags:
  - Corrupcion-Memoria
  - Protocolos
  - Pentesting/Explotacion
Descripción: "El paso intermedio de casi toda corrupción de heap: desbordamiento, truncamiento y confusión de signo al calcular tamaños con datos del atacante"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - Desbordamientos de búfer - fijos y variables]]"
Nota siguiente: "[[03 - Indexación fuera de límites y expansión de datos]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

Un error de enteros rara vez es el fallo final. Es <mark style="background: #8000E1A6;">el eslabón que convierte una reserva de memoria «correcta» en una insuficiente</mark>, y a partir de ahí el desbordamiento parece culpa del `memcpy`. Por eso, cuando encuentres una corrupción de heap al parsear un protocolo, la causa raíz casi siempre está unas líneas más arriba, en una multiplicación o una suma.

## Aritmética modular: la premisa

Los enteros nativos tienen tamaño fijo, y la CPU opera módulo 2ⁿ. Si el resultado no cabe, se pierde el acarreo:

```text
 0x41 (65)  ×  4   =  0x104 (260)
 En 8 bits:            0x04 (4)      ← el bit alto se descarta
```

Idéntico con 32 bits: `0x40000001 × 4 = 0x100000004`, que truncado a 32 bits es **4**. En C esto es **silencioso para enteros sin signo** (está definido por el estándar como aritmética modular) y **comportamiento indefinido para enteros con signo** — lo que significa que el compilador puede optimizar asumiendo que nunca ocurre, y eliminar la comprobación que escribiste para detectarlo.

## Los cuatro sabores

### 1. Desbordamiento en el cálculo del tamaño

```c
uint32_t n = leer_u32(sock);
struct item *v = malloc(n * sizeof(struct item));   // ← desborda
for (uint32_t i = 0; i < n; i++) leer_item(sock, &v[i]);
```

El clásico. La forma correcta es comprobar **antes**, o usar aritmética con detección:

```c
if (n > SIZE_MAX / sizeof(struct item)) return -1;   // comprobación previa
// o, con GCC/Clang:
size_t total;
if (__builtin_mul_overflow(n, sizeof(struct item), &total)) return -1;
// o, directamente:
struct item *v = calloc(n, sizeof(struct item));     // calloc comprueba el producto
```

**Matiz sobre `calloc`**: la norma ISO C no dice literalmente «detecta el desbordamiento», pero sí exige que devuelva espacio para un array de `nmemb` objetos — y un array es a su vez un objeto cuyo tamaño tiene que caber en un `size_t`. De ahí que **glibc, musl y el CRT de Windows comprueben el producto y devuelvan `NULL`** si desborda. En la práctica es seguro y por eso se recomienda sobre `malloc(a*b)`; en un objetivo empotrado con una libc exótica, verifícalo antes de darlo por hecho.

OpenBSD añade `reallocarray(ptr, nmemb, size)` justamente para tener la misma garantía al **redimensionar**, que es donde `calloc` no llega; está también en glibc ≥ 2.26.

### 2. Desbordamiento en la suma

```c
uint16_t total = cabecera_len + cuerpo_len;   // ambos uint16 controlados
char *buf = malloc(total);
memcpy(buf, cabecera, cabecera_len);
memcpy(buf + cabecera_len, cuerpo, cuerpo_len);   // ← escribe más de 'total'
```

Con `cabecera_len = 0xFFF0` y `cuerpo_len = 0x0020`, `total` vale `0x10` (16). Se reservan 16 bytes y se copian casi 64 KB.

### 3. Truncamiento al convertir

```c
uint32_t len = leer_u32(sock);      // el atacante manda 0x00010000
uint16_t corta = len;               // ← se queda en 0x0000
char *buf = malloc(corta);          // reserva 0 bytes
recv(sock, buf, len, 0);            // copia 65536
```

Ocurre al pasar de `size_t` (64 bits) a `int` (32 bits), o al asignar a un campo de estructura más pequeño. Es especialmente traicionero porque el desensamblado lo muestra como un simple `mov` a un registro de 32 bits.

### 4. Confusión de signo

El más rentable de los cuatro para el atacante:

```c
int len = leer_i32(sock);                // ← el atacante manda -1
if (len > MAX_LEN) return -1;            // -1 > 1024 es FALSO: pasa el filtro
memcpy(dst, src, len);                   // memcpy toma size_t: -1 → 0xFFFFFFFFFFFFFFFF
```

La comparación se hace **con signo** y la copia **sin signo**. `-1` supera el filtro y se convierte en el mayor tamaño posible. La comprobación correcta es doble:

```c
if (len < 0 || len > MAX_LEN) return -1;
```

Y recuerda la asimetría del complemento a dos ([[00 - Anatomía de un protocolo binario]]): `abs(INT_MIN)` sigue siendo negativo, así que «normalizar» con `abs()` **no arregla nada**.

> [!warning]+ Promoción de tipos: la trampa que casi nadie ve
> En C, los operandos más pequeños que `int` se **promueven a `int` con signo** antes de operar. Consecuencia:
>
> ```c
> uint16_t a = 0xFFFF, b = 0xFFFF;
> if (a * b > 0) { ... }     // a*b se calcula en int (32 bits, con signo)
>                            // 0xFFFE0001 desborda int → COMPORTAMIENTO INDEFINIDO
> ```
>
> Y aún peor: comparar `char` (que en x86 es **con signo**) contra un valor de 0 a 255 hace que los bytes ≥ 0x80 se lean como negativos. Un `if (buf[i] > 0x7F)` **nunca es cierto** con `char` firmado. Es la raíz de innumerables *bypass* de validación de entrada.

## Cómo se detectan

**Con fuente**, la vía definitiva es **UndefinedBehaviorSanitizer**, que aborta en el momento exacto:

```shell-session
$ clang -fsanitize=integer,undefined -fno-sanitize-recover=all -g parser.c
```

Nota importante: `-fsanitize=undefined` detecta el desbordamiento **con signo** (que es UB); el desbordamiento **sin signo** está definido por el estándar y hay que pedirlo aparte con `-fsanitize=unsigned-integer-overflow`, que produce falsos positivos porque hay código que lo usa a propósito (hashes, PRNGs).

**Sin fuente**, en el desensamblado, las señales son:
- `IMUL` / `SHL` sobre un valor que viene de la red, seguido de `CALL malloc`, **sin `JB`/`JO` de por medio**.
- **`MOVSXD`** (extensión con signo de 32 a 64 bits) aplicado a un valor de red antes de usarlo como tamaño: ahí puede colarse un negativo.
- Comparaciones con `JG`/`JL` (con signo) sobre valores que luego se usan como tamaños sin signo.

**Fuzzeando**, los valores que hay que meter siempre en cualquier campo numérico:

```text
0x00000000   0x00000001   0x0000007F   0x00000080   0x000000FF
0x00007FFF   0x00008000   0x0000FFFF   0x7FFFFFFF   0x80000000
0xFFFFFFFF   0xFFFFFFFE   0x40000000   0x40000001
```

Son las fronteras de todos los tipos y las que hacen desbordar al multiplicar por 2, 4, 8 y 16. Un diccionario de *fuzzing* con estos valores encuentra más que millones de casos aleatorios ([[01 - Construir el corpus y el harness]]).

## Y en lenguajes seguros

No desaparecen del todo, cambian de forma:

- **Rust**: *panic* en *debug*, envolvente en *release* salvo que uses `checked_*`/`saturating_*`. Un desbordamiento no corrompe memoria, pero **puede producir lógica incorrecta**.
- **Go**: envolvente silencioso, como C. `int` es de 64 bits, lo que reduce mucho la superficie, pero las conversiones a `int32` truncan igual.
- **Java / C#**: envolvente silencioso; C# tiene `checked {}` y no se usa casi nunca.
- **Python**: enteros de precisión arbitraria — el problema no existe.

En todos ellos el resultado sería una excepción de índice o un valor absurdo, no corrupción de memoria: DoS o fallo lógico, no RCE.

> [!info]+ Fuentes
> - [CWE-190](https://cwe.mitre.org/data/definitions/190.html) (overflow), [CWE-191](https://cwe.mitre.org/data/definitions/191.html) (underflow), [CWE-197](https://cwe.mitre.org/data/definitions/197.html) (truncamiento), [CWE-195](https://cwe.mitre.org/data/definitions/195.html) (confusión de signo).
> - [SEI CERT C — INT30-C, INT31-C, INT32-C](https://wiki.sei.cmu.edu/confluence/display/c/INT30-C.+Ensure+that+unsigned+integer+operations+do+not+wrap).
> - [Clang UBSan — lista de comprobaciones](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html).
