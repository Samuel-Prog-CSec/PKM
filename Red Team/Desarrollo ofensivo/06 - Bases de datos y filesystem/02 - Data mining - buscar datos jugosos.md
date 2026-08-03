---
tags:
  - Go
  - Go/Datos
  - Pentesting/Post-Explotacion
Descripción: "Ya sabes conectarte a SQL (00 - Bases de datos SQL - database-sql) y MongoDB (01 - MongoDB con el driver oficial)"
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - MongoDB con el driver oficial]]"
Nota siguiente: "[[03 - Pillaging del sistema de ficheros]]"
Area: "[[Bases de datos y filesystem.base|Bases de datos y filesystem]]"
---
---

Ya sabes conectarte a SQL ([[00 - Bases de datos SQL - database-sql]]) y MongoDB ([[01 - MongoDB con el driver oficial]]). El tool que de verdad importa en post-explotación busca **automáticamente** los datos jugosos —tarjetas, contraseñas, hashes, PII— en cualquier base a la que llegues. La clave no es la consulta, sino el **diseño**: una interfaz común que hace que una sola función de búsqueda sirva para MongoDB, MySQL o lo que venga.

## La interfaz: una función para todas las BBDD

Cada motor extrae su esquema de forma distinta, pero una vez tienes "qué bases, qué tablas, qué columnas", la búsqueda es idéntica. Eso se modela con una **interfaz** (nota [[10 - Interfaces]]):

```go
type DatabaseMiner interface {
    GetSchema() (*Schema, error)   // cada BBDD lo implementa a su manera
}

type Schema   struct{ Databases []Database }
type Database struct{ Name string; Tables []Table }
type Table    struct{ Name string; Columns []string }
```

La función de búsqueda **acepta la interfaz**, no un tipo concreto:

```go
func Search(m DatabaseMiner) error {
    schema, err := m.GetSchema()      // llama a la implementación del tipo real
    if err != nil {
        return err
    }
    for _, db := range schema.Databases {
        for _, t := range db.Tables {
            for _, col := range t.Columns {
                for _, re := range patterns {
                    if re.MatchString(col) {
                        fmt.Printf("[+] HIT: %s.%s.%s\n", db.Name, t.Name, col)
                    }
                }
            }
        }
    }
    return nil
}
```

<mark style="background: #8000E1A6;">`Search(mongoMiner)` y `Search(mysqlMiner)` usan el **mismo** código</mark>; cada miner solo aporta su `GetSchema`. Es el principio "accept interfaces, return structs" en acción, y el motivo por el que añadir soporte para PostgreSQL o MSSQL es escribir un `GetSchema` más, no tocar la búsqueda.

## La lista de patrones

Los nombres de columna delatan el contenido: una columna `ccnum` guarda tarjetas; `password`, credenciales. Se buscan con una lista de regex insensibles a mayúsculas. <mark style="background: #FF5582A6;">Aquí una modernización sobre el libro</mark>: el libro compila las regex dentro de una función `getRegex()` que se llama en **cada** búsqueda; compilar una regex es caro, así que se hace **una vez** a nivel de paquete:

```go
var patterns = []*regexp.Regexp{   // compiladas una sola vez, al cargar el paquete
    regexp.MustCompile(`(?i)pass(word)?`),
    regexp.MustCompile(`(?i)ssn|social`),
    regexp.MustCompile(`(?i)ccnum|card|cvv`),
    regexp.MustCompile(`(?i)secret|key|hash`),
}
```

## Extraer el esquema: Mongo vs SQL

La parte específica de cada motor es el `GetSchema`:

- **MongoDB**: enumeras bases y colecciones y sacas **un documento de muestra** de cada una para leer los **nombres de campo** — sin conocer el esquema de antemano (MongoDB es *schema-less*). El truco es el *lazy unmarshal* a `bson.Raw`: <mark style="background: #FFB8EBA6;">solo quieres las claves, no los valores</mark>.

```go
dbNames, _ := m.client.ListDatabaseNames(ctx, bson.D{})
// por cada base -> ListCollectionNames; por cada colección -> un doc de muestra:
var sample bson.Raw
coll.FindOne(ctx, bson.D{}).Decode(&sample)
elems, _ := sample.Elements()          // cada elems[i].Key() es un nombre de campo
```

- **MySQL** (y SQL en general): la metadata vive en `information_schema.columns`. Una consulta te da todas las columnas de todas las bases; luego agrupas las filas por base y tabla:

```go
rows, err := m.db.QueryContext(ctx, `SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
    FROM information_schema.columns
    WHERE TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
    ORDER BY TABLE_SCHEMA, TABLE_NAME`)
if err != nil {
    return nil, err
}
defer rows.Close()

// El ORDER BY ya agrupa; acumulas schema -> tabla -> columnas (más limpio que el prev/curr del libro)
byDB := map[string]map[string][]string{}
for rows.Next() {
    var schema, table, col string
    if err := rows.Scan(&schema, &table, &col); err != nil {
        return nil, err
    }
    if byDB[schema] == nil {
        byDB[schema] = map[string][]string{}
    }
    byDB[schema][table] = append(byDB[schema][table], col)
}
// ...convertir byDB a *Schema; comprobar rows.Err() al final (como en la nota 00)
```

## Por qué minar el esquema

<mark style="background: #FFB86CA6;">Minar nombres de columna encuentra **dónde** está el botín sin leerlo todo</mark> — mucho más rápido y sigiloso que volcar bases enteras. Una columna `password`, `ccnum` o `ssn` te dice exactamente qué tabla exfiltrar después. El pillaging y el looting post-explotación a fondo (qué buscar, cómo exfiltrar sin ser detectado) son metodología de Red Team; aquí tienes el motor en Go, portable y extensible por la interfaz.

Del looting de bases pasamos al del disco: recorrer el sistema de ficheros buscando archivos jugosos → [[03 - Pillaging del sistema de ficheros]].
