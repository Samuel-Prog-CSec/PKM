---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Descripción: "Las APIs consumen otras APIs para intercambiar datos, formando un ecosistema interconectado"
Fecha de actualización: 2026-07-15
Nota previa: "[[09 - Improper Inventory Management (API9)]]"
Nota siguiente: "[[11 - Detección y evasión en APIs]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Las APIs consumen otras APIs para intercambiar datos, formando un ecosistema interconectado. `Unsafe Consumption of APIs` ocurre cuando <mark style="background: #ADCCFFA6;">una API **confía ciegamente** en los datos que recibe de otra API de terceros</mark>, relajando la validación "porque viene de una fuente reputada". Es la **cadena de suministro** aplicada a las APIs. OWASP mapea esta categoría a `CWE-20` (input validation), `CWE-200` (exposición de datos) y `CWE-319` (transmisión en claro); `CWE-1357: Reliance on Insufficiently Trustworthy Component` capta bien la idea de "componente poco fiable" pero **no es el CWE oficial** que OWASP asigna a API10:2023.

# Los riesgos de la comunicación API↔API

| Riesgo | Qué implica |
| - | - |
| **Transmisión insegura** | Canales sin cifrar → interceptación de datos sensibles (MITM) |
| <mark style="background: #FFB86CA6;">**Validación inadecuada**</mark> | No sanear los datos de la API externa antes de procesarlos/reenviarlos → inyección, corrupción, incluso `RCE` |
| **Autenticación débil** | Auth pobre entre servicios → acceso no autorizado a datos/funciones |
| **Sin rate-limiting** | Un servicio satura a otro → `DoS` en cascada |
| **Monitorización insuficiente** | Difícil detectar y responder a incidentes en el flujo API↔API |

El corazón del problema es <mark style="background: #8000E1A6;">tratar la respuesta de un tercero como confiable por defecto</mark>. Si el tercero es comprometido —o si el atacante puede influir en lo que ese tercero devuelve— el payload malicioso entra en tu sistema **con la guardia baja**.

# El enfoque ofensivo moderno (más allá de HTB)

HTB trata esta categoría de forma conceptual. En un pentest real, los vectores concretos son:

- <mark style="background: #FFB86CA6;">**SSRF a través de la integración**</mark>: si la API objetivo llama a una URL de tercero que **tú controlas** (webhook, "importar desde proveedor X", OAuth callback), devuelves datos maliciosos o rediriges hacia recursos internos. Se solapa con [[07 - Server-Side Request Forgery (API7)|SSRF]].
- **Redirects no validados**: la API sigue un `3xx` de la API externa hacia un destino interno → SSRF de segundo salto.
- **Inyección vía datos de tercero**: el tercero devuelve un campo que la API objetivo mete en una consulta SQL, un comando o una plantilla sin sanear → [[00 - Introducción a SQL Injection|SQLi]]/[[00 - Introducción a Command Injection|command injection]]/[[00 - Motores de plantillas e introducción a SSTI|SSTI]] **de segundo orden**.
- **Confianza en webhooks sin firmar**: si el endpoint que recibe webhooks (Stripe, GitHub, etc.) no valida la firma, cualquiera falsifica eventos (pagos confirmados, despliegues).
- **Deserialización de la respuesta**: parsear la respuesta del tercero con un deserializador inseguro → RCE.

> [!warning]+ El eslabón que no controlas... hasta que sí
> La suposición peligrosa es *"la API de mi proveedor es segura"*. Pero el atacante rara vez ataca al proveedor: **manipula el punto donde tú lo consumes** (el webhook, el parámetro de callback, el redirect que sigues). Trata **toda** entrada externa —venga de un usuario o de otra API— como no confiable.

# Prevención

- **TLS** en toda comunicación entre servicios; verificar certificados.
- **Validar y sanear** los datos del tercero **antes** de procesarlos o reenviarlos (misma disciplina que con la entrada del usuario).
- **Autenticación robusta** entre servicios (mTLS, tokens con scope mínimo) y **firma** de webhooks verificada.
- **No seguir redirects** ciegamente hacia destinos arbitrarios; allowlist.
- **Rate-limiting** y **monitorización** de las interacciones API↔API.

Con esto cerramos el OWASP API Top 10. Las dos notas siguientes consolidan la [[11 - Detección y evasión en APIs|detección y evasión]] y las [[12 - Herramientas para pentesting de APIs|herramientas]] del pentest de APIs.

## Referencias

- OWASP — [API10:2023 Unsafe Consumption of APIs](https://owasp.org/API-Security/editions/2023/en/0xaa-unsafe-consumption-of-apis/)
- MITRE — [CWE-1357](https://cwe.mitre.org/data/definitions/1357.html)
- HTB Academy — *API Attacks* (base, 2024)
