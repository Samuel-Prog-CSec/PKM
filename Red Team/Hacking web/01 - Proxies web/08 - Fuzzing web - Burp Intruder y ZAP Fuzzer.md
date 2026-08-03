---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "Más allá del proxy, Burp y ZAP traen fuzzers integrados"
Fecha de actualización: 2026-06-23
Nota previa: "[[07 - Proxying de herramientas]]"
Nota siguiente: "[[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Más allá del proxy, Burp y ZAP traen **fuzzers** integrados. <mark style="background: #ADCCFFA6;">Un web fuzzer itera una wordlist sobre una posición de la petición</mark> — directorios, parámetros, valores, credenciales. Son el equivalente gráfico de [[15 - Introducción al web fuzzing|`ffuf`/`gobuster`]], con la ventaja de operar sobre la petición exacta que ya tienes capturada (cookies, cabeceras, cuerpo).

# Burp Intruder

Localiza la petición en el historial, clic derecho → `Send to Intruder` (`CTRL+I`). Tiene cuatro pasos.

**Positions** — marcas dónde va el payload con `§`. Para fuzzear directorios, envuelves la parte a iterar: `GET /§DIRECTORY§/`.

![Burp Intruder, pestaña Positions: petición GET con la posición de payload marcada con § y el selector de attack type.](https://academy.hackthebox.com/storage/modules/110/burp_intruder_position.png)

El **attack type** define cómo se combinan posiciones y payloads — el mismo concepto que en [[03 - Medusa y alternativas modernas|ffuf]]:

| Tipo | Qué hace |
| - | - |
| `Sniper` | Un set, una posición a la vez (fuzzing de un parámetro) |
| `Battering Ram` | Mismo payload en **todas** las posiciones a la vez |
| `Pitchfork` | Varios sets **alineados** por línea (user[i] + pass[i]) |
| `Cluster Bomb` | **Todas** las combinaciones (user × pass) |

**Payloads** — eliges el tipo (`Simple List`, `Runtime file` para wordlists enormes sin agotar memoria, `Character Substitution`...) y cargas la wordlist (`Load` → p. ej. SecLists `common.txt`).

**Payload processing y encoding** — reglas sobre cada palabra: saltar las que casen un regex (`Skip if matches ^\..*$` ignora las que empiezan por `.`), añadir extensión, y URL-encodear.

En **Settings**, `Grep - Match` marca las respuestas que contienen una cadena (p. ej. `200 OK`) para localizar el acierto entre el ruido. `Start Attack`, ordenas por estado/longitud, y el hit aparece:

![Resultados de Intruder: el payload "admin" devuelve 200 OK (longitud 244), el resto 404 — directorio /admin/ descubierto.](https://academy.hackthebox.com/storage/modules/110/burp_intruder_attack.png)

> [!warning]+ El throttling de la Community lo cambia todo
> <mark style="background: #FF5582A6;">Burp Intruder **gratis está limitado a ~1 petición/segundo**</mark>; un `ffuf` hace 10.000/s. Para wordlists grandes, el Intruder Community es inusable — usa la CLI ([[16 - Herramientas de fuzzing|ffuf]]) o Burp Pro (sin límite). El Intruder gratis se reserva para ataques **cortos y precisos** donde el control sobre la petición compensa la lentitud: forzar un login con pocas contraseñas, [[02 - Fuerza bruta de contraseñas en el login|password spraying]] contra OWA/Citrix/VPN, fuzzear un parámetro concreto.

# ZAP Fuzzer

La gran ventaja de ZAP: <mark style="background: #FFB86CA6;">su fuzzer **no tiene throttling**</mark>, así que de gratis a gratis supera al Intruder Community. Clic derecho sobre la petición → `Attack > Fuzz`. Conceptos paralelos:

- **Fuzz Location**: como las *positions*, seleccionas la palabra y `Add` (marca verde).
- **Payloads**: `File` (tu wordlist), `File Fuzzers` (wordlists integradas, p. ej. `dirbuster`), `Numberzz` (secuencias). No necesitas traer wordlist propia.
- **Processors**: transforma cada payload — Base64, MD5/SHA, URL encode, prefix/postfix, o un `Script` propio.
- **Options**: hilos concurrentes (`20` para ir rápido) y estrategia `Depth first` (todas las pass de un user antes de pasar al siguiente) vs `Breadth first`.

Ordenas por código de respuesta; el `200` con payload `skills` revela `/skills/`. Otros indicadores de acierto: **tamaño** de respuesta distinto (página diferente) o **RTT** alto (clave para [[08 - Extracción de datos time-based|SQLi time-based]]).

> [!important]+ Cuándo proxy-fuzzer y cuándo CLI
> <mark style="background: #8000E1A6;">Regla práctica</mark>: fuzzing **masivo** de contenido/directorios → `ffuf` en CLI (rapidísimo). Fuzzing que necesita la **petición exacta** con su estado (cookies de sesión, CSRF token, cabeceras, flujo multistep) → Intruder/ZAP Fuzzer, porque parten de la petición real capturada. Y si pagas Pro, Intruder une lo mejor de ambos.

> [!info]+ Fuentes
> - [PortSwigger — Burp Intruder](https://portswigger.net/burp/documentation/desktop/tools/intruder) · [attack types](https://portswigger.net/burp/documentation/desktop/tools/intruder/configure-attack/attack-types)
> - [ZAP — Fuzzer](https://www.zaproxy.org/docs/desktop/addons/fuzzer/)
