---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - SAML
Fecha de actualización: 2026-06-23
Nota previa: "[[10 - Vulnerabilidades adicionales y prevención OAuth]]"
Nota siguiente: "[[12 - Ataque de exclusión de firma SAML]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

<mark style="background: #ADCCFFA6;">`SAML` (Security Assertion Markup Language) es un estándar XML para intercambiar autenticación y autorización entre partes, base del SSO empresarial.</mark> La identidad viaja en documentos XML **firmados digitalmente**. Toda su seguridad descansa en esa firma — y sus ataques explotan la complejidad de verificar firmas sobre XML.

# Componentes

| Componente | Rol |
| - | - |
| `Identity Provider (IdP)` | Autentica al usuario y emite las assertions firmadas (`sso.htb`) |
| `Service Provider (SP)` | Ofrece el recurso; confía en las assertions del IdP (`academy.htb`) |
| `SAML Assertion` | El XML con la info de autenticación/autorización del usuario |

# El flujo

John quiere acceder al SP `academy.htb` con sus credenciales de `sso.htb`:

![Flujo SAML: el usuario accede al SP, que lo redirige al IdP; el usuario se autentica, el IdP firma una assertion y la envía vía el navegador al SP, que la verifica y concede el recurso.](https://academy.hackthebox.com/storage/modules/259/Diagram7.png)

1. John accede a `academy.htb` (SP).
2. Al no estar autenticado, el SP lo redirige al IdP con un `AuthnRequest`.
3. John se autentica en `sso.htb` (IdP).
4. El IdP genera una **assertion firmada** y la manda al navegador, que la reenvía al SP.
5. El SP **verifica** la assertion.
6-7. Verificada, John accede al recurso sin más autenticación.

<mark style="background: #FFB8EBA6;">El paso 4 es la clave del ataque</mark>: la assertion pasa **por el navegador del usuario** de camino al SP. Es decir, por las manos del atacante, que puede interceptarla y manipularla antes de que llegue al SP.

# La assertion: lo que el SP cree

El `AuthnRequest` (SP→IdP) lleva `Destination`, `AssertionConsumerServiceURL` (a dónde responder) e `Issuer`. Pero lo jugoso es la **assertion** que devuelve el IdP:

```xml
<saml:Assertion ID="_1234567890" Version="2.0">
  <saml:Issuer>http://sso.htb/idp/</saml:Issuer>
  <saml:Subject>
    <saml:NameID Format="...emailAddress">johndoe@hackthebox.htb</saml:NameID>
  </saml:Subject>
  <saml:AttributeStatement>
    <saml:Attribute Name="username"><saml:AttributeValue>john</saml:AttributeValue></saml:Attribute>
    <saml:Attribute Name="email"><saml:AttributeValue>john@hackthebox.htb</saml:AttributeValue></saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
```

- `saml:Subject` / `NameID`: identifica al usuario.
- <mark style="background: #FFB86CA6;">`saml:AttributeStatement`</mark>: los atributos (username, email, rol) que el SP usa para autorizar. **El objetivo a manipular**: cambiar `username` de `john` a `admin`.

La assertion se transporta como `SAMLResponse`, codificada en **Base64 y luego URL-encoding**, en un POST al SP:

```http
POST /acs.php HTTP/1.1
Host: academy.htb

SAMLResponse=PHNhbW...%3d&RelayState=%2Facs.php
```

> [!important]+ El patrón de todos los ataques SAML
> Manipular el `AttributeStatement` (poner `admin`) es trivial: decodificas, editas, recodificas. <mark style="background: #8000E1A6;">Lo único que lo impide es la firma `ds:Signature`.</mark> Por eso los dos ataques canónicos —[[12 - Ataque de exclusión de firma SAML|exclusión]] y [[13 - Ataque de envoltura de firma XML (XSW)|wrapping]]— no rompen la firma: la **eluden**, haciendo que el SP lea datos no firmados creyendo que están protegidos. Es el mismo principio que en [[02 - Ataques a la verificación de firma JWT|JWT]]: el fallo está en *cómo* se verifica, no en la cripto.

> [!info]+ Fuentes
> - [SAML 2.0 (OASIS)](https://wiki.oasis-open.org/security/FrontPage) · [PortSwigger — SAML](https://portswigger.net/web-security/saml)
> - [OWASP — SAML Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html)
