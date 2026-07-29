---
tags:
  - Redes
  - Protocolos
Descripción: "DNS (*Domain Name System*) resuelve nombres de dominio a direcciones IP. No tiene base de datos central: la información está distribuida en miles de servidores, como una…"
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`DNS` (*Domain Name System*) resuelve nombres de dominio a direcciones IP</mark>. No tiene base de datos central: la información está distribuida en miles de servidores, como una biblioteca con muchas guías telefónicas. Es la infraestructura que decide a qué servidor llega un usuario al teclear un dominio.

# Tipos de servidor

| Tipo | Función |
| --- | --- |
| `Root Server` | Cúspide de la jerarquía; deriva a los servidores de TLD. |
| `Authoritative` | Tiene la **verdad** de una zona (responde con autoridad sobre sus dominios). |
| `Non-authoritative` | No posee la zona; responde con datos obtenidos/cacheados de otros. |
| `Caching` | Guarda respuestas un tiempo (`TTL`) para acelerar. |
| `Forwarding` | Reenvía las consultas a otro servidor. |
| `Resolver` | El que hace la consulta por el cliente (recursivo). |

# Tipos de registro

| Registro | Contenido |
| --- | --- |
| `A` / `AAAA` | Nombre → IPv4 / IPv6. |
| `MX` | Servidor de correo del dominio. |
| `NS` | Nameservers autoritativos de la zona. |
| `CNAME` | Alias de un nombre a otro. |
| `TXT` | Texto libre: `SPF`, `DMARC`, `DKIM`, verificaciones de terceros. |
| `SOA` | *Start of Authority*: servidor primario, contacto, seriales de zona. |
| `PTR` | IP → nombre (resolución **inversa**). |
| `SRV` | Servicio + puerto (p. ej. `_ldap._tcp` en AD). |

# Puertos y zonas

- **`UDP 53`** — consultas normales (rápidas, respuesta ≤512 bytes).
- **`TCP 53`** — <mark style="background: #FFB8EBA6;">transferencias de zona (`AXFR`), respuestas grandes y DNSSEC</mark>.

Una **zona** es una porción del espacio de nombres que administra un servidor; su fichero (en BIND, definido en `named.conf`) contiene el `SOA` y todos los registros. Los servidores primario y secundario se sincronizan mediante **transferencia de zona** (`AXFR` completa, `IXFR` incremental) — una operación que **debe restringirse**, porque vuelca la zona entera.

# Relevancia ofensiva

DNS filtra información a raudales si está mal configurado: una `AXFR` abierta entrega todos los subdominios e IPs internas de golpe, y los `SRV`/`TXT` revelan la infraestructura. La enumeración pasiva de dominio está en [[01 - Reconocimiento de dominio]]; el ataque directo a un servidor DNS (zone transfer, brute-force) en [[07 - DNS|Footprinting de DNS]].
