---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Deteccion
Descripción: "ZMap sabe disfrazar su paquete de sistema operativo real, pero no puede disfrazar su comportamiento — y escanear Internet te fabrica una reputación de IP"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - ZDNS - resolución DNS masiva]]"
Nota siguiente:
Area: "[[ZMap.base|ZMap]]"
---
---

ZMap tiene una capacidad de evasión que masscan no tiene y que casi ninguna documentación menciona: **puede fabricar un `SYN` indistinguible del de un sistema operativo real**. Y aun así sigue siendo detectable, porque lo que lo delata no es el paquete sino el patrón. Esta nota separa las dos cosas.

# La palanca buena: perfiles de opciones TCP

`tcp_synscan` construye la cabecera TCP imitando pilas reales, y el perfil se elige con `--probe-args`:

```shell-session
$ sudo zmap -p 443 -w scope.txt -M tcp_synscan --probe-args="linux"
$ sudo zmap -p 443 -w scope.txt -M tcp_synscan --probe-args="bsd,rtt"
```

| Valor | Opciones TCP que emite | Cabecera |
| --- | --- | --- |
| `windows` (**por defecto**) | MSS + SACK + WindowScale=8 | 32 bytes |
| `linux` | MSS + SACK + Timestamps + WindowScale=7 | 40 bytes |
| `bsd` | MSS + NOP + WindowScale=6 + Timestamps + SACK | 44 bytes |
| `smallest-probes` | Solo MSS | 24 bytes |

Solo se puede elegir un perfil por escaneo; se le pueden encadenar por comas otros modificadores (`rtt`, `ja4ts`, `ja4t`).

<mark style="background: #8000E1A6;">Esto invierte por completo la comparación con masscan</mark>. El `SYN` de masscan lleva TTL 255, sin `DF`, ventana fija de 1024 y **una sola opción TCP** — una firma que se identifica mirando dos campos ([[05 - Evasión de firewalls e IDS con masscan]]). El de ZMap por defecto se parece al de una máquina Windows cualquiera, y con `--probe-ttl 64` + `--probe-args="linux"` se parece al de un Linux cualquiera:

```shell-session
$ sudo zmap -p 443 -w scope.txt --probe-args="linux" --probe-ttl 64 -B 2M
```

> [!important]+ Que el proyecto incluya `ja4t`/`ja4ts` no es casualidad
> **JA4T** y **JA4TScan** son métodos de *fingerprinting* que identifican una pila TCP —y, en el caso de JA4TScan, un escáner activo— a partir de la ventana, el conjunto **y el orden** de las opciones TCP, el MSS y el patrón de retransmisión. Que ZMap traiga modos para emitir esas huellas a propósito indica que sus autores juegan en los dos lados del tablero: sirve tanto para medir cómo de detectable eres como para generar tráfico de prueba con el que calibrar defensas.

# Las demás palancas

| Flag | Uso ofensivo |
| --- | --- |
| `--probe-ttl N` | Sacar el TTL de un valor delator. 64 (Linux) o 128 (Windows) según el perfil elegido. |
| `-S`, `--source-ip` | Acepta **rango**: reparte el origen entre varias IPs propias. |
| `-s`, `--source-port` | Puerto de origen "de confianza" (53, 443) contra firewalls con reglas perezosas. |
| `--shards` + `-e` | Repartir entre varias máquinas/IPs. La semilla común es obligatoria. |
| `-r` / `-B` bajos | Diluir por debajo del umbral. |
| `-X`, `--iplayer` | Salir por un túnel VPN sin trama Ethernet. |
| `--min-hitrate` | Defensivo para ti: aborta si te han bloqueado, en vez de seguir gritando al vacío. |

Y lo que **no** tiene, igual que masscan: sin fragmentación, sin *decoys*, sin *idle scan*, sin tipos de escaneo alternativos. La deformación de paquete no es el camino aquí.

# Por qué sigue siendo detectable

## El comportamiento, no el paquete

<mark style="background: #FF5582A6;">ZMap manda **un paquete por objetivo y nunca vuelve**</mark> (`-P 1` por defecto). Ese es su rasgo delator y no hay flag que lo arregle, porque es el diseño:

- Un cliente legítimo que recibe `SYN/ACK` **completa el handshake**. ZMap no. Una avalancha de conexiones a medio abrir desde un origen es la definición de escaneo, mires la pila TCP que mires.
- Un cliente legítimo que no recibe respuesta **reintenta**. ZMap no.
- El abanico es enorme: miles de destinos distintos, un puerto, sin repetición.

Un IDS por firma de paquete cae con `--probe-args="linux"`. Un motor de **flujo** (Zeek, NDR, VPC Flow Logs) no, porque cuenta destinos únicos por origen y ratio de handshakes completados. Es la misma conclusión de [[08 - Detección de escaneos y evasión moderna|la detección moderna]]: sobrevive lo que mira comportamiento, no forma.

