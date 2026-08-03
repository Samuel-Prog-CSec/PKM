---
tags:
  - Wi-Fi/WEP
  - Pentesting/Explotacion
Descripción: "Cómo el KSA y el PRGA de RC4 convierten IV más clave en keystream, y por qué anteponer el IV público es lo que rompe el cifrado"
Fecha de actualización: 2026-08-01
Nota previa: "[[00 - WEP, qué fue y por qué murió]]"
Nota siguiente: "[[02 - El ICV CRC-32 y su linealidad]]"
Area: "[[WEP.base|WEP]]"
---
---

<mark style="background: #ADCCFFA6;">`RC4` es un cifrado de flujo: genera una secuencia pseudoaleatoria —el `keystream`— que se combina con el texto en claro mediante XOR</mark>. Lo diseñó Ron Rivest en 1987 y su virtud fue la simplicidad: cabía en unas decenas de líneas y corría en el hardware de la época. Esa simplicidad es también su límite.

![Flujo del cifrado WEP: el IV de 24 bits y la clave de 40/104 bits forman el seed que entra en RC4 (KSA y PRGA) para producir el keystream, que se XORea con el texto en claro más el CRC-32](https://academy.hackthebox.com/storage/modules/185/Diagrams/wep_1.png)

# Las dos fases

**KSA** (*Key Scheduling Algorithm*) — parte de la permutación identidad `S = [0,1,2,…,255]` y la baraja usando la clave. Es un barajado tipo Fisher-Yates, salvo que el índice de intercambio `j` no es aleatorio: **lo determina la clave**.

```python
def ksa(key):
    S = list(range(256))          # permutación identidad
    j = 0
    for i in range(256):
        # j acumula el byte de clave correspondiente: aquí entra el secreto
        j = (j + S[i] + key[i % len(key)]) % 256
        S[i], S[j] = S[j], S[i]   # intercambio
    return S                      # permutación "barajada por la clave"
```

<mark style="background: #FFB8EBA6;">La clave se recorre cíclicamente (`key[i % len(key)]`), así que una clave de 8 bytes se usa 32 veces</mark>. Y las primeras iteraciones dependen sólo de los primeros bytes de la clave — que en WEP son **el IV público**. Ése es el hueco por el que entra FMS.

**PRGA** (*Pseudo-Random Generation Algorithm*) — recorre el estado permutado produciendo un byte de keystream por iteración, y sigue barajando `S` mientras lo hace:

```python
def prga(S, n):
    i = j = 0
    for _ in range(n):
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]        # el estado nunca deja de mutar
        yield S[(S[i] + S[j]) % 256]   # el byte de keystream
```

Juntando ambas, cifrar es una línea:

```python
def rc4(key, datos):
    return bytes(b ^ k for b, k in zip(datos, prga(ksa(key), len(datos))))

>>> rc4(b'Clave', b'Hola').hex()
'd1ac2489'
>>> rc4(b'Clave', bytes.fromhex('d1ac2489'))
b'Hola'
```

> [!success]+ Vectores de prueba para validar la implementación
> Si se reescribe RC4 —propio o en otro lenguaje—, estos dos vectores canónicos lo confirman en un segundo:
> ```python
> >>> rc4(b'Key', b'Plaintext').hex().upper()
> 'BBF316E8D940AF0AD3'
> >>> rc4(b'Wiki', b'pedia').hex().upper()
> '1021BF0420'
> ```
> Un solo bit mal en el `% 256` o en el orden del intercambio y ambos fallan. <mark style="background: #FFB8EBA6;">Merece la pena tenerlos a mano: la mayoría de implementaciones de RC4 que circulan en tutoriales no se validan contra nada</mark>.

El cifrado y el descifrado son **la misma función**, porque el XOR es su propio inverso:

```text
C = P ⊕ KS
P = C ⊕ KS = (P ⊕ KS) ⊕ KS
```

> [!warning]+ La consecuencia de esa simetría
> Que cifrar y descifrar sean idénticos es cómodo de implementar y devastador si el keystream se repite. <mark style="background: #FF5582A6;">Un cifrado de flujo **nunca** puede reutilizar la misma combinación clave + nonce</mark>, y todo el diseño de WEP consiste en garantizar que eso ocurra: un nonce de 24 bits y una clave que no cambia nunca.

# El seed de WEP

En RC4 estándar la clave entra directamente en el KSA. <mark style="background: #FFB86CA6;">WEP no usa la clave: usa un **seed** formado anteponiendo el IV público a la clave secreta</mark>.

```text
Seed = IV (3 bytes) ‖ Clave (5 o 13 bytes)
```

| Variante | IV | Clave | Seed |
| -------- | -- | ----- | ---- |
| WEP-64 | 24 bits | 40 bits | 64 bits |
| WEP-128 | 24 bits | 104 bits | 128 bits |
| WEP-256 (propietario) | 24 bits | 232 bits | 256 bits |

Ahí está el fallo estructural, y merece la pena verlo con claridad: **los tres primeros bytes del seed viajan en claro en cada paquete**. El atacante conoce siempre una parte de la entrada del KSA, y esa parte cambia mientras el resto —la clave— permanece fijo.

<mark style="background: #FF5582A6;">Eso convierte cada paquete en una observación estadística sobre la misma clave</mark>. Con suficientes observaciones, las correlaciones entre el IV conocido y el primer byte del keystream permiten recuperar la clave byte a byte. Es lo que explotan FMS, KoreK y PTW — ver [[10 - Cracking - PTW, FMS y KoreK]].

# Reproducirlo en Python

`PyCryptodome` implementa RC4 en su módulo [`ARC4`](https://pycryptodome.readthedocs.io/en/latest/src/cipher/arc4.html):

```python
from Crypto.Cipher import ARC4
from Crypto.Random import get_random_bytes

IV = get_random_bytes(3)                                # 24 bits
clave40  = b'\x01\x02\x03\x04\x05'                      # 40 bits
clave104 = b'\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D'

seed64  = IV + clave40
seed128 = IV + clave104

cifrador = ARC4.new(seed64)
mensaje  = cifrador.encrypt(b'Wired Equivalent Privacy')

print('IV:', IV.hex())
print('Seed 64:', seed64.hex())
print('Cifrado:', mensaje.hex())
```

```shell-session
$ python3 seedgen.py
IV: 79234b
Seed 64: 79234b0102030405
Cifrado: 2963e936f0ab109ba29fdd19fff581d5e2e92d78169625 6e
```

Cada ejecución da un resultado distinto porque el IV cambia. <mark style="background: #FFB8EBA6;">Un objeto `ARC4` mantiene estado interno: si se llama a `encrypt()` dos veces, la segunda continúa el keystream donde lo dejó la primera</mark>, no lo reinicia. Para cifrar dos mensajes con el mismo seed hay que crear dos cifradores — un detalle que rompe el script si se pasa por alto.

# La colisión de IV, en la práctica

Si dos paquetes comparten IV, comparten keystream:

```python
from Crypto.Cipher import ARC4

seed = bytes.fromhex('79234b') + b'\x01\x02\x03\x04\x05'
c1 = ARC4.new(seed).encrypt(b'GET /admin HTTP/1.1')
c2 = ARC4.new(seed).encrypt(b'GET /index HTTP/1.1')

xor = bytes(a ^ b for a, b in zip(c1, c2))
print(xor.hex())        # == P1 ⊕ P2, sin rastro del keystream
```

Con 5.000 paquetes la probabilidad de encontrar una colisión ronda el 50 %, y con tráfico predecible —una petición ARP tiene estructura y longitud fijas— recuperar ambos textos del XOR es directo.

# Por qué RC4 no es el culpable

Conviene distinguirlo, porque es la lección transferible: <mark style="background: #8000E1A6;">RC4 tiene debilidades propias, pero WEP habría caído igual con un cifrado de flujo perfecto</mark>. Los errores son de protocolo:

| Decisión de WEP | Consecuencia |
| --------------- | ------------ |
| IV de 24 bits | Colisiones de keystream en horas |
| IV en claro y concatenado a la clave | Cada paquete es una observación sobre la clave |
| Clave estática | Las colisiones se acumulan indefinidamente |
| Sin descartar bytes iniciales del keystream | Expone el sesgo del KSA que explota FMS |

Ese último punto tiene remedio conocido: **RC4-drop[n]** descarta los primeros *n* bytes del keystream (típicamente 768 o 3072), donde se concentra el sesgo. WEP no descarta ninguno. TKIP intentó parchearlo mezclando la clave por paquete, y aun así acabó retirado.

La otra mitad del cifrado —el control de integridad que permite modificar paquetes sin la clave— es [[02 - El ICV CRC-32 y su linealidad]].
