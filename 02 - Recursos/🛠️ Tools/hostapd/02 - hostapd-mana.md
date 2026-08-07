---
tags:
  - Wi-Fi/Evil-Twin
  - Tipo/Arsenal
  - Pentesting/Explotacion
Descripción: "El fork de SensePost que añade KARMA, MANA y captura de credenciales EAP a hostapd, con su estado real y cuándo conviene EAPHammer en su lugar"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - AP falso con hostapd]]"
Nota siguiente: 
Area: "[[hostapd.base|hostapd]]"
---
---

`hostapd-mana` es el fork de **SensePost** que añade a `hostapd` tres cosas que el original no tiene: <mark style="background: #ADCCFFA6;">responder a las redes que buscan los clientes (KARMA/MANA), capturar credenciales EAP (WPE) y aceptar autenticaciones incorrectas</mark>.

| Dato | Valor |
| ---- | ----- |
| Repositorio | [`sensepost/hostapd-mana`](https://github.com/sensepost/hostapd-mana) |
| Actividad del repo | Activa (agosto de 2026) |
| **Última versión etiquetada** | **2.6.5, enero de 2019** |
| Base | `hostapd` 2.6 |

> [!warning]+ Repositorio activo, base antigua
> El repositorio recibe commits, pero está construido sobre `hostapd` **2.6** mientras el original va por la **2.11**. <mark style="background: #FF5582A6;">No soporta SAE, OWE ni 6 GHz</mark>. Para un AP falso WPA3 hay que usar `hostapd` de serie; `hostapd-mana` es la herramienta para 802.1X y para suplantar la PNL.

# Las opciones propias

| Opción | Valor por defecto | Función (según su propio `hostapd.conf`) |
| ------ | ----------------- | ---------------------------------------- |
| `enable_mana` | `0` | Activa el ataque MANA |
| `mana_loud` | **`0`** | `0` = anunciar a los dispositivos que buscan; `1` = **a todos** |
| `mana_macacl` | `0` | Extiende las ACL de MAC a las *probe responses* |
| `mana_wpe` | apagado | Captura de credenciales EAP |
| `mana_credout` | — | Fichero de salida de las credenciales |
| `mana_eapsuccess` | apagado | *"Allow clients to connect with incorrect credentials"* |

> [!important]+ MANA no es "el ataque de beacons KARMA"
> La descripción que circula —y que repite el módulo 305 de HTB— confunde ambas cosas. **KARMA** responde a *probe requests* dirigidas; **MANA** construye la lista de redes preferidas de cada cliente y responde de forma dirigida a cada uno. `mana_loud=1` es un tercer comportamiento: reemite **todas** las redes conocidas a **todos** los dispositivos.
>
> La distinción importa porque explica la vigencia: <mark style="background: #FFB86CA6;">KARMA se degradó cuando los clientes dejaron de emitir *probes* dirigidas</mark> (~2015, con la MAC aleatoria), y el modo *loud* existe precisamente como respuesta a eso. El contexto completo está en [[07 - Karma y MANA]].

# MANA sobre PSK

```config
interface=wlan1
driver=nl80211
ssid=CorpWiFi
hw_mode=g
channel=6

wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=cualquiercosa

enable_mana=1
mana_loud=0
```

Con `mana_loud=0` el AP sólo responde a los clientes que preguntan por una red concreta: es la variante quirúrgica y la que corresponde cuando el reconocimiento ya identificó qué SSID busca cada dispositivo.

`mana_loud=1` anuncia decenas de SSID a todo el mundo. Consigue clientes que `0` no conseguiría, y a cambio produce <mark style="background: #FF5582A6;">la firma exacta que busca la alerta `KARMAOUI`</mark> de Kismet. Se usa cuando no hay más remedio, no por defecto.

# MANA sobre Enterprise: captura de credenciales

```config
interface=wlan1
ssid=CorpWiFi
channel=6
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
mana_wpe=1
mana_credout=/opt/certs/credenciales.creds
mana_eapsuccess=1
```

`mana_eapsuccess=1` merece explicación: hace que el AP **acepte** al cliente aunque no pueda validar sus credenciales. Sirve para que el dispositivo complete la asociación y quede en la red del atacante, disponible para un MITM posterior, en vez de reintentar contra el AP legítimo y delatar el ataque.

## El fichero `eap_user`

```text
*        PEAP,TTLS,TLS,MD5,GTC
"t"      TTLS-PAP,GTC,TTLS-CHAP,TTLS-MSCHAP,TTLS-MSCHAPV2,MD5   "password"  [2]
```

La primera línea lista los métodos de **fase 1**; la segunda, los de **fase 2**, ordenados de más débil a más fuerte para que el cliente acepte el primero que soporte. `GTC` y `TTLS-PAP` entregan la contraseña en claro; `MSCHAPv2`, un reto crackeable con `hashcat -m 5500` — ver [[08 - Cracking de identidades WPA-Enterprise]].

## La salida

```text
MANA EAP Identity Phase 0: DOMINIO\usuario
MANA EAP GTC | DOMINIO\usuario:contraseña
```

El fichero de `mana_credout` marca el modo al principio de cada línea, separado por un tabulador, para poder filtrar con `grep` y `cut`.

# Certificados: la parte que más falla

La secuencia manual con `openssl` es donde más errores se cometen —encadenar `-keyout` sobre una clave ya generada, pasar `-passin` a una clave sin cifrar, declarar `private_key_passwd` para una clave sin contraseña—. La versión correcta, en tres pasos, está en [[07 - Karma y MANA]].

<mark style="background: #8000E1A6;">Si sólo se necesita el resultado, `eaphammer --cert-wizard` lo genera bien</mark> y evita todo ese terreno minado — ver [[00 - Introducción a EAPHammer]].

# Cuándo usar cada herramienta

| Objetivo | Herramienta |
| -------- | ----------- |
| AP falso WPA3 (SAE) u OWE | **`hostapd` de serie** |
| Control fino de la negociación EAP | `hostapd-mana` |
| Ataque Enterprise completo con certificados y crackeo | **`EAPHammer`** |
| Portal cautivo con plantillas | `wifiphisher`, `airgeddon` |
| Sólo capturar handshake o PMKID | `hcxdumptool` |

`hostapd-mana` sigue siendo la opción cuando hace falta escribir el `eap_user` a mano y ver exactamente qué se negocia. Para el flujo completo de un engagement, `EAPHammer` lo envuelve con mejor ergonomía y añade gestión de certificados, listas de alcance y crackeo integrado.
