---
tags:
  - Pentesting/Enumeracion
  - Recon
  - Tipo/Arsenal
Descripción: "Convertir el pipeline en monitorización continua: notificar solo lo nuevo, gestionar los binarios y no ahogarse en repeticiones"
Fecha de actualización: 2026-08-04
Nota previa: "[[07 - uncover - recon pasivo vía motores de búsqueda]]"
Nota siguiente: "[[09 - Evasión, rate-limiting y detección de la suite]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

Un pipeline que se lanza a mano es una foto. <mark style="background: #8000E1A6;">El salto de calidad en bug bounty está en convertirlo en un proceso continuo que corre solo y **solo te avisa de lo que ha cambiado**</mark>: el subdominio que apareció esta madrugada, el puerto que se abrió, el panel que alguien publicó sin querer. Esta nota cubre las piezas que faltan para eso.

# `notify` — que el resultado llegue a donde estás

```shell-session
$ subfinder -d objetivo.com -silent | notify -bulk
$ notify -data resultados.txt -bulk -provider discord,slack
$ subfinder -d objetivo.com -silent | httpx -silent | nuclei -tags exposure -o out.txt; notify -bulk -data out.txt
```

Envía a **Slack, Discord, Telegram, Microsoft Teams, Google Chat, Pushover, Gotify, SMTP y webhooks personalizados**, configurados en `$HOME/.config/notify/provider-config.yaml` con plantillas que usan el marcador `{{data}}`.

| Flag | Uso |
| --- | --- |
| `-data`, `-i` | Fichero de entrada. |
| `-bulk` | Un mensaje con todo, en vez de uno por línea. |
| `-id` | Enviar solo a proveedores concretos por su identificador. |
| `-pc`, `-provider-config` | Config alternativa. |
| `-cl`, `-char-limit` | Tope de caracteres por mensaje (por defecto **4000**). |
| `-mf`, `-msg-format` | Formato del mensaje. |
| `-rl`, `-rate-limit` | Peticiones HTTP por segundo. |

> [!warning]+ `-bulk` no es opcional
> Sin él, `notify` manda **un mensaje por línea**. Un `subfinder` con 3.000 resultados son 3.000 mensajes: te banean del webhook, revientas el canal y pierdes el resultado. <mark style="background: #FF5582A6;">Usa `-bulk` siempre</mark>, y ten presente el `-char-limit` de 4.000 — la salida larga se trocea.

# El eslabón que falta: notificar solo lo nuevo

`notify` manda lo que le llega. Si tu pipeline corre cada noche, cada noche te manda **todo**, y en una semana dejas de leerlo. La pieza que arregla eso no es de ProjectDiscovery: es **`anew`**, de tomnomnom.

```shell-session
$ subfinder -d objetivo.com -all -silent \
  | anew subdominios.txt \
  | notify -bulk -id slack
```

<mark style="background: #ADCCFFA6;">`anew` añade al fichero solo las líneas que no estaban, y **escribe a `stdout` únicamente esas**</mark>. Si no hay nada nuevo, no sale nada, y `notify` no manda nada. Es una utilidad de veinte líneas que convierte un pipeline en un sistema de monitorización.

El patrón completo, para un cron nocturno:

```bash
#!/usr/bin/env bash
# recon-continuo.sh — monitorización de superficie
cd "$HOME/recon/objetivo" || exit 1

subfinder -d objetivo.com -all -silent \
  | anew subdominios.txt \
  | dnsx -silent -a -resp-only -auto-wildcard \
  | anew ips.txt \
  | naabu -silent -top-ports 1000 -exclude-cdn -rate 100 \
  | anew puertos.txt \
  | httpx -silent -sc -title -td -fd \
  | anew web.txt \
  | notify -bulk -id slack
```

Cada `anew` corta el flujo si no hay novedad, así que <mark style="background: #FFB86CA6;">las noches tranquilas no gastan ni una petición contra el objetivo más allá de la fase pasiva</mark>. Y cuando el mensaje llega, es señal real.

> [!important]+ Otras utilidades de pegamento del mismo autor
> `anew` (deduplicar y detectar novedad), `unfurl` (descomponer URLs en sus partes), `httprobe` (predecesor de `httpx`), `gf` (patrones grep predefinidos para hallazgos). Son de **tomnomnom**, no de ProjectDiscovery, pero el ecosistema de bug bounty los usa juntos y encajan porque comparten el mismo contrato: texto por líneas, `stdin` a `stdout`.

# `pdtm` — mantener los binarios al día

```shell-session
$ pdtm -install-all
$ pdtm -update-all
$ pdtm -i httpx,naabu,dnsx
$ pdtm -r katana
$ pdtm -sp                      # mostrar la ruta de los binarios
```

El gestor oficial de la suite: instala, actualiza y desinstala. Con diez binarios que sacan *release* cada pocas semanas, `pdtm -update-all` en el cron semanal evita el escenario clásico de ir a usar `nuclei` en medio de un engagement y descubrir que tienes una versión de hace un año sin la mitad de las plantillas.

`-bp` fija una ruta de binarios propia y `-ip` la añade al `PATH`.

# Cosas que romperán el pipeline (y cómo evitarlas)

> [!warning]+ Los cuatro fallos habituales
> 1. **Falta un `-silent`** — el banner ASCII entra en la tubería como si fuera un objetivo. Es el fallo número uno.
> 2. **Sin control de errores en el cron** — una etapa que falla deja las siguientes con la entrada vacía, `anew` no ve novedad y **el silencio parece "todo bien"**. Registra el recuento de cada etapa en un log: cero resultados donde ayer había 400 es una avería, no una noche tranquila.
> 3. **Sin límite de ritmo** — un cron nocturno a los defaults (`naabu` 1.000 pps, `httpx` 150 req/s) es un escaneo agresivo diario contra el mismo objetivo. En bug bounty eso acaba en expulsión del programa.
> 4. **El fichero de `anew` crece sin control** — con `-auto-wildcard` mal puesto o un objetivo con comodín, `subdominios.txt` llega a millones de líneas y el pipeline se atasca. Revísalo de vez en cuando.

> [!important]+ Automatizar no exime del scope
> <mark style="background: #FF5582A6;">Un cron no lee el contrato</mark>. Si el scope del cliente cambia, o el programa de bug bounty retira un dominio, tu automatización sigue escaneándolo hasta que la pares. Mete el filtro de scope **dentro** del script (`grep -f scope.txt`) y revísalo cada vez que cambie el alcance. Un escaneo automatizado contra un activo retirado del scope es exactamente el tipo de incidente que termina un programa ([[01 - Reglas, legalidad y conducta]]).

> [!info]+ Fuentes
> READMEs de [notify](https://github.com/projectdiscovery/notify) (proveedores, `provider-config.yaml`, `-bulk`, `-char-limit 4000`) y [pdtm](https://github.com/projectdiscovery/pdtm). `anew`, `unfurl` y `gf` son de [tomnomnom](https://github.com/tomnomnom). Metodología de recon continuo en [[02 - Recon y herramientas para bug bounty]] y [[14 - Automatización del recon]].
