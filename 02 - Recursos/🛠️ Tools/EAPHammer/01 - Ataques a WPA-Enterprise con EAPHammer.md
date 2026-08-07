---
tags:
  - Wi-Fi/Enterprise
  - Pentesting/Explotacion
Descripción: "Negociación de métodos EAP, downgrade a GTC, captura de retos MSCHAPv2 y las opciones de crackeo integradas que HTB no menciona"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a EAPHammer]]"
Nota siguiente: "[[02 - Portales, Karma y ataques a PSK con EAPHammer]]"
Area: "[[EAPHammer.base|EAPHammer]]"
---
---

El ataque a WPA-Enterprise se reduce a una idea: <mark style="background: #ADCCFFA6;">si el cliente no valida el certificado del servidor RADIUS, el AP falso negocia el método EAP **más débil** que acepte y se queda con la credencial</mark>. `EAPHammer` automatiza esa negociación.

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi -c 6 --auth wpa-eap --negotiate weakest --creds
```

# `--negotiate`: la opción central

| Valor | Qué hace |
| ----- | -------- |
| `balanced` | **Valor por defecto.** Negocia PEAP-MSCHAPv2: reto crackeable, comportamiento creíble |
| `weakest` | Fuerza el método más débil disponible: **GTC o TTLS-PAP → contraseña en claro** |
| `speed` | Prioriza cerrar la negociación cuanto antes |
| `gtc-downgrade` | Downgrade específico a GTC |
| `manual` | Control total mediante `--phase-1-methods` y `--phase-2-methods` |

<mark style="background: #FFB86CA6;">`weakest` es a la vez el ataque y la prueba diagnóstica</mark>: si el cliente acepta bajar a GTC, hay dos hallazgos —no valida el certificado **y** no restringe métodos—. Si sólo acepta MSCHAPv2, el primero sigue en pie.

Para escenarios concretos, el control manual:

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi --auth wpa-eap --negotiate manual \
      --phase-1-methods PEAP,TTLS --phase-2-methods GTC,MSCHAPV2,TTLS-PAP --creds
```

El orden importa: se listan **de más débil a más fuerte** para que el cliente acepte el primero que soporte. `--eap-user-file` permite pasar directamente un fichero `hostapd.eap_user` propio.

# Qué se recoge

```text
mschapv2: Sat Sep 20 10:16:28 2025
    username:  jdorian
    challenge: aa:f2:44:ed:0b:4e:d3:b3
    response:  a93621d5c06394680afaad8dd8962600555155eaa051dec2
    hashcat NETNTLM: jdorian::::a93621d5...:aaf244ed0b4ed3b3

GTC: Sat Sep 20 10:16:51 2025
    username: jdorian
    password: <en claro>
```

La herramienta emite el reto ya formateado para `hashcat -m 5500` y para John, así que no hay que reconstruirlo a mano. El crackeo y por qué la longitud de la contraseña es irrelevante en MSCHAPv2 están en [[08 - Cracking de identidades WPA-Enterprise]].

# Crackeo integrado

Dos opciones que HTB no menciona y que ahorran el paso manual:

| Opción | Función |
| ------ | ------- |
| `--autocrack` | Lanza el crackeo automáticamente al capturar un reto |
| `--remote-cracking-rig` | Envía el material a un rig remoto |

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi --auth wpa-eap --creds --autocrack
```

> [!warning]+ `--remote-cracking-rig` saca material del entorno del cliente
> Enviar un reto MSCHAPv2 a una máquina externa es **exfiltrar material de autenticación del cliente**. Requiere autorización expresa en el RoE, exactamente igual que subir hashes a la nube — ver [[05 - Cracking en la nube y rigs]]. La comodidad de la opción no cambia el marco contractual.

# `--eap-spray`: probar credenciales contra el AP real

Además del AP falso, EAPHammer puede lanzar credenciales contra la red legítima:

```shell-session
$ sudo ./eaphammer --eap-spray --interface wlan0 --essid CorpWiFi \
      --user-list usuarios.txt --password 'Empresa2026!'
```

<mark style="background: #FF5582A6;">Cada intento fallido va contra Active Directory</mark>, así que aplica la disciplina de *password spraying*: una o dos contraseñas contra muchos usuarios, respetando el umbral de bloqueo y la ventana de reintentos del dominio. Recorrer un diccionario aquí bloquea cuentas y convierte el pentest en un incidente. La metodología está en [[10 - Password Spraying interno]].

# WPA3-Enterprise y PMF

| Opción | Función |
| ------ | ------- |
| `--pmf` | Configura Protected Management Frames en el AP falso |
| `--auth owe` | Levanta un AP con Enhanced Open |

Que el AP falso soporte `PMF` importa por credibilidad: <mark style="background: #FFB8EBA6;">un cliente configurado para una red WPA3-Enterprise —donde PMF es obligatorio— puede rechazar un AP que no lo anuncie</mark>. Ajustarlo al perfil de la red real forma parte de la suplantación.

Lo que **no** cambia con WPA3-Enterprise es el fallo de fondo: si el suplicante no valida el certificado, el ataque funciona igual. WPA3 endurece la gestión de tramas, no la confianza en el RADIUS.

# ESSID stripping

El repositorio documenta una técnica propia en `ESSIDStripping.md`: aprovechar cómo distintos sistemas operativos interpretan caracteres nulos o especiales dentro del SSID para que **el nombre que muestra el cliente no coincida con el que se anuncia**.

```shell-session
$ sudo ./eaphammer -i wlan1 -e "CorpWiFi" --essid-stripping --auth wpa-eap --creds
```

Permite que el usuario vea el nombre legítimo mientras el AP anuncia técnicamente otro, lo que ayuda a esquivar controles que comparan el SSID exacto contra una lista de redes autorizadas.

# La contramedida, en dos líneas

Todo lo anterior se cae si el suplicante tiene:

```ini
ca_cert="/etc/ssl/certs/CA-corporativa.pem"
domain_suffix_match="radius.empresa.com"
```

<mark style="background: #8000E1A6;">La primera línea sin la segunda es insuficiente</mark>: sin `domain_suffix_match`, un certificado válido emitido por **cualquier** CA de confianza engaña al cliente. Ambas se despliegan por GPO o MDM en un único sitio y protegen a toda la flota — el argumento completo, en [[08 - WPA2-Enterprise, evil twin y robo de credenciales]].
