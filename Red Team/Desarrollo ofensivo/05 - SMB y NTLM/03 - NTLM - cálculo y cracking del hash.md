---
tags:
  - Go
  - Go/SMB
  - Cracking
Descripción: "Los dos ataques anteriores giran en torno al hash NTLM. Esta última nota cierra el círculo: de dónde sale ese hash, por qué a veces necesitas la contraseña en claro (y no solo…"
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Password spraying y pass-the-hash sobre SMB]]"
Nota siguiente: 
Area: "[[SMB y NTLM.base|SMB y NTLM]]"
---
---

Los dos ataques anteriores giran en torno al **hash NTLM**. Esta última nota cierra el círculo: de dónde sale ese hash, por qué a veces necesitas la contraseña en claro (y no solo el hash), y cómo se crackea. El libro monta un cracker por diccionario; en la práctica se usa `hashcat`/`john`, pero entender el cálculo es lo que hace que el resto tenga sentido.

## Por qué a veces el hash no basta

El pass-the-hash (nota [[02 - Password spraying y pass-the-hash sobre SMB]]) autentica por SMB con el hash. Pero <mark style="background: #FFB86CA6;">muchos servicios no aceptan autenticación por hash</mark> — Remote Desktop, Outlook Web Access y otros exigen la contraseña en claro. Si tu cadena de ataque pasa por uno de esos, tienes que **crackear** el hash para recuperar la contraseña.

## El hash NTLM: MD4 sin sal

El "NT hash" que se pasa en pass-the-hash es sencillísimo de calcular: <mark style="background: #ADCCFFA6;">MD4 de la contraseña codificada en UTF-16LE</mark>. Nada más.

```go
import (
    "encoding/binary"
    "unicode/utf16"
    "golang.org/x/crypto/md4"   // MD4 no está en la stdlib; vive en x/crypto (deprecado)
)

// No hay helper mágico: la contraseña se codifica en UTF-16LE a mano.
func toUTF16LE(s string) []byte {
    u := utf16.Encode([]rune(s))
    b := make([]byte, len(u)*2)
    for i, r := range u {
        binary.LittleEndian.PutUint16(b[i*2:], r)
    }
    return b
}

func ntHash(password string) []byte {
    h := md4.New()
    h.Write(toUTF16LE(password))
    return h.Sum(nil)   // 16 bytes, SIN sal
}
```

Dos consecuencias con las que juega el atacante:

- <mark style="background: #FF5582A6;">Sin sal, dos usuarios con la misma contraseña tienen el **mismo** NT hash</mark> — visible de un vistazo en un volcado de NTDS.dit, y vulnerable a *rainbow tables*.
- MD4 es **rápido de calcular**, lo que significa **rápido de romper por fuerza bruta**.

El `Ntowfv2(pass, user, domain)` que usa el libro es la función un-paso-más-allá del protocolo (HMAC-MD5 sobre el NT hash con usuario+dominio), la que se usa en el challenge-response NetNTLMv2 que capturas con Responder o en un relay.

## El cracker por diccionario del libro

El cracker es un bucle: por cada palabra del diccionario, calcula su hash y compara con el objetivo. Para que cuadre con lo anterior, crackeamos el **NT hash** (el de `-m 1000` / NTDS.dit) reutilizando la función `ntHash` de arriba:

```go
target, _ := hex.DecodeString(os.Args[4])   // el NT hash a romper (32 caracteres hex)
f, err := os.Open(os.Args[1])                // diccionario
if err != nil {
    log.Fatalln(err)
}
defer f.Close()

for sc := bufio.NewScanner(f); sc.Scan(); {
    if bytes.Equal(target, ntHash(sc.Text())) {   // MD4(UTF-16LE(candidato))
        fmt.Printf("[+] Contraseña recuperada: %s\n", sc.Text())
        break
    }
}
```

> [!warning]+ Qué crackeas exactamente
> Este juguete rompe el **NT hash** (`MD4` de la contraseña, `-m 1000`). No sirve para un **NetNTLMv2** capturado con Responder (`-m 5600`), que necesita el *server challenge* y el *blob* del challenge-response. El libro usa aquí su propio paquete `ntlmssp.Ntowfv2` — que es *interno* en `go-smb2` y **no se puede importar** desde fuera, así que con el stack moderno calculas el hash tú mismo, como arriba.

Es didáctico y funciona, pero es un juguete: mono-hilo y en CPU. Contra un diccionario grande tarda una eternidad.

## En la práctica: `hashcat` / `john`

<mark style="background: #8000E1A6;">Nadie crackea NTLM con un bucle en Go en un engagement real</mark> — se usa GPU con `hashcat` o `john`, que hacen **miles de millones** de intentos por segundo precisamente porque MD4 es trivial de calcular:

- **`hashcat -m 1000`** — NT hash (el de NTDS.dit / pass-the-hash).
- **`hashcat -m 5600`** — NetNTLMv2 (el challenge-response capturado en la red).

La debilidad de NTLM es justo esa velocidad: una contraseña de 8 caracteres cae en horas. La defensa moderna no es un hash rápido sino un **KDF lento y con sal** (`bcrypt`, `argon2`), tema del bloque de [[Criptografía.base|Criptografía]] (Cap. 11). La operativa de cracking a fondo —reglas, máscaras, wordlists— vive en las herramientas del vault: [[Hashcat.base|Hashcat]] y [[John the Ripper.base|John the Ripper]].

> [!info]+ El valor de tu tool en Go
> Un cracker en Go no compite con hashcat en velocidad, pero sí brilla para lógica **a medida**: calcular un hash NTLM concreto, verificar una credencial contra un servicio, o integrar el cálculo dentro de una herramienta mayor. Para romper a volumen, hashcat; para automatizar y encadenar, Go.

---

Con esto cierras el Cap. 6 y todo el bloque de protocolos de red del libro (TCP, HTTP, DNS, SMB). Sabes hablar SMB —con librería moderna—, hacer spraying, pass-the-hash y crackear NTLM en Go. El siguiente capítulo cambia de tercio: dejamos los protocolos para **saquear datos** — bases de datos y sistemas de ficheros → [[Bases de datos y filesystem.base|Bases de datos y filesystem]] (Cap. 7).
