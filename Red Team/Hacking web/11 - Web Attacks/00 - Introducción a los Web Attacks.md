---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Web-Attacks
  - Tipo/Introduccion
Descripción: "Este módulo agrupa tres ataques que aparecen en casi cualquier aplicación web y que no encajan en la lógica clásica de 'inyección en un sink concreto' (como XSS o SQLi)"
Fecha de actualización: 2026-07-15
Nota previa: ""
Nota siguiente: "[[01 - Introducción a HTTP Verb Tampering]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Este módulo agrupa tres ataques que aparecen en **casi cualquier** aplicación web y que no encajan en la lógica clásica de "inyección en un sink concreto" (como [[00 - Introducción a XSS|XSS]] o [[00 - Introducción a SQL Injection|SQLi]]). Los tres explotan <mark style="background: #ADCCFFA6;">inconsistencias en cómo el servidor y la aplicación tratan las peticiones y las referencias a objetos</mark>, no un fallo de sanitización de una entrada puntual. Son fallos de **arquitectura y control de acceso**, y por eso escapan a muchos escáneres automáticos.

# Los tres ataques

| Ataque | Raíz del fallo | Qué consigue el atacante |
| - | - | - |
| [[01 - Introducción a HTTP Verb Tampering\|HTTP Verb Tampering]] | El servidor/app no maneja **todos** los métodos HTTP de forma coherente | Saltar autenticación o filtros de seguridad |
| [[06 - Introducción a IDOR\|IDOR]] | Falta de **control de acceso** sobre referencias directas a objetos | Acceder a datos/recursos de otros usuarios |
| [[14 - Introducción a XXE\|XXE Injection]] | Parser XML **desactualizado** que procesa entidades externas | Leer archivos locales, `SSRF`, robo de credenciales, `RCE` |

- <mark style="background: #FFB8EBA6;">**HTTP Verb Tampering**</mark>: si la autorización o un filtro se aplican solo a `GET`/`POST` pero el servidor acepta `HEAD`, `PUT`, `OPTIONS`… un método inesperado <mark style="background: #FFB86CA6;">bypassa el control por completo</mark>. Situacional en frameworks modernos, pero muy vivo en APIs y configuraciones legacy.
- <mark style="background: #FFB8EBA6;">**IDOR** (Insecure Direct Object Reference)</mark>: la app expone referencias directas (`?uid=1`, `/documents/Invoice_1.pdf`) y **no verifica** que el objeto pertenezca al usuario. Cambiando el identificador se accede a lo ajeno. Es <mark style="background: #FFB86CA6;">una de las vulnerabilidades más reportadas y mejor pagadas en bug bounty</mark>, porque la explotación es trivial y el impacto (fuga masiva de datos) enorme. Encabeza `A01:2021 – Broken Access Control` de OWASP.
- <mark style="background: #FFB8EBA6;">**XXE** (XML External Entity)</mark>: un parser XML mal configurado resuelve entidades externas definidas por el atacante, permitiendo <mark style="background: #FFB86CA6;">leer archivos del servidor, escanear la red interna (`SSRF`) e incluso ejecutar código</mark>. La lectura del código fuente o de ficheros de configuración convierte una caja negra en un [[Whitebox]] parcial.

# Por qué siguen importando (y qué está desactualizado)

> [!warning]+ El módulo HTB es de 2021
> El material original tiene **más de cuatro años** y no refleja el estado actual de los frameworks ni de las defensas. He modernizado cada sub-tema con las técnicas y herramientas que se usan hoy en pentesting web y bug bounty profesional. Los puntos clave:
> - **XXE** hoy es *menos* frecuente: `libxml2` (PHP), la mayoría de parsers Java (`DocumentBuilderFactory` con `FEATURE_SECURE_PROCESSING`) y .NET modernos <mark style="background: #FFB8EBA6;">deshabilitan las entidades externas por defecto</mark>. Sigue siendo crítico donde hay librerías viejas, SOAP, SAML, `SVG`, `DOCX`/`XLSX` (OOXML) o configuraciones que reactivan `DTD`.
> - **IDOR** es *más* frecuente que nunca por la explosión de APIs REST/GraphQL. En APIs se cataloga como `BOLA` ([[01 - Broken Object Level Authorization (API1)\|API1:2023]]) y `BFLA`.
> - **Verb Tampering** clásico casi ha desaparecido en apps con routing explícito, pero renace vía cabeceras de *method override* (`X-HTTP-Method-Override`) y spoofing de método (`_method`) en Rails/Laravel/Symfony.

La filosofía del módulo es la misma que en [[00 - Introducción a las HTTP Misconfigurations|HTTP Misconfigurations]] o los [[00 - Introducción a los HTTP Attacks|HTTP Attacks]]: atacar la **infraestructura y el control de acceso**, no la lógica de negocio. Los tres se estudian con el mismo esquema: **detectar → explotar → detección/evasión avanzada → herramientas → prevenir**.

## Encaje con el resto del path

IDOR reaparece en [[01 - Broken Object Level Authorization (API1)|API Attacks]] (como `BOLA`), en [[02 - IDOR en GraphQL|GraphQL]] y en [[07 - Second-Order IDOR (whitebox)|Modern Web Exploitation]] (segundo orden). XXE se apoya en el mismo motor XML que [[00 - Inyección XSLT|XSLT injection]] y encadena de forma natural con [[00 - Introducción a los ataques server-side|SSRF]]. Verb Tampering es primo de los [[06 - Introducción a HTTP Request Smuggling|desync attacks]] y suele usarse para habilitar [[00 - Introducción a Command Injection|Command Injection]] u otras inyecciones saltándose el filtro.

## Referencias

- OWASP — [A01:2021 Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/) (IDOR)
- OWASP — [XML External Entity (XXE) Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html)
- PortSwigger Web Security Academy — [Access control](https://portswigger.net/web-security/access-control) y [XXE injection](https://portswigger.net/web-security/xxe)
- HTB Academy — *Web Attacks* (módulo base de estas notas, 2021)
