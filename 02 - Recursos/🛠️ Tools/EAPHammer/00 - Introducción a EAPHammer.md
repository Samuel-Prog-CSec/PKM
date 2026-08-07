---
tags:
  - Wi-Fi/Enterprise
  - Tipo/Introduccion
  - Pentesting/Explotacion
Descripción: "Qué automatiza EAPHammer frente a montar hostapd a mano, cómo se prepara la infraestructura de certificados y el detalle del OpenSSL débil que compila"
Fecha de actualización: 2026-08-04
Nota previa: 
Nota siguiente: "[[01 - Ataques a WPA-Enterprise con EAPHammer]]"
Area: "[[EAPHammer.base|EAPHammer]]"
---
---

<mark style="background: #ADCCFFA6;">`EAPHammer` empaqueta el AP falso, el servidor RADIUS, la infraestructura de certificados y la captura de credenciales en una sola herramienta</mark>. Es la vía práctica para atacar redes WPA-Enterprise sin ensamblar a mano `hostapd`, `FreeRADIUS` y `openssl` — el montaje manual, con sus errores típicos, está en [[07 - Karma y MANA]].

| Dato | Valor |
| ---- | ----- |
| Repositorio | [`s0lst1c3/eaphammer`](https://github.com/s0lst1c3/eaphammer) |
| Versión | **v1.14.1** (septiembre de 2024) |
| Autor | Gabriel Ryan (`@s0lst1c3`), autor del ataque **MANA** *indirect wireless pivot* |
| Base | `hostapd-wpe` extendido |

# Instalación

```shell-session
$ git clone https://github.com/s0lst1c3/eaphammer
$ cd eaphammer && sudo ./kali-setup        # o ./parrot-setup
```

El script de instalación compila sus propias dependencias, y una de ellas merece atención.

> [!warning]+ Compila un OpenSSL deliberadamente débil
> Su configuración fija `openssl_version = '1.1.1a'` con las opciones `enable-ssl2 enable-ssl3 enable-ssl3-method enable-des enable-rc4 enable-weak-ssl-ciphers`.
>
> Es **intencionado**: para negociar métodos EAP antiguos y cifrados débiles hace falta una pila TLS que los soporte, y las distribuciones modernas los eliminaron. Pero implica que <mark style="background: #FF5582A6;">la caja de ataque acaba con una copia de OpenSSL 1.1.1a —de 2018, con vulnerabilidades conocidas— compilada localmente</mark>. Se enlaza estáticamente contra la herramienta, no sustituye al OpenSSL del sistema, pero es un motivo más para que la caja de ataque sea desechable y no un equipo de trabajo.

# La infraestructura de certificados

Un AP falso Enterprise necesita un certificado de servidor. `--cert-wizard` genera la CA y el certificado firmado sin los errores de encadenamiento típicos del proceso manual:

```shell-session
$ sudo ./eaphammer --cert-wizard
```

Pide país, provincia, localidad, organización, unidad, correo y `CN`. <mark style="background: #FFB86CA6;">Esos campos no son burocracia: son lo que ve el usuario si su cliente muestra un aviso</mark>. Rellenarlos imitando el certificado legítimo —visible en una captura del EAP real— es la diferencia entre que alguien pulse «confiar» o no.

Para control fino, la herramienta acepta los parámetros directamente:

| Opción | Función |
| ------ | ------- |
| `--cn`, `--org`, `--org-unit`, `--country`, `--state`, `--locale`, `--email` | Campos del sujeto |
| `--ca-cert`, `--ca-key`, `--ca-key-passwd` | Reutilizar una CA existente |
| `--server-cert`, `--private-key`, `--private-key-passwd` | Certificado de servidor propio |
| `--self-signed` | Certificado autofirmado sin CA |
| `--key-length`, `--algorithm` | Tamaño y algoritmo de clave |
| `--not-before`, `--not-after` | Ventana de validez |

`--not-before` y `--not-after` sirven para un detalle de credibilidad que casi nadie cuida: un certificado emitido **hoy** para una infraestructura corporativa que existe desde hace años es sospechoso si alguien lo mira.

# Modos de operación

| Familia | Opción principal | Objetivo |
| ------- | ---------------- | -------- |
| **WPA-Enterprise** | `--auth wpa-eap` | Credenciales de dominio — ver [[01 - Ataques a WPA-Enterprise con EAPHammer]] |
| **WPA-PSK / abierta** | `--auth wpa-psk`, `--auth open` | Portal cautivo, hostil, PMKID |
| **Karma / MANA** | `--karma`, `--mana`, `--loud` | Suplantar redes de la PNL |
| **Portal cautivo** | `--captive-portal`, `--hostile-portal` | Phishing y entrega de carga |
| **WPA3 transición** | `--transition-ssid`, `--transition-bssid` | Downgrade — ver [[05 - WPA3 en modo transición y downgrade]] |

# Configuración básica de un AP

```shell-session
$ sudo ./eaphammer --interface wlan1 --essid CorpWiFi --auth wpa-eap --creds
```

| Opción | Función |
| ------ | ------- |
| `--interface`, `-i` | Interfaz que hospeda el AP |
| `--essid`, `-e` | Nombre de la red a suplantar |
| `--bssid`, `-b` | BSSID concreto (suplantación de MAC) |
| `--channel`, `-c` | Canal. **Debe coincidir con el del AP real** |
| `--auth` | `wpa-eap`, `wpa-psk`, `open`, `owe` |
| `--creds` | Capturar y mostrar credenciales |
| `--interface-pool` | Varias interfaces para roles simultáneos |
| `--hw-mode`, `--channel-width`, `--ht40` | Parámetros de radio |

<mark style="background: #8000E1A6;">`--interface-pool` resuelve el problema práctico del engagement</mark>: un evil twin necesita al menos tres radios —monitor, AP falso y cliente— y gestionarlas a mano entre herramientas es donde se pierden capturas. El detalle de la caja de ataque está en [[13 - Arsenal del engagement Wi-Fi corporativo]].

# Listas blancas y negras

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi --auth wpa-eap \
      --mac-whitelist objetivos.txt --ssid-whitelist alcance.txt
```

| Opción | Función |
| ------ | ------- |
| `--mac-whitelist` / `--mac-blacklist` | Limitar a qué clientes se responde |
| `--ssid-whitelist` / `--ssid-blacklist` | Limitar qué SSID se suplantan |

Estas cuatro opciones son **el control de alcance de la herramienta**. En un engagement con SSID concretos autorizados, una lista blanca es lo que impide que el AP falso capte dispositivos de terceros que nunca firmaron nada — el mismo razonamiento que el filtro BPF de [[01 - hcxdumptool]].

# Cuándo usar otra cosa

| Situación | Mejor opción |
| --------- | ------------ |
| AP falso WPA3 (SAE) u OWE | `hostapd` de serie: EAPHammer se apoya en una base antigua |
| Sólo capturar handshake o PMKID | `hcxdumptool`, mucho más ligero |
| Portal de phishing con plantillas ricas | `wifiphisher` o `airgeddon` |
| Ataque a WPS | `reaver` / `bully` |

EAPHammer es la herramienta correcta cuando el objetivo es **802.1X**. Para lo demás hay opciones más directas.
