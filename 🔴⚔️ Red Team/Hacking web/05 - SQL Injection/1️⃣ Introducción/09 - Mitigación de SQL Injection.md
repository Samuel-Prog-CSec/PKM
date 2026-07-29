---
tags:
  - Web/Red-Team
  - SQLi
  - Seguridad/Prevencion-Vulnerabilidad
  - Tipo/Defensa
Descripción: "Conocer las defensas no es solo cosa de desarrolladores: para un atacante, entender exactamente qué detiene una SQLi —y qué no— es lo que permite evadirlas"
Fecha de actualización: 2026-06-04
Nota previa: "[[08 - Escritura de archivos]]"
Nota siguiente:
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Conocer las defensas no es solo cosa de desarrolladores: para un atacante, entender exactamente qué detiene una SQLi —y qué no— es lo que permite [[05 - Bypass de caracteres comunes|evadirlas]]. Esta es la nota de referencia de mitigación para todo el tema; los módulos avanzados ([[01 - Introducción a Blind SQL Injection|Blind]], avanzado) remiten aquí y añaden solo matices propios. Las defensas se ordenan de la más efectiva a la complementaria.

# Consultas parametrizadas (prepared statements) — la defensa real

<mark style="background: #ADCCFFA6;">La solución correcta y definitiva es separar el código de los datos mediante consultas parametrizadas</mark>: la estructura de la query se define con marcadores (`?`) y los valores del usuario se envían aparte, sin poder alterar la sintaxis.

```php
$query = "SELECT * FROM logins WHERE username=? AND password=?";
$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, 'ss', $username, $password);
mysqli_stmt_execute($stmt);
```

El driver escapa y tipa los valores; una comilla inyectada se trata como el carácter literal `'`, no como delimitador. <mark style="background: #8000E1A6;">Bien aplicado, esto elimina la SQLi de raíz</mark>, no la mitiga: el dato nunca se interpreta como código.

> [!warning]+
> El punto ciego que un atacante explota: <mark style="background: #FF5582A6;">los prepared statements **no pueden parametrizar identificadores**</mark> —nombres de tabla/columna, `ORDER BY`, `LIMIT`, dirección de orden—. Esas partes se siguen construyendo concatenando, y son donde [[Consultas y operadores SQL|sobrevive la SQLi]] en aplicaciones modernas que, por lo demás, parametrizan todo. Los ORMs (Hibernate, Sequelize, Django ORM) parametrizan por defecto, pero exponen métodos de *raw query* y construcción dinámica de `ORDER BY` que reintroducen el fallo.

# Validación de entrada (allowlist)

Validar que la entrada coincide con lo esperado, rechazando todo lo demás. Es la defensa correcta justo donde los prepared statements no llegan (identificadores). Para un código de puerto que solo contiene letras y espacios:

```php
$pattern = "/^[A-Za-z\s]+$/";
if (!preg_match($pattern, $_GET["port_code"])) {
    die("Invalid input!");
}
```

<mark style="background: #FFB8EBA6;">La validación por allowlist (qué se permite) es muy superior a la blocklist (qué se prohíbe)</mark>: enumerar caracteres malos siempre deja huecos. Para `ORDER BY`, la práctica correcta es mapear la entrada a un conjunto fijo de columnas permitidas, nunca concatenarla.

# Saneamiento / escaping — último recurso

Funciones como `mysqli_real_escape_string()` (o `pg_escape_string()` en PostgreSQL) escapan `'` y `"` para que pierdan su significado especial.

```php
$username = mysqli_real_escape_string($conn, $_POST['username']);
```

> [!warning]+
> El escaping es la opción **más frágil** y no debe ser la defensa principal. <mark style="background: #FFB86CA6;">No protege en contexto numérico</mark> (sin comillas que escapar, `id=1 OR 1=1` pasa intacto), depende del *charset* correcto (ataques de *multibyte encoding* como GBK lo han burlado históricamente), y es fácil olvidarlo en un punto. Úsalo solo como capa adicional, nunca en lugar de consultas parametrizadas.

# Privilegio mínimo — defensa en profundidad

La cuenta que usa la aplicación debe tener **solo** los permisos que necesita. Nunca un superusuario o DBA:

```sql
CREATE USER 'reader'@'localhost' IDENTIFIED BY 'p@ssw0Rd!!';
GRANT SELECT ON ilfreight.ports TO 'reader'@'localhost';
```

Así, aunque exista una SQLi, el atacante no podrá leer otras tablas (`SELECT command denied`), ni [[07 - Lectura de archivos|leer]]/[[08 - Escritura de archivos|escribir ficheros]] (sin privilegio `FILE`), ni tocar `INFORMATION_SCHEMA` completo. <mark style="background: #8000E1A6;">No previene la inyección, pero reduce drásticamente su impacto</mark> —convierte un compromiso total en una fuga acotada—.

# WAF — capa perimetral, no solución

Un Web Application Firewall (ModSecurity con OWASP CRS, Cloudflare, AWS WAF) inspecciona las peticiones y rechaza las que contienen patrones maliciosos —por ejemplo, cualquier petición con `INFORMATION_SCHEMA` o `UNION SELECT`—.

> [!important]+
> El WAF es **defensa en profundidad, no un parche**: protege ante fallos de la lógica de la aplicación, pero <mark style="background: #FF5582A6;">se evade con regularidad</mark> mediante codificación, comentarios en línea, mayúsculas mixtas, *whitespace* alternativo y funciones equivalentes —el repertorio completo está en [[05 - Bypass de caracteres comunes|evasión de filtros y WAF]]—. Confiar solo en el WAF es una invitación: arregla el código.

> [!info]+
> Otras medidas: **stored procedures** (con parametrización interna, no concatenando), desactivar mensajes de error detallados en producción (evita las inyecciones [[06 - SQL Injection basada en errores|error-based]] y filtra menos información), y monitorización/alertado de patrones anómalos de consulta. La defensa efectiva es **en capas**: parametrizar + validar + privilegio mínimo + WAF + ocultar errores.

Con los fundamentos y la explotación clásica de MySQL cubiertos, el siguiente paso del path es automatizar el proceso con [[SQLMap.base|SQLMap]] y, después, atacar los escenarios donde no hay salida visible: [[01 - Introducción a Blind SQL Injection|Blind SQL Injection]].
