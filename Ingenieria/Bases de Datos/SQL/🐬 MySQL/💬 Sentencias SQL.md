---
tags:
  - Bases-de-Datos
  - SQL
Descripción: "Sobre la estructura ya creada en 🐬 MySQL, las sentencias de manipulación (DML) y definición (DDL) son las operaciones reales que la aplicación —y, por extensión, el atacante—…"
Fecha de actualización: 2026-06-04
Nota previa: "[[🐬 MySQL]]"
Nota siguiente: "[[Consultas y operadores SQL]]"
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

Sobre la estructura ya creada en [[🐬 MySQL]], las sentencias de manipulación (`DML`) y definición (`DDL`) son las operaciones reales que la aplicación —y, por extensión, el atacante— ejecuta contra los datos. <mark style="background: #ADCCFFA6;">`SELECT` es la sentencia central de la SQL injection clásica</mark>, porque la inmensa mayoría de consultas vulnerables que devuelven contenido al usuario (logins, búsquedas, listados) son `SELECT`. El resto —`INSERT`, `UPDATE`, `DROP`, `ALTER`— gana relevancia en escenarios concretos como las *stacked queries* y la inyección de [[07 - SQL Injection de segundo orden|segundo orden]].

# `INSERT` — añadir registros

Inserta nuevos registros en una tabla. La forma básica exige un valor por cada columna:

```sql
INSERT INTO table_name VALUES (valor1, valor2, valor3, ...);
```

Se pueden insertar valores solo en columnas concretas (dejando que las demás tomen su valor por defecto) nombrándolas, e insertar varios registros separándolos por comas:

```sql
INSERT INTO logins(username, password) VALUES ('john', 'john123!'), ('tom', 'tom123!');
```

> [!warning]+
> Omitir una columna con restricción `NOT NULL` provoca error: es un campo obligatorio. Este detalle reaparece al explotar formularios de registro vulnerables, donde un `INSERT` mal saneado permite inyectar pero las restricciones de la tabla limitan qué se puede escribir.

> [!info]+
> Los ejemplos guardan contraseñas en claro **solo para demostración**. En producción deben ir siempre con hash + salt (bcrypt, Argon2). <mark style="background: #FFB86CA6;">Una tabla `logins` con contraseñas en texto plano es exactamente el botín que un SQLi `UNION`-based busca exfiltrar</mark>.

Desde el lado ofensivo, una inyección dentro de un `INSERT` (típico en registros o formularios de contacto) permite **escribir** datos arbitrarios. Si esos datos se almacenan y luego se usan sin sanear en otra consulta, nace una inyección de [[07 - SQL Injection de segundo orden|segundo orden]].

# `SELECT` — recuperar datos

Lee datos de una o varias tablas. El asterisco (`*`) es comodín y selecciona todas las columnas; `FROM` indica la tabla:

```sql
SELECT * FROM logins;
SELECT username, password FROM logins;
```

```shell-session
mysql> SELECT username,password FROM logins;
+---------------+------------+
| username      | password   |
+---------------+------------+
| admin         | p@ssw0rd   |
| administrator | adm1n_p@ss |
+---------------+------------+
```

<mark style="background: #8000E1A6;">Saber qué columnas y en qué orden devuelve un `SELECT` es la base de la [[05 - Inyección UNION|inyección UNION]]</mark>: para "colgar" un segundo `SELECT` del original hay que igualar el número y tipo de columnas. De ahí que `SELECT` y sus cláusulas de filtrado sean el material que más se manipula en un ataque.

# `UPDATE` — modificar registros

Actualiza registros existentes según una condición `WHERE`:

```sql
UPDATE table_name SET columna1=valor1, columna2=valor2 WHERE <condición>;
```

```shell-session
mysql> UPDATE logins SET password = 'change_password' WHERE id > 1;
```

> [!warning]+
> <mark style="background: #FF5582A6;">`UPDATE` **no exige** `WHERE` sintácticamente: sin él modifica **todos** los registros de la tabla</mark>. Por eso un `WHERE` controlado por el atacante —o eliminado vía inyección— convierte un cambio puntual en una modificación masiva: resetear todas las contraseñas, o elevar el rol de la propia cuenta. (`sql_safe_updates` puede forzar la condición, pero no está activo por defecto.) La cláusula `WHERE` se detalla en [[Consultas y operadores SQL]].

# `DROP` y `ALTER` — estructura de la tabla

`DROP` elimina tablas o bases de datos **de forma permanente y sin confirmación**. `ALTER` modifica la estructura: añadir, renombrar, cambiar el tipo o eliminar columnas.

| Sentencia | Acción |
| --------- | ------ |
| `DROP TABLE logins;` | Elimina la tabla por completo. |
| `ALTER TABLE logins ADD nueva INT;` | Añade una columna. |
| `ALTER TABLE logins RENAME COLUMN nueva TO otra;` | Renombra una columna. |
| `ALTER TABLE logins MODIFY otra DATE;` | Cambia el tipo de dato. |
| `ALTER TABLE logins DROP otra;` | Elimina una columna. |

> [!warning]+
> `DROP` borra sin pedir confirmación. En un *engagement* real **nunca** se lanza un `DROP` (ni un `UPDATE`/`DELETE` no acotado) contra producción: rompe la regla de oro de demostrar el fallo sin causar daño. Para evidenciar capacidad de escritura basta una operación reversible e inocua.

Todas estas sentencias requieren **privilegios suficientes** en la cuenta que las ejecuta. Por eso, durante la explotación, enumerar los privilegios de la cuenta de la base de datos (`SHOW GRANTS`) determina hasta dónde se puede llegar: de solo leer, a escribir ficheros o ejecutar comandos.

El verdadero poder para un atacante está en **filtrar y combinar** resultados: las cláusulas `WHERE`, `ORDER BY`, `LIMIT`, `LIKE` y los operadores lógicos —todo ello en [[Consultas y operadores SQL]]— son las piezas que se manipulan para [[02 - Subvertir la lógica de consulta|subvertir la lógica]] de una consulta.
