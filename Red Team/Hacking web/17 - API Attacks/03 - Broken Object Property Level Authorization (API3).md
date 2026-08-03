---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Descripción: "BOPLA (Broken Object Property Level Authorization) agrupa dos subclases que atacan las propiedades de un objeto, no el objeto entero"
Fecha de actualización: 2026-07-15
Nota previa: "[[02 - Broken Authentication (API2)]]"
Nota siguiente: "[[04 - Unrestricted Resource Consumption (API4)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

`BOPLA` (Broken Object Property Level Authorization) agrupa dos subclases que atacan las **propiedades** de un objeto, no el objeto entero:

- <mark style="background: #ADCCFFA6;">**Excessive Data Exposure**</mark>: la API devuelve propiedades sensibles que el usuario no debería ver.
- <mark style="background: #ADCCFFA6;">**Mass Assignment**</mark>: la API permite **modificar** propiedades fuera del alcance autorizado.

Es la versión "a nivel de propiedad" del control de acceso roto, y ambas subclases nacen de la misma causa: <mark style="background: #FFB86CA6;">exponer el modelo de dominio completo en vez de un DTO acotado</mark>.

# Excessive Data Exposure (CWE-213)

Como customer, tenemos los roles `Suppliers_Get`/`Suppliers_GetAll`. Es normal que un marketplace deje ver datos de suppliers. Pero `GET /api/v1/suppliers` devuelve, además de `id`, `companyID` y `name`, los campos `email` y `phoneNumber`:

```json
{
  "id": "...", "companyID": "...", "name": "ACME Corp",
  "email": "sales@acme.htb", "phoneNumber": "+34..."
}
```

<mark style="background: #FF5582A6;">Esos campos sensibles no deberían llegar al customer</mark>: con ellos puede contactar al supplier directamente y comprar fuera del marketplace (a precio con descuento), saltándose la comisión. Impacto económico directo para el negocio.

**Prevención**: el endpoint debe devolver un `DTO` (Data Transfer Object) con **solo** los campos pensados para el customer, no el modelo entero que usa la base de datos.

# Mass Assignment (CWE-915)

Como supplier con rol `SupplierCompanies_Update`, consultamos nuestra empresa con `GET /api/v1/supplier-companies/current-user` y vemos el campo `isExemptedFromMarketplaceFee: 0` (pagamos comisión). El `PATCH /api/v1/supplier-companies` permite enviar ese campo:

```http
PATCH /api/v1/supplier-companies HTTP/1.1
Authorization: Bearer <JWT>
Content-Type: application/json

{ "isExemptedFromMarketplaceFee": 1 }
```

Éxito. Al reconsultar, `isExemptedFromMarketplaceFee` es `1`: <mark style="background: #8000E1A6;">nos hemos eximido de la comisión que paga nuestra empresa por cada venta</mark>. El endpoint deja actualizar un campo que el supplier no debería tocar.

> [!important]+ Mass assignment: el mismo bug que en la web
> Esto es exactamente lo que explotamos en [[11 - Encadenamiento de IDOR|el IDOR de Web Attacks]] al ponernos `role: web_admin`. El patrón: la API vincula automáticamente los campos del JSON al objeto del modelo (`model binding`), incluidos los que no salen en el formulario. <mark style="background: #FFB8EBA6;">Prueba siempre a enviar campos "extra"</mark> (`isAdmin`, `role`, `verified`, `balance`, `price`, `discount`) y compara la respuesta del `GET` con lo que el `PATCH`/`POST` acepta.

**Prevención**: un `DTO` de entrada dedicado que incluya **solo** los campos que el usuario puede modificar. Nunca hacer binding directo del request al modelo de dominio.

# Cómo cazarlo

1. Para **Excessive Data Exposure**: inspecciona cada respuesta buscando campos que no se usan en el front (`email`, `hash`, `ssn`, `internalNotes`, flags booleanos). La API a menudo devuelve más de lo que la UI muestra — el front filtra, la API no.
2. Para **Mass Assignment**: enumera los campos de un objeto con un `GET`, y en el `PUT`/`PATCH`/`POST` **añade** los campos sensibles que viste. Herramientas como el *Param Miner* de Burp o `Arjun` ayudan a descubrir propiedades ocultas aceptadas.

Siguiente: [[04 - Unrestricted Resource Consumption (API4)|Unrestricted Resource Consumption]].

## Referencias

- OWASP — [API3:2023 BOPLA](https://owasp.org/API-Security/editions/2023/en/0xa3-broken-object-property-level-authorization/)
- MITRE — [CWE-213](https://cwe.mitre.org/data/definitions/213.html) · [CWE-915](https://cwe.mitre.org/data/definitions/915.html)
- HTB Academy — *API Attacks* (base, 2024)
