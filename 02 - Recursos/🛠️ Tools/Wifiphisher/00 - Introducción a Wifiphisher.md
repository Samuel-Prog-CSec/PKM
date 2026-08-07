---
tags:
  - Wi-Fi/Evil-Twin
  - Tipo/Introduccion
  - Pentesting/Explotacion
Descripción: "El framework de phishing inalámbrico: escenarios, interfaces necesarias y la opción que evita recoger contraseñas inventadas"
Fecha de actualización: 2026-08-04
Nota previa: 
Nota siguiente: "[[01 - Escenarios y opciones de Wifiphisher]]"
Area: "[[Wifiphisher.base|Wifiphisher]]"
---
---

<mark style="background: #ADCCFFA6;">`Wifiphisher` automatiza el ataque de AP falso con portal de phishing</mark>: levanta la red, desautentica a los clientes del AP legítimo, les sirve una página creíble y recoge lo que introduzcan. Su valor frente a montar `hostapd` + `dnsmasq` + un servidor web está en las plantillas y en la validación del resultado.

| Dato | Valor |
| ---- | ----- |
| Repositorio | [`wifiphisher/wifiphisher`](https://github.com/wifiphisher/wifiphisher) |
| Actividad del repo | Activa (mayo de 2026) |
| **Última versión etiquetada** | **v1.4, enero de 2018** |
| Instalación práctica | Desde `git`, no desde paquete |

> [!warning]+ Repositorio activo, ocho años sin release
> Es una distinción que importa al preparar una caja de ataque: el paquete de la distribución puede ir muy por detrás de `master`, y no hay versión etiquetada reciente a la que anclarse. Se instala desde `git`, y conviene fijar un commit concreto para que el engagement sea reproducible.

```shell-session
$ git clone https://github.com/wifiphisher/wifiphisher
$ cd wifiphisher && sudo python3 setup.py install
```

# Interfaces

El ataque necesita **dos radios** como mínimo, con roles distintos:

| Interfaz | Papel | Opción |
| -------- | ----- | ------ |
| AP falso | Hospeda la red y el portal | `-aI`, `--apinterface` |
| Extensiones | Desautentica y monitoriza | `-eI`, `--extensionsinterface` |
| Internet | Salida real, si el escenario la necesita | `-iI`, `--internetinterface` |

```shell-session
$ sudo wifiphisher -aI wlan1 -eI wlan2 -p firmware-upgrade --handshake-capture cap-01.cap -kN
```

Con una sola radio la herramienta puede arrancar, pero no desautentica mientras emite, lo que reduce mucho su eficacia. La configuración de la caja de ataque está en [[13 - Arsenal del engagement Wi-Fi corporativo]].

# La opción que evita recoger basura

`--handshake-capture` recibe un fichero con un handshake real de la red objetivo y <mark style="background: #FFB86CA6;">valida contra él cada contraseña que el usuario introduce</mark>: deriva el PMK y compara el MIC, exactamente el mismo cálculo que hace [[03 - hcxhashtool, hcxpsktool y el resto|`hcxpmktool`]].

Sin esa opción, el portal acepta cualquier cosa que se teclee. Un usuario que escribe mal la contraseña —o que directamente pone algo al azar para quitarse el aviso de encima— produce un "resultado" falso que acaba en el informe. **Es la diferencia entre un hallazgo y un error.**

Para obtener el handshake previo:

```shell-session
$ sudo hcxdumptool -i wlan0 -c 6a --bpf=alcance.bpf --exitoneapol -w cap.pcapng
$ hcxhash2cap --pcapngout=cap-01.cap -i hash.hc22000     # si sólo se tiene el hash
```

# Preparar el sistema

`wifiphisher` levanta `dnsmasq`, que necesita el puerto 53:

```shell-session
$ ss -tulpn | grep :53
$ sudo systemctl stop systemd-resolved
$ sudo wifiphisher -aI wlan1 -eI wlan2 -p firmware-upgrade -kN
```

Al terminar hay que devolver el sistema a su estado:

```shell-session
$ sudo systemctl restart NetworkManager systemd-resolved
```

<mark style="background: #FFB8EBA6;">Olvidar el `stop` de `systemd-resolved` es el fallo más frecuente</mark>: el AP se levanta pero nadie consigue IP, y el síntoma —clientes que se conectan y se desconectan— parece un problema de radio cuando es de DHCP. `-kN` (`--keepnetworkmanager`) evita además que la herramienta tumbe la conectividad de gestión de la propia caja.

# El marco ético

> [!important]+ Esto es ingeniería social contra empleados
> Un portal que imita una actualización de firmware es un ataque **contra personas**, no contra un sistema. Muchos RoE excluyen la ingeniería social por defecto, y la desautenticación previa puede afectar a equipos en uso —en un entorno sanitario o industrial, con consecuencias reales.
>
> <mark style="background: #FF5582A6;">Requiere autorización explícita y separada</mark>, además de acuerdo sobre qué se hace con las credenciales recogidas y cómo se destruyen al cierre. Ver [[04 - Evil twin y portales hostiles]] y [[11 - Post-explotación y valor para el cliente]].

# Alternativas

| Herramienta | Cuándo |
| ----------- | ------ |
| **`airgeddon`** | Muy activa (jul-2026). Menú unificado y más mantenida |
| **`Fluxion`** | Activa (jul-2026). Especializada en portal + validación de handshake |
| `wifipumpkin3` | Estancada (ene-2024). Framework MITM más general |
| **`EAPHammer`** | Cuando el objetivo es 802.1X, no PSK |

Para un engagement en 2026, `airgeddon` es la opción por defecto por mantenimiento; `wifiphisher` conserva la ventaja de sus plantillas y de la validación por handshake integrada.
