---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Introduccion
Descripción: "Un escáner que sigue la filosofía UNIX: cada escaneo es un filtro que lee JSONL y escribe JSONL, con la caché ARP como artefacto explícito"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Tipos de escaneo con sx]]"
Area: "[[sx.base|sx]]"
---
---

<mark style="background: #ADCCFFA6;">`sx` es un escáner de red en Go construido con filosofía UNIX: cada tipo de escaneo es un subcomando que lee de `stdin`, escribe JSONL a `stdout` y se encadena con tuberías</mark>. Su autor lo presenta como *«el escáner de red más rápido con código limpio y simple»* y afirma ser **30 veces más rápido que Nmap** (cifra del proyecto, no verificada de forma independiente).

Es la herramienta menos conocida de este arsenal y merece un hueco por dos razones muy concretas que ninguna de las otras cubre:

1. **Trae los escaneos TCP "raros"** —`FIN`, `NULL`, `Xmas` y combinaciones arbitrarias de flags— que masscan y ZMap **no tienen en absoluto** y que siguen siendo la vía de sondeo de firewall más útil que queda ([[02 - Evasión de firewalls y detección con sx]]).
2. **Su limitación de ritmo es fraccionaria**: `--rate 1/5s` significa *un paquete cada cinco segundos*. Ningún otro escáner del lote expresa el *low-and-slow* con esa naturalidad.

# La caché ARP como artefacto

Es su decisión de diseño más característica y la que más desconcierta al principio.

Los escaneos de nivel superior (TCP, UDP) **necesitan** una caché ARP: un fichero JSONL con el mapeo IP → MAC → fabricante. No se genera sola en cada ejecución; se produce una vez con `sx arp` y se reutiliza:

```shell-session
$ sudo sx arp 192.168.0.1/24 --json | tee arp.cache
{"ip":"192.168.0.1","mac":"00:11:22:33:44:55","vendor":"Cisco Systems"}
{"ip":"192.168.0.171","mac":"aa:bb:cc:dd:ee:ff","vendor":"Dell Inc."}

$ cat arp.cache | sudo sx tcp -p 1-65535 192.168.0.171
$ sudo sx tcp -a arp.cache -p 22,443 192.168.0.171
```

La documentación justifica que esto *«simplifica el diseño del programa y además acelera el escaneo, porque no hace falta hacer un escaneo ARP cada vez»*.

<mark style="background: #8000E1A6;">La consecuencia práctica es mejor que la justificación</mark>: separar el descubrimiento L2 del escaneo L3+ convierte el inventario de la red en un **artefacto reutilizable y versionable**. En un engagement interno haces el ARP una vez, lo guardas como evidencia (con fabricantes incluidos, que ya te dicen si hay impresoras, cámaras o equipo de red) y todos los escaneos posteriores parten de ese mismo inventario conocido.

> [!important]+ Eso lo orienta a la red local
> Todos los ejemplos de la documentación operan sobre segmentos L2 propios (`192.168.0.1/24`). Es coherente con el diseño: si construyes tramas Ethernet a mano necesitas la MAC de destino, y para un objetivo remoto esa MAC es la del router, no la del host. <mark style="background: #FFB8EBA6;">`sx` brilla en la red interna del cliente</mark> —donde ARP es exactamente lo que quieres— y no es la herramienta para escanear Internet: para eso están [[00 - Introducción a masscan y el escaneo stateless|masscan]] y [[00 - Introducción a ZMap y el escaneo a escala de Internet|ZMap]].

# Todo es JSONL

```shell-session
$ sudo sx arp --json 192.168.0.1/24
$ cat arp.cache | sudo sx tcp --json -p 22,443 192.168.0.171
$ cat arp.cache | sudo sx udp --json -p 53 192.168.0.171
```

Una línea JSON por resultado, emitida en cuanto se conoce. Eso permite dos cosas que los formatos por fichero no:

- **Encadenar en streaming** con `jq`, `tee` o cualquier consumidor, sin esperar a que el escaneo termine.
- **Realimentar**: la salida de un escaneo es entrada válida del siguiente (`-f fichero.jsonl`), así que el pipeline se construye sin *scripts* de conversión por el medio.

```shell-session
$ cat arp.cache | sudo sx tcp --json -p 1-65535 192.168.0.171 \
    | jq -r 'select(.flags=="sa") | "\(.ip):\(.port)"'
```

## Escaneo continuo

```shell-session
$ sudo sx arp 192.168.0.1/24 --live 10s --json | tee arp.cache
$ while true; do sudo sx tcp -p 1-65535 -a arp.cache -f arp.cache; sleep 30; done
```

`--live` mantiene el escaneo ARP corriendo y va emitiendo hosts según aparecen. Combinado con el bucle, da un **monitor de red**: detecta equipos que se conectan y los escanea al vuelo. En un engagement largo eso sirve para pillar el portátil del administrador cuando llega por la mañana, o el servidor que solo se enciende para el backup nocturno.

# Frente al resto del arsenal

| | `sx` | masscan | ZMap | RustScan |
| --- | --- | --- | --- | --- |
| **Paquetes crudos** | Sí | Sí | Sí | No (sockets del SO) |
| **FIN / NULL / Xmas / flags libres** | **Sí** | No | No | No |
| **Descubrimiento ARP** | **Sí, de primera clase** | No | No | No |
| **Rate fraccionario** (`1/5s`) | **Sí** | No (`--rate` ≥ 1 pps) | No | No |
| **Salida en streaming JSONL** | **Sí** | JSON al final | CSV/JSON | Texto |
| **IPv6** | No documentado | Sí | Sí (`zmapv6`) | Sí |
| **Escala de Internet** | No | Sí | Sí | No |

> [!warning]+ Herramienta de nicho, no sustituto
> `sx` no reemplaza a nada del arsenal: complementa. <mark style="background: #FF5582A6;">No documenta soporte IPv6</mark> —serio en 2026, donde una red corporativa dual-stack es la norma y el firewall IPv6 suele estar más flojo que el IPv4—, su ecosistema es minúsculo comparado con el de Nmap, y no hace *fingerprinting* de versión. Úsalo por lo que hace bien: ARP, escaneos de flags exóticos y ritmos ridículamente bajos.

> [!info]+ Estado del proyecto (verificado 2026-08-04)
> **v0.6.0 (junio de 2026)**, ~1.500 estrellas, repositorio `v-byte-cpu/sx`. Activo pero pequeño: un solo mantenedor principal. La lista completa de subcomandos de tu versión sale de `sx --help` — la documentación pública cubre `arp`, `tcp`, `udp`, `icmp` y `socks`.

> [!info]+ Fuente
> [README de sx](https://github.com/v-byte-cpu/sx) — filosofía de diseño, mecanismo y justificación de la caché ARP, salida JSONL, `--live`, `--rate` y todos los ejemplos citados.
