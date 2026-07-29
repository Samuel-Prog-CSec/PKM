---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Command-Injection
  - Tipo/Arsenal
Descripción: "El módulo enseña a entender la command injection a bajo nivel —imprescindible para reconocerla y exprimirla—"
Fecha de actualización: 2026-06-13
Nota previa: "[[09 - Prevención de Command Injection]]"
Nota siguiente: "[[11 - Argument injection]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

El módulo enseña a entender la command injection a bajo nivel —imprescindible para reconocerla y exprimirla—. Esta nota es el complemento operativo: el set de herramientas que se usa hoy en un engagement real para ir rápido sin perder rigor, organizado por las cuatro fases del trabajo: **detección, evasión, explotación y registro**. No sustituye al criterio manual; lo acelera.

# 1. Mapeo y detección

Antes de inyectar nada, mapear la superficie y localizar parámetros candidatos (los que alimentan `ping`, conversores, lookups…).

| Herramienta | Rol |
| - | - |
| **Burp Suite Pro** / **Caido** | Proxy, `Repeater`, `Intruder`. El núcleo del trabajo manual; [[02 - Interceptación de peticiones\|interceptar y replay]] |
| **ffuf** | Fuzzing de parámetros y valores; el más rápido para barridos |
| **nuclei** | Plantillas de command injection para escaneo masivo en bug bounty |
| **interactsh** / **Burp Collaborator** | Canal OOB para confirmar [[01 - Detección de Command Injection\|inyección ciega]] |
| **SecLists** / **PayloadsAllTheThings** | Wordlists y payloads por SO y por filtro |

Para **blind**, el patrón más eficaz es fuzzear con un payload de retardo y ordenar por tiempo de respuesta:

```shell-session
$ ffuf -u "https://target.htb/ping?ip=127.0.0.1FUZZ" -w /usr/share/seclists/Fuzzing/command-injection-commix.txt -mt ">5000"
```

Y para barridos en bug bounty, `nuclei` con sus plantillas de inyección detecta candidatos a escala (no explota — confirma a mano después):

```shell-session
$ nuclei -u https://target.htb -tags cmdi,injection
```

# 2. Explotación automatizada: commix

<mark style="background: #ADCCFFA6;">`commix` (COMMand Injection eXploiter) es la herramienta de referencia</mark>, lo que `sqlmap` es a la SQLi. <mark style="background: #FFB86CA6;">Automatiza la detección y la explotación</mark>: prueba operadores, confirma la inyección (incluida la ciega por tiempo) y abre un pseudo-terminal sobre el objetivo. HTB apenas lo nombra; en bug bounty es de lo primero que sacas tras confirmar el vector a mano.

```shell-session
$ commix --url="https://target.htb/ping.php" --data="ip=127.0.0.1"
```

Banderas que de verdad se usan:

| Flag | Uso |
| - | - |
| `--data="..."` | Inyección en cuerpo POST |
| `--cookie=`, `--headers=` | Inyección en cookies/cabeceras |
| `--level=3` | Sube el alcance a cabeceras (`User-Agent`, `Referer`) |
| `--technique=` | `c`lassic, `e`val, `t`ime-based, `f`ile-based, `r` tempfile |
| `--os-cmd="whoami"` | Ejecuta un comando puntual sin shell interactiva |
| `--tamper=` | Encadena ofuscadores para [[03 - Identificación de filtros y defensas\|evadir filtros/WAF]] |

> [!important]+ Mismo principio que SQLMap: a mano primero
> <mark style="background: #FF5582A6;">Detecta y confirma el contexto manualmente; lanza `commix` afinado al punto exacto</mark>. Igual que con [[01 - Detección de SQL Injection|SQLMap en SQLi]], la herramienta automática falla en contextos raros (JSON anidado, doble encoding, segundo orden) y genera mucho ruido. Un `commix` a ciegas contra todo dispara WAFs y *rate limits* y quema el objetivo.

# 3. Evasión

Cuando hay filtro o WAF, las técnicas manuales de las notas [[04 - Bypass de filtros de espacios|04]]–[[07 - Ofuscación avanzada de comandos|07]] se automatizan:

- **`commix --tamper`**: módulos como `space2ifs`, `space2tab`, `space2htab`, `dollarat`, `uninitializedvariable` — el análogo a los *tamper scripts* de sqlmap. Encadenables.
- **Bashfuscator** / **Invoke-Obfuscation**: generadores de payload ofuscado ([[08 - Herramientas de evasión y ofuscación|nota 08]]).
- **wafw00f**: identifica el WAF para elegir el repertorio de bypass correcto.

