---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[02 - SQLMap sobre peticiones HTTP]]"
Nota siguiente: "[[04 - Enumeración de bases de datos con SQLMap]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

SQLMap funciona "de fábrica" en la mayoría de casos, pero saber afinar la detección marca la diferencia cuando un objetivo no responde a la configuración por defecto. Todo payload que SQLMap envía tiene dos partes: el <mark style="background: #ADCCFFA6;">**vector** (el SQL útil, p. ej. `UNION ALL SELECT 1,2,VERSION()`) y los **boundaries** (el prefijo y sufijo que insertan el vector en la consulta vulnerable, p. ej. `'<vector>-- -`)</mark>. Afinar el ataque es controlar qué vectores y boundaries se prueban.

# `--level` y `--risk`: cuánto prueba

- **`--level` (1-5, def. 1)**: amplía vectores **y** boundaries, de mayor a menor probabilidad de éxito.
- **`--risk` (1-3, def. 1)**: amplía los vectores según su riesgo de causar daño (pérdida de datos, DoS).

El salto es enorme: <mark style="background: #FFB86CA6;">con `--level=1 --risk=1` se prueban ~72 payloads por parámetro; con `--level=5 --risk=3`, ~7.865</mark>. Por eso subirlos ralentiza muchísimo y, por defecto, **no conviene tocarlos**.

> [!important]+
> Lo que el material original no destaca y es crucial: <mark style="background: #FF5582A6;">`--level` también decide *qué* se testea</mark>. A partir de `--level=2` SQLMap prueba las **cookies**; a partir de `--level=3`, cabeceras como `User-Agent` y `Referer`. Si sospechas inyección en una cookie o cabecera, hay que subir el nivel o no se probará nunca.

> [!warning]+
> Los payloads `OR` son peligrosos en una ejecución por defecto porque, si la consulta vulnerable es un `UPDATE`/`DELETE`, pueden afectar a **todas** las filas. SQLMap los reserva para `--risk=3`. <mark style="background: #FFB86CA6;">En páginas de login (donde el bypass requiere `OR`) hay que subir el risk</mark>, asumiendo el peligro: nunca contra producción sin entender la query.

Para ver exactamente qué se envía con cada combinación, `-v 3` muestra los `[PAYLOAD]`.

# `--prefix` / `--suffix`: boundaries manuales

Cuando la query tiene una estructura rara que SQLMap no cubre, se fijan los boundaries a mano. Si el código vulnerable es:

```php
$query = "SELECT ... WHERE id LIKE (('" . $_GET["q"] . "')) LIMIT 0,1";
```

hace falta cerrar `(('`:

```shell-session
$ sqlmap -u "host/?q=test" --prefix="%'))" --suffix="-- -"
```

El vector queda envuelto: `...LIKE (('test%')) UNION ALL SELECT 1,2,VERSION()-- -'))...`. <mark style="background: #8000E1A6;">Conocer la query (por código fuente o por error) permite fijar boundaries que la detección automática no encuentra</mark>.

# Forzar y acotar el ataque

- **`--dbms=MySQL`**: si ya conoces el motor, fuérzalo para no perder tiempo probando otros.
- **`--technique=BEU`**: limita las técnicas usadas (aquí Boolean, Error, Union). Útil para **saltar time-based** si causa timeouts, o forzar una técnica concreta. El orden por defecto es `BEUSTQ`.

# Afinar la detección booleana

Cuando la respuesta tiene mucho contenido dinámico, SQLMap necesita ayuda para distinguir `TRUE` de `FALSE`:

| Opción | Cuándo usarla |
| ------ | ------------- |
| `--string="success"` | Una cadena aparece solo en respuestas `TRUE`. La detección más fiable. |
| `--not-string="error"` | Una cadena aparece solo en respuestas `FALSE`. |
| `--code=200` | La diferencia está en el código HTTP (`200` TRUE vs `500` FALSE). |
| `--titles` | La diferencia está en el `<title>` de la página. |
| `--text-only` | Mucho contenido oculto (`<script>`, `<style>`): compara solo el texto visible. |

<mark style="background: #FFB86CA6;">`--string` elimina los falsos positivos</mark> en blind boolean, porque ancla la comparación a un marcador inequívoco en lugar de a heurísticas difusas.

# Afinar la inyección `UNION`

Si conoces el número de columnas a mano, ahórrale el trabajo a SQLMap:

- `--union-cols=17`: fija el número de columnas.
- `--union-char='a'`: cambia el relleno por defecto (`NULL`/entero aleatorio) si los tipos no encajan.
- `--union-from=users`: añade el `FROM <tabla>` necesario en algunos motores (p. ej. Oracle).

> [!info]+
> Regla práctica: empieza por defecto (`--batch`), y solo sube `--level`/`--risk` o fijas boundaries cuando ya tienes un indicio (detección manual, error revelador) de que hay inyección y SQLMap no la confirma. Afinar a ciegas con valores máximos es lento y ruidoso —dispara WAFs y *rate limits*—.

Con el ataque afinado y la inyección confirmada, SQLMap automatiza la fase que a mano es tediosa: la [[04 - Enumeración de bases de datos con SQLMap|enumeración]].
