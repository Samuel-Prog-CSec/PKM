---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Descripción: "Lanzar peticiones es trivial; distinguir el acierto del ruido es donde se gana o se pierde el fuzzing. ffuf lo resuelve con dos familias de flags —matchers (qué conservar) y…"
Fecha de actualización: 2026-07-19
Nota previa: "[[04 - Fuzzing de parámetros y valores con ffuf]]"
Nota siguiente: "[[06 - Opciones avanzadas y rendimiento]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

<mark style="background: #FF5582A6;">Lanzar peticiones es trivial; distinguir el acierto del ruido es donde se gana o se pierde el fuzzing</mark>. `ffuf` lo resuelve con dos familias de flags —**matchers** (qué conservar) y **filtros** (qué descartar)— y con la **autocalibración**, que aprende el ruido sola. Es la nota más importante del sub-tema. Su contraparte de metodología —con los equivalentes en `gobuster`/`feroxbuster`— es [[21 - Filtrado de la salida de fuzzing]].

# Matchers: qué conservar (`-m*`)

Por defecto `ffuf` ya aplica `-mc 200-299,301,302,307,401,403,405,500`. Puedes redefinirlo por cualquier métrica:

| Flag | Empareja por | Ejemplo |
| --- | --- | --- |
| `-mc` | Código HTTP | `-mc 200,302` · `-mc all` |
| `-ms` | Tamaño (bytes) | `-ms 1234` |
| `-ml` | Líneas | `-ml 40` |
| `-mw` | Palabras | `-mw 212` |
| `-mr` | Regex en la respuesta | `-mr "admin"` |
| `-mt` | Tiempo de respuesta | `-mt ">500"` |

# Filtros: qué descartar (`-f*`)

Los mismos ejes, en negativo — para eliminar el patrón del "no encontrado":

```shell-session
$ ffuf -w wl.txt -u https://target/FUZZ -fc 404          # descarta 404
$ ffuf -w wl.txt -u https://target/FUZZ -fs 0            # descarta respuestas vacías
$ ffuf -w wl.txt -u https://target/FUZZ -fw 12           # descarta las de 12 palabras
$ ffuf -w wl.txt -u https://target/FUZZ -fc 400-499      # rangos y listas
```

<mark style="background: #ADCCFFA6;">El flujo profesional: `-mc all` para verlo TODO, identificar el patrón del ruido, y filtrarlo</mark> con `-fs`/`-fw`/`-fl`. Filtrar por `Size` mata el soft-404; por `Words`/`Lines` afina cuando el tamaño varía por un timestamp o un token. Apilar varios matchers (o varios filtros) del mismo tipo los combina con `or` por defecto (basta que uno se cumpla); `-mmode and`/`-fmode and` exige que se cumplan **todos**.

# Autocalibración: que ffuf aprenda el ruido

<mark style="background: #FFB86CA6;">`-ac` (autocalibrate) es la joya moderna</mark>: antes de empezar, `ffuf` manda unas cuantas peticiones a rutas que **seguro** no existen, mide la respuesta "no encontrado" y **filtra ese patrón automáticamente** — sin que tú calcules el `-fs`:

```shell-session
$ ffuf -w wl.txt -u https://target/FUZZ -ac
# Autocalibración con strings propios (p. ej. para vhosts o WAFs)
$ ffuf -w wl.txt -u https://target/FUZZ -ac -acc "custom-test-string" -ach
```

- `-ac`: autocalibración estándar (ideal para soft-404 y vhost por defecto).
- `-acc`: añade strings de calibración propios.
- `-ach`: calibra **por host** (necesario al fuzzear varios vhosts/dominios).

> [!success]+ La receta anti-ruido que casi siempre funciona
> ```shell-session
> $ ffuf -w wl.txt -u https://target/FUZZ -mc all -ac -c
> ```
> `-mc all` no descarta nada por código, `-ac` aprende y elimina el patrón de "no encontrado", y ves solo lo que **de verdad** difiere. Si aún queda ruido, añade un `-fs`/`-fw` sobre el tamaño/palabras dominante que observes. Un hallazgo así ya está medio [[22 - Validación de hallazgos|validado]].

Con el ruido bajo control, el siguiente eje es hacerlo **rápido y sin tumbar el objetivo**: [[06 - Opciones avanzadas y rendimiento]].
