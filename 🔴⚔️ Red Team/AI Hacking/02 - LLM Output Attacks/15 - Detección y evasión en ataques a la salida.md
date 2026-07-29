---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "Un ataque a la salida deja rastro en dos sitios independientes: la telemetría del LLM y la telemetría clásica del sink"
Fecha de actualización: 2026-07-28
Nota previa: "[[14 - Marco regulatorio del contenido generado por IA]]"
Nota siguiente: "[[16 - Arsenal de herramientas para ataques a la salida]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 2 del vault; HTB no lo cubre en este módulo. La telemetría general de un sistema de IA está en [[12 - Detección y evasión en sistemas de IA]] y lo específico de prompt injection en [[14 - Detección y evasión en prompt injection]]. Aquí, lo propio de los ataques a la **salida**.

# La diferencia: aquí hay dos superficies de detección

<mark style="background: #ADCCFFA6;">Un ataque a la salida deja rastro en dos sitios independientes: la telemetría del LLM **y** la telemetría clásica del sink.</mark> Es una asimetría que juega a favor del defensor y que conviene entender antes de planificar nada.

| Fase | Dónde queda | Quién lo ve normalmente |
| - | - | - |
| El prompt que provoca la salida | Logs de conversación, plataforma de observabilidad, proveedor | Equipo de IA |
| La salida generada | Los mismos | Equipo de IA |
| **El efecto en el sink** | Log de consultas SQL, log de procesos, WAF, logs de red | **SOC** |

El tercero es el interesante. <mark style="background: #FF5582A6;">Un `UNION SELECT` acabará en el log de consultas de la base de datos igual que si hubiera venido de un formulario</mark>, y un `ping -c 3 127.0.0.1 | id` aparecerá en la telemetría de creación de procesos como cualquier otro comando. **El SOC no necesita saber nada de IA para detectarlo**: sus reglas de siempre disparan.

Eso tiene dos consecuencias operativas:

- **Para el defensor** — la superficie del LLM puede estar sin instrumentar y aun así detectarse el ataque en el sink. Es el argumento para no tratar la seguridad de IA como un silo aparte.
- **Para el atacante** — un payload que evada perfectamente el guardrail sigue siendo perfectamente visible en el otro extremo. Evadir el clasificador no es evadir la detección.

# Detecciones específicas

Reglas que un defensor competente monta y que conviene anticipar:

- **Metacaracteres en la salida del modelo.** Alertar si contiene `<script`, `onerror=`, `UNION SELECT`, `;`, `|`, `$(`, o rutas absolutas. Barato, con falsos positivos manejables si el bot no es un asistente de programación.
- **Consultas SQL que no encajan con las plantillas esperadas.** Si el [[02 - SQL injection a través del LLM|text-to-SQL]] solo debería emitir `SELECT` sobre tres tablas, cualquier otra cosa es una alerta de alta fidelidad. Es la detección más efectiva de esta nota, y la habilita justamente la mitigación de las plantillas.
- **Procesos hijo del servicio del LLM.** Un servicio que solo debería ejecutar `ping` lanzando `id`, `sh`, `curl` o `python` es indicador directo.
- **Peticiones salientes generadas por el renderizado**: dominios fuera de la allowlist, rutas de alta entropía, `GET` a imágenes que devuelven 404. Firma de [[06 - Exfiltración por renderizado de markdown|exfiltración]].
- **`Honeytokens` en el contexto.** Un registro señuelo en la base de datos, un fichero canario en el sistema, una cadena única en el system prompt. Si aparecen en cualquier salida o en cualquier petición saliente, la exfiltración está confirmada — <mark style="background: #8000E1A6;">detección de altísima fidelidad y coste prácticamente cero</mark>, y la única que funciona igual de bien contra un atacante sigiloso.
- **Errores de intérprete en la respuesta.** Un `SyntaxError` o un `sqlite3.OperationalError` sirviéndose al usuario es a la vez fuga de información y señal de sondeo activo.

# Evasión

## Lo que sí ayuda

**El indirector.** El patrón central de todo el módulo, ya visto en [[01 - XSS desde la salida del modelo#El truco que hace viable el ataque|XSS]]: sustituir el payload por una referencia. El modelo genera `<script src="//x.tld/a.js">` en vez del `cookie stealer`, o `import lib` en vez del código malicioso. La salida es sintácticamente inocua y **ningún filtro de salida por firmas la marca**, porque no hay nada que marcar.

**Fragmentar entre respuestas.** Repartir el payload en varias interacciones cuando el sink es acumulativo — varios `INSERT` que construyen un registro, varias imágenes que exfiltran trozos. Los filtros evalúan respuestas individuales.

**Preferir la primitiva menos ruidosa.** `open(path).read()` en vez de `os.system('cat ...')`; leer la tabla directamente en vez de una `UNION`; una petición HTTP legítima de la aplicación en vez de `curl`. Detalle en [[04 - Function calling y ejecución de herramientas#Explotarlo|la escala de primitivas]].

**Usar los canales de salida legítimos.** La exfiltración por imagen markdown es difícil de distinguir del renderizado normal si el dominio está en la allowlist. Encadenar con un [[05 - Bypass de CSP|proxy permitido]] elimina la anomalía de red por completo.

## Lo que no ayuda tanto como parece

<mark style="background: #FFB86CA6;">La evasión del guardrail de entrada no evade la detección en el sink.</mark> Es el error de cálculo más común: se invierte todo el esfuerzo en que el clasificador no vea el prompt, y el `UNION SELECT` aparece igual en el log de la base de datos treinta segundos después.

Si el objetivo tiene un SOC funcionando, la explotación de esta carpeta es **ruidosa por naturaleza**, porque el impacto ocurre en sistemas que sí están monitorizados. Consecuencias prácticas:

- **Demostrar, no explotar.** Un `id` prueba la RCE igual que un `curl | bash`, y no dispara la mitad de las reglas.
- **Contar el número de intentos.** Cada payload fallido contra un sink instrumentado es una alerta. El desarrollo va contra una réplica local, nunca contra producción.
- **Cronometrar.** El intervalo entre la petición al chat y el evento en el sink es lo que permite correlacionar y atribuir; espaciar reduce esa correlación, aunque no la elimina.

# Atribución

Detalle que conviene tener claro y que afecta tanto al informe como al ejercicio:

**Desde el sink, el atacante es la aplicación.** La base de datos ve al usuario de servicio del LLM; el sistema ve al proceso del backend; el servidor web ve su propia respuesta. <mark style="background: #FFB8EBA6;">Reconstruir quién lo provocó exige correlacionar el evento del sink con el log de conversación por marca de tiempo</mark> — y eso solo es posible si ambos existen y comparten un identificador de traza.

Es una recomendación concreta y muy valorada para el informe: **propagar un identificador de correlación** desde la sesión de chat hasta cada llamada a herramienta, consulta y comando. Sin él, un incidente confirmado en la base de datos es imposible de atribuir a un usuario.

Para un ejercicio de red team con objetivo de sigilo, la lectura es la inversa: <mark style="background: #FF5582A6;">si no hay correlación implementada, el sink registra el ataque pero no puede señalar al atacante</mark>, y la investigación se detiene en "la aplicación hizo algo raro".
