---
tags:
  - Go
  - Go/Cripto
  - Cracking
Descripción: "Antes de crackear un hash tienes que saber de qué tipo es — el modo de Hashcat, la wordlist, el coste esperado dependen de ello"
Fecha de actualización: 2026-07-26
Nota previa: "[[08 - Predicción de un generador congruencial lineal (LCG)]]"
Nota siguiente: 
Area: "[[Criptografía.base|Criptografía]]"
---
---

Antes de crackear un hash tienes que saber **de qué tipo es** — el modo de Hashcat, la wordlist, el coste esperado dependen de ello. El tipo se deduce del formato: longitud, alfabeto y prefijo. Es una utilidad de reconocimiento que ahorra intentos fallidos. El cracking en sí vive en [[00 - Hashing - cracking y almacenamiento seguro]].

> [!info]+ Fuente
> Receta "Identifying hashes" de *Python Web Penetration Testing Cookbook* (2015).

## Reglas de identificación

El prefijo es la señal fuerte (`$2b$` = bcrypt, `$6$` = sha512crypt); a falta de él, longitud + alfabeto hex acotan el tipo:

```go
type HashType struct {
    Name        string
    HashcatMode int
}

func identify(h string) []HashType {
    h = strings.TrimSpace(h)
    switch {
    case strings.HasPrefix(h, "$2a$"), strings.HasPrefix(h, "$2b$"), strings.HasPrefix(h, "$2y$"):
        return []HashType{{"bcrypt", 3200}}
    case strings.HasPrefix(h, "$6$"):
        return []HashType{{"sha512crypt", 1800}}
    case strings.HasPrefix(h, "$argon2id$"):
        return []HashType{{"argon2id", 34000}}
    case isHex(h) && len(h) == 32:
        return []HashType{{"MD5", 0}, {"NTLM", 1000}}   // ambiguo: mismo formato
    case isHex(h) && len(h) == 40:
        return []HashType{{"SHA-1", 100}}
    case isHex(h) && len(h) == 64:
        return []HashType{{"SHA-256", 1400}}
    }
    return nil
}
```

## La ambigüedad manda: el contexto desempata

<mark style="background: #FF5582A6;">32 caracteres hex son MD5 **o** NTLM</mark> — idéntico formato. La longitud no basta; lo resuelve el **origen**: un hash sacado del SAM/NTDS de Windows es NTLM; uno de una tabla de usuarios de una web es casi seguro MD5. Por eso `identify` devuelve una **lista** de candidatos, no un tipo único: presentas las opciones y el pentester decide con el contexto. Igual que en la detección de SQLi o de librerías, <mark style="background: #8000E1A6;">el formato acota, el contexto confirma</mark>.

## Modernizaciones sobre el recetario

- **Devuelve candidatos con el modo de Hashcat** listo para copiar (`-m 1000` para NTLM), no solo un nombre.
- **Prefijos modernos** (`$argon2id$`, `$2b$`) que el original de 2015 no cubría — Argon2 es hoy el estándar de almacenamiento de contraseñas.
- **Reconoce la ambigüedad** en vez de adivinar un único tipo.

> [!info]+ Arsenal
> `hashid`, `hash-identifier` y el propio `hashcat --identify` hacen esto con cientos de firmas mantenidas. Tu función Go es el núcleo didáctico y encaja en un pipeline propio (identificar → elegir modo → lanzar hashcat). El cracking con John/Hashcat está en Red Team (Pentesting) [[Hashcat.base|Hashcat]] y [[John the Ripper.base|John the Ripper]].

---

Con esto cierras el addendum de cripto **clásica y débil** —cifras clásicas, reuso de OTP, predicción de LCG e identificación de hashes—, complemento a la cripto moderna del resto del bloque. El siguiente tema del proyecto baja al sistema operativo: Windows y análisis de PE → carpeta `11 - Windows y PE`.
