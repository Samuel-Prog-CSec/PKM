---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Fecha de actualización: 2026-07-15
Nota previa: ""
Nota siguiente: "[[01 - Broken Object Level Authorization (API1)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Las <mark style="background: #ADCCFFA6;">`API` (Application Programming Interfaces) son las reglas y protocolos que dictan cómo se comunican dos sistemas</mark>. Las web API son el pegamento de casi toda arquitectura moderna (móvil, SPA, microservicios, integraciones B2B) y, por su ubicuidad y su exposición directa de datos y funciones, una <mark style="background: #FFB86CA6;">superficie de ataque enorme</mark>. Este módulo recorre el `OWASP API Security Top 10 (2023)` sobre una API `REST` real.

# Estilos de API

| Estilo | Características | Nota ofensiva |
| - | - | - |
| **REST** | El más común. Cliente-servidor, **stateless**, métodos HTTP (`GET`/`POST`/`PUT`/`DELETE`), respuestas `JSON`/`XML` | Foco de este módulo |
| **SOAP** | Basado en `XML`, muy estandarizado (seguridad, transacciones) | Módulo propio: [[00 - Introducción a Web Services y APIs\|Web Services]]; superficie de [[14 - Introducción a XXE\|XXE]] |
| **GraphQL** | Endpoint único, query tipada; el cliente pide **exactamente** los campos que necesita | Módulo propio: [[00 - Introducción a GraphQL\|Attacking GraphQL]] |
| **gRPC** | `Protocol Buffers`, alto rendimiento, microservicios | Requiere proto/reflection para atacar |

El módulo ataca una API **REST**, pero <mark style="background: #FFB8EBA6;">las mismas vulnerabilidades aparecen en los demás estilos</mark> — la lógica de autorización rota no depende del transporte.

# OWASP API Security Top 10 (2023)

La taxonomía de referencia para pentest de APIs. Cada riesgo se explota en su nota:

| Riesgo | Qué es |
| - | - |
| [[01 - Broken Object Level Authorization (API1)\|API1 · BOLA]] | Acceder a objetos de otros usuarios (es el [[06 - Introducción a IDOR\|IDOR]] de las APIs) |
| [[02 - Broken Authentication (API2)\|API2 · Broken Authentication]] | Bypass o debilidad de los mecanismos de autenticación |
| [[03 - Broken Object Property Level Authorization (API3)\|API3 · BOPLA]] | Leer/modificar propiedades de objeto que no deberías (mass assignment + excessive data exposure) |
| [[04 - Unrestricted Resource Consumption (API4)\|API4 · Resource Consumption]] | Sin límites de recursos → DoS y coste económico |
| [[05 - Broken Function Level Authorization (API5)\|API5 · BFLA]] | Invocar funciones/roles que no te corresponden |
| [[06 - Unrestricted Access to Sensitive Business Flows (API6)\|API6 · Business Flows]] | Abusar de flujos de negocio (comprar todo el stock, spam) |
| [[07 - Server-Side Request Forgery (API7)\|API7 · SSRF]] | La API pide URLs sin validar → [[00 - Introducción a los ataques server-side\|SSRF]] |
| [[08 - Security Misconfiguration (API8)\|API8 · Misconfiguration]] | Errores de configuración, incluidas inyecciones |
| [[09 - Improper Inventory Management (API9)\|API9 · Inventory]] | Versiones/entornos viejos y no documentados expuestos |
| [[10 - Unsafe Consumption of APIs (API10)\|API10 · Unsafe Consumption]] | Confiar ciegamente en APIs de terceros que consumimos |

> [!important]+ BOLA, BFLA y BOPLA dominan
> Las tres vulnerabilidades de **autorización** (API1 BOLA, API5 BFLA, API3 BOPLA) son, con diferencia, las más frecuentes y rentables en bug bounty de APIs. Si vienes de [[06 - Introducción a IDOR|IDOR]], BOLA es literalmente lo mismo a nivel de objeto, y BFLA su versión a nivel de función. Domínalas antes que el resto.

# El laboratorio: Inlanefreight E-Commerce Marketplace

Una API REST **multi-tenant** con control de acceso `RBAC`. Detalles operativos que usaremos en todas las notas:

- <mark style="background: #FFB86CA6;">Autenticación por `JWT`</mark>: te logueas en un endpoint de sign-in y usas el token como `Authorization: Bearer <JWT>`.
- **Swagger UI** en la ruta `/swagger` (añádela tras el puerto del target): documenta los 60+ endpoints y permite invocarlos. Es el mapa de la superficie.
- **Roles = nombres de endpoint**: el rol `Suppliers_GetAll` autoriza el endpoint `/api/v1/suppliers`. Esta convención facilita razonar sobre qué "debería" poder hacer cada usuario — y detectar cuándo puede hacer más.
- **Dos tenants**: cuentas `@pentestercompany.com` = suppliers; `@hackthebox.com` = customers. La segregación entre tenants es justo lo que romperemos.

> [!info]+ Pentest de API ≠ pentest web clásico
> No hay UI que navegar: el trabajo empieza por **descubrir la superficie** (Swagger/OpenAPI, `/api-docs`, colecciones de Postman, JS del front) y por **entender el modelo de autorización** (roles, tenants, claims del JWT). Herramientas como Postman, `ffuf`, `kiterunner` y Burp reemplazan al navegador. Todo esto se detalla en [[11 - Detección y evasión en APIs|Detección]] y [[12 - Herramientas para pentesting de APIs|Herramientas]].

Empezamos por la reina de las vulnerabilidades de API: [[01 - Broken Object Level Authorization (API1)|BOLA]].

## Referencias

- OWASP — [API Security Top 10 (2023)](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)
- OWASP — [API Security Project](https://owasp.org/www-project-api-security/)
- Corey Ball — *Hacking APIs* (No Starch Press, referencia moderna del área)
- HTB Academy — *API Attacks* (base de estas notas, 2024)
