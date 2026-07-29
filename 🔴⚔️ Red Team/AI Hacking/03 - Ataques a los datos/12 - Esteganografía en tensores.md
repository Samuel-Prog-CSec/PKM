---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "La tensor steganography esconde información dentro de los parámetros numéricos de un modelo"
Fecha de actualización: 2026-07-28
Nota previa: "[[11 - Pickle y la deserialización insegura de modelos]]"
Nota siguiente: "[[13 - Ejecución del ataque de esteganografía]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

<mark style="background: #ADCCFFA6;">La `tensor steganography` esconde información dentro de los parámetros numéricos de un modelo.</mark> Un modelo tiene millones —a veces miles de millones— de números en coma flotante, y alterar los suficientes de forma imperceptible da una capacidad de almacenamiento notable.

Complementa al [[11 - Pickle y la deserialización insegura de modelos|`pickle`]]: uno da el **vector de ejecución**, el otro el **medio de transporte**. Juntos producen un fichero de modelo que funciona con normalidad y lleva dentro un payload que nadie ve.

# Dónde se esconde — el `state_dict`

Las redes aprenden ajustando **pesos** (asociados a conexiones) y **sesgos** (asociados a neuronas). Se almacenan en **tensores**: arrays multidimensionales que generalizan vectores (1D) y matrices (2D). Los pesos entre dos capas densas son un tensor 2D; los filtros de una capa convolucional, uno 4D.

El conjunto completo de esos tensores es el **`state_dict`**, y es lo que se guarda al serializar un modelo. Ahí es donde se esconde el payload.

# Anatomía de un `float32`

Los parámetros se almacenan normalmente como `float32` según el estándar **IEEE 754**. Cada número usa 32 bits repartidos en tres campos:

| Campo | Bits | Función |
| - | - | - |
| **Signo** ($s$) | 31 | Positivo (`0`) o negativo (`1`) |
| **Exponente** ($E_{stored}$) | 30–23 | Escala del número, con un sesgo de 127 |
| **Mantisa** ($m$) | 22–0 | Precisión — los dígitos significativos |

$$\text{Valor} = (-1)^s \times (1.m) \times 2^{(E_{stored} - \text{bias})}$$

Tomando `0.15625` como ejemplo: en binario es $0.00101_2$, normalizado $1.01_2 \times 2^{-3}$. De ahí salen los tres campos — signo `0`, exponente $-3 + 127 = 124 =$ `01111100`, mantisa `01000000000000000000000`:

