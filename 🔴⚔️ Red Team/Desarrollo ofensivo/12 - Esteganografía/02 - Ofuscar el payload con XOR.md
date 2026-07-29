---
tags:
  - Go
  - Go/Esteganografia
  - Evasion
Descripción: "El payload implantado en 01 - Implantar un payload en un chunk PNG va en claro: cualquiera que extraiga el chunk lo lee"
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - Implantar un payload en un chunk PNG]]"
Nota siguiente: ""
Area: "[[Esteganografía.base|Esteganografía]]"
---
---

El payload implantado en [[01 - Implantar un payload en un chunk PNG]] va en claro: cualquiera que extraiga el chunk lo lee. <mark style="background: #ADCCFFA6;">XOR transforma el payload byte a byte contra una clave</mark> para que no sea legible de un vistazo. El libro lo presenta como "cifrado" — y ahí está la lección más importante de esta nota: **XOR ofusca, no cifra**.

## XOR con clave rotativa

`A ^ B` da 1 solo si los bits difieren. La propiedad mágica: `(P ^ K) ^ K = P` — <mark style="background: #FFB8EBA6;">aplicar XOR con la misma clave descifra</mark>. Por eso codificar y decodificar son la misma función:

```go
func encodeDecode(input []byte, key string) []byte {
    out := make([]byte, len(input))
    for i := range input {
        out[i] = input[i] ^ key[i%len(key)]   // clave rotativa: i % len(key)
    }
    return out
}

// XorEncode y XorDecode son el MISMO cálculo (XOR es simétrico):
func XorEncode(data []byte, key string) []byte { return encodeDecode(data, key) }
func XorDecode(data []byte, key string) []byte { return encodeDecode(data, key) }
```

El `key[i % len(key)]` <mark style="background: #8000E1A6;">recicla la clave</mark>: cuando llegas al final, el módulo vuelve al primer byte, así una clave corta cubre un payload largo.

> [!warning]+ Corrección al libro: `=`, no `+=`
> El libro escribe `bArr[i] += input[i] ^ key[...]`. El `+=` sobre un slice recién creado (bytes a 0) "funciona" por casualidad —`0 + x == x`— pero es confuso y un bug esperando a pasar: si el buffer no estuviera a cero, sumaría en vez de asignar. Es `=`, no `+=`. La operación es una asignación, no una acumulación.

## Lo que de verdad importa: XOR no es cifrado

> [!fail]+ XOR con clave repetida es trivial de romper
> El libro llama a esto *encrypt/decrypt*. No lo es. <mark style="background: #FF5582A6;">XOR con clave repetida es ofuscación, no confidencialidad</mark>:
> - **Known-plaintext**: si conoces (o adivinas) parte del texto claro —y en shellcode conoces cabeceras típicas— recuperas la clave con un XOR y descifras el resto.
> - **Análisis de frecuencia / longitud de clave**: técnicas clásicas (Kasiski, índice de coincidencia) sacan la longitud de la clave y luego cada byte.
> - **La clave viaja con el payload**: para descifrar en el objetivo, la clave está en el propio binario — recuperable.
>
> La regla de oro (nota [[02 - Cifrado simétrico - descifrar AES]]): **no te inventes tu criptografía**. Para confidencialidad real, cifra el payload con **AES-GCM** (`crypto/aes` + `crypto/cipher`), que sí autentica y resiste. El propio libro lo deja como ejercicio; hazlo el estándar. XOR sirve como capa de ofuscación *ligera* encima de un cifrado real, nunca como el cifrado.

## Alcance real en evasión

XOR-ear el payload evade **firmas estáticas ingenuas** (el AV que busca los bytes exactos del shellcode de msfvenom). Pero un endpoint moderno no se queda ahí: <mark style="background: #FFB86CA6;">emula, hace *sandboxing* y detecta el patrón de desofuscación en tiempo de ejecución</mark>. Y la imagen con el chunk anómalo sigue siendo visible al *steganalysis*. El stack de evasión real —cifrado fuerte, *loaders*, ejecución sin tocar disco— es metodología de Red Team; XOR es el primer eslabón didáctico, no la solución.

> [!info]+ Detalle de implementación: el chunk duplicado al decodificar
> Al escribir el chunk decodificado en el mismo offset, la implementación ingenua **desplaza** el chunk codificado a la derecha en vez de sobreescribirlo — acabas con los dos chunks en el fichero. El fix (como XOR es *byte-for-byte*, ambos chunks miden lo mismo) es hacer un `r.Seek(int64(len(chunk)), io.SeekCurrent)` para saltar el chunk viejo antes del `io.Copy` final. Un recordatorio de que manipular offsets a mano es frágil — comprueba el resultado con un editor hex.

Con esto cierras la esteganografía en PNG: leer chunks, implantar un payload y ofuscarlo. El capítulo final ata muchos de estos hilos en una sola herramienta — un RAT de command-and-control con gRPC → carpeta `13 - Command and Control`.
