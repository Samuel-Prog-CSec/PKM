---
tags:
  - Wi-Fi/WEP
  - Pentesting/Explotacion
Descripción: "Por qué usar CRC-32 como control de integridad permite modificar tráfico cifrado sin conocer la clave, con la demostración de la propiedad lineal"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - RC4 y la generación del keystream]]"
Nota siguiente: "[[03 - Cifrado y descifrado WEP paso a paso]]"
Area: "[[WEP.base|WEP]]"
---
---

WEP protege la integridad con un **`ICV`** (*Integrity Check Value*): un `CRC-32` calculado sobre el texto en claro, concatenado a él y cifrado junto con él. <mark style="background: #ADCCFFA6;">La elección es el segundo error de diseño de WEP, y el que permite manipular tráfico ajeno sin conocer la clave</mark>.

![Construcción del ICV: al texto en claro del paquete se le añade su checksum CRC-32 antes de cifrar](https://academy.hackthebox.com/storage/modules/185/Diagrams/wep_2.png)

# CRC-32 detecta ruido, no ataques

`CRC-32` se diseñó para detectar errores de transmisión: bits que se voltean por interferencia. Su polinomio generador es

$$g(x) = x^{32} + x^{26} + x^{23} + x^{22} + x^{16} + x^{12} + x^{11} + x^{10} + x^{8} + x^{7} + x^{5} + x^{4} + x^{2} + x + 1$$

Cumple ese cometido perfectamente. <mark style="background: #FFB8EBA6;">Lo que no es, ni pretende ser, es una función criptográfica</mark>: no tiene clave, cualquiera puede calcularla, y —lo decisivo— es **lineal**.

```python
import zlib
print(zlib.crc32(b'Something Sensitive'))   # 2950664974
```

# La propiedad lineal

`CRC-32` es lineal respecto al XOR:

$$\text{CRC}(x \oplus y) = \text{CRC}(x) \oplus \text{CRC}(y) \oplus \text{CRC}(0)$$

Se comprueba en tres líneas:

```python
import zlib
x  = b'AAAAAAAA'
y  = b'\x00\x00\x00\x01\x00\x00\x00\x00'
xy = bytes(a ^ b for a, b in zip(x, y))

izq = zlib.crc32(xy)
der = zlib.crc32(x) ^ zlib.crc32(y) ^ zlib.crc32(b'\x00' * len(x))
print(izq, der, izq == der)
```

```text
1154954682 1154954682 True
```

> [!important]+ La identidad exige longitudes iguales
> El término `CRC(0)` no es "el CRC del byte cero": es <mark style="background: #FFB8EBA6;">el CRC de una cadena de ceros **de la misma longitud** que `x` e `y`</mark>. Aparece porque el CRC-32 estándar no es lineal puro — usa un valor inicial de `0xFFFFFFFF` y un XOR final del mismo valor, y ese término lo cancela. Comparar cadenas de longitudes distintas rompe la igualdad, y es el fallo habitual al implementar el ataque a mano.

# Por qué eso rompe WEP

En WEP el texto cifrado es

$$C = (P \parallel \text{CRC}(P)) \oplus KS$$

Supongamos que un atacante quiere convertir $P$ en $P' = P \oplus \Delta$, con $\Delta$ elegido por él, **sin conocer $KS$ ni la clave**. Le basta con calcular:

$$C' = C \oplus (\Delta \parallel \text{CRC}(\Delta) \oplus \text{CRC}(0))$$

Al descifrar, el receptor obtiene $P \oplus \Delta$ y un ICV que **valida correctamente**, porque la linealidad garantiza que el checksum se ha ajustado solo.

<mark style="background: #FFB86CA6;">El resultado: cualquiera que capte un paquete WEP puede modificar su contenido de forma controlada y volver a inyectarlo, y el AP lo aceptará como legítimo</mark>. El cifrado sigue intacto; la integridad no existe.

## Verlo funcionar

El ataque completo cabe en unas líneas, usando el `rc4()` de [[01 - RC4 y la generación del keystream]]:

```python
import zlib
le = lambda n: n.to_bytes(4, 'little')

# --- Emisor legítimo ---
IV, CLAVE = bytes.fromhex('5d7eb7'), bytes([1, 2, 3, 4, 5])
P = b'Transferir 100 EUR'
C = rc4(IV + CLAVE, P + le(zlib.crc32(P)))

# --- Atacante: no conoce la clave ni el keystream ---
D = bytearray(len(P))
for k in range(3):                       # cambiar "100" por "900"
    D[11 + k] = b'900'[k] ^ b'100'[k]    # delta = P ⊕ P'
corr  = le(zlib.crc32(bytes(D)) ^ zlib.crc32(b'\x00' * len(P)))
C_mod = bytes(a ^ b for a, b in zip(C, bytes(D) + corr))

# --- Receptor ---
M  = rc4(IV + CLAVE, C_mod)
Pr, icv = M[:-4], M[-4:]
print(Pr, le(zlib.crc32(Pr)) == icv)
```

```text
b'Transferir 900 EUR' True
```

<mark style="background: #FF5582A6;">El texto cambió a voluntad del atacante y el ICV valida</mark>. En ningún momento se conocieron la clave ni el keystream: sólo se aprovechó que el checksum se puede corregir a ciegas.

Nótese que el delta se aplica **byte a byte sobre posiciones conocidas** — el atacante necesita saber *dónde* está el campo que quiere cambiar, no su valor cifrado. En tráfico real eso es fácil: las cabeceras IP, ARP y LLC/SNAP están en desplazamientos fijos.

# Qué habilita en la práctica

| Ataque | Cómo usa la linealidad |
| ------ | ---------------------- |
| **Bit-flipping** | Modificar campos concretos —una IP de destino, un puerto— manteniendo el ICV válido |
| **[[07 - KoreK ChopChop]]** | Truncar un byte, ajustar el ICV y deducir su valor por la respuesta del AP |
| **[[06 - Ataque de fragmentación]]** | Construir paquetes válidos con sólo 8 bytes de keystream conocido |
| **Reinyección** | Reenviar tráfico modificado para forzar la generación de nuevos IVs |

ChopChop merece detalle porque es el uso más elegante: se corta el último byte del texto cifrado, se corrige el ICV suponiendo un valor para ese byte y se envía el paquete al AP. <mark style="background: #FF5582A6;">Si el AP lo acepta, la suposición era correcta</mark> — el AP actúa como oráculo de descifrado sin saberlo. Repitiendo byte a byte se descifra el paquete completo. **Sin conocer la clave en ningún momento.**

# Cómo se hace bien

La lección que WEP dejó para todo diseño posterior: <mark style="background: #8000E1A6;">la integridad necesita **una clave**</mark>. Un checksum sin clave lo puede recalcular el atacante.

| Esquema | Integridad | Nota |
| ------- | ---------- | ---- |
| WEP | `CRC-32` sin clave | Roto |
| WPA/TKIP | `Michael` (MIC con clave) | Débil, con contramedidas que son un DoS |
| WPA2 | `CBC-MAC` (parte de CCMP) | Sólido |
| WPA3 | `GMAC` / `CCM` | Sólido |

`Michael` fue el parche de compatibilidad: aporta una clave, pero es tan débil que el estándar obliga a cortar el servicio 60 segundos ante dos fallos de MIC en un minuto — lo que a su vez es un vector de denegación de servicio trivial ([[00 - MDK4]], módulo `m`). CCMP resolvió el problema de verdad al integrar cifrado y autenticación en una sola construcción.

> [!important]+ El patrón se repite fuera de Wi-Fi
> "Cifrar sin autenticar" y "usar un checksum donde hace falta un MAC" siguen apareciendo en auditorías de aplicaciones: cookies cifradas sin firmar, tokens con CRC, protocolos propietarios con AES-CBC y sin MAC. El resultado es el mismo — *padding oracle*, *bit-flipping*, manipulación controlada del texto en claro. Reconocer el patrón en WEP ayuda a reconocerlo en un binario de 2026.

Con las dos piezas —keystream e ICV— ya se puede reconstruir el algoritmo completo: [[03 - Cifrado y descifrado WEP paso a paso]].
