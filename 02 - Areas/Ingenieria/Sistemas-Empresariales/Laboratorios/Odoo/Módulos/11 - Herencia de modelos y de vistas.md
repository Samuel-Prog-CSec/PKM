---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[10 - Relaciones entre modelos]]"
Nota siguiente: "[[12 - Vistas XML]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Herencia de modelos y de vistas

Odoo no solo deja crear modelos nuevos: deja **extender los que ya existen** sin tocar su código. Es la potencia real de un ERP modular — añades un campo a `res.partner` (contactos) y aparece en toda la aplicación. Aquí van la herencia de modelos, la de vistas y los dominios sobre campos relacionales.

## Herencia de modelos: `_inherit`

<mark style="background: #ADCCFFA6;">Usando `_inherit` en lugar de `_name`, la clase no crea un modelo nuevo: amplía uno existente.</mark> Es el mismo mecanismo de herencia de Python ([[01 - Python para Odoo]]), pero aplicado a un modelo del núcleo.

```python
# openacademy/models/partner.py
# -*- coding: utf-8 -*-
from odoo import fields, models

class Partner(models.Model):
    _inherit = 'res.partner'        # NO _name: extiende res.partner

    instructor = fields.Boolean("Instructor", default=False)
    session_ids = fields.Many2many('openacademy.session',
                                   string="Attended Sessions", readonly=True)
```

<mark style="background: #8000E1A6;">Esto añade dos columnas (`instructor`, `session_ids`) a la tabla de contactos existente</mark>: cualquier `res.partner` puede marcarse como instructor y ver sus sesiones. No has copiado ni modificado el modelo original.

Recuerda añadir el fichero a la cadena de imports:

```python
# openacademy/models/__init__.py
from . import models
from . import partner
```

> [!warning]+
> Al extender `res.partner` el profesor avisa de un *gotcha*: para que no falle al arrancar, cambia en `docker-compose.yml` la línea `command: -- --dev=reload` por `command: -- --dev=reload -d nombre_base_datos -u openacademy`. Así el módulo se **actualiza automáticamente** al levantar el contenedor (`-d` fija la base de datos, `-u` el módulo a actualizar). Para el examen Filmoteca **no hace falta**, porque no hereda `res.partner`.

## Herencia de vistas: `inherit_id` + `position`

Igual que con los modelos, puedes **inyectar contenido en una vista que ya existe** sin reescribirla. Se referencia la vista original con `inherit_id` y se indica dónde insertar con `position`.

```xml
<record model="ir.ui.view" id="partner_instructor_form_view">
    <field name="name">partner.instructor</field>
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <notebook position="inside">
            <page string="Sessions">
                <group>
                    <field name="instructor"/>
                    <field name="session_ids"/>
                </group>
            </page>
        </notebook>
    </field>
</record>
```

- `inherit_id ref="base.view_partner_form"` apunta a la vista de formulario de contactos del módulo `base`.
- <mark style="background: #FFB8EBA6;">`position` indica el punto de inserción</mark>: `inside` (dentro del elemento), `before`, `after`, `replace`. Aquí añade una pestaña "Sessions" dentro del `<notebook>` existente de los contactos.

## Dominios en campos relacionales

Un **dominio** restringe qué registros se pueden elegir en un campo relacional — la misma sintaxis de filtros que viste en [[07 - Servicios web XML-RPC]]. Por ejemplo, que el instructor de una sesión solo pueda ser un contacto marcado como instructor:

```python
instructor_id = fields.Many2one('res.partner', string="Instructor",
                                domain=[('instructor', '=', True)])
```

Dominios más complejos usan la notación prefija `'|'` (OR), `'&'` (AND), `'!'` (NOT). Que el instructor sea instructor **o** pertenezca a una categoría "Teacher":

```python
instructor_id = fields.Many2one('res.partner', string="Instructor",
    domain=['|', ('instructor', '=', True),
                 ('category_id.name', 'ilike', "Teacher")])
```

<mark style="background: #FFB8EBA6;">El `'|'` afecta a las DOS condiciones que le siguen</mark>: se lee "OR(instructor, categoría)". `category_id.name` navega por la relación hasta el nombre de la categoría.

> [!info]+
> Para el examen Filmoteca esta nota es de apoyo: el examen **no** exige heredar `res.partner` ni dominios (solo enlaza asistentes con un `Many2many` simple). Pero entender la herencia te prepara para una variante que pida, por ejemplo, marcar socios o restringir asistentes. Ver [[19 - Variantes y práctica]].

> [!question]- Comprueba: ¿qué cambia entre usar `_name` y `_inherit` en una clase?
> `_name` **crea** un modelo nuevo (tabla nueva). `_inherit = 'res.partner'` (sin `_name`) **extiende** uno existente: añade campos/lógica a `res.partner` sin tocar su código ni crear otra tabla.

> [!question]- Comprueba: en herencia de vistas, ¿para qué sirve `position`?
> Indica dónde inyectar tu XML dentro de la vista original: `inside`, `before`, `after` o `replace`. Junto con `inherit_id ref="..."` (la vista que extiendes) permite, p. ej., añadir una pestaña al formulario de contactos sin reescribirlo.

Ya tienes los datos y sus relaciones. Toca decidir cómo se ven: [[12 - Vistas XML]].
