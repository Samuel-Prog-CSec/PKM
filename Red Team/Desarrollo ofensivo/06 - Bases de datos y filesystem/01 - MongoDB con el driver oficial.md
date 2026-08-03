---
tags:
  - Go
  - Go/Datos
  - MongoDB
Descripción: "MongoDB es la base NoSQL que más te vas a encontrar"
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - Bases de datos SQL - database-sql]]"
Nota siguiente: "[[02 - Data mining - buscar datos jugosos]]"
Area: "[[Bases de datos y filesystem.base|Bases de datos y filesystem]]"
---
---

MongoDB es la base NoSQL que más te vas a encontrar. Go no trae soporte NoSQL en la stdlib (a diferencia de `database/sql`, nota [[00 - Bases de datos SQL - database-sql]]), así que necesitas una librería. Y aquí está **la modernización más importante del capítulo**: el libro usa `mgo`, que <mark style="background: #FF5582A6;">lleva sin mantenimiento desde ~2018 y está archivado</mark>. En 2026 se usa el **driver oficial** de MongoDB.

## `mgo` está muerto: usa el driver oficial

`gopkg.in/mgo.v2` fue el driver de facto durante años, pero su autor lo abandonó y quedó congelado — sin soporte para versiones nuevas del servidor, sin parches. El sustituto es **`go.mongodb.org/mongo-driver`**, el driver oficial mantenido por MongoDB (**v2**, GA en enero de 2025), con una API *context-first*.

```shell-session
$ go get go.mongodb.org/mongo-driver/v2/mongo
```

## Conectar y consultar

El flujo recuerda al de `database/sql`: <mark style="background: #ADCCFFA6;">`mongo.Connect` crea un cliente perezoso</mark> (no conecta hasta la primera operación, igual que `sql.Open`); las operaciones toman un `context`.

```go
import (
    "go.mongodb.org/mongo-driver/v2/mongo"
    "go.mongodb.org/mongo-driver/v2/mongo/options"
    "go.mongodb.org/mongo-driver/v2/bson"
)

ctx := context.Background()   // en producción, un ctx con timeout
client, err := mongo.Connect(options.Client().ApplyURI("mongodb://127.0.0.1:27017"))
if err != nil {
    return err
}
defer client.Disconnect(ctx)

coll := client.Database("store").Collection("transactions")
cursor, err := coll.Find(ctx, bson.D{})   // bson.D{} = filtro vacío -> todos los documentos
if err != nil {
    return err
}
var results []Transaction
if err := cursor.All(ctx, &results); err != nil {   // vuelca el cursor entero al slice
    return err
}
```

> [!info]+ v2 vs v1
> En el driver **v2**, `mongo.Connect` ya no toma `context` (es perezoso); las operaciones (`Find`, `Disconnect`…) sí lo toman. En el v1 (aún muy usado) `Connect` recibía el `ctx` como primer argumento. Si copias código antiguo, ese es el cambio de firma que verás.

## BSON: el JSON binario de MongoDB

MongoDB almacena en **BSON** (Binary JSON). El driver mapea entre BSON y tus structs con **struct tags** `bson:"..."`, exactamente igual que `json:"..."` (nota [[12 - JSON, XML y datos estructurados]]):

```go
type Transaction struct {
    CCNum      string  `bson:"ccnum"`
    Amount     float64 `bson:"amount"`
    Cvv        string  `bson:"cvv"`
    Expiration string  `bson:"exp"`
}
```

Hay dos tipos para construir documentos: <mark style="background: #FFB8EBA6;">`bson.D` es **ordenado** (una lista de pares clave/valor); `bson.M` es un mapa sin orden</mark>. Para filtros normales `bson.M` es más legible; `bson.D` se usa cuando el orden importa (comandos, índices compuestos).

## Filtros

Un filtro es un documento BSON con la condición. Para saquear, filtras lo que te interesa — por ejemplo, transacciones de importe alto:

```go
// {amount: {$gt: 1000}}
filter := bson.M{"amount": bson.M{"$gt": 1000}}
cursor, err := coll.Find(ctx, filter)
```

Los operadores (`$gt`, `$regex`, `$in`…) son los de MongoDB; el driver solo los transporta. <mark style="background: #FFB86CA6;">Un `$regex` sobre nombres de campo o valores es la base de la minería de datos</mark> que montas en la nota siguiente — buscar tarjetas, contraseñas o PII sin conocer el esquema.

Con SQL y MongoDB cubiertos, el tool que de verdad importa en pillaging: uno que **busca automáticamente** los datos jugosos en cualquier BBDD, usando una interfaz común → [[02 - Data mining - buscar datos jugosos]].
