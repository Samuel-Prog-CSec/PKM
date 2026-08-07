---
tags:
  - Wi-Fi/WPA
  - Seguridad/Contraseñas
  - Pentesting/Explotacion
Descripción: "Qué dice exactamente cada campo de una línea hc22000, cómo leer el byte de message pair y por qué un par marcado como challenge puede darte una contraseña que la red rechaza"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Capturar el material criptográfico]]"
Nota siguiente: "[[03 - Herramientas de crackeo y su estado en 2026]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

El formato `hc22000` no es un detalle de fontanería entre `hcxpcapngtool` y `hashcat`: <mark style="background: #ADCCFFA6;">es donde está escrito **qué calidad tiene lo que has capturado**</mark>. El último byte de la línea decide si el resultado del crackeo es la contraseña de la red o sólo la que un cliente creía tener.

# La línea, campo a campo

```text
WPA*02*c38b3838fe073a8a8a6bf98700aab96d*fee1decea5e1*020000000300*537461724c696768742d42594f44*4f01c3df...*0103007502010900...*82
     │  │                                │            │            │                              │           │                 │
     │  │  MIC (16 B)                    │ MAC del AP │ MAC del STA│ ESSID en hexadecimal         │ ANonce    │ trama EAPOL     │ message pair
     │  └─ 01 = PMKID · 02 = EAPOL
     └─ marca de formato
```

| Campo | Contenido |
| ----- | --------- |
| `WPA` | Marca fija |
| `TYPE` | `01` para PMKID, `02` para un par EAPOL |
| `PMKID/MIC` | El verificador: el PMKID, o el MIC del mensaje que aporta la trama |
| `MACAP` / `MACSTA` | BSSID y MAC del cliente, sin separadores |
| `ESSID` | **En hexadecimal** — permite SSID con bytes no imprimibles |
| `NONCE` | El nonce que *no* viaja dentro de la trama EAPOL |
| `EAPOL` | La trama EAPOL completa en hex, con el otro nonce ya embebido |
| `MESSAGEPAIR` | El byte que describe de dónde salió todo |

El ESSID en hex se decodifica en un segundo y es la forma más rápida de comprobar que no estás crackeando una red fuera de alcance:

```shell-session
$ echo 537461724c696768742d42594f44 | xxd -r -p
StarLight-BYOD
```

Una línea de **PMKID** es más corta porque no hay nonces ni trama: `WPA*01*<PMKID>*<MACAP>*<MACSTA>*<ESSID>***`. Los tres asteriscos finales son los campos vacíos.

# El byte de message pair

Es un mapa de bits. Los **bits 0-2** dicen de qué mensajes se construyó el hash; los **bits 3-7** son banderas de calidad.

```text
0x82 = 1000 0010
       │      └── bits 0-2 = 010 → N3E2 (M2+M3, EAPOL de M2)
       └───────── bit 7 = 0x80 → replaycount sin verificar
```

## Bits 0-2: de dónde salió el hash

Un hash necesita cuatro cosas: `ANonce`, `SNonce`, `MIC` y la trama EAPOL. La trama ya lleva **uno** de los dos nonces embebido, así que sólo hay que aportar el otro. De ahí salen seis combinaciones, que colapsan en **tres hashes distintos** —uno por cada mensaje que puede aportar la trama—:

| Valor | Mensajes | Trama EAPOL de | Nonce externo de | Estado |
| ----- | -------- | -------------- | ---------------- | ------ |
| `0x00` | M1+M2 | M2 | M1 | **challenge** (por defecto) |
| `0x02` | M2+M3 | M2 | M3 | **authorized** (por defecto) |
| `0x03` | M2+M3 | M3 | M2 | authorized, sólo con `--all` |
| `0x04` | M3+M4 | M3 | M4 | authorized, sólo con `--all` |
| `0x01` | M1+M4 | M4 | M1 | authorized, sólo con `--all` |
| `0x05` | M3+M4 | M4 | M3 | authorized, sólo con `--all` |

> [!important]+ *Challenge* frente a *authorized*: la distinción que decide si el resultado vale
> `0x00` significa que sólo hicieron falta M1 y M2. <mark style="background: #FF5582A6;">El AP **no llegó a confirmar** que la contraseña fuera correcta</mark>, porque M3 nunca apareció. `0x02` y superiores implican M3 o M4, que sólo existen después de que **ambos** extremos validaran el MIC.
>
> En la práctica: un `0x00` capturado contra un [[01 - Capturar el material criptográfico|AP falso]] te da la passphrase que el **cliente** tiene guardada. Si el usuario la escribió mal, o el dispositivo arrastra el perfil de otra red homónima, crackeas una contraseña que la red real rechaza. Es exactamente el escenario del downgrade WPA3, donde el rogue AP nunca puede emitir un M3 válido.

