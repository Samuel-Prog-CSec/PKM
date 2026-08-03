---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - Introduccion
  - Tipo/Introduccion
Descripción: "Broken Authentication cubrió los ataques 'básicos' a un login: fuerza bruta, bypass, sesión"
Fecha de actualización: 2026-06-23
Nota previa:
Nota siguiente: "[[01 - Introducción a JWT]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

[[00 - Introducción a la autenticación|Broken Authentication]] cubrió los ataques "básicos" a un login: fuerza bruta, bypass, sesión. Este sub-tema sube de nivel a los **frameworks y estándares** que las organizaciones usan para centralizar la identidad — `JWT`, `OAuth` y `SAML` — y que, mal implementados, abren account takeovers de alto impacto. Son la materia del módulo CWEE *Attacking Authentication Mechanisms*.

# Por qué existen estos estándares

Las organizaciones quieren que el usuario entre **una vez** y acceda a todo (SSO), y reducir los silos de autenticación dispersos. <mark style="background: #ADCCFFA6;">JWT, OAuth y SAML son las tres piezas con las que se construye esa identidad federada y sin estado.</mark> Cada una resuelve un problema distinto, y conviene no confundirlas.

# Autenticación vs. autorización (otra vez, pero con matices)

La distinción importa más aquí que en ningún sitio, porque estos frameworks mezclan ambas:

- **Autenticación**: confirmar *quién* eres.
- **Autorización**: qué *puedes hacer*. Se gobierna con una política de control de acceso. Cuatro modelos clásicos:

| Modelo | Base de la decisión |
| - | - |
| `DAC` | El dueño del recurso decide quién accede |
| `MAC` | Etiquetas/clearances impuestas por el sistema |
| `RBAC` | **Roles** (admin, editor, lector) — el más común en web |
| `ABAC` | Atributos (departamento, hora, ubicación...) |

![Autenticación verifica la identidad del usuario con credenciales; autorización verifica su nivel de acceso a los recursos mediante políticas como DAC, MAC, RBAC y ABAC.](https://academy.hackthebox.com/storage/modules/170/diagrams/IMG_7460.png)

<mark style="background: #8000E1A6;">Cuando comprometes la capacidad de la app de identificar al usuario que pide algo, comprometes toda su seguridad.</mark> Y eso es exactamente lo que permiten los fallos en estos tres estándares.

# El mapa: JWT, OAuth y SAML

| Estándar | Qué es | Para qué se usa |
| - | - | - |
| [[01 - Introducción a JWT\|JWT]] | Formato de token con datos firmados (JSON) | Token de sesión **stateless** |
| [[07 - Introducción a OAuth 2.0\|OAuth 2.0]] | Protocolo de **autorización** delegada | "Entrar con Google", acceso de apps a APIs sin compartir contraseña |
| [[11 - Introducción a SAML\|SAML]] | Estándar XML de SSO entre IdP y SP | SSO empresarial (federación) |

- <mark style="background: #FFB8EBA6;">`JWT`</mark> no es en sí un mecanismo de login: es un **formato** de token. Su atractivo es ser stateless — el servidor confía en los `claims` firmados sin consultar una base de datos. Si la firma se rompe o se elude, se forjan identidades.
- <mark style="background: #FFB8EBA6;">`OAuth`</mark> es **autorización delegada**: permite que una app de terceros acceda a tus recursos en otro servicio sin darle tu contraseña. Es el motor del "Login with...". Se abusa robando tokens de acceso y rompiendo su protección CSRF.
- <mark style="background: #FFB8EBA6;">`SAML`</mark> es SSO empresarial sobre XML firmado. Sus ataques explotan la complejidad del procesamiento de firmas XML (exclusión y wrapping).

Los tres comparten un patrón de fallo: <mark style="background: #FFB86CA6;">confían en datos firmados, y la seguridad colapsa cuando la **verificación de la firma** es débil, opcional o eludible.</mark> Ese es el hilo conductor de todo el sub-tema, empezando por la pieza común: el [[01 - Introducción a JWT|JWT]].

> [!info]+ Fuentes
> - [RFC 7519 — JWT](https://datatracker.ietf.org/doc/html/rfc7519) · [RFC 6749 — OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) · [SAML (OASIS)](https://wiki.oasis-open.org/security/FrontPage)
> - [OWASP — Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