> [!info]+ Estado de mantenimiento (2026)
> Al contrario que el arsenal de [[11 - Arsenal de herramientas para File Inclusion|File Inclusion]] (lleno de herramientas muertas), aquí el set está mayormente vivo: <mark style="background: #ADCCFFA6;">`commix` sigue activo</mark> (commits en 2026) y todo el stack de ProjectDiscovery (`ffuf`, `nuclei`, `interactsh`) es de lo más mantenido del ecosistema. Los dos rezagados son de ofuscación: `Bashfuscator` e `Invoke-Obfuscation`/`Invoke-DOSfuscation` (Daniel Bohannon) llevan años sin commits, pero la técnica sigue siendo válida y no hay reemplazo directo — úsalos sabiendo que son estáticos.

```shell-session
$ commix --url="https://target.htb/ping.php" --data="ip=127.0.0.1" --tamper=space2ifs,uninitializedvariable
```

# 4. Reverse shells y post-explotación

Confirmada la RCE, el objetivo suele ser una shell estable:

- **revshells.com**: generador interactivo de reverse shells (bash, nc, Python, PowerShell, `msfvenom`) con el formato listo para pegar.
- **`commix`**: trae opción de pseudo-shell y de reverse shell directa.
- **Metasploit**: módulos específicos cuando la inyección corresponde a una CVE de un producto conocido (`unix/webapp/...`).
- Tras la shell: estabilizar (`python3 -c 'import pty; pty.spawn("/bin/bash")'`), enumerar y escalar — fuera del alcance de esta nota.

# 5. Registro, evidencia y reporting

El paso que más se descuida y el que cobra el bounty: <mark style="background: #8000E1A6;">una PoC reproducible vale más que el hallazgo</mark>.

- **Historial de Burp / Caido**: guarda la petición y respuesta exactas. El proyecto `.burp` es la fuente de verdad del engagement; se puede explorar luego con un parser de proyectos Burp.
- **interactsh**: sus logs DNS/HTTP son la **evidencia limpia** de una inyección ciega para adjuntar al informe.
- **PwnDoc** / **Faraday** / **Dradis**: plataformas de reporting que centralizan hallazgos en un pentest formal.
- Para bug bounty: documenta el **payload exacto**, la **URL/parámetro**, el **timestamp** y la respuesta. Un vídeo o secuencia de capturas reproduciendo el RCE acelera el triaje.

> [!warning]+ OPSEC y rate limiting en bug bounty
> Las herramientas automáticas son ruidosas. En un programa con WAF, `commix --level=3` a saco puede ganarte un baneo de IP y cerrar el objetivo. Empieza suave, respeta el *scope* y el *rate limit* del programa, y recuerda que [[07 - Ofuscación avanzada de comandos|el payload que evade el WAF puede encender el EDR]]. Pesa siempre detección frente a beneficio.

# Flujo de referencia

```text
Mapear parámetros (Burp/Caido)
      → Fuzz de candidatos (ffuf + SecLists) · barrido (nuclei)
      → Confirmar a mano + OOB (interactsh) para ciegos
      → Explotar (commix afinado / Repeater manual)
      → ¿WAF? evasión (tampers / Bashfuscator)
      → Reverse shell (revshells.com)
      → Registrar (historial Burp/Caido + logs interactsh → informe)
```

> [!info]+ Fuentes y repos
> - [commix](https://github.com/commixproject/commix) · [wiki de commix](https://github.com/commixproject/commix/wiki)
> - [ffuf](https://github.com/ffuf/ffuf) · [nuclei](https://github.com/projectdiscovery/nuclei) · [interactsh](https://github.com/projectdiscovery/interactsh)
> - [SecLists](https://github.com/danielmiessler/SecLists) · [PayloadsAllTheThings — Command Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Command%20Injection)
> - [revshells.com](https://www.revshells.com/) · [wafw00f](https://github.com/EnableSecurity/wafw00f)

Con esto se cierra el sub-tema de Command Injection: desde [[00 - Introducción a Command Injection|qué es]] y cómo [[01 - Detección de Command Injection|detectarla]], pasando por [[02 - Operadores de inyección de comandos|operadores]] y todo el bloque de [[03 - Identificación de filtros y defensas|evasión de filtros]], hasta la [[09 - Prevención de Command Injection|prevención]] y este arsenal operativo.

Un último vector, avanzado y moderno, cierra el sub-tema: la [[11 - Argument injection|argument injection]], que esquiva incluso la ejecución sin shell que la prevención da por segura.
