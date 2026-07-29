---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "La SQLi boolean-based se identifica en dos pasos: encontrar el punto de inyección y confirmar que la respuesta cambia de forma binaria según la lógica inyectada"
Fecha de actualización: 2026-06-04
Nota previa: "[[01 - Introducción a Blind SQL Injection]]"
Nota siguiente: "[[03 - Diseño del oráculo booleano]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

La SQLi `boolean-based` se identifica en dos pasos: encontrar el punto de inyección y confirmar que la respuesta cambia de forma binaria según la lógica inyectada. El escenario que sigue —una tienda con un registro de usuarios— ilustra dónde aparece hoy la SQLi: <mark style="background: #FF5582A6;">no en un formulario que muestra resultados, sino en un endpoint de API JSON consumido por JavaScript</mark>.

# El punto de inyección moderno: validación asíncrona

La página de registro comprueba en tiempo real si un nombre de usuario está disponible. Al perder el foco del campo, un script lanza:

```javascript
xhr.open("GET", "/api/check-username.php?u=" + usernameInput.value, true);
// respuesta: {"status":"available"}  ó  {"status":"taken"}
```

<mark style="background: #ADCCFFA6;">Este patrón —validación de username/email vía API que consulta la base de datos— es ubicuo en aplicaciones modernas y un punto de inyección que se pasa por alto</mark>: no es el campo de login obvio, sino un endpoint auxiliar que igualmente concatena la entrada en una consulta. Revisar el JavaScript del frontend para descubrir estos endpoints es parte de la [[01 - Detección de SQL Injection|metodología de detección]].

# Paso 1: provocar el error

Probando nombres reales (`admin`, `maria`) la API responde `status: taken`. La señal de inyección aparece al enviar una comilla simple como nombre:

```http
GET /api/check-username.php?u=' HTTP/1.1
```

```text
HTTP/1.1 500 Internal Server Error
```

<mark style="background: #FFB86CA6;">El error 500 ante una sola comilla es el indicio clásico</mark>: la comilla rompe la consulta, que probablemente es:

```sql
SELECT Username FROM Users WHERE Username = '<u>'
```

# Paso 2: confirmar el comportamiento binario

El error confirma que hay inyección, pero para explotarla a ciegas necesitamos un **oráculo**: una forma de hacer que la respuesta distinga `TRUE` de `FALSE`. Inyectando una condición siempre verdadera:

```text
u=' or '1'='1
→ {"status":"taken"}
```

La consulta devuelve filas, así que el servidor cree que el nombre está "taken". <mark style="background: #8000E1A6;">Aquí está la clave de la blind boolean: solo obtenemos dos respuestas posibles (`taken`/`available`), así que toda la extracción se hará mediante preguntas de SÍ/NO</mark>.

> [!warning]+
> En MSSQL el comentario es `--` (no `#`). Y ojo con el contexto: aquí la inyección va en un parámetro `GET` dentro de comillas simples, así que el cierre es `'`. Si fuera numérico o con paréntesis, habría que ajustar el [[01 - Detección de SQL Injection|contexto]] como en cualquier SQLi.

> [!info]+
> **Detección sin error visible**: muchas apps modernas ocultan el 500 y devuelven una respuesta genérica. En ese caso, se confirma directamente con el diferencial booleano: `' AND '1'='1` (debe dar `taken`) frente a `' AND '1'='2` (debe dar `available`). Si ambas difieren de forma consistente, hay inyección aunque no haya error. Cuando ni eso funciona, se pasa a [[06 - Identificar SQLi basada en tiempo|time-based]].

# El oráculo, conceptualmente

Para preguntar cualquier cosa a la base de datos, se ancla la inyección a un usuario que **existe** (`maria`) y se añade la condición a evaluar:

```sql
SELECT Username FROM Users WHERE Username = 'maria' AND <condición>-- -
```

Si la condición es verdadera, sigue devolviendo la fila de `maria` (`taken`); si es falsa, no devuelve nada (`available`). <mark style="background: #FFB8EBA6;">Es imprescindible usar un usuario existente</mark>: con uno inexistente, la respuesta sería siempre `available` y el oráculo no distinguiría nada.

El siguiente paso es convertir este oráculo manual en un script reutilizable: [[03 - Diseño del oráculo booleano]].
