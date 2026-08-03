---
tags:
  - Protocolos
  - Redes
  - Pentesting/Explotacion
Descripción: "Tumbar un servicio sin corromper nada: memoria, disco, CPU por complejidad algorítmica y criptografía configurable por el cliente"
Fecha de actualización: 2026-08-03
Nota previa: "[[04 - Use-after-free, double-free y confusión de tipos]]"
Nota siguiente: "[[06 - Format strings e inyección en servicios de red]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

No hace falta corromper memoria para tumbar un servicio. Basta con que **una petición barata para el atacante sea cara para el servidor**. Es la vulnerabilidad más subestimada del catálogo: se reporta poco porque «solo» es DoS, y sin embargo es la que más veces provoca una caída no planificada durante un pentest.

Lo que la diferencia de un DDoS volumétrico es la **asimetría**: aquí no se gasta ancho de banda, se explota un defecto de diseño. Unos pocos kilobytes pueden consumir gigabytes de RAM o minutos de CPU.

## Agotamiento de memoria

```c
uint32_t len = leer_u32(sock);     // ① el atacante dice 4 GB
char *buf = malloc(len);           // ② se reserva
recv(sock, buf, len, 0);           // ③ ...y se envía a 1 byte/s para no cerrar
```

Se reserva **antes** de comprobar que los datos existen. Con varias conexiones simultáneas y envío lento se agota la memoria del sistema. Y si el proceso está limitado por cgroups o corre en un contenedor, el OOM killer lo mata: DoS limpio.

En Linux, el *overcommit* mitiga parcialmente esto (la memoria no se materializa hasta que se toca), pero **en sistemas empotrados, en OT y en dispositivos sin memoria virtual el efecto es inmediato y total**. Es justo donde viven los protocolos propietarios.

Lo correcto es un tope absoluto por mensaje y **reservar de forma incremental** a medida que llegan los datos, nunca por adelantado según lo anunciado.

## Agotamiento de almacenamiento

Casi siempre por **logs**. Si el servicio registra unos cientos de kilobytes por conexión y no hay rotación con límite, unas cuantas miles de conexiones llenan el disco. Y cuando el disco se llena:

- El servicio deja de escribir y puede abortar.
- Otros servicios del mismo volumen fallan.
- <mark style="background: #FFB86CA6;">Si el sistema no puede escribir en el arranque, la denegación es persistente</mark> — sobrevive al reinicio y requiere intervención manual.

El multiplicador clásico: si el servicio **registra datos que envía el cliente** y además acepta **datos comprimidos**, unos kilobytes en el cable se convierten en megabytes en disco.

## Agotamiento de CPU: complejidad algorítmica

El caso más elegante. Todo algoritmo tiene un peor caso, y si el atacante puede construir la entrada, lo dispara.

| Notación | Nombre | Ejemplo |
| - | - | - |
| O(1) | Constante | Acceso a un array |
| O(log n) | Logarítmica | Búsqueda binaria |
| O(n) | Lineal | Recorrer una lista |
| O(n log n) | Casi lineal | Quicksort medio |
| **O(n²)** | Cuadrática | Bubble sort, hash con colisiones |
| **O(2ⁿ)** | Exponencial | Backtracking sin memoización |

**Hash flooding** es el caso canónico. Una tabla hash es O(1) de media y O(n²) si todas las claves colisionan. En 2011, Klink y Wälde demostraron que se podían tumbar servidores web de PHP, Java, Python, Ruby y .NET enviando un formulario con unos cientos de parámetros con hash idéntico — **un solo POST**. La corrección fue adoptar **SipHash** con semilla aleatoria por proceso, que es lo que usan hoy Python, Ruby, Rust y Perl.

En un protocolo propietario, la pregunta es: **¿hay alguna tabla hash indexada por datos que yo controlo?** Nombres de usuario, claves de sesión, cabeceras, identificadores de canal.

