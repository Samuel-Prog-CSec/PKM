---
tags:
  - Web/Red-Team
  - SQLi
  - Introduccion
  - Tipo/Introduccion
Descripción: "La SQL injection (SQLi) es la explotación de una consulta SQL que mezcla, sin separar, código y datos"
Fecha de actualización: 2026-06-04
Nota previa:
Nota siguiente: "[[01 - Detección de SQL Injection]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La `SQL injection` (SQLi) es la explotación de una consulta SQL que mezcla, sin separar, código y datos. Pese a ser una de las vulnerabilidades más antiguas y documentadas, sigue apareciendo —cada vez en sitios menos obvios— y su impacto va desde el volcado completo de la base de datos hasta la ejecución de comandos en el servidor. Dominar SQLi exige primero entender cómo una aplicación web habla con su base de datos; los [[Consultas y operadores SQL|fundamentos de SQL]] son el prerrequisito.

# Cómo las aplicaciones web usan SQL

Tras instalar un DBMS, la aplicación lo usa para almacenar y recuperar datos. En PHP, por ejemplo, se conecta y lanza consultas con `mysqli`:

```php
$conn = new mysqli("localhost", "root", "password", "users");
$query = "SELECT * FROM logins";
$result = $conn->query($query);
```

El problema nace cuando la consulta incorpora **entrada del usuario**. Un buscador de usuarios típico construye la query concatenando lo que el usuario escribe:

```php
$searchInput = $_POST['findUser'];
$query = "SELECT * FROM logins WHERE username LIKE '%$searchInput'";
$result = $conn->query($query);
```

<mark style="background: #FF5582A6;">Esa concatenación directa, sin sanear, es el patrón vulnerable</mark>. El dato del usuario pasa a formar parte del texto de la consulta, y el motor no distingue dónde acaba el dato y empieza el código.

# Qué es una inyección

<mark style="background: #ADCCFFA6;">Una inyección ocurre cuando una aplicación interpreta la entrada del usuario como código en lugar de como una simple cadena</mark>, alterando el flujo del programa y ejecutándolo. En SQLi, se logra escapando los límites del dato con un carácter especial —típicamente la comilla simple (`'`)— y escribiendo SQL a continuación. El mismo principio gobierna otras inyecciones sobre lenguajes de consulta, como la [[00 - Introducción a XPath Injection|Inyección XPath]] sobre documentos XML. Si la entrada no se **sanea** (eliminar o neutralizar los caracteres especiales que rompen la consulta), el código inyectado se ejecuta.

# Anatomía de un SQL injection

En la query del buscador, todo lo que escribimos va dentro de `'%...'`. Si introducimos `admin`, queda `'%admin'` y se trata como término de búsqueda. Pero al introducir una comilla simple cerramos el literal y lo que sigue se interpreta como SQL. Con la entrada `1'; DROP TABLE users;` la consulta resultante sería:

```sql
SELECT * FROM logins WHERE username LIKE '%1'; DROP TABLE users;'
```

La comilla rompe el `LIKE`, y `DROP TABLE users` se ejecuta como sentencia propia. <mark style="background: #FFB86CA6;">La comilla sobrante final deja la consulta mal formada y provoca un error de sintaxis</mark> (`syntax error near "'"`), que en sí mismo es la primera señal de que hay inyección. Para que el ataque funcione, la query modificada debe quedar **sintácticamente válida**: como rara vez tenemos el código fuente, se recurre a [[03 - Uso de comentarios|comentarios]] o a equilibrar las comillas.

> [!warning]+
> El ejemplo del `DROP` apilado tras `;` **no funciona en MySQL** con la API estándar (`mysqli->query()` ejecuta una sola sentencia), pero **sí en MSSQL y PostgreSQL**, que permiten *stacked queries*. Es un matiz crítico de `fingerprinting`: la técnica de explotación depende del motor. En MySQL las inyecciones reales se apoyan en `UNION`, subconsultas y condiciones, no en apilar sentencias.

# Tipos de SQL injection

Las SQLi se clasifican según **cómo y dónde** se recupera su salida:

![Matriz de tipos de SQL injection: In-band (Union-based, Error-based), Blind (Boolean-based, Time-based) y Out-of-band.](https://academy.hackthebox.com/storage/modules/33/types_of_sqli.jpg)

- **In-band**: la salida aparece en la misma respuesta. Dos variantes: <mark style="background: #ADCCFFA6;">`Union Based`</mark> (se usa `UNION` para dirigir el resultado a columnas visibles) y `Error Based` (se provoca un error que filtra datos en el mensaje).
- **Blind**: no hay salida directa; se infiere dato a dato. `Boolean Based` (una condición decide si la página responde de una u otra forma) y `Time Based` (una condición introduce un retardo con `SLEEP()`).
- **Out-of-band (OOB)**: sin acceso a la salida, se exfiltra hacia un canal externo (p. ej. una petición DNS controlada por el atacante).

> [!info]+
> Cada tipo se trabaja en su módulo del path: la **`Union Based`** en este; la **`Boolean`/`Time Based`** y la **OOB** en [[01 - Introducción a Blind SQL Injection|Blind SQL Injection]]; la **`Error Based`** y la de [[07 - SQL Injection de segundo orden|segundo orden]] en SQLi avanzado.

# Dónde sobrevive SQLi hoy

<mark style="background: #FFB8EBA6;">El uso generalizado de `prepared statements` y ORMs ha reducido drásticamente la SQLi clásica</mark>, pero <mark style="background: #FF5582A6;">no la ha erradicado</mark>. Sigue apareciendo en:

- **Cláusulas no parametrizables** (`ORDER BY`, `LIMIT`, nombres de tabla/columna), que los ORMs construyen concatenando.
- **APIs y cuerpos JSON**, donde la entrada llega por rutas que escapan a la validación del formulario clásico.
- **Cabeceras y cookies** reflejadas en consultas de logging o analítica.
- **Inyección de [[07 - SQL Injection de segundo orden|segundo orden]]**, donde el dato malicioso se almacena y detona en una consulta posterior.

El impacto justifica el esfuerzo: <mark style="background: #FFB86CA6;">lectura y modificación de datos arbitrarios, bypass de autenticación, y —según privilegios— lectura/escritura de ficheros y ejecución de comandos en el host del DBMS</mark>. El siguiente paso es saber **detectarla** de forma metódica: [[01 - Detección de SQL Injection]].

> [!info]+ Variante moderna — `text-to-SQL`
> Cuando un LLM traduce lenguaje natural a SQL, el atacante no controla un valor dentro de la consulta: controla **la consulta entera**. Las sentencias preparadas dejan de aplicar, porque no hay plan fijo del que separar los datos. Ver [[02 - SQL injection a través del LLM]].
