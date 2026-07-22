---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Reporting
Fecha de actualización: 2026-07-17
Nota previa: "[[00 - Programas de bug bounty y scope]]"
Nota siguiente: "[[02 - Recon y herramientas para bug bounty]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

En bug bounty, la técnica es la mitad; la otra mitad es **operar dentro de las reglas** — legales y de conducta. Salirse de scope o comportarse mal no solo quema un programa: arruina tu *track record*, que es lo que abre las invitaciones a los programas privados jugosos ([[00 - Programas de bug bounty y scope]]).

# El código de conducta

<mark style="background: #FF5582A6;">El historial de violaciones de un cazador siempre cuenta</mark>. Cada programa y cada plataforma tienen su *code of conduct*/política; leerla a fondo no es burocracia — te hace más efectivo y evita fricción en el *triage*. Para consolidarte, hay que equilibrar **profesionalismo y capacidad técnica**: el mejor bug mal comunicado o entregado con malos modos vale menos.

# Legalidad y safe harbor

La diferencia entre *hacking* ético y delito es el **permiso**, y en bug bounty ese permiso lo define la política del programa.

- <mark style="background: #ADCCFFA6;">**Safe harbor**</mark> es la cláusula por la que la organización se compromete a **no tomar acciones legales** contra la investigación de buena fe realizada **dentro del scope y las reglas**. El estándar de facto es el [**disclose.io** Gold Standard Safe Harbor](https://disclose.io/) — busca su presencia en la política antes de tocar nada.
- En EE. UU., la [política del DOJ de 2022 sobre la CFAA](https://www.justice.gov/archives/opa/pr/department-justice-announces-new-policy-charging-cases-under-computer-fraud-and-abuse-act) dejó de perseguir la *good-faith security research*, pero <mark style="background: #FFB86CA6;">el safe harbor solo te cubre si te ciñes al scope</mark>. Un test fuera de los dominios/reglas autorizados pierde esa protección.
- Cuidado con acciones intrínsecamente destructivas o que afecten a terceros (DoS, ingeniería social a empleados, acceso a datos reales de usuarios) — casi siempre explícitamente prohibidas.

> [!warning]+ El scope es la línea legal, no una sugerencia
> `Out of Scope` no es "menos interesante" — es "territorio sin cobertura legal". Leer meticulosamente scope, out-of-scope y reglas de engagement **antes** de empezar te ahorra reportes rechazados y, en el peor caso, problemas legales. No malgastes horas en algo que nunca pagarán ni deberías tocar.

# Interactuar con el equipo de triage

Enviado el reporte, la conducta profesional sigue:

- <mark style="background: #8000E1A6;">**No interactúes de inmediato**</mark>. Da tiempo al equipo a procesar y validar. Respeta los *vendor response SLAs* si el programa los publica, y **no hagas spam**.
- Si no responden en un plazo razonable y fue vía plataforma, existe la **mediación**.
- Cuando respondan, anota el usuario del *triager* y **etiquétalo** en la comunicación futura. Nunca uses canales no oficiales (redes sociales, etc.).
- Ante **desacuerdos de severidad/bounty**: explica tu razonamiento guiándoles por **cada métrica del CVSS** que elegiste ([[03 - Escribir un buen reporte]]), verifica que tu envío cumple política y scope, y que el pago encaja con lo publicado. Si nada funciona, mediación.

Un reporte profesional merece una comunicación profesional. Mantén la calma y actúa como el profesional de seguridad que eres — incluso cuando no estés de acuerdo.

Con las reglas claras, empieza el trabajo de campo: el [[02 - Recon y herramientas para bug bounty|recon]] sobre el objetivo autorizado.
