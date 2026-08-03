---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "La SQLi clásica que hemos visto es *non-blind*: la salida de la consulta aparece en la respuesta, y se explota con UNION o leyendo errores"
Fecha de actualización: 2026-06-04
Nota previa: "[[00 - Introducción a MSSQL]]"
Nota siguiente: "[[02 - Identificar SQLi basada en booleanos]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

La SQLi clásica que hemos visto es *non-blind*: la salida de la consulta aparece en la respuesta, y se explota con [[05 - Inyección UNION|UNION]] o leyendo errores. <mark style="background: #ADCCFFA6;">La `blind SQL injection` es aquella en la que el atacante **no recibe el resultado** de la consulta y debe inferirlo a partir de diferencias en el comportamiento de la página</mark>. Es más lenta y laboriosa, pero —y esto es clave— es **la forma más común de SQLi que queda en aplicaciones modernas**.

> [!example]+ Caso real — Uber Blind SQLi · $4.000 · [H1 #150156](https://hackerone.com/reports/150156)
> Orange Tsai vio que el enlace de baja de un email de Uber llevaba un parámetro **base64 con JSON** (`{"user_id":"5755",...}`). Añadió `and sleep(12)=1` a `user_id`, lo re-codificó, y la respuesta tardó 12s+ → **blind time-based** confirmada. Extrajo el `user()` carácter a carácter con `mid(user(),N,1)='X'#` en un script Python (`requests`+`base64`). **Lección**: vigila los parámetros codificados —decodifica, inyecta, re-codifica— y un `sleep()` diferencial basta como PoC, sin volcar datos reales.

> [!important]+
> <mark style="background: #8000E1A6;">Por qué blind domina en 2026</mark>: las buenas prácticas actuales —desactivar mensajes de error detallados, no reflejar datos crudos del usuario, devolver respuestas genéricas— eliminan justo los canales que usa la SQLi *in-band*. Lo que sobrevive es la inyección que solo altera el comportamiento (un login que dice "ok"/"error", un filtro que devuelve más o menos resultados). Detectar y explotar a ciegas es, por tanto, la habilidad que de verdad se usa hoy.

# Las dos categorías

- **Boolean-based** (también *content-based*): el atacante observa diferencias en la respuesta (longitud, un texto, el código HTTP) para deducir si la consulta inyectada devolvió `TRUE` o `FALSE`.
- **Time-based**: el atacante inyecta comandos de espera (`SLEEP`, `WAITFOR DELAY`) y mide el **tiempo de respuesta** para inferir el `TRUE`/`FALSE`.

> [!info]+
> <mark style="background: #FFB8EBA6;">Toda técnica time-based sirve también en un contexto boolean, pero no al revés</mark>. Si la página tiene una diferencia de contenido observable, boolean es preferible (más rápido y fiable); el tiempo es el recurso cuando no hay **ninguna** diferencia visible —por ejemplo, cuando la consulta vulnerable es un `INSERT`/`UPDATE` auxiliar que no afecta a lo que se renderiza—.

# El concepto de "oráculo"

La idea central de toda blind SQLi es convertir la aplicación en un **oráculo binario**: un mecanismo al que le hacemos una pregunta SÍ/NO sobre los datos y nos responde con uno de dos comportamientos distinguibles. Por ejemplo:

```sql
' AND (SELECT SUBSTRING(password,1,1) FROM users WHERE id=1)='a' --
```

Si la primera letra de la contraseña es `a`, la página responde de una forma (`TRUE`); si no, de otra (`FALSE`). <mark style="background: #FFB86CA6;">Repitiendo la pregunta carácter a carácter y bit a bit, se reconstruye cualquier dato</mark> —lento, pero completo—.

# Ejemplo: boolean-based en MSSQL

Código PHP vulnerable que no devuelve el resultado, solo "Email found" / "Email not found":

```php
$sql = "SELECT * FROM accounts WHERE email = '" . $_POST['email'] . "'";
$stmt = sqlsrv_query($conn, $sql);
$row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);
if ($row === null) { echo "Email not found"; } else { echo "Email found"; }
```

No hay errores ni datos reflejados, pero el cambio entre los dos mensajes es exactamente el oráculo que necesitamos. <mark style="background: #FF5582A6;">El origen es el mismo de siempre: entrada de usuario concatenada sin sanear</mark> en la consulta.

# La consecuencia práctica: automatización

Extraer una contraseña de 32 caracteres a ~8 peticiones por carácter son cientos de peticiones. Hacerlo a mano es inviable, así que la blind SQLi **se automatiza**: scripts a medida (Python con `requests`) o herramientas como [[SQLMap.base|SQLMap]] y `ghauri`. Aun así, escribir el *oráculo* a mano —saber qué consulta condicional enviar y cómo medir la respuesta— es imprescindible para los casos que las herramientas no resuelven y para evadir defensas.

Empezamos por el caso más rápido: detectar y confirmar una [[02 - Identificar SQLi basada en booleanos|inyección boolean-based]].
