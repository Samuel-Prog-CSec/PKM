---
cssclasses:
  - temario
Descripción: "Fuente única del progreso: certificaciones y bloques de estudio; marca una casilla y la Home se actualiza sola"
Fecha de actualización: 2026-07-31
---
---

> [!important]+ Cómo funciona
> Esta nota es la **fuente de verdad** del progreso. `🏡 Home` la lee entera y de aquí salen los anillos y la lista de pendientes — no hay ningún número escrito a mano en ningún otro sitio.
>
> **Marcar módulos**
> - `- [ ]` pendiente · `- [x]` hecho
> - **Saltado a propósito**: ítem **sin casilla** y tachado — `- ~~02 · Getting Started~~ — motivo`. Queda fuera del numerador *y* del denominador. Se escribe así aposta: un checkbox solo alterna entre vacío y marcado, así que un clic accidental destruiría el estado «saltado».
> - Da igual lo que el plugin Tasks añada al final (`✅ 2026-07-31`, prioridades, fechas): se limpia al leer.
>
> **Añadir una certificación nueva** — no hay que tocar nada más, la Home la recoge sola:
> 1. Un encabezado `## SIGLA · Nombre completo` (el `·` es lo que la marca como certificación y le da su anillo).
> 2. Debajo, un párrafo de una línea: es el texto que sale bajo la sigla en la Home.
> 3. Debajo, la lista de módulos.
>
> El **orden de los anillos** es el orden de los encabezados aquí. El color se asigna solo. Un encabezado `##` **sin `·`** no genera anillo: es una sección auxiliar y su primer pendiente aparece en «Qué toca ahora».
>
> **`## Plan de estudio` es un encabezado reservado**: no es un catálogo de módulos sino la planificación con fechas. Se parsea aparte, alimenta su propio panel y **no** entra en «Qué toca ahora».

## CPTS · Penetration Tester

Certificación generalista: red, infraestructura, AD, escalada de privilegios, web y reporting. Los módulos web se reutilizan del trabajo de CWES/CWEE.

- [x] 01 · Penetration Testing Process — `Pentesting/000 - Fases del Pentesting/` (legacy parcial, pendiente enriquecer)
- ~~02 · Getting Started~~ — se salta, contenido cubierto en otros módulos
- [x] 03 · Network Enumeration with Nmap — `02 - Recursos/🛠️ Tools/Nmap/`
- [x] 04 · Footprinting — `Pentesting/001 - Footprinting/`
- [x] 05 · Information Gathering – Web Edition — `Hacking web/02 - Reconocimiento Web/`
- [x] 06 · Vulnerability Assessment — `Pentesting/002 - Evaluación de vulnerabilidades/`
- [x] 07 · File Transfers — `Pentesting/003 - Transferencia de archivos/`
- [x] 08 · Shells & Payloads — `Pentesting/004 - Shells y Payloads/`
- [x] 09 · Using the Metasploit Framework — `02 - Recursos/🛠️ Tools/Metasploit/`
- [x] 10 · Password Attacks — `Pentesting/005 - Ataques a contraseñas/`
- [x] 11 · Attacking Common Services — `Pentesting/006 - Ataque a servicios comunes/`
- [x] 12 · Pivoting, Tunneling & Port Forwarding — `Pentesting/007 - Pivoting y túneles/`
- [x] 13 · Active Directory Enumeration & Attacks — `Red Team/Active Directory/`
- [x] 14 · Using Web Proxies — `Hacking web/01 - Proxies web/`
- [x] 15 · Attacking Web Applications with Ffuf — `02 - Recursos/🛠️ Tools/Ffuf/`
- [x] 16 · Login Brute Forcing — `Hacking web/09 - Brute Forcing/`
- [x] 17 · SQL Injection Fundamentals — `Hacking web/05 - SQL Injection/`
- [x] 18 · SQLMap Essentials — `02 - Recursos/🛠️ Tools/SQLMap/`
- [x] 19 · Cross-Site Scripting (XSS) — `Hacking web/04 - XSS/`
- [x] 20 · File Inclusion — `Hacking web/08 - File Inclusion/`
- [x] 21 · File Upload Attacks — `Hacking web/07 - File Upload/`
- [x] 22 · Command Injections — `Hacking web/06 - Command Injection/`
- [x] 23 · Web Attacks — `Hacking web/11 - Web Attacks/`
- [x] 24 · Attacking Common Applications — `Hacking web/19 - Common Applications/`
- [x] 25 · Linux Privilege Escalation — `Pentesting/008 - Escalada de privilegios Linux/`
- [x] 26 · Windows Privilege Escalation — `Pentesting/009 - Escalada de privilegios Windows/`
- [x] 27 · Documentation & Reporting — `Pentesting/010 - Documentación y reporting/`
- [x] 28 · Attacking Enterprise Networks — `Pentesting/011 - Ataque a redes empresariales/` (capstone) ✅ 2026-07-31

## COAE · AI Red Teamer

