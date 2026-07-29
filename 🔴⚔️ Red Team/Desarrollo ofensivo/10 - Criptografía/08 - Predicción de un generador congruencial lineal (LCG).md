---
tags:
  - Go
  - Go/Cripto
  - Cracking
Descripción: "Un generador congruencial lineal (LCG) produce 'aleatoriedad' con X_{n+1} = (a·X_n + c) mod m"
Fecha de actualización: 2026-07-26
Nota previa: "[[07 - Ataque a reuso de one-time pad]]"
Nota siguiente: "[[09 - Identificación de hashes]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

Un generador congruencial lineal (LCG) produce "aleatoriedad" con `X_{n+1} = (a·X_n + c) mod m`. Es rápido y **predecible**: es el motor de `rand()` de C, `glibc`, `java.util.Random` y mil PRNGs no criptográficos. <mark style="background: #FFB86CA6;">Si un token de sesión, reset o CSRF se genera con un LCG, un atacante los predice todos</mark>. La relevancia para pentest es directa (Red Team [[03 - Fuerza bruta de tokens de reset]]).

> [!info]+ Fuente
> Receta "Predicting a linear congruential generator" de *Python Web Penetration Testing Cookbook* (2015).

## Con parámetros conocidos, es trivial

Si conoces `a`, `c`, `m` y una salida, calculas la siguiente con una multiplicación. Lo interesante es el caso realista: **no** conoces los parámetros, solo ves salidas consecutivas. Y aun así se recuperan.

## Recuperar `m`, `a`, `c` desde las salidas

Con suficientes salidas consecutivas `s0, s1, …`, el módulo se recupera por álgebra: las diferencias `d_i = s_{i+1} − s_i` cumplen que `m` divide `t_i = d_{i+2}·d_i − d_{i+1}²`, así que `m = gcd(t_i)`. Usas `math/big` porque los módulos son grandes:

```go
func recoverModulus(seq []*big.Int) *big.Int {
    diffs := make([]*big.Int, 0, len(seq)-1)
    for i := 1; i < len(seq); i++ {
        diffs = append(diffs, new(big.Int).Sub(seq[i], seq[i-1]))
    }
    var m *big.Int
    for i := 0; i+2 < len(diffs); i++ {
        t := new(big.Int).Sub(
            new(big.Int).Mul(diffs[i+2], diffs[i]),
            new(big.Int).Mul(diffs[i+1], diffs[i+1]),
        )
        t.Abs(t)
        if m == nil {
            m = t
        } else {
            m.GCD(nil, nil, m, t)   // gcd acumulado
        }
    }
    return m
}
```

Con `m`, el multiplicador sale del inverso modular, y de ahí el incremento:

```go
// a = (s2 − s1) · (s1 − s0)^{-1}  (mod m)
func recoverAC(s0, s1, s2, m *big.Int) (a, c *big.Int) {
    inv := new(big.Int).ModInverse(new(big.Int).Sub(s1, s0), m)
    a = new(big.Int).Mul(new(big.Int).Sub(s2, s1), inv)
    a.Mod(a, m)
    c = new(big.Int).Sub(s1, new(big.Int).Mul(a, s0))   // c = s1 − a·s0 (mod m)
    c.Mod(c, m)
    return a, c
}
```

> [!warning]+ Dos gotchas al recuperar los parámetros
> Con **pocas** salidas, `gcd(t_i)` puede quedarse en un **múltiplo** de `m`, no en `m` exacto — añade más muestras hasta que el valor se estabilice. Y `ModInverse` devuelve `nil` si `(s1−s0)` **no** es coprimo con `m` (y entonces el `Mul` siguiente panica): si ocurre, prueba con otro trío de salidas consecutivas.

<mark style="background: #8000E1A6;">Con `a`, `c`, `m` recuperados, predices toda la secuencia futura</mark> — y, si el token era un output del LCG, generas el siguiente token de reset antes de que la víctima lo use.

## Modernizaciones sobre el recetario

- **`math/big`** para aritmética modular exacta (`ModInverse`, `GCD`) — los módulos de un LCG real desbordan `int64`.
- **Recuperación desde salidas desconocidas**, el caso realista, no solo predecir con parámetros dados.
- Marco de **relevancia para pentest**: el ataque no es un juguete de CTF, es lo que rompe tokens generados con `math/rand`.

> [!warning]+ La lección: `math/rand` no es para tokens
> Todo esto funciona porque el PRNG es lineal y predecible. <mark style="background: #FF5582A6;">Para nada de seguridad —tokens, claves, IDs de sesión, salts— usa `crypto/rand`</mark>, no `math/rand`/`math/rand/v2` (ver [[00 - Hashing - cracking y almacenamiento seguro]]). Si en un pentest ves tokens con estructura predecible (secuenciales, tiempo-dependientes), sospecha de un PRNG débil y pruébalo.

El último apunte del addendum: antes de crackear un hash, saber **de qué tipo es** → [[09 - Identificación de hashes]].
