---
tags:
  - Evasion
  - Windows
  - EDR
Descripción: "No todas las evasiones son iguales ni valen lo mismo"
Fecha de actualización: 2026-07-27
Nota previa: "[[02 - Cómo se construye una detección]]"
Nota siguiente: "[[04 - Function-hooking DLLs]]"
Area: "[[Fundamentos de evasión.base|Fundamentos de evasión]]"
---
---

No todas las evasiones son iguales ni valen lo mismo. Jonathan Johnson, en *"Evadere Classifications"* (2021), clasifica los bypasses según **en qué punto del pipeline de detección** ocurren —usando el *Funnel of Fidelity* de Jared Atkinson (recogida → procesado → clasificación → alerta → respuesta)—. Saber en qué clase juega tu técnica te dice cuánto durará y contra qué producto sirve. Esta nota cierra los fundamentos con esa taxonomía y con el **modelo mental** que gobierna todo el área: no hay bala de plata, hay presupuesto de riesgo.

# Las cuatro clases de bypass

| Clase | Qué falla en el EDR | Valor para el atacante |
| --- | --- | --- |
| **Configuración** | La telemetría *existe* pero el sensor no la recoge (p. ej. un provider ETW no habilitado, o eventos que no se reenvían al backend) | Alto y **muy común** — a veces se explota sin saberlo |
| **Perceptual** | El sensor **carece** de la capacidad de ver ese dato (no hay minifilter → no ve el filesystem) | <mark style="background: #FFB86CA6;">El más valioso: si el dato no existe y nada lo compensa, el EDR **no tiene ninguna opción** de detectarte</mark> |
| **Lógico** | El atacante abusa de una **grieta en la lógica** de la regla (una exención, un caso no cubierto) | Potente pero frágil — exige conocer la regla; se rompe si la parchean |
| **Clasificación** | El sensor **ve** la actividad pero no reúne datapoints suficientes para clasificarla como maliciosa | Muy usado por red teams (p. ej. *beaconing* lento a un sitio reputado) |

<mark style="background: #ADCCFFA6;">Un **configuration bypass** aprovecha que el EDR *podría* ver el dato pero no lo hace</mark> (para reducir volumen de eventos, por rendimiento, por mala config). Un **perceptual** aprovecha un agujero estructural — no hay sensor. Un **lógico** vive de las exenciones (recuerda `opera.exe` en la regla de Elastic de la [[02 - Cómo se construye una detección|nota anterior]]). Un **clasificación** consiste en *parecerte a lo normal*: quedas por debajo del umbral aunque te observen.

> [!important]+ Cómo elegir
> - Si puedes, busca un **perceptual** (silencio total). Ej.: si el EDR no escanea si una asignación de memoria está respaldada por imagen, no te preocupa ese indicador.
> - Un **configuración** suele ser lo más accesible: cegar/interferir el canal de recogida ([[15 - Evasión de ETW|patchear ETW]], [[12 - Minifilter drivers de filesystem|descargar un minifilter]]).
> - Un **clasificación** es barato y fiable si perfilas bien el entorno: *living off the land*, [[13 - Filtros de red y WFP|egress por 443 a dominios reputados]], jitter en el C2.
> - Un **lógico** es potente pero perecedero: úsalo, pero no dependas de él.

# La cadena de evasión: presupuesto de riesgo

La clave del capítulo 1 de Hand: <mark style="background: #8000E1A6;">la evasión no es encontrar *una* técnica mágica, sino **encadenar** varias para caer por debajo del umbral de alerta</mark>. El libro modela un sistema de puntuación (los EDR reales funcionan así, con *scoring* acumulativo):

| Actividad | Riesgo |
| --- | --- |
| Ejecutar un binario sin firmar | 250 |
| Proceso hijo atípico | 400 |
| Tráfico HTTP saliente desde un proceso no-navegador | 100 |
| Asignar un buffer RWX (lectura-escritura-ejecución) | 200 |
| Memoria *committed* no respaldada por imagen | 350 |

Umbral: **≥500 → alerta**; **>750 → matan el proceso y sus hijos**. Cada actividad, aislada, se evade; combinadas, se acumulan. Un ataque bien planeado las esquiva de forma quirúrgica:

1. **Acceso inicial** ejecutando bajo un cliente de correo legítimo (firmado, sin coste de firma) → C2 por HTTP: +100 (proceso no-navegador hablando HTTP).
2. En vez de lanzar `powershell.exe` (hijo atípico, +400 → 500 → alerta), se relanza el **propio cliente de correo** como hijo y se ejecuta el tooling dentro con *Unmanaged PowerShell*. El agente asigna un buffer RWX: +200 → 300.
3. Antes de la siguiente acción (que subiría a ≥500), hay que decidir.

<mark style="background: #FFB86CA6;">En ese punto crítico, las opciones son tres</mark>:

- **Aceptar la detección** y moverse rápido para adelantar a la respuesta (o asumir quemar la operación).
- **Esperar**: como el agente solo correla eventos dentro de una ventana temporal, dejar que el estado *recicle* y el score vuelva a cero. Es la base de por qué el [[21 - Sleep obfuscation y escáneres de memoria|sleep con jitter]] no es solo para el C2.
- **Cambiar de método**: dropear el script y ejecutarlo localmente, o *proxyar* el tráfico del post-exploit para eliminar indicadores de host.

Ninguna evasión funcionó *universalmente* en el ejemplo: se combinaron técnicas apuntando a **las detecciones más relevantes para cada acción**. Ese es el oficio.

> [!warning]+ El error del script kiddie de EDR
> Copiar un PoC de un blog ("este bypass evade el EDR") falla por cuatro razones que Hand desmenuza: (1) los productos **evolucionan** y difieren por config entre clientes; (2) *bypass* se usa con ligereza — muchos PoCs no distinguen "no me bloqueó" de "no me vio"; (3) el investigador rara vez nombra el producto probado, así que *"evade todos los EDR"* casi nunca es cierto; (4) rara vez aclaran **qué componente** evaden. <mark style="background: #FF5582A6;">Una técnica que ciega el hook de `NtCreateUserProcess` es inútil contra un EDR que recoge la creación de procesos por su driver o por ETW</mark>. De ahí la necesidad de entender los sensores uno a uno — que es lo que hacen las notas siguientes.

# El mapa del resto del área

Con esto montado, el recorrido: [[04 - Function-hooking DLLs|hooking de userland]] → [[07 - Notificaciones de creación de proceso e hilo|callbacks de kernel]] → [[12 - Minifilter drivers de filesystem|minifilters y red]] → [[14 - Event Tracing for Windows|ETW/EtwTi]] → [[17 - Scanners de firmas y YARA|scanners, AMSI y ELAM]] → [[20 - Call-stack spoofing|tradecraft moderno]] → [[25 - Ataque detection-aware de principio a fin|caso práctico]]. Cada sensor, su telemetría y su evasión.

Fuentes: Matt Hand, *Evading EDR* cap. 1 · [J. Johnson — *Evadere Classifications*](https://medium.com/@jsecurity101) · [J. Atkinson — *Funnel of Fidelity*](https://www.specterops.io/) · [MITRE ATT&CK](https://attack.mitre.org).