Path desarrollado con Google. Repartido en tres áreas: fundamentos a `Ingenieria/`, defensivo a `Blue Team/`, ofensivo a `Red Team/AI Hacking/` (ADR 008 y 011).

- [x] 01 · Fundamentals of AI — `Ingenieria/Inteligencia Artificial/00-01/`
- [x] 02 · Applications of AI in InfoSec — partido: `Ingenieria/IA/02/` + `Blue Team/005/`
- [x] 03 · Introduction to Red Teaming AI — `AI Hacking/00 - Fundamentos de Red Teaming AI/`
- [x] 04 · Prompt Injection Attacks — `AI Hacking/01 - Prompt Injection/`
- [x] 05 · LLM Output Attacks — `AI Hacking/02 - LLM Output Attacks/`
- [x] 06 · AI Data Attacks — `AI Hacking/03 - Ataques a los datos/`
- [x] 07 · Attacking AI - Application and System — `AI Hacking/04/` + `05 - MCP/`
- [x] 08 · AI Evasion - Foundations — `AI Hacking/06 - Evasión de modelos/`
- [x] 09 · AI Evasion - First-Order Attacks — `AI Hacking/07 - Ataques de primer orden/`
- [x] 10 · AI Evasion - Sparsity Attacks — `AI Hacking/08 - Ataques dispersos/`
- [x] 11 · AI Privacy — `AI Hacking/09 - Privacidad en IA/`
- [x] 12 · AI Defense — `Blue Team/007 - Defensa de sistemas de IA/`

## CWES · Web Penetration Tester

Base web. Completa y funcionando ya como material de referencia.

- ~~01 · Web Requests~~ — se salta
- ~~02 · Introduction to Web Applications~~ — se salta
- [x] 03 · Using Web Proxies — `Hacking web/01 - Proxies web/`
- [x] 04 · Information Gathering – Web Edition — `Hacking web/02 - Reconocimiento Web/`
- [x] 05 · Web Fuzzing — `Hacking web/02 - Reconocimiento Web/` (notas 15-24)
- [x] 06 · JavaScript Deobfuscation — `Hacking web/03 - JavaScript Deobfuscation/`
- [x] 07 · Cross-Site Scripting (XSS) — `Hacking web/04 - XSS/`
- [x] 08 · SQL Injection Fundamentals — `Hacking web/05 - SQL Injection/`
- [x] 09 · SQLMap Essentials — `02 - Recursos/🛠️ Tools/SQLMap/`
- [x] 10 · Command Injections — `Hacking web/06 - Command Injection/`
- [x] 11 · File Upload Attacks — `Hacking web/07 - File Upload/`
- [x] 12 · Server-side Attacks — `Hacking web/{12 SSRF, 13 SSTI, 14 SSI, 15 XSLT}/`
- [x] 13 · Login Brute Forcing — `Hacking web/09 - Brute Forcing/`
- [x] 14 · Broken Authentication — `Hacking web/10 - Authentication/`
- [x] 15 · Web Attacks — `Hacking web/11 - Web Attacks/`
- [x] 16 · File Inclusion — `Hacking web/08 - File Inclusion/`
- [x] 17 · Attacking GraphQL — `Hacking web/16 - GraphQL/`
- [x] 18 · API Attacks — `Hacking web/17 - API Attacks/`
- [x] 19 · Attacking Common Applications — `Hacking web/19 - Common Applications/`
- [x] 20 · Bug Bounty Hunting Process — `Hacking web/30 - Bug Bounty/`

## CWEE · Senior Web Penetration Tester

En pausa mientras CPTS y COAE son el foco. Lo que queda es whitebox, deserialización y lógica de parámetros.

- [x] 01 · Injection Attacks — `Hacking web/{21 LDAP, 22 XPath, 23 PDF}/`
- [x] 02 · Introduction to NoSQL Injection — `Hacking web/20 - NoSQL Injection/`
- [x] 03 · Attacking Authentication Mechanisms — `Hacking web/10 - Authentication/Avanzado/`
- [x] 04 · Advanced XSS and CSRF Exploitation — `Hacking web/04 - XSS/Avanzado/` + `24 - CSRF/`
- [x] 05 · HTTPs/TLS Attacks — `Hacking web/26 - HTTPs-TLS/`
- [x] 06 · Abusing HTTP Misconfigurations — `Hacking web/25 - HTTP/Misconfigurations/`
- [x] 07 · HTTP Attacks — `Hacking web/25 - HTTP/Attacks/`
- [x] 08 · Blind SQL Injection — `Hacking web/05 - SQL Injection/2️⃣ Nivel avanzado/Blind/`
- [ ] 09 · Intro to Whitebox Pentesting — `Hacking web/Whitebox/Intro/` (crear)
- [x] 10 · Modern Web Exploitation Techniques — `Hacking web/28 - Modern Exploitation/`
- [ ] 11 · Introduction to Deserialization Attacks — `Hacking web/Deserialization/Intro/` (crear)
- [ ] 12 · Whitebox Attacks — `Hacking web/Whitebox/Attacks/` (crear)
- [x] 13 · Advanced SQL Injections — `Hacking web/05 - SQL Injection/2️⃣ Nivel avanzado/Advanced/`
- [ ] 14 · Advanced Deserialization Attacks — `Hacking web/Deserialization/Advanced/` (crear)
- [ ] 15 · Parameter Logic Bugs — `Hacking web/Parameter Logic Bugs/` (crear)

