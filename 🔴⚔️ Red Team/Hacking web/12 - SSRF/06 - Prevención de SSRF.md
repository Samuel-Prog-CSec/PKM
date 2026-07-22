---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - Server-Side/SSRF
Fecha de actualización: 2026-06-22
Nota previa: "[[05 - Evasión de defensas SSRF]]"
Nota siguiente: "[[07 - Arsenal de herramientas SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
---

Prevenir la SSRF se ataca en **dos capas**: la aplicación (qué se permite pedir) y la red (qué puede salir del servidor). Ninguna basta por sí sola; la defensa robusta las combina —y conoce el *gotcha* que tumba la mayoría de implementaciones ingenuas: el **DNS rebinding**—.

# Capa de aplicación

Si la app trae recursos según input del usuario, el control central es una <mark style="background: #ADCCFFA6;">**allowlist** de destinos permitidos</mark>: el origen al que se va a pedir se comprueba contra una lista blanca, de modo que el atacante no pueda forzar peticiones a destinos arbitrarios. A ello se suma:

- **Restringir el esquema/protocolo**: fijar `http(s)://` y **bloquear** `file://`, `gopher://`, `dict://`… —son los que convierten una SSRF en lectura de ficheros o RCE—. Hardcodear el esquema o validarlo contra whitelist.
- **Sanitización de entrada**: como toda entrada de usuario, ayuda a evitar comportamientos inesperados, pero es **secundaria** a la allowlist.

# El gotcha que rompe los allowlists: DNS rebinding

<mark style="background: #FF5582A6;">Validar el **hostname** y luego dejar que el cliente HTTP lo **resuelva de nuevo** es una condición de carrera (TOCTOU)</mark>. El atacante apunta a un dominio propio cuyo DNS, con TTL bajo, devuelve una IP benigna durante la validación y la IP interna (`169.254.169.254`, `127.0.0.1`) en la petición real. La validación pasa; la conexión va al destino prohibido.

La defensa correcta:

1. **Resolver el host una sola vez**.
2. **Validar la IP resuelta** contra una *denylist* de rangos internos —en **todas** sus representaciones (ver [[05 - Evasión de defensas SSRF|evasión]], donde se ve por qué los chequeos por *string* fallan)—: loopback (`127.0.0.0/8`, `::1`), link-local (`169.254.0.0/16`), privados (`10/8`, `172.16/12`, `192.168/16`), CGN (`100.64.0.0/10` — donde cae la metadata de Alibaba), `0.0.0.0/8`, y sus equivalentes IPv6 (`fc00::/7`, `::ffff:…`).
3. **Conectar a esa IP ya validada** (pinning), no re-resolver el nombre.

# Redirecciones

Un endpoint atacante puede validar como benigno y luego devolver un `302` a la IP interna. Por eso: **re-validar tras cada redirección** o, más simple, **desactivar el seguimiento de redirects** en el cliente HTTP.

# Capa de red

Defensa en profundidad por si la capa de aplicación falla:

- **Firewall de egress** con *default-deny*: el servidor solo puede salir a los destinos que necesita. Una config restrictiva **descarta** las peticiones a sistemas internos inesperados y mitiga la SSRF aunque exista el bug.
- **Segmentación de red**: que el servidor web no tenga ruta a los servicios sensibles que un atacante querría alcanzar.
- **Bloquear el endpoint de metadatos** (`169.254.169.254`) a nivel de red para los servidores que no lo necesiten.

# Cloud: blindar el endpoint de metadatos

<mark style="background: #FFB86CA6;">El control que más reduce el impacto en AWS: forzar `IMDSv2` y desactivar `IMDSv1`</mark>. IMDSv2 exige un token obtenido por `PUT` (que un SSRF GET-only normalmente no puede emitir) y permite fijar un *hop limit* de 1 (bloquea el acceso desde un contenedor por un salto extra). <mark style="background: #FFB8EBA6;">Ojo</mark>: EKS/Docker suelen subir el hop limit a `2`–`3` para que los contenedores lleguen al IMDS, lo que **re-introduce** el riesgo desde un contenedor comprometido —ahí la defensa real es el token + políticas de red—. Con IMDSv1 deshabilitado, una SSRF que alcance el endpoint **no** obtiene las credenciales IAM directamente. En GCP y Azure, el endpoint exige cabeceras específicas (`Metadata-Flavor: Google`, `Metadata: true`) que un SSRF simple no inyecta —pero conviene igualmente restringir el acceso de red—.

# No filtrar errores verbosos

Devolver mensajes de error genéricos e idénticos evita que el atacante use el **diferencial de errores** como oráculo —justo la palanca que hace explotable una [[04 - Blind SSRF|SSRF ciega]] (puerto abierto/cerrado, fichero existe/no existe)—.

> [!important]+ Resumen para el informe
> El parche real es **allowlist de destino + validación de IP resuelta (anti-rebinding) + esquema restringido**, reforzado con **egress firewall** y, en cloud, **IMDSv2 obligatorio**. La sanitización de strings y el WAF son capas secundarias, no la solución. <mark style="background: #8000E1A6;">Un allowlist que valida el hostname pero no la IP resuelta da una falsa sensación de seguridad.</mark>

> [!info]+ Fuentes
> - [OWASP — SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
> - [AWS — Use IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) · [PortSwigger — Preventing SSRF](https://portswigger.net/web-security/ssrf)

Cierra el sub-tema el inventario de herramientas que automatizan el descubrimiento, la explotación con gopher y el canal OOB: [[07 - Arsenal de herramientas SSRF]].
