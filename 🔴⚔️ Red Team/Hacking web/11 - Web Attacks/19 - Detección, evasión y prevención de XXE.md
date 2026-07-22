---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - XXE
Fecha de actualización: 2026-07-15
Nota previa: "[[18 - Exfiltración de datos ciega (OOB)]]"
Nota siguiente: "[[20 - Herramientas para XXE]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Nota dedicada a **encontrar** superficie XXE (que hoy está más escondida), **evadir** los WAF y parsers endurecidos, y **prevenir**. Como XXE ha cambiado mucho desde 2021, la detección de dónde vive el XML y la evasión son la parte que HTB no cubre y donde está el valor real.

# Detección: ¿dónde vive el XML hoy?

El XXE evidente (un formulario que manda XML plano) casi ha desaparecido. La superficie moderna está **escondida** en formatos que son XML por dentro:

| Vector | Dónde mirar |
| - | - |
| `Content-Type` | Cambiar `application/json` → `application/xml`/`text/xml` en cualquier endpoint y ver si lo acepta |
| **SOAP / WSDL** | APIs legacy, servicios B2B — XML por diseño |
| **SAML** | El `SAMLResponse` es XML en base64: punto clásico de XXE en SSO federado |
| **Subida de ficheros** | **SVG** (imágenes), **OOXML** (`.docx`/`.xlsx`/`.pptx` son ZIP con XML: mira `[Content_Types].xml`), **PDF**, `.svg` en avatares |
| **RSS/Atom, XML-RPC, sitemaps** | Feeds y endpoints que parsean XML de terceros |

Confirmación: inyecta una entidad interna (¿se refleja?), luego externa. <mark style="background: #FF5582A6;">Para el caso ciego —el más común hoy— la detección fiable es un canario OOB</mark>: apunta una entidad a un dominio de **Burp Collaborator** o **interactsh** y observa el callback DNS/HTTP. Si el servidor resuelve tu dominio, procesa entidades externas → XXE confirmado aunque no veas ningún dato.

# Evasión de WAF y parsers endurecidos

Cuando hay un WAF filtrando `SYSTEM`/`DOCTYPE` o el parser está a medio endurecer, estas técnicas (documentadas por **Sharoglazov**, **Wallarm** y **PayloadsAllTheThings**) abren camino:

## Doble encoding (UTF-16 / UTF-7)

Muchos WAF solo inspeccionan `ASCII/UTF-8`. Los parsers XML **deben** soportar varios encodings y cambian al que declara la cabecera XML **antes** de validar. <mark style="background: #FFB86CA6;">Codificando el payload en `UTF-16` (o combinando dos encodings), el WAF ve ruido pero el parser lo procesa</mark> — la técnica *"Evil XML with Two Encodings"* de Arseniy Sharoglazov:

```shell-session
$ iconv -f UTF-8 -t UTF-16BE payload.xml > payload-utf16.xml
```

## Reutilización de DTDs locales (error-based sin OOB)

Si el tráfico saliente está bloqueado (no hay OOB), aún se puede hacer error-based usando **DTDs que ya existen** en el sistema y redefiniendo sus parameter entities. Ficheros habituales en Linux:

```text
/usr/share/xml/fontconfig/fonts.dtd
/usr/share/xml/svg/svg10.dtd  /  svg11.dtd
/usr/share/yelp/dtd/docbookx.dtd
```

Cargas el DTD local, redifines una de sus entidades para incluir tu payload y provocas un error que filtra el fichero. <mark style="background: #8000E1A6;">Es la técnica clave cuando el servidor no tiene salida a internet</mark>.

## Otras evasiones

- **HTML-encodear** la declaración de la entidad externa para saltar filtros de palabras clave (`SYSTEM`, `ENTITY`).
- Entregar el payload **dentro de un fichero** que el WAF no inspecciona: SVG subido como avatar, `[Content_Types].xml` de un `.docx`.
- Variar el esquema (`file://` vs `netdoc://` vs `jar://` en Java) y la ubicación del DTD (interno vs externo).

# Prevención

<mark style="background: #ADCCFFA6;">La raíz del XXE son librerías XML desactualizadas o mal configuradas</mark>, no (principalmente) código inseguro. Por eso prevenirlo es más fácil que otras vulns: se arregla en la configuración del parser.

## Actualizar y configurar el parser

- Usar librerías XML actuales. En PHP, `libxml_disable_entity_loader()` está **deprecado desde PHP 8** (ya no hace falta: las entidades externas van desactivadas por defecto).
- **Deshabilitar explícitamente**: referencias a DTDs personalizados, entidades externas, **parameter entities**, `XInclude`, y bucles de referencia de entidades. En Java, lo canónico:

```java
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setXIncludeAware(false);
dbf.setExpandEntityReferences(false);
```

- **Actualizar también** los procesadores de documentos que parsean XML: SOAP, procesadores de SVG, de PDF, de OOXML. El XXE se cuela por ahí.
- **Deshabilitar la muestra de errores** de runtime en producción (mata el error-based).

## Defensa en profundidad

- Preferir formatos **`JSON`/`YAML`** y APIs `REST` sobre `SOAP`/XML cuando sea posible — elimina la clase de bug de raíz.
- **WAF** como **capa adicional**, nunca única: como muestran las evasiones de arriba, <mark style="background: #FFB8EBA6;">un WAF de XXE siempre es evitable</mark>; el back-end debe estar seguro por sí mismo.

> [!info]+ Resumen de prioridades defensivas
> **(1)** Deshabilitar DTD/entidades externas en el parser (una línea, mata casi todo). **(2)** Actualizar librerías y procesadores de documentos. **(3)** Ocultar errores de runtime. **(4)** WAF como red de seguridad. El paso 1 por sí solo neutraliza la inmensa mayoría de XXE.

Cerramos con el [[20 - Herramientas para XXE|arsenal de herramientas]] para automatizar todo lo visto.

## Referencias

- OWASP — [XXE Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html) (configuración segura por lenguaje)
- Arseniy Sharoglazov — [Evil XML with two encodings](https://mohemiv.com/all/evil-xml/) (bypass UTF-16)
- Wallarm — [XXE that can bypass WAF protection](https://lab.wallarm.com/xxe-that-can-bypass-waf-protection-98f679452ce0/)
- YesWeHack — [The ultimate bug bounty guide to exploiting XXE](https://www.yeswehack.com/learn-bug-bounty/xml-external-entity-guide-xxe)
- Ambrotd — [XXE-Notes (WAF bypass)](https://github.com/Ambrotd/XXE-Notes)

> [!important]+ XXE en APIs y SOAP modernas
> Todo cuerpo XML es un vector XXE — incluido **SOAP** (el `<soap:Body>` es XML) y cualquier API que parsee XML. Dos técnicas modernas clave: (1) con el **Content Type Converter de Burp**, reenvía una petición **JSON como `Content-Type: text/xml`**; si el servidor la parsea como XML, tienes XXE donde la app "no usaba XML". (2) Cuando **no controlas el `DOCTYPE`** (tu input solo se inserta en un XML que construye el servidor), usa **XInclude**: `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>`. Fuente: [PortSwigger — XXE](https://portswigger.net/web-security/xxe). Contexto web-service completo en [[05 - Detección y evasión en Web Services]].
