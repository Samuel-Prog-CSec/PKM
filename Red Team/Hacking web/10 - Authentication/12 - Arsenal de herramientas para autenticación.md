---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - Tipo/Arsenal
Descripción: "El instrumental específico de autenticación, por fase"
Fecha de actualización: 2026-06-23
Nota previa: "[[11 - Detección y metodología en autenticación]]"
Nota siguiente:
Area: "[[Authentication.base|Authentication]]"
---
---

El instrumental específico de autenticación, por fase. Las herramientas de **fuerza bruta** (Hydra, Medusa, ffuf, fireprox, hashcat) viven en su propio sub-tema: [[06 - Arsenal de herramientas para Brute Forcing]]. Aquí, lo que ataca la **lógica** de autenticación, los tokens y la sesión.

# Enumeración de usuarios

| Herramienta | Qué aporta |
| - | - |
| **ffuf** / **Burp Intruder** | Enum por mensaje/longitud/timing diferencial. Ver [[01 - Enumeración de usuarios]] |
| **wpscan** | `--enumerate u` para usuarios de WordPress (REST API, `?author=`) |
| **Kerbrute** ([repo](https://github.com/ropnop/kerbrute)) | Enum y spraying de usuarios en Active Directory sin lockouts ruidosos |
| **Arjun** ([repo](https://github.com/s0md3v/Arjun)) / **Param Miner** | Descubren parámetros ocultos (`user_id`, `admin`) que disparan bypass |

# Análisis de tokens y sesión

| Herramienta | Qué aporta |
| - | - |
| <mark style="background: #FFB86CA6;">**Burp Sequencer**</mark> | Mide estadísticamente la entropía de cientos de tokens — la prueba clave de "tokens predecibles" |
| **Burp Inspector** / **CyberChef** ([repo](https://github.com/gchq/CyberChef)) | Decodifican y reforjan tokens (base64/hex/URL), magia para el `role=admin` |
| **jwt_tool** ([repo](https://github.com/ticarpi/jwt_tool)) | Cuando el token es un [[01 - Introducción a JWT\|JWT]]: análisis y ataque de firma |

# Reset y lógica

| Herramienta | Qué aporta |
| - | - |
| **Burp Repeater** | Manipular paso a paso el flujo de reset (host header, parámetro de usuario) |
| **Burp Collaborator** / **interactsh** | Capturar la fuga del token por `Referer` o el callback del host header poisoning |

# Bypass de autenticación y autorización

| Herramienta | Qué aporta |
| - | - |
| **Autorize** ([repo](https://github.com/Quitten/Autorize)) | Extensión de Burp que reenvía cada petición con sesión de menor privilegio → detecta bypass/IDOR automáticamente |
| **AuthMatrix** ([repo](https://github.com/PortSwigger/auth-matrix)) | Matriz de roles × endpoints para validar control de acceso sistemáticamente |
| **ffuf** | *Forced browsing* a recursos protegidos sin sesión |

# 2FA, race conditions y robo de sesión

| Herramienta | Qué aporta |
| - | - |
| **Turbo Intruder** ([repo](https://github.com/PortSwigger/turbo-intruder)) | *Single-packet attack* HTTP/2 para [[04 - Fuerza bruta de códigos 2FA y MFA\|race conditions]] anti-lockout en OTP |
| **fireprox** ([repo](https://github.com/ustayready/fireprox)) | Rotación de IP para evadir el rate limit del OTP. Ver [[05 - Defensas y evasión]] |
| <mark style="background: #FFB86CA6;">**Evilginx2**</mark> ([repo](https://github.com/kgretzky/evilginx2)) | Phishing *adversary-in-the-middle*: roba la cookie de sesión ya autenticada y **salta el MFA** por completo |

# Escaneo automatizado

| Herramienta | Qué aporta |
| - | - |
| **nuclei** ([repo](https://github.com/projectdiscovery/nuclei)) | Plantillas `default-logins`, `exposures` y bypass de auth conocidos a escala |
| **changeme** ([repo](https://github.com/ztgrace/changeme)) | Escáner de [[06 - Credenciales por defecto\|credenciales por defecto]] — clásico poco mantenido (release 2020); hoy `nuclei default-logins` es la opción primaria |

# Flujo de referencia

```text
Mapear flujos (login/registro/reset/2FA/sesión)
   → Enum usuarios (ffuf/wpscan/Kerbrute)
   → Protecciones: ¿bypass de rate limit/CAPTCHA? (Burp + fireprox)
   → Login: spraying/brute force (ver Brute Forcing) · default creds (nuclei/changeme)
   → Reset: lógica (Repeater + Collaborator) · token (Sequencer)
   → 2FA: forced browse · brute OTP (Turbo Intruder)
   → Bypass: Autorize/AuthMatrix · Sesión: Sequencer + análisis de cookie
   → ¿MFA fuerte? → robo de sesión (Evilginx2)
```

> [!info]+ Fuentes y repos
> - Sesión/tokens: [Burp Sequencer](https://portswigger.net/burp/documentation/desktop/tools/sequencer) · [CyberChef](https://github.com/gchq/CyberChef) · [jwt_tool](https://github.com/ticarpi/jwt_tool)
> - Authz: [Autorize](https://github.com/Quitten/Autorize) · [AuthMatrix](https://github.com/PortSwigger/auth-matrix) · [Arjun](https://github.com/s0md3v/Arjun)
> - 2FA/sesión: [Turbo Intruder](https://github.com/PortSwigger/turbo-intruder) · [fireprox](https://github.com/ustayready/fireprox) · [Evilginx2](https://github.com/kgretzky/evilginx2)
> - Escaneo: [nuclei](https://github.com/projectdiscovery/nuclei) · [changeme](https://github.com/ztgrace/changeme) · [Kerbrute](https://github.com/ropnop/kerbrute)
