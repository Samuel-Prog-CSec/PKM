---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - IDOR
Fecha de actualización: 2026-07-15
Nota previa: "[[12 - Detección, evasión y prevención de IDOR]]"
Nota siguiente: "[[14 - Introducción a XXE]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

El IDOR es difícil de automatizar del todo (la máquina no sabe qué objeto "debería" verse), así que las herramientas **asisten** el juicio humano: reproducen tráfico con otra identidad y marcan dónde falla el control de acceso. Estas son las que se usan hoy en pentest de autorización y bug bounty.

# Extensiones de Burp (el núcleo)

## Autorize

<mark style="background: #ADCCFFA6;">La herramienta estándar para IDOR/broken access control</mark> (de Barak Tawily). Cargas la cookie/token de un usuario de **bajo privilegio** y navegas como usuario de **alto privilegio**; Autorize reenvía cada petición con la sesión de bajo privilegio **y** sin sesión, y compara respuestas. Codifica por colores:

- 🟢 `Enforced!` — el control de acceso funciona (respuestas distintas).
- 🔴 `Bypassed!` — <mark style="background: #FF5582A6;">acceso no autorizado: IDOR confirmado</mark>.
- 🟡 `Is enforced??? (please configure)` — revisar a mano.

Setup mínimo, resultados inmediatos. Es el primer filtro para detectar accesos horizontales.

## Auth Analyzer

Similar pero con **múltiples sesiones simultáneas**, ideal para probar escaladas **horizontales y verticales** a la vez. Su ventaja: <mark style="background: #FFB8EBA6;">extrae y reemplaza parámetros automáticamente</mark> (tokens `CSRF`, `uuid`, características de sesión) desde las respuestas, así que mantiene flujos con anti-CSRF o IDs encadenados sin romperse. Navegas con el usuario privilegiado y repite cada petición para cada identidad definida.

## Otras

| Extensión | Uso |
| - | - |
| **AuthMatrix** | Matriz roles × peticiones: pruebas de autorización sistemáticas y repetibles (bueno para informes) |
| **AutoRepeater** | Reemplazo automático de tokens/cookies/parámetros en todo el tráfico; base para tests de authz a medida |
| **Authz** | Reenvía peticiones con la sesión de menor privilegio (alternativa ligera a Autorize) |

# Descubrimiento de referencias y parámetros

Antes de probar acceso, hay que **encontrar** las referencias ocultas:

- <mark style="background: #ADCCFFA6;">**Param Miner**</mark> (Burp): descubre parámetros y cabeceras ocultos por fuerza bruta de diccionario.
- **Arjun**: `arjun -u https://target/api/endpoint` — mina parámetros GET/POST/JSON desde CLI.
- **x8**: fuzzer de parámetros ocultos en Rust, muy rápido para superficies grandes.
- **LinkFinder / xnLinkFinder / getJS**: extraen endpoints y referencias de los ficheros `.js` del front-end.

# Enumeración y explotación

- **ffuf** para barrer IDs: `ffuf -w <(seq 1 5000) -u https://target/api/user/FUZZ -H "Cookie: ..." -mc 200 -ac` y filtrar por diff de tamaño.
- **Burp Intruder** con *Grep – Extract* para tabular datos extraídos por cada ID.
- **Referencias codificadas**: [CyberChef](https://gchq.github.io/CyberChef/) para reconstruir cadenas `base64`/hash; `hashid`/`hash-identifier` para identificar el algoritmo; `hashcat` si hay que romper.
- **Nuclei**: tiene plantillas para `BOLA`/IDOR en patrones conocidos (APIs con `id` en path), útiles en escaneo masivo — pero cobertura limitada por la naturaleza del bug.

> [!tip]+ Flujo recomendado
> 1. **Recon**: Param Miner/Arjun + análisis de `.js` para mapear referencias y endpoints ocultos. 2. **Detección**: Autorize/Auth Analyzer con dos sesiones → localizar accesos `Bypassed!`. 3. **Confirmación manual**: reproducir en Repeater aplicando las [[12 - Detección, evasión y prevención de IDOR|técnicas de evasión]] (cambio de método, wrapping, pollution) si el control resiste. 4. **Explotación**: ffuf/Intruder para enumeración masiva y demostrar impacto. 5. **Reporte**: documentar la cadena completa ([[11 - Encadenamiento de IDOR|leak → privesc → ATO]]).

Con esto cerramos IDOR. El último sub-tema del módulo es [[14 - Introducción a XXE|XXE Injection]], que ataca el motor XML del back-end.

## Referencias

- PortSwigger BApp Store — [Autorize](https://portswigger.net/bappstore/f9bbac8c4acf4aefa4d7dc92a991af2f)
- YesWeHack — [Test privilege escalation with Auth Analyzer](https://www.yeswehack.com/learn-bug-bounty/pimpmyburp-auth-analyzer-test-horizontal-vertical-privileges-escalation)
- Black Hat Ethical Hacking — [Maximizing IDOR Detection with Burp Suite's Autorize](https://www.blackhatethicalhacking.com/articles/maximizing-idor-detection-with-burp-suites-autorize/)
- [Arjun](https://github.com/s0md3v/Arjun) · [x8](https://github.com/Sh1Yo/x8) · [Param Miner](https://github.com/PortSwigger/param-miner)
