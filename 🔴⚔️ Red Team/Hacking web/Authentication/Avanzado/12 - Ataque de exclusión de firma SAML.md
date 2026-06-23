---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - SAML
Fecha de actualización: 2026-06-23
Nota previa: "[[11 - Introducción a SAML]]"
Nota siguiente: "[[13 - Ataque de envoltura de firma XML (XSW)]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

El ataque SAML más simple y devastador cuando funciona. <mark style="background: #ADCCFFA6;">La `signature exclusion` explota un SP que solo verifica la firma **si está presente**, y acepta la respuesta por defecto cuando no la hay.</mark> Quitas la firma, manipulas la assertion libremente y te haces pasar por quien quieras.

# El punto de partida

Tras autenticarte legítimamente, el SP te muestra tus datos, sacados de la [[11 - Introducción a SAML|assertion firmada]]. Para suplantar a `admin`, hay que cambiar el atributo de la assertion:

```xml
<saml:Attribute Name="name">
  <saml:AttributeValue xsi:type="xs:string">htb-stdnt</saml:AttributeValue>  <!-- → admin -->
</saml:Attribute>
```

Pero al editar el XML, la firma deja de cuadrar y el SP rechaza la respuesta con `Invalid SAML Response`. Editar sin más no basta.

# La exclusión

El fallo: un SP mal configurado **salta la verificación entera** si la respuesta no contiene elemento de firma. El ataque:

1. Captura el `SAMLResponse`, hazle **URL-decode** y **Base64-decode** para obtener el XML.
2. Manipula el `AttributeStatement` (`htb-stdnt` → `admin`, el `id` al del admin).
3. <mark style="background: #FF5582A6;">Elimina **todos** los elementos `ds:Signature`</mark> del XML — puede haber varios (sobre la Response y sobre la Assertion). Hay que quitarlos todos.
4. Re-codifica: **Base64** y luego **URL-encode**, y reemplaza el `SAMLResponse` en la petición.

```http
POST /acs.php HTTP/1.1
Host: academy.htb

SAMLResponse=PHNhbW...%2b&RelayState=%2Facs.php   ← sin firma, con name=admin
```

Si el SP es vulnerable, <mark style="background: #FFB86CA6;">acepta la respuesta sin firma y te autentica como `admin`.</mark>

> [!warning]+ Quita TODAS las firmas
> El error de ejecución más común: dejar una `ds:Signature` olvidada (la de la Response cuando solo mirabas la de la Assertion, o viceversa). Si queda **una** firma y no cuadra con tu XML manipulado, el SP rechaza todo. Localiza cada `ds:Signature` y elimínalo por completo, incluido su contenido.

# Por qué ocurre

Es un fallo de lógica `fail-open`: <mark style="background: #8000E1A6;">"verifica la firma si la hay" en vez de "exige una firma válida siempre".</mark> La ausencia de firma debería ser un rechazo inmediato, no un pase libre. La defensa es trivial de enunciar (firma **obligatoria** y válida) pero se incumple en implementaciones caseras de SAML. Cuando el SP **sí** exige firma pero su verificación es manipulable, se pasa al [[13 - Ataque de envoltura de firma XML (XSW)|signature wrapping]].

> [!info]+ Fuentes
> - [PortSwigger — SAML signature exclusion](https://portswigger.net/web-security/saml)
> - [OWASP — SAML Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html)
