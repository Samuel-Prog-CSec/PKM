---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[02 - DNS - fundamentos]]"
Nota siguiente: "[[04 - Transferencias de zona DNS]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Con la teoría del [[02 - DNS - fundamentos|DNS]] clara, toca interrogarlo. La enumeración DNS consiste en consultar los servidores de nombres para extraer todos los registros publicados de un objetivo. <mark style="background: #FFB8EBA6;">Sigue siendo recon pasivo mientras preguntes a resolvers públicos</mark> y no a los servidores autoritativos del propio objetivo de forma agresiva.

# Herramientas de enumeración DNS

| Herramienta | Características | Uso típico |
| - | - | - |
| `dig` | Consultas de cualquier tipo (A, MX, NS, TXT…), salida detallada | Consultas manuales, *zone transfers*, análisis a fondo |
| `nslookup` | Más simple, sobre todo A/AAAA/MX | Comprobaciones rápidas de resolución |
| `host` | Salida concisa | Chequeo rápido de A/AAAA/MX |
| `dnsenum` | Enumeración automatizada, diccionario, *brute-force*, AXFR | Descubrir subdominios eficientemente |
| `fierce` | Recon con búsqueda recursiva y detección de *wildcard* | Enumeración amigable de subdominios |
| `dnsrecon` | Combina varias técnicas, varios formatos de salida | Enumeración exhaustiva y exportable |
| `theHarvester` | OSINT multi-fuente (incluye correos vía DNS) | Correos, empleados y datos asociados al dominio |

# `dig`: el bisturí del DNS

`dig` (Domain Information Groper) es la utilidad de referencia: <mark style="background: #ADCCFFA6;">consulta cualquier tipo de registro contra cualquier servidor y devuelve una salida completa y personalizable</mark>.

| Comando | Qué hace |
| - | - |
| `dig domain.com` | Consulta `A` por defecto |
| `dig domain.com MX` | Servidores de correo |
| `dig domain.com NS` | Servidores de nombres autoritativos |
| `dig domain.com TXT` | Registros `TXT` (SPF, verificaciones…) |
| `dig domain.com SOA` | Registro `SOA` de la zona |
| `dig @1.1.1.1 domain.com` | Consulta a un resolver concreto (`1.1.1.1`) |
| `dig +trace domain.com` | Muestra la ruta completa de resolución (delegación) |
| `dig -x 192.168.1.1` | *Reverse lookup* (PTR): IP → nombre |
| `dig +short domain.com` | Respuesta escueta (solo el dato) |
| `dig +noall +answer domain.com` | Solo la sección *answer* |
| `dig domain.com ANY` | Todos los registros (a menudo ignorado, ver abajo) |

# Anatomía de una respuesta

```shell-session
$ dig google.com

;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16449
;; flags: qr rd ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             0       IN      A       142.251.47.142

;; Query time: 0 msec
;; SERVER: 172.23.176.1#53(172.23.176.1) (UDP)
```

Leer la salida sección por sección:

- **Header**: `status: NOERROR` indica consulta exitosa; `id` es el identificador. Los **flags** importan: `qr` (es una respuesta), `rd` (se pidió recursión), `ad` (el resolver considera el dato auténtico — relacionado con `DNSSEC`). Los contadores dicen cuántas entradas hay en cada sección.
- **Question**: repite la pregunta —"¿cuál es el `A` de `google.com`?"—.
- **Answer**: la respuesta. El número antes de `IN A` es el `TTL` del registro —el valor lo fija la zona; en una respuesta cacheada por un *resolver* representa los segundos que le quedan—. Aquí sale `0` porque responde un *resolver* local con el registro casi expirado; en una consulta normal verás el `TTL` publicado (p. ej. `300`).
- **Footer**: tiempo de consulta, `SERVER` que respondió (con puerto `53` y protocolo `UDP`) y tamaño del mensaje.

Para *scripting* y pipelines, `+short` devuelve solo el valor —ideal para encadenar con otras herramientas—:

```shell-session
$ dig +short hackthebox.com
104.18.20.126
104.18.21.126
```

> [!warning]+ Detección y rate limiting
> Algunos servidores detectan y bloquean ráfagas de consultas DNS. Respeta los límites y, sobre todo, <mark style="background: #FF5582A6;">confirma que tienes autorización antes de una enumeración DNS extensa</mark> sobre un objetivo. Además, la consulta `ANY` está prácticamente muerta: por el `RFC 8482`, la mayoría de servidores la ignoran o devuelven una respuesta mínima para evitar abuso y amplificación.

> [!info]+ Alternativas modernas a `dig`
> En recon automatizado actual conviene conocer relevos más rápidos y *script-friendly*:
> - `dnsx` (ProjectDiscovery): resolución masiva de listas de subdominios, filtrado por tipo de registro y detección de *wildcards* — la pieza estándar tras un `subfinder` (ver [[06 - Fuerza bruta de subdominios]]).
> - `doggo` y `dog`: clones modernos de `dig` con salida en color y `JSON` nativo.
> - `q` (de natesales): cliente DNS que soporta `DoH`/`DoT`/`DoQ` y salida `JSON`.
> Para `dig` clásico, `dig +dnssec` añade la validación `DNSSEC` a la consulta.

Una consulta puntual revela registros sueltos. El premio gordo es obtener la **zona completa** de una sola petición: cuando un servidor está mal configurado, una transferencia de zona vuelca todos sus registros. Eso es [[04 - Transferencias de zona DNS]].
