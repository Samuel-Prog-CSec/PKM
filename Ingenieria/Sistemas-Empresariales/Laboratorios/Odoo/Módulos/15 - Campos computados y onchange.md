---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Descripción: "Hasta aquí los campos guardan lo que el usuario teclea"
Fecha de actualización: 2026-05-31
Nota previa: "[[14 - Seguridad y datos demo]]"
Nota siguiente: "[[16 - Informes QWeb]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Campos computados y onchange

Hasta aquí los campos guardan lo que el usuario teclea. Ahora dos mecanismos que añaden **lógica**: campos que se calculan solos y validaciones reactivas en el formulario. Es donde entran en juego los decoradores de [[01 - Python para Odoo]].

## Campos computados: `compute` + `@api.depends`

<mark style="background: #ADCCFFA6;">Un campo computado no se almacena (por defecto): se calcula al vuelo a partir de otros campos mediante un método.</mark> Se declara con `compute='_metodo'` y el método se marca con `@api.depends(...)` para que Odoo sepa **cuándo recalcular**.

Ejemplo: el porcentaje de plazas ocupadas de una sesión, a partir del número de plazas y de asistentes:

```python
from odoo import models, fields, api

class Session(models.Model):
    _name = 'openacademy.session'

    seats = fields.Integer(string="Number of seats")
    attendee_ids = fields.Many2many('res.partner', string="Attendees")
    taken_seats = fields.Float(string="Taken seats", compute='_taken_seats')

    @api.depends('seats', 'attendee_ids')
    def _taken_seats(self):
        for r in self:
            if not r.seats:
                r.taken_seats = 0.0
            else:
                r.taken_seats = 100.0 * len(r.attendee_ids) / r.seats
```

Claves:
- `@api.depends('seats', 'attendee_ids')` declara las dependencias: <mark style="background: #FFB8EBA6;">al cambiar cualquiera de esos campos, Odoo recalcula `taken_seats`.</mark>
- El método **siempre itera** `for r in self:` — `self` puede ser un conjunto de varios registros (un *recordset*), no uno solo. Asignas el resultado a `r.taken_seats`.
- Recuerda importar `api` (ahora sí lo usas).

Un ejemplo mínimo y verificado: en el ejercicio [[21 - Ejercicio de práctica - Biblioteca (resuelto)|Biblioteca]] añadí `num_sesiones = fields.Integer(compute='_compute_num_sesiones', store=True)` con `@api.depends('sesion_ids')` que hace `len(libro.sesion_ids)`. El campo se rellena solo y, con `store=True`, se guarda y se puede usar en filtros. Así se ve en el formulario ("Nº de sesiones: 2", calculado sin teclearlo):

![[biblio-ampliacion-form.png]]

Se muestra bien con un widget de barra de progreso en la vista ([[12 - Vistas XML]]):

```xml
<field name="taken_seats" widget="progressbar"/>
```

## Valores por defecto y campo activo

Dos detalles del mismo bloque de la práctica:

```python
start_date = fields.Date(default=fields.Date.today)   # hoy por defecto
active = fields.Boolean(default=True)                  # campo "active" especial
```

<mark style="background: #FFB8EBA6;">El campo llamado `active` es especial en Odoo</mark>: si vale `False`, el registro se "archiva" (deja de aparecer en los listados sin borrarse). Es una convención del ORM, no un campo cualquiera.

## Onchange: validación reactiva en el formulario

<mark style="background: #ADCCFFA6;">Un `@api.onchange` se dispara en el formulario al cambiar un campo, antes de guardar</mark>, y permite avisar al usuario o ajustar otros campos en caliente. Para avisar, el método devuelve un diccionario `warning`:

```python
@api.onchange('seats', 'attendee_ids')
def _verify_valid_seats(self):
    for r in self:
        if r.seats < 0:
            return {
                'warning': {
                    'title': "Incorrect 'seats' value",
                    'message': "The number of available seats may not be negative",
                },
            }
        if r.seats < len(r.attendee_ids):
            return {
                'warning': {
                    'title': "Too many attendees",
                    'message': "Increase seats or remove excess attendees",
                },
            }
```

<mark style="background: #8000E1A6;">Esta lógica "mantener un valor dentro de un rango válido" es la misma del ejercicio 22 (clase `Contador`)</mark> de [[02 - Ejercicios Python resueltos]] — la idea se repite, ahora integrada en el ciclo de un formulario Odoo.

> [!info]+
> `onchange` vs `constrains`: `@api.onchange` actúa en la interfaz (avisa mientras editas, no bloquea el guardado por sí solo); `@api.constrains` valida al guardar y puede abortar con `ValidationError`. La práctica usa `onchange`; para una validación dura usarías `constrains`.

## Validar un máximo (máx. 2 contrincantes)

El examen pide a menudo **controlar un límite** ("no más de 2 contrincantes", "máximo N inscritos"). Hay dos formas, y conviene saber cuál reproduce el modal que aparece en el enunciado.

**Opción A — `@api.onchange` (la del modal con título propio).** Reproduce exactamente el aviso *"Demasiados contrincantes / El máximo de contrincantes es 2"*: el `warning` te deja poner **título y mensaje**.

```python
from odoo import models, fields, api

class Partida(models.Model):
    _name = 'ajedrez.partida'
    contrincante_ids = fields.Many2many('res.partner', string="Contrincantes")

    @api.onchange('contrincante_ids')
    def _check_contrincantes(self):
        for r in self:
            if len(r.contrincante_ids) > 2:
                return {'warning': {
                    'title': "Demasiados contrincantes",
                    'message': "El máximo de contrincantes es 2",
                }}
```

**Opción B — `@api.constrains` (bloqueo duro al guardar).** Si quieres impedir de verdad que se guarde (no solo avisar), valida al guardar y aborta con `ValidationError`:

```python
from odoo import models, fields, api
from odoo.exceptions import ValidationError

class Partida(models.Model):
    _name = 'ajedrez.partida'
    contrincante_ids = fields.Many2many('res.partner', string="Contrincantes")

    @api.constrains('contrincante_ids')
    def _check_contrincantes(self):
        for r in self:
            if len(r.contrincante_ids) > 2:
                raise ValidationError("El máximo de contrincantes es 2")
```

Claves, para adaptarlo a cualquier límite:
- <mark style="background: #ADCCFFA6;">`onchange` **avisa** mientras editas (warning con título/mensaje) pero no impide guardar; `constrains` valida **al guardar** y aborta con `ValidationError`.</mark>
- El decorador vigila el campo: `@api.onchange('contrincante_ids')` / `@api.constrains('contrincante_ids')`. Importa `api` (y, para la opción B, `from odoo.exceptions import ValidationError`).
- Siempre `for r in self:` (recordset). La cardinalidad de un `Many2many`/`One2many` se mide con `len(r.campo_ids)`; un número se compara directo (`if r.seats < 0`).
- <mark style="background: #FF5582A6;">El modal del enunciado (título "Demasiados contrincantes") es un `onchange` warning</mark>: si solo necesitas que el modal coincida, usa la Opción A. Para máxima robustez, pon **las dos** — el aviso en caliente y el bloqueo al guardar.

> [!important]+
> Para el examen Filmoteca **no se piden campos computados ni onchange** (la solución del profesor no los lleva). Pero una **variante muy común sí pide un límite** — p. ej. el "máx. 2 contrincantes" del examen **Ajedrez** —: para eso es la sección de arriba. Si controlas el `taken_seats`, el `warning` y el `constrains`, vas sobrado para P6 y preparado para un examen más exigente. Ver [[19 - Variantes y práctica]].

Última pieza de la práctica, también opcional para el examen: los informes PDF. [[16 - Informes QWeb]].
