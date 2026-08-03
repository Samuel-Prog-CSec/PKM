---
tags:
  - Go
  - Go/Datos
  - Bases-de-Datos
  - Tipo/Introduccion
Descripción: "Dejamos los protocolos de red para el saqueo de datos (*pillaging*): una fase menos vistosa que la explotación, pero crítica — las credenciales que encuentras en una BBDD abren…"
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - MongoDB con el driver oficial]]"
Area: "[[Bases de datos y filesystem.base|Bases de datos y filesystem]]"
---
---

Dejamos los protocolos de red para el **saqueo de datos** (*pillaging*): una fase menos vistosa que la explotación, pero crítica — las credenciales que encuentras en una BBDD abren el movimiento lateral, y los datos (PII, tarjetas) son el botín. Empezamos por las bases SQL. Go trae `database/sql` en la stdlib: <mark style="background: #ADCCFFA6;">una **interfaz común** para MySQL, PostgreSQL, MSSQL y demás</mark> — el mismo código sirve para todas, solo cambia el driver.

## La interfaz común: `database/sql` + un driver

`database/sql` define la API; el trabajo real lo hace un **driver** que la implementa. El driver se importa con `_` (blank import): no usas sus tipos, solo se **registra** a sí mismo en `database/sql`.

```go
import (
    "database/sql"
    _ "github.com/go-sql-driver/mysql"   // blank import: registra el driver "mysql"
)
```

Cambiar de backend es cambiar el driver importado, el nombre en `sql.Open` y ajustar la sintaxis SQL — el resto del código es idéntico. Esa portabilidad es la gracia de la interfaz.

## `sql.Open` no conecta: hazle `Ping`

Un detalle que el libro pasa por alto: <mark style="background: #FF5582A6;">`sql.Open` **no** abre ninguna conexión</mark> — crea un **pool** perezoso y valida los argumentos. Si el DSN está mal o la BBDD está caída, `sql.Open` devuelve `nil` de error igualmente; el fallo no aparece hasta la primera consulta. Para verificar de verdad, haz `PingContext`:

```go
db, err := sql.Open("mysql", os.Getenv("DB_DSN"))   // pool, aún sin conectar
if err != nil {
    return err
}
defer db.Close()

ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
if err := db.PingContext(ctx); err != nil {   // AHORA sí verifica la conexión
    return err
}
```

## Consultar: `QueryContext`, `Scan`, `Close`

El patrón de lectura: consultar, iterar filas, escanear cada una a variables, y —clave— comprobar el error **después** del bucle. El libro usa `db.Query` sin contexto; la versión moderna usa `QueryContext` para poder cancelar/poner deadline (nota [[13 - Goroutines, channels y concurrencia]]):

```go
rows, err := db.QueryContext(ctx, "SELECT ccnum, amount FROM transactions")
if err != nil {
    return err
}
defer rows.Close()                        // imprescindible: libera la conexión al pool

for rows.Next() {
    var ccnum string
    var amount float64
    if err := rows.Scan(&ccnum, &amount); err != nil {   // orden y tipos deben cuadrar
        return err
    }
    fmt.Println(ccnum, amount)
}
if err := rows.Err(); err != nil {        // ¿hubo error a mitad de la iteración?
    return err
}
```

<mark style="background: #FFB86CA6;">`rows.Next()` devuelve `false` tanto al terminar como al fallar</mark>, así que `rows.Err()` tras el bucle no es opcional — sin él, un error de red a mitad de lectura pasa desapercibido.

## Parametrizadas y credenciales

Dos reglas de seguridad que un tool de pentest debe respetar en su propio código:

```go
name := userInput
// ❌ concatenar entrada -> SQL injection:
db.QueryContext(ctx, "SELECT * FROM users WHERE name = '"+name+"'")
// ✓ placeholders -> el driver separa datos de código:
db.QueryContext(ctx, "SELECT * FROM users WHERE name = ?", name)
```

<mark style="background: #8000E1A6;">Los placeholders (`?` en MySQL, `$1` en Postgres) mantienen los datos separados del SQL</mark>, cerrando la inyección — la misma que explotas desde el otro lado en [[SQL Injection.base|SQL Injection]] de Red Team. Y las credenciales del DSN van por **variable de entorno**, nunca hardcodeadas (nota [[01 - Diseñar un cliente de API - el caso Shodan]]).

## Drivers modernos y pooling

El ecosistema cambió desde 2020; elige bien el driver:

| Base | Driver 2026 |
| - | - |
| MySQL/MariaDB | `github.com/go-sql-driver/mysql` |
| PostgreSQL | `github.com/jackc/pgx` (sustituye al viejo `lib/pq`) |
| MSSQL | `github.com/microsoft/go-mssqldb` (el `denisenkom/...` pasó a Microsoft) |
| SQLite | `modernc.org/sqlite` (Go puro, sin cgo → cross-compila) |

El `*sql.DB` es un pool concurrente-seguro; ajústalo según la carga con `db.SetMaxOpenConns(n)`, `SetMaxIdleConns(n)`, `SetConnMaxLifetime(d)` y `SetConnMaxIdleTime(d)`. Los fundamentos de cada motor (MySQL, MSSQL, Oracle) viven en [[Bases de Datos.base|Bases de Datos]] (`Ingenieria/`).

Las bases SQL cubiertas, toca la NoSQL más común — y la mayor modernización del capítulo, porque el driver del libro está muerto → [[01 - MongoDB con el driver oficial]].
