---
tags:
  - Protocolos
  - Authentication
  - Pentesting/Explotacion
Descripción: "Credenciales embebidas, enumeración de usuarios, comparaciones en tiempo variable y confianza en el estado que envía el cliente"
Fecha de actualización: 2026-08-03
Nota previa: "[[07 - Canonicalización de rutas y errores verbosos]]"
Nota siguiente: "[[09 - Conversión de codificaciones y parser differentials]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

Los fallos de esta nota no corrompen nada: el programa hace exactamente lo que se le pidió. <mark style="background: #ADCCFFA6;">El problema es **a quién se lo permite**</mark>. Son los que el *fuzzing* no encuentra nunca y que hay que buscar entendiendo el protocolo.

## Credenciales por defecto y embebidas

```c
bool autenticar(int sock) {
    char *usuario = leer_cadena(sock);
    char *clave   = leer_cadena(sock);
    if (strcmp(usuario, "debug") == 0)      // ← "quitar antes de release"
        return true;
    return comprobar(usuario, clave);
}
```

Dos variantes con implicaciones distintas:

- **Por defecto**: el producto se instala con `admin:admin` y el administrador no lo cambia. Es un fallo de despliegue.
- **Embebidas** ([CWE-798](https://cwe.mitre.org/data/definitions/798.html)): la credencial está **en el binario** y solo se quita recompilando. Es un fallo del fabricante, y no siempre es un descuido de depuración: a veces es una cuenta de soporte deliberada, que a efectos prácticos es una puerta trasera.

Se encuentran con `strings` sobre el binario, buscando en el desensamblado las llamadas a `strcmp`/`memcmp` cercanas al flujo de autenticación ([[02 - Localizar el código de red en un binario]]), o en el firmware extraído con `binwalk`. Sigue siendo **endémico en dispositivos empotrados, cámaras IP, routers y equipos industriales** — Mirai se construyó entero sobre una lista de 62 pares por defecto.

Y ojo con la variante moderna: **claves de API, tokens y certificados privados** embebidos en aplicaciones móviles y clientes de escritorio. Es lo mismo con otro nombre.

## Enumeración de usuarios

```c
if (!existe_usuario(usuario))
    escribir_error(sock, "El usuario no existe");        // ← distinto
else if (!clave_correcta(usuario, clave))
    escribir_error(sock, "Contraseña incorrecta");       // ← distinto
```

Con esa diferencia, un atacante separa el problema en dos: primero enumera usuarios válidos, luego ataca solo las contraseñas. <mark style="background: #8000E1A6;">Convierte un espacio de búsqueda de usuario × contraseña en usuario + contraseña</mark>.

Los cuatro canales por los que se filtra, en orden de sutileza:

1. **Mensaje distinto** — el obvio.
2. **Código de error o de estado distinto**.
3. **Tiempo de respuesta distinto** — el más frecuente y el que casi nadie corrige. Si el usuario no existe, se devuelve el error **sin ejecutar el hash de la contraseña**; si existe, se ejecuta un bcrypt de 100 ms. La diferencia es medible sin esfuerzo.
4. **Comportamiento colateral**: bloqueo de cuenta que solo se aplica a usuarios reales, o un `429` que solo aparece si la cuenta existe.

La corrección del canal temporal es **ejecutar siempre el mismo trabajo**: hashear contra una contraseña señuelo cuando el usuario no exista, para que el tiempo sea constante.

Metodología completa en [[01 - Enumeración de usuarios]] y [[08 - Enumerar políticas de contraseñas]].

## Comparación en tiempo variable

```c
if (memcmp(token_recibido, token_esperado, 32) == 0) { /* ... */ }
```

`memcmp` **para en el primer byte que difiere**. La diferencia de tiempo entre acertar 0 bytes y acertar 5 es medible, y permite reconstruir el token byte a byte: 256 intentos por posición en vez de 256³² para el token entero.

En una red local con suficientes muestras y análisis estadístico es explotable de verdad; a través de Internet es mucho más difícil pero se ha demostrado. El coste de arreglarlo es cero, así que **es un hallazgo válido aunque la explotación sea costosa**:

```c
// Comparación en tiempo constante: recorre siempre los N bytes
int r = 0;
for (size_t i = 0; i < 32; i++) r |= a[i] ^ b[i];
if (r == 0) { /* iguales */ }
```

En la práctica se usa `CRYPTO_memcmp` (OpenSSL), `sodium_memcmp` (libsodium), `hmac.compare_digest` (Python) o `subtle.ConstantTimeCompare` (Go). El vault lo cubre desde el lado del desarrollo en [[01 - HMAC y comparación en tiempo constante]].

## Confiar en el estado que manda el cliente

El fallo de autorización por excelencia en protocolos con estado:

```c
struct sesion { int socket; int es_admin; char usuario[64]; };

// El cliente envía su "contexto de sesión" en cada mensaje
void procesar(struct sesion *s, comando_t *c) {
    if (c->tipo == CMD_EJECUTAR && s->es_admin)     // ← ¿de dónde salió es_admin?
        system(c->datos);
}
```

<mark style="background: #FF5582A6;">Si `es_admin` viaja en el protocolo —aunque sea dentro de un *blob* que parece opaco— el cliente decide sus propios privilegios.</mark> Variantes que se ven constantemente:

- **Token de sesión que contiene el rol** sin firma, o firmado con un algoritmo que se puede degradar (el `alg: none` de JWT).
- **Identificador de objeto sin comprobación de propiedad** — es IDOR de manual, solo que en binario ([[06 - Introducción a IDOR]]).
- **Comprobación solo en el cliente**: el servidor expone comandos privilegiados y confía en que la interfaz no los muestre. Con el protocolo entendido, se envían directamente.
- **Comandos no documentados sin control de acceso**: los tags que el cliente nunca usa ([[03 - Indexación fuera de límites y expansión de datos]]) a menudo son funciones de administración que nadie protegió porque «no son accesibles».

> [!important]+ La pregunta que resuelve el 80 %
> Para cada comando del protocolo: **¿qué pasa si lo envío sin autenticarme, o autenticado como el usuario con menos privilegios?**
>
> Es una prueba mecánica una vez tienes la lista de comandos ([[05 - Del hex dump a la estructura del protocolo]]) y la capacidad de construir paquetes ([[07 - Modificar el protocolo en vuelo]]). Y es donde más hallazgos de alta severidad salen, porque el *fuzzing* no llega aquí: requiere entender qué significa cada comando.

## Y los fallos de sesión

- **Sin anti-replay**: reproducir la autenticación capturada de otro usuario funciona ([[07 - Modificar el protocolo en vuelo]]).
- **Tokens predecibles**: generados con `rand()` sembrado con la hora, o con contador.
- **Sesión que no expira** o que no se invalida al desconectar.
- **Fijación de sesión**: el cliente propone su propio identificador y el servidor lo acepta.

> [!info]+ Fuentes
> - [CWE-798](https://cwe.mitre.org/data/definitions/798.html) (credenciales embebidas), [CWE-204](https://cwe.mitre.org/data/definitions/204.html) (discrepancia observable en respuesta), [CWE-208](https://cwe.mitre.org/data/definitions/208.html) (discrepancia temporal), [CWE-807](https://cwe.mitre.org/data/definitions/807.html) (confianza en entrada no fiable para decisión de seguridad).
> - [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/) — capítulos V2 (autenticación) y V4 (control de acceso), aplicables fuera de la web.
> - Forshaw, *Attacking Network Protocols*, cap. 9.
