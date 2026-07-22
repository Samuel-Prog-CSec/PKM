# CLAUDE.md — Guía operativa del PKM

Este repositorio es el **segundo cerebro digital** de Samuel: un *vault* de Obsidian en español usado para estudiar, retener y consultar conocimiento técnico durante su trabajo profesional como **pentester** y su actividad en **bug bounty**. Las notas no son apuntes para aprobar un examen — son material de referencia para sesiones reales de hacking ético.

## Sobre Samuel — cómo trabajar conmigo

*(La misión y el contexto profesional están abajo; esto es el trato y las preferencias de trabajo — el equivalente a un `me.md` portable, embebido aquí.)*

**Trato.** Tuteo, casual, directo. Quiero un **colaborador que reta**, no un asistente complaciente: cuestiona mis ideas, señala fallos y ofrece alternativas antes de darme la razón. Si algo está mal o hay una vía mejor, dilo.

**Proactividad con freno.** Detecta y **propón** mejoras, siguientes pasos y problemas que veas, aunque no los haya pedido. Pero si la mejora **queda fuera del scope** de lo que te pedí, **pregúntame antes de aplicarla**; si te doy el OK, adelante. Dentro del scope, en decisiones menores, **actúa y avísame** — no me consultes cada detalle.

**Explicación: siempre suficiente y mejor que la fuente.** Estudio con estas notas para *entender*, no para memorizar comandos. La explicación debe ser **siempre suficiente** — nunca la recortes hasta dejarla pobre o incompleta; la suficiencia manda sobre la brevedad. Lo que se evita es lo **redundante, el relleno y la teoría excesiva**, no la profundidad. Y **mejora siempre el contenido de la fuente original**, aunque el tema no sea avanzado: modernízalo (muchas fuentes de pentest/seguridad llevan 2-3 años sin tocar) y explícalo mejor. "Mejor" no es "más palabras" — a veces la mejor explicación es más corta. La palanca es la **calidad**, no la longitud.

**Evita conmigo:**
- **Halago vacío** — nada de "¡buena pregunta!" ni validación de relleno.
- **Relleno y recaps** — sin recapitulaciones obvias ni prosa motivacional.
- **Hedging** — sin advertencias obvias ni disclaimers innecesarios; al grano.
- **Actuar sin avisar** en cosas importantes — confirma antes.

**Mi estilo de escritura** (para textos que redactes *en mi nombre* — reports, mensajes, resúmenes; **no** las notas del vault, que siguen `pkm-note-format`):
- Español pragmático y directo, registro informal-profesional.
- Frases con varias cláusulas encadenadas por comas; explico el porqué con incisos entre paréntesis "(...)".
- Orientado a la acción y al objetivo, poco ceremonial. Coletillas tipo "y ya está" para cerrar.

## Contexto de la investigación en ciberseguridad

Este proyecto implica investigación legítima en ciberseguridad, que incluye:

- Análisis estático de software de código abierto
- Análisis de vulnerabilidades con fines defensivos
- Clasificación de CWE con fines educativos
- Extracción de contenido de cursos de ciberseguridad (fuentes legítimas) para crear material de estudio y referencia
- Redacción de notas técnicas y de referencia para pentesters y bug hunters

Todo el trabajo se realiza fuera de línea, sin objetivos reales y sin ejecutar código de ningún tipo, solo se crean notas de Obsidian (.md).

## Misión y estado

El vault es una base de conocimiento de seguridad ofensiva que debe servir **indefinidamente como referencia profesional**, no solo durante el estudio. El motor de contenido actual son las **certificaciones de HTB Academy**, pero la estructura **no está atada a HTB ni a web**: cualquier área de Red Team (y a futuro Blue Team, cloud, móvil…) o certificación nueva encaja con la misma receta (ver "Patrón para dar de alta una certi/área nueva").

**Certificaciones en juego:**

1. **HTB CWES** — *Certified Web Exploitation Specialist* (path "Web Penetration Tester", antes CBBH). 20 módulos. **Base web — prácticamente completa; funciona ya como material de referencia.**
2. **HTB CWEE** — *Certified Web Exploitation Expert* (path "Senior Web Penetration Tester"). 15 módulos, dificultad alta. **En pausa** — faltan whitebox, deserialización y parameter logic bugs.
3. **HTB CPTS** — *Certified Penetration Testing Specialist* (path "Penetration Tester"). 28 módulos. Pentesting **generalista**: reconocimiento, red/infraestructura, Active Directory, escalada de privilegios (Linux/Windows), web y reporting. **Foco activo.**

