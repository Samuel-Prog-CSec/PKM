---
tags:
  - Wi-Fi
  - Tipo/Introduccion
  - Pentesting/Enumeracion
Descripción: "Qué aporta Kismet frente a airodump-ng: estado persistente, correlación cliente-AP y una arquitectura cliente-servidor pensada para sensores desatendidos"
Fecha de actualización: 2026-08-04
Nota previa: 
Nota siguiente: "[[01 - Fuentes de datos y uso operativo]]"
Area: "[[Kismet.base|Kismet]]"
---
---

<mark style="background: #ADCCFFA6;">`Kismet` es un detector, husmeador y sistema de detección de intrusiones inalámbrico</mark>, y la diferencia práctica con [[02 - Airodump-ng|`airodump-ng`]] es que **mantiene estado**: no muestra una instantánea del canal actual, sino un modelo acumulado de todo lo que ha visto, con la relación entre cada cliente y cada AP a lo largo del tiempo.

| Dato | Valor |
| ---- | ----- |
| Versión estable | **2025-09-R1** (4 de septiembre de 2025) |
| Repositorio | [`kismetwireless/kismet`](https://github.com/kismetwireless/kismet) |
| Arquitectura | Servidor + interfaz web, no una TUI |
| Alcance | Wi-Fi, Bluetooth, RF genérica (SDR), ADS-B, Zigbee… |

# Cuándo gana a airodump-ng

| Situación | Herramienta |
| --------- | ----------- |
| Ver rápido qué hay en un canal | `airodump-ng` |
| Capturar un handshake concreto | `airodump-ng` o `hcxdumptool` |
| **Parque con decenas de AP y mucho ruido** | **Kismet** |
| **Correlacionar clientes con APs a lo largo de horas** | **Kismet** |
| **Sensor desatendido durante días** | **Kismet** |
| Detectar el AP que sólo aparece un instante | **Kismet** |

<mark style="background: #FFB86CA6;">El caso que justifica aprenderla es el ESS grande</mark>: una organización con once AP anunciando el mismo SSID, cada uno con configuración potencialmente distinta. `airodump-ng` salta de canal y muestra lo que hay ahora; Kismet acumula, y por eso encuentra el único AP con WPS activo o el único en modo transición. El razonamiento operativo está en [[01 - Reconocimiento de un parque de APs]].

# Arranque

```shell-session
$ sudo kismet -c wlan0
```

Kismet gestiona la interfaz por su cuenta: no hace falta ponerla en modo monitor con `airmon-ng` previamente. La sintaxis de `-c` admite opciones por fuente:

```shell-session
$ sudo kismet -c 'wlan0:name=Sensor1,channels="1,6,11,36HT40+"'
```

Al arrancar levanta su servidor web:

```text
KISMET - Point your browser to http://localhost:2501 for the Kismet UI
```

# La primera vez: credenciales

> [!important]+ Kismet no tiene usuario ni contraseña por defecto
> La primera ejecución obliga a **crear** un usuario desde la interfaz web. La credencial se guarda en `~/.kismet/kismet_httpd.conf`, en el directorio del usuario que arrancó Kismet.
>
> <mark style="background: #FFB8EBA6;">Eso tiene una consecuencia que confunde en cajas desplegadas</mark>: si se arranca a veces con `sudo` y a veces sin él, hay **dos ficheros de credenciales distintos** (`/root/.kismet/` y `~/.kismet/`), y parece que la contraseña "se ha perdido". Para un despliegue repetible conviene fijarla en `kismet_site.conf`, que es el fichero de sobrescritura recomendado.

# Configuración

| Fichero | Papel |
| ------- | ----- |
| `/etc/kismet/kismet.conf` | Configuración base. **No se edita** |
| `kismet_httpd.conf`, `kismet_alerts.conf`, `kismet_80211.conf`… | Sub-configuraciones por área |
| **`kismet_site.conf`** | **Aquí van los cambios propios**: sobrescribe todo lo anterior |
| `~/.kismet/kismet_httpd.conf` | Credencial del usuario que arranca |

La disciplina de tocar sólo `kismet_site.conf` es la que permite actualizar el paquete sin perder la configuración del engagement.

# Salto de canal

Por defecto Kismet recorre canales a unos cinco saltos por segundo, mucho más rápido que `airodump-ng`. Eso cubre más espectro a costa de perder tramas concretas.

<mark style="background: #8000E1A6;">Para reconocimiento amplio conviene dejarlo saltar; para capturar un handshake concreto hay que fijar canal</mark> —o mejor, usar otra interfaz con `hcxdumptool`—. Intentar las dos cosas con la misma radio es la causa habitual de capturas incompletas.

# Uso ofensivo y defensivo

Kismet nació como herramienta de auditoría y hoy se usa igual en los dos lados:

| Papel | Uso |
| ----- | --- |
| **Ofensivo** | Reconocimiento, inventario de AP y clientes, detección de redes ocultas y fantasma |
| **Defensivo** | WIDS: alertas de deauth, rogue AP, Karma, KRACK — ver [[02 - Alertas y uso como WIDS]] |

Su catálogo de alertas es **público**, y por eso sirve de referencia para entender qué detectan los WIPS comerciales, cuyas firmas no lo son. Ese es su segundo valor para un pentester: saber qué umbral no conviene superar.

> [!info]+ No es sólo Wi-Fi
> Kismet captura Bluetooth, RF de 433/915 MHz con SDR, ADS-B, Zigbee y más, según el hardware disponible. En un engagement de superficie inalámbrica amplia —no sólo 802.11— es la única herramienta que unifica todo eso en un solo modelo de datos.
