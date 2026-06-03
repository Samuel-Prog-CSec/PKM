---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[05 - Enumeración de subdominios]]"
Nota siguiente: "[[07 - Certificate Transparency logs]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">La fuerza bruta de subdominios prueba sistemáticamente una lista de nombres candidatos contra el dominio para descubrir cuáles existen</mark>. Es la técnica **activa** de descubrimiento por excelencia: rellena los huecos que la enumeración pasiva no ve, a cambio de generar consultas DNS detectables.

# El proceso en cuatro pasos

1. **Selección de `wordlist`**: el motor de todo. Puede ser:
   - *General*: nombres comunes (`dev`, `staging`, `admin`, `mail`, `test`). Útil cuando no conoces las convenciones del objetivo.
   - *Dirigida*: enfocada a la industria, tecnología o patrones del objetivo. Más eficiente y con menos falsos positivos.
   - *Custom*: generada a partir de inteligencia previa (nombres de productos, regiones, entornos vistos en otros activos).
2. **Iteración**: la herramienta antepone cada palabra al dominio (`dev.example.com`, `staging.example.com`…).
3. **Consulta DNS**: resuelve cada candidato (registro `A`/`AAAA`). Si resuelve, el subdominio existe.
4. **Filtrado y validación**: los que resuelven pasan a la lista de válidos; conviene confirmarlos sondeándolos por HTTP.

<mark style="background: #FFB8EBA6;">La calidad de la `wordlist` determina el resultado más que la herramienta</mark>. El estándar de facto es `SecLists`:

```shell-session
$ ls /usr/share/seclists/Discovery/DNS/
subdomains-top1million-5000.txt
subdomains-top1million-20000.txt
subdomains-top1million-110000.txt
dns-Jhaddix.txt
```

# Herramientas

| Herramienta | Descripción |
| - | - |
| `dnsenum` | Toolkit clásico en Perl: enumera registros, intenta `AXFR` y *brute-force* |
| `fierce` | Recursivo, con detección de *wildcard*, interfaz sencilla |
| `dnsrecon` | Combina técnicas y formatos de salida exportables |
| `amass` | Agregación **pasiva** multi-fuente (su modo *brute-force* está deshabilitado por defecto) |
| `assetfinder` | Agregación **pasiva** ligera (no hace *brute-force* per se) |
| `puredns` | *Brute-force* DNS masivo: resuelve y filtra a gran escala |

# `dnsenum` en acción

```shell-session
$ dnsenum --enum inlanefreight.com -f /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -r

-----   inlanefreight.com   -----

Host's addresses:
inlanefreight.com.            300   IN   A   134.209.24.248

Brute forcing with subdomains-top1million-20000.txt:
www.inlanefreight.com.        300   IN   A   134.209.24.248
support.inlanefreight.com.    300   IN   A   134.209.24.248
[...]
done.
```

Los flags clave:

- `--enum`: atajo que activa varias opciones de *tuning* razonables.
- `-f <wordlist>`: la lista para *brute-force* (ajusta la ruta a tu instalación de `SecLists`).
- `-r`: *brute-force* recursivo — si encuentra un subdominio, intenta enumerar subdominios de ese subdominio.

Además del *brute-force*, `dnsenum` intenta automáticamente `AXFR` contra los `NS` descubiertos, hace `reverse lookups`, *scraping* de Google y `WHOIS` — un toolkit completo para una primera pasada.

> [!warning]+ `dnsenum` no escala
> `dnsenum` está escrito en Perl y resuelve de forma secuencial: para una `wordlist` de 20k aguanta, pero para listas de cientos de miles o resolución de millones de candidatos es **demasiado lento**. Para volumen real usa el stack rápido.

> [!info]+ El stack rápido de brute-force DNS
> - `puredns bruteforce <wordlist> <dominio>` apoyado en `massdns` resuelve a gran escala —cientos de miles de nombres por minuto con una buena lista de *resolvers* de confianza (`-r resolvers.txt`)—, órdenes de magnitud por encima de `dnsenum`. Maneja la detección de *wildcard* y el descarte de *resolvers* envenenados o con *rate-limit*.
> - `shuffledns` (ProjectDiscovery) envuelve `massdns` con detección de *wildcard* integrada.
> - `gobuster dns -d dominio -w wordlist` y `ffuf` (en modo DNS) son alternativas concurrentes.
> Conseguir una buena lista de *resolvers* públicos sanos es tan importante como la `wordlist`: con *resolvers* malos obtienes falsos positivos y resultados inconsistentes.

# Permutación: exprimir lo que ya tienes

Una técnica que HTB omite y que dispara los resultados: <mark style="background: #FF5582A6;">generar variaciones a partir de los subdominios ya descubiertos</mark>. Si existe `dev.example.com`, probablemente existan `dev1`, `dev2`, `dev-staging`, `staging-dev`, `dev.internal`… Herramientas como `gotator`, `dnsgen`, `altdns` o `ripgen` toman tu lista de subdominios conocidos y producen permutaciones que luego resuelves con `puredns`. <mark style="background: #8000E1A6;">Este bucle "descubrir → permutar → resolver" encuentra hosts que ninguna `wordlist` genérica contiene</mark>.

> [!important]+ Brute-force de DNS ≠ brute-force de vhost
> Aquí resolvemos nombres por **DNS**: el subdominio debe tener su propio registro y resolver a una IP. Pero hay hosts que **no** están en DNS y solo responden si envías la cabecera `Host` correcta a la IP — son `Virtual Hosts`, y se descubren con otra técnica (fuzzing de la cabecera `Host`). Esa distinción se trata en [[08 - Virtual Hosts]] y en el fuzzing de [[20 - Fuzzing de vhosts y subdominios]].

La vía pasiva más rentable para subdominios no es la fuerza bruta, sino leer los certificados que el propio objetivo ha emitido. Eso son los [[07 - Certificate Transparency logs]].
