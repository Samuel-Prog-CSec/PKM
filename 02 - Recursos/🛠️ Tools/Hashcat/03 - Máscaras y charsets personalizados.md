---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
Descripción: "La tabla completa de charsets, los cuatro conjuntos propios, los ficheros .hcchr y .hcmask, y el techo de --increment que sorprende a todo el mundo"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - Combinator e híbridos a fondo]]"
Nota siguiente: "[[04 - Backends, dispositivos y tuning]]"
Area: "[[Hashcat.base|Hashcat]]"
---
---

Una máscara describe la **forma** del candidato, posición a posición. Es la herramienta correcta cuando se conoce la estructura pero no el contenido — una política de contraseñas, un prefijo corporativo, un número de teléfono. La sintaxis básica está en [[01 - Ataques avanzados y optimización con Hashcat]]; aquí van los detalles que deciden si la máscara es viable.

# Los charsets integrados

| Token | Expande a |
| ----- | --------- |
| `?l` | `abcdefghijklmnopqrstuvwxyz` |
| `?u` | `ABCDEFGHIJKLMNOPQRSTUVWXYZ` |
| `?d` | `0123456789` |
| `?h` | `0123456789abcdef` |
| `?H` | `0123456789ABCDEF` |
| `?s` | Los 33 símbolos imprimibles, incluido el espacio (ver abajo) |
| `?a` | `?l?u?d?s` — los 95 imprimibles ASCII |
| `?b` | **`0x00`–`0xff`** — los 256 valores de byte |

El contenido exacto de `?s`, que no cabe legible en una celda porque incluye la barra vertical y el acento grave:

```text
 !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
```

Empieza por un **espacio**, que es el carácter que más se olvida al construir una máscara a mano.

