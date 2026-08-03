---
tags:
  - Blue-Team
  - Deception
  - Tipo/Deteccion
Descripción: "Capturar la amenaza viva en vez de borrarla: honeypots, trampas, live forensics y deception activa (MITRE Engage, honeytokens) frente al anti-forense del atacante"
Fecha de actualización: 2026-08-03
Nota previa: "[[02 - Zero-trust - bloquear lo sospechoso, no solo lo malicioso]]"
Nota siguiente: "[[04 - Cultura del SOC, complacencia y vigilancia]]"
Area: "[[Doctrina defensiva.base|Doctrina defensiva]]"
---
---

El *Bansenshūkai* recomienda capturar al shinobi enemigo **vivo** en lugar de matarlo: interrogarlo revela qué ha hecho, para quién trabaja y qué tradecraft usa — inteligencia que ningún cadáver da. La lección defensiva es incómoda porque la práctica habitual es la contraria: <mark style="background: #ADCCFFA6;">muchas organizaciones, al detectar una amenaza, desconectan, borran y reinstalan</mark> ("wipe and forget"), erradicando el problema y toda la inteligencia sobre él a la vez.

# Live capture vs. forensics muerto

La forense clásica se hace sobre datos **estáticos** (una imagen de disco), que ya perdió lo efímero: malware *fileless* que vive en memoria, artefactos en cachés de tablas de rutas, procesos vivos. La `live capture` (o *live analysis*) captura el sistema **en marcha**. Se practica poco por razones concretas —requiere tecnología y personal especializado, choca con políticas de "aislar y apagar", falta gente forense on-site— pero <mark style="background: #8000E1A6;">apagar el sistema equivale a quemar al prisionero antes de interrogarlo</mark>. El coste: quedas relegado a "conserje forense", el que limpia después de que el atacante ya cumplió su objetivo.

# Trampas: del honeypot al tiger trap

Los ninjas usaban trampas activas: el `mogari` (tiger fall trap), que canalizaba al intruso por un laberinto de trampas ocultas, o el `tsuiritei` (falsos muros que colapsaban al escalarlos). Sus equivalentes:

- **Honeypot**: sistema señuelo, aislado, diseñado para atraer y registrar al atacante.
- **NAC a VLAN infectada**: contener al host comprometido dejándolo "vivo" en un segmento controlado mientras se le observa.
- **Tiger trap**: un sistema de **producción** con capacidades de honeypot que se disparan solo ante una acción incorrecta. Un `jumpbox` con trampa que parece una ruta a otra red pero congela, aísla o registra al que la usa mal — mientras el administrador legítimo la atraviesa por el camino correcto sin caer.

> [!warning]+ El atacante sabe que existen los honeypots
> Los adversarios prueban si están en un entorno simulado (tiempos de cálculo, artefactos de virtualización) y, si lo confirman, <mark style="background: #FFB86CA6;">cambian de comportamiento o cesan la operación</mark>. Además, el atacante avanzado se despliega en fases: en la de reconocimiento **busca la tecnología de captura** y solo carga sus herramientas tras validar que puede operar seguro. Un honeypot obvio no engaña a un profesional; la deception moderna busca ser indistinguible de producción.

# El anti-forense del atacante

La amenaza sofisticada se mueve a donde la forense estándar no mira: firmware de disco con sistemas de ficheros ocultos, malware en BIOS/UEFI —de LoJax (2018, el primer *rootkit* UEFI visto in-the-wild, de APT28) a BlackLotus, que en 2023 fue el primer *bootkit* capaz de saltarse UEFI Secure Boot en un Windows 11 parcheado (CVE-2022-21894)—, código en routers y switches que nadie imagina. O se esconde en la **memoria de sistemas que rara vez reinician** —un Domain Controller— y espera a que baje el escrutinio forense antes de volver. Si la *live analysis* se hace mal, la amenaza detecta el software forense y se borra, se oculta o lanza un ataque destructivo. Por eso capturar vivo exige protocolo: aislar sin alertar, y controlar al proceso para que no avise a sus aliados ni se autodestruya.

# Deception activa: convertir el silencio en señal

*Cyberjutsu* propone deception que va más allá del honeypot pasivo:

- **"Squeaky gates"** (cap 20): alertas falsas que se disparan cada minuto en un DC. Un atacante que quiere operar en silencio intentará "apagar" o desviar esos logs — y <mark style="background: #FF5582A6;">la súbita ausencia de la alerta falsa delata su presencia</mark>.
- **El juego del grillo** (`kamaritsuke`, cap 26): el defensor aprende que el silencio de los insectos indica un intruso; el atacante lleva una caja de grillos para llenar el silencio; el defensor añade patrullas ocultas escalonadas… una co-evolución de medida y contramedida que, bien jugada, hace la infiltración demasiado cara.

# Modernización: deception como disciplina

Lo que el libro intuía hoy tiene marco y herramientas. `MITRE Engage` (2022, sucesor de MITRE Shield) es el framework de *adversary engagement* que sistematiza denegación, deception y compromiso activo del adversario. Y la tendencia ya no es el honeypot aislado sino la **deception distribuida**: <mark style="background: #8000E1A6;">honeytokens y breadcrumbs sembrados en producción</mark> — credenciales falsas, `canarytokens` (Thinkst), claves AWS señuelo, documentos con balizas — que no atraen a un rincón sino que **cualquier interacción con ellos es, por definición, maliciosa**, porque ningún proceso legítimo debería tocarlos. Es el mismo principio del sensor pasivo de [[01 - Sensores defensivos - tipos y colocación|la nota de sensores]], llevado al dato.

Todo esto se integra en el [[🚨⚙️ Proceso de manejo de incidentes|proceso de manejo de incidentes]]. La contracara ofensiva —cómo el atacante detecta trampas y ejerce anti-forense— se razona desde [[00 - El mindset del atacante persistente|Doctrina pentesting]].

> [!info]+ Fuentes
> - Ben McCarty, *Cyberjutsu*, caps. 16 ("Live Capture"), 20 y 26, 2021.
> - [MITRE Engage](https://engage.mitre.org/) — framework de adversary engagement (sucede a MITRE Shield).
> - Thinkst, [Canarytokens](https://canarytokens.org/) — honeytokens gratuitos.
