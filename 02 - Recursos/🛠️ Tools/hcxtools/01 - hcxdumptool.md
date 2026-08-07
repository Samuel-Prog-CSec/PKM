---
tags:
  - Wi-Fi
  - Pentesting/Enumeracion
Descripción: "La herramienta de captura que sustituye a airodump-ng y aireplay-ng: sintaxis de canal por banda, filtros BPF como control de alcance y las opciones de la 7.x"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - La suite hcx]]"
Nota siguiente: "[[02 - hcxpcapngtool]]"
Area: "[[hcxtools.base|hcxtools]]"
---
---

`hcxdumptool` hace en un solo proceso lo que la suite clásica reparte entre [[02 - Airodump-ng|`airodump-ng`]] y [[04 - Aireplay-ng|`aireplay-ng`]]: <mark style="background: #ADCCFFA6;">escanea, solicita PMKID, provoca handshakes y escribe `pcapng`</mark>. Gestiona la interfaz por su cuenta, así que no hace falta `airmon-ng`.

```shell-session
$ sudo hcxdumptool -i wlan0 -c 6a -w captura.pcapng --exitoneapol
```

# Opciones principales

| Opción | Función |
| ------ | ------- |
| `-i <interfaz>` | Interfaz. **Cambia su modo, MAC virtual y canal** |
| `-w <fichero>` | Salida `pcapng` (no sobrescribe si existe) |
| `-c <canal>` | Canal **con letra de banda**. Por defecto `1a,6a,11a` |
| `-f <frecuencia>` | Frecuencia en MHz, alternativa a `-c` |
| `-F` | Todas las frecuencias que soporte la interfaz |
| `-t <segundos>` | Tiempo mínimo de permanencia por canal |
| `-A` | Confirmar (ACK) las tramas entrantes. Requiere *active monitor* |
| `-L` / `-l` | Listar interfaces físicas |
| `-I <interfaz>` | Información detallada de una interfaz |

> [!warning]+ El canal necesita letra de banda o se ignora en silencio
> <mark style="background: #FF5582A6;">`-c 6` **no** vale</mark>. Hay que escribir `6a`, y la letra indica la banda porque los números de canal no son únicos entre ellas:
>
> | Letra | Banda |
> | ----- | ----- |
> | `a` | 2,4 GHz |
> | `b` | 5 GHz |
> | `c` | 6 GHz |
> | `d` | 60 GHz |
> | `e` | Sub-1 GHz (802.11ah) |
>
> Un `-c 36` sin letra se descarta **sin aviso** y la herramienta sigue saltando por los canales por defecto. Es el fallo más común al pasar de la 6.x a la 7.x. El mapa de canales por banda está en [[01 - Bandas, canales y regulación del espectro]].

# El filtro BPF: el control de alcance

En un engagement, capturar sólo lo autorizado no es una optimización: es el requisito legal. En `hcxdumptool` 7.x **la única vía para eso es un filtro BPF**, que sustituye a las `--filterlist_ap` y `--filtermode` de la 6.x.

```shell-session
$ hcxdumptool --bpfc="wlan addr3 802dbffe1383 || wlan addr3 802dbffe1384" > alcance.bpf
$ sudo hcxdumptool -i wlan0 -c 6a --bpf=alcance.bpf -w captura.pcapng
```

| Opción | Función |
| ------ | ------- |
| `--bpfc=<filtro>` | Compila un filtro estilo `pcap-filter` y lo imprime |
| `--bpf=<fichero>` | Aplica un filtro ya compilado |
| `--bpfd=<modo>` | Formato de salida del compilado (decimal, con cuenta, o fragmento en C) |

`wlan addr3` es el campo de dirección que en una trama de infraestructura contiene el **BSSID** —ver la tabla `To DS`/`From DS` de [[02 - Arquitectura 802.11 y la trama MAC]]—, así que ese filtro deja pasar únicamente las tramas de los dos AP autorizados. Se compila una vez y se reutiliza durante todo el engagement.

<mark style="background: #FFB86CA6;">El BPF filtra en el kernel, antes de que la trama llegue al proceso</mark>. El tráfico ajeno **nunca se escribe en disco**, lo que convierte al fichero de filtro en la evidencia de que el engagement respetó su alcance. La sintaxis es la de `man pcap-filter`.

> [!warning]+ `--essidlist` **no** es un filtro de captura
> Es un error fácil de cometer por el nombre. Su ayuda dice: *"initialize ESSID list with these ESSIDs"* — <mark style="background: #FF5582A6;">alimenta el anillo de ESSID que la herramienta **transmite** en sus `PROBERESPONSE`</mark>, junto con `--proberesponsetx`. Es una opción **ofensiva**, para responder a los clientes que buscan esas redes, no defensiva.
>
> Usarla creyendo que acota la captura deja el engagement sin ningún control de alcance **y** hace que la tarjeta anuncie redes activamente. Para acotar, `--bpf`; y sólo `--bpf`.

# Control del ataque

| Opción | Función |
| ------ | ------- |
| `--exitoneapol` | Termina al conseguir material utilizable |
| `--m2max=<n>` | Máximo de mensajes M2 a solicitar por cliente |
| `--associationmax=<n>` | Límite de intentos de asociación |
| `--disable_disassociation` | No enviar desasociaciones |
| `--proberesponsetx` | Control de las respuestas a *probes* |
| `--tot=<minutos>` | Tiempo total antes de terminar |
| `--errormax`, `--watchdogmax` | Umbrales de error antes de abortar |

`--exitoneapol` es la mejor medida de sigilo disponible: <mark style="background: #8000E1A6;">en cuanto hay material, la herramienta deja de transmitir</mark> en vez de seguir insistiendo contra APs que ya no aportan. Y `--disable_disassociation` permite operar en modo puramente pasivo, sin generar ninguna alerta de desautenticación.

Para operación desatendida —el patrón para el que fue diseñada, sobre una Raspberry Pi— hay ganchos de sistema:

| Opción | Función |
| ------ | ------- |
| `--daemonize` | Ejecutar en segundo plano |
| `--gpio_button`, `--gpio_statusled` | Botón y LED en GPIO |
| `--onsigterm`, `--ontot`, `--onerror` | Acción al terminar por cada motivo |

# Modo de escaneo pasivo

```shell-session
$ sudo hcxdumptool -i wlan0 --rcascan=active
```

`--rcascan` hace un barrido de canales para inventariar qué hay antes de atacar nada. Es el equivalente a un `airodump-ng` de reconocimiento y el paso previo razonable a cualquier captura dirigida.

# Requisitos que sí importan

El `README` es exigente y conviene tomárselo al pie de la letra:

- **Kernel ≥ 5.15**, y recomienda la última LTS o estable.
- El driver debe soportar **modo monitor e inyección completa**. Sin inyección, el ataque de PMKID no funciona.
- `-A` (*active monitor*) está **roto en muchos drivers mt76** según la propia ayuda.
- No hay soporte para Windows, macOS ni emuladores.

La elección de adaptador y la comprobación de capacidades del driver están en [[04 - Interfaces, chipsets y drivers]].

> [!important]+ Sin filtro, ataca todo lo que ve
> Lanzado sin `--bpf`, `hcxdumptool` intenta obtener material de **todas** las redes al alcance. En una oficina eso incluye a los vecinos. <mark style="background: #FF5582A6;">Es la diferencia entre una auditoría y un delito</mark>, y la herramienta no avisa. El filtro se compila antes del primer comando, no después.
