---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Descripción: "Los modelos guardan datos; las vistas deciden cómo se ven y editan"
Fecha de actualización: 2026-05-27
Nota previa: "[[11 - Herencia de modelos y de vistas]]"
Nota siguiente: "[[13 - Acciones y menús]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Vistas XML

Los modelos guardan datos; las **vistas** deciden cómo se ven y editan. Se declaran en XML como registros del modelo `ir.ui.view`. Las tres que necesitas para el examen son **form** (formulario), **tree** (listado) y **search** (búsqueda).

## Anatomía de una vista

<mark style="background: #ADCCFFA6;">Cada vista es un `<record model="ir.ui.view">` con tres campos: `name` (identificador descriptivo), `model` (a qué modelo aplica) y `arch` (la arquitectura XML de la vista).</mark> Si no defines vista, Odoo genera una por defecto; tú la sobrescribes para controlar qué campos aparecen y cómo.

Todo el fichero de vistas va envuelto en una raíz `<odoo><data>...</data></odoo>`.

> [!warning]+
> **`<odoo>` vs `<openerp>`**: la raíz moderna (Odoo 9+) es `<odoo>`. La antigua es `<openerp>`. <mark style="background: #FFB8EBA6;">Odoo 14 acepta las dos</mark> (`<openerp>` es un alias heredado). El guion de la P5 usa `<odoo>`; la solución del examen del profesor usa `<openerp>`. Ambas funcionan: usa `<odoo>` por ser la actual, pero no te asustes si ves `<openerp>` en su código. Ver [[18 - Filmoteca paso a paso]].

## Vista form (formulario)

Muestra un registro para verlo/editarlo. Estructura: `<form>` → `<sheet>` (la "hoja" principal) → `<group>` (agrupa campos en columnas) → `<field>`.

```xml
<record model="ir.ui.view" id="course_form_view">
    <field name="name">course.form</field>
    <field name="model">openacademy.course</field>
    <field name="arch" type="xml">
        <form string="Course Form">
            <sheet>
                <group>
                    <field name="name"/>
                    <field name="description"/>
                </group>
            </sheet>
        </form>
    </field>
</record>
```

### Pestañas: `<notebook>` y `<page>`

Para repartir la información en pestañas se usa `<notebook>` con varias `<page>`. Una página puede contener una **tabla embebida** para un campo `One2many`/`Many2many` (un `<tree>` dentro del `<field>`):

```xml
<form string="Course Form">
    <sheet>
        <group>
            <field name="name"/>
        </group>
        <notebook>
            <page string="Description">
                <field name="description"/>
            </page>
            <page string="Sessions">
                <field name="session_ids">
                    <tree string="Registered sessions">
                        <field name="name"/>
                        <field name="instructor_id"/>
                    </tree>
                </field>
            </page>
        </notebook>
    </sheet>
</form>
```

<mark style="background: #FF5582A6;">Este patrón —notebook con una página de texto y otra con la lista embebida de los hijos `One2many`— es exactamente lo que pide el examen</mark> (una película con pestaña "Resumen" y pestaña "Sesiones"). Memorízalo.

Así se renderiza ese XML en Odoo. La pestaña "Resumen" (un `<page>` con un `<field>` de texto):

![[odoo-filmo-form-resumen.png]]

Y la pestaña "Sesiones" (otro `<page>` con el `<field>` `One2many` mostrado como tabla embebida `<tree>` día/hora):

![[odoo-filmo-form-sesiones.png]]

Se pueden anidar `<group>` para columnas paralelas (p. ej. datos "General" a la izquierda y "Schedule" a la derecha):

```xml
<group>
    <group string="General">
        <field name="course_id"/>
        <field name="instructor_id"/>
    </group>
    <group string="Schedule">
        <field name="start_date"/>
        <field name="seats"/>
    </group>
</group>
<label for="attendee_ids"/>
<field name="attendee_ids"/>
```

## Vista tree (listado)

Muestra varios registros en filas. Solo enumera las columnas:

```xml
<record model="ir.ui.view" id="course_tree_view">
    <field name="name">course.tree</field>
    <field name="model">openacademy.course</field>
    <field name="arch" type="xml">
        <tree string="Course Tree">
            <field name="name"/>
            <field name="responsible_id"/>
        </tree>
    </field>
</record>
```

Renderizado, un `<tree>` es la típica tabla de filas con las columnas que declaraste (aquí, el listado de películas con nombre/director/año):

![[odoo-filmo-lista.png]]

Un campo puede mostrarse con un **widget** que cambia su representación. El más vistoso es `progressbar` para un porcentaje:

```xml
<field name="taken_seats" widget="progressbar"/>
```

## Vista search (búsqueda)

Define qué campos se pueden buscar/filtrar en la barra superior del listado:

```xml
<record model="ir.ui.view" id="course_search_view">
    <field name="name">course.search</field>
    <field name="model">openacademy.course</field>
    <field name="arch" type="xml">
        <search>
            <field name="name"/>
            <field name="description"/>
        </search>
    </field>
</record>
```

Tras añadirla, la caja de búsqueda sugiere filtrar por nombre y descripción.

> [!important]+
> Las vistas no aparecen en ningún sitio por sí solas: necesitan una **acción** que las abra y un **menú** que lance la acción. Y para *ver* los menús nuevos debes ser superusuario (modo desarrollador → **Become Superuser**). Eso es lo siguiente: [[13 - Acciones y menús]].
