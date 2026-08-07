---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Recon
  - Tipo/Introduccion
Descripción: "Diez binarios que hablan el mismo idioma por tuberías: el estándar de facto del recon en bug bounty y en attack surface management"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - subfinder - enumeración pasiva de subdominios]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

<mark style="background: #ADCCFFA6;">ProjectDiscovery no es una herramienta sino una **familia de binarios pequeños que se encadenan por tuberías**</mark>, cada uno resolviendo una etapa del reconocimiento. Escritos en Go, distribuidos como binario único, todos leen de `stdin`, escriben a `stdout` y hablan JSONL. Es la razón de que se hayan comido el ecosistema: no compiten con Nmap, compiten con los *scripts* de pegamento que antes escribía cada uno.

Para bug bounty son **el** estándar; para pentest de superficie externa, la vía rápida de pasar de un nombre de dominio a una lista de servicios vivos.

# El pipeline canónico

```shell-session
$ subfinder -d objetivo.com -all -silent \
  | dnsx -silent -a -resp-only \
  | naabu -silent -top-ports 1000 \
  | httpx -silent -sc -title -tech-detect -json -o superficie.json
```

Leído de arriba abajo, cada paso reduce y enriquece:

```
 subfinder   ── nombres candidatos (pasivo, no toca al objetivo)
     ↓
 alterx      ── permutaciones sobre esos nombres
     ↓
 dnsx        ── ¿cuáles resuelven de verdad? (filtra wildcards)
     ↓
 asnmap      ── ¿qué rangos IP son suyos de verdad?
 cdncheck    ── ¿cuáles están detrás de CDN/WAF?
     ↓
 naabu       ── ¿qué puertos tienen abiertos?
     ↓
 httpx       ── ¿qué hay en cada puerto? (status, título, tecnología)
 tlsx        ── ¿qué dicen los certificados? (→ realimenta a dnsx)
     ↓
 nuclei      ── ¿algo de eso es vulnerable?
 notify      ── avísame por Slack/Discord/Telegram
```

<mark style="background: #8000E1A6;">La realimentación de `tlsx` hacia `dnsx` es el bucle que más superficie encuentra</mark>: los nombres del certificado (SAN) de un host revelan dominios hermanos que ninguna fuente pasiva listaba, y esos vuelven a entrar por el principio.

# Qué cubre esta carpeta y qué no

| Binario | Etapa | Nota |
| --- | --- | --- |
| `subfinder` | Subdominios pasivos | [[01 - subfinder - enumeración pasiva de subdominios]] |
| `alterx` + `dnsx` | Permutación y resolución | [[02 - alterx y dnsx - permutación y resolución masiva]] |
| `asnmap` + `cdncheck` | Superficie por ASN, detección de CDN | [[03 - asnmap y cdncheck - superficie por ASN y detección de CDN]] |
| `naabu` | Puertos | [[04 - naabu - descubrimiento de puertos]] |
| `httpx` | Sondeo HTTP | [[05 - httpx - sondeo y fingerprinting HTTP a escala]] |
| `tlsx` | Inteligencia TLS | [[06 - tlsx - inteligencia desde TLS]] |
| `uncover` | Recon pasivo por buscadores | [[07 - uncover - recon pasivo vía motores de búsqueda]] |
| `notify` | Notificación y automatización | [[08 - notify y automatización del pipeline]] |

**Fuera a propósito**: `nuclei` (escáner de plantillas) y `katana` (*crawler*). Los dos son grandes, ya están cubiertos como técnica en [[26 - Escaneo dirigido con nuclei]] y [[10 - Crawling web]], y merecen carpeta propia. Aquí son el **consumidor** del pipeline, no parte de él.

# Lo que comparten todos

Aprender uno es aprender casi todos. Convenciones comunes:

| Patrón | Significado |
| --- | --- |
| `-silent` | Solo resultados, sin banner ni ruido. **Obligatorio al encadenar.** |
| `-j` / `-json` | JSONL, una línea por resultado. |
| `-o fichero` | Salida a fichero (además de `stdout`). |
| `-l fichero` | Entrada por fichero en vez de `stdin`. |
| `-rl N` | *Rate limit* en peticiones por segundo. |
| `-t N` | Hilos/concurrencia. |
| `-config` | `$HOME/.config/<herramienta>/config.yaml`. |
| `-duc` | Desactiva la comprobación de actualización. |
| `-hc` / `-health-check` | Diagnóstico de la instalación (permisos, resolutores, red). |

> [!important]+ `-silent` no es cosmético
> Sin él, el banner ASCII y los mensajes de progreso van a `stdout` y **contaminan la tubería**: la herramienta siguiente recibe basura como si fueran objetivos. Es el error número uno al montar el primer pipeline. Si algo se comporta de forma inexplicable, el primer sospechoso es un `-silent` que falta.

## Ficheros de configuración y claves de API

Cada binario lee `$HOME/.config/<nombre>/config.yaml`, y los que consultan servicios externos (`subfinder`, `uncover`) tienen además un `provider-config.yaml` con las claves:

```yaml
# ~/.config/uncover/provider-config.yaml
shodan:
  - API_KEY_1
censys:
  - API_TOKEN:ORGANIZATION_ID
fofa:
  - EMAIL:KEY
```

> [!warning]+ Esas claves son credenciales, y viven en texto plano
> <mark style="background: #FF5582A6;">`provider-config.yaml` es un fichero con claves de API en claro en tu `$HOME`</mark>. No lo metas en el repositorio de notas ni en el del engagement, revisa los permisos (`chmod 600`) y ten presente que un compromiso de tu máquina de trabajo las entrega. Varias de esas cuentas (Shodan, Censys) son de pago y su abuso se factura.

# El aviso que hay que dar antes de usarlo

La suite es **muy** fácil de usar y por eso es fácil pasarse de la raya:

- **El pipeline entero es activo a partir de `dnsx`.** `subfinder` es pasivo de verdad; todo lo que viene después manda paquetes al objetivo.
- **Los valores por defecto son agresivos** para lo que espera un programa de bug bounty: `httpx` sale a **150 req/s** y `naabu` a **1.000 paquetes/s**. Ver [[09 - Evasión, rate-limiting y detección de la suite]].
- **`subfinder` puede sacar hosts fuera de scope.** Un `-d empresa.com` devuelve subdominios que pueden pertenecer a terceros (SaaS, proveedores). Filtrar contra el scope **antes** de la primera fase activa no es opcional ([[00 - Programas de bug bounty y scope]]).

> [!info]+ Estado del ecosistema (verificado 2026-08-04 contra la API de GitHub)
> Es el conjunto de herramientas ofensivas más activo que existe hoy: `nuclei` v3.11.0, `httpx` v1.10.0, `subfinder` v2.14.0, `naabu` v2.6.1, `dnsx` v1.3.0, `tlsx` v1.3.0, `cdncheck` v1.2.47, `katana` v1.6.1 — todos con *releases* en 2026 y commits de esta misma semana. Frente a masscan (último *release* etiquetado: enero de 2021), la diferencia de mantenimiento es abismal.

> [!info]+ Fuente
> READMEs oficiales de cada herramienta en [github.com/projectdiscovery](https://github.com/projectdiscovery) y la [documentación de la suite](https://docs.projectdiscovery.io/).
