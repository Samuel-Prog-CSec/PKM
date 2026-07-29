---
tags:
  - Go
  - Go/Cripto
  - Cracking
Descripción: "Cripto clásica: cifras monoalfabéticas que no protegen nada pero aparecen en CTFs, retos, malware simple y ofuscación casera"
Fecha de actualización: 2026-07-26
Nota previa: "[[05 - Brute-forcing RC2 concurrente]]"
Nota siguiente: "[[07 - Ataque a reuso de one-time pad]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

Cripto clásica: cifras monoalfabéticas que no protegen nada pero aparecen en CTFs, retos, malware simple y ofuscación casera. ROT13 y Atbash son reversibles a ojo; la sustitución general se rompe por **análisis de frecuencia**. Son utilidades de "reconoce y descifra", no defensa.

> [!info]+ Fuente
> Recetas "Encoding with ROT13", "Cracking a substitution cipher" y "Cracking the Atbash cipher" de *Python Web Penetration Testing Cookbook* (2015).

## ROT13 y Atbash: su propia inversa

Ambas son involuciones (aplicarlas dos veces devuelve el original), así que cifrar = descifrar. Con `strings.Map` recorres runas sin tocar lo que no es letra:

```go
func rot13(s string) string {
    return strings.Map(func(r rune) rune {
        switch {
        case r >= 'a' && r <= 'z':
            return 'a' + (r-'a'+13)%26
        case r >= 'A' && r <= 'Z':
            return 'A' + (r-'A'+13)%26
        }
        return r
    }, s)
}

func atbash(s string) string {
    return strings.Map(func(r rune) rune {
        switch {
        case r >= 'a' && r <= 'z':
            return 'z' - (r - 'a')   // a↔z, b↔y…
        case r >= 'A' && r <= 'Z':
            return 'Z' - (r - 'A')
        }
        return r
    }, s)
}
```

> [!warning]+ Base64/ROT13/hex NO son cifrado
> El libro incluye "Encoding with Base64" en el mismo capítulo. <mark style="background: #FF5582A6;">Base64, hex y ROT13 son *encoding*, no *encryption*</mark>: no hay clave, son reversibles por cualquiera. Si en un pentest encuentras "datos cifrados" que resultan ser Base64, márcalo como exposición, no como cripto. Reconocer encodings al vuelo (`=` de padding en Base64, solo `0-9a-f` en hex) ahorra tiempo.

## Sustitución: análisis de frecuencia

Una sustitución general (cada letra → otra fija, 26! claves) no se fuerza a lo bruto pero <mark style="background: #ADCCFFA6;">se rompe por estadística</mark>: en un texto largo, la letra más frecuente del cifrado suele ser la `e` (o la más común del idioma). Cuentas frecuencias y las alineas con las esperadas:

```go
func letterFreq(cipher string) map[rune]int {
    freq := map[rune]int{}
    for _, r := range strings.ToLower(cipher) {
        if r >= 'a' && r <= 'z' {
            freq[r]++
        }
    }
    return freq
}
```

El mapeo inicial por frecuencia da un descifrado **aproximado**; refinarlo hasta texto legible es un problema de optimización: <mark style="background: #8000E1A6;">hill-climbing puntuando con fitness de n-gramas</mark> (quadgrams) del idioma. Partes de un mapa aleatorio, intercambias dos letras, y te quedas con el cambio si sube la puntuación de "esto parece español/inglés". Es lo mismo que hace `quipqiup` online.

## Modernizaciones sobre el recetario

- **`strings.Map`** sobre runas, correcto con UTF-8, en vez de manipular bytes o índices.
- **Análisis de frecuencia adaptable al idioma**: frecuencias de español (`e a o s`) o inglés (`e t a o`) según el objetivo — el original asume inglés.
- **Hill-climbing con fitness de quadgramas** como método real de crackeo de sustitución, no solo el mapeo por frecuencia (que rara vez da el texto limpio de una).

> [!info]+ Arsenal
> Para CTFs: `CyberChef` (recetas encadenables: detecta encoding, prueba ROT-n, XOR brute), `quipqiup` (sustitución), `dcode.fr`. Tu código Go entra cuando automatizas dentro de un pipeline o el reto tiene un twist propio.

De las cifras deterministas pasamos a una que **sí** sería irrompible... si no se reusara la clave: el one-time pad → [[07 - Ataque a reuso de one-time pad]].
