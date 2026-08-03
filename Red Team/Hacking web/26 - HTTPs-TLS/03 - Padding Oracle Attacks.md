---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Descripción: "Un padding oracle es un ataque criptográfico que surge cuando el servidor filtra de forma observable si el padding de un texto cifrado en modo CBC es correcto tras descifrarlo"
Fecha de actualización: 2026-07-14
Nota previa: "[[02 - Handshake TLS 1.2 y 1.3]]"
Nota siguiente: "[[04 - POODLE y BEAST]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Un **padding oracle** es un ataque criptográfico que surge cuando <mark style="background: #ADCCFFA6;">el servidor filtra de forma observable si el `padding` de un texto cifrado en modo `CBC` es correcto tras descifrarlo</mark>. No es específico de TLS: aparece en **cualquier** aplicación que maneje mal cifrado/descifrado. Y esto lo hace directamente relevante para bug bounty — cada cookie, token o parámetro "cifrado" que el servidor descifra puede ser un oráculo.

# Qué es el padding y por qué existe

Los **cifradores de bloque** (block ciphers como `AES`) procesan el texto en bloques de tamaño fijo, así que la entrada debe ser múltiplo del tamaño de bloque. El **padding** son los bytes añadidos para llegar a esa longitud. `AES` usa bloques de 16 bytes: para cifrar 30 bytes hay que añadir 2 de padding.

El padding debe ser **reversible**, y ahí está el matiz. Con un esquema ingenuo (rellenar con `FF` hasta completar):

```text
Bloque de 8 bytes · plaintext = DE AD BE EF FF  (5 bytes)
Padding ingenuo:    DE AD BE EF FF FF FF FF       → al quitar los FF finales
Resultado:          DE AD BE EF                   → ¡perdimos el FF original!
```

Es imposible saber cuántos bytes quitar. Por eso los esquemas reales (**`PKCS#7`**) <mark style="background: #FFB8EBA6;">codifican la **longitud** del padding en los propios bytes de relleno</mark>: si faltan 3 bytes, se rellena con `03 03 03`. Al descifrar, el último byte dice cuántos quitar — y si esos bytes no cuadran, el padding es **inválido**.

# El mecanismo del oráculo (CBC)

En `CBC`, el descifrado de un bloque es: `P_i = Decrypt(C_i) XOR C_{i-1}`. Llamamos **intermediate** al resultado de `Decrypt(C_i)`.

```text
   C_{i-1} (bloque anterior)        C_i (bloque objetivo)
        │                                │
        │                          ┌─────▼─────┐
        │                          │ Decrypt() │  → Intermediate = Decrypt(C_i)
        │                          └─────┬─────┘
        └──────────► XOR ◄───────────────┘
                      │
                      ▼
                     P_i (plaintext)
```

<mark style="background: #FFB86CA6;">El atacante controla `C_{i-1}` (es texto cifrado, público)</mark>. Modificándolo byte a byte hasta que el servidor acepte el padding del bloque `C_i`, deduce el `Intermediate` de ese byte; XOR con el `C_{i-1}` **original** revela un byte de plaintext. Repetido byte a byte descifra el bloque, y bloque a bloque descifra el mensaje **completo** — todo <mark style="background: #FFB86CA6;">sin conocer la clave</mark>. En muchos casos, además, permite **cifrar** un plaintext arbitrario, forjando un texto cifrado válido.

# Detección

Se identifica observando la respuesta ante un padding inválido. <mark style="background: #FF5582A6;">Cualquier diferencia frente a un padding válido es el oráculo</mark>:

- Mensajes de error verbosos (`Invalid Padding`, `PaddingException`).
- Diferencia en el **código de estado** HTTP (p. ej. `200` vs `500`).
- Diferencia en el **cuerpo** o la longitud de la respuesta.
- **Timing**: un padding válido sigue procesándose (verifica MAC), uno inválido corta antes → diferencia medible.

> [!warning] El oráculo suele ser silencioso
> En objetivos modernos casi nunca verás `Invalid Padding` a pelo. El oráculo se esconde en diferencias sutiles: un `500` genérico vs un `403`, 2 bytes de diferencia en el cuerpo, o solo timing. La caza consiste en encontrar un **blob base64/hex que el servidor descifre** (cookie, token `state`, parámetro `data=`) y medir esas diferencias con precisión.

# Explotación con PadBuster

`PadBuster` (Perl) automatiza el ataque. Necesita la URL, una muestra cifrada y el tamaño de bloque (prueba 16, luego 8):

```shell-session
# Descifrar el valor de una cookie cifrada
$ padbuster http://target/admin "AAAA...JQB/nhNEuPuNC8ox7cN1z0=" 16 \
    -encoding 0 -cookies "user=AAAA...JQB/nhNEuPuNC8ox7cN1z0="
# ...selecciona la firma de respuesta que marca el error (la marcada con **)
[+] Decrypted value (ASCII): user=htb-stdnt
```

`-encoding 0` = base64; `-cookies` ubica el cifrado en la cookie (`-post` si va en el cuerpo); `-usebody`/`-error 'Invalid Padding'` afinan cómo distingue el padding válido. Descubierto que la cookie es `user=<nombre>`, se **forja** una nueva para `admin`:

```shell-session
$ padbuster http://target/admin "AAAA...=" 16 -encoding 0 \
    -cookies "user=AAAA...=" -plaintext "user=admin"
[+] Encrypted value is: Jdd83wBRLkdmqhUqUEjzmAAAAAAAAAAAAAAAAAAAAAA%3D
```

Poniendo ese valor como cookie `user`, se accede al panel admin. Alternativa en Burp: la extensión **Padding Oracle Hunter**.

# Contexto profesional: dónde aparece de verdad

HTB lo presenta en TLS, pero los padding oracles **famosos son web**:

- **ASP.NET (MS10-070 / CVE-2010-3332, 2010)**: el padding oracle más impactante de la historia web. Permitía descifrar y **forjar** el `ViewState`, descargar `web.config` vía `WebResource.axd`/`ScriptResource.axd` y lograr RCE. Afectó a millones de sitios.
- **Vaudenay (2002)**: el paper original que introdujo la técnica contra CBC.
- **Hoy**: cualquier "criptografía casera" — cookies cifradas, tokens de reset, `JWE` con `A128CBC-HS256` mal implementado, parámetros de URL cifrados. Es un patrón vivo en bug bounty siempre que veas un blob descifrado server-side.

> [!success] Por qué el mundo moderno lo mitiga
> Los padding oracles son un problema de **CBC + MAC-then-Encrypt**. Se cierran con:
> - **AEAD** (`AES-GCM`, `ChaCha20-Poly1305`): no hay padding que validar; la autenticación es intrínseca. TLS 1.3 solo admite AEAD.
> - **Encrypt-then-MAC**: verificar el MAC **antes** de descifrar; si falla, ni se toca el padding.
> - Error **genérico y comportamiento constante** ante fallo de descifrado (mismo status, cuerpo y timing).
> Regla de oro: <mark style="background: #FF5582A6;">"Never roll your own crypto"</mark> — usar librerías estándar bien configuradas.

## Referencias

- [Vaudenay 2002 — CBC Padding Oracle](https://www.iacr.org/archive/eurocrypt2002/23320530/cbc02_e02d.pdf)
- [PadBuster (GitHub)](https://github.com/AonCyberLabs/PadBuster)
- [MS10-070 — ASP.NET Padding Oracle](https://learn.microsoft.com/en-us/security-updates/securitybulletins/2010/ms10-070)
