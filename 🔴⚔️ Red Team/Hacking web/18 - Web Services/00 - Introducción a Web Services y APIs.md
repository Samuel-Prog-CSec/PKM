---
tags:
  - Web/Red-Team
  - Web-Services
  - Introduccion
  - Tipo/Introduccion
Descripción: "Un *web service* es una pieza de software que expone funcionalidad a otras aplicaciones a través de la red, típicamente con XML o JSON sobre HTTP. Permite que sistemas…"
Fecha de actualización: 2026-07-17
Nota previa: ""
Nota siguiente: "[[01 - WSDL - enumeración y descubrimiento]]"
Area: "[[Web Services.base|Web Services]]"
---
---

<mark style="background: #ADCCFFA6;">Un *web service* es una pieza de software que expone funcionalidad a otras aplicaciones a través de la red</mark>, típicamente con XML o JSON sobre HTTP. Permite que sistemas heterogéneos — un Java sobre Linux con Oracle y un C++ sobre Windows con SQL Server — se comuniquen. Este sub-tema cubre el ataque a *web services* clásicos (SOAP/WSDL/XML-RPC), un terreno que las notas de [[00 - Introducción a las API Attacks|API Attacks]] (OWASP API Top 10, orientadas a REST/JSON) no tocan.

# Web Service vs API

No son sinónimos, aunque se solapan:

- Un *web service* **es** un tipo de API; lo contrario no siempre se cumple.
- Un *web service* **necesita red**; una API puede funcionar offline (una librería local es una API).
- Los *web services* suelen usar **SOAP** y codificar en **XML**; las APIs modernas usan REST/JSON, GraphQL, gRPC…

# Aproximaciones y tecnologías

| Tecnología | Codificación | Transporte | Notas |
| - | - | - | - |
| **XML-RPC** | XML | HTTP | RPC simple; `<methodCall>`/`<methodResponse>`. WordPress `xmlrpc.php` ([[04 - Ataques a xmlrpc.php]]) |
| **JSON-RPC** | JSON | HTTP | RPC con JSON; `{"method":..,"params":..,"id":..}` |
| **SOAP** | XML | HTTP/otros | El pesado: define header, body y manejo de errores. Descrito por [[01 - WSDL - enumeración y descubrimiento|WSDL]] |
| **WS-BPEL** | XML | HTTP | SOAP con orquestación de procesos |
| **REST** | XML/JSON | HTTP | El estándar actual; sin WSDL habitualmente |
| **gRPC** | Protobuf | HTTP/2 | API moderna de alto rendimiento (microservicios) |
| **GraphQL** | JSON | HTTP | API moderna de consulta flexible ([[00 - Introducción a GraphQL|GraphQL]]) |

# Anatomía de un mensaje SOAP

SOAP es el que más superficie de ataque ofrece. Un mensaje SOAP es un **sobre XML** con cuatro bloques:

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>...</soap:Header>          <!-- opcional: extensibilidad (WS-Security, etc.) -->
  <soap:Body>                             <!-- requerido: la operación y sus parámetros -->
    <m:GetQuotation xmlns:m="http://xyz.org/quotations">
      <m:QuotationsName>Microsoft</m:QuotationsName>
    </m:GetQuotation>
    <soap:Fault>...</soap:Fault>          <!-- opcional: mensajes de error -->
  </soap:Body>
</soap:Envelope>
```

- **`soap:Envelope`** (requerido) — raíz; diferencia SOAP de XML normal, requiere `namespace`.
- **`soap:Header`** (opcional) — extensibilidad vía módulos SOAP.
- **`soap:Body`** (requerido) — contiene el **procedimiento, parámetros y datos**. Aquí es donde se inyecta.
- **`soap:Fault`** (opcional, dentro de Body) — errores de la llamada.

<mark style="background: #FFB86CA6;">Que el cuerpo SOAP sea XML lo hace vector directo de [[14 - Introducción a XXE|XXE]]</mark> y de inyección XML — cualquier parser mal configurado que procese el `Body` es explotable.

> [!info]+ ¿Sigue vivo SOAP en 2026?
> REST y GraphQL dominan las APIs nuevas, pero <mark style="background: #FF5582A6;">SOAP sigue muy presente en entornos empresariales, banca, salud, gobierno y B2B legacy</mark> — justo donde hay dinero y datos sensibles. Un cazador se topa con SOAP cuando audita integraciones internas, *middleware*, o APIs antiguas de grandes organizaciones. No es lo más común, pero cuando aparece, suele estar mal protegido y poco revisado. (Se afina esta valoración con fuentes en [[05 - Detección y evasión en Web Services]].)

El primer paso al encontrar un servicio SOAP es conseguir su **contrato** — el fichero WSDL: [[01 - WSDL - enumeración y descubrimiento]].
