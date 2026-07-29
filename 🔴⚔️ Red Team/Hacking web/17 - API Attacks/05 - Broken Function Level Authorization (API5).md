---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Descripción: "Una API es vulnerable a BFLA (Broken Function Level Authorization) si permite a usuarios sin privilegios invocar endpoints privilegiados"
Fecha de actualización: 2026-07-15
Nota previa: "[[04 - Unrestricted Resource Consumption (API4)]]"
Nota siguiente: "[[06 - Unrestricted Access to Sensitive Business Flows (API6)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Una API es vulnerable a `BFLA` (Broken Function Level Authorization) si <mark style="background: #ADCCFFA6;">permite a usuarios sin privilegios invocar endpoints privilegiados</mark>. La diferencia con [[01 - Broken Object Level Authorization (API1)|BOLA]] es sutil pero importante:

- <mark style="background: #FFB8EBA6;">**BOLA**</mark>: estás autorizado a usar el endpoint, pero accedes a **objetos** de otros.
- <mark style="background: #FFB8EBA6;">**BFLA**</mark>: **no** estás autorizado a usar el endpoint en absoluto (te falta el rol/función), pero puedes igualmente.

En el lab: `CWE-200: Exposure of Sensitive Information to an Unauthorized Actor` (el CWE que asigna HTB a este ejercicio). Matiz: `CWE-200` describe la **consecuencia** (fuga de información); la clase de vulnerabilidad —un fallo de autorización a nivel de función— corresponde propiamente a `CWE-285 (Improper Authorization)` o `CWE-862 (Missing Authorization)`.

# Escenario

Como customer (`htbpentester9@hackthebox.com`), buscamos endpoints que **requieran** autorización pero no la comprueben. Bajo el grupo *Products*, el endpoint `/api/v1/products/discounts` documenta que exige el rol `ProductDiscounts_GetAll`. Consultamos nuestros roles con `/api/v1/roles/current-user`:

```json
[]
```

<mark style="background: #FFB86CA6;">No tenemos ningún rol asignado</mark>. Aun así, invocamos el endpoint:

```http
GET /api/v1/products/discounts HTTP/1.1
Authorization: Bearer <JWT_sin_roles>
```

Y devuelve **todos** los descuentos de productos. <mark style="background: #FF5582A6;">Los desarrolladores documentaron que solo `ProductDiscounts_GetAll` debía acceder, pero no implementaron la comprobación `RBAC`</mark> en el código. La autorización existía "en el papel" (Swagger) pero no en el backend.

# Cazar BFLA en un pentest

BFLA es de las vulnerabilidades más productivas en APIs porque la superficie es enorme. Estrategia:

1. <mark style="background: #8000E1A6;">**Enumera todos los endpoints** con dos identidades</mark>: uno privilegiado (o la documentación) y uno sin privilegios. Invoca cada endpoint privilegiado con el token de bajo privilegio y observa si responde.
2. **Adivina endpoints** por convención de nombres: si existe `/api/v1/users/{id}`, prueba `/api/v1/admin/users`, `/api/v1/users/{id}/delete`, `DELETE /api/v1/users/{id}`.
3. <mark style="background: #FFB86CA6;">**BFLA por método (verb tampering)**</mark>: el control puede existir para `GET` pero no para `POST`/`PUT`/`DELETE`. Cambia el verbo — es el mismo bug que el [[04 - Detección, evasión y prevención de Verb Tampering|HTTP Verb Tampering]] aplicado a APIs.
4. **Versiones viejas**: `/api/v1/` puede carecer del control que sí tiene `/api/v2/` (o al revés). Ver [[09 - Improper Inventory Management (API9)|Improper Inventory Management]].

> [!tip]+ Automatización
> [[13 - Herramientas para IDOR|Autorize y Auth Analyzer]] cazan BFLA igual que BOLA/IDOR: reproducen cada petición del usuario privilegiado con la sesión del no privilegiado y marcan las que **no** fueron bloqueadas. Es el primer barrido en cualquier pentest de API.

# Prevención

El endpoint debe **imponer la comprobación de autorización a nivel de código**: verificar que el usuario tiene el rol `ProductDiscounts_GetAll` antes de procesar la petición. La documentación/Swagger **no** es un control de seguridad — la denegación por defecto debe estar en el backend, para **todos** los métodos y versiones.

Siguiente: [[06 - Unrestricted Access to Sensitive Business Flows (API6)|abuso de flujos de negocio]].

## Referencias

- OWASP — [API5:2023 Broken Function Level Authorization](https://owasp.org/API-Security/editions/2023/en/0xa5-broken-function-level-authorization/)
- MITRE — [CWE-200](https://cwe.mitre.org/data/definitions/200.html)
- HTB Academy — *API Attacks* (base, 2024)
