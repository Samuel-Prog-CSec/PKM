---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
  - Introduccion
Fecha de actualización: 2026-06-23
Nota previa:
Nota siguiente: "[[01 - Tipos de ataque - diccionario, híbrido y máscara]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
---

<mark style="background: #ADCCFFA6;">El `brute forcing` es probar credenciales o claves de forma sistemática hasta dar con la correcta.</mark> Es la última herramienta del cinturón: ruidosa, lenta y dependiente de la fuerza de la contraseña objetivo. Pero cuando el resto de vías falla —no hay vulnerabilidad conocida, el phishing no entra, no hay reutilización de credenciales evidente— sigue siendo el camino que abre la puerta. Esta nota fija el marco conceptual; las siguientes lo ejecutan con `Hydra`, `Medusa` y wordlists.

# Online vs. offline: la distinción que lo cambia todo

HTB mezcla en una sola tabla técnicas que viven en mundos opuestos. La primera pregunta ante cualquier escenario de fuerza bruta es **dónde** se prueba la credencial:

| | `Online` | `Offline` |
| - | - | - |
| Contra qué | Un servicio vivo (login web, SSH, RDP, API) | Un hash que ya has capturado |
| Velocidad | Decenas–miles de intentos/seg, limitada por red y servidor | Miles de millones/seg, limitada solo por hardware y algoritmo |
| Lo frena | Rate limiting, lockout, CAPTCHA, MFA, WAF | La dureza del hash (`bcrypt`/`argon2` vs `MD5`/`NTLM`) |
| Herramientas | `Hydra`, `Medusa`, `ffuf`, `patator` | `hashcat`, `John the Ripper` |
| Ruido | Altísimo: cada intento es una petición logueada | Cero: ocurre en tu máquina |

<mark style="background: #8000E1A6;">Este módulo trata el ataque `online` contra logins web.</mark> Es el más limitado de los dos: contra un único usuario, las defensas modernas (lockout tras N fallos, MFA) hacen que probar millones de contraseñas sea inviable. Por eso el atacante real no fuerza bruta "a lo bestia" un solo usuario, sino que <mark style="background: #FFB8EBA6;">juega con el ángulo: pocas contraseñas contra muchos usuarios (`password spraying`), o credenciales filtradas reutilizadas (`credential stuffing`)</mark>. El crackeo offline de hashes pertenece a post-explotación y se cubre con [[00 - Introducción a Hashcat|hashcat]] aparte.

# Taxonomía de ataques

