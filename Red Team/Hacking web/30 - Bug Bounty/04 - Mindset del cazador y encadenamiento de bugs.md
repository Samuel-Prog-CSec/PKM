---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Explotacion
Descripción: "La técnica es la mitad; la otra mitad es cómo piensas"
Fecha de actualización: 2026-07-27
Nota previa: "[[03 - Metodología de caza - mapear y atacar la aplicación]]"
Nota siguiente: "[[05 - Escribir un buen reporte]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

La técnica es la mitad; la otra mitad es **cómo piensas**. Dos cazadores con el mismo conocimiento encuentran cosas muy distintas en el mismo objetivo, y la diferencia está en el modelo mental con el que miran la aplicación.

# Pensar en acciones no previstas

<mark style="background: #ADCCFFA6;">Una vulnerabilidad es una debilidad que permite realizar una acción no permitida u obtener acceso a información que no debería verse</mark>. La pregunta ante **cada** funcionalidad no es "¿funciona?", sino <mark style="background: #8000E1A6;">"¿cómo se puede abusar de esto?"</mark>. El ejemplo de Yaworski: una red social mantiene tu perfil privado y solo lo comparte con amigos —correcto—, pero si **cualquiera puede añadirte como amigo sin tu permiso**, cualquiera accede a tu información. La funcionalidad "funciona"; el abuso está en el hueco entre lo que el desarrollador *asumió* y lo que el sistema *permite*.

Ese hueco —acciones **intencionadas** vs **no intencionadas**— es donde vive casi todo bug. Cada feature es superficie de ataque: un campo que se refleja, un ID en la URL, un webhook, una subida de fichero.

> [!info]+ Definir el éxito para no quemarte
> Yaworski insiste: mide tu éxito por el **conocimiento y la habilidad** que ganas, no por los bugs o el dinero. Los programas maduros (Uber, Shopify, Google) los testean cazadores muy buenos **a diario** — hay menos bugs y son más difíciles. Si mides tu valía en bounties, las rachas secas te hunden; si la mides en aprendizaje, sigues avanzando.

# Encadenar: donde está el dinero

<mark style="background: #FFB86CA6;">Un bug de severidad baja, encadenado con otro, se vuelve crítico</mark>. Esto separa el reporte de $50 del de $5.000, y es lo que más valora el triager. Un cazador experto no reporta un open redirect suelto: busca **qué desbloquea**. Cadenas clásicas que conviene tener en la cabeza:

| Cadena | Resultado |
| - | - |
| [[00 - Introducción a Open Redirect\|Open redirect]] → `redirect_uri` de OAuth | Robo del token → [[08 - Robo de tokens de acceso OAuth\|account takeover]] |
| Self-XSS + CSRF de login/logout | Convertir un self-XSS "inútil" en XSS explotable contra cualquiera |
| [[00 - Introducción a XSS\|XSS]] → robo del token anti-CSRF | Acciones sensibles en nombre de la víctima ([[01 - Fundamentos y defensas de CSRF\|CSRF]]) |
| [[00 - Introducción a los ataques server-side\|SSRF]] → `169.254.169.254` | Credenciales de la metadata cloud → escalada en la infraestructura |
| [[06 - Introducción a IDOR\|IDOR]] → info disclosure | Fuga de datos de otros → [[11 - Encadenamiento de IDOR\|escalada a ATO]] |
| [[00 - Fundamentos de Subdomain Takeover\|Subdomain takeover]] → cookie del dominio padre | Robo de sesión / phishing sobre un dominio de confianza |
| [[01 - Introducción a CRLF Injection\|CRLF]] → response splitting | Cache poisoning / XSS vía cabecera |

<mark style="background: #FF5582A6;">La regla: al encontrar un bug "menor", no lo reportes aún — pregúntate contra qué lo puedes combinar</mark>. El [[00 - Introducción a Open Redirect|open redirect]] es la navaja suiza del chaining (OAuth, bypass de filtros SSRF, fuga de `Referer`).

# Demostrar el impacto máximo

El chaining alimenta la última pieza del mindset: <mark style="background: #FF5582A6;">no pares en la prueba de concepto mínima, escala hasta enseñar el daño real</mark>. Un XSS con `alert(1)` es un `alert(1)`; el mismo XSS robando `document.cookie` o encadenado a un *account takeover* es un reporte de severidad alta. El triager tiene que **vender tu bug internamente**, y para eso necesita ver el peor escenario, no la existencia teórica del fallo. Esto es lo que convierte la técnica en dinero, y es la bisagra con el [[05 - Escribir un buen reporte|reporte]].

> [!important]+ Perseverancia
> El tercio que no sale en los write-ups. Los casos publicados cuentan el éxito, nunca las horas sin encontrar nada. "Cavar más hondo sin malgastar el tiempo" —saber cuándo insistir y cuándo cambiar de objetivo— es puro criterio, y solo se gana testeando.

Con el bug encontrado, encadenado y con su impacto demostrado, queda cobrarlo: comunicarlo en un [[05 - Escribir un buen reporte|reporte]] que el triager pueda validar y defender.
