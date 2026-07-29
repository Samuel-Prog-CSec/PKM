---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSTI
Descripción: "Confirmado que el motor es Jinja2 —el de Flask, y opcional en Django (que además trae su motor nativo, mucho más restringido y sin esta cadena de gadgets)—, la explotación…"
Fecha de actualización: 2026-06-22
Nota previa: "[[01 - Identificación de SSTI]]"
Nota siguiente: "[[03 - Explotación de SSTI - Twig]]"
Area: "[[SSTI.base|SSTI]]"
---
---

Confirmado que el motor es **Jinja2** —el de `Flask`, y opcional en `Django` (que además trae su **motor nativo**, mucho más restringido y sin esta cadena de gadgets)—, la explotación escala de fuga de información a RCE. La idea central: <mark style="background: #ADCCFFA6;">desde el contexto de la plantilla, navegamos los **atributos de los objetos Python** hasta alcanzar funciones peligrosas</mark> (`open`, `os.popen`). Los ejemplos asumen `Flask`; en otros frameworks la sintaxis varía un poco.

> [!example]+ Caso real — Uber Flask/Jinja2 SSTI · $10.000 · [H1 #125980](https://hackerone.com/reports/125980)
> Orange Tsai puso `{{1+1}}` como nombre de perfil en `riders.uber.com` (Node/Express) y recibió un email de notificación con un literal **"2"** — la entrada había cruzado a un servicio en **Flask/Jinja2** (`vault.uber.com`). Confirmó la ejecución con un bucle `{% for c in [1,2,3] %}{{c,c,c}}{% endfor %}` renderizado en el email, y **paró en la prueba de ejecución** sin forzar el RCE. **Lección**: rastrea qué stack expone cada subdominio y prueba si un input en *un* servicio llega a renderizarse en **otro**.

# Fuga de información

Lo primero, sin tocar el sistema de ficheros. En Flask, el objeto `config` lleva toda la configuración —incluida la `SECRET_KEY`—:

```jinja2
{{ config.items() }}
```

<mark style="background: #FF5582A6;">Volcar la `SECRET_KEY` es jugoso por sí solo</mark>: permite **forjar cookies de sesión** de Flask y suplantar a cualquier usuario (las sesiones Flask van firmadas con esa clave, no cifradas). Para empezar a tocar Python, volcamos los *built-ins* disponibles:

```jinja2
{{ self.__init__.__globals__.__builtins__ }}
```

# El gadget: por qué funciona la cadena

Jinja2 no expone `os` ni `open` directamente, pero sí los objetos del contexto. La cadena de atributos los alcanza:

- `self.__init__` → el método de inicialización del objeto de plantilla.
- `.__globals__` → el **diccionario de globales** del módulo donde corre ese código: incluye lo importado y `__builtins__`.
- `.__builtins__` → las funciones *built-in* de Python (`open`, `__import__`, `eval`…). Según el contexto es el **módulo** `builtins` o un **dict**; en ambos casos se llega como atributo (`.__builtins__.open`) o como clave (`.__builtins__['open']`).

Desde ahí, todo Python está a un paso.

# Local File Inclusion (LFI)

Con `open` (vía `__builtins__`, no se puede llamar directa) leemos ficheros:

```jinja2
{{ self.__init__.__globals__.__builtins__.open("/etc/passwd").read() }}
```

<mark style="background: #FFB86CA6;">Leer el código fuente de la app desde aquí</mark> revela rutas, credenciales y otros fallos —igual de valioso que en [[01 - Local File Inclusion (LFI)|LFI clásica]]—.

# Remote Code Execution (RCE)

El objetivo final. Con la librería `os` (importándola si no está ya) y `popen`/`system`:

```jinja2
{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}
```

`__import__('os')` carga el módulo aunque la app no lo importara; `popen('id').read()` ejecuta y devuelve la salida. <mark style="background: #8000E1A6;">Esto es RCE como el usuario del servicio web</mark> —punto de partida para reverse shell y escalada—. Para una shell estable, sustituye `id` por un one-liner de reverse shell (ver [[01 - Explotación básica - web shells y reverse shells|reverse shells]]).

> [!tip]+ Gadgets más cortos y a prueba de filtros
> La cadena `self.__init__.__globals__...` es la "de libro", pero verbosa y llena de guiones bajos que un filtro puede bloquear. En la práctica se usan gadgets más limpios —`{{ cycler.__init__.__globals__.os.popen('id').read() }}`, `{{ lipsum.__globals__.os.popen('id').read() }}`, `{{ request.application.__globals__... }}`— y técnicas para esquivar el `SandboxedEnvironment` y los filtros de caracteres. Todo eso, en [[04 - Evasión de filtros y sandbox en SSTI|evasión]].

> [!info]+ Fuentes
> - [PortSwigger — SSTI (Jinja/Python)](https://portswigger.net/web-security/server-side-template-injection/exploiting) · [HackTricks — Jinja2 SSTI](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection/jinja2-ssti)
> - [PayloadsAllTheThings — SSTI (Jinja2)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md#jinja2)

El mismo recorrido —info → LFI → RCE— en el otro motor mayoritario, esta vez en PHP: [[03 - Explotación de SSTI - Twig]].
