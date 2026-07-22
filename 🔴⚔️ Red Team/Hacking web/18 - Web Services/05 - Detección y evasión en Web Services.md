---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[04 - Ataques a xmlrpc.php]]"
Nota siguiente: "[[06 - Arsenal de herramientas para Web Services]]"
Area: "[[Web Services.base|Web Services]]"
---
---

SOAP/WSDL es tecnología *legacy*, pero <mark style="background: #FF5582A6;">legacy no es lo mismo que muerto — es "poco auditado"</mark>. REST/GraphQL/gRPC dominan lo nuevo, pero SOAP sigue moviendo flujos críticos en **banca, seguros, telecomunicaciones, gobierno, salud y ERP (SAP)** ([Levo.ai](https://www.levo.ai/resources/blogs/soap-api-security-testing)). Y ahí está la oportunidad: <mark style="background: #FFB86CA6;">la mayoría de escáneres automáticos no parsean bien SOAP</mark> (WSDL, WS-Security, canonicalización XML), así que estos endpoints quedan sin testear. Si encuentras un `?wsdl`, suele ser terreno virgen y de alto valor.

# Detectar un web service

Dónde buscar SOAP/WSDL en un objetivo:

- **Sufijos de query**: `?wsdl`, `?WSDL`, `?disco` (DISCO de .NET), `?singleWsdl` (WCF).
- **Extensiones/rutas**: `.asmx?wsdl` (ASP.NET), `.svc?wsdl` (WCF), `/axis2/services/` y `/services/listServices` (Apache Axis2).
- **Google dorking**: `inurl:?wsdl`, `filetype:wsdl` — los buscadores indexan WSDLs expuestos ([SecureLayer7](https://blog.securelayer7.net/owasp-top-10-pentesting-mitigating-soap-service-risks/)).
- **En el tráfico**: peticiones con `Content-Type: text/xml` (o `application/soap+xml`) y cabecera `SOAPAction` delatan un servicio SOAP aunque no veas el WSDL.

> [!info]+ UDDI está muerto
> El registro público UDDI (IBM/Microsoft/SAP) se **cerró en 2006**. La "fase UDDI" del material clásico es historia; como mucho, algún registro interno en grandes empresas. Trátalo como casilla a marcar, no como técnica. La enumeración real hoy es fuzzing de rutas + dorks + [[01 - WSDL - enumeración y descubrimiento|análisis del WSDL]].

# La superficie que los escáneres no ven

Lo que hace a SOAP jugoso es que su superficie es **XML-céntrica** y distinta de REST:

- <mark style="background: #ADCCFFA6;">**XXE**: el cuerpo SOAP es XML → cualquier parámetro es punto de inyección de entidades externas</mark> ([[14 - Introducción a XXE|XXE en Web Attacks]]). El vector #1.
- **SOAPAction Spoofing**: bypass de autorización cuando el perímetro enruta por la cabecera y el backend ejecuta la operación del `Body` ([[02 - SOAP Action Spoofing]]).
- **XML Signature Wrapping (XSW)**: en WS-Security, la firma referencia *qué* se firma pero no *dónde* está en el árbol; se reubica el elemento firmado y se inyecta uno malicioso con el ID que la app procesa, manteniendo la firma válida → bypass de autenticación ([IBM: XSW](https://www.ibm.com/think/topics/xml-signature-wrapping)). Sigue vivo: [CoreWCF GHSA-gqv6-pwcg-87r8](https://github.com/CoreWCF/CoreWCF/security/advisories/GHSA-gqv6-pwcg-87r8).
- **UsernameToken sin nonce/timestamp** → **replay attacks**.

# Evasión

- **WAFs y XML**: muchos WAF inspeccionan mal los cuerpos XML/SOAP — payloads de XXE o inyección que bloquearían en un form pasan dentro de un `<soap:Body>`. Convertir una petición JSON a `Content-Type: text/xml` (con el [[06 - Arsenal de herramientas para Web Services|Content Type Converter de Burp]]) es una vía para colar XXE donde la app "no usaba XML".
- **Rate-limit por cabecera**: como en cualquier API, cabeceras como `X-Forwarded-For`/`X-Forwarded-IP` a veces resetean el contador o pasan una allowlist mal implementada (`in_array($_SERVER['HTTP_X_FORWARDED_FOR'], $whitelist)`).
- **Fuzzing de operaciones ocultas**: el WSDL lista operaciones que la UI nunca llama (`getPatientSSN`, `admin_*`). Si falta autorización por operación, se invocan directamente — caso real documentado en salud ([SecureLayer7](https://blog.securelayer7.net/owasp-top-10-pentesting-mitigating-soap-service-risks/)).

> [!warning]+ La caza de SOAP en bug bounty
> No lo verás en scopes de startups/SaaS modernas. <mark style="background: #8000E1A6;">Aparece en programas *enterprise* de scope amplio</mark>: banca, gobierno, telecom, subdominios *legacy* de empresas adquiridas, *middleware* de back-office y *backends* de apps móviles que aún hablan SOAP. Cuando aparece, suele estar mal protegido — precisamente porque el tooling automático no llega.

El instrumental concreto — Burp Wsdler, SoapUI/ReadyAPI, `python-zeep` — en [[06 - Arsenal de herramientas para Web Services]].
