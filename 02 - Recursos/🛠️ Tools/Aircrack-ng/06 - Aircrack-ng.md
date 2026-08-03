---
tags:
  - Wi-Fi
  - Seguridad/Contraseñas
  - Pentesting/Explotacion
Descripción: "Recuperar claves WEP con PTW y WPA/WPA2 por diccionario, y por qué conviene delegar el cracking WPA a hashcat"
Fecha de actualización: 2026-08-01
Nota previa: "[[05 - Airdecap-ng]]"
Nota siguiente: 
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`aircrack-ng` es la pieza que convierte una captura en una clave</mark>. Trabaja **offline**, sobre ficheros, sin volver a tocar la red: una vez se tiene el `.cap`, el resto se puede hacer a kilómetros del objetivo y días después.

Recupera dos cosas muy distintas con dos mecanismos que no se parecen en nada: la clave **WEP** por criptoanálisis estadístico, y la frase de paso **WPA/WPA2** por fuerza bruta con diccionario.

# WEP: criptoanálisis, no fuerza bruta

WEP no se rompe probando claves: se rompe acumulando IVs y explotando el sesgo estadístico de RC4. Cuantos más IVs, más determinado queda cada byte de la clave.

```shell-session
$ aircrack-ng HTB-01.cap

  [00:00:17] Tested 1741 keys (got 566693 IVs)

  KB    depth   byte(vote)
   0    0/  1   EB( 50) 11( 20) 71( 20) 0D( 12) 10( 12)
   1    1/  2   C8( 31) BD( 18) F8( 17) E6( 16) 35( 15)
   2    0/  3   7F( 31) 74( 24) 54( 17) 1C( 13) 73( 13)

  KEY FOUND! [ EB:C8:7F:3A:03:D0:AF:DA:F6:8D:A5:E2:C7 ]
  Decrypted correctly: 100%
```

Cada fila es un byte de la clave. `depth` indica cuántas alternativas se están explorando: `0/ 1` significa que el candidato principal domina, `1/ 2` que hay ambigüedad. Los votos entre paréntesis son la fuerza estadística de cada candidato.