![Diagrama de flujo del bucle de fuerza bruta: generar combinación, aplicarla, comprobar éxito y repetir hasta lograr acceso.](https://academy.hackthebox.com/storage/modules/57/1n.png)

| Método | En qué consiste | Cuándo usarlo |
| - | - | - |
| `Simple brute force` | Recorre todo el espacio de un charset y longitud dados | No hay info previa y sobran recursos (casi siempre offline) |
| `Dictionary attack` | Prueba una lista precompilada (`rockyou.txt`, SecLists) | Se sospecha una contraseña común o débil — el caso base |
| `Hybrid attack` | Diccionario + mutaciones (sufijos, `leet`, años) | La víctima parte de una palabra común y la "decora" |
| `Mask attack` | Brute force acotado a un patrón conocido (`?u?l?l?l?d?d`) | Conoces la política de contraseñas o el formato |
| `Credential stuffing` | Reutiliza pares `user:pass` filtrados en otros servicios | Tienes un volcado de brechas y sospechas reutilización |
| `Password spraying` | Pocas contraseñas (1–3) contra muchos usuarios | Hay lockout: repartir intentos evita bloquear cuentas |
| `Rainbow table` | Hashes precomputados para revertir rápido (offline) | Hashes sin `salt` y con algoritmo débil |

<mark style="background: #FF5582A6;">`Password spraying` y `credential stuffing` son los que de verdad funcionan hoy en un engagement</mark>: esquivan el lockout por diseño y aprovechan la reutilización masiva de contraseñas. Los detalla [[02 - Fuerza bruta de contraseñas en el login]] del sub-tema de autenticación.

# Por qué (casi nunca) funciona ya la fuerza bruta pura

La viabilidad depende del **keyspace**: el número de combinaciones posibles, que crece exponencialmente con la longitud. Una contraseña de 8 caracteres solo en minúsculas son 26⁸ ≈ 200.000 millones de combinaciones; añadir mayúsculas, dígitos y símbolos (95 caracteres imprimibles) la dispara a 95⁸ ≈ 6,6·10¹⁵.

Lo que convierte ese número en tiempo es el hardware y el algoritmo de hashing. La tabla anual de **Hive Systems (2025)**, modelada sobre un sistema de 12× `RTX 5090` atacando `bcrypt` (cost 10), es la referencia para argumentar criticidad en un informe:

- 8 caracteres solo minúsculas → **~3 semanas**.
- 8 caracteres con símbolos → **~164 años**.
- 10 caracteres con símbolos → **~803 años**.

> [!warning]+ El algoritmo de hash lo es todo
> Esas cifras son contra `bcrypt`, un hash **lento** y con `salt` diseñado para resistir. Contra `MD5` o `NTLM` —rápidos— los mismos 12 GPUs revientan esa contraseña de 8 con símbolos en horas, no siglos. <mark style="background: #FFB86CA6;">Y con hardware de IA (el que mueve los LLM), Hive estima que los tiempos se desploman a horas incluso para casos antes "seguros"</mark>. En un pentest, lo primero que determina la criticidad de un hash robado no es la longitud de la contraseña, sino **qué algoritmo** la protege.

Frente a un login `online`, sin embargo, nada de esto aplica: no atacas el keyspace completo, atacas la **probabilidad** de que el usuario haya elegido algo del top de una wordlist. Por eso el diccionario, no la fuerza bruta exhaustiva, es la técnica de cabecera contra formularios web.

# La defensa moderna y lo que implica para nosotros

La guía vigente **NIST SP 800-63B Rev. 4** rompió con el dogma clásico de "complejidad obligatoria". Hoy recomienda:

- Mínimo **15 caracteres** cuando la contraseña es el único factor (8 como suelo absoluto), soportando al menos 64.
- **Prohibido** exigir composición (mayúsculas + dígitos + símbolos): genera patrones predecibles (`P@ssw0rd1`) que las reglas de [[03 - Medusa y alternativas modernas|los crackers]] ya conocen.
- **Sin expiración periódica** salvo evidencia de compromiso.
- Cribado contra listas de contraseñas filtradas (`Have I Been Pwned`) y MFA recomendado.

<mark style="background: #8000E1A6;">Esto reconfigura el objetivo del atacante</mark>: si la organización aplica NIST, las contraseñas serán largas pero **memorizables** (passphrases) y, sobre todo, los controles de cribado y MFA pesan más que la longitud. La superficie real pasa de "adivinar la contraseña" a "esquivar el rate limiting" ([[05 - Defensas y evasión]]), encontrar cuentas sin MFA, o explotar lógica rota en el reset de contraseña. Donde NIST **no** se aplica —paneles internos, IoT, apps legacy— la fuerza bruta clásica sigue muy viva.

# Cuándo recurrir a la fuerza bruta en un engagement

No es la primera carta. Tiene sentido cuando:

- <mark style="background: #FFB8EBA6;">Se han agotado otras vías</mark> (no hay CVE, ni reutilización obvia, ni misconfiguración).
- La política de contraseñas es laxa o inexistente — paneles administrativos, dispositivos de red, servicios internos.
- Hay un objetivo concreto: una cuenta privilegiada, un endpoint de API, un panel olvidado.
- Antes de tocar la contraseña, hay un username que enumerar ([[01 - Enumeración de usuarios]]): conocer el usuario es la mitad del trabajo, y las credenciales por defecto ([[06 - Credenciales por defecto]]) muchas veces lo resuelven sin forzar nada.

> [!info]+ Fuentes
> - [Hive Systems — 2025 Password Table](https://www.hivesystems.com/password-table) (tiempos de crackeo, hardware actual)
> - [NIST SP 800-63B Rev. 4 — Digital Identity Guidelines](https://pages.nist.gov/800-63-4/sp800-63b.html) (política de contraseñas vigente)
> - [SecLists — Usernames/top-usernames-shortlist.txt](https://github.com/danielmiessler/SecLists/blob/master/Usernames/top-usernames-shortlist.txt)
