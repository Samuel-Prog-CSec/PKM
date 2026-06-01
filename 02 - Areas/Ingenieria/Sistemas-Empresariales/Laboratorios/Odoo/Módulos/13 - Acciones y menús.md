---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[12 - Vistas XML]]"
Nota siguiente: "[[14 - Seguridad y datos demo]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Acciones y menús

Una vista no se muestra sola. Hace falta una **acción** que diga "abre este modelo con estas vistas" y un **menú** que el usuario pulse para lanzar la acción. Es la pieza que hace navegable tu módulo.

## Acción de ventana: `ir.actions.act_window`

<mark style="background: #ADCCFFA6;">Una *window action* abre un modelo en un conjunto de vistas.</mark> Sus campos clave son `res_model` (qué modelo) y `view_mode` (qué vistas y en qué orden).

```xml
<record model="ir.actions.act_window" id="course_list_action">
    <field name="name">Courses</field>
    <field name="res_model">openacademy.course</field>
    <field name="view_mode">tree,form</field>
    <field name="help" type="html">
        <p class="oe_view_nocontent_create">Create the first course</p>
    </field>
</record>
```

- `view_mode="tree,form"` significa: <mark style="background: #FFB8EBA6;">abre primero el listado (tree) y, al pulsar un registro, el formulario (form)</mark>. El orden de la lista es el orden de apertura.
- `help` (opcional) es el mensaje que se ve cuando aún no hay registros, con un enlace para crear el primero.

## Menús: `menuitem`

Los menús se declaran con `<menuitem>` y forman una **jerarquía** mediante `parent`. El menú de nivel superior no tiene padre; los submenús apuntan a su padre y lanzan una acción.

```xml
<!-- menú raíz: sin parent -->
<menuitem id="main_openacademy_menu" name="Open Academy"/>

<!-- submenú: cuelga del raíz y lanza la acción -->
<menuitem id="courses_menu" name="Courses"
          parent="main_openacademy_menu"
          action="course_list_action"/>
```

Un segundo submenú para otro modelo (sesiones) cuelga del mismo raíz:

```xml
<menuitem id="session_menu" name="Sessions"
          parent="main_openacademy_menu"
          action="session_list_action"/>
```

## Orden de declaración (importa)

<mark style="background: #FF5582A6;">El XML se carga de arriba abajo, así que un elemento solo puede referenciar algo ya declarado.</mark> En la práctica:

- La **acción debe declararse antes** del `menuitem` que la usa (`action="course_list_action"`).
- El **menú padre debe declararse antes** que sus hijos (`parent="main_openacademy_menu"`).

El propio profesor lo anota en el guion: *"the following menuitem should appear after its parent and after its action"*.

> [!info]+
> En `action="course_list_action"` se usa el **id corto**. El id completo sería `openacademy.course_list_action` (módulo + id), pero <mark style="background: #FFB8EBA6;">no hace falta el prefijo del módulo cuando referencias algo del mismo módulo</mark>. Solo necesitarías `modulo.id` para referenciar un id de *otro* módulo (como `base.view_partner_form` en la herencia de vistas).

> [!warning]+
> Detalle del estilo del profesor: en la solución del examen define la acción de las sesiones (`sesion_list_action`) pero **no le pone ningún `menuitem`** — las sesiones se gestionan desde la pestaña de la película, no desde un menú propio. Es una decisión deliberada (o un residuo del openacademy original); funciona igual. Ver [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].

> [!question]- Comprueba: en el XML, ¿qué va antes, la acción o el menú que la lanza?
> La **acción** antes que el `menuitem` que la referencia, y el **menú padre** antes que sus hijos. El XML se carga de arriba abajo: referenciar algo aún no declarado rompe la carga.

> [!question]- Comprueba: ¿qué hace `view_mode="tree,form"`?
> Abre primero el **listado** (tree) y, al pulsar un registro, el **formulario** (form). El orden de la lista marca el orden de apertura.

> [!important]+
> Recuerda: para que el menú aparezca tras el `Upgrade`, debes estar en modo desarrollador y haber hecho **Become Superuser**. Si no, el menú existe pero no lo ves.

Falta proteger los modelos y, opcionalmente, cargar datos de ejemplo: [[14 - Seguridad y datos demo]].
