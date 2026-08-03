---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Sniffing sin tocar la comunicación: dónde pinchar, filtros BPF para no ahogarte y en qué cuatro escenarios la captura pasiva deja de servir"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Modelo de análisis de protocolos de red]]"
Nota siguiente: "[[02 - Aislar el tráfico de una aplicación con trazado de syscalls]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

La captura pasiva extrae los datos **según pasan por el cable**, sin interponerse. Es el punto de partida natural: no requiere hardware especial, no modifica nada y —crucialmente— <mark style="background: #ADCCFFA6;">no altera el comportamiento de las aplicaciones que estás analizando</mark>, así que no introduce artefactos que luego confundan el análisis.

## Dónde pinchar

El sitio determina lo que ves. Un *switch* solo reenvía la trama al puerto destino, así que poner la interfaz en modo promiscuo desde una máquina cualquiera de la LAN **no basta**:

| Punto de captura | Qué consigues | Coste |
| - | - | - |
| El propio host (cliente o servidor) | Todo su tráfico, incluido `localhost` | Requiere acceso al host |
| Puerto SPAN / *mirror* del switch | Tráfico de otros puertos, sin tocar la red | Requiere gestionar el switch |
| TAP de red (pasivo) | Copia física, invisible e infalsificable | Hardware y acceso físico |
| Hub (legado) | Todo el dominio de colisión | Prácticamente extinto |
| MITM activo (ARP/DHCP/DNS) | Tráfico ajeno sin tocar infraestructura | **Ya no es pasivo** → [[01 - ARP poisoning]] |

> [!warning]+ Modo promiscuo ≠ modo monitor
> En Ethernet, **promiscuo** significa procesar toda trama que llegue al adaptador aunque su MAC destino no sea la tuya. En 802.11, el que captura tramas crudas es el **modo monitor** (RFMON), que además no requiere estar asociado. Son cosas distintas y se confunden constantemente — el detalle está en [[05 - Modos de operación y modo monitor]].

Capturar la interfaz *loopback* en Windows es históricamente incómodo (necesita `Npcap` con la opción de *loopback adapter*); en Linux basta `-i lo`. Si el cliente y el servidor están en la misma máquina, muchas veces sale más a cuenta mover uno a una VM.

## Filtrar en captura, no en pantalla

Wireshark tiene **dos lenguajes de filtro distintos** y confundirlos cuesta horas:

- **Filtro de captura** — sintaxis BPF, se aplica en el *kernel*, descarta el paquete antes de escribirlo. Es lo que evita un `.pcap` de 40 GB.
- **Filtro de visualización** — sintaxis propia de Wireshark, se aplica sobre lo ya capturado.

```shell-session
# Captura (BPF): solo lo que va o viene del servidor, puerto 12345
$ tshark -i eth0 -w captura.pcap 'host 192.168.56.100 and tcp port 12345'

# Visualización: sobre el fichero ya guardado
$ tshark -r captura.pcap -Y 'tcp.srcport == 12345'
```

En un análisis de protocolo <mark style="background: #FF5582A6;">el filtro de captura debe ser lo más estrecho posible desde el principio</mark>: el ruido de fondo (broadcast, mDNS, actualizaciones) enmascara el patrón que buscas y multiplica el tiempo de cada vuelta del bucle.

## Leer la conversación, no los paquetes

TCP es un flujo: los límites de paquete no significan nada para la aplicación, y hay retransmisiones y reordenaciones. Wireshark reensambla por ti:

- `Statistics → Conversations` → identificar las sesiones TCP y sus puertos.
- Botón derecho → `Follow → TCP Stream` → el flujo completo, con **salida en rosa** (cliente→servidor) y **azul** (servidor→cliente).
- En el desplegable `Show and save data as` → `Hex Dump` para ver los bytes, y `Raw` para exportar a fichero binario y atacarlo con un *script*.

Ese *hex dump* separado por dirección es el material de trabajo de [[05 - Del hex dump a la estructura del protocolo]].

Desde la línea de comandos, el equivalente para volcar solo la carga útil de una dirección:

```shell-session
$ tshark -r captura.pcap -T fields -e data -Y 'tcp.srcport==49825' > salida.hex
$ xxd -p -r salida.hex > salida.bin
```

> [!warning]+ El campo `data` desaparece si hay disector
> `-e data` solo existe si Wireshark **no** ha reconocido el protocolo. Si intenta disecar tu tráfico como otra cosa —le pasa constantemente con puertos altos, típicamente lo interpreta como `GVSP`— el campo se queda vacío. Se desactiva con `--disable-protocol <nombre>`. Es exactamente la razón por la que acabarás escribiendo tu propio disector.

## Los cuatro límites que te empujan a la captura activa

1. **Cifrado.** Si va por TLS solo ves el *handshake*. O consigues las claves de sesión (`SSLKEYLOGFILE`, ver [[Desencriptar conexiones]]) o te interpones ([[03 - Proxies de intercepción para protocolos no-HTTP]]).
2. **No puedes modificar nada.** Para desactivar la compresión o el cifrado opcional de un protocolo y verlo en claro hace falta reescribir el tráfico en vuelo.
3. **Demasiado bajo nivel.** Ves segmentos TCP; quieres mensajes de aplicación. Sin disector, correlacionar acción del usuario con bytes en el cable es lento.
4. **Tráfico de terceros en el mismo host.** Si el objetivo es *una* aplicación entre veinte, filtrar por tiempo es frágil — para eso está el [[02 - Aislar el tráfico de una aplicación con trazado de syscalls|trazado de syscalls]].

## Lo que la captura pasiva sí resuelve mejor que nada

Antes de complicarse: la pasiva es la única técnica que **no rompe nada**. En un entorno industrial, médico o de producción crítica esa propiedad no es una comodidad, es un requisito de alcance. Un TAP pasivo en un OT no altera el temporizado del bus; un proxy interpuesto sí puede.

También es la vía para el **inventario inicial**: qué habla con qué, en qué puertos, con qué volumen y en qué momentos. Eso alimenta el reconocimiento de [[00 - Principios y metodología de enumeración]] y decide dónde merece la pena invertir en captura activa.

> [!info]+ Fuentes
> - Guía de referencia de filtros de captura: [Wireshark — CaptureFilters](https://wiki.wireshark.org/CaptureFilters) y `man 7 pcap-filter` para la sintaxis BPF completa.
> - Herramientas del vault: [[Wireshark.base|Wireshark]] y [[Tcpdump.base|Tcpdump]].
