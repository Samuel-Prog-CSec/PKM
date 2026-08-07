---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "La única técnica clásica que sigue derrotando a un IDS bien afinado — bajar por debajo del umbral que dispara la alerta, y por qué no basta contra un NDR"
Fecha de actualización: 2026-08-04
Nota previa: "[[06 - Rotación de origen e infraestructura sacrificable]]"
Nota siguiente: "[[08 - Cómo te ve el defensor]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

De toda la evasión de la era clásica, <mark style="background: #ADCCFFA6;">el *low-and-slow* es lo único que sigue funcionando</mark>, y funciona por una razón estructural: la detección por umbral es, en el fondo, un problema de **tasa**, y a un detector de tasa se le gana bajando la tasa. Deformar el paquete no engaña a un contador; mandar menos, sí.

# Cómo detecta un umbral

`Snort`, `Suricata` y `Zeek` no buscan un paquete malo aislado, sino **cuántos eventos ocurren en una ventana de tiempo** desde un mismo origen:

- **Suricata** — la palabra clave `detection_filter` / `threshold`: *«alerta solo si veo N coincidencias en T segundos desde este origen»* (`track by_src, count N, seconds T`).
- **Snort** — el inspector de *portscan* (`sfPortscan` en Snort 2, `port_scan` en Snort 3) cuenta conexiones a puertos cerrados por origen dentro de una ventana, con niveles de sensibilidad.
- **Zeek** — su detección de *scan* dispara al ver **N puertos o N hosts distintos** tocados por un origen en un intervalo.

<mark style="background: #FFB86CA6;">Todos comparten la misma forma: contar por origen dentro de una ventana</mark>. Un `-sS` a los top-1000 puertos es un caso de manual porque mete mil eventos en segundos. La consecuencia es directa: **si te mantienes por debajo de N en T, no existes para ese detector**.

# Bajar por debajo

Las palancas son las del [[05 - Rendimiento y timing|timing de Nmap]], pero usadas al revés de lo habitual —para ir lento, no rápido—:

```shell-session
# Nmap: una sonda cada 15 s, sin paralelismo, pocos puertos
$ sudo nmap -sS -T0 --scan-delay 15s --max-retries 1 \
    -p 22,80,443,445,3389 objetivo -Pn -n

# Reparto de puertos en pasadas separadas en el tiempo
$ sudo nmap -sS --max-rate 2 -p 1-16384  objetivo   # pasada 1
#   (horas después) -p 16385-32768 ...               # pasada 2
```

- **`-T0`/`-T1`** y **`--scan-delay`** espacian las sondas en segundos o minutos.
- **`--max-rate`** muy bajo (1–5 paq/s) fija un techo de tasa por debajo del umbral.
- **Pocos puertos por pasada** y **repartir en horas o días**: el escaneo deja de ser un pico y se disuelve en el ruido de fondo.
- **Aleatorizar** orden de puertos y hosts (`--randomize-hosts`) y meter *jitter* en los tiempos, para no dibujar un patrón regular.

Los escáneres rápidos también se pueden frenar: `naabu -rate` bajo ([[04 - naabu - descubrimiento de puertos|naabu]]), `masscan --rate` moderado ([[00 - Introducción a masscan y el escaneo stateless|masscan]]). Pero para *low-and-slow* real, la precisión y los reintentos de Nmap importan más que la velocidad que aquí no quieres.

# El límite: un NDR no es un umbral

Aquí está el matiz que separa el *low-and-slow* que funciona del que da falsa confianza. Un **umbral** es un contador fijo; un **NDR conductual** (Darktrace, Vectra) es un modelo de lo normal, y <mark style="background: #FF5582A6;">un escaneo lento sigue creando la anomalía «este host ha hablado con 200 destinos con los que nunca habló»</mark>, aunque tarde tres días en hacerlo. El comportamiento acumulado no baja con la tasa.

Por eso el *low-and-slow* solo es completo si es además **low-and-narrow y distribuido**:

- **Estrecho**: tocar pocos destinos, los que de verdad importan, no barrer. Lo que dispara al NDR es la **cantidad de destinos nuevos**, no la velocidad.
- **Distribuido**: repartir entre varios orígenes ([[06 - Rotación de origen e infraestructura sacrificable|rotación de origen]]) para que ningún host acumule un fan-out anómalo.
- **Precedido de recon pasivo**: llegar sabiendo qué buscar reduce el número de sondas activas a lo mínimo.

<mark style="background: #8000E1A6;">La regla completa no es «lento», es «poco, contra poco, desde varios sitios y sabiendo ya qué buscas»</mark>.

# La misma lógica en el C2: jitter

El *beaconing* de un C2 es un detector de umbral al revés: el SOC busca **regularidad**, una llamada a casa cada 60 s exactos durante horas. La contramedida es el **jitter**: aleatorizar el intervalo de *sleep* (p. ej. 60 s ± 40 %) para romper la periodicidad. Es *low-and-slow* aplicado a la persistencia — mandar menos y sin patrón para no cruzar el umbral de "esto es demasiado regular para ser humano".

> [!warning]+ El coste es tiempo, y el tiempo tiene dueño
> El *low-and-slow* cambia sigilo por horas o días. En un red team con sigilo como objetivo, es la inversión correcta. En un **pentest anunciado con plazo**, escanear a `-T0` es malgastar el presupuesto del cliente en un sigilo que nadie te ha pedido: si el ejercicio no es evasivo, escanea a ritmo normal y dedica el tiempo a explotar ([[08 - Cómo te ve el defensor|elige el nivel de evasividad que toca]]).

> [!info]+ Fuentes
> Detección por umbral: [`threshold`/`detection_filter` de Suricata](https://docs.suricata.io/en/latest/rules/thresholding.html), el inspector [`port_scan` de Snort 3](https://docs.snort.org/) y la [detección de escaneo de Zeek](https://docs.zeek.org/). Tácticas de evasión por tasa: secybr, [*Evasion Tactics for Scanning Targets*](https://secybr.com/posts/evasion-tactics-for-scanning-targets/). Marco: MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/). Palancas de timing en [[05 - Rendimiento y timing]]; la vista defensiva completa, en [[08 - Cómo te ve el defensor]].
