---
tags:
  - Go
  - Go/Cripto
Descripción: "RC2 es un cifrado de bloque de Rivest (1987) con clave de 40 bits — débil por diseño (el gobierno de EE. UU. exigió que fuese rompible por fuerza bruta)"
Fecha de actualización: 2026-07-25
Nota previa: "[[04 - Autenticación mutua con TLS]]"
Nota siguiente: "[[06 - Cifras clásicas - ROT13, Atbash y sustitución]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

RC2 es un cifrado de bloque de Rivest (1987) con clave de **40 bits** — débil por diseño (el gobierno de EE. UU. exigió que fuese rompible por fuerza bruta). <mark style="background: #FFB86CA6;">Hoy un PC casero agota el espacio de 40 bits en días</mark>. El cifrado está muerto, pero el proyecto vale por el **patrón concurrente** de fuerza bruta: *producer/consumer* que reparte el trabajo entre goroutines — reutilizable para crackear cualquier cosa.

## El montaje

El objetivo: recorrer todo el keyspace (`0x0` a `0xffffffffff`), descifrar el ciphertext con cada clave y validar el resultado con un *Luhn check* (¿es un número de tarjeta válido?). El reparto: **productores** generan claves a un channel, **consumidores** las prueban.

<mark style="background: #ADCCFFA6;">No hay tipo de 40 bits en Go</mark> — solo 32 o 64. Se itera el keyspace como `uint64` y se recortan los 3 bytes sobrantes con `key[3:]` (una clave de 5 bytes = 40 bits):

```go
type cryptoData struct {
    block cipher.Block
    key   []byte
}
var numeric = regexp.MustCompile(`^\d{8}$`)   // un bloque RC2 = 8 bytes
```

## El productor y el consumidor

El productor itera su subrango del keyspace y empuja trabajo. El consumidor descifra y valida:

```go
func generate(ctx context.Context, start, stop uint64, out chan<- *cryptoData, wg *sync.WaitGroup) {
    wg.Go(func() {                              // Go 1.25: wg.Go en vez de Add/Done
        for i := start; i <= stop; i++ {
            key := make([]byte, 8)              // PutUint64 exige 8 bytes
            binary.BigEndian.PutUint64(key, i)
            block, err := rc2.New(key[3:], 40)  // key[3:] = los 5 bytes útiles
            if err != nil {
                log.Fatal(err)
            }
            select {
            case <-ctx.Done():                  // alguien encontró la clave -> parar
                return
            case out <- &cryptoData{block: block, key: key[3:]}:   // el send también respeta la cancelación
            }
        }
    })
}

func decrypt(ctx context.Context, cancel context.CancelFunc, ct []byte, in <-chan *cryptoData, wg *sync.WaitGroup) {
    wg.Go(func() {
        size := rc2.BlockSize
        pt := make([]byte, len(ct))
        for data := range in {
            select {
            case <-ctx.Done():
                return
            default:
                data.block.Decrypt(pt[:size], ct[:size])    // descifra el 1er bloque
                if numeric.Match(pt[:size]) {               // ¿numérico? -> candidato
                    data.block.Decrypt(pt[size:], ct[size:])
                    if numeric.Match(pt[size:]) && luhn.Valid(string(pt)) {
                        fmt.Printf("tarjeta [%s] con clave [%x]\n", pt, data.key)
                        cancel()                            // avisa a todos
                        return
                    }
                }
            }
        }
    })
}
```

El truco de rendimiento: <mark style="background: #8000E1A6;">descifra primero **un** bloque (8 bytes) y descarta la clave si no es numérico</mark>, sin gastar tiempo en el segundo bloque. Ejecutado millones de veces, ese corte temprano es enorme.

Fíjate en un detalle de concurrencia del productor: el envío `out <- ...` va **dentro** del `select`, no en un `default` con el send bloqueante debajo. Es deliberado — si al llamar `cancel()` los consumidores paran con el channel lleno, un productor bloqueado en un send fuera del `select` nunca vería `ctx.Done()` y colgaría `prodWg.Wait()` (*deadlock*). Con el send como un `case`, el productor sale limpio aunque nadie esté leyendo.

## La modernización clave: `context` en vez de `close(done)`

> [!warning]+ Cerrar un channel dos veces es un panic
> El libro señaliza el fin con `close(done)` desde el consumidor que encuentra la clave. <mark style="background: #FF5582A6;">Es una *race*: si dos goroutines llaman `close(done)`, la segunda hace *panic* ("close of closed channel")</mark> — con validaciones laxas (un falso positivo de Luhn) es posible. La forma idiomática moderna es `context.Context` + `context.CancelFunc`: **`cancel()` es idempotente**, lo pueden llamar N goroutines sin romper nada, y `ctx.Done()` cierra el `select` de todas a la vez. Sustituir el `done channel` por un `context` elimina la race y es el patrón estándar de cancelación en Go (nota [[13 - Goroutines, channels y concurrencia]]).

El `main` reparte el keyspace entre productores, arranca los consumidores y sincroniza con dos `WaitGroup`:

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()
work := make(chan *cryptoData, 100)
var prodWg, consWg sync.WaitGroup

// repartir [min,max] en N productores...
for /* cada subrango */ {
    generate(ctx, start, end, work, &prodWg)
}
for range 30 {                       // range-over-int (Go 1.22+)
    decrypt(ctx, cancel, ciphertext, work, &consWg)
}
prodWg.Wait()                        // esperar a que los productores acaben
close(work)                          // cerrar el channel -> los consumidores salen del range
consWg.Wait()                        // esperar a que los consumidores drenen
```

El orden importa: `prodWg.Wait()` → `close(work)` → `consWg.Wait()`. <mark style="background: #FFB86CA6;">Cerrar `work` antes de que los productores terminen provocaría un *send on closed channel*</mark> (otro panic), y no cerrarlo dejaría a los consumidores bloqueados para siempre en el `range`.

> [!info]+ El paquete RC2 es interno
> Go tiene RC2 solo en un paquete `internal` (no importable). El libro lo copia al workspace — sigue siendo el truco en 2026. Pero el valor real de esta nota no es RC2: es el **esqueleto de fuerza bruta concurrente** (repartir keyspace, `context` para cancelar, corte temprano de validación), que aplicas igual a crackear [[00 - Hashing - cracking y almacenamiento seguro|hashes]] o cualquier cifrado débil. Para acotar goroutines en vez de lanzar 75+30 a pelo, el patrón `errgroup.SetLimit` de [[01 - Escáner TCP - de secuencial a concurrente]] encaja aquí también.

Con esto cierras el bloque de criptografía **moderna**: hashing, HMAC, simétrico, asimétrico, mTLS y fuerza bruta concurrente. Como addendum, un puñado de ataques a cripto **clásica y débil** —los que aparecen en CTFs, forense y objetivos legacy—, empezando por las cifras clásicas → [[06 - Cifras clásicas - ROT13, Atbash y sustitución]].