## Plan de estudio

Rotación de repaso de la base web ya escrita — **dos bloques por semana**. `Reconocimiento Web`, `Proxies web` y `SQLMap` se intercalan cuando sobre tiempo. Lo lee la Home, que calcula el plazo consumido de cada semana y avisa de retrasos y cuellos de botella.

El `esfuerzo` es la **suma de las estimaciones oficiales de HTB Academy** de los módulos de esa semana (campo `estimated_time_of_completion`), no una cifra a ojo.

**Formato de una línea**, editable desde el modal del plugin Tasks:
`- [estado] Tarea [[bloque del PKM]] 🛫 inicio 📅 límite ⏫ [esfuerzo:: 6h] [depende:: otra tarea] [nota:: por qué está parada]`

Estados: `[ ]` pendiente · `[/]` en progreso · `[x]` hecha · `[-]` cancelada. Prioridad: `⏫` alta · `🔼` media · `🔽` baja. Todo salvo la tarea y el límite es opcional.

> [!tip]+ Se marca desde la Home
> El círculo de cada tarea en `🏡 Home` **cicla el estado** (pendiente → en progreso → hecha → pendiente) y reescribe la línea de aquí. Al cerrarla le pone la fecha `✅`; al reabrirla se la quita. Las cerradas siguen apareciendo al final de la lista, atenuadas, para poder revertir un clic accidental.
>
> El botón **«+ Nueva tarea»** de la Home añade una plantilla al final de esta sección y abre esta nota para que la rellenes.

- [/] Semana 1 · Brute forcing + SQLi básico [[Brute Forcing.base]] 🛫 2026-07-28 📅 2026-08-03 ⏫ [esfuerzo:: 14h]
- [/] Semana 1 · Nmap [[Nmap.base]] 🛫 2026-07-28 📅 2026-08-03 🔽 [esfuerzo:: 7h]
- [ ] Semana 2 · XSS básico + File Inclusion [[XSS.base]] 🛫 2026-08-04 📅 2026-08-10 ⏫ [esfuerzo:: 14h]
- [ ] Semana 2 · Evaluación de vulnerabilidades [[Evaluación de vulnerabilidades.base]] 🛫 2026-08-04 📅 2026-08-10 🔽 [esfuerzo:: 2h]
- [ ] Semana 3 · Command Injection + File Upload [[Command Injection.base]] 🛫 2026-08-11 📅 2026-08-17 [esfuerzo:: 14h]
- [ ] Semana 4 · SSRF + SSTI/SSI/XSLT [[SSRF.base]] 🛫 2026-08-18 📅 2026-08-24 [esfuerzo:: 8h]
- [ ] Semana 5 · Authentication básico + GraphQL [[Authentication.base]] 🛫 2026-08-25 📅 2026-08-31 [esfuerzo:: 24h]
- [ ] Semana 6 · API Attacks + Web Attacks [[API Attacks.base]] 🛫 2026-09-01 📅 2026-09-07 [esfuerzo:: 24h]
- [ ] Semana 7 · XSS avanzado + SQLi Blind [[XSS Avanzado.base]] 🛫 2026-09-08 📅 2026-09-14 [esfuerzo:: 24h]
- [ ] Semana 8 · Authentication avanzado + NoSQLi [[Authentication Avanzado.base]] 🛫 2026-09-15 📅 2026-09-21 [esfuerzo:: 16h]

## Ejes

Los ejes transversales que muestra `🏡 Home` bajo «Los ejes del vault». Salen del campo `Tipo/` del frontmatter, no de la carpeta.

**Formato**: `Tipo/Tag · Título · color · criterio`. El **color es opcional** (`red`, `blue`, `teal`, `amber`, `violet`, `green`); si se omite, la Home asigna uno libre. El criterio puede llevar los `·` que quiera: solo se parten los dos primeros.

Un `Tipo/` que **no** esté listado aquí igual aparece en la Home — con su nombre crudo y sin criterio — así que esta sección es para ponerle nombre bonito y explicación, no para darlo de alta.

- Tipo/Arsenal · Arsenal · green · El set de herramientas actual de cada tema, con el comando de ejemplo y cuándo usar cada una.
- Tipo/Deteccion · Detección y evasión · red · Qué telemetría deja la técnica y cómo se evade hoy: timing, fragmentación, living-off-the-land.
- Tipo/Defensa · Defensa y mitigación · blue · Cómo se previene y se endurece: la contraparte defensiva de cada ataque.
- Tipo/Introduccion · Puertas de entrada · violet · La nota por la que se empieza cada sub-tema. Útil para retomar un área que tienes fría.
