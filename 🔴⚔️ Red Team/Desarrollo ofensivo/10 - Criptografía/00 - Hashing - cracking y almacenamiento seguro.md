---
tags:
  - Go
  - Go/Cripto
  - Hashing
  - Tipo/Introduccion
Descripción: "Go trae casi toda la criptografía en la stdlib (crypto/...), sin OpenSSL ni dependencias externas — una ventaja enorme para tooling ofensivo portable"
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - HMAC y comparación en tiempo constante]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

Go trae casi toda la criptografía en la stdlib (`crypto/...`), sin OpenSSL ni dependencias externas — una ventaja enorme para tooling ofensivo portable. <mark style="background: #ADCCFFA6;">Un hash es una función unidireccional que produce una salida de longitud fija</mark> a partir de una entrada variable, irreversible. Se usa para almacenar contraseñas e integridad. Desde el lado ofensivo, dos operaciones: crackear los hashes débiles que encuentres y saber cuál es el almacenamiento correcto que un objetivo *debería* usar.

## Crackear MD5/SHA-256 por diccionario

No inviertes el hash: adivinas el texto claro hasheando palabras de una `wordlist` y comparando. La stdlib te da `crypto/md5` y `crypto/sha256`:

```go
var targetMD5 = "77f62e3524cd583d698d51fa24fdff4f"

func main() {
    f, err := os.Open("wordlist.txt")
    if err != nil {
        log.Fatal(err)
    }
    defer f.Close()

    scanner := bufio.NewScanner(f)
    for scanner.Scan() {
        password := scanner.Text()
        sum := md5.Sum([]byte(password))          // [16]byte
        if fmt.Sprintf("%x", sum) == targetMD5 {  // %x -> string hex
            fmt.Printf("[+] MD5: %s\n", password)
        }
    }
    if err := scanner.Err(); err != nil {         // comprobar error del scanner
        log.Fatal(err)
    }
}
```

`md5.Sum` devuelve un array `[16]byte`; `sha256.Sum256` uno de `[32]byte`. `fmt.Sprintf("%x", ...)` los pasa a string hexadecimal para comparar. <mark style="background: #FFB86CA6;">Que MD5 y SHA se crackeen tan rápido no es un accidente: están diseñados para ser veloces</mark>, y esa velocidad es justo lo que te deja probar millones de candidatos por segundo. Como pentester, un hash MD5/SHA es una victoria.

> [!important]+ Esto es didáctico — la herramienta real es Hashcat/John
> Este cracker en Go es para *entender* el mecanismo. En un pentest real usas [[00 - Introducción a Hashcat|Hashcat]] (GPU, miles de millones de hashes/s) o [[00 - Introducción a John the Ripper|John]] — reglas, máscaras, modos híbridos. La metodología de cracking vive en [[00 - Introducción a los ataques a contraseñas]]. Escribes tu propio cracker en Go solo para un formato raro que esas herramientas no soporten.

## Almacenamiento seguro: bcrypt

Lo que un objetivo **debería** hacer con contraseñas es lo contrario de MD5/SHA: usar un hash **lento** y con *salt*. `bcrypt` (`golang.org/x/crypto/bcrypt`) lo hace por defecto:

```go
hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
// ...almacenar 'hash'...

// Verificar (compara internamente, con el salt embebido en el hash):
err = bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
if err != nil {
    // no coincide
}
```

`GenerateFromPassword` <mark style="background: #FFB8EBA6;">incluye un salt aleatorio y un *cost factor*</mark> — por eso el mismo password da hashes distintos cada vez, y por eso `CompareHashAndPassword` re-hashea con el salt embebido en vez de comparar strings. El *cost* controla las iteraciones: subirlo hace el hash exponencialmente más lento de crackear (y ajustable con el tiempo, según crezca el cómputo). El `DefaultCost` es 10; <mark style="background: #FF5582A6;">en 2026 sube a 12 como mínimo</mark>.

## Modernización 2026: Argon2id sobre bcrypt

> [!warning]+ La recomendación actual es Argon2id
> bcrypt sigue siendo aceptable, pero el estándar OWASP para hashing de contraseñas nuevo es **Argon2id** (`golang.org/x/crypto/argon2`): es *memory-hard*, lo que lo hace resistente a *cracking* con GPU y ASIC — precisamente el hardware que hace trivial romper MD5/SHA. bcrypt es *cpu-hard* pero no *memory-hard*.
> ```go
> // Parámetros orientativos OWASP: 19 MiB, 2 pasadas, 1 hilo, salt de 16 B (crypto/rand)
> salt := make([]byte, 16)
> rand.Read(salt)                                  // crypto/rand, NUNCA math/rand
> key := argon2.IDKey([]byte(password), salt, 2, 19*1024, 1, 32)
> ```
> El salt **siempre** de `crypto/rand`, nunca `math/rand` (predecible). Si auditas código y ves passwords con MD5/SHA "a pelo", es un hallazgo: hashing rápido sin salt = crackeable en masa.

> [!info]+ Go 1.24 movió cripto de `x/crypto` a la stdlib
> `crypto/sha3`, `crypto/pbkdf2` y `crypto/hkdf` ya están en la stdlib desde Go 1.24 (antes en `golang.org/x/crypto`). Argon2 y bcrypt siguen en `x/crypto`. Si portas código viejo, actualiza esos imports.

Los hashes que crackeas suelen salir del *pillaging* — bases de datos, ficheros de config ([[02 - Data mining - buscar datos jugosos]]). El hashing verifica integridad pero no autentica el origen de un mensaje; para eso está el HMAC → [[01 - HMAC y comparación en tiempo constante]].
