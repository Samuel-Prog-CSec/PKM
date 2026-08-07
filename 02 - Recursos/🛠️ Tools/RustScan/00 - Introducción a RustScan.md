---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Introduccion
Descripción: "Los 65k puertos de un host en segundos y el relevo automático a Nmap — pero hace connect completo, no SYN, y eso lo cambia todo"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Configuración, rendimiento y Scripting Engine]]"
Area: "[[RustScan.base|RustScan]]"
---
---

<mark style="background: #ADCCFFA6;">RustScan es un descubridor de puertos asíncrono escrito en Rust cuya única función real es encontrar puertos abiertos deprisa y **pasárselos a Nmap**</mark>. Anuncia recorrer los 65.535 puertos de un host en 3 segundos en el mejor caso.

A diferencia de [[00 - Introducción a masscan y el escaneo stateless|masscan]] y [[00 - Introducción a ZMap y el escaneo a escala de Internet|ZMap]], que están pensados para lo ancho (muchos hosts, pocos puertos), RustScan está pensado para **lo profundo**: un host o un puñado de ellos, todos los puertos. Es el caso de uso del pentest de un objetivo concreto y de las máquinas de laboratorio, y por eso es la herramienta que más se ve en los *writeups*.

# El dato que cambia todo: hace connect, no SYN

Aquí está lo que ninguna comparativa menciona y determina cuándo puedes usarlo.

masscan y ZMap construyen paquetes crudos y mandan un `SYN` suelto. RustScan **usa la pila del sistema operativo** y abre la conexión entera:

```rust
async fn connect(&self, socket: SocketAddr) -> io::Result<TcpStream> {
    let stream = io::timeout(
        self.timeout,
        async move { TcpStream::connect(socket).await },
    ).await?;
    Ok(stream)
}
```

Y al encontrar el puerto abierto, cierra ordenadamente: `tcp_stream.shutdown(Shutdown::Both)`.

Consecuencias, en orden de importancia:

| | Implicación |
| --- | --- |
| **No necesita `root`** | Es la única de estas herramientas que corre como usuario normal. Muy cómodo. |
| <mark style="background: #FF5582A6;">**Completa el handshake en cada puerto abierto**</mark> | Es el escaneo **más ruidoso que existe**. Cada acierto deja registro en la aplicación, no solo en el IDS. |
| **Respeta el firewall local y el enrutado** | Sale por donde diría el sistema; no hay sorpresas de interfaz. |
| **Sujeto a los límites del SO** | De ahí el problema del `ulimit` de [[01 - Configuración, rendimiento y Scripting Engine]]. |

<mark style="background: #8000E1A6;">Traducido: RustScan es rápido y cómodo, y es exactamente lo que **no** debes usar si te importa el sigilo</mark>. Un `-sS` de Nmap deja el handshake a medias y muchos servicios ni se enteran; RustScan se conecta y se desconecta de todos y cada uno de los puertos abiertos, lo que en un servidor web es una línea en el log y en un SSH un `Connection closed by ... [preauth]` por cada pasada.

# El pipeline con Nmap

Su razón de ser. Todo lo que va **después de `--`** se le pasa tal cual a Nmap:

```shell-session
$ rustscan -a 10.129.2.28 --range 1-65535 -- -sCV -oA objetivo
#           └ descubre en segundos          └ Nmap solo sobre lo que encontró
```

```shell-session
$ rustscan -a 10.129.2.28 -- -A -sC -T4
$ rustscan -a objetivos.txt --top -- -sV --script vuln
$ rustscan -a 10.129.0.0/24 -g                    # solo puertos, sin Nmap
```

Es el mismo reparto de trabajo de [[03 - Salidas y pipeline hacia Nmap|masscan → Nmap]], empaquetado en un solo comando. `-g/--greppable` corta la parte de Nmap y escupe solo los puertos, para encadenar a mano.

> [!important]+ Qué escaneo lanza Nmap después
> RustScan invoca a Nmap con los puertos que encontró. Si no le pasas nada tras `--`, Nmap corre con sus opciones por defecto. <mark style="background: #FFB8EBA6;">Y ojo: ese Nmap **sí** hará `-sS` si tienes privilegios</mark>, así que el escaneo acaba siendo connect (RustScan) + SYN (Nmap) sobre los mismos puertos — el objetivo ve las dos cosas.

# Adaptive Learning

El proyecto agrupa bajo este nombre un conjunto de ajustes automáticos: RustScan afina sus parámetros según el sistema anfitrión y el comportamiento observado. En la práctica, lo que verás es que ajusta solo el `batch size` al límite de descriptores de fichero de tu máquina.

Es útil y también es la razón de que <mark style="background: #FFB8EBA6;">el mismo comando dé resultados distintos en dos máquinas</mark>: si una tiene el `ulimit` bajo, RustScan baja el lote y el escaneo se comporta de otra forma. Para resultados reproducibles hay que fijar `-b` y `-u` a mano ([[01 - Configuración, rendimiento y Scripting Engine]]).

# Cuándo usarlo

| Escenario | ¿RustScan? |
| --- | --- |
| Un host, todos los puertos, con permiso y sin sigilo | **Sí** — es su mejor caso |
| Laboratorio, CTF, máquina de HTB | **Sí**, es lo más cómodo que hay |
| Rango grande (`/16`, `/8`) | No — [[00 - Introducción a masscan y el escaneo stateless\|masscan]] o [[00 - Introducción a ZMap y el escaneo a escala de Internet\|ZMap]] |
| Sin privilegios de `root` | **Sí**, es el único que no los pide |
| Fase sigilosa de un engagement | **No.** Connect completo en cada puerto abierto |
| Red con pérdidas o latencia alta | Con cuidado: sube `--timeout` y `--tries` o dará falsos negativos |

> [!warning]+ Fiabilidad en redes malas
> RustScan es conocido por dar **falsos negativos en redes inestables** — un timeout de 1.500 ms por defecto es corto para una VPN mala o un objetivo al otro lado del mundo. El escáner asume cerrado lo que no contesta a tiempo. Si el resultado te parece sospechosamente escueto, sube `-t` y `--tries` antes de concluir nada; y confirma siempre con Nmap, que aguanta mucho mejor la pérdida de paquetes ([[05 - Rendimiento y timing]]).

> [!info]+ Estado del proyecto (verificado 2026-08-04)
> **v2.4.1 (febrero de 2025)**, con commits en julio de 2026 y ~20.000 estrellas. Vivo, aunque el ritmo de *releases* es lento. El repositorio oficial es **`bee-san/RustScan`**.

> [!info]+ Fuentes
> - [Repositorio de RustScan](https://github.com/bee-san/RustScan) — README (velocidad, Adaptive Learning, Scripting Engine, pipeline con Nmap).
> - Código fuente `src/scanner/mod.rs` — `TcpStream::connect()` con timeout y `shutdown(Shutdown::Both)`: la prueba de que es un *connect scan* y no un SYN scan.