![Estructura de bits IEEE 754 float32 para 0.15625, con los campos de signo, exponente y mantisa](https://academy.hackthebox.com/storage/modules/302/ieee_754.png)

# Por qué los bits menos significativos

La mantisa ocupa los 23 bits de menor peso. Los de la izquierda (bit 22) aportan mucho al valor; los de la derecha (bit 0), casi nada. La comparación lo deja claro:

**Invertir el bit 0** (el LSB) de `0.15625`:

![Cambio al invertir el bit 0: 0.15625 pasa a 0.156250014901161](https://academy.hackthebox.com/storage/modules/302/lsb_flip.png)

El valor pasa a `0.156250014901161` — un cambio de **$1.49 \times 10^{-8}$**.

**Invertir el bit 22** (el MSB de la mantisa):

![Cambio al invertir el bit 22: 0.15625 pasa a 0.21875](https://academy.hackthebox.com/storage/modules/302/msb_flip.png)

El valor pasa a `0.21875` — un cambio de **0,0625**, más de **seis órdenes de magnitud** mayor que el del LSB ($0{,}0625 / 1{,}49	imes10^{-8} pprox 4{,}2	imes10^{6}$).

<mark style="background: #8000E1A6;">Un cambio de $10^{-8}$ en un peso está por debajo del ruido de entrenamiento: es indistinguible de la variación que produce ejecutar el mismo entrenamiento con otra semilla, otro orden de lotes u otro hardware.</mark> Ese margen es exactamente lo que hace viable la técnica.

# Las herramientas — `encode_lsb` y `decode_lsb`

Se necesita el módulo `struct` para pasar de `float` a su representación en bytes y viceversa, que es lo que permite manipular bits.

## Codificar

```python
import struct

def encode_lsb(tensor_orig: torch.Tensor, data_bytes: bytes, num_lsb: int) -> torch.Tensor:
    if tensor_orig.dtype != torch.float32:
        raise TypeError("Tensor must be float32.")
    if not 1 <= num_lsb <= 8:
        raise ValueError("num_lsb must be 1-8. More bits increase distortion.")

    tensor = tensor_orig.clone().detach()
    tensor_flat = tensor.flatten()
    n_elements = tensor.numel()

    # Prefijo de longitud: 4 bytes, entero sin signo big-endian
    data_to_embed = struct.pack(">I", len(data_bytes)) + data_bytes

    total_bits_needed = len(data_to_embed) * 8
    capacity_bits = n_elements * num_lsb
    if total_bits_needed > capacity_bits:
        raise ValueError(f"Tensor too small: needs {total_bits_needed} bits, capacity {capacity_bits}.")
    ...
```

El núcleo del bucle, para cada elemento del tensor:

```python
    # float -> representación entera de 32 bits
    packed_float = struct.pack(">f", original_float)
    int_representation = struct.unpack(">I", packed_float)[0]

    mask = (1 << num_lsb) - 1          # máscara de los num_lsb bits bajos

    # ... se acumulan num_lsb bits del payload en data_bits_for_float ...

    cleared_int = int_representation & (~mask)          # borrar los LSB
    new_int_representation = cleared_int | data_bits_for_float   # insertar los datos

    # de vuelta a float
    new_float = struct.unpack(">f", struct.pack(">I", new_int_representation))[0]
    tensor_flat[element_index] = new_float
```

## El bucle, trazado sobre un solo peso

El fragmento anterior tiene un `# ... se acumulan ...` que esconde justo la parte que importa. Traza completa de **un elemento**, retomando el `0.15625` de la sección de IEEE 754 y con `num_lsb = 2`:

```text
w                = 0.15625
int32            = 0x3E200000   →  0011 1110 0010 0000 0000 0000 0000 0000
                                                                        ^^ los 2 LSB

mask             = (1 << 2) - 1 = 0b11
cleared_int      = 0x3E200000 & ~0b11 = 0x3E200000     (ya terminaba en 00)

bits del payload = 0b01
new_int          = 0x3E200000 | 0b01  = 0x3E200001

w'               = 0.1562500149011612      delta = 1,49e-08
```

Y con los dos bits a `1`, que es el peor caso posible para un solo elemento:

```text
bits del payload = 0b11
new_int          = 0x3E200003
w'               = 0.15625004470348358     delta = 4,47e-08
```

<mark style="background: #FF5582A6;">Ese `delta` de como mucho $4{,}47\times10^{-8}$ es el coste total de esconder 2 bits en un peso.</mark> Un tensor de un millón de elementos absorbe 250 KB de payload con esa distorsión por valor — completamente invisible frente al ruido de entrenamiento.

Comprobarlo en tres líneas:

```python
import struct
w = 0.15625
i = struct.unpack(">I", struct.pack(">f", w))[0]      # 0x3E200000
w2 = struct.unpack(">f", struct.pack(">I", (i & ~0b11) | 0b11))[0]
print(w2, w2 - w)        # 0.15625004470348358  4.470348358154297e-08
```

Tres decisiones de diseño que conviene entender:

- **El prefijo de longitud de 4 bytes** (`struct.pack(">I", data_len)`) va delante del payload. Sin él, el decodificador no sabría dónde termina el dato y dónde empiezan los bits originales del modelo. <mark style="background: #FFB86CA6;">Es también la firma más detectable de la técnica</mark>: los primeros 32 bits del canal LSB contienen un entero razonable en lugar de ruido.
- **`num_lsb` entre 1 y 8** es el parámetro de compromiso: más bits por elemento = más capacidad y menos elementos tocados, pero más distorsión por elemento. Con `num_lsb=2` (el valor del lab) cada peso aporta 2 bits y la alteración sigue siendo despreciable.
- **`clone().detach()`** trabaja sobre una copia, sin tocar el tensor original ni arrastrar el grafo de gradientes.

## Decodificar

```python
def decode_lsb(tensor_modified: torch.Tensor, num_lsb: int) -> bytes:
    tensor_flat = tensor_modified.flatten()
    shared_state = {"element_index": 0}

    def get_bits(count: int) -> list[int]:
        bits = []
        while len(bits) < count and shared_state["element_index"] < tensor_flat.numel():
            v = tensor_flat[shared_state["element_index"]].item()
            int_repr = struct.unpack(">I", struct.pack(">f", v))[0]
            lsb_data = int_repr & ((1 << num_lsb) - 1)
            for i in range(num_lsb):
                bits.append((lsb_data >> (num_lsb - 1 - i)) & 1)
                if len(bits) == count:
                    break
            shared_state["element_index"] += 1
        return bits

    length_bits = get_bits(32)                       # primero, la longitud
    payload_len_bytes = 0
    for bit in length_bits:
        payload_len_bytes = (payload_len_bytes << 1) | bit

    payload_bits = get_bits(payload_len_bytes * 8)   # luego, el payload
    ...
```

El `shared_state` con `nonlocal` mantiene la posición entre las dos llamadas a `get_bits`, de forma que la segunda continúa donde terminó la primera. Es lo que permite leer primero la cabecera y después exactamente el número de bits que anuncia.

# Capacidad

Con `num_lsb` bits por elemento, un tensor de $N$ elementos almacena $N \times \text{num\_lsb}$ bits, menos los 32 de la cabecera. Para hacerse una idea:

| Tensor | Elementos | Capacidad con `num_lsb=2` |
| - | - | - |
| Capa densa 512×512 | 262.144 | ~64 KB |
| Capa densa 4096×4096 | 16,7 M | ~4 MB |
| Modelo de 7B parámetros | 7×10⁹ | **~1,7 GB** |

<mark style="background: #FF5582A6;">Un modelo grande esconde binarios completos sin despeinarse.</mark> El payload del lab —un reverse shell en Python— son unos pocos KB, y cabe en una sola capa.

Por eso el ataque elige una capa grande como portadora (`large_layer.weight` en el lab): cuanto mayor el tensor, menor la **densidad de modificación** y más difícil que un análisis estadístico note nada.
