---
tags:
  - Bases-de-Datos
  - SQL
  - Tipo/Introduccion
Descripción: "Toda aplicación web con estado —autenticación, catálogos, mensajería, paneles de administración— delega el almacenamiento en una base de datos"
Fecha de actualización: 2026-06-04
Nota previa:
Nota siguiente: "[[🐬 MySQL]]"
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

Toda aplicación web con estado —autenticación, catálogos, mensajería, paneles de administración— delega el almacenamiento en una base de datos. Entender cómo se organiza y cómo se consulta ese almacén es el prerrequisito para atacarlo: <mark style="background: #ADCCFFA6;">una base de datos es una colección estructurada de información organizada para facilitar su almacenamiento, recuperación y modificación</mark>. Antes de enviar una sola comilla a un parámetro, conviene tener un modelo mental claro del motor que hay detrás, porque la sintaxis del ataque depende por completo de él.

# Sistemas de gestión de bases de datos (DBMS)

Las primeras aplicaciones guardaban datos en ficheros planos, un enfoque que se degrada con rapidez al crecer el volumen y, sobre todo, la concurrencia. De ahí el salto a los DBMS. <mark style="background: #ADCCFFA6;">Un *Database Management System* (DBMS) es el software que crea, define, aloja y gestiona bases de datos</mark>, actuando como capa intermedia entre la aplicación y los datos en disco. La aplicación nunca toca el fichero de datos directamente: pide al DBMS, y este responde.

Existen varias familias de DBMS según el modelo de datos: file-based, relacionales (`RDBMS`), `NoSQL`, orientados a grafos y almacenes clave/valor. Se interactúan por línea de comandos, interfaces gráficas o `APIs`. Más allá de almacenar, un DBMS aporta garantías que un sistema de ficheros no ofrece:

| Característica | Qué garantiza |
| -------------- | ------------- |
| Concurrencia   | Múltiples usuarios operan a la vez sin corromper ni perder datos. |
| Consistencia   | Los datos permanecen válidos y coherentes pese a esas operaciones simultáneas. |
| Seguridad      | Control de acceso fino mediante autenticación y permisos por usuario. |
| Fiabilidad     | Copias de seguridad y restauración a un estado previo ante pérdida o brecha. |
| SQL            | Un lenguaje de consulta estándar e intuitivo para todas las operaciones. |

> [!important]+
> El control de acceso por usuario y permisos es precisamente lo que una `SQL injection` bien ejecutada busca subvertir: si la aplicación se conecta al DBMS con una cuenta sobreprivilegiada (algo demasiado común en producción), el atacante hereda esos privilegios y la "seguridad fina" del DBMS deja de protegerle.

# Arquitectura: dónde encaja la inyección

Una aplicación con base de datos se despliega en capas. <mark style="background: #ADCCFFA6;">La capa cliente (Tier I) son las interfaces de alto nivel —la web, una app de escritorio— donde el usuario inicia acciones como iniciar sesión o comentar</mark>. Esa entrada viaja a la capa de aplicación o *middleware* (Tier II), que la interpreta, la traduce a consultas y, mediante librerías y drivers específicos del motor, habla con el DBMS (Tier III). El DBMS ejecuta la operación —inserción, lectura, borrado, actualización— y devuelve datos o códigos de error.

