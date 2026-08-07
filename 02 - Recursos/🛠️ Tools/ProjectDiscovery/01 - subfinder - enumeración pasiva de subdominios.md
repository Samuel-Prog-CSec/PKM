---
tags:
  - Pentesting/Enumeracion
  - Recon
  - DNS
Descripción: "La única pieza del pipeline que no manda un solo paquete al objetivo: subdominios extraídos de fuentes que ya los tenían indexados"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - La suite ProjectDiscovery y el pipeline de recon]]"
Nota siguiente: "[[02 - alterx y dnsx - permutación y resolución masiva]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

<mark style="background: #ADCCFFA6;">`subfinder` descubre subdominios consultando fuentes pasivas que ya los tienen indexados</mark> — registros de *Certificate Transparency*, buscadores, bases de datos de DNS pasivo, repositorios de código. Su propia documentación lo define como *«construido para hacer una sola cosa: enumeración pasiva de subdominios, y hacerla muy bien»*.

Es la pieza más importante del pipeline y también la más incomprendida, porque *pasivo* aquí significa algo muy concreto.

# Qué significa "pasivo" exactamente

<mark style="background: #8000E1A6;">`subfinder` **no manda ni un paquete al objetivo**</mark>. Le pregunta a terceros que ya escanearon, indexaron o registraron ese dominio. Consecuencias:

- **El objetivo no se entera.** No hay entrada en sus logs, no hay alerta, no hay nada que correlacionar. Su documentación lo vende como *«velocidad y sigilo aprovechables tanto por pentesters como por cazadores de bugs»*, y es cierto.
- **Los que se enteran son los proveedores.** Shodan, Censys, VirusTotal y compañía registran tus consultas contra tu clave de API. No es un problema de sigilo frente al cliente, pero sí una traza asociada a tu identidad.
- **La cobertura depende de las fuentes.** Un subdominio que nunca ha tenido certificado, nunca se ha publicado y nunca se ha crawleado **no aparece**. Por eso `subfinder` es el principio del recon, no el final.

```shell-session
$ subfinder -d objetivo.com -silent
$ subfinder -d objetivo.com -all -silent -o subdominios.txt
$ subfinder -dL dominios.txt -silent -oJ -o resultado.jsonl
```

# Fuentes y claves de API

```shell-session
$ subfinder -ls                       # listar las fuentes disponibles
$ subfinder -d objetivo.com -s crtsh,github -silent
$ subfinder -d objetivo.com -es shodan -silent
$ subfinder -d objetivo.com -all -silent
```

| Flag | Qué hace |
| --- | --- |
| `-s`, `-sources` | Usar **solo** esas fuentes. |
| `-es`, `-exclude-sources` | Excluir fuentes concretas. |
| `-all` | Todas las fuentes. **Lento**, pero es lo que hay que usar en un engagement serio. |
| `-recursive` | Solo las fuentes que admiten búsqueda recursiva. |
| `-ls`, `-list-sources` | Listar fuentes. |

<mark style="background: #FFB86CA6;">Sin claves de API, `subfinder` funciona pero rinde una fracción de lo que puede</mark>. Muchas de las fuentes más productivas (Censys, SecurityTrails, Shodan, BinaryEdge, VirusTotal…) requieren cuenta. Las claves van en:

```text
$HOME/.config/subfinder/provider-config.yaml
```

configurable con `-pc` o la variable `SUBFINDER_PROVIDER_CONFIG`. El fichero principal es `$HOME/.config/subfinder/config.yaml` (`SUBFINDER_CONFIG`).

> [!important]+ Invierte una tarde en las claves gratuitas
> Casi todas esas plataformas tienen nivel gratuito suficiente para bug bounty. La diferencia entre `subfinder` sin claves y con ellas es de un orden de magnitud en resultados, y es trabajo que se hace **una vez**. Es la mejora de recon con mejor relación esfuerzo/beneficio que existe.

# Filtrado y control de ritmo

```shell-session
$ subfinder -d objetivo.com -m "*.api.objetivo.com" -silent
$ subfinder -d objetivo.com -f "test.objetivo.com" -silent
$ subfinder -d objetivo.com -all -rl 10 -silent
$ subfinder -d objetivo.com -rls "hackertarget=10/s" -silent
```

| Flag | Uso |
| --- | --- |
| `-m`, `-match` | Quedarse solo con los que casen. |
| `-f`, `-filter` | Descartar los que casen. |
| `-rl`, `-rate-limit` | Peticiones por segundo globales. |
| `-rls` | Límite **por proveedor**: `-rls "hackertarget=10/s"`. |
| `-timeout` | Timeout HTTP (por defecto **30 s**). |
| `-max-time` | Tope total de la enumeración (por defecto **10 min**). |

> [!warning]+ `-max-time 10` puede cortarte el recon sin avisar
> El tope por defecto de **10 minutos** es cómodo para un dominio pequeño y **corto para uno grande con `-all`**. Cuando se agota, `subfinder` devuelve lo que llevaba y termina normalmente: no distingues un recon completo de uno truncado. En objetivos grandes, sube `-max-time` explícitamente.

## Modo activo

```shell-session
$ subfinder -d objetivo.com -nW -silent      # solo subdominios que resuelven
$ subfinder -d objetivo.com -oI -silent      # incluir las IPs
```

`-nW/-active` y `-oI/-ip` hacen que `subfinder` **resuelva** los nombres, y `-t` (concurrencia, por defecto 10) solo aplica a ese modo. <mark style="background: #FF5582A6;">Con esos flags deja de ser pasivo</mark>: genera consultas DNS. Sigue sin tocar al objetivo directamente si usas resolutores públicos, pero es un cambio de naturaleza que conviene tener presente.

En la práctica conviene dejar `subfinder` puramente pasivo y hacer la resolución con [[02 - alterx y dnsx - permutación y resolución masiva|`dnsx`]], que la hace mejor: filtra *wildcards*, controla resolutores y reintentos, y da los registros completos.

# Encadenado

```shell-session
# el flujo estándar
$ subfinder -d objetivo.com -all -silent | dnsx -silent -a -resp-only | httpx -silent -sc -title

# con las fuentes de cada resultado, para el informe
$ subfinder -d objetivo.com -all -cs -oJ -o subs.jsonl
```

`-cs/-collect-sources` guarda **de qué fuente salió cada subdominio**. En un informe eso permite decir «este host apareció en un log de Certificate Transparency el día X», que es reproducible y verificable, en vez de «lo encontró la herramienta».

> [!important]+ Filtra por scope antes de la siguiente fase
> <mark style="background: #FFB8EBA6;">`subfinder` devuelve todo lo que encuentra bajo el dominio, incluidos hosts de terceros</mark>: SaaS con CNAME, CDNs, proveedores de correo. Lanzar `naabu`/`httpx` contra esa lista en bruto significa escanear infraestructura de otras empresas — fuera de scope y potencialmente ilegal. El filtrado (`-m`, `grep -f scope.txt`, o [[03 - asnmap y cdncheck - superficie por ASN y detección de CDN|`asnmap`/`cdncheck`]]) va **antes** de la primera herramienta activa, siempre.

> [!info]+ Fuente
> [README de subfinder](https://github.com/projectdiscovery/subfinder) — filosofía pasiva, flags de fuente/filtro/rate-limit, rutas de `config.yaml` y `provider-config.yaml`, defaults (`-timeout 30`, `-max-time 10`, `-t 10`). Complementa la técnica de [[05 - Enumeración de subdominios]] y [[07 - Certificate Transparency logs]].
