---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Deteccion
Descripción: "FIN, NULL y Xmas se venden como escaneos sigilosos: hoy evaden el filtro estático y encienden el IDS al instante — su valor real es diagnóstico"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Tipos de escaneo con sx]]"
Nota siguiente:
Area: "[[sx.base|sx]]"
---
---

`sx` es el único escáner de este arsenal que trae los escaneos de flags exóticos, así que aquí toca explicarlos bien — incluida la parte que las guías repiten mal desde hace veinte años.

# Por qué FIN, NULL y Xmas devuelven información

El mecanismo sale directamente de la especificación de TCP, hoy la **RFC 9293** (agosto de 2022, que obsoleta la clásica RFC 793):

- **Puerto cerrado** (no existe TCB): *«An incoming segment not containing a RST causes a RST to be sent in response.»* → responde **`RST`**.
- **Puerto abierto** (estado `LISTEN`): un segmento sin `SYN` y sin `ACK` válido no encaja en ninguna transición y se **descarta en silencio**.

<mark style="background: #ADCCFFA6;">De ahí la inversión que hace útiles a estos escaneos: **silencio = abierto**, `RST` = cerrado</mark>. Al revés que en un SYN scan.

```shell-session
$ cat arp.cache | sudo sx tcp fin  --json -p 1-1000 192.168.0.171
$ cat arp.cache | sudo sx tcp null --json -p 1-1000 192.168.0.171
$ cat arp.cache | sudo sx tcp xmas --json -p 1-1000 192.168.0.171
```

Y por qué se llamaron "sigilosos": un filtro de paquetes sin estado de los años 90 bloqueaba los `SYN` entrantes y dejaba pasar todo lo demás, porque *lo demás* parecía tráfico de conexiones ya establecidas. Un `FIN` suelto atravesaba el filtro y el host respondía.

## El fallo que invalida el resultado: Windows

<mark style="background: #FF5582A6;">La pila TCP de Windows responde `RST` a estos paquetes **tanto si el puerto está abierto como si está cerrado**</mark>. No es un bug: es una desviación de la especificación que Microsoft mantiene desde siempre, y que comparten varios equipos de red (dispositivos Cisco, algunos IBM y HP-UX entre los históricamente documentados).

Consecuencia: contra un objetivo Windows, un escaneo FIN/NULL/Xmas reporta **todos los puertos como cerrados**. No "no encontré nada" — sino un resultado positivo y falso.

