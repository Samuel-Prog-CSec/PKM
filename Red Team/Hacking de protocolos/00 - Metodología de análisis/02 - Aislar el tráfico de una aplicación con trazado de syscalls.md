---
tags:
  - Protocolos
  - Linux
  - Windows
  - Pentesting/Enumeracion
Descripción: "Sacar los datos de red de un proceso concreto sin sniffer: strace, eBPF, Process Monitor y hooking con Frida cuando no tienes privilegios o el tráfico está mezclado"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - Captura pasiva y sus límites]]"
Nota siguiente: "[[03 - Proxies de intercepción para protocolos no-HTTP]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

Un *sniffer* ve el cable; no ve **qué proceso** generó cada byte. Si el host ejecuta veinte cosas a la vez, o si no tienes privilegios para capturar, o si el protocolo va cifrado y quieres verlo **antes** de que se cifre, la vía es interceptar la frontera entre la aplicación y el *kernel*: las llamadas al sistema de sockets.

## Dónde está la frontera

Casi todo Unix implementa el modelo *Berkeley Sockets* (por eso es el de facto: IP se implementó primero en BSD 4.2 y acabó en POSIX). Las llamadas que importan:

| Llamada | Qué hace |
| - | - |
| `socket` | Crea el descriptor de fichero del socket |
| `connect` | Conecta a una IP y puerto conocidos |
| `bind` / `listen` / `accept` | Lado servidor: escuchar y aceptar |
| `read` / `recv` / `recvfrom` / `recvmsg` | Recibe datos |
| `write` / `send` / `sendto` / `sendmsg` | Envía datos |

<mark style="background: #8000E1A6;">Interceptar `read`/`write` sobre el descriptor del socket te da el flujo de aplicación en claro</mark>, con el proceso ya identificado y sin tocar la red.

## Linux: de `strace` a eBPF

`strace` es el camino corto y **no requiere `root`** si el proceso corre con tu usuario:

```shell-session
$ strace -f -e trace=network,read,write -s 65535 -o traza.log ./cliente servidor.local
```

- `-f` sigue los hijos (`fork`), imprescindible en servidores que bifurcan por conexión.
- `-s 65535` evita que trunque las cadenas a 32 bytes — sin esto el volcado es inútil.
- `-e trace=network,read,write` limita el ruido.

```text
socket(PF_INET, SOCK_STREAM, IPPROTO_TCP) = 3
connect(3, {sa_family=AF_INET, sin_port=htons(5555),
        sin_addr=inet_addr("192.168.10.1")}, 16) = 0
write(3, "Hello World!\n", 13)          = 13
read(3, "Boo!\n", 2048)                 = 5
```

Se lee de corrido: socket TCP con descriptor `3`, conexión a `192.168.10.1:5555`, envío y recepción.

> [!warning]+ `strace` es caro y detectable
> `ptrace` intercepta cada llamada con dos cambios de contexto: puede ralentizar un proceso de red **10-100×** y romper protocolos con temporizadores. Además `strace` es trivial de detectar desde el propio proceso (`TracerPid` en `/proc/self/status`, o un `ptrace(PTRACE_TRACEME)` que falla porque ya hay un *tracer*). Muchos productos con anti-*debugging* se niegan a arrancar. Para binarios que se resisten, `eBPF` no usa `ptrace` y no aparece en `TracerPid`.

**La vía moderna es eBPF.** El libro (2018) propone `DTrace`, que sigue vivo en macOS/FreeBSD/illumos pero que en Linux ha sido desplazado por completo:

```shell-session
# Conexiones salientes de todo el sistema, con nombre de proceso
$ sudo bpftrace -e 'tracepoint:syscalls:sys_enter_connect { printf("%s(%d)\n", comm, pid); }'

# Herramientas ya hechas de bcc-tools
$ sudo tcpconnect -P 443          # conexiones TCP salientes
$ sudo tcplife                    # sesiones TCP con duración y bytes
$ sudo sslsniff                   # ¡tráfico TLS en claro, hookeando OpenSSL/GnuTLS/NSS!
```

`sslsniff` merece atención aparte: engancha `SSL_read`/`SSL_write` en la librería, con lo que <mark style="background: #FF5582A6;">ves el texto plano de conexiones TLS sin descifrar nada ni interponerte</mark>. Es la respuesta más limpia al problema del cifrado cuando controlas el host.

Microsoft publicó además **ProcMon for Linux** (Sysinternals, basado en eBPF), con la interfaz de filtrado de Procmon sobre trazado de *syscalls*.

## macOS: DTrace con matices

`DTrace` sigue siendo la herramienta natural, pero **System Integrity Protection lo restringe** desde El Capitán: los binarios firmados por Apple y las apps sin la *entitlement* `com.apple.security.get-task-allow` no son trazables sin desactivar SIP en modo recovery (`csrutil enable --without dtrace`). Para aplicaciones propias o de terceros sin protección, funciona:

```shell-session
$ sudo dtrace -n 'syscall::connect:entry { printf("%s %d", execname, pid); }'
```

## Windows: sin syscalls, con ETW

Windows **no expone el stack de red por llamadas al sistema directas**: el subsistema se maneja por driver (`afd.sys`) mediante `NtDeviceIoControlFile`, así que no hay un `strace` equivalente. Lo que sí hay:

- **Process Monitor** (Sysinternals). Filtro por `Operation` → categoría *Network*. Da proceso, protocolo, extremos y —muy útil para el paso siguiente— **la pila de llamadas** en el momento de la conexión. No da los datos, pero sí te dice *dónde* en el binario se establece la conexión, que es justo el punto de entrada de [[02 - Localizar el código de red en un binario]].
- **ETW** (*Event Tracing for Windows*), proveedores `Microsoft-Windows-TCPIP` y `Microsoft-Windows-Winsock-AFD`. Es la vía programática; `pktmon` (integrado desde Windows 10 1809) permite captura por PID sin instalar nada:

```shell-session
C:\> pktmon start --capture --pkt-size 0 -f captura.etl
C:\> pktmon etl2pcap captura.etl -o captura.pcap
```

- **eBPF for Windows** existe, pero a día de hoy cubre sobre todo observabilidad de red (XDP) y no reemplaza a ETW para este uso.

## El comodín: hooking con Frida

Cuando ninguna de las anteriores llega —protocolo cifrado con implementación propia, app móvil, binario con anti-*debug*— la respuesta es **instrumentar el proceso en runtime**. `Frida` inyecta un motor de JavaScript y permite enganchar cualquier función exportada:

```javascript
// Volcar todo lo que pasa por send() antes de salir al cable
Interceptor.attach(Module.getExportByName(null, 'send'), {
  onEnter(args) {
    console.log(hexdump(args[1].readByteArray(args[2].toInt32())));
  }
});
```

Enganchando la función de **cifrado propietaria** en vez del socket, obtienes el texto plano de un protocolo que ningún proxy podría descifrar. Es la técnica que convierte un análisis bloqueado en uno trivial, y se desarrolla en [[03 - Reversing dinámico - debuggers y hooking]].

> [!info]+ Fuentes
> - `man 2 socket`, `man 1 strace`; [bcc-tools](https://github.com/iovisor/bcc) y [bpftrace](https://github.com/bpftrace/bpftrace) para el equivalente eBPF.
> - [Frida](https://frida.re/docs/javascript-api/) — API de `Interceptor` y `Module`.
> - [`pktmon`](https://learn.microsoft.com/en-us/windows-server/networking/technologies/pktmon/pktmon) — documentación de Microsoft.
> - Restricciones de DTrace bajo SIP: documentación de Apple sobre *System Integrity Protection*.
