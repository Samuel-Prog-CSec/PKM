---
tags:
  - Go
  - Go/Cripto
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - Hashing - cracking y almacenamiento seguro]]"
Nota siguiente: "[[02 - Cifrado simétrico - descifrar AES]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

Un hash prueba integridad, pero no **quién** generó el mensaje. Para autenticar el origen se usa un **MAC** (*Message Authentication Code*). <mark style="background: #ADCCFFA6;">HMAC es un MAC con clave: consume el mensaje y un secreto compartido, y produce una etiqueta que solo quien tenga la clave puede generar</mark>. Sin el secreto, un atacante no puede falsificar un HMAC válido. Es el mecanismo detrás de firmas de webhooks, tokens de API y cookies firmadas.

## HMAC en Go

`crypto/hmac` lo hace trivial. Se crea con una función hash y la clave, se alimenta el mensaje y se compara:

```go
var key = []byte("secreto compartido")   // en real: aleatorio y protegido

func checkMAC(message, recvMAC []byte) bool {
    mac := hmac.New(sha256.New, key)      // HMAC-SHA256 con la clave
    mac.Write(message)
    calcMAC := mac.Sum(nil)
    return hmac.Equal(calcMAC, recvMAC)   // <- comparación en tiempo constante
}
```

El emisor calcula el HMAC y lo adjunta; el receptor lo recalcula localmente y compara. Si coinciden, el mensaje viene de alguien con la clave y no fue alterado.

## El detalle que rompe todo: la comparación

> [!warning]+ `hmac.Equal`, nunca `bytes.Compare` ni `==`
> Aquí es donde caen muchas implementaciones. <mark style="background: #FF5582A6;">`bytes.Compare` y `==` comparan byte a byte y **cortan en la primera diferencia**</mark>: comparar un HMAC que difiere en el primer byte tarda menos que uno que difiere en el último. Un atacante mide esa diferencia de tiempo y deduce el HMAC esperado byte a byte, hasta forjar uno válido. Es un *timing attack* clásico.
> `hmac.Equal` compara en **tiempo constante**: tarda lo mismo encuentre la diferencia donde la encuentre, sin patrón medible. <mark style="background: #8000E1A6;">La diferencia entre `hmac.Equal` y `bytes.Compare` es la diferencia entre seguro y falsificable.</mark> Por debajo usa `crypto/subtle.ConstantTimeCompare`, la primitiva que debes usar para comparar **cualquier** secreto (tokens, claves de API), no solo HMACs.

## Por qué HMAC y no `hash(clave || mensaje)`

> [!info]+ Ataques de extensión de longitud
> Un error frecuente es "firmar" con `sha256(clave || mensaje)` en vez de un HMAC. No es equivalente: <mark style="background: #FFB86CA6;">SHA-256 (como MD5 y SHA-1) es vulnerable a *length-extension*</mark> — un atacante que ve `hash(clave||mensaje)` y la longitud puede calcular `hash(clave||mensaje||padding||extra)` sin conocer la clave, forjando un mensaje con MAC válido. La construcción interna de HMAC (con `ipad`/`opad`) lo impide. Regla: para autenticar mensajes, **siempre HMAC**, nunca un hash concatenado a mano.

Un uso ofensivo directo: si un objetivo firma sus peticiones con un secreto que encuentras *hardcoded* en el código o la config ([[03 - Pillaging del sistema de ficheros]]), puedes forjar peticiones válidas con este mismo `crypto/hmac`. El secreto compartido es el punto débil — protégelo tú, explótalo en ellos.

El HMAC da autenticidad e integridad, pero no **confidencialidad**: el mensaje viaja legible. Para ocultarlo hace falta cifrado → [[02 - Cifrado simétrico - descifrar AES]].