**ReDoS** es la otra variante omnipresente: una expresión regular con *backtracking* catastrófico ante una entrada construida ([[00 - Introducción a ReDoS]]). Si el protocolo valida campos con regex, es candidato directo.

Y los sospechosos habituales en cualquier parser: ordenaciones sobre listas controladas por el atacante, búsqueda de subcadenas ingenua (O(n·m)), y descompresión o parseo **recursivo** sin límite de profundidad — que además agota la pila, no el tiempo.

## Criptografía configurable por el cliente

```c
void autenticar(int sock) {
    char *usuario = leer_cadena(sock);
    char *clave   = leer_cadena(sock);
    int iteraciones = leer_int(sock);        // ← ¡lo elige el cliente!
    for (int i = 0; i < iteraciones; i++)
        clave = hash(clave);
    comprobar(usuario, clave);
}
```

El *stretching* de contraseñas (PBKDF2, bcrypt, scrypt, Argon2) está **diseñado para ser caro**. Si el número de iteraciones, el factor de coste o el uso de memoria los fija el cliente y no hay tope, cada petición puede consumir segundos de CPU.

Es un fallo real y frecuente en formatos que llevan sus parámetros dentro: el `$2b$31$` de bcrypt (2³¹ iteraciones) o unos parámetros de scrypt con memoria desmesurada, si el servidor los acepta del cliente en vez de imponerlos.

Variantes de la misma familia: aceptar que el cliente proponga un **tamaño de clave** desmesurado (generar un RSA de 16384 bits tarda minutos), o aceptar parámetros Diffie-Hellman arbitrarios.

## Agotamiento de conexiones y descriptores

- **Slowloris**: abrir muchas conexiones y mandar un byte de vez en cuando para no disparar el *timeout*. Agota el pool de conexiones de servidores con modelo de hilo por conexión.
- **Descriptores de fichero**: cada conexión consume uno; si el límite del proceso es 1024 y no hay control, mil conexiones lo bloquean.
- **Estados a medio negociar**: SYN flood clásico, o su equivalente aplicativo — iniciar mil *handshakes* del protocolo y no terminar ninguno, dejando mil estructuras de sesión reservadas.

## Cómo se prueban

> [!warning]+ Esto tumba servicios de verdad
> A diferencia del resto del catálogo, probar agotamiento **provoca la caída como resultado esperado**, no como efecto secundario. En un *engagement* hay que tenerlo explícitamente autorizado, hacerlo en ventana pactada, contra preproducción si existe, y con alguien localizable para reiniciar. Es la clase de prueba que se acuerda por escrito.

El procedimiento razonable:

1. **Medir el coste base**: cuánta CPU y memoria consume una petición normal.
2. **Variar un parámetro a la vez** y medir la respuesta: longitudes anunciadas, número de elementos, profundidad de anidamiento, iteraciones criptográficas.
3. **Buscar la no linealidad**: si duplicar la entrada cuadruplica el tiempo, tienes O(n²) y un hallazgo.
4. **Extrapolar en vez de ejecutar**: si con 1.000 elementos tarda 2 segundos y la curva es cuadrática, **no hace falta enviar 100.000** para demostrarlo. El informe se escribe con la medición y la extrapolación.

Ese último punto es la diferencia entre un pentester y alguien que tira el entorno del cliente.

> [!info]+ Fuentes
> - [CWE-400](https://cwe.mitre.org/data/definitions/400.html) (consumo incontrolado), [CWE-407](https://cwe.mitre.org/data/definitions/407.html) (complejidad algorítmica), [CWE-770](https://cwe.mitre.org/data/definitions/770.html) (reserva sin límite).
> - Klink & Wälde, *Efficient Denial of Service Attacks on Web Application Platforms* (28C3, 2011) — el trabajo original de hash flooding.
> - [SipHash](https://131002.net/siphash/) — Aumasson & Bernstein, la respuesta adoptada por los lenguajes.
> - [RFC 9106](https://datatracker.ietf.org/doc/html/rfc9106) — Argon2, con recomendaciones de parámetros que el **servidor** debe fijar.