Las tres últimas filas necesitan que M4 traiga un nonce distinto de cero. <mark style="background: #FFB8EBA6;">`IEEE 802.11i-2004 §8.5.3.4` exige que el nonce de M4 sea `0`</mark>, y la mayoría de implementaciones cumplen, así que en capturas reales sólo se ven `0x00` y `0x02`.

## Bits 3-7: banderas de calidad

| Bit | Hex | Significado |
| --- | --- | ----------- |
| 4 | `0x10` | Ataque *AP-less* (no hacen falta correcciones de nonce) |
| 5 | `0x20` | Router *little endian* detectado |
| 6 | `0x40` | Router *big endian* detectado |
| 7 | `0x80` | **Replaycount sin verificar** — correcciones de nonce necesarias |

El `0x80` es el que cuesta dinero. En el código de `hcxpcapngtool` se activa cuando hay un **hueco en los contadores de repetición** (`rcgap > 0`) entre los dos mensajes emparejados, o cuando detecta una anomalía de *endianness*. Traducción operativa: se perdieron tramas por el camino y no hay garantía de que el `ANonce` sea el que el AP usó realmente.

```shell-session
$ hashcat -m 22000 --nonce-error-corrections=8 hash.hc22000 wordlist.txt
```

<mark style="background: #8000E1A6;">Cada unidad de corrección multiplica el trabajo</mark>: hashcat prueba variaciones de los últimos bytes del nonce por cada candidata. El propio `hcxpcapngtool` sugiere el valor en su resumen (`REPLAYCOUNT gap (suggested NC)`). Un hash `0x80` con un `NC` alto puede tardar un orden de magnitud más que uno limpio — razón de sobra para volver a capturar en mejores condiciones antes que forzar la GPU.

# Leer el resumen de la conversión

`hcxpcapngtool` imprime un informe que dice más que cualquier `airodump-ng`:

```shell-session
$ hcxpcapngtool -o hash.hc22000 captura.pcapng
EAPOL M1 messages (total)................: 1
EAPOL M2 messages (total)................: 1
EAPOL M3 messages (total)................: 1
EAPOL M4 messages (total)................: 1
EAPOL M4 messages (zeroed NONCE).........: 1
EAPOL pairs (total)......................: 2
EAPOL pairs (best).......................: 1
EAPOL pairs written to 22000 hash file...: 1 (RC checked)
EAPOL M32E2 (authorized - ANONCE from M3): 1
```

Lo que hay que mirar, por orden:

1. **`EAPOL pairs written`** en `0` significa que no hay nada que crackear, por muchos M1 sueltos que aparezcan.
2. **`M32E2 (authorized)`** frente a **`M12E2 (challenge)`**: el primero vale, el segundo hay que verificarlo después.
3. **`REPLAYCOUNT gap`**: si es mayor que cero, habrá `0x80` y correcciones de nonce.
4. **`PMKID`**: si aparece, se puede crackear sin haber tocado a ningún cliente.

# Filtrar antes de crackear

Una captura de una hora en una oficina mezcla decenas de redes. `hcxhashtool` recorta el fichero al alcance autorizado:

```shell-session
$ hcxhashtool -i todo.hc22000 --essid=CorpWiFi -o alcance.hc22000
$ hcxhashtool -i todo.hc22000 --mac-ap=fee1decea5e1 -o alcance.hc22000
$ hcxhashtool -i todo.hc22000 --info=stdout            # inventario sin escribir nada
$ hcxhashtool -i todo.hc22000 --type=1 -o solo_pmkid.hc22000
```

<mark style="background: #FFB86CA6;">Este paso no es comodidad: es lo que impide crackear la contraseña del vecino del cliente</mark>. Junto con el filtro BPF de la captura, cierra el argumento de alcance en el informe.

La misma herramienta filtra **por calidad**, que es donde todo lo anterior se vuelve accionable:

| Filtro | Selecciona |
| ------ | ---------- |
| `--authorized` | Pares `M2M3`, `M3M4`, `M1M4`: el AP validó la contraseña |
| `--challenge` | Pares `M1M2` y `M1M2ROGUE`: sin confirmar por el AP |
| `--apless` | Sólo `M1M2ROGUE`, los obtenidos con AP falso |
| `--rc` / `--rc-not` | Con o sin replaycount verificado (el bit `0x80`) |

```shell-session
$ hcxhashtool -i alcance.hc22000 --authorized --rc -o prioritario.hc22000
```

Ese único comando deja el subconjunto que **merece la GPU primero**: pares confirmados por el AP y sin correcciones de nonce. El resto se ataca después, sabiendo que su resultado exige verificación.

Como bonus, `hcxpsktool` deriva candidatas triviales directamente del propio hash —ESSID, MAC, patrones de fabricante— y resuelve un porcentaje nada despreciable de redes domésticas antes de tocar un diccionario:

```shell-session
$ hcxpsktool -c hash.hc22000 --netgear --weakpass > candidatas.txt
```