## Los telescopios de red te ven aunque no escanees a nadie

Este es el punto que casi nadie considera y el que tiene consecuencias más largas.

Existen **darknets / telescopios de red**: bloques enteros de direcciones enrutadas pero sin hosts, cuyo único propósito es registrar lo que llega. <mark style="background: #FFB86CA6;">Cualquier escaneo indiscriminado de IPv4 los atraviesa por definición</mark> — no puedes escanear "todo Internet" y esquivar los rangos que existen para observarte. Plataformas como **GreyNoise** catalogan las IPs que hacen escaneo masivo y publican esa clasificación.

La consecuencia operativa es diferida y cara:

```
Escaneas Internet desde tu VPS
        ↓
Tu IP queda catalogada como "known scanner"
        ↓
Semanas después, en otro engagement, esa misma IP
dispara alertas que no habría disparado
```

Enlaza directamente con lo que ya sabemos de [[08 - Detección de escaneos y evasión moderna|GuardDuty]]: `Recon:EC2/PortProbeUnprotectedPort` **exige que tu IP figure como escáner conocido o maliciosa** en la *threat intel* de AWS. Un pentester con IP limpia no dispara ese hallazgo; uno que hizo un censo de Internet el mes pasado, sí.

> [!warning]+ Regla de infraestructura
> <mark style="background: #ADCCFFA6;">La IP desde la que haces investigación a escala y la IP desde la que haces engagements de cliente **nunca** deben ser la misma</mark>. Quemar reputación es gratis y recuperarla no existe. Es el mismo principio de VPS sacrificables de [[07 - Evasión de firewalls, IDS e IPS#Detectar el IDS/IPS|la rotación de infraestructura]], llevado a la escala de meses.

## Lo demás

- **Umbral y honeypots** — barrer un espacio completo garantiza pisar puertos-trampa y canarios.
- **Logs de aplicación** — ZMap no, pero [[02 - ZGrab2 - handshakes L7 y banners a escala|ZGrab2]] sí completa conexiones y deja línea en el log del servidor.
- **DNS autoritativo** — [[03 - ZDNS - resolución DNS masiva|ZDNS]] con `--iterative` consulta directamente a los servidores del objetivo, con tu IP.

# Ética y legalidad: aquí no es opcional

ZMap es el único de estos escáneres cuya documentación fija reglas de conducta, y no por remilgos: **su modelo de amenaza es que tú escanees a terceros que no te han autorizado**.

Las tres reglas del proyecto: *escanear a la velocidad mínima necesaria, más lento aún si el espacio objetivo es pequeño, y ofrecer a los operadores una vía para excluirse.*

La práctica que la comunidad de investigación ha consolidado alrededor de eso:

1. **PTR descriptivo** en la IP de escaneo (`research-scanner.tudominio.tld`), para que quien mire sus logs sepa quién eres.
2. **Servidor web en el puerto 80 de esa IP** con una página que explique el propósito y dé un correo de exclusión.
3. **Honrar las exclusiones** y meterlas en el `blocklist` para siempre.
4. **Avisar antes a tu propio proveedor** — un escaneo masivo sin previo aviso al abuse desk termina con el VPS apagado.
5. **Registrar cada escaneo** con `-m metadata.json` y `--notes`, para poder responder «qué lanzaste el día X» con datos y no de memoria.

> [!warning]+ El marco legal español
> Escanear infraestructura de terceros **sin autorización escrita** no es una zona gris: el **art. 197 bis CP** castiga el acceso o el mantenimiento en sistemas ajenos vulnerando medidas de seguridad, y un escaneo indiscriminado es difícil de defender como investigación legítima si no hay ni encargo ni consentimiento. En un engagement, lo que te protege es el **scope firmado**; en bug bounty, las reglas del programa, que <mark style="background: #FFB8EBA6;">con frecuencia prohíben explícitamente el escaneo automatizado de alto volumen</mark> ([[01 - Reglas, legalidad y conducta]]). Un censo de Internet "para investigar" desde tu conexión doméstica es el peor escenario posible: máximo riesgo y ninguna cobertura.

> [!info]+ Fuentes
> - Código fuente de ZMap, `src/probe_modules/module_tcp_synscan.c` — `synscan_global_initialize()`, perfiles `windows`/`linux`/`bsd`/`smallest-probes` y modificadores `rtt`/`ja4ts`/`ja4t`; `README.md` para las tres reglas de conducta.
> - [GreyNoise](https://www.greynoise.io/) — clasificación pública de IPs que hacen escaneo masivo de Internet.
> - Contexto defensivo y de infraestructura en [[08 - Detección de escaneos y evasión moderna]]; MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/).
