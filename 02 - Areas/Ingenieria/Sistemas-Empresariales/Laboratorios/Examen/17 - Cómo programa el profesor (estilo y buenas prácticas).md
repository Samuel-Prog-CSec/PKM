---
tags:
  - SIE/Laboratorio
  - SIE/Examen
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[16 - Informes QWeb]]"
Nota siguiente: "[[18 - Filmoteca paso a paso]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Cómo programa el profesor (estilo y buenas prácticas)

El que corrige el examen es tu profesor. Conviene que tu entrega "suene" como su código. Esta nota destila su estilo a partir de sus fuentes reales: el guion de la Práctica 5 (openacademy), su solución del examen (`filmo`) y sus scripts de servicios web (`2.py`, `8.py`). Tres bloques: convenciones a **imitar**, buenas prácticas con su **porqué**, y **rarezas** suyas que conviene conocer (no necesariamente copiar).

## openacademy vs. filmo: el patrón completo y el mínimo

<mark style="background: #8000E1A6;">La clave para aprobar: el examen pide la versión MÍNIMA del módulo que enseña en la práctica.</mark> `filmo` es `openacademy` sin la lógica avanzada.

| Pieza | openacademy (práctica) | filmo (examen) |
| - | - | - |
| Modelos + campos | sí | sí |
| Relaciones (M2o/O2m/M2m) | sí | sí |
| Vistas form/tree/search | sí | sí |
| Acción + menú | sí | sí (menú solo para películas) |
| Seguridad CSV | por grupos | **abierta** (`group_id` vacío) |
| Herencia `res.partner` | sí | **no** |
| Dominios | sí | no |
| Campos computados / onchange | sí | **no** |
| Informe QWeb | sí | no |
| Datos demo | sí | no (vacío) |

Para P6 basta lo de la columna derecha. Lo demás prepara variantes ([[19 - Variantes y práctica]]).

## Convenciones a imitar

Replícalas y tu código será indistinguible del suyo:

- <mark style="background: #ADCCFFA6;">**Nombres internos en inglés, etiquetas en español.**</mark> Modelos y campos en inglés (`filmo.pelicula`, `name`, `director`, `pelicula_id`, `sesion_ids`); `string=` y `<page string="...">` en español ("Pelicula", "Resumen", "Sesiones", "Asistentes"). Comentarios en español.
- **Estructura estándar de módulo**: `models/models.py`, un único fichero de vistas con el nombre del módulo (`filmo.xml`, no `views.xml`), `security/ir.model.access.csv`, `__manifest__.py`, `__init__.py`. Sin `controllers/` ni `demo/` si no se usan.
- **Un solo fichero de vistas** con todo dentro (todas las vistas + acciones + menús del módulo), no un fichero por modelo.
- **`_name` siempre; `_description` casi nunca** (él lo omite).
- **Importa solo lo necesario**: `from odoo import models, fields` (añade `api` solo si hay computed/onchange — en `filmo` no lo importa).
- **Activa el CSV de seguridad** en `data` del manifest (el scaffold lo deja comentado; él lo descomenta siempre).

## Buenas prácticas que aplica (y su porqué)

Entiéndelas, no solo las copies:

- <mark style="background: #FFB8EBA6;">`ondelete='cascade'` en el `Many2one` "hijo"</mark>: una sesión no existe sin su película/curso, así que al borrar el padre se borran los hijos. En relaciones débiles (responsable) usa `'set null'`: el padre puede desaparecer sin arrastrar al registro.
- **`One2many` siempre con su `Many2one` inverso** definido: el `One2many` no crea columna, se apoya en el `Many2one`. Si falta, no funciona.
- **`required=True` en los campos clave** que el enunciado marca como obligatorios (nombre de la película, día y hora de la sesión).
- **Orden de declaración en XML**: la acción antes que el menú que la referencia; el menú padre antes que los hijos. El XML se carga de arriba abajo.
- **Datos en su sitio**: seguridad y vistas en `data` (se cargan siempre), datos de prueba en `demo` (solo con demostración).
- **`digits=(6,2)`, `help=`, `default=fields.Date.today`** cuando aportan: precisión a los `Float`, ayuda al usuario, valor inicial sensato.

## Rarezas y residuos suyos (conócelas)

Detalles reales de su código. Saber por qué están te evita copiarlos a ciegas:

- <mark style="background: #FF5582A6;">**`<openerp>` vs `<odoo>`**</mark>: en la práctica (P5) usa la raíz moderna `<odoo>`; en la solución del examen usa la antigua `<openerp>`. Odoo 14 acepta ambas. Recomendación: usa `<odoo>` (es la actual) pero no te sorprenda ver `<openerp>` en su solución.
- **`filmo.sesion` define `name = fields.Char()`** que no es obligatorio ni se muestra en ninguna vista: es un residuo del modelo `Session` de openacademy (donde `name` sí se usaba). Inofensivo, pero innecesario.
- **`pelicula_id` sin `required=True`** en `filmo`, mientras que en openacademy el `course_id` equivalente sí lo lleva. Pequeña inconsistencia suya; el enunciado de Filmoteca no exige que la sesión tenga película obligatoria.
- **Define `sesion_list_action` pero no le pone menú**: las sesiones se gestionan desde la pestaña de la película, no desde un menú propio. La acción queda "huérfana" pero no molesta.
- **`object` como nombre de variable** en `8.py`, pisando el builtin `object` de Python. Funciona, pero es mala práctica; mejor `models` (ver [[07 - Servicios web XML-RPC]]).
- **Python informal (no PEP 8)**: `l=conn.list()`, `user_passwd= "admin"`, variables de una letra, sin espacios alrededor del `=`. En sus scripts de servicios web es su estilo habitual.

## Gotchas operativos que él recalca

Errores de proceso, no de código, que cuestan tiempo en el examen:

> [!warning]+
> - **Ciclo de actualización**: cambiar `.py` → parar+reiniciar Odoo + `Upgrade`; cambiar `.xml` → solo `Upgrade`; **eliminar/cambiar un campo** → desinstalar y borrar el módulo, reiniciar, reinstalar (un `Upgrade` no quita columnas).
> - **No actualizar el módulo hasta tener TODAS las relaciones** (M2o + O2m + M2m) introducidas.
> - **Become Superuser** (modo desarrollador) para ver los menús nuevos.
> - `scaffold` crea ficheros como `root` → `sudo chown -R $USER:$USER`; y `chmod 777 addons` al crear la carpeta.
> - Heredar `res.partner` exige cambiar el `command` del compose a `-- --dev=reload -d <BD> -u <modulo>` (no aplica a Filmoteca).

> [!important]+
> Resumen para el examen: escribe **inglés interno / español visible**, **estructura estándar**, **CSV abierto activado en el manifest**, `<odoo>` como raíz, y aplica el ciclo `.py`→reiniciar+Upgrade. Con eso tu `filmo` será como el suyo (o más limpio). Vamos a construirlo: [[18 - Filmoteca paso a paso]].
