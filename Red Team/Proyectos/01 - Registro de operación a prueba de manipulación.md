---
tags:
  - Proyectos
  - Go
  - Pentesting/Reporting
  - Tipo/Proyecto
Descripción: "Grabadora de sesión con cadena de hashes que responde el deconflicting con certeza y convierte el trabajo del día en material de informe sin reescribir nada"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Guardián de alcance para engagements]]"
Nota siguiente: "[[02 - Espejo de huella del atacante]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 1
Esfuerzo: 2 semanas
---
---

**Nombre propuesto**: `flightrec`

A media mañana el cliente llama: *"a las 14:32 de ayer alguien intentó autenticarse 40 veces contra el DC. ¿Fuisteis vosotros?"*. Esa pregunta —el **deconflicting**— se responde con certeza o no se responde. Si la respuesta es "creo que sí, déjame mirar mis notas", el SOC ya ha activado el plan de respuesta a incidentes por algo que hiciste tú, y la factura de esa confusión la paga el cliente en horas de su equipo.

El otro lado del mismo problema aparece dos semanas después, al redactar: <mark style="background: #FFB86CA6;">reconstruir a posteriori qué comando produjo qué salida es donde se pierden más horas de un engagement</mark>, y donde se cuelan los errores del informe.

# El problema que resuelve

Las herramientas actuales cubren los extremos y dejan el centro vacío. `script(1)` y `asciinema` graban la sesión, pero producen un blob que hay que ver en tiempo real para entenderlo: no se puede consultar *"qué toqué en el rango 10.20.5.0/24"*. Las plataformas de reporting como **Ghostwriter** o **SysReptor** sí tienen registro de actividad, pero se rellena a mano — y lo que se rellena a mano se rellena tarde, mal, o nunca.

Falta la pieza intermedia: <mark style="background: #ADCCFFA6;">un registro automático, indexado por objetivo y por tiempo, que nadie tiene que acordarse de escribir</mark>.

# Alcance del proyecto

Un envoltorio de terminal que se pone delante de la sesión de trabajo (`flightrec zsh`) y captura, por cada comando ejecutado: marca de tiempo en UTC, el comando literal, el directorio de trabajo, el usuario y host desde el que se lanzó, el código de salida, la duración y la salida (truncada por tamaño configurable, con el volcado completo en un adjunto aparte).

Sobre eso, dos capas que son las que le dan valor:

**Extracción de objetivos.** El registro no sirve de nada si hay que hacer `grep` sobre 4.000 líneas. El proyecto extrae de cada comando las **IPs, CIDRs, dominios y puertos** que aparecen, y los indexa. La consulta que importa es directa:

```shell-session
$ flightrec query --target 10.20.5.14 --from "2026-08-11 14:00" --to "2026-08-11 15:00"
14:31:58Z  netexec smb 10.20.5.14 -u users.txt -p 'Verano2026!'  (exit 0, 41s)
14:33:12Z  netexec smb 10.20.5.14 -u users.txt -p 'Otoño2026!'   (exit 0, 39s)
```

**Integridad encadenada.** Cada entrada incluye el hash de la anterior, de modo que el registro es *append-only* verificable: alterar o borrar una entrada del pasado invalida toda la cadena posterior. Es el esquema clásico de *secure audit log*, y su virtud aquí no es defenderse de un atacante sino <mark style="background: #8000E1A6;">poder afirmar ante el cliente que el registro que le entregas no se ha retocado</mark>.

# Funcionalidades principales

| Funcionalidad | Detalle |
| --- | --- |
| Captura por PTY | Envuelve la shell real, no la sustituye. Todo funciona igual: `vim`, `tmux`, colores, `Ctrl-C` |
| Índice por objetivo y por tiempo | La consulta de deconflicting se responde en segundos, no reconstruyendo |
| Cadena de hashes | Cada entrada encadena con la anterior; `flightrec verify` comprueba la cadena entera |
| Exportación a informe | Markdown y JSON, con los comandos de una cadena de ataque en orden y sus salidas como evidencia |
| Redacción de secretos | Filtro configurable que enmascara contraseñas y hashes antes de escribirlos a disco |
| Marcadores manuales | `flightrec mark "primer acceso a DC01"` para anclar hitos que luego son la línea temporal del informe |

