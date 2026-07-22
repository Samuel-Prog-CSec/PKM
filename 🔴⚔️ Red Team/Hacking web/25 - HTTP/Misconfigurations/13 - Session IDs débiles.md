---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Session-Puzzling
Fecha de actualización: 2026-07-14
Nota previa: "[[12 - Introducción a Session Puzzling]]"
Nota siguiente: "[[14 - Variables de sesión compartidas - bypass de autenticación]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Aunque las variables de sesión se manejen bien, si el **propio session ID** es débil el atacante puede <mark style="background: #FFB86CA6;">adivinar o forzar la sesión de otro usuario</mark> y secuestrar su cuenta. Un session ID seguro tiene que ser **largo** e **impredecible**. Esta nota ataca las dos formas de fallar: longitud insuficiente y aleatoriedad insuficiente.

# Session IDs cortos → fuerza bruta

OWASP marca un mínimo de **128 bits (16 bytes)** de longitud, **asumiendo** que son aleatorios. Pero la longitud no basta sin entropía real: un ID de, pongamos, 16 caracteres con 12 fijos deja solo <mark style="background: #FFB8EBA6;">4 caracteres efectivos</mark> — trivial de forzar. Ejemplo real: un login que responde con un `sessionID` de **4 caracteres** (minúsculas + dígitos).

```shell-session
# Generar el espacio completo de 4 chars con crunch
$ crunch 4 4 "abcdefghijklmnopqrstuvwxyz1234567890" -o wordlist.txt

# Fuzzear cookies de sesión: -b pone la cookie, -fc 302 filtra el "no logueado"
$ ffuf -u http://target/profile.php -b 'sessionID=FUZZ' -w wordlist.txt -fc 302 -t 10
a7sh   [Status: 200, Size: 2262]   ← sesión válida de otro usuario → secuestro
```

El ID `a7sh` pertenece a un usuario logueado (el admin); poniéndolo como cookie en Burp, <mark style="background: #FFB86CA6;">tomas su sesión</mark>. Con 36^4 ≈ 1.7M combinaciones, es cuestión de minutos.

# Aleatoriedad insuficiente → entropía baja

Un ID puede ser largo y aun así **predecible** si tiene patrones (basado en timestamp, contador, `MD5(username)`, partes fijas). La aleatoriedad se mide en **entropía**; OWASP exige <mark style="background: #FFB8EBA6;">al menos **64 bits**</mark> (y 128 bits de longitud). Para medirla se usa **Burp Sequencer**:

1. Botón derecho en la petición de login → *Send to Sequencer*.
2. En la pestaña Sequencer, confirma que detecta la cookie de sesión (o define una ubicación custom) → *Start live capture*.
3. Espera a **≥1000** tokens y pulsa *Analyze*.

Si Burp estima, por ejemplo, **~14 bits** de entropía, es **gravemente insuficiente** — un atacante puede forzar sesiones activas. El **análisis por posición de carácter** revela qué posiciones no aportan entropía (caracteres fijos entre todos los IDs). <mark style="background: #FF5582A6;">En un engagement real, una entropía tan baja es un hallazgo de **severidad alta**</mark>.

> [!success] Estándar seguro (OWASP)
> - **Longitud**: ≥ 128 bits (16 bytes) de ID.
> - **Entropía**: ≥ 64 bits de aleatoriedad real.
> - **Fuente**: un **CSPRNG** (generador criptográficamente seguro), nunca `rand()`/`mt_rand()` ni timestamps.
> - **Rotación**: regenerar el ID **al autenticar** (previene session fixation).
> Los frameworks modernos (PHP 7+, Django, Rails, Express con `express-session` bien configurado) ya cumplen esto por defecto; los IDs débiles aparecen en **implementaciones custom o legacy**.

# Herramientas

| Herramienta | Uso |
| - | - |
| **Burp Sequencer** | Análisis estadístico de entropía y patrones de tokens |
| **crunch** | Generar el espacio de IDs cortos para fuerza bruta |
| **ffuf** | Fuzzear cookies de sesión (`-b 'sessionID=FUZZ'`) |
| **hashcat** | Si el ID es un hash de algo predecible, romperlo |

Esto se solapa con los [[10 - Ataques a tokens de sesión|ataques a tokens de sesión]] del módulo de autenticación (donde se cubren fixation, predicción y robo con más detalle). El resto del bloque vuelve al session puzzling puro: [[14 - Variables de sesión compartidas - bypass de autenticación|variables compartidas entre flujos]].

## Referencias

- [OWASP — Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [PortSwigger — Predictable session tokens](https://portswigger.net/web-security/authentication/other-mechanisms)