> [!warning]+ HTB usa `-K`, el método antiguo, y eso multiplica por diez los IVs necesarios
> El módulo 222 lanza `aircrack-ng -K HTB.ivs` sin explicar qué hace esa bandera. <mark style="background: #FF5582A6;">`-K` invoca **KoreK**, el método de la versión 0.x; el método por defecto desde la 1.0 es **PTW**, que es sustancialmente mejor</mark> ([documentación oficial](https://www.aircrack-ng.org/doku.php?id=aircrack-ng)):
>
> | Método | IVs para 64 bits | IVs para 128 bits |
> | ------ | ---------------- | ----------------- |
> | **PTW** (por defecto) | ~20.000 | ~40.000 |
> | KoreK (`-K`) | 250.000+ | 1.500.000+ |
>
> La diferencia práctica es entre unos minutos de captura y varias horas de reinyección. **No usar `-K`** salvo que PTW falle, que ocurre cuando la captura no tiene suficientes paquetes ARP (PTW los necesita; KoreK acepta cualquier IV) o cuando la clave es de 152/256 bits.

Se puede ahorrar espacio guardando sólo los IVs en lugar de la captura completa, con `airodump-ng --ivs`. La contrapartida: un `.ivs` no sirve para descifrar tráfico después con [[05 - Airdecap-ng]] ni para nada que no sea crackear.

# WPA/WPA2: diccionario

Aquí no hay criptoanálisis. La única vía es derivar la `PMK` de cada candidato con `PBKDF2-SHA1` (4096 iteraciones, con el ESSID como sal), calcular el `MIC` y compararlo con el capturado.

```shell-session
$ aircrack-ng HTB.cap -w /usr/share/wordlists/rockyou.txt -e CyberCorp

  Reading packets, please wait...
  #  BSSID              ESSID          Encryption
  1  2D:0C:51:12:B2:33  CyberCorp      WPA (1 handshake, with PMKID)

  [00:00:34] 80234/14344392 keys tested (2345.32 k/s)
  KEY FOUND! [ Verano2026! ]

  Master Key     : A2 88 FC F0 CA AA CD A9 A9 F5 86 33 FF 35 E8 99 ...
  EAPOL HMAC     : A4 62 A7 02 9A D5 BA 30 B6 AF 0D F3 91 98 8E 45
```

| Opción | Uso |
| ------ | --- |
| `-w` | Diccionario. Acepta varios separados por comas, o `-` para leer de stdin |
| `-b` | BSSID objetivo, para no elegir a mano |
| `-e` | ESSID. **Obligatorio** — entra en la derivación de la `PMK` |
| `-a 2` | Forzar modo WPA |
| `-S` | Benchmark de velocidad |
| `-j` / `-J` | Exportar a formato hashcat (`HCCAPX`, **legado**) |

<mark style="background: #FFB8EBA6;">Como el ESSID es la sal, una `PMK` no es reutilizable entre redes</mark>: la misma contraseña en dos SSID distintos da claves distintas. Es lo que impide las rainbow tables genéricas — y lo que hace que sí funcionen contra SSID por defecto muy comunes (`vodafone1234`, `MOVISTAR_XXXX`), donde sí compensa precomputar con `airolib-ng`.

## Qué hace falta en la captura

La documentación oficial dice que sirven los pares de mensajes EAPOL **(2,3)** o **(3,4)**. En la práctica hay una vía mejor:

- **Con `PMKID`** (redes con 802.11r) basta el mensaje 1. No hace falta ningún cliente: se pide al AP y responde. Es la vía preferente hoy.
- **`hashcat` en modo `22000`** acepta también el par **(1,2)**, que es el más fácil de capturar tras una desautenticación.

Verificar qué hay antes de irse del sitio:

```shell-session
$ hcxpcapngtool -o HTB.22000 HTB-01.cap
```

# El cracking de WPA no se hace con aircrack-ng

> [!important]+ Dos o tres órdenes de magnitud de diferencia
> `aircrack-ng` **sólo usa CPU**. Su benchmark lo deja claro:
> ```shell-session
> $ aircrack-ng -S
> 1628.101 k/s
> ```
> <mark style="background: #FF5582A6;">`k/s` significa ***keys per second***, no «kilo-claves por segundo»</mark>. Son **1.628 contraseñas por segundo**, no 1,6 millones — verificado en [`aircrack-ng.c`](https://github.com/aircrack-ng/aircrack-ng/blob/master/src/aircrack-ng/aircrack-ng.c), donde `ksec = nb_kprev / delta` cuenta claves y se imprime con la etiqueta `k/s`. La cifra es coherente: derivar una `PMK` exige `PBKDF2-SHA1` con 4096 iteraciones, y unos pocos miles por segundo es lo que da una CPU moderna con SIMD.
>
> Frente a eso, `hashcat -m 22000` sobre una GPU de gama alta se mueve en el orden de **cientos de miles a millones** de candidatos por segundo. La diferencia es de dos a tres órdenes de magnitud: lo que en CPU son días, en GPU son minutos.
>
> El flujo correcto es:
> ```shell-session
> $ hcxpcapngtool -o CyberCorp.22000 HTB-01.cap
> $ hashcat -m 22000 CyberCorp.22000 /usr/share/wordlists/rockyou.txt -r best64.rule
> ```
> Las banderas `-j`/`-J` de `aircrack-ng` producen `HCCAPX`, el formato del **modo 2500 ya deprecado**. Usar `hcxpcapngtool` y el modo `22000`, que además admite `PMKID` y EAPOL en el mismo fichero. Ver [[00 - Introducción a Hashcat]] y [[01 - Wordlists y reglas personalizadas]].

`aircrack-ng` sigue siendo la opción razonable en tres casos: **WEP** (donde hashcat no compite porque no es fuerza bruta), una **comprobación rápida** contra un diccionario corto en el propio portátil, y **verificar que la captura es válida** antes de recogerla.

# Diccionarios que funcionan en Wi-Fi

Las claves de Wi-Fi tienen un mínimo de 8 caracteres impuesto por el estándar, lo que descarta buena parte de cualquier diccionario genérico:

```shell-session
$ awk 'length($0) >= 8 && length($0) <= 63' rockyou.txt > wifi.txt
```

Y donde más se acierta es en lo específico del objetivo: nombre de la empresa con años y sufijos, la dirección, el SSID mismo con variaciones, y sobre todo <mark style="background: #8000E1A6;">los patrones de clave por defecto del ISP</mark>, que en muchos operadores se derivan del BSSID o del SSID con un algoritmo conocido. Generarlos con reglas es más rentable que cualquier diccionario grande — [[01 - Wordlists y reglas personalizadas]].