> [!warning]+ `?b` no es `?a`
> Circulan tablas —la del módulo 312 de HTB entre ellas— que dan `?l?u?d?s` como ejemplo de `?b`, copiando la fila de `?a`. <mark style="background: #FF5582A6;">`?b` es el espacio completo de bytes</mark>, incluidos los no imprimibles. Sólo sirve para claves binarias, y multiplica el espacio por 2,7 respecto a `?a` en cada posición. Verificado en la [documentación oficial](https://hashcat.net/wiki/doku.php?id=mask_attack).

Para escribir un `?` literal dentro de una máscara se duplica: `??`.

# Charsets propios: `-1` a `-4`

Cuatro conjuntos definidos por el usuario, referenciados como `?1`…`?4`. Se pueden componer con los integrados:

```shell-session
$ hashcat -m 22000 -a 3 hash.hc22000 -1 '?l?d' '?1?1?1?1?1?1?1?1'
$ hashcat -m 22000 -a 3 hash.hc22000 -1 '?d?s' '?u?l?l?l?l?l?l?l?1'
$ hashcat -m 22000 -a 3 hash.hc22000 -1 'abcdef?d' -2 '?u?s' '?1?1?1?2?2'
```

<mark style="background: #FFB86CA6;">Aquí está el mayor ahorro disponible</mark>. Si se sabe que la última posición es un dígito o un símbolo, `-1 '?d?s'` da 42 candidatas por posición frente a las 95 de `?a`: un factor 2,3 por cada posición afectada, que compuesto sobre cuatro posiciones es un factor 28.

## Ficheros `.hcchr`

Un charset reutilizable se guarda en un fichero de texto plano y se pasa igual que una cadena:

```shell-session
$ printf 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' > alnum.hcchr
$ hashcat -m 22000 -a 3 hash.hc22000 -1 alnum.hcchr '?1?1?1?1?1?1?1?1'
```

hashcat trae una colección en `charsets/`, organizada en `standard/` (por idioma) y `special/` (por codificación). Entre los idiomas hay **`Castilian` y `Catalan`**, además de `French`, `German`, `Greek`, `Polish` y una veintena más. Son imprescindibles cuando el objetivo no escribe en ASCII: <mark style="background: #FFB8EBA6;">una máscara `?l` nunca encontrará una contraseña con `ñ`, `ü` o `ç`</mark>, y en un engagement en España eso descarta una fracción nada trivial del espacio real.

```shell-session
$ ls charsets/standard/Castilian/       # es-ES_ISO-8859-1 · es-ES_ISO-8859-15 · es-ES_cp1252
$ hashcat -m 22000 -a 3 hash.hc22000 -1 charsets/standard/Castilian/es-ES_cp1252.hcchr '?1?1?1?1?1?1?1?1'
```

> [!important]+ El fichero no debe llevar salto de línea final
> Un `echo` normal añade `\n`, que hashcat interpreta como un carácter más del conjunto. Usar `printf` sin `\n`, o `echo -n`. Es un fallo silencioso: el ataque funciona, pero prueba candidatas con saltos de línea y desperdicia una fracción del espacio.

# `--increment` y su techo

`--increment` recorre longitudes crecientes en vez de una fija:

```shell-session
$ hashcat -m 22000 -a 3 hash.hc22000 --increment --increment-min=8 --increment-max=12 '?a?a?a?a?a?a?a?a?a?a?a?a'
```

Dos comportamientos que sorprenden:

1. **La máscara actúa como techo.** El incremento no puede superar el número de posiciones escritas. Para llegar a 12 caracteres hay que escribir 12 tokens, aunque el mínimo sea 8. Una máscara de 8 con `--increment-max=12` se queda en 8 sin avisar.
2. **Se rellena por la izquierda.** hashcat va tomando prefijos de la máscara: con `?u?l?l?d?d`, la longitud 3 prueba `?u?l?l`, no `?l?d?d`. Si el patrón real termina en dígitos, hay que construir la máscara pensando en eso o usar varias máscaras.

Además, cada modo impone sus propios límites: `-m 22000` acepta 8–63 y **rechaza** en silencio lo que quede fuera, contándolo en `Rejected`.

# Ficheros de máscaras `.hcmask`

En vez de una máscara por ejecución, un fichero con una por línea. Se pasa igual que una wordlist en `-a 3`:

```text
?u?l?l?l?l?l?d?d
?u?l?l?l?l?l?l?d?d?d?d
Empresa?d?d?d?d
?d?d?d?d?d?d?d?d?d
```

```shell-session
$ hashcat -m 22000 -a 3 hash.hc22000 politica.hcmask
```

Los charsets propios se pueden declarar **por línea**, separados por comas, lo que permite que cada máscara tenga los suyos:

```text
?d?s,?u?l?l?l?l?l?1?1
abcdef?d,?u?s,?1?1?1?2?2
```

hashcat incluye en `masks/` una colección derivada del análisis estadístico de `rockyou`, y su nomenclatura es más útil de lo que parece: <mark style="background: #FFB86CA6;">el número del nombre es el **presupuesto de tiempo en segundos**</mark>.

| Fichero | Presupuesto |
| ------- | ----------- |
| `rockyou-1-60.hcmask` | 1 minuto |
| `rockyou-2-1800.hcmask` | 30 minutos |
| `rockyou-3-3600.hcmask` | 1 hora |
| `rockyou-4-43200.hcmask` | 12 horas |
| `rockyou-5-86400.hcmask` | 1 día |
| `rockyou-6-864000.hcmask` | 10 días |
| `rockyou-7-2592000.hcmask` | 30 días |

Cada uno contiene las máscaras más rentables que caben en ese presupuesto, ordenadas por probabilidad. Elegir el fichero es elegir cuánto tiempo se le dedica al objetivo — mucho mejor punto de partida que inventar una máscara cuando no se sabe nada de la política. También están `8char-1l-1u-1d-1s-compliant.hcmask` y su versión `noncompliant`, para el caso concretísimo de una política de "8 caracteres con las cuatro clases".

# Ordenar por rentabilidad, no por longitud

```shell-session
$ hashcat -a 3 --keyspace '?u?l?l?l?l?l?d?d'
$ hashcat -b -m 22000
```

Con esos dos datos se calcula el tiempo de cada máscara y se ordenan de más a menos rentable. <mark style="background: #8000E1A6;">Una máscara que tarda dos minutos y cubre el 5 % de los casos vale más que una de tres días que cubre el 20 %</mark>, porque se pueden lanzar treinta de las primeras en el tiempo de una de las segundas.

La aritmética concreta para WPA2 —qué espacios son alcanzables y cuáles no— está en [[04 - Anatomía de una contraseña Wi-Fi]].

# Generar máscaras a partir de datos

Cuando ya hay contraseñas crackeadas de la misma organización, la mejor máscara es la que sale de ellas. `maskprocessor` (de la misma familia que hashcat) genera candidatas por patrón, y `PACK`/`policygen` deriva máscaras de un conjunto de contraseñas conocidas o de una política declarada:

```shell-session
$ mp64 -1 '?d?s' 'Empresa?1?1?1?1' | hashcat -m 22000 hash.hc22000
```

Ese bucle —crackear, analizar, generar máscaras, volver a crackear— es lo que convierte un 20 % de éxito inicial en un 60 % en el análisis de contraseñas de dominio descrito en [[11 - Post-explotación y valor para el cliente]].
