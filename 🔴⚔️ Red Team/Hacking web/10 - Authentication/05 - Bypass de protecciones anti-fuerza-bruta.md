---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[04 - Fuerza bruta de códigos 2FA y MFA]]"
Nota siguiente: "[[06 - Credenciales por defecto]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Toda la fuerza bruta de las notas anteriores choca con dos defensas: **rate limiting** y **CAPTCHA**. Ambas se implementan mal con frecuencia. El catálogo completo de evasión vive en [[05 - Defensas y evasión|Brute Forcing]]; aquí están los dos fallos clásicos en el contexto de autenticación, con sus instancias reales.

# Rate limiting confiado en cabeceras

El rate limiting suele indexarse por IP de origen. <mark style="background: #FFB8EBA6;">El problema: detrás de un reverse proxy, load balancer o CDN, la IP de la conexión es la del *middlebox*, no la del cliente</mark>. Para recuperar la IP real, muchas apps confían en una cabecera HTTP como `X-Forwarded-For`.

Pero esa cabecera la controla el atacante. <mark style="background: #FF5582A6;">Randomizando `X-Forwarded-For` en cada petición, el contador de rate limit nunca se acumula</mark> y la fuerza bruta vuelve a ser viable:

```http
POST /login HTTP/1.1
X-Forwarded-For: 13.37.4.2      ← un valor distinto por intento
```

Es un fallo real y recurrente: [CVE-2020-35590](https://nvd.nist.gov/vuln/detail/CVE-2020-35590) (WordPress) es exactamente esto. Otras variantes (doble `X-Forwarded-For`, `X-Real-IP`, race conditions, variación de endpoint) y la rotación real de IP con `fireprox`, en [[05 - Defensas y evasión|el catálogo de Brute Forcing]].

# CAPTCHA: cuándo no sirve de nada

El `CAPTCHA` convierte la fuerza bruta automatizada en una tarea manual. En teoría la frena; en la práctica falla de varias formas:

- <mark style="background: #FFB86CA6;">**Solución en la respuesta**</mark>: si el valor esperado del CAPTCHA viaja en el HTML o en una cabecera/cookie, lo lees y lo respondes — el reto es decorativo. Inspecciona siempre el DOM y el tráfico.
- **Solo cliente**: el CAPTCHA se valida en JavaScript pero el endpoint no lo comprueba server-side. Envías la petición directa sin el campo y pasa.
- **No se invalida**: un token de CAPTCHA reutilizable se resuelve una vez y se reenvía en cada intento.
- **Resolución automatizada**: los solvers basados en IA (reconocimiento de imagen/voz) y servicios como 2captcha han erosionado el valor de los CAPTCHA clásicos. Un reCAPTCHA "no soy un robot" mal integrado se salta con frecuencia.

> [!warning]+ Un control presente no es un control efectivo
> El error de evaluación más común: ver un CAPTCHA o un mensaje de rate limit y asumir que el endpoint está protegido. <mark style="background: #8000E1A6;">Hay que probar el bypass</mark> — randomizar la cabecera, quitar el campo del CAPTCHA, repetir el token. Un "429" que desaparece al añadir `X-Forwarded-For` es un hallazgo reportable por sí mismo, independientemente de si luego revientas alguna cuenta.

Cuando el rate limiting es real e infranqueable por estas vías, el ataque cambia de eje: en vez de muchas contraseñas contra un usuario, pocas contra muchos ([[02 - Fuerza bruta de contraseñas en el login|password spraying]]).

> [!info]+ Fuentes
> - [PortSwigger — Bypassing brute-force protection](https://portswigger.net/web-security/authentication/password-based)
> - [CVE-2020-35590 — WordPress X-Forwarded-For rate limit bypass](https://nvd.nist.gov/vuln/detail/CVE-2020-35590)
> - Catálogo de evasión: [[05 - Defensas y evasión]]
