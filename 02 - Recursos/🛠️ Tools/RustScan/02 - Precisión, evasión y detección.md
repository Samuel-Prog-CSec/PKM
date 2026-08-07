---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Deteccion
Descripción: "RustScan es el escáner más fácil de detectar del arsenal, y no por descuido: completar el handshake es su diseño"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Configuración, rendimiento y Scripting Engine]]"
Nota siguiente:
Area: "[[RustScan.base|RustScan]]"
---
---

Con RustScan la respuesta a "¿cómo lo hago sigiloso?" es corta: **no se puede**. Merece la pena entender por qué, porque el motivo es estructural y explica también sus problemas de precisión.

# Por qué es indisimulable

<mark style="background: #FF5582A6;">RustScan hace `TcpStream::connect()` y luego `shutdown(Shutdown::Both)`</mark> ([[00 - Introducción a RustScan]]). Sobre cada puerto abierto que encuentra, el objetivo ve:

```
  RustScan                                    objetivo
     │──────────── SYN ─────────────────────────▶│
     │◀─────────── SYN/ACK ──────────────────────│
     │──────────── ACK ─────────────────────────▶│   ← conexión ESTABLECIDA
     │──────────── FIN ─────────────────────────▶│   ← y cerrada acto seguido
```

Eso no es un escaneo de red: es una **conexión completa** a la aplicación. Y una conexión completa deja rastro donde el SYN scan no llega:

| Servicio | Lo que registra |
| --- | --- |
| nginx / Apache | Entrada en `access.log` (típicamente `400` por petición vacía) |
| OpenSSH | `Connection closed by <IP> port <n> [preauth]` en `auth.log` |
| Bases de datos | Intento de conexión fallido, a menudo con alerta |
| Aplicaciones a medida | Lo que su código registre al aceptar un socket |

<mark style="background: #8000E1A6;">Un `-sS` de Nmap deja el handshake a medias y muchos servicios ni se enteran; RustScan garantiza una línea de log por cada puerto abierto</mark>. En una caja con 30 servicios, son 30 evidencias con tu IP y hora exacta, en sitios que el cliente revisa después del engagement.

Añade la firma de red: **cientos o miles de conexiones establecidas y cerradas inmediatamente desde un mismo origen** en pocos segundos. Es de las señales más limpias que puede pedir un defensor — mucho más inequívoca que un patrón de SYN sueltos, que puede confundirse con tráfico legítimo con pérdidas.

> [!important]+ Contrapartida real (que sí juega a favor)
> El *connect scan* tiene una ventaja que conviene reconocer: <mark style="background: #FFB8EBA6;">atraviesa cualquier cosa que un cliente legítimo atravesaría</mark>. Si hay un firewall con inspección de estado, un proxy transparente o una VPN que rompe los paquetes crudos, un escaneo SYN puede fallar y el connect funcionar. Cuando `masscan`/`nmap -sS` no devuelven nada raro pero sospechas del camino, un connect scan es la prueba de contraste.

# Lo poco que hay para reducir ruido

| Palanca | Qué consigue |
| --- | --- |
| `--scan-order random` | Rompe la secuencia ascendente 1,2,3… que dispara las reglas más simples. |
| `-b` bajo (`--batch-size 50-200`) | Baja la concurrencia y con ella el pico de conexiones por segundo. |
| `-p` acotado en vez de `-r 1-65535` | Menos puertos = menos huella. Pisar menos puertos también evita canarios. |
| `--exclude-ports` | Sacar del barrido puertos-trampa conocidos o servicios frágiles. |
| `--scripts none` | Evita la fase Nmap y su ruido añadido. |
| `proxychains` / SOCKS | Al usar sockets del SO, <mark style="background: #ADCCFFA6;">RustScan **sí** funciona a través de un proxy SOCKS</mark>, cosa que masscan y ZMap no pueden. |

Ese último punto es el único caso donde RustScan gana claramente en OPSEC: en post-explotación, escaneando la red interna **a través de un túnel** desde un host comprometido, un escáner de paquetes crudos no sirve y uno de sockets sí. Es el escenario de [[Pivoting y túneles.base|pivoting]], y ahí RustScan encaja bien con `proxychains` o un SOCKS de Ligolo-ng.

```shell-session
$ proxychains -q rustscan -a 172.16.5.0/24 --top -b 100 -g
```

> [!warning]+ Ojo con `proxychains` y el timeout
> Cada conexión a través del túnel suma latencia. Con `-t 1500` por defecto sobre un SOCKS que ya va lento, la mitad de los puertos abiertos se marcan cerrados. Sube `-t` a 5000-8000 ms y baja `-b`, o el escaneo miente.

# Precisión: las tres causas de falso negativo

Ordenadas por frecuencia real:

1. **`ulimit` agotado** — el lote por defecto (4500) supera el límite típico (1024) y los sobrantes se cuentan como cerrados sin avisar. Solución: `-u` o `-b` bajo ([[01 - Configuración, rendimiento y Scripting Engine]]).
2. **Timeout corto para la latencia real** — 1.500 ms no llegan por VPN, por SOCKS o contra objetivos lejanos. Solución: `-t` alto.
3. **Rate-limiting del objetivo** — un lote grande dispara la protección y el objetivo empieza a descartar. Solución: `-b` bajo y `--tries 2-3`.

Las tres se manifiestan igual: un resultado limpio, plausible e **incompleto**. Por eso la regla es la misma que con masscan — <mark style="background: #FFB86CA6;">nunca escribas "el puerto está cerrado" a partir de un solo escaneo rápido</mark>. Confirma con Nmap, que distingue `closed` de `filtered` y reintenta con criterio ([[02 - Escaneo de puertos y hosts]]).

# Cómo se detecta

- **Umbral de conexiones** — `Suricata`, `Zeek` y cualquier regla de SIEM sobre conexiones establecidas por origen. Es detección trivial: no hace falta inspeccionar nada, basta contar.
- **Ratio conexión/duración** — miles de sesiones TCP de duración ~0 ms. Ningún tráfico legítimo tiene ese perfil.
- **Logs de aplicación** — la evidencia más incómoda, porque sobrevive a la retención del IDS y la ve el cliente.
- **Fingerprinting de pila: ninguno** — al usar la pila del SO, los paquetes son *indistinguibles* de los de cualquier cliente. Es lo único que RustScan hace "bien" en detección, e irónicamente no sirve de nada porque lo delata el comportamiento.

# Regla operativa

```
¿Lab / CTF / permiso amplio y prisa?     → RustScan, es lo más cómodo
¿Escaneo interno a través de un túnel?   → RustScan (los crudos no pasan por SOCKS)
¿Fase sigilosa de un engagement real?    → NO. Nmap -sS -T1, o recon pasivo
¿Sin root?                               → RustScan es la única opción del arsenal
```

> [!info]+ Fuentes
> - Código fuente `src/scanner/mod.rs` del [repositorio de RustScan](https://github.com/bee-san/RustScan) — `TcpStream::connect()` + `shutdown(Shutdown::Both)`, y la lógica de reintentos sobre `--tries`.
> - Contexto de detección por comportamiento y umbral en [[08 - Detección de escaneos y evasión moderna]]; MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/).
