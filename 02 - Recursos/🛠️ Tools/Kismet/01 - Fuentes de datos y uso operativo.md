---
tags:
  - Wi-Fi
  - Pentesting/Enumeracion
Descripción: "Configurar fuentes de captura, navegar la interfaz para sacar el inventario del parque y exportar el resultado a los formatos que consumen otras herramientas"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a Kismet]]"
Nota siguiente: "[[02 - Alertas y uso como WIDS]]"
Area: "[[Kismet.base|Kismet]]"
---
---

# Fuentes de datos

Una *datasource* es cada radio o receptor que alimenta al servidor. Se declaran en línea de comandos con `-c`, o de forma permanente en `kismet_site.conf`.

```shell-session
$ sudo kismet -c wlan0 -c wlan1
$ sudo kismet -c 'wlan0:name=2GHz,channels="1,6,11"' -c 'wlan1:name=5GHz,channels="36,40,44,48"'
```

| Opción de fuente | Función |
| ---------------- | ------- |
| `name=` | Etiqueta legible en la interfaz |
| `channels=` | Lista fija de canales a recorrer |
| `channel=` | **Fijar** un solo canal, sin salto |
| `hop=false` | Desactivar el salto |
| `hoprate=` | Saltos por segundo |

<mark style="background: #FFB86CA6;">Repartir bandas entre dos radios es la configuración que más rinde en un parque corporativo</mark>: una fija en 2,4 GHz y otra recorriendo 5 GHz cubre el espectro real sin que ninguna pierda tramas por saltar demasiado. Con una sola interfaz siempre se sacrifica cobertura o profundidad.

```text
kismet_site.conf
source=wlan0:name=2GHz,channels="1,6,11"
source=wlan1:name=5GHz,channels="36,40,44,48,149,153,157,161"
```

# Navegar el inventario

La interfaz web en `http://localhost:2501` organiza los datos en tres vistas que responden a preguntas distintas:

| Vista | Responde a |
| ----- | ---------- |
| **Devices** | Qué APs y clientes existen, con cifrado, canal, fabricante y señal |
| **SSID** | Qué **nombres de red** se han visto, anunciados o **buscados** |
| **Alerts** | Qué eventos sospechosos se han detectado |

La vista **SSID** es la que no tiene equivalente en `airodump-ng`. Sus columnas `Advertising` y `Responding` distinguen tres situaciones:

| Advertising | Responding | Situación |
| ----------- | ---------- | --------- |
| > 0 | > 0 | Red normal, con AP activo |
| 0 | 0 | **Red fantasma**: sólo la buscan los clientes. El AP no existe |
| 0 | > 0 | Red oculta: no emite el nombre pero responde a quien lo sabe |

<mark style="background: #8000E1A6;">Una red con ambos contadores a cero es un objetivo servido</mark>: hay clientes dispuestos a asociarse a un AP que nadie está levantando. Es la condición exacta de [[07 - Karma y MANA]].

Filtrando `Devices` por el SSID en alcance aparecen **todos** los BSSID de un ESS, y al pinchar en cada uno se ve su cifrado, sus clientes asociados y su fabricante. Ahí es donde se localiza el único AP con WPS activo o el único en modo transición.

# Ficha de dispositivo

Al abrir un AP, la información útil para el ataque:

| Campo | Para qué |
| ----- | -------- |
| Fabricante | Keyspace de contraseña de fábrica — [[06 - Credenciales por defecto y keyspaces de fabricante]] |
| Cifrado y AKM | Decide la vía: PSK, SAE, 802.1X, OWE |
| Canal y frecuencia | Fijar la captura y el AP falso |
| Clientes asociados | Si hay a quién desautenticar |
| Primera y última vez visto | Patrón horario, para elegir ventana |

El último campo se subestima: <mark style="background: #FFB8EBA6;">saber a qué hora aparecen los clientes permite capturar handshakes de forma pasiva</mark>, sin emitir nada. Es la información que convierte un engagement ruidoso en uno silencioso, y sólo la da una herramienta que acumula estado.

# Registros y exportación

Kismet escribe por defecto un `.kismet`, que es una base de datos SQLite con todo lo observado. Para interoperar:

```shell-session
$ kismetdb_to_pcap --in registro.kismet --out captura.pcapng
$ kismetdb_dump_devices --in registro.kismet --out dispositivos.json
$ kismetdb_statistics --in registro.kismet
```

| Herramienta | Salida |
| ----------- | ------ |
| `kismetdb_to_pcap` | `pcapng` para Wireshark o `hcxpcapngtool` |
| `kismetdb_dump_devices` | JSON con todos los dispositivos |
| `kismetdb_statistics` | Resumen del registro |
| `kismetdb_to_wiglecsv` | CSV para WiGLE |

El primero es el puente al resto del flujo: un `.kismet` de una sesión larga se convierte a `pcapng` y se procesa con [[02 - hcxpcapngtool|`hcxpcapngtool`]] para extraer los handshakes que Kismet capturó de pasada.

> [!warning]+ Un registro de Kismet contiene todo lo que había en el aire
> A diferencia de una captura filtrada con BPF, el `.kismet` guarda **todos** los dispositivos observados, incluidos los ajenos al engagement. <mark style="background: #FF5582A6;">Eso lo convierte en un fichero con datos personales de terceros</mark>. Conviene filtrar por alcance antes de procesarlo, no incluirlo íntegro como evidencia, y destruirlo con el resto del material al cierre — ver [[11 - Post-explotación y valor para el cliente]].

# Interfaz sin navegador

Para una caja desatendida o una sesión por SSH, el servidor y la interfaz están desacoplados:

```shell-session
$ sudo kismet --no-ncurses -c wlan0        # sólo servidor
$ ssh -L 2501:localhost:2501 usuario@caja  # túnel para ver la web en local
```

Ese túnel es la forma correcta de operar las cajas desplegadas en sedes del cliente: el servidor no expone su puerto a la red, y la interfaz se consulta a través de SSH.
