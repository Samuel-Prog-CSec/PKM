---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "El DNS (Domain Name System) traduce nombres de dominio legibles (www.example.com) a las direcciones IP numéricas (192.0.2.1) que las máquinas usan para comunicarse"
Fecha de actualización: 2026-06-02
Nota previa: "[[01 - WHOIS]]"
Nota siguiente: "[[03 - Enumeración DNS con dig]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
<mark style="background: #ADCCFFA6;">El `DNS` (Domain Name System) traduce nombres de dominio legibles (`www.example.com`) a las direcciones IP numéricas (`192.0.2.1`) que las máquinas usan para comunicarse</mark>. Es el **GPS de internet**: tú memorizas un nombre, el `DNS` resuelve la coordenada exacta. Sin él tendrías que recordar la IP de cada servicio.

Para el recon, el `DNS` no es solo plumbing: es <mark style="background: #FFB86CA6;">un mapa de la infraestructura del objetivo</mark>. Cada registro publicado es un activo que el objetivo expone voluntariamente, y leerlos no requiere tocar sus servidores web.

# Cómo se resuelve un nombre

La resolución es una carrera de relevos por la jerarquía `DNS`. Cuando pides `www.example.com`:

1. Tu equipo mira su **caché** local. Si no está, pregunta a un **`DNS resolver`** (normalmente el de tu ISP o uno público como `8.8.8.8`).
2. El `resolver` revisa su propia caché. Si falla, inicia una **consulta recursiva** por la jerarquía.
3. Pregunta a un **root name server** (hay 13, `a`–`m.root-servers.net`). El root no sabe la IP, pero sabe quién gestiona el `TLD`.
4. El **`TLD name server`** (Verisign para `.com`, PIR para `.org`) indica qué **servidor autoritativo** es responsable de `example.com`.
5. El **`authoritative name server`** es la parada final: tiene el registro real y devuelve la IP.
6. El `resolver` entrega la IP a tu equipo y la **cachea** durante el `TTL` del registro.
7. Tu equipo se conecta directamente al servidor web.

<mark style="background: #FFB8EBA6;">El `TTL` (Time-To-Live) controla cuánto se cachea cada registro</mark>. Un `TTL` muy bajo (30–60 s) <mark style="background: #FF5582A6;">suele delatar balanceo de carga, failover o infraestructura que cambia a menudo</mark> — información útil al perfilar al objetivo.

# El fichero hosts

El fichero `hosts` mapea nombres a IPs **localmente**, saltándose el `DNS`. Está en `C:\Windows\System32\drivers\etc\hosts` (Windows) y `/etc/hosts` (Linux/macOS). Formato:

```text
<IP>            <Hostname> [<Alias> ...]
127.0.0.1       localhost
192.168.1.10    devserver.local
```

En pentest web es una herramienta de trabajo constante: cuando un servidor sirve `Virtual Hosts` por cabecera `Host`, mapeas el nombre del vhost a la IP del objetivo en `/etc/hosts` para poder navegarlo. Ese flujo se detalla en [[08 - Virtual Hosts]]. También sirve para forzar la resolución a una IP concreta saltándose el balanceador (`0.0.0.0 dominio.com` bloquea un dominio enviándolo a una IP inexistente).

# Zonas y zone files

<mark style="background: #ADCCFFA6;">Una **zona** es la parte del espacio de nombres que gestiona una entidad concreta</mark> —`example.com` y sus subdominios suelen pertenecer a la misma zona—. El **`zone file`** es el fichero de texto en el servidor autoritativo que define los `resource records` de esa zona:

```text
$TTL 3600 ; TTL por defecto (1 hora)
@       IN SOA   ns1.example.com. admin.example.com. (
                2024060401 ; Serial (YYYYMMDDNN)
                3600       ; Refresh
                900        ; Retry
                604800     ; Expire
                86400 )    ; Minimum TTL
@       IN NS    ns1.example.com.
@       IN NS    ns2.example.com.
@       IN MX 10 mail.example.com.
www     IN A     192.0.2.1
mail    IN A     198.51.100.1
ftp     IN CNAME www.example.com.
```

Este fichero declara los servidores de nombres (`NS`), el de correo (`MX`) y las IPs (`A`) de los hosts de la zona. Conseguir el `zone file` completo de un objetivo es un hallazgo de oro porque enumera **toda** la zona de golpe — exactamente el riesgo de las [[04 - Transferencias de zona DNS|transferencias de zona]].

# Conceptos clave

