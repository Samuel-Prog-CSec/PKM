---
tags:
  - Go
  - Go/Cripto
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - HMAC y comparación en tiempo constante]]"
Nota siguiente: "[[03 - Cifrado asimétrico - RSA con OAEP y PSS]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

<mark style="background: #ADCCFFA6;">El cifrado simétrico usa la **misma clave** para cifrar y descifrar</mark>. AES es el algoritmo estándar. El escenario ofensivo típico: has comprometido una app, encuentras la clave *hardcoded* en el código o la config, y en la BBDD hay tarjetas cifradas con AES. Con la clave, las descifras. Go pone AES en `crypto/aes` + `crypto/cipher`.

## Descifrar AES-CBC

AES tiene varios **modos de operación** no intercambiables — el de descifrado debe ser el mismo que el de cifrado. Un caso muy común en código real es CBC (*Cipher Block Chaining*):

```go
func decryptCBC(ciphertext, key []byte) ([]byte, error) {
    if len(ciphertext) < aes.BlockSize {
        return nil, errors.New("ciphertext demasiado corto")
    }
    if len(ciphertext)%aes.BlockSize != 0 {
        return nil, errors.New("longitud no múltiplo del bloque")
    }

    iv := ciphertext[:aes.BlockSize]        // el IV va al principio del ciphertext
    ciphertext = ciphertext[aes.BlockSize:]

    block, err := aes.NewCipher(key)        // inicializa el cifrador con la clave
    if err != nil {
        return nil, err
    }
    plaintext := make([]byte, len(ciphertext))
    cipher.NewCBCDecrypter(block, iv).CryptBlocks(plaintext, ciphertext)
    return unpad(plaintext), nil            // quitar el relleno PKCS#7
}
```

Tres piezas: <mark style="background: #FFB8EBA6;">el **IV** (vector de inicialización) va prepended al ciphertext</mark> —no es secreto, como un salt, y ocupa un bloque—; `CryptBlocks` descifra en sitio; y `unpad` retira el relleno PKCS#7 que alinea los datos al tamaño de bloque. Las dos validaciones de longitud son obligatorias: CBC exige que el ciphertext sea múltiplo del bloque o el descifrado revienta.

## La modernización que importa: CBC/ECB no autentican

> [!warning]+ CBC y ECB son cifrado **sin autenticar** — usa AES-GCM
> El gran hueco del libro (2020) para 2026: <mark style="background: #FF5582A6;">CBC y ECB solo dan confidencialidad, no integridad</mark>. Un atacante puede **modificar** el ciphertext y el descifrado no lo detecta — la base de los *bit-flipping* y, sobre todo, los **padding oracle attacks**: ese `unpad` manual, si el servidor filtra si el padding es válido o no, permite **descifrar sin la clave**. El estándar hoy es **AES-GCM**, un modo AEAD que cifra **y** autentica de una vez:
> ```go
> block, _ := aes.NewCipher(key)
> gcm, _ := cipher.NewGCM(block)
> nonce := make([]byte, gcm.NonceSize())
> rand.Read(nonce)                                   // crypto/rand
> ciphertext := gcm.Seal(nonce, nonce, plaintext, nil)   // cifra + autentica
> // Descifrar: gcm.Open falla si el ciphertext fue manipulado
> plaintext, err := gcm.Open(nil, nonce, ct[gcm.NonceSize():], nil)
> ```
> `gcm.Open` **rechaza** un ciphertext manipulado (devuelve error), cerrando el padding oracle de raíz. Para código nuevo, GCM; CBC/ECB solo aparecen al **descifrar lo que la víctima ya cifró mal**.

> [!info]+ ECB, todavía peor
> ECB cifra cada bloque de forma independiente, así que <mark style="background: #8000E1A6;">bloques de texto claro idénticos dan ciphertext idéntico</mark> — el patrón se ve a simple vista (el famoso "pingüino ECB"). Si encuentras ECB en un objetivo, es una debilidad explotable por sí sola.

## El ángulo ofensivo

Saber un poco de simétrico dispara el valor de un pentest. En *code review* de repos de clientes es habitual encontrar AES en CBC o ECB con la clave estática en el propio código o un fichero de config ([[03 - Pillaging del sistema de ficheros]]). El desarrollador asume que "AES = seguro" ignorando que el **modo** y el **manejo de la clave** lo son todo. Con la clave hardcoded y este `decryptCBC`, descifras los datos sensibles. Si en cambio ves GCM con claves bien gestionadas, no hay atajo — como debe ser.

El simétrico es rápido pero arrastra el problema de **distribuir la clave** de forma segura. Eso lo resuelve el cifrado asimétrico → [[03 - Cifrado asimétrico - RSA con OAEP y PSS]].
