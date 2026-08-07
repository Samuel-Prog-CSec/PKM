---
tags:
  - Pentesting/Enumeracion
  - Recon
  - Tipo/Introduccion
Descripción: "Saber qué rangos IP son realmente del cliente y cuáles pertenecen a una CDN — la frontera entre escanear en scope y escanear a un tercero"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - alterx y dnsx - permutación y resolución masiva]]"
Nota siguiente: "[[04 - naabu - descubrimiento de puertos]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

Entre la resolución de nombres y el escaneo de puertos hay un paso que casi todo el mundo se salta y que decide si el engagement es limpio: **averiguar de quién es cada IP**. Estas dos herramientas resuelven las dos mitades del problema.

# `asnmap` — de una organización a sus rangos

<mark style="background: #ADCCFFA6;">`asnmap` traduce entre organización, ASN, dominio e IP, y devuelve los prefijos CIDR asociados</mark>. Es la vía para pasar de "nuestro cliente es ACME" a "estos son los bloques de direcciones que ACME anuncia en BGP".

```shell-session
$ echo AS14421 | asnmap -silent
$ asnmap -a AS14421 -silent
$ asnmap -org GOOGLE -silent
$ asnmap -d objetivo.com -silent
$ asnmap -i 104.16.99.52 -silent
```

Lo que da: los prefijos que ese ASN anuncia. Lo que eso significa en un pentest:

- **Superficie que el recon por DNS no ve.** Un host sin nombre DNS no aparece en `subfinder` ni en `dnsx`, pero **sí está** en el rango del cliente. Servicios de administración, VPNs, dispositivos de red y entornos internos expuestos por error viven ahí.
- **Validación de scope.** Si el contrato dice "toda nuestra infraestructura", los prefijos del ASN son la definición operativa de eso.
- **Entrada directa para el escaneo**: `naabu` y `tlsx` aceptan ASN como objetivo, así que la cadena se cierra sola.

```shell-session
$ echo AS14421 | naabu -p 80,443 -silent
$ echo AS14421 | tlsx -san -cn -silent -resp-only
```

> [!warning]+ Un ASN no es sinónimo de "en scope"
> <mark style="background: #FF5582A6;">Que un prefijo esté anunciado por el ASN del cliente no significa que el cliente sea responsable de todo lo que hay dentro</mark>: hay rangos subarrendados, clientes del cliente en un ISP, y adquisiciones con infraestructura ajena. Y al revés: mucha superficie moderna vive en rangos de AWS/Azure/GCP que **no** están en el ASN del cliente. Los prefijos del ASN son una **hipótesis de scope que hay que confirmar por escrito**, nunca una autorización.

# `cdncheck` — separar al cliente de su CDN

El otro lado del problema. Cuando `dnsx` te devuelve `104.16.x.x`, esa IP es de **Cloudflare**, no del cliente.

```shell-session
$ echo objetivo.com | cdncheck -silent
$ cat ips.txt | cdncheck -resp -silent
$ cat hosts.txt | dnsx -silent -cdn
```

`cdncheck` identifica si una IP pertenece a un CDN, un WAF o un proveedor cloud conocido, y cuál. Está integrado en el resto de la suite: `dnsx -cdn`, `httpx -cdn` (activado por defecto) y `naabu -exclude-cdn` usan el mismo motor.

## Por qué importa tanto

**1. Escanear la CDN es escanear a un tercero.**

Lanzar `naabu -p -` contra `104.16.99.52` es escanear infraestructura de Cloudflare, no del cliente. Está fuera de scope en cualquier engagement, prohibido explícitamente en la mayoría de programas de bug bounty, y en el peor caso te bloquea la IP de trabajo. Por eso `naabu` trae el flag:

```shell-session
$ naabu -l hosts.txt -exclude-cdn -silent
```

<mark style="background: #8000E1A6;">`-exclude-cdn` no salta esas IPs: les escanea **solo 80 y 443**</mark>, que es lo único que tiene sentido probar en un host de CDN. Los proveedores que reconoce incluyen Cloudflare, Akamai, Incapsula y Sucuri.

**2. Los resultados de un escaneo a CDN son basura.**

Los puertos que veas son de la CDN, compartidos con miles de clientes. El `Server:` que devuelva es de la CDN. Cualquier hallazgo que reportes será un falso positivo o un hallazgo del proveedor, no del cliente.

**3. Es la señal de que hay que buscar el origen real.**

<mark style="background: #FFB86CA6;">Que un host esté tras CDN/WAF significa que la máquina de verdad está en otro sitio</mark>, y encontrarla suele saltarse todas las protecciones de golpe: el WAF, el rate-limiting y el DDoS protection se evitan yendo directo a la IP de origen. Esa caza tiene su propia nota: [[28 - Origen real tras WAF, CDN y balanceadores]].

> [!important]+ El orden correcto del pipeline
> ```shell-session
> $ subfinder -d objetivo.com -all -silent \
>   | dnsx -silent -a -resp-only -auto-wildcard \
>   | cdncheck -silent -resp \
>   | grep -v -E 'cloudflare|akamai|fastly|incapsula' \
>   | naabu -silent -top-ports 1000
> ```
> `cdncheck` va **entre** la resolución y el escaneo de puertos. Ponerlo después es haber escaneado ya lo que no debías.

# Lo que cambia esto en la práctica

Sin estas dos piezas, el recon típico produce una lista de IPs sobre la que se escanea a ciegas. Con ellas, la lista se parte en tres montones con tratamiento distinto:

| Montón | Qué hacer |
| --- | --- |
| **IPs en prefijos del ASN del cliente** | Escaneo completo. Es el objetivo real. |
| **IPs de CDN/WAF** | Solo 80/443, y buscar el origen ([[28 - Origen real tras WAF, CDN y balanceadores]]). |
| **IPs de terceros / SaaS** | <mark style="background: #FF5582A6;">No tocar</mark> sin autorización específica. Documentarlas como dependencia. |

Ese tercer montón es además un hallazgo por sí mismo: la lista de proveedores externos de los que depende el cliente es superficie de cadena de suministro, y en un informe vale más que un puerto abierto.

> [!info]+ Fuentes
> READMEs de [asnmap](https://github.com/projectdiscovery/asnmap) y [cdncheck](https://github.com/projectdiscovery/cdncheck); [README de naabu](https://github.com/projectdiscovery/naabu) para `-exclude-cdn`/`-display-cdn` y la lista de proveedores soportados. Contexto de scope en [[00 - Programas de bug bounty y scope]] y [[01 - Reglas, legalidad y conducta]].
