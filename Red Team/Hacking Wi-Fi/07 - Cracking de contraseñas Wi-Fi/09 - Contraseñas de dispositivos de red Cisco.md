---
tags:
  - Seguridad/Contraseñas
  - Redes
  - Pentesting/Post-Explotacion
Descripción: "Qué credenciales guarda la configuración de un controlador o switch, cómo se craquea cada tipo de contraseña Cisco y por qué es un pivote habitual desde el Wi-Fi"
Fecha de actualización: 2026-08-04
Nota previa: "[[08 - Cracking de identidades WPA-Enterprise]]"
Nota siguiente: "[[10 - Detección y evasión del cracking Wi-Fi]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

Esta nota es la única del sub-tema que no trata de radio. Está aquí porque, en un engagement inalámbrico, <mark style="background: #ADCCFFA6;">la configuración de un controlador o de un switch es la vía más corta entre la Wi-Fi y el resto de la red</mark> — y porque HTB enseña a crackearla sin explicar nunca qué pinta en un módulo de Wi-Fi.

# Qué hay dentro que importe a un pentest inalámbrico

Un `show running-config` de un **WLC** (*Wireless LAN Controller*) o de un switch de acceso contiene, en texto:

| Elemento | Por qué importa |
| -------- | --------------- |
| PSK de cada WLAN | La contraseña que se estaba intentando crackear, servida sin GPU |
| **Secreto compartido RADIUS** | Permite montar un RADIUS falso creíble, o descifrar atributos |
| Credenciales de gestión | Acceso al controlador: todos los AP a la vez |
| SNMP community strings | Enumeración del parque completo |
| VLAN por SSID | El mapa de segmentación que el informe necesita |

<mark style="background: #FFB86CA6;">El secreto RADIUS es el premio silencioso</mark>: con él, un atacante deja de necesitar que el cliente acepte un certificado falso, porque puede hablar el protocolo como si fuera el autenticador legítimo.

Estos ficheros aparecen donde nadie los busca: recursos SMB de "Automatización" o "Backup", servidores TFTP de aprovisionamiento, adjuntos en tickets, y repositorios internos. El [[10 - Del Wi-Fi al dominio - la cadena|caso práctico del módulo corporativo]] llega exactamente así: un recurso compartido legible con un `.config` dentro.

# Los tipos de contraseña de Cisco

| Tipo | Algoritmo | Coste de romperlo | Recomendación oficial |
| ---- | --------- | ----------------- | --------------------- |
| `0` | **Texto plano** | Ninguno | No usar |
| `4` | SHA-256, **1 iteración, sin sal** | Inmediato | No usar. Retirado por Cisco |
| `5` | MD5-crypt, 1.000 iteraciones + sal | Medio | Sólo si no hay 6/8/9 |
| `6` | AES-128, **reversible** | Depende de la clave maestra | Sólo si hace falta reversibilidad |
| `7` | Cifrado Vigenère con clave publicada | **Inmediato, sin crackear** | No usar |
| `8` | PBKDF2-SHA256, 20.000 iteraciones, sal 80 bits | Alto | **Recomendado** |
| `9` | scrypt (`N=16384, r=1, p=1`), sal 80 bits | Alto | **Recomendado** |

El tipo 4 es el caso curioso: se introdujo en 2013 *para mejorar* el tipo 5 y salió peor, porque una sola pasada de SHA-256 sin sal es más débil que mil de MD5 con sal. Cisco lo retiró.

<mark style="background: #8000E1A6;">El tipo 7 no es cifrado, es ofuscación</mark>: usa una clave fija publicada desde los años noventa. Se revierte en local, sin diccionario ni GPU.

```shell-session
$ python3 ciscot7.py -d -p 08116C5D1A0E550516
$ python3 ciscot7.py -d -f configuracion.txt     # todas las de un fichero
```