> [!warning]+ Cómo usarlos sin engañarte
> Estos escaneos solo son interpretables **si ya sabes que el objetivo no es Windows**. El orden correcto es: primero identifica el sistema (ARP/OUI, TTL de respuesta, `nmap -O`, banners) y solo entonces decide si un FIN scan te dice algo. Y aun así, la lectura correcta de "silencio" es **abierto *o* filtrado**, ambigüedad que estos escaneos no pueden resolver — para eso está el `-sA` de [[07 - Evasión de firewalls, IDS e IPS#Leer las reglas del firewall - el ACK scan (`-sA`)|Nmap]].

## `--flags`: construir la sonda exacta

```shell-session
$ cat arp.cache | sudo sx tcp --flags syn,fin,ack --json -p 23 192.168.0.171
$ cat arp.cache | sudo sx tcp --flags ack --json -p 1-1000 192.168.0.171
```

Con combinaciones arbitrarias, `sx` deja de ser un escáner y pasa a ser un **probador de reglas**. Los usos concretos:

| Sonda | Para qué |
| --- | --- |
| `ack` solo | Equivalente al ACK scan: distingue puerto **filtrado** de **no filtrado**, revelando la política del firewall. |
| `syn,fin` | Combinación ilegal. Un filtro perezoso que solo mira "¿lleva SYN?" la trata distinto que un stack real. |
| `syn,ack` | Simula la segunda parte de un handshake. Delata dispositivos que no llevan estado. |
| `fin,psh,urg` (`xmas`) | La combinación clásica; máxima probabilidad de comportamiento anómalo en pilas antiguas. |

<mark style="background: #8000E1A6;">Esto es sondeo de perímetro, no sigilo</mark>: lo que buscas no es pasar desapercibido sino **aprender cómo filtra el dispositivo que tienes delante**. Es exactamente el trabajo que se desarrolla en [[00 - El perímetro moderno - firewall, NGFW, IDS-IPS, NDR y WAF|el bloque de evasión de perímetro]].

# Low-and-slow de verdad

La otra palanca real de `sx`, y la más infravalorada:

```shell-session
$ cat arp.cache | sudo sx tcp --rate 1/5s --json -p 22,80,443 192.168.0.171
$ cat arp.cache | sudo sx tcp --rate 30/1m --json -p 1-65535 192.168.0.171
```

<mark style="background: #FFB8EBA6;">`--rate` acepta fracciones</mark>: `1/5s` es un paquete cada cinco segundos. masscan y ZMap razonan en paquetes por segundo y su suelo práctico es 1 pps; `sx` baja de ahí sin trucos. Contra un IDS con umbral por ventana temporal, eso es la diferencia entre disparar y no disparar — y es la única técnica de la nota que **sigue funcionando contra defensas modernas** ([[08 - Detección de escaneos y evasión moderna|low-and-slow]]).

Un `-p 1-65535` a `1/5s` son unos 3,8 días. Ese es el precio real del sigilo, y por eso se combina con acotar puertos: los 100 que importan a `1/5s` son 8 minutos.

# Cómo se detecta

## La paradoja de los escaneos de flags

Aquí está la parte que las guías siguen contando mal.

> [!important]+ Evaden el filtro y encienden el IDS
> FIN, NULL y Xmas fueron diseñados para atravesar **filtros de paquetes sin estado**. Contra un firewall con estado —lo normal desde hace dos décadas— <mark style="background: #FFB86CA6;">simplemente se descartan: no pertenecen a ninguna sesión conocida</mark>, así que ni siquiera llegan. Y contra un IDS son de las firmas **más antiguas y mejor cubiertas** que existen: un paquete NULL o Xmas no aparece en tráfico legítimo jamás, así que basta un solo paquete para una alerta de altísima confianza.
>
> Resultado en 2026: **poca capacidad de evasión y máxima capacidad de delatarte**. Son herramientas de diagnóstico contra dispositivos concretos, no una fase de reconocimiento sigilosa.

## Lo demás

- **Firma de un solo paquete** — un segmento TCP sin ningún flag (NULL) es imposible en tráfico real. Igual el Xmas. No hace falta contar ni correlacionar.
- **Combinaciones ilegales** — `syn,fin` es una violación de la especificación que cualquier IDS marca.
- **ARP scan** — un barrido ARP del `/24` es ruidoso a nivel L2 y lo ven las herramientas de monitorización de red y los switches con *port security* / *dynamic ARP inspection*. En una red con NAC bien montado, es lo que dispara la cuarentena del puerto.
- **Pila propia** — al construir tramas a mano, `sx` genera paquetes cuya combinación de opciones TCP y TTL no coincide con ningún SO, igual que [[05 - Evasión de firewalls e IDS con masscan|masscan]]. No tiene perfiles de imitación como [[04 - Evasión, detección y ética del escaneo a escala|ZMap]].

# Regla operativa

```
¿Quiero saber cómo filtra este firewall?    → sx tcp --flags ack / fin   (diagnóstico)
¿Quiero sigilo de verdad?                   → sx tcp --rate 1/5s -p <pocos puertos>
¿El objetivo es Windows?                    → NO uses fin/null/xmas: mienten
¿Hay un IDS delante?                        → null/xmas te delatan al primer paquete
```

<mark style="background: #FF5582A6;">La palanca de sigilo de `sx` es el ritmo, no los flags</mark>. Los flags son para aprender qué hay delante, y eso se paga con alertas — asúmelo y hazlo cuando el objetivo del sondeo lo justifique, no por costumbre.

> [!info]+ Fuentes
> - **RFC 9293** — *Transmission Control Protocol (TCP)*, agosto de 2022 (obsoleta la RFC 793): comportamiento de un puerto cerrado (`RST` en respuesta) y de uno en `LISTEN` (descarte silencioso) ante segmentos sin `SYN`/`ACK` válidos.
> - [README de sx](https://github.com/v-byte-cpu/sx) — subcomandos `fin`/`null`/`xmas`, `--flags` y sintaxis fraccionaria de `--rate`.
> - La desviación de la pila de Windows ante FIN/NULL/Xmas está documentada de largo en la referencia de tipos de escaneo de [nmap.org](https://nmap.org/book/scan-methods-null-fin-xmas-scan.html).
