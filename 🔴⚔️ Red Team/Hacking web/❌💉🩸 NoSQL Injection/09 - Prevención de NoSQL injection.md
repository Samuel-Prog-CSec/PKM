---
tags:
  - Web/Red-Team
  - NoSQLi
Fecha de actualización: 2026-07-16
Nota previa: "[[08 - Arsenal de herramientas para NoSQL]]"
Nota siguiente: ""
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

A diferencia de SQL, <mark style="background: #FFB8EBA6;">MongoDB no tiene consultas parametrizadas</mark> como defensa universal, así que la prevención es distinta. La raíz del bug es la **confusión de tipos** (un string que se convierte en un objeto/operador), y de ahí salen las dos defensas.

# Casting de tipo + validación (la defensa principal)

<mark style="background: #ADCCFFA6;">MongoDB es *strongly-typed*: si le pasas un string, lo trata como string</mark>. Forzar el tipo esperado neutraliza la inyección de operadores — un `email[$ne]=x` se convierte en la cadena literal `"Array"` y no casa nada:

```php
// Vulnerable: la entrada llega cruda al filtro
$query = new MongoDB\Driver\Query(array("email" => $_POST['email'], "password" => $_POST['password']));

// Corregido: castear a string
$query = new MongoDB\Driver\Query(array("email" => strval($_POST['email']), "password" => strval($_POST['password'])));
```

Además del casting, **validar el formato** cierra errores futuros: `filter_var($email, FILTER_VALIDATE_EMAIL)` para emails, o una regex para formatos conocidos (`preg_match('/^[a-z0-9\{\}]+$/i', $trackingNum)`).

# Reescritura de consultas (para SSJI)

El casting **no** arregla la [[06 - Server-Side JavaScript Injection|SSJI]], porque ahí no se inyecta un array sino código en un `$where`. La solución es <mark style="background: #8000E1A6;">reescribir la consulta para que no evalúe JavaScript</mark>, usando operadores normales:

```php
// Vulnerable: $where con JS concatenado
$q = array('$where' => 'this.username === "' . $_POST['username'] . '" && this.password === "' . md5($_POST['password']) . '"');

// Corregido: operadores normales, sin JS
$q = array('username' => strval($_POST['username']), 'password' => md5($_POST['password']));
```

MongoDB recomienda <mark style="background: #FF5582A6;">usar `$where` solo si es imposible expresar la consulta de otra forma</mark>, y **deshabilitar la evaluación de JavaScript server-side** (activada por defecto) si el proyecto no la usa.

> [!info]+ Modernización: el ecosistema Node.js/Express
> HTB solo muestra PHP, pero la mayoría de NoSQLi vive hoy en Node. Ahí las defensas de referencia son: <mark style="background: #ADCCFFA6;">`express-mongo-sanitize`</mark> (middleware que elimina claves con `$` y `.` del input), **Mongoose con schemas tipados** (`username: String` rechaza objetos automáticamente por *casting*), y validadores como `joi` o `express-validator`. Regla de oro: **nunca pasar `req.body` crudo a un `find()`**.

> [!important]+ Resumen de prevención
> No hay parametrización universal, así que: <mark style="background: #FF5582A6;">(1) nunca usar entrada cruda — allowlist + casting de tipo</mark>; (2) validar formato; (3) evitar `$where`/JS y reescribir con operadores; (4) mínimo privilegio en el usuario de la BD. La misma filosofía en espejo que la [[10 - Prevención de SQL Injection|prevención de SQLi]] y la [[08 - Prevención de XPath Injection|de XPath]].
