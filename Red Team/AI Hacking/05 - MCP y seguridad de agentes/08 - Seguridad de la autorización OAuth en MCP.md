---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - Tipo/Defensa
Descripción: "MCP delega la autenticación en OAuth, y el documento oficial de seguridad enumera confused deputy, token passthrough, SSRF y otros ataques que HTB no cubre en absoluto"
Fecha de actualización: 2026-07-29
Nota previa: "[[07 - Rug pull y tool shadowing]]"
Nota siguiente: "[[09 - CVEs y ataques reales de MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">MCP no inventa su propia autenticación: delega en `OAuth 2.1`, y el documento oficial *MCP Security Best Practices* enumera los ataques concretos que aparecen cuando se hace mal.</mark> Es la parte que HTB no toca en absoluto —su módulo es de antes de que MCP tuviera un modelo de autorización serio— y es donde están varios de los fallos más graves de 2025-2026. Esta nota es un resumen operativo de la fuente primaria.

> [!info]+ Fuente primaria
> Todo lo de esta nota viene del documento oficial [*MCP Security Best Practices*](https://modelcontextprotocol.io/specification/latest/basic/security_best_practices) (versión 2026-07-28) y de la [*MCP Authorization*](https://modelcontextprotocol.io/specification/latest/basic/authorization) que lo acompaña. Se cita con los `MUST`/`SHOULD` de la spec porque son requisitos verificables en un pentest.

# Por qué OAuth y por qué se complica

Un servidor MCP suele actuar de **proxy** hacia una API de terceros (GitHub, Google Drive), con OAuth por medio. Esa posición de intermediario —el servidor tiene credenciales propias y actúa en nombre de muchos clientes— es la que genera casi todos los ataques de autorización. La versión 2026-07-28 endureció mucho este modelo: validación de `iss` (RFC 9207), `Client ID Metadata Documents (CIMD)` en lugar de registro dinámico, y binding de credenciales al servidor emisor.

# Confused deputy

El ataque central del proxy OAuth. Se da cuando el servidor MCP usa un **client ID estático** contra el servidor de autorización de terceros, permite a los clientes **registrarse dinámicamente**, y el servidor de terceros pone una **cookie de consentimiento** tras el primer OK.

El flujo del ataque:

1. Un usuario legítimo consiente el acceso a la API de terceros. El servidor de terceros deja una cookie de consentimiento ligada al `client_id` estático del proxy.
2. El atacante registra dinámicamente un cliente malicioso con su `redirect_uri`, y envía a la víctima un enlace de autorización con ese `redirect_uri`.
3. El navegador de la víctima **aún tiene la cookie** de consentimiento, así que el servidor de terceros **salta la pantalla de consentimiento**.
4. El código de autorización se redirige al servidor del atacante.
5. El atacante lo canjea por tokens sin que la víctima haya aprobado nada.

<mark style="background: #FF5582A6;">La víctima solo tuvo que hacer clic en un enlace; nunca vio una pantalla de consentimiento porque la cookie la saltó.</mark>

**Mitigación (spec, `MUST`)**: el proxy MCP debe implementar **consentimiento por cliente propio**, comprobado *antes* de reenviar al servidor de terceros. Además: validación exacta del `redirect_uri` (sin comodines), cookies con prefijo `__Host-` y `SameSite=Lax`, y `state` OAuth criptográfico validado en el callback y de un solo uso.

# Token passthrough

Antipatrón explícitamente **prohibido** por la spec: un servidor MCP acepta tokens sin verificar que fueron emitidos **para él** (validación de audiencia, `aud`), y los reenvía tal cual a la API de abajo.

Dos problemas encadenados:

- **Fallo de validación de audiencia** — el servidor acepta tokens emitidos para otro servicio, rompiendo la frontera de seguridad de OAuth.
- **Passthrough** — al reenviarlos sin más, provoca el *confused deputy* en la API de abajo, que confía en el token como si el servidor MCP lo hubiera validado.

Riesgos: se saltan los controles que dependen de la audiencia (rate limiting, validación), se rompe la traza de auditoría (los logs de la API muestran al servidor MCP, no al cliente real), y un token robado se reutiliza entre servicios.

**Mitigación (spec, `MUST NOT`)**: un servidor MCP **NO DEBE** aceptar ningún token que no se haya emitido explícitamente para él. Validación de `aud` en toda petición.

# SSRF en el descubrimiento de metadatos

Durante el descubrimiento de OAuth, el cliente MCP obtiene URLs de fuentes que puede controlar un **servidor malicioso**: la `resource_metadata` de la cabecera `WWW-Authenticate`, las `authorization_servers` del documento de metadatos, y los endpoints del servidor de autorización. Un servidor hostil las apunta a recursos internos:

- **IP internas** — `http://192.168.1.1/admin`, `http://10.0.0.1/api`.
- **Metadatos de nube** — `http://169.254.169.254/` para robar credenciales IAM de AWS/GCP/Azure.
- **Servicios en localhost** — `http://localhost:6379/` (Redis), paneles de administración.
- **DNS rebinding** y **cadenas de redirección** para saltarse una validación que solo mire la URL inicial.

Es [[01 - Introducción a SSRF|SSRF]] con el cliente MCP como *deputy*, y la spec dedica una sección entera a mitigarlo:

**Mitigación (spec, `SHOULD`)**: exigir HTTPS (salvo `loopback` en desarrollo), **bloquear rangos privados y reservados** (`10/8`, `172.16/12`, `192.168/16`, `127/8`, `169.254/16`, `fc00::/7`), validar los destinos de redirección con las mismas reglas, y usar un proxy de egreso tipo `Smokescreen`. La spec avisa explícitamente: **no validar IPs a mano** —los atacantes usan codificación octal, hexadecimal e IPv4-mapped-IPv6 que los parsers caseros fallan.

# Los otros ataques de la spec

El documento enumera varios más, que conviene conocer para auditar un cliente/servidor moderno:

| Ataque | Esencia | Mitigación clave |
| - | - | - |
| **State handle hijacking** | Adivinar/robar el `state handle` stateless de otro usuario | Handles no deterministas, ligados al usuario en servidor; nunca tratar posesión como auth |
| **Mix-up attacks** | Un AS malicioso hace que el cliente le mande un código de otro AS honesto | Validación de `iss` en la respuesta (RFC 9207); PKCE **no** basta |
| **OAuth URL injection** | Un servidor da una URL `javascript:` o con inyección de shell que el cliente abre | Solo `http(s)`; nunca abrir URLs con shell; validar esquema por lista blanca |
| **Local server compromise** | Comando de arranque malicioso en la config de un servidor local | Consentimiento mostrando el **comando exacto**; sandboxing del proceso |
| **Localhost redirect impersonation** | Un cliente nativo reclama el `redirect_uri` `localhost` de otro | El AS avisa y muestra el hostname del redirect |
| **Scope minimization** | Un token con scopes excesivos amplía el radio de un robo | Scopes mínimos incrementales vía `WWW-Authenticate` |

# El vector `localhost`: MCP en tu propia máquina

Un matiz que conecta con [[08 - MLflow, del path traversal al RCE#El MLflow de 2026: sigue igual de roto|MLflow]]: muchos servidores MCP corren en **local**, y la spec avisa de que un servidor local inseguro dejado escuchando en `localhost` es alcanzable desde el navegador vía **DNS rebinding**. Por eso la [[01 - El protocolo MCP - mensajes, transportes y ciclo de vida#`Streamable HTTP` — remoto|spec obliga]] a que el servidor valide la cabecera `Origin` (HTTP 403 si es inválida) en el transporte `Streamable HTTP`. Un servidor MCP local que no valide `Origin` es un RCE potencial desde una web maliciosa — exactamente el patrón de [[04 - DNS Rebinding para bypass de Same-Origin Policy|DNS rebinding contra la SOP]].

# Qué comprobar en un pentest de MCP con OAuth

> [!warning]+ Los cinco checks de autorización
> 1. ¿El servidor valida la **audiencia** (`aud`) de los tokens? Manda un token emitido para otro servicio → si lo acepta, token passthrough.
> 2. ¿Hay **consentimiento por cliente**? Registra un cliente con `redirect_uri` propio y mira si el servidor reenvía sin re-consentir → confused deputy.
> 3. ¿El cliente valida las URLs de **descubrimiento**? Levanta un servidor MCP que devuelva `resource_metadata: http://169.254.169.254/...` → SSRF.
> 4. ¿El servidor valida `Origin`? Petición con `Origin` arbitrario → si no da 403, DNS rebinding.
> 5. ¿Los `state handles` son **predecibles**? Enumera → state handle hijacking.
>
> Estos cinco checks cubren la mayor parte de la superficie de autorización de un despliegue MCP moderno, y ninguno aparece en el material de HTB.