# Cosas a tener en cuenta

> [!warning]+ El registro se convierte en el objeto más sensible del engagement
> Contiene credenciales en claro, hashes, rutas internas y la topología del cliente. <mark style="background: #FF5582A6;">Un registro de operación filtrado es peor que no haber hecho el pentest</mark>. Cifrado en reposo desde el primer día, y la política de destrucción tras la retención acordada debe estar implementada, no documentada.

- **La marca de tiempo va en UTC, siempre, y con la zona registrada aparte.** El SOC del cliente correlaciona en su huso; tú operas quizá en otro; una mezcla de horarios de verano convierte el deconflicting en una discusión. Es un detalle de una línea de código que evita el problema entero.
- **Cadena de hashes ≠ firma.** Encadenar demuestra que el registro es internamente coherente, pero quien controla la cadena puede regenerarla completa. Si de verdad se quiere no repudio, hay que firmar periódicamente con una clave que evolucione (*forward-secure logging*) o anclar el hash raíz en un servicio externo. Merece la pena saber la diferencia y **no vender más garantía de la que se da**.
- **Cuidado con presentarlo como requisito regulatorio.** TIBER-EU y DORA exigen que el equipo rojo documente su actividad y aporte evidencia, y el deconflicting es parte del proceso; pero <mark style="background: #FFB8EBA6;">ninguno de los dos especifica cadenas de hash ni formato técnico</mark>. La herramienta encaja con lo que piden, no implementa una obligación que exista con ese nombre.
- **Truncar la salida es una decisión de diseño, no un atajo.** Un `nmap -A` de un `/16` genera megabytes que nadie va a leer. El patrón que funciona es guardar las primeras y últimas N líneas en el índice y el volcado íntegro en un adjunto direccionado por hash.

# Stack y decisiones técnicas

`creack/pty` para el PTY, `bbolt` o SQLite para el índice local (sin servidor, un fichero por engagement), y la extracción de objetivos con expresiones regulares compiladas una vez. Go es buena elección aquí precisamente por el binario único: <mark style="background: #FFB8EBA6;">el registro tiene que poder correr en la máquina de salto del cliente, donde no vas a instalar un intérprete</mark>.

# Fuera de alcance

No es una plataforma de reporting ni pretende sustituir a SysReptor. Exporta hacia ellas y se acabó. Tampoco captura tráfico de red — eso es un `pcap` y ya existe.

# Criterio de terminado

Cuando una pregunta de deconflicting real se responde en menos de un minuto con una consulta, la verificación de la cadena detecta una entrada modificada a mano, y el export produce la sección de cadena de ataque del informe sin reescribir los comandos.

# Conexiones en el vault

El procedimiento de deconflicting y por qué el cliente necesita esta respuesta rápido está en [[03 - Coordinación de operadores y deconflicting]]; la exigencia de evidencia por nivel de evasividad, en [[12 - Niveles de evasividad y testing dirigido por amenazas (TLPT)]]. La salida alimenta [[02 - Evidencias, capturas y redacción]] y [[04 - Componentes de un informe I (cadena de ataque y resumen ejecutivo)]]. Las plataformas con las que integra están en [[08 - Arsenal de herramientas de documentación y reporting]].

> [!info]+ Fuentes
> - Banco Central Europeo, [TIBER-EU Framework](https://www.ecb.europa.eu/paym/cyber-resilience/tiber-eu/html/index.en.html) — requisitos de documentación y evidencia del equipo rojo (consultado 2026-08-04).
> - Schneier & Kelsey, *Secure Audit Logs to Support Computer Forensics* (1999) — el esquema de encadenado con evolución de clave que sigue siendo la referencia.
> - `creack/pty`, [documentación del paquete](https://pkg.go.dev/github.com/creack/pty) — captura de PTY en Go.
