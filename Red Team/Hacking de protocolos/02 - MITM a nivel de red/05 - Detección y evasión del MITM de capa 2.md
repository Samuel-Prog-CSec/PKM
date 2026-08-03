---
tags:
  - MITM
  - Redes
  - Evasion
  - Tipo/Deteccion
Descripción: "DAI, DHCP snooping, RA Guard, 802.1X y arpwatch: qué corta cada control, qué deja pasar y qué margen real queda para el atacante"
Fecha de actualización: 2026-08-03
Nota previa: "[[04 - DNS spoofing y redirección de nombres]]"
Nota siguiente: "[[06 - Arsenal de MITM de red]]"
Area: "[[MITM de red.base|MITM de red]]"
---
---

El MITM de capa 2 es de los ataques con **peor relación ruido/beneficio** que existen: funciona siempre en una red sin controles, y salta en una red que los tenga. Saber cuáles hay antes de lanzarlo es la diferencia entre un hallazgo y una llamada del SOC.

## Lo que deja cada técnica

| Ataque | Rastro observable | Dónde se ve |
| - | - | - |
| ARP poisoning | Dos IPs con la misma MAC; ráfagas de *gratuitous ARP*; cambios de MAC para una IP estable | Tabla de vecinos del host, `arpwatch`, DAI del switch |
| DHCP spoofing | `OFFER`/`ACK` desde un puerto no autorizado; concesiones fuera del pool | DHCP snooping, logs del servidor DHCP legítimo |
| DHCP starvation | Avalancha de `DISCOVER` con MACs distintas desde un puerto | Port security, contadores del switch |
| RA / DHCPv6 spoofing | RA desde una MAC que no es el router; DHCPv6 en una red que no lo usaba | RA Guard — **casi nunca activado** |
| DNS spoofing | Respuestas duplicadas para la misma consulta; TTL anómalos | Resolver, NDR, logs de DNS |
| Cualquiera + proxy TLS | Certificado de CA desconocida; huella JA4 distinta | Cliente, telemetría de EDR |

## Los controles, por eficacia

### Dynamic ARP Inspection (DAI)

Es **la** contramedida contra el ARP poisoning. El switch valida cada paquete ARP contra la tabla de asociaciones IP↔MAC↔puerto que ha construido el DHCP snooping (o contra ACLs estáticas para hosts con IP fija) y descarta lo que no cuadre.

```text
# Cisco IOS
ip dhcp snooping
ip dhcp snooping vlan 10
ip arp inspection vlan 10
interface Gi0/1
 ip dhcp snooping trust
 ip arp inspection trust        ← solo hacia el router y el servidor DHCP
```

Con DAI bien configurado, el ARP poisoning **muere en el puerto de acceso** y además genera un evento con el puerto físico exacto. No hay evasión: el ataque es incompatible con el control.

### DHCP snooping

Marca como *trusted* solo los puertos por los que puede llegar un servidor DHCP legítimo, y descarta `OFFER`/`ACK` del resto. Además construye la *binding table* que alimenta a DAI y a IP Source Guard. <mark style="background: #ADCCFFA6;">Es el control base del que dependen los demás</mark> — sin él, DAI necesita ACLs estáticas.

### RA Guard y DHCPv6 Guard

El equivalente para IPv6 ([RFC 6105](https://datatracker.ietf.org/doc/html/rfc6105)). Y aquí está el hueco que hace tan rentable [[03 - IPv6 - RA spoofing y DHCPv6 con mitm6|mitm6]]: **hay que habilitarlo explícitamente**, no viene por defecto, y muchísimas redes que tienen DAI y DHCP snooping bien montados en IPv4 tienen IPv6 completamente desatendido.

Hay técnicas de evasión conocidas de RA Guard basadas en **cabeceras de extensión y fragmentación de IPv6** — un RA partido en fragmentos que el switch no reensambla pero el host sí. El [RFC 7113](https://datatracker.ietf.org/doc/html/rfc7113) documenta el problema y el [RFC 6980](https://datatracker.ietf.org/doc/html/rfc6980) lo cierra prohibiendo NDP fragmentado, pero **depende de que la implementación del switch esté al día**.

### 802.1X y NAC

Autenticación antes de dar acceso al puerto. Impide conectar un equipo no autorizado, que es el requisito previo de todo lo anterior. Sus límites conocidos:

- **MAB** (*MAC Authentication Bypass*) para impresoras y teléfonos IP: si el puerto autoriza por MAC, clonar la MAC de la impresora te da acceso.
- **Bridging tras el suplicante**: un dispositivo transparente entre el equipo autenticado y la roseta hereda la sesión ya autenticada.
- **Sin MACsec**, 802.1X autentica **al inicio** y no protege las tramas posteriores.

### Detección desde el endpoint

```shell-session
# Linux: la tabla de vecinos, buscando MACs duplicadas
$ ip neigh | awk '{print $5}' | sort | uniq -d

# arpwatch: alerta por cambios de asociación IP↔MAC
$ sudo arpwatch -i eth0

# Windows
C:\> arp -a
C:\> netsh interface ipv6 show neighbors
```

Una entrada ARP **estática** para el gateway inmuniza a un host concreto:

```shell-session
$ sudo ip neigh replace 192.168.1.1 lladdr aa:bb:cc:dd:ee:ff dev eth0 nud permanent
```

## Qué margen queda para el atacante

Con honestidad, porque exagerar aquí es contraproducente:

- **Contra DAI bien configurado: ninguno.** El ARP poisoning no es evadible; es incompatible. Cambia de vector.
- **La vía viva es IPv6.** Es asimétrico: la defensa IPv4 está madura y la IPv6 casi nunca se ha tocado. Empieza siempre por ahí.
- **Reducir el alcance reduce la detección.** Envenenar un host en vez de la subred, o desviar un nombre por DNS en vez de secuestrar el gateway, baja el ruido en un orden de magnitud. La **opción 121 de DHCP** (rutas estáticas) es la versión sigilosa de hacerse gateway.
- **Aprovechar renovaciones naturales.** El DHCP spoofing no genera tráfico anómalo si simplemente ganas la carrera cuando el cliente renueva por su cuenta.
- **Y el hueco de siempre**: las redes con controles fuertes en el acceso corporativo suelen tener VLANs de invitados, de gestión, de OT o de laboratorio donde no se ha configurado nada.

> [!warning]+ La regla de alcance
> Todo lo de esta nota afecta al **dominio de difusión completo**, no solo al objetivo. Un DAI que salta desconecta el puerto (`err-disable`); un DHCP starvation deja sin IP a toda la planta. En un *engagement* esto se autoriza por escrito, con VLAN y ventana horaria acotadas, y con un contacto disponible para revertir. No es una formalidad: es el ataque con más probabilidad de causar una interrupción no planificada.

> [!info]+ Fuentes
> - [RFC 6105](https://datatracker.ietf.org/doc/html/rfc6105) (RA-Guard), [RFC 7113](https://datatracker.ietf.org/doc/html/rfc7113) (evasión por fragmentación) y [RFC 6980](https://datatracker.ietf.org/doc/html/rfc6980) (prohibición de NDP fragmentado).
> - Cisco — *Configuring Dynamic ARP Inspection* y *DHCP Snooping*, guías de configuración de la serie Catalyst.
> - MITRE ATT&CK [T1557](https://attack.mitre.org/techniques/T1557/) y sus sub-técnicas, con las mitigaciones M1041/M1037.
