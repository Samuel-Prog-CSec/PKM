---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - DNS
Descripción: "Resolver millones de nombres con recursión propia, sin depender de un resolver ajeno que te limite o te mienta"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - ZGrab2 - handshakes L7 y banners a escala]]"
Nota siguiente: "[[04 - Evasión, detección y ética del escaneo a escala]]"
Area: "[[ZMap.base|ZMap]]"
---
---

<mark style="background: #ADCCFFA6;">ZDNS es un resolutor DNS de alto rendimiento escrito en Go que trae **su propio código de resolución recursiva**</mark> y una caché optimizada para consultas muy dispersas. Es la tercera pata del ecosistema ZMap y la que más se usa fuera de él, porque el problema que resuelve —resolver cientos de miles de nombres deprisa y sin mentiras por el camino— aparece en cualquier recon serio.

# Por qué no basta con `dig` en bucle ni con un resolver público

Resolver 500.000 subdominios candidatos contra `8.8.8.8` falla de tres formas distintas:

1. **Te limitan.** Los resolutores públicos aplican *rate-limiting* y empiezan a devolver `SERVFAIL` o a descartar consultas. Interpretas "no existe" donde había "no me diste tiempo".
2. **Te mienten por diseño.** Muchos resolutores hacen filtrado, bloqueo por categorías o *NXDOMAIN hijacking*. <mark style="background: #FFB86CA6;">Un dominio que existe puede aparecer como inexistente, y uno que no existe puede resolver a una landing del ISP</mark> — los dos errores arruinan una enumeración de subdominios.
3. **Ves la caché, no la verdad.** Un resolver recursivo te da lo que tiene cacheado, no lo que dicen ahora los autoritativos del dominio.

`--iterative` resuelve los tres: ZDNS hace la recursión él mismo, empezando por los servidores raíz (rota entre ellos) y bajando por la delegación hasta el autoritativo de la zona.

```shell-session
$ echo "ejemplo.com" | zdns A --iterative
```

# Uso

```shell-session
$ echo "censys.io" | zdns A
$ zdns A google.com --name-servers=1.1.1.1
$ cat subdominios.txt | zdns A --iterative --threads 500 -o resueltos.json
$ echo "censys.io" | zdns mxlookup --ipv4-lookup
```

| Flag | Qué hace |
| --- | --- |
| `--iterative` | Recursión propia desde los servidores raíz. |
| `--name-servers` | Resolutores a usar (los rota por consulta). |
| `--threads` | Goroutines concurrentes — **por defecto 1.000**. |
| `--input-file` / `--output-file` | Entrada y salida por fichero. |
| `--retries` | Reintentos por servidor durante la iteración. |
| `--timeout` | Tope por consulta. |
| `--name-server-mode` | Consulta **el mismo nombre a varios servidores** (ver abajo). |
| `--include-fields` | Campos extra: `class`, `protocol`, `ttl`, `resolver`, `flags`, `dnssec`. |

La verbosidad de salida va por niveles (`short`, `normal` —por defecto—, `long`, `trace`). <mark style="background: #FFB8EBA6;">`trace` guarda el camino completo de la resolución</mark>: qué preguntó a qué servidor y qué le respondió en cada salto. Es lo que necesitas cuando un nombre resuelve distinto de lo esperado y hay que demostrar por qué.

## Los módulos

Dos familias. Los **módulos de lookup** hacen trabajo compuesto:

- **`alookup`** — como `nslookup`, sigue los `CNAME` hasta el final.
- **`mxlookup`** — resuelve los MX y además hace la A de cada uno.
- **`nslookup`** — resuelve los NS y sus A/AAAA.
- **`MULTIPLE`** — varios módulos en la misma pasada, configurados por `.ini`.

Y los **módulos crudos**, uno por tipo de registro: `A`, `AAAA`, `MX`, `NS`, `SOA`, `TXT`, `PTR`, `SRV`, `CNAME`, `CAA`, `DMARC`, `SPF`, `DNSKEY`, `DS`, `RRSIG`, `NSEC`, `NSEC3`, `TLSA`, `SSHFP`, `HTTPS`, `SVCB`, `AXFR`, `BINDVERSION`, `ANY` y una lista larga de tipos raros.

# Lo que esto da en un engagement

## Validar una enumeración de subdominios

El caso de uso más común. `subfinder` y las permutaciones producen candidatos; hay que separar los que existen:

```shell-session
$ cat candidatos.txt | zdns A --iterative --threads 500 \
    | jq -r 'select(.status=="NOERROR") | .name' > vivos.txt
```

Es la misma función que cumple `dnsx` en la suite de ProjectDiscovery ([[02 - alterx y dnsx - permutación y resolución masiva]]); ZDNS gana cuando quieres **recursión propia** y la transcripción completa, `dnsx` gana en integración con el resto del pipeline.

## Registros que delatan superficie

- **`AXFR`** — transferencia de zona. Sigue apareciendo, y sigue regalando la zona entera ([[04 - Transferencias de zona DNS]]).
- **`CAA`, `DMARC`, `SPF`, `TXT`** — revelan qué CA emite los certificados, qué proveedores de correo y SaaS usa el cliente, y a menudo verificaciones de dominio que nombran servicios internos.
- **`SRV`** — en dominios con Active Directory expuesto, `_ldap._tcp.dc._msdcs.<dominio>` canta los controladores ([[02 - Enumeración inicial del dominio|enumeración de AD]]).
- **`BINDVERSION`** — consulta `version.bind` en CHAOS; identifica el software del servidor DNS.
- **`NSEC`/`NSEC3`** — habilitan el *zone walking* cuando DNSSEC está mal configurado.

## `--name-server-mode`: detectar respuestas divergentes

```shell-session
$ echo "8.8.8.8" | zdns A --name-server-mode --override-name="ejemplo.com"
```

Pregunta **el mismo nombre a servidores distintos** y compara. <mark style="background: #8000E1A6;">Divergencia entre autoritativos es un hallazgo por sí misma</mark>: indica un servidor desincronizado, una zona parcialmente migrada o un `NS` delegado a un proveedor que el cliente ya no controla — que es exactamente la precondición de un [[Subdomain Takeover.base|subdomain takeover]].

> [!warning]+ Resolver también es tocar
> Es fácil pensar que resolver DNS es pasivo. No lo es del todo: <mark style="background: #FF5582A6;">con `--iterative` estás consultando directamente a los servidores autoritativos **del cliente**</mark>, que registran tus consultas con tu IP. 500.000 consultas iterativas contra el DNS de una organización pequeña es un ataque de disponibilidad involuntario y una entrada enorme en sus logs. Baja `--threads`, y si solo quieres saber si un nombre existe sin tocar al objetivo, usa un resolver público o datos pasivos.

> [!important]+ El error de medida clásico
> Con 1.000 goroutines por defecto y `--timeout` bajo, ZDNS produce **falsos `SERVFAIL`** por saturación propia o del camino, no porque el nombre no exista. Antes de dar por muerta una lista de subdominios, repite los fallos con menos hilos y más timeout. Es el equivalente DNS del falso negativo por falta de reintentos de [[00 - Introducción a masscan y el escaneo stateless|masscan]].

> [!info]+ Fuente
> [README de ZDNS](https://github.com/zmap/zdns) — recursión propia, `--iterative`, lista de módulos y tipos de registro, `--threads` por defecto 1.000, niveles de verbosidad, `--name-server-mode` y ejemplos de invocación. Estado verificado 2026-08-04: **v2.1.1 (mayo 2026)**.