> [!warning]+ No pegues configuraciones del cliente en descifradores web
> Circulan páginas que revierten el tipo 7 en el navegador. Enviar ahí una línea de configuración es <mark style="background: #FF5582A6;">entregar una credencial del cliente a un tercero</mark>, y suele violar el acuerdo de confidencialidad del engagement. El algoritmo cabe en veinte líneas de Python; no hay excusa para externalizarlo.

# Crackeo de los tipos que sí lo requieren

| Tipo | hashcat | John |
| ---- | ------- | ---- |
| `4` | `-m 5700` | `--format=Raw-SHA256` |
| `5` | `-m 500` | `--format=md5crypt` |
| `8` | `-m 9200` | `--format=pbkdf2-hmac-sha256` |
| `9` | `-m 9300` | `--format=scrypt` |

```shell-session
$ hashcat -m 5700 -a 0 hash.txt rockyou.txt
$ hashcat -m 9200 -a 0 hash.txt rockyou.txt -r best64.rule
$ john --format=md5crypt --fork=4 --wordlist=rockyou.txt hash.txt
```

Los formatos de John aceptan la forma nativa de Cisco: `Raw-SHA256` reconoce la cadena base64 de 43 caracteres del tipo 4 —con o sin el prefijo `$cisco4$`— y los formatos de tipo 8 y 9 detectan sus prefijos `$8$` y `$9$` (verificado en `rawSHA256_common_plug.c`, `pbkdf2_hmac_common.h` y `scrypt_fmt.c` de `openwall/john`).

> [!important]+ `-O` sí recorta aquí, al contrario que en Wi-Fi
> Con `-m 5700` y otros hashes rápidos, el kernel optimizado **limita la longitud del candidato** (típicamente a 31 caracteres). En `-m 22000` no ocurre: `module_22000.c` fija `pw_max = 63` sin variante optimizada. <mark style="background: #FFB8EBA6;">La regla "usa siempre `-O`" es falsa</mark>; depende del modo, y conviene comprobarlo antes de dar por agotado un espacio.

# El tipo 6 y su clave maestra

El tipo 6 cifra con AES-128 usando una **clave maestra** que se configura con `key config-key password-encrypt` y **no se guarda en el fichero**. Por eso un `.config` robado con contraseñas tipo 6 no entrega nada por sí solo.

```console
(config)# password encryption aes
(config)# key config-key password-encrypt MiClaveMaestra
```

Eso lo convierte en un objetivo distinto: no se craquea el hash, se busca la clave maestra —en un runbook, en una consola de gestión, en la memoria del dispositivo—. Si aparece, **todas** las contraseñas tipo 6 del parque se descifran de golpe.

# El pivote: reutilización de contraseñas

El valor real de estas credenciales rara vez es el propio dispositivo. Es que <mark style="background: #FFB86CA6;">la contraseña de un administrador de red suele repetirse en su cuenta de dominio</mark>. Un tipo 7 revertido en un segundo puede ser la contraseña de una cuenta con privilegios de replicación en Active Directory — el salto que cierra el caso práctico del módulo corporativo.

Por eso, al recuperar credenciales de un equipo de red, el paso inmediato es probarlas contra el dominio antes que contra el propio equipo:

```shell-session
$ nxc smb 172.16.10.72 -u admin_red -p 'Recuperada123' --shares
```

La técnica y sus límites están en [[04 - Password spraying, stuffing y defaults]]; el hallazgo se reporta como **reutilización de credenciales administrativas**, que es de impacto mucho mayor que "contraseña débil en un switch".

# Referencia

La NSA publicó en 2022 una guía específica de tipos de contraseña Cisco que sigue siendo la referencia citable en un informe: [*Cisco Password Types: Best Practices*](https://media.defense.gov/2022/Feb/17/2002940795/-1/-1/1/CSI_CISCO_PASSWORD_TYPES_BEST_PRACTICES_20220217.PDF). Su recomendación se resume en una línea: **tipo 8 o tipo 9, y nada más**.