![Diagrama de arquitectura en capas: el cliente (Tier I) habla con un servidor de aplicación (Tier II), que a su vez consulta el DBMS (Tier III).](https://academy.hackthebox.com/storage/modules/33/db_2.png)

> [!warning]+
> El material original etiqueta este diagrama como arquitectura de *dos* capas, pero describe *tres* (cliente, aplicación y datos). La confusión es habitual: lo relevante es que entre la entrada del usuario y la ejecución de la consulta hay una capa de aplicación que **construye la query**. <mark style="background: #FF5582A6;">Ese punto de construcción —donde el dato del usuario se concatena en una sentencia SQL— es exactamente donde nace la inyección</mark>.

El servidor de aplicación y el DBMS pueden compartir host, pero en sistemas con muchos datos y usuarios suelen separarse para mejorar rendimiento y escalabilidad. Esa separación tiene consecuencias ofensivas: un SQLi que logra ejecución de comandos lo hace en el host del DBMS, que puede ser una máquina interna distinta del servidor web —un pivote hacia la red interna.

# Bases de datos relacionales vs no-relacionales

A grandes rasgos, las bases de datos se dividen en relacionales y no-relacionales. <mark style="background: #FFB8EBA6;">Solo las relacionales utilizan SQL; las no-relacionales emplean métodos de comunicación propios</mark>. Esta distinción no es académica: determina por completo la técnica de explotación.

## Relacionales (RDBMS)

Es el tipo más común. <mark style="background: #ADCCFFA6;">Una base de datos relacional organiza los datos en tablas (filas y columnas) gobernadas por un *schema*, la plantilla que define la estructura</mark>. Las tablas —también llamadas entidades— se vinculan entre sí mediante claves (`keys`). Una `PRIMARY KEY` identifica unívocamente cada fila; una `FOREIGN KEY` referencia la clave de otra tabla, creando la relación.

El ejemplo canónico: una tabla `users` y una tabla `posts`.

| users | | | posts | |
|---|---|---|---|---|
| **id** | username | | **id** | user_id |
| 1 | admin | | 1 | 1 |
| 2 | jose | | 2 | 1 |

El campo `user_id` de `posts` apunta al `id` de `users`. Así, con una sola consulta se recuperan todos los datos de un usuario y sus publicaciones sin duplicar información. <mark style="background: #8000E1A6;">El *schema* define la estructura completa de la base de datos: tablas, columnas, tipos de dato, restricciones y las relaciones entre tablas</mark>, y es lo que hace a las bases relacionales rápidas y fiables sobre datos bien estructurados. El gestor que implementa este modelo es un `RDBMS`: MySQL, MariaDB, PostgreSQL, Microsoft SQL Server (MSSQL) y Oracle son los más extendidos.

## No-relacionales (NoSQL)

Una base de datos no-relacional (o `NoSQL`) prescinde de tablas, filas, columnas, claves y schema fijo. Almacena los datos con modelos flexibles según su naturaleza, lo que la hace muy escalable y adecuada para datos poco estructurados. Hay cuatro modelos comunes: clave-valor (`Key-Value`), documental (`Document-Based`), columna ancha (`Wide-Column`) y grafo (`Graph`). El modelo clave-valor, por ejemplo, suele almacenar en JSON:

```json
{
  "100001": { "date": "01-01-2021", "content": "Welcome to this web application." },
  "100002": { "date": "02-01-2021", "content": "This is the first post on this web app." }
}
```

Recuerda a un diccionario de Python o PHP (`{'clave': 'valor'}`). El ejemplo más conocido es MongoDB.

> [!info]+
> Las bases NoSQL tienen su propia familia de ataques, las `NoSQL injection`, **completamente distintas** de las SQLi clásicas: no se inyecta sintaxis SQL sino operadores del motor (p. ej. `$ne`, `$gt` en MongoDB) o JavaScript del lado servidor. Se tratan en [[NoSQL Injection|su propio tema]].

# Por qué esto importa para SQL injection

La superficie de ataque de un SQLi es el lenguaje SQL en sí: cuando la entrada del usuario se concatena sin saneamiento en una consulta, el atacante puede alterar la lógica de esa consulta. Pero <mark style="background: #8000E1A6;">cada RDBMS implementa su propio *dialecto* de SQL</mark> —funciones, concatenación de cadenas, comentarios, metadatos del sistema y operaciones de fichero difieren entre motores—. <mark style="background: #FF5582A6;">Por eso el primer paso de toda explotación es identificar el DBMS concreto (*fingerprinting*)</mark>: un payload que funciona en MySQL falla en MSSQL.

> [!important]+
> El path de SQL injection recorre justo los tres motores relacionales más habituales, cada uno con su dialecto:
> - **MySQL / MariaDB** — fundamentos y explotación clásica (este módulo). Ver [[🐬 MySQL]].
> - **MSSQL (SQL Server)** — inyección a ciegas y abuso de funciones del sistema.
> - **PostgreSQL** — técnicas avanzadas, lectura/escritura de ficheros y ejecución de comandos.
>
> Dominar el dialecto de cada uno es lo que separa reproducir un payload de laboratorio de explotar un objetivo real.

El siguiente paso es manejar con soltura el lenguaje sobre el motor de referencia del módulo, [[🐬 MySQL]], y sus [[💬 Sentencias SQL|sentencias SQL]] fundamentales, porque un atacante necesita escribir las mismas consultas que escribiría un desarrollador —solo que desde el lado equivocado del parámetro.