| Concepto | Descripción |
| - | - |
| `Domain Name` | Etiqueta legible de un recurso (`www.example.com`) |
| `IP Address` | Identificador numérico único de un dispositivo (`192.0.2.1`) |
| `DNS Resolver` | Servidor que traduce nombres a IPs (el del ISP, o `8.8.8.8`) |
| `Root Name Server` | Cima de la jerarquía: 13 *identidades* (`a`–`m`), cada una replicada en cientos de instancias físicas vía `anycast` |
| `TLD Name Server` | Responsable de un dominio de primer nivel (`.com`, `.org`) |
| `Authoritative NS` | Servidor que guarda la IP real del dominio |
| `Record Types` | Tipos de información almacenada (A, AAAA, CNAME, MX, NS, TXT…) |

# Tipos de registro

| Tipo | Nombre | Para qué sirve | Ejemplo |
| - | - | - | - |
| `A` | Address | Mapea un host a su IPv4 | `www IN A 192.0.2.1` |
| `AAAA` | IPv6 Address | Mapea un host a su IPv6 | `www IN AAAA 2001:db8::7334` |
| `CNAME` | Canonical Name | Alias que apunta a otro nombre | `blog IN CNAME web.example.net.` |
| `MX` | Mail Exchange | Servidor(es) de correo del dominio | `example.com. IN MX 10 mail...` |
| `NS` | Name Server | Delega la zona a un servidor autoritativo | `example.com. IN NS ns1...` |
| `TXT` | Text | Texto arbitrario (verificación, políticas) | `IN TXT "v=spf1 mx -all"` |
| `SOA` | Start of Authority | Datos administrativos de la zona | `IN SOA ns1... admin...` |
| `SRV` | Service | Host y puerto de un servicio | `_sip._udp IN SRV 10 5 5060 sip...` |
| `PTR` | Pointer | DNS inverso: IP → nombre | `1.2.0.192.in-addr.arpa. IN PTR www...` |

> [!info]+ La clase `IN`
> El `IN` que <mark style="background: #FFB86CA6;">precede al tipo significa "Internet"</mark> — el campo de clase del registro. Existen otras clases (`CH` Chaosnet, `HS` Hesiod), pero en el DNS moderno verás `IN` casi siempre.

# Por qué el DNS importa en recon

El `DNS` es un componente crítico de la infraestructura del objetivo y una de las fuentes más rentables de la fase pasiva:

- **Descubrir activos**: los registros revelan subdominios, servidores de correo y de nombres. <mark style="background: #FF5582A6;">Un `CNAME` que apunta a un recurso externo ya dado de baja (`dev.example.com → bucket-abandonado.s3.aws`) es un *dangling CNAME*: la base de un `subdomain takeover`</mark>, una de las vulnerabilidades más cazadas en bug bounty. Lo retomamos en [[07 - Certificate Transparency logs]] y [[05 - Enumeración de subdominios]].
- **Mapear la infraestructura**: los `NS` <mark style="background: #ADCCFFA6;">revelan el proveedor de hosting</mark>; un `A` para `loadbalancer.example.com` <mark style="background: #FFB86CA6;">localiza el balanceador</mark>; los `MX` el correo. <mark style="background: #8000E1A6;">Encadenando registros reconstruyes cómo se conectan los sistemas</mark> y dónde están los puntos de estrangulamiento.
- **Fugas en registros `TXT`**: <mark style="background: #FFB86CA6;">los `TXT` filtran qué SaaS usa la organización</mark>. Un `google-site-verification=...` indica Google Workspace; `_1password=...` delata el gestor de contraseñas; los registros `SPF`/`DKIM`/`DMARC` listan los proveedores de correo autorizados. Todo ello alimenta fingerprinting y campañas de phishing dirigidas.
- **Monitorización de cambios**: vigilar el `DNS` en el tiempo delata infraestructura nueva. La aparición repentina de `vpn.example.com` o `staging.example.com` señala un punto de entrada recién expuesto — la lógica del recon continuo.

> [!info]+ DNS over HTTPS / TLS (DoH/DoT)
> Resolvers modernos (`1.1.1.1`, `8.8.8.8`) cifran las consultas con `DoH`/`DoT`. No cambia lo que el objetivo **publica** en sus zonas, pero sí <mark style="background: #FF5582A6;">dificulta espiar las consultas DNS de un usuario en la red</mark> — relevante en escenarios de *man-in-the-middle* o *DNS hijacking* defensivo.

Conocer la teoría es la mitad; la otra es interrogar el `DNS` activamente. La herramienta de referencia es `dig`, que abrimos en [[03 - Enumeración DNS con dig]].
