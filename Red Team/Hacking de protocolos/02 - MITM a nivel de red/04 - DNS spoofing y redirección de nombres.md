---
tags:
  - MITM
  - Redes
  - Pentesting/Explotacion
Descripción: "Redirigir por nombre en vez de por ruta: DNS falso en la LAN, envenenamiento de caché y por qué DoH y DNSSEC cambian el cálculo pero no lo cierran"
Fecha de actualización: 2026-08-03
Nota previa: "[[03 - IPv6 - RA spoofing y DHCPv6 con mitm6]]"
Nota siguiente: "[[05 - Detección y evasión del MITM de capa 2]]"
Area: "[[MITM de red.base|MITM de red]]"
---
---

ARP y DHCP te ponen en la ruta; DNS te deja redirigir **por nombre**, que es más selectivo y mucho más silencioso. Solo desvías `api.objetivo.com` y el resto del tráfico sigue su camino normal — nadie pierde conectividad, nadie se queja, no hay ráfagas de paquetes anómalos.

Esta nota cubre el DNS como **vector de redirección hacia tu proxy**. El ataque a DNS como servicio (transferencias de zona, *subdomain takeover*, enumeración) está en [[08 - Ataque a DNS]], y los fundamentos del protocolo en [[DNS]].

## Vía 1: ser el servidor DNS del cliente

La más fácil, si ya controlas la configuración de red por [[02 - DHCP spoofing y rogue DHCP|DHCP]] (opción 6), por [[03 - IPv6 - RA spoofing y DHCPv6 con mitm6|DHCPv6]] o porque puedes tocar el cliente.

```shell-session
# dnsmasq: responde tu IP a TODO
$ sudo dnsmasq -d -i eth0 --address=/#/192.168.1.50 --no-resolv

# Selectivo: solo un dominio, el resto se reenvía al DNS real
$ sudo dnsmasq -d -i eth0 --server=8.8.8.8 --address=/api.objetivo.com/192.168.1.50
```

**`dnschef`** es más cómodo para reglas por tipo de registro y por expresión regular:

```shell-session
$ dnschef --fakeip 192.168.1.50 --fakedomains api.objetivo.com,*.interno.local \
          --nameserver 8.8.8.8
```

La versión selectiva es la buena: <mark style="background: #8000E1A6;">redirigir un solo nombre no rompe nada y no se nota</mark>. Responder tu IP a todo tumba la navegación del objetivo en el primer minuto.

## Vía 2: responder antes que el servidor real

Si ya estás en el camino (ARP/DHCP/Wi-Fi), puedes contestar tú a la consulta antes de que llegue la del servidor legítimo. Es una carrera, pero la ganas casi siempre porque estás más cerca.

```shell-session
$ sudo bettercap -iface eth0
> set dns.spoof.domains api.objetivo.com
> set dns.spoof.address 192.168.1.50
> set arp.spoof.targets 192.168.1.5
> arp.spoof on; dns.spoof on
```

El `dnsspoof` de `dsniff` que menciona el libro sigue existiendo, pero `bettercap` integra el envenenamiento y el spoofing en un solo flujo.

## Vía 3: envenenamiento de caché (ya no es la vía)

El ataque clásico —adivinar el TXID de 16 bits y adelantarse a la respuesta legítima— lo hizo práctico Kaminsky en 2008 al atacar nombres inexistentes con registros *glue*. La mitigación fue la **aleatorización del puerto de origen**, que subió la entropía de 16 a ~32 bits.

Volvió con **SAD DNS** (CVE-2020-25705 y variantes de 2021), que usa el límite de velocidad de ICMP como canal lateral para inferir el puerto de origen y devolver el ataque a ~16 bits. Se mitigó en el kernel de Linux aleatorizando ese límite.

Conclusión práctica: <mark style="background: #FFB8EBA6;">el envenenamiento de caché remoto es hoy investigación, no herramienta de pentest</mark>. En un *engagement*, la redirección DNS se consigue estando en la LAN, no adivinando TXIDs.

## Lo que rompe la vía DNS

| Defensa | Qué corta | Qué NO corta |
| - | - | - |
| **DNSSEC** | Respuestas falsificadas para zonas firmadas | Nada dentro de zonas internas sin firmar (la mayoría) |
| **DoH / DoT** | Ver y modificar las consultas en el camino | Un DNS que tú controlas y el cliente acepta |
| **HSTS + preload** | Degradar a HTTP tras redirigir | La conexión en sí (verá error de certificado) |
| **Certificate pinning** | Suplantar el servidor con tu CA | Que la conexión llegue a ti |

**DoH y DoT** son el cambio grande frente a 2018. Si el navegador resuelve por DNS-over-HTTPS contra Cloudflare o Google, tu DNS de la LAN **no ve nada**: ni las consultas ni la oportunidad de responder. Firefox lo lleva activo por defecto en varios mercados y Chrome usa *Secure DNS* automáticamente cuando el resolver configurado lo soporta.

Vías para lidiar con ello, en un entorno autorizado:
- **Bloquear los resolvers DoH conocidos** por IP/SNI, que es lo que hacen las propias empresas para conservar visibilidad. Firefox además respeta el dominio canario `use-application-dns.net`: si resuelve a `NXDOMAIN`, desactiva DoH.
- **Aceptar que solo redirigirás lo que resuelva por el sistema** — que sigue siendo casi todo lo que no es un navegador moderno: clientes propietarios, servicios, dispositivos empotrados. Y ese es justamente el objetivo de esta área.

> [!warning]+ Redirigir por DNS no descifra TLS
> Que el cliente llegue a tu servidor no significa que confíe en él. Verá un error de certificado, salvo que hayas conseguido que confíe en tu CA ([[04 - Redirigir el tráfico hacia tu proxy]]). Con **HSTS** ni siquiera podrá saltarse el aviso, y con *pinning* fallará sin preguntar. La redirección DNS es **el transporte**, no la solución del cifrado.

## Y su uso más rentable: nombres internos

Donde el DNS spoofing sigue siendo devastador es en **nombres internos que no tienen certificado válido de todos modos**: `\\fileserver`, `intranet`, `wpad`, `sccm`, `mssql-prod`. Ahí no hay HSTS, no hay pinning, y muchas veces no hay ni TLS. Es el mismo terreno que cubren `Responder` para LLMNR/NBT-NS/mDNS ([[06 - Envenenamiento LLMNR y NBT-NS]]) y `mitm6` para IPv6 — tres protocolos de resolución sin autenticar cubriendo el mismo hueco.

> [!info]+ Fuentes
> - [RFC 5452](https://datatracker.ietf.org/doc/html/rfc5452) — resistencia de resolvers a respuestas falsificadas (aleatorización de puerto).
> - SAD DNS: [CVE-2020-25705](https://nvd.nist.gov/vuln/detail/CVE-2020-25705) y el trabajo de UC Riverside/Tsinghua sobre canales laterales de ICMP.
> - [Mozilla — DoH canary domain](https://support.mozilla.org/en-US/kb/canary-domain-use-application-dnsnet).
> - MITRE ATT&CK [T1557](https://attack.mitre.org/techniques/T1557/) y [T1584.002](https://attack.mitre.org/techniques/T1584/002/).
