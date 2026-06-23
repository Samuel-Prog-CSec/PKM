---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Fecha de actualización: 2026-06-23
Nota previa: "[[03 - Interceptación de respuestas]]"
Nota siguiente: "[[05 - Repeater - repetir y modificar peticiones]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Interceptar y editar a mano cada petición no escala. <mark style="background: #ADCCFFA6;">Las reglas de `Match and Replace` aplican una modificación a **todas** las peticiones o respuestas automáticamente</mark>, según un patrón. Es la diferencia entre cambiar algo una vez y que se cambie siempre, solo.

# Burp: Match and Replace

En `Proxy > Proxy settings > HTTP match and replace rules > Add`. El caso típico: falsear el `User-Agent` para evadir un filtro que bloquea ciertos agentes.

![Diálogo de regla Match/Replace en Burp: tipo Request header, match `^User-Agent.*$`, replace `User-Agent: HackTheBox Agent 1.0`, regex activado.](https://academy.hackthebox.com/storage/modules/110/burp_match_replace_user_agent_1.png)

| Campo | Valor |
| - | - |
| `Type` | `Request header` (el cambio va en la cabecera) |
| `Match` | `^User-Agent.*$` (regex que captura toda la línea) |
| `Replace` | `User-Agent: HackTheBox Agent 1.0` |
| `Regex match` | `True` (no sabemos el UA exacto, casamos por patrón) |

Desde ese momento, cada petición sale con el UA reemplazado, sin intervención.

# ZAP: Replacer

El equivalente en ZAP es `Replacer` (`CTRL+R`). Mismas opciones: `Match Type` = `Request Header (will add if not present)`, `Match String` = `User-Agent`, `Replacement String` = el nuevo valor. Los `Initiators` deciden a qué tráfico se aplica (por defecto, a todo).

# Modificación automática de respuestas

El mismo mecanismo sobre respuestas. Recuperando el caso de [[03 - Interceptación de respuestas|interceptar respuestas]], donde los cambios al campo `IP` eran temporales: una regla de tipo `Response body` los hace **persistentes**:

| Campo | Valor |
| - | - |
| `Type` | `Response body` |
| `Match` | `type="number"` |
| `Replace` | `type="text"` |
| `Regex match` | `False` (cadena exacta conocida) |

<mark style="background: #FFB86CA6;">Ahora el campo acepta cualquier entrada en cada recarga, sin interceptar nada.</mark> Una segunda regla (`maxlength="3"` → `maxlength="100"`) elimina el límite de longitud.

> [!important]+ Usos reales en un engagement
> Match & Replace brilla para automatizar lo repetitivo: <mark style="background: #8000E1A6;">inyectar una cabecera en todo el tráfico</mark> (un token de auth, un `X-Forwarded-For` para [[05 - Defensas y evasión|evadir rate limiting]], una cabecera de bypass de WAF), forzar `type=text` en formularios restringidos de toda la app, o neutralizar protecciones de cliente de forma global. Es el sustituto automatizado de interceptar a mano una y otra vez.

> [!info]+ Fuentes
> - [PortSwigger — Match and replace rules](https://portswigger.net/burp/documentation/desktop/tools/proxy/match-and-replace)
