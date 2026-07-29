---
tags:
  - Go
  - Go/Cripto
  - Cracking
Descripción: "El one-time pad es el único cifrado matemáticamente irrompible — con clave aleatoria, tan larga como el mensaje y usada una sola vez"
Fecha de actualización: 2026-07-26
Nota previa: "[[06 - Cifras clásicas - ROT13, Atbash y sustitución]]"
Nota siguiente: "[[08 - Predicción de un generador congruencial lineal (LCG)]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

El one-time pad es <mark style="background: #ADCCFFA6;">el único cifrado matemáticamente irrompible</mark> — con clave aleatoria, tan larga como el mensaje y usada **una sola vez**. Rompe cualquiera de esas tres condiciones y se cae. La más común en la práctica: **reusar la clave**. Dos mensajes cifrados con el mismo keystream se descifran mutuamente sin conocer la clave.

> [!info]+ Fuente
> Receta "Attacking one-time pad reuse" de *Python Web Penetration Testing Cookbook* (2015).

## Por qué el reuso lo mata

Si `C1 = P1 ⊕ K` y `C2 = P2 ⊕ K` con la **misma** `K`, entonces:

```
C1 ⊕ C2 = (P1 ⊕ K) ⊕ (P2 ⊕ K) = P1 ⊕ P2
```

<mark style="background: #FF5582A6;">La clave se cancela</mark>. Te quedas con el XOR de los dos textos planos, sin clave de por medio:

```go
func xorBytes(a, b []byte) []byte {
    n := min(len(a), len(b))
    out := make([]byte, n)
    for i := range n {
        out[i] = a[i] ^ b[i]
    }
    return out
}

combined := xorBytes(c1, c2)   // = P1 ⊕ P2
```

## Crib-dragging

De `P1 ⊕ P2` recuperas ambos textos con **crib-dragging**: adivinas una palabra probable (`" the "`, `" http"`, un token conocido), la XOR-eas en cada posición del stream combinado, y si el resultado es texto imprimible, has encontrado un fragmento del **otro** mensaje ahí:

```go
func cribDrag(combined, crib []byte) {
    for i := 0; i+len(crib) <= len(combined); i++ {
        guess := xorBytes(combined[i:i+len(crib)], crib)
        if isPrintable(guess) {                     // solo ASCII legible
            fmt.Printf("pos %d con %q → %q\n", i, crib, guess)
        }
    }
}
```

Si `" the "` en la posición 10 revela `" pass"`, sabes que un mensaje tiene `the` y el otro `pass` ahí — y tiras del hilo alternando cribs entre ambos.

## Muchos mensajes: recuperar el keystream

<mark style="background: #8000E1A6;">Con varios ciphertexts bajo la misma clave (many-time pad), es aún más fácil</mark>: en cada posición, el byte de plaintext más frecuente en texto natural es el **espacio** (`0x20`). Si en la columna `j` la mayoría de `Ci[j] ⊕ Ck[j]` corresponde a XOR con espacio, deduces `K[j]` y descifras esa columna en **todos** los mensajes a la vez. Paralelizable por columna con el patrón de la [[05 - Brute-forcing RC2 concurrente|fuerza bruta concurrente]].

## Modernizaciones sobre el recetario

- **Trabajo directo sobre `[]byte`** con `min` (Go 1.21) y `range n` (1.22) — sin conversiones ni bucles manuales.
- **Ataque estadístico multi-mensaje** (recuperación de keystream por columna), no solo el crib-dragging de dos mensajes del original.
- **Concurrencia por columna** cuando hay muchos ciphertexts.

> [!info]+ En un pentest real
> Verás esto en cifrados caseros: un stream cipher (RC4, AES-CTR) con **nonce/IV fijo** es exactamente un OTP con clave reusada. Si un objetivo cifra varios mensajes con el mismo keystream (mismo IV), aplica esto. La lección defensiva: nunca reutilizar nonce/IV — es el fallo detrás de vulnerabilidades reales de WEP y de implementaciones AES-GCM mal hechas.

De reusar claves pasamos a predecir "aleatoriedad" que no lo es: los generadores congruenciales lineales → [[08 - Predicción de un generador congruencial lineal (LCG)]].
