---
tags:
  - MITM
  - Redes
  - Pentesting/Explotacion
Descripción: "Ganar la carrera al DHCP legítimo para repartir tu gateway y tu DNS, y por qué es más silencioso y más duradero que el ARP poisoning"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - ARP poisoning]]"
Nota siguiente: "[[03 - IPv6 - RA spoofing y DHCPv6 con mitm6]]"
Area: "[[MITM de red.base|MITM de red]]"
---
---

`ARP` te mete en el camino de un host **ya configurado**. `DHCP` te deja configurarlo tú desde el principio: si controlas la respuesta, decides su **gateway por defecto**, sus **servidores DNS**, su dominio de búsqueda, su ruta estática y su servidor WPAD. Es más limpio, dura toda la concesión y <mark style="background: #8000E1A6;">el objetivo no está siendo engañado: está haciendo exactamente lo que le mandaron</mark>.

## El intercambio DORA

DHCP ([RFC 2131](https://datatracker.ietf.org/doc/html/rfc2131)) va sobre UDP, del puerto 68 al 67, y arranca por difusión porque el cliente aún no tiene IP:

| Paso | Quién | Qué |
| - | - | - |
| **D**iscover | Cliente → difusión | «¿Hay algún DHCP?» |
| **O**ffer | Servidor → cliente | «Toma esta IP y esta configuración» |
| **R**equest | Cliente → difusión | «Acepto la de este servidor» |
| **A**cknowledge | Servidor → cliente | «Confirmado» |

Los dos fallos: **no hay autenticación** (la opción 90 del [RFC 3118](https://datatracker.ietf.org/doc/html/rfc3118) existe desde 2001 y **no la implementa prácticamente nadie**), y **el cliente se queda con la primera oferta que llega**. El ataque es, literalmente, una carrera.

## Ganar la carrera

Tres formas, de menos a más agresiva:

1. **Estar más cerca.** Si estás en el mismo segmento y el DHCP legítimo está detrás de un *relay*, tu respuesta llega antes sin hacer nada especial.
2. **Responder más rápido.** Un servidor sin lógica de asignación responde en microsegundos; uno corporativo consulta IPAM y bases de datos.
3. **Agotar el pool legítimo** (*DHCP starvation*). Pides todas las direcciones disponibles con MACs falsificadas; cuando el servidor real se queda sin IPs, todas las peticiones nuevas solo las puedes atender tú. Es efectivo y **muy ruidoso** — es una denegación de servicio contra el DHCP corporativo, y hay que tenerlo autorizado por escrito.

## Ejecución

**bettercap**:

```shell-session
$ sudo bettercap -iface eth0
> set dhcp6.spoof.domains microsoft.com     # el módulo IPv6, ver la nota siguiente
> set arp.spoof.targets ...
```

**Ettercap**, que es lo que usa el libro y sigue funcionando:

```shell-session
$ sudo ettercap -T -q -i eth0 -M dhcp:192.168.1.100-150/255.255.255.0/192.168.1.50
#                                      pool a repartir  /   máscara     /   DNS
```

En el GUI: `Sniff → Unified Sniffing`, luego `Mitm → Dhcp spoofing`. La línea que confirma que funciona en el log es **`fake ACK`** en respuesta al `Request` del cliente.

**dnsmasq** como servidor propio, que es la vía más controlable:

```shell-session
$ sudo dnsmasq -d -i eth0 \
    --dhcp-range=192.168.1.100,192.168.1.150,1h \
    --dhcp-option=3,192.168.1.50 \      # opción 3: gateway = tú
    --dhcp-option=6,192.168.1.50 \      # opción 6: DNS = tú
    --dhcp-option=252,"http://192.168.1.50/wpad.dat"   # opción 252: WPAD
```

**`Responder`** trae `DHCP.py` para el mismo fin, integrado con su captura de credenciales.

> [!important]+ Las opciones que de verdad importan
> No te quedes en gateway y DNS. Las que dan más juego:
>
> - **Opción 3** (router) → te conviertes en el gateway. Requiere `ip_forward` y SNAT.
> - **Opción 6** (DNS) → controlas la resolución de nombres sin tocar ARP. A menudo **más rentable que ser el gateway**, porque redirige selectivamente y pasa mucho más desapercibido.
> - **Opción 252** (WPAD) → el cliente descarga un fichero de autoconfiguración de proxy y **envía su tráfico HTTP/HTTPS a tu proxy voluntariamente**. En entornos Windows esto es de lo más productivo que existe: combinado con autenticación NTLM, es la vía directa a capturar y retransmitir hashes ([[06 - Envenenamiento LLMNR y NBT-NS]]).
> - **Opción 121 / 249** (rutas estáticas sin clase) → inyectas rutas concretas en vez de secuestrar el gateway entero. **Mucho más sigiloso**: solo desvías el tráfico hacia el rango que te interesa y el resto sigue su camino normal.

## Frente a ARP poisoning

| | ARP poisoning | DHCP spoofing |
| - | - | - |
| **Momento** | En cualquier momento | Solo en arranque o renovación |
| **Duración** | Hay que refrescar constantemente | Toda la concesión (horas o días) |
| **Ruido** | Alto: ráfagas continuas de ARP | Bajo: unos pocos paquetes |
| **Detección** | Trivial (DAI, `arpwatch`) | DHCP snooping, si está configurado |
| **Alcance** | Hosts concretos | Quien renueve mientras estés activo |
| **Control** | Solo el camino | Gateway, DNS, WPAD, rutas, dominio |

La paciencia es el coste: puedes esperar horas a que alguien renueve. Se fuerza provocando reconexiones —desautenticación Wi-Fi ([[01 - Tramas de gestión y su valor ofensivo]]), o simplemente al empezar la jornada, cuando todos los portátiles arrancan a la vez.

## Detección y defensa

**DHCP snooping** en el switch es la contramedida: se marcan los puertos donde puede haber un DHCP legítimo como *trusted* y se descartan `OFFER`/`ACK` que vengan de cualquier otro. Con eso el ataque muere en el puerto de acceso. Detalle en [[05 - Detección y evasión del MITM de capa 2]].

> [!info]+ Fuentes
> - [RFC 2131](https://datatracker.ietf.org/doc/html/rfc2131) (DHCP) y [RFC 3118](https://datatracker.ietf.org/doc/html/rfc3118) (autenticación, prácticamente sin implementar).
> - [RFC 3442](https://datatracker.ietf.org/doc/html/rfc3442) — opción 121 de rutas estáticas sin clase.
> - [dnsmasq — man page](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html), sección `--dhcp-option`.
> - MITRE ATT&CK [T1557](https://attack.mitre.org/techniques/T1557/) — *Adversary-in-the-Middle*.
