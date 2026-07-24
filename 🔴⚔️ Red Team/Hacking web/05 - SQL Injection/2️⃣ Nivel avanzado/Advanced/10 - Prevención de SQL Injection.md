---
tags:
  - Web/Red-Team
  - SQLi
  - Seguridad/Prevencion-Vulnerabilidad
Fecha de actualización: 2026-06-04
Nota previa: "[[09 - PostgreSQL ejecución de comandos]]"
Nota siguiente: "[[11 - Inyección en ORMs]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

`BlueBird` acumulaba varias SQLi: una protegida por un [[05 - Bypass de caracteres comunes|filtro burlado]], una [[06 - SQL Injection basada en errores|error-based]] y una de [[07 - SQL Injection de segundo orden|segundo orden]]. Todas tienen la misma raíz —concatenar entrada en la consulta— y la misma cura. Esta nota cierra el path; la referencia maestra de defensa es [[09 - Mitigación de SQL Injection|Mitigación de SQL Injection]], y aquí se añade lo específico de PostgreSQL.

# La cura: consultas parametrizadas

<mark style="background: #ADCCFFA6;">La defensa definitiva sigue siendo parametrizar</mark>. El arreglo del SQLi de `/find-user`, con `JdbcTemplate`, mantiene el `LIKE` usando `CONCAT` y un placeholder:

```java
// Vulnerable
String sql = "SELECT * FROM users WHERE username LIKE '%" + u + "%'";
jdbcTemplate.query(sql, new BeanPropertyRowMapper(User.class));

// Seguro
String sql = "SELECT * FROM users WHERE username LIKE CONCAT('%', ?, '%')";
jdbcTemplate.query(sql, new Object[]{u}, new BeanPropertyRowMapper(User.class));
```

Tras el cambio, el payload `'/**/and/**/1=1--` deja de funcionar. <mark style="background: #8000E1A6;">El mismo principio aplica a las tres vulnerabilidades</mark>, incluida la de [[07 - SQL Injection de segundo orden|segundo orden]]: hay que parametrizar **también** al releer datos de la propia base de datos, nunca solo en la entrada directa.

# Privilegio mínimo en PostgreSQL

`BlueBird` se conectaba como **superusuario**, lo que habilitaba la [[08 - PostgreSQL lectura y escritura de archivos|lectura/escritura de ficheros]] y la [[09 - PostgreSQL ejecución de comandos|ejecución de comandos]]. <mark style="background: #FF5582A6;">El privilegio mínimo no previene la inyección, pero anula su escalada a RCE</mark>:

| Capacidad peligrosa | Privilegio que la habilita | Si no se necesita… |
| ------------------- | -------------------------- | ------------------ |
| Leer/escribir ficheros (`COPY`) | superuser, `pg_read/write_server_files` | no concederlo |
| Ejecutar programas (`COPY FROM PROGRAM`) | superuser, `pg_execute_server_program` | no concederlo |
| Cargar extensiones / funciones `LANGUAGE C` | solo `superuser` (`CREATE` en `public` **no** lo habilita) | no dar el rol `superuser` a la cuenta de la app |
| Large objects (import/export) | superuser, permisos explícitos | no conceder |

> [!important]+
> La cuenta de la aplicación casi nunca necesita leer ficheros, ejecutar programas ni crear extensiones. <mark style="background: #FFB86CA6;">Dale solo `SELECT`/`INSERT`/`UPDATE`/`DELETE` sobre las tablas concretas que usa</mark>, y revoca todo lo demás. Cada privilegio "por si acaso" es un vector de RCE esperando una inyección.

> [!info]+
> Defensa en profundidad, como en la [[14 - Defensa contra Blind SQL Injection|defensa de Blind]] y la [[09 - Mitigación de SQL Injection|mitigación general]]: validación de entrada por allowlist, desactivar mensajes de error en producción (cierra el [[06 - SQL Injection basada en errores|error-based]] y el filtrado de stacktraces vía [[06 - SQL Injection basada en errores|`X-Forwarded-For`]]), un [[05 - Bypass de protecciones web con SQLMap|WAF]] como capa, y SAST en el pipeline ([[02 - Búsqueda de strings en el código|semgrep/CodeQL]]) para detectar concatenación de SQL antes de desplegar.

> [!important]+
> El cierre conceptual del path completo: <mark style="background: #8000E1A6;">SQLi nace siempre de mezclar código y datos; parametrizar los separa y la elimina</mark>. Todo lo demás —privilegio mínimo, WAF, ocultar errores— reduce el impacto cuando algo se escapa, pero no sustituye la parametrización. En 2026, la SQLi que el pentester encuentra vive justo en los huecos donde no se parametrizó: [[Consultas y operadores SQL|identificadores como `ORDER BY`]], [[07 - SQL Injection de segundo orden|datos releídos de la BD]] y APIs con entrada por rutas inesperadas.

Con esto se completa el recorrido clásico de SQL injection, desde los [[00 - Introducción a SQL Injection|fundamentos]] hasta la explotación avanzada en tres motores. La habilidad que perdura es la del principio: encontrar la inyección donde sobrevive y superar las defensas reales.

Y la defensa más extendida hoy —el `ORM`, que parametriza por defecto— tiene sus propios huecos donde la inyección reaparece pese a "estar protegidos": [[11 - Inyección en ORMs]].