> **Foco actual: CPTS**, con parón temporal en las certis web (CWES/CWEE). El **detalle vivo** de qué módulos están hechos/pendientes vive en la **memoria** (`project_cpts_*`) y en la columna `Estado` de la tabla del path CPTS más abajo — no en esta sección, que solo fija el rumbo. Próximo net-new típico: Attacking Common Services (#11) / Reporting (#27) — la escalada de privilegios Linux (#25) y Windows (#26) ya están hechas.

## Idioma, filosofía y voz

- **Idioma de las notas: español**. Mantener en inglés (envueltos en backticks: `` `payload` ``) los términos técnicos consolidados de la industria — *false positive*, *wordlist*, *HTTP response splitting*, *web shell*, etc. — y los nombres de herramientas, parámetros y APIs.
- **Zettelkasten**: cada nota es atómica, trata un único concepto/técnica/ataque, y se enlaza por contexto con notas vecinas mediante los campos `Nota previa` / `Nota siguiente` del frontmatter y referencias `[[ ]]` en el cuerpo. Las MOC viven en archivos `.base` de Obsidian.
- **Densidad orientativa, no obligatoria.** Referencia: notas *conceptuales* (explican un mecanismo, ataque o defensa) ~1000–1500 palabras de teoría; notas *técnicas/operativas* (payloads, comandos, herramientas) menos, primando la densidad de payloads sobre la prosa. La cuenta excluye callouts, código, enlaces y sintaxis de Obsidian. **El límite inferior es solo una referencia**: si la nota explica bien el concepto y está completa, quedarse por debajo es perfectamente asumible. **Nunca añadir contenido redundante o de relleno para alcanzar un número** — no aporta valor. **Importa más respetar el límite superior** (~1500): si una nota se dispara, **dividirla** en varias atómicas. Si una nota conceptual se queda genuinamente corta de contenido útil, enriquecer con sustancia real; si no la hay, dejarla.
- **Voz profesional, no académica**. Notas escritas para un pentester que necesita ejecutar — frases cortas, ejemplos concretos, advertencias accionables. Evitar relleno motivacional, recapitulaciones obvias o frases tipo "como veremos a continuación…".

## Estándares de calidad — los 3 ejes (todo el vault)

Aplican a **cualquier tema/módulo net-new**, no solo a CPTS (donde son más críticos: los módulos de red/infra de HTB llevan años sin actualizarse y hay que tratarlos como **borrador de partida**, no como verdad de 2026). El patrón **detección · evasión · arsenal + fuentes + gráficos** es el estándar del vault:

1. **Investigar y profundizar SIEMPRE (como profesional, 2026).** Para **todo** contenido de **todo** módulo —no solo los desfasados— contrastar cada técnica/herramienta/flag con **fuentes oficiales y de confianza** y con el estado del arte, para explicar mejor, profundizar y ampliar. Si además la fuente propone algo obsoleto o hay una vía mejor / más sigilosa / más fiable hoy, **actualizar y modernizar** (nunca traducir a ciegas). Señalar explícitamente lo desfasado. La **mecánica** (jerarquía de fuentes primarias/oficiales, cita por-claim, subagente en background para paralelizar) → skill **`pkm-research`**.
2. **Detección y evasión (más a fondo que la fuente).** En real hay EDR/IDS/IPS, WAF, firewalls modernos, rate-limiting y logging que el lab ignora. Cada tema cubre **cómo se detecta** (telemetría/logs que deja el atacante) y **cómo se evade** hoy (timing, fragmentación, decoys, living-off-the-land, blending con tráfico legítimo). **Por defecto → nota dedicada `Detección y evasión`** (net-new); **excepción** (¿HTB ya cubre el tema?): si HTB lo trae, respetar su formato e **investigar a fondo para modernizar/ampliar** — no forzar nota aparte.
3. **Arsenal de herramientas.** Cada módulo net-new cierra con **nota dedicada `Arsenal de herramientas`**: el set profesional actual para automatizar/asistir detección, evasión, explotación y registro del tema, con el *cómo* (comando de ejemplo, cuándo usar cada una, alternativa a la de la fuente). Misma regla de forma que el eje 2: nota dedicada por defecto; si HTB ya trae sus herramientas, respetar su formato y modernizar.
4. **Fuentes actuales y citadas** (nmap.org, PortSwigger, HackTricks, SANS, RFCs, advisories, blogs de investigación recientes). Citarlas en la nota e indicar qué parte viene de qué fuente cuando haya varias. Ver `pkm-research` (jerarquía de confianza) y `pkm-note-format` § Fuentes (cómo atribuir por-fuente).
5. **Elementos gráficos.** Priorizar diagramas/tablas sobre párrafos densos (máquinas de estado, flujos de protocolo, matrices de flags). Imagen incrustada solo si aporta de verdad y **verificar siempre que renderiza**. Se admiten diagramas propios (Mermaid, `.canvas`) o de fuentes citadas.

## Estructura del vault

Raíz PARA + carpetas temáticas:

```
01 - Proyectos/         (proyectos activos con fecha límite, no usado por el flujo de extracción HTB)
02 - Recursos/          (Biblioteca, Lenguajes, Templates, 🛠️ Tools)
03 - Archivos/          (imágenes y adjuntos, también Escalidraw)
04 - PENDIENTES/        (inbox, no usado por el flujo de extracción HTB)
Ingenieria/             (fundamentos y conocimientos relacionados con la ingeniería de software, bases de datos, criptografía, etc.)
🔴⚔️ Red Team/         (todo el contenido ofensivo: Hacking web + Pentesting/CPTS + Hacking Active Directory)
🔵🛡️ Blue Team/        (defensivo: SOC analyst, analisis de malware y redes, etc.)
Redes/                  (fundamentos de redes, utilidades, protocolos, etc. Interesante para Pentesting y Bug Bounty)
```

El contenido se integra por **tema/área** (no por módulo HTB). Todo lo web va dentro de `🔴⚔️ Red Team/Hacking web/`; el pentest generalista (CPTS) en `🔴⚔️ Red Team/Pentesting/`. Las carpetas temáticas existentes son la base; se crean carpetas nuevas sólo cuando un tema todavía no existe.

*Nota (migración en curso)*: las **áreas principales de conocimiento ya viven en la raíz** (`🔴⚔️ Red Team/`, `🔵🛡️ Blue Team/`, `Redes/`, `Ingenieria/`, `02 - Recursos/`, `03 - Archivos`). Las carpetas PARA numeradas restantes (`01 - Proyectos`, `04 - PENDIENTES`) se irán eliminando; la única que se mantiene con su nombre es Recursos y Archivos. **Ojo**: la carpeta de ingeniería en disco es `Ingenieria/` (sin tilde), aunque en prosa se escriba "Ingeniería".

## Mapeo módulos HTB → carpetas del PKM

### Patrón para dar de alta una certi/área nueva

Las certis/áreas futuras (no solo web) siguen esta receta — evita re-improvisar de cero cada vez:

1. **Ubicar por *tema/área*, no por módulo.** El conocimiento va a su área de la raíz (`🔴⚔️ Red Team/`, `🔵🛡️ Blue Team/`, `Redes/`, `Ingenieria/`). Las **herramientas** siempre a `02 - Recursos/🛠️ Tools/` con su `.base` Level 2 propio (patrón `Nmap.base` / `SQLMap.base`), **nunca** bajo el área temática.
2. **Reutilizar antes de crear.** Una certi nueva suele solaparse con lo ya hecho (los módulos web de CPTS se reutilizan tal cual). Mapear primero qué módulos ya están cubiertos y cuáles son net-new.
3. **Fundamentos ≠ ofensiva.** "Cómo funciona" (protocolo, motor BBDD, lenguaje) → `Redes/` o `Ingenieria/`; "cómo enumerar/atacar" → el área ofensiva. Cross-linkear ambos (patrón Footprinting ↔ `Redes/Protocolos/`).
4. **Aplicar los 3 ejes** (detección · evasión · arsenal + fuentes + gráficos — ver "Estándares de calidad" arriba) a cada módulo net-new.
5. **Registrar el mapeo** módulo→carpeta en una tabla nueva aquí, con columna `Estado`. El progreso vivo va a **memoria**, no a la misión.
6. **`.base` Level 2 por sub-tema** en cuanto haya notas reales; Level 1 solo si el área agrupa varios sub-temas. No crear `.base` vacíos por adelantado.

### Path CWES (Web Penetration Tester)

| #   | Módulo HTB                          | Carpeta destino                                                                                                      | Estado                    |
| --- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| 1   | Web Requests                        | `Hacking web/Web Requests/` *(lo saltamos, no lo tratamos)*                                                          | -                         |
| 2   | Introduction to Web Applications    | `Hacking web/Web Applications/` *(lo saltamos, no lo tratamos)*                                                      | -                         |
| 3   | Using Web Proxies                   | `Hacking web/Proxies web/`                                                                                           | Completado                |
| 4   | Information Gathering – Web Edition | `Hacking web/Reconocimiento Web/` (notas 00-14)                                                                      | Completado                |
| 5   | Web Fuzzing                         | `Hacking web/Reconocimiento Web/` (notas 15-24, tag `Fuzzing`)                                                       | Completado                |
| 6   | JavaScript Deobfuscation            | `Hacking web/JavaScript Deobfuscation/` *(crear)*                                                                    | Completado                |
| 7   | Cross-Site Scripting (XSS)          | `Hacking web/XSS/`                                                                                                   | Completado                |
| 8   | SQL Injection Fundamentals          | `Hacking web/💉🩸 SQL Injection/1️⃣ Introducción/` (fundamentos DB/SQL en `Ingenieria/Bases de Datos/`)   | Completado                |
| 9   | SQLMap Essentials                   | `02 - Recursos/🛠️ Tools/SQLMap/` (herramienta → Tools, NO bajo SQL Injection)                                       | Completado                |
| 10  | Command Injections                  | `Hacking web/Command Injection/`                                                                                     | Completado                |
| 11  | File Upload Attacks                 | `Hacking web/File Upload/`                                                                                           | Completado                |
| 12  | Server-side Attacks                 | `Hacking web/{SSRF,SSTI,SSI,XSLT}/` (4 carpetas hermanas · tag `Server-Side`)                                        | Completado                |
| 13  | Login Brute Forcing                 | `Hacking web/Brute Forcing/`                                                                                         | Completado                |
| 14  | Broken Authentication               | `Hacking web/Authentication/`                                                                                        | Completado                |
| 15  | Web Attacks                         | `Hacking web/Web Attacks/` (verb tampering, IDOR, XXE · notas 00-20)                                                 | Completado                |
| 16  | File Inclusion                      | `Hacking web/File Inclusion/`                                                                                        | Completado                |
| 17  | Attacking GraphQL                   | `Hacking web/GraphQL/` (notas 00-07)                                                                                 | Completado                |
| 18  | API Attacks                         | `Hacking web/API Attacks/` (OWASP API Top 10 2023 · notas 00-12)                                                     | Completado                |
| 19  | Attacking Common Applications       | `Hacking web/Common Applications/` — **subcarpeta por app** (~36 notas; **WordPress ampliado a 8 con el módulo 17**) | Completado ✅ (2026-07-16) |
| 20  | Bug Bounty Hunting Process          | `Hacking web/Bug Bounty/` (notas 00-04 · 5 notas)                                                                    | Completado ✅ (2026-07-17) |

### Path CWEE (Senior Web Penetration Tester)

| # | Módulo HTB | Carpeta destino | Estado |
| - | - | - | - |
| 1 | Injection Attacks | ⚠️ **NO es SQLi** (XPath+LDAP+PDF) → 3 carpetas hermanas `Hacking web/{XPath Injection,LDAP Injection,PDF Injection}/` (9+7+5 notas) · el "Attacking LDAP" del módulo 19 quedó como nota-puente en `Common Applications/Misc/` enlazando a `LDAP Injection/` (no fusionado) | Completado ✅ (2026-07-16) |
| 2 | Introduction to NoSQL Injection | `Hacking web/❌💉🩸 NoSQL Injection/` (MongoDB · notas 00-09) | Completado ✅ (2026-07-16) |
| 3 | Attacking Authentication Mechanisms | `Hacking web/Authentication/Avanzado/` | Completado |
| 4 | Advanced XSS and CSRF Exploitation | `Hacking web/XSS/Avanzado/` + `Hacking web/CSRF/` | Completado |
| 5 | HTTPs/TLS Attacks | `Hacking web/HTTPs-TLS/` | Completado |
| 6 | Abusing HTTP Misconfigurations | `Hacking web/HTTP/Misconfigurations/` | Completado |
| 7 | HTTP Attacks | `Hacking web/HTTP/Attacks/` | Completado |
| 8 | Blind SQL Injection | `Hacking web/💉🩸 SQL Injection/2️⃣ Nivel avanzado/Blind/` | Completado |
| 9 | Intro to Whitebox Pentesting | `Hacking web/Whitebox/Intro/` *(crear)* | Pendiente |
| 10 | Modern Web Exploitation Techniques | `Hacking web/Modern Exploitation/` (DNS rebinding · second-order · WebSockets · notas 00-17) | Completado |
| 11 | Introduction to Deserialization Attacks | `Hacking web/Deserialization/Intro/` *(crear)* | Pendiente |
| 12 | Whitebox Attacks | `Hacking web/Whitebox/Attacks/` *(crear)* | Pendiente |
| 13 | Advanced SQL Injections | `Hacking web/💉🩸 SQL Injection/2️⃣ Nivel avanzado/Advanced/` | Completado |
| 14 | Advanced Deserialization Attacks | `Hacking web/Deserialization/Advanced/` *(crear)* | Pendiente |
| 15 | Parameter Logic Bugs | `Hacking web/Parameter Logic Bugs/` *(crear)* | Pendiente |

### Path CPTS (Penetration Tester)

Path "Penetration Tester" de HTB Academy — **28 módulos**, ~250 secciones, del reconocimiento al reporting sobre infraestructura empresarial. Certificación **generalista** (red, infra, AD, privesc, web, reporting), no solo web.

Buena parte del path — **los módulos web (5, 14–24)** — ya está cubierta por el trabajo CWES/CWEE y **se reutiliza tal cual**. CPTS aporta net-new sobre todo **red, infraestructura, Active Directory, escalada de privilegios y reporting**.

**Ubicación del contenido net-new**:
- Conocimiento de pentest → `🔴⚔️ Red Team/Pentesting/`, en **carpetas numeradas por fase / orden lógico del pentest** (`000 - Fases del Pentesting`, `001 - Footprinting`, `002 - Evaluación de vulnerabilidades`, …). Los números de módulos aún no extraídos son **tentativos** — se confirman al llegar.
- **Herramientas** (Nmap, Metasploit, John the Ripper, Hashcat, …) → `02 - Recursos/🛠️ Tools/` como cualquier herramienta, **NO** bajo Pentesting. Su MOC es un `.base` Level 2 propio en la carpeta de la herramienta (patrón `SQLMap.base`).
- Footprinting es **autocontenido** (1 nota ofensiva por servicio en `001 - Footprinting/`) y **cross-linkea** a la nota de **fundamentos del protocolo** (Redes = "cómo funciona"; Footprinting = "cómo enumerar/atacar"). **Cada protocolo de red tiene su nota de fundamentos en `Redes/Protocolos/`** (indexadas por `Protocolos de red.base`; creadas/rellenadas al hacer Footprinting: FTP, SMB, NFS, DNS, SMTP, IMAP-POP3, SNMP, IPMI, SSH, Rsync, R-services, RDP, WinRM, WMI). Los **motores de BBDD** (MySQL, MSSQL, Oracle) van a `Ingenieria/Bases de Datos/` (no a Redes), indexados por `Bases de Datos.base`.

| #  | Módulo HTB | Carpeta destino | Estado |
| -- | ---------- | --------------- | ------ |
| 1  | Penetration Testing Process | `Pentesting/000 - Fases del Pentesting/` (enriquece las notas de fases existentes) | Legacy parcial |
| 2  | Getting Started | *(se salta / cherry-pick — primer generalista, contenido cubierto en otros módulos)* | — |
| 3  | Network Enumeration with Nmap | `02 - Recursos/🛠️ Tools/Nmap/` (herramienta → Tools; 10 notas 00-09 + `Nmap.base`) | ✅ Completado (2026-07-18) |
| 4  | Footprinting | `Pentesting/001 - Footprinting/` (19 notas 00-18 + `Footprinting.base`; fundamentos de protocolo en `Redes/Protocolos/` [11 notas + `Protocolos de red.base`] y BBDD en `Ingenieria/Bases de Datos/` [MSSQL, Oracle]) | ✅ Completado (2026-07-18) |
| 5  | Information Gathering – Web Edition | `Hacking web/Reconocimiento Web/` | ✅ Contenido web |
| 6  | Vulnerability Assessment | `Pentesting/002 - Evaluación de vulnerabilidades/` (7 notas 00-06 + `.base`; **Nessus** [4 notas] y **OpenVAS** [2 notas] → `02 - Recursos/🛠️ Tools/`, como Nmap) | ✅ Completado (2026-07-18) |
| 7  | File Transfers | `Pentesting/003 - Transferencia de archivos/` (12 notas 00-11 + `.base`; misc/protegidas/catching/LotL + detección/evasión + arsenal) | ✅ Completado (2026-07-19) |
| 8  | Shells & Payloads | `Pentesting/004 - Shells y Payloads/` (13 notas 00-12 + `.base`; incl. detección/evasión + arsenal) | ✅ Completado (2026-07-18) |
| 9  | Using the Metasploit Framework | `02 - Recursos/🛠️ Tools/Metasploit/` (**rehecho desde 0**: 14 notas 00-13 + `Metasploit.base`, patrón Nmap) | ✅ Completado (2026-07-18) |
| 10 | Password Attacks | `Pentesting/005 - Ataques a contraseñas/` (19 notas 00-18 + `.base`; **John the Ripper** y **Hashcat** → `Tools/` con `.base` propio) | ✅ Completado (2026-07-18) |
| 11 | Attacking Common Services | `Pentesting/006 - Ataque a servicios comunes/` *(tentativo)* | Pendiente |
| 12 | Pivoting, Tunneling & Port Forwarding | `Pentesting/007 - Pivoting y túneles/` (16 notas 00-15 + `.base`; **Ligolo-ng** net-new, detección/evasión, arsenal; rpivot plegado en arsenal) | ✅ Completado (2026-07-19) |
| 13 | Active Directory Enumeration & Attacks | `🔴⚔️ Red Team/Active Directory/Enumeración y Ataques/` (**área propia** · 6 sub-temas Level-2 · 27 notas 00-26 · Linux/Windows unificados por técnica; las 5 notas AD de `005` [NTLM-Kerberos/PtH/PtT/Pass the Certificate/NTDS.dit] **cross-linkeadas, no movidas**) | ✅ Completado (2026-07-21) |
| 14 | Using Web Proxies | `Hacking web/Proxies web/` | ✅ Contenido web |
| 15 | Attacking Web Applications with Ffuf | `Hacking web/Reconocimiento Web/` (Fuzzing, metodología) + `02 - Recursos/🛠️ Tools/Ffuf/` (8 notas 00-07 + `Ffuf.base`, referencia de la herramienta) | ✅ Contenido web + tool (2026-07-19) |
| 16 | Login Brute Forcing | `Hacking web/Brute Forcing/` | ✅ Contenido web |
| 17 | SQL Injection Fundamentals | `Hacking web/💉🩸 SQL Injection/` | ✅ Contenido web |
| 18 | SQLMap Essentials | `02 - Recursos/🛠️ Tools/SQLMap/` | ✅ Contenido web |
| 19 | Cross-Site Scripting (XSS) | `Hacking web/XSS/` | ✅ Contenido web |
| 20 | File Inclusion | `Hacking web/File Inclusion/` | ✅ Contenido web |
| 21 | File Upload Attacks | `Hacking web/File Upload/` | ✅ Contenido web |
| 22 | Command Injections | `Hacking web/Command Injection/` | ✅ Contenido web |
| 23 | Web Attacks | `Hacking web/Web Attacks/` | ✅ Contenido web |
| 24 | Attacking Common Applications | `Hacking web/Common Applications/` | ✅ Contenido web |
| 25 | Linux Privilege Escalation | `Pentesting/008 - Escalada de privilegios Linux/` (25 notas 00-24 + `.base`; detección/evasión + arsenal net-new; CVEs 2021-2025 [PwnKit, Baron Samedit, Dirty Pipe, Looney Tunables, GameOver(lay), sudo 2025, nf_tables] y escapes de contenedores [runc, K8s] modernizados) | ✅ Completado (2026-07-22) |
| 26 | Windows Privilege Escalation | `Pentesting/009 - Escalada de privilegios Windows/` (26 notas 00-25 + `.base`; familia Potato [GodPotato/PrintSpoofer], UAC, CLFS/PrintNightmare/SeriousSAM modernizados; detección/evasión + arsenal net-new) | ✅ Completado (2026-07-22) |
| 27 | Documentation & Reporting | `Pentesting/010 - Documentación y reporting/` *(tentativo)* | Pendiente |
| 28 | Attacking Enterprise Networks | `Pentesting/011 - Ataque a redes empresariales/` *(capstone · tentativo)* | Pendiente |

#### CPTS — estándares de calidad extra

Todos los módulos CPTS net-new siguen los **3 ejes del vault** (detección · evasión · arsenal + fuentes + gráficos) — son especialmente críticos aquí porque los módulos de red/infra de HTB llevan años sin actualizarse. Ver la sección **"Estándares de calidad — los 3 ejes"** al principio del documento.

### Módulos extra (fuera de los paths CWES/CWEE)

Extraídos por complementar módulos ya hechos con técnicas/herramientas/escenarios nuevos:

| Módulo HTB | Destino | Estado |
| - | - | - |
| 17 · Hacking WordPress | **Fusionado** en `Common Applications/WordPress/` (2→8 notas granulares: estructura/roles, enumeración, login/brute, plugins, RCE admin, detección/evasión, arsenal, hardening) | Completado ✅ (2026-07-17) |
| 160 · Web Service & API Attacks | `Hacking web/Web Services/` (SOAP/WSDL/SOAPAction/Command Injection/xmlrpc · 7 notas) + `Hacking web/ReDoS/` (net-new · 2 notas). Su grupo "API Attacks" (vulns clásicas vía endpoint API) se **distribuyó como enriquecimientos** a las carpetas canónicas (SQLi, File Upload, File Inclusion, XSS, SSRF, Web Attacks/XXE) | Completado ✅ (2026-07-17) |

Antes de crear una carpeta nueva, **siempre verificar** con `ls` o `Glob` que no existe ya bajo otro nombre — el vault tiene cierta inconsistencia histórica (carpetas con emoji vs sin emoji).

## Convenciones de nota

> **Fuente autoritativa: skill `pkm-note-format`** — frontmatter, glosario de colores con ejemplos, callouts, bloques de código (lenguaje declarado siempre), enlaces, imágenes, voz/estilo y checklist final. Se activa al crear/editar cualquier nota. Aquí queda solo lo esencial (siempre en contexto); el detalle vive en la skill.

### Frontmatter

Bloque YAML inicial, seguido de **dos** líneas `---` (la primera cierra el YAML; la segunda es regla horizontal visible):

```yaml
---
tags:
  - <tag-área>                 # p. ej. Web/Red-Team, Pentesting, Active-Directory, Linux
  - <tag-fase>                 # fase del pentest: Pentesting/Enumeracion, /Explotacion, /Post-Explotacion
  - <tag-tema>                 # p. ej. XSS, SQLi, Fuzzing, Pivoting
Fecha de actualización: 2026-05-11
Nota previa: "[[Nombre nota anterior]]"
Nota siguiente: "[[Nombre nota siguiente]]"
Area: "[[XSS.base|XSS]]"       # ← .base Level 2 del sub-tema, NO Level 1
---
---
```

- `Fecha de actualización`: siempre `YYYY-MM-DD` (ISO 8601), fecha real del día.
- `Nota previa` / `Nota siguiente`: alias entre comillas (`"[[ ]]"`); forman la cadena Zettelkasten. La cabecera del tema tiene `prev` vacío; la cola, `next` vacío. Mantenimiento de la cadena → skill `zettelkasten-linking`.
- `Area`: enlace al `.base` **Level 2** del sub-tema, **nunca** al Level 1 (ver "Vista `.base`" más abajo). Notas legacy apuntando a Level 1 = deuda a migrar.
- `tags`: área + fase + tema. **Reusar** tags existentes antes de inventar (`grep` / `obsidian tags`). El primer tag **no es siempre** `Web/Red-Team` — depende del área de la nota (una nota de red/AD/privesc no es web).

### Marcas con colores (glosario semántico)

Las marcas usan la sintaxis `<mark style="background: COLOR;">texto</mark>`. **Cada color tiene un significado fijo** — no usar al azar:

| Color | Hex | Uso semántico |
| - | - | - |
| Azul claro | `#ADCCFFA6` | Definiciones, conceptos clave, "qué es X". |
| Rosa claro | `#FFB8EBA6` | Matices, detalles importantes, condiciones, probabilidades. |
| Naranja | `#FFB86CA6` | Impacto, criticidad, lo que un atacante consigue/un defensor pierde. |
| Morado | `#8000E1A6` | Reformulaciones / consecuencias destacables, "esto significa que…". |
| Coral-rojo | `#FF5582A6` | Hallazgos accionables durante un pentest, "esto importa para los próximos pasos". También útil para destacar información crítica (errores, resultados) o restricciones muy importantes. |
| Gris claro | `#CACFD9A6` | Apenas usado — información de baja prioridad. Evitar salvo necesidad real. |

Una nota saturada de marcas pierde el sistema. Marcar **lo importante**, no todo.

### Callouts, código, enlaces, imágenes y tablas

Detalle completo en la skill `pkm-note-format`. Recordatorios siempre-on:

- **Callouts** de Obsidian (`> [!important]+`, `> [!warning]+`, `> [!success]+`, `> [!info]+`, `> [!fail]+`) para matices/avisos. Las palabras dentro de callouts **no cuentan** para las 1000–1500 de teoría.
- **Bloques de código**: siempre con lenguaje declarado (` ```shell-session `, ` ```http `, ` ```sql `, ` ```python `, …).
- **Enlaces** `[[ ]]` a notas reales o fantasmas intencionales (sirven de TODO).
- **Imágenes**: HTB por URL pública (`academy.hackthebox.com/storage/...`); capturas propias en `03 - Archivos/Images/<contexto>/`. Solo si aportan valor.
- **Tablas** para comparativas, ≤8 filas.

> [!warning]+ Excepción Nuevo-Formato
> En `🔴⚔️ Red Team/Hacking web/💉🩸 SQL Injection/Nuevo-Formato/` **no** se usan marks de color: usar `"==highlight=="` y `"**bold**"`". Resto de convenciones igual. (Detalle en `pkm-note-format`.)

## Flujo de extracción HTB → nota

> **Fuente autoritativa: skill `htb-extraction-workflow`** — Fase 0-3 detalladas, reglas de transformación, criterios de relleno/enriquecimiento y anti-patrones. Para conducir el navegador (tu Chrome logueado), la skill `claude-in-chrome` + `fetch` a la API interna de HTB (ver callout). El usuario inicia sesión en HTB Academy; la extracción se ejecuta en **Fase 0 (planificación) + 3 fases iterativas**, sin avanzar sin cerrar la actual. Resumen:
>
> - **Fase 0 — Planificar** (1 vez/módulo): identificar módulo + carpeta destino (mapeo de arriba), listar capítulos, presentar **plan de fragmentación** (1:1 / M:1 / 1:N, cadena `prev`/`next`, carpetas, `.base` Level 2, tags) y **esperar confirmación** salvo módulos cortos (<8 secc).
> - **Fase 1 — Extraer** capítulo a capítulo en **corte vertical** (una nota entera antes de la siguiente): traducir al español (términos técnicos en `backticks`), eliminar relleno HTB, enriquecer con contexto profesional (WAF, rate-limiting, CVEs, herramientas actuales), aplicar formato PKM, encadenar Zettelkasten.
> - **Fase 2 — Sellar cada nota**: `[[wikilinks]]` internos + pulir redacción antes de avanzar.
> - **Fase 3 — Cierre de módulo (NUNCA se omite)**: revisión cruzada con TODO el PKM, integrar enlaces cross-módulo, actualizar MOCs `.base` Level 1/2, reportar (sin `git commit`).

> [!important]+ Atajo de extracción vía API (mucho más rápido que snapshots del navegador)
> Con Chrome logueado en HTB Academy, en vez de leer el DOM sección a sección se puede pedir el contenido directamente a la API interna con un `fetch` desde la pestaña (JS en el navegador, usa las cookies de sesión). Descubierto y validado el 2026-07-18 con el trío de red:
> - **Lista de secciones**: `GET /api/v3/modules/<módulo>/sections` → JSON `{data:[{group, sections:[{id, title, page, type}]}]}`. Da los **IDs reales** (no son contiguos ni siguen el orden de visualización — no los adivines).
> - **Contenido de una sección**: `GET /api/v2/modules/<módulo>/sections/<id>?language=en` → campo `.data.content` con el **markdown completo** (encabezados, bloques de código, tablas y URLs de imágenes intactos).
> - *Gotcha*: el filtro de seguridad de la herramienta puede **bloquear** trozos con material tipo credencial/clave. Si pasa, saca solo los encabezados (`content.split('\n').filter(l=>/^#/.test(l))`) para el esquema y redacta desde el conocimiento experto + el outline.

*(Fases 0–3 paso a paso, reglas de transformación, criterios de relleno a eliminar y de contexto propio a añadir, herramientas del vault y anti-patrones → skill `htb-extraction-workflow`.)*

## Vista `.base` (MOCs de Obsidian) — jerarquía de 2 niveles

Las MOC del vault usan el formato nativo de Obsidian Bases (`.base`) y se organizan en **dos niveles**:

### Level 1 — Índice de tema grande

- **Ubicación**: raíz de una carpeta temática mayor (ej. `🔴⚔️ Red Team/Hacking web/Web Pentesting.base`).
- **Función**: índice de los `.base` **Level 2 hijos**, no de notas individuales. Equivalente a una tabla de contenidos del tema mayor — lista sub-temas (XSS, SQL Injection, Fuzzing, ...) cada uno representado por su Level 2.
- Las notas **no apuntan aquí** con `Area`.

Filtro estándar Level 1 (lista los `.base` Level 2 bajo la carpeta del tema):

```yaml
views:
  - type: table
    name: Sub-temas
    filters:
      and:
        - file.ext == "base"
        - file.folder.startsWith("🔴⚔️ Red Team/Hacking web")
        - file.name != "Web Pentesting"   # excluir el propio Level 1
    sort:
      - property: file.name
        direction: ASC
```

### Level 2 — Índice de sub-tema concreto

- **Ubicación**: dentro de la sub-carpeta del sub-tema (ej. `🔴⚔️ Red Team/Hacking web/XSS/XSS.base`).
- **Función**: índice de las notas atómicas del sub-tema. A este `.base` apuntan las notas vía su propiedad `Area`.
- **Filtro estándar**: `Area == link("<este .base>.base", "<alias>")`. Desacopla el listado de la ubicación física de la nota — robusto ante reorganizaciones.

Ejemplo (XSS.base):

```yaml
views:
  - type: table
    name: Notas del sub-tema
    filters:
      Area == link("XSS.base", "XSS")
    order:
      - file.name
      - file.tags
    sort:
      - property: file.name
        direction: ASC
```

### Reglas operativas

- Cuando una nota nueva entra en un sub-tema, su `Area` apunta al **Level 2** del sub-tema. Si el Level 2 no existe todavía, **crearlo primero** (en Fase 0 del módulo HTB que se vaya a extraer, o como acción previa a la nota suelta).
- **No crear `.base` Level 2 prematuros** (vacíos, sin notas inminentes). Crearlos justo antes de necesitarlos.
- Cuando aparece un Level 2 nuevo bajo una carpeta de tema grande, verificar que el filtro del Level 1 lo recoge (puede requerir actualizar la cláusula `file.folder.startsWith(...)`).
- Notas legacy con `Area` apuntando al Level 1 (p. ej. `Web Pentesting.base`) son **deuda a migrar**. Al crear el Level 2 correspondiente, migrar `Area` de **todas** las notas del sub-tema en lote (`obsidian property:set` o `Edit` directo del frontmatter).

## Decisiones estructurales (ADR)

Las decisiones estructurales del vault que se **ejecutan** (reorganizaciones, nuevas convenciones, fusiones/divisiones de temas, renombrados masivos) se registran como **ADR** (*Architecture Decision Record*) para no perder el **porqué** ni las **alternativas descartadas** —lo que la memoria y este archivo capturan peor—.

- Lo automatiza la skill **`pkm-design-grilling`** como paso final del interrogatorio (idea tomada de `grill-with-docs` de aihero.dev).
- **Ubicación**: `02 - Recursos/Decisiones estructurales/NNN - <título>.md`. Son **notas meta**: exentas de la cadena Zettelkasten y de `Area`.
- **Formato**: contexto → decisión → alternativas descartadas → consecuencias. Escueto (media pantalla) y solo cuando hubo alternativas reales que descartar; si no, basta memoria/CLAUDE.md.

## Plantilla base

Plantilla vacía en `02 - Recursos/Templates/Template para proyectos.md` (Templater). Para crear una nota a mano, usar el esqueleto de frontmatter de "Convenciones de nota" (arriba); el formato completo lo posee la skill `pkm-note-format`.

## Plugins, skills y MCP disponibles

### Skills locales del proyecto (en `.claude/skills/`)

Estas se activan automáticamente cuando la descripción coincide con la tarea. **Son las que codifican el workflow del PKM**:

- `htb-extraction-workflow` — Playbook completo para extraer un módulo de HTB Academy con Playwright MCP: precondiciones, plan de fragmentación, transformaciones obligatorias, corte vertical (nota completa antes de pasar a la siguiente), MOC, reporte. Se activa al mencionar "extraer módulo X", "vamos con X de HTB", etc.
- `pkm-note-format` — Referencia del formato exacto: frontmatter, glosario de colores hex con ejemplos, callouts, bloques de código con lenguaje, imágenes, voz/estilo, checklist final. Se activa al crear/editar cualquier nota del vault.
- `zettelkasten-linking` — Procedimientos de mantenimiento de la cadena `Nota previa`/`Nota siguiente` para las 6 operaciones (crear al final, insertar, borrar, renombrar, dividir, fusionar). Evita romper enlaces silenciosamente.
- `pkm-design-grilling` — Interrogatorio dirigido antes de cualquier decisión estructural del PKM (reorganizar carpetas, crear MOCs, fusionar temas, renombrados masivos). 8–20 preguntas categorizadas por motivación, alcance, convenciones, reversibilidad y modelo mental antes de proponer plan. Adaptación PKM de `/grill-me` de aihero.dev. Ahora también **registra la decisión ejecutada como ADR** en `02 - Recursos/Decisiones estructurales/` (idea de `grill-with-docs`).
- `pkm-structure-audit` — Auditoría de salud del vault: wikilinks rotos, cadenas Zettelkasten rotas, densidad de notas fuera de rango, taxonomía de tags duplicada, MOCs `.base` obsoletas, frontmatter inconsistente. Produce informe priorizado sin tocar archivos. Adaptación PKM de `/improve-codebase-architecture` de aihero.dev.
- `pkm-research` — Investigación con **fuentes primarias/oficiales** y cita por-fuente; materializa el eje 1/eje 4. La usa `htb-extraction-workflow` en el enriquecimiento (Fase 1.2) y es invocable a demanda para pentest/bug bounty. Adaptación PKM de `/research` de aihero.dev.

### Plugins ya instalados a nivel usuario (`~/.claude/settings.json`)

- `playwright@claude-plugins-official` — MCP de navegador. **Alternativa** de extracción; el método principal hoy es `claude-in-chrome` sobre el Chrome logueado + `fetch` a la API interna de HTB (markdown limpio — ver "Flujo de extracción").
- `superpowers@claude-plugins-official` — skills generales de desarrollo, brainstorming, debugging.
- `claude-md-management@claude-plugins-official` — gestión de este propio archivo.
- `context7@claude-plugins-official` — documentación de librerías y frameworks.
- `chrome-devtools-mcp@claude-plugins-official` — debugging de páginas web.
- `feature-dev`, `code-review`, `code-simplifier`, `commit-commands`, `mongodb`, `security-guidance`, `frontend-design`, `typescript-lsp` (todos `@claude-plugins-official`).

### Plugins instalados de Trail of Bits (`trailofbits` marketplace)

Marketplace clonado en `~/.claude/plugins/marketplaces/trailofbits/`. Plugins habilitados, relevantes para web pentesting / white-box / bug bounty:

- `ask-questions-if-underspecified` — Clarifica requisitos ambiguos antes de implementar. Útil para planificar la fragmentación de módulos HTB.
- `audit-context-building` — Análisis ultra-granular para construir contexto arquitectónico antes de cazar vulnerabilidades. **Clave para módulos white-box de CWEE**.
- `burpsuite-project-parser` — Extracción de datos de archivos `.burp`. Requiere Burp Suite Pro + extensión `burpsuite-project-file-parser` para uso completo. Útil cuando documentemos hallazgos reales.
- `differential-review` — Revisión de cambios de código con análisis de blast radius y git history. Útil para analizar parches de CVEs.
- ~~`fp-check`~~ — *Deshabilitado* (2026-05-13): su Stop hook con `matcher: "*"` se ejecutaba en cada cierre de turno y producía ruido visible. Para reactivarlo cuando se necesite (verificación de hallazgos de bug bounty, análisis de FPs), cambiar `"fp-check@trailofbits": false` → `true` en `~/.claude/settings.json` y ejecutar `/reload-plugins`.
- `insecure-defaults` — Detecta credenciales hardcodeadas, autenticación débil, configuraciones fail-open.
- `semgrep-rule-creator` — Desarrolla reglas Semgrep personalizadas. Útil para módulos white-box.
- `sharp-edges` — Identifica APIs propensas a error, configuraciones peligrosas y *footguns* de diseño.
- `static-analysis` — Toolkit con CodeQL + Semgrep + SARIF parsing. Requiere CodeQL/Semgrep instalados para ejecución completa. **Clave para white-box de CWEE**.
- `testing-handbook-skills` — Metodologías del Trail of Bits Testing Handbook (fuzzers, static analysis, sanitizers, coverage).
- `variant-analysis` — Encuentra vulnerabilidades similares en bases de código mediante pattern matching. Útil para escalar un hallazgo.
- ~~`second-opinion`~~ — *Desactivado*: requiere OpenAI Codex CLI o Google Gemini CLI instalado. Si en el futuro instalas alguno de los dos, se puede reactivar añadiendo `"second-opinion@trailofbits": true` a `~/.claude/settings.json`.

### Plugin bundle `example-skills` de Anthropic

Marketplace `anthropic-agent-skills` ya configurado. Habilitado `example-skills@anthropic-agent-skills` que incluye:

- **`doc-coauthoring`** — Workflow estructurado para co-autoría de docs (Context Gathering → Refinement → Reader Testing). **Útil para notas largas o complejas**.
- `skill-creator` — Para crear más skills si surgen necesidades nuevas.
- `mcp-builder` — Para construir MCP servers personalizados.
- `webapp-testing` — Pruebas de aplicaciones web.
- Otras skills decorativas (algorithmic-art, slack-gif-creator, theme-factory) que se ignoran salvo que se invoquen.

### Marketplaces a nivel usuario (`~/.claude/settings.json`)

- `claude-plugins-official` (anthropics/claude-plugins-official)
- `anthropic-agent-skills` (anthropics/skills)
- `trailofbits` (trailofbits/skills)

### Obsidian CLI oficial — herramienta principal de manipulación del vault

Obsidian 1.12.4+ (febrero 2026) incluye una **CLI oficial** que se instala automáticamente con la app de escritorio. El binario `obsidian` está en `PATH` (`C:\Users\Samuel\AppData\Local\Programs\Obsidian\Obsidian.exe`) y se invoca **vía Bash** sin necesidad de MCP intermedio.

**Por qué CLI > cualquier MCP de Obsidian**: es oficial, mantenida por el equipo de Obsidian, cubre 80+ comandos (más que cualquier MCP de terceros), no requiere API key ni proceso adicional, y Claude la invoca como cualquier otro comando shell.

**Requisito de uso**: Obsidian debe estar **abierto** en el vault del PKM. La CLI actúa como cliente del proceso de Obsidian — si la app está cerrada, los comandos fallan.

**Comandos esenciales** (lista completa con `obsidian help`):

```shell-session
# Archivos y contenido
$ obsidian files                              # listar todos los archivos
$ obsidian read file="XSS Almacenado"         # leer una nota
$ obsidian create path="XSS/Avanzado.md" content="..."
$ obsidian append file="..." content="..."
$ obsidian move file="..." path="nuevo/path.md"
$ obsidian delete file="..."

# Frontmatter (properties)
$ obsidian property:set file="X" name="Nota siguiente" value="[[Y]]"
$ obsidian property:read file="X" name="tags"
$ obsidian properties                         # inventario de properties del vault

# Links y estructura
$ obsidian backlinks file="X" format=json    # backlinks de una nota
$ obsidian links file="X"                     # links salientes
$ obsidian orphans                            # notas sin enlaces entrantes
$ obsidian deadends                           # notas sin enlaces salientes

# Bases (MOCs)
$ obsidian bases                              # listar archivos .base
$ obsidian base:query file="Web Pentesting.base" view="Tabla"

# Plugins
$ obsidian plugins                            # listados instalados
$ obsidian plugins:enabled                    # solo los activos
$ obsidian plugin:install <plugin-id>         # instalar uno del catálogo
$ obsidian plugin:enable <plugin-id>
$ obsidian plugin:disable <plugin-id>

# Search
$ obsidian search "XSS reflected"
$ obsidian search:context "payload" 

# Templates
$ obsidian templates
$ obsidian template:insert file="X" name="Template para proyectos"

# Tags
$ obsidian tags
$ obsidian tag name="Pentesting/Enumeracion"

# Command palette directo (puerta de escape)
$ obsidian commands                           # listar comandos disponibles
$ obsidian command id="<command-id>"
```

**Skills oficiales instaladas** (plugin `obsidian@obsidian-skills`, autor Steph Ango — fundador de Obsidian). Cárgalas todas siempre antes de empezar a crear notas y a investigar. Es siempre lo primero de todo que debes hacer. Skills Obsidian:

- `obsidian-cli` — Cómo usar la CLI correctamente, patrones idiomáticos, escapes seguros.
- `obsidian-markdown` — Crear/editar markdown con sintaxis Obsidian (wikilinks, callouts, embeds).
- `obsidian-bases` — Crear y manipular archivos `.base` (las MOCs del vault).
- `json-canvas` — Trabajar con archivos `.canvas` (vistas canvas de Obsidian).
- `defuddle` — Extracción de contenido web limpio (artículos → notas).

### Skills/plugins de terceros NO instalados (con razón)

- **Skills de Zettelkasten/PKM de marketplaces no oficiales** (mcpmarket.com, skillsllm.com): Snyk encontró *prompt injection* en el 36% de skills auditadas en estos marketplaces. Las skills locales del proyecto (`htb-extraction-workflow`, `pkm-note-format`, `zettelkasten-linking`) cubren la funcionalidad sin importar código de terceros.
- **Plugins HTB-machine-pwning** (`allsmog/blackbox-claude-plugin`, etc.): orientados a explotar máquinas HTB Labs, no a crear notas. Fuera de alcance.

## Operativa con Git

- El vault es un repositorio git con su origen en `Obsidian Git` (plugin de Obsidian). Los commits con mensaje `Fecha: DD/MM/YYYY` los hace el plugin automáticamente al cerrar Obsidian.
- **Claude no hace commits a menos que el usuario lo pida explícitamente.** Cuando lo pida, seguir las reglas de la sección "Committing changes with git" del system prompt (mensajes en español si se acompaña al estilo del repo; firmar con `Co-Authored-By` solo si el usuario lo pide).
- No tocar `.obsidian/` salvo que se solicite cambiar configuración. Los cambios de ese directorio que aparezcan modificados (`M .obsidian/...`) en `git status` son actualizaciones de plugins gestionadas por Obsidian.

## Consideraciones de uso del contenido HTB

- HTB Academy **permite** usar su contenido para apuntes personales/educativos. **Prohíbe** la comercialización o redistribución como producto. Este PKM es de uso estrictamente personal.
- Las imágenes se referencian por URL pública (`academy.hackthebox.com/storage/...`) — eso preserva la atribución implícita.
- Si el contenido se va a publicar fuera del vault (blog, charla), revisar con HTB.

## Reglas operativas para mí (Claude)

- **Idioma de las notas**: español. **Idioma de mensajes al usuario**: español por defecto (es nativo del usuario).
- Antes de crear una carpeta nueva, comprobar con `Glob`/`ls` que no existe ya bajo otro nombre.
- Antes de crear un tag nuevo, hacer `grep` en el vault por el tag deseado o variantes.
- Antes de enlazar a una nota, comprobar que el nombre exacto coincide (los wikilinks rotos en Obsidian son silenciosos).
- Cuando extraiga un módulo HTB completo, **resumir al usuario el plan de fragmentación antes de escribir**, salvo en módulos cortos (<8 secciones).
- No tocar `TFG/` salvo petición explícita. Tampoco `🔵🛡️ Blue Team/` salvo que la tarea lo requiera. **`Redes/`**: se puede **leer y enlazar** libremente (Footprinting de CPTS cross-linkea a `Redes/Protocolos/`); modificar sus notas solo si la tarea lo pide.
- Si encuentro inconsistencia en el vault (notas con frontmatter incompleto, enlaces rotos, MOCs desactualizadas), **flaggear al usuario** — no "limpiar" silenciosamente.
- El campo `Fecha de actualización` se rellena con la fecha real del día en formato ISO `YYYY-MM-DD` (obtener del sistema); convertir fechas relativas siempre a absolutas.
- Tras **ejecutar una decisión estructural** (reorg, convención nueva, fusión/división, renombrado masivo), registrar un **ADR** en `02 - Recursos/Decisiones estructurales/` — ver «Decisiones estructurales (ADR)».
