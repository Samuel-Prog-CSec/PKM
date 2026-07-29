---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Descripción: "Última pieza del openacademy completo: generar un informe PDF desde un registro"
Fecha de actualización: 2026-05-27
Nota previa: "[[15 - Campos computados y onchange]]"
Nota siguiente: "[[17 - Cómo programa el profesor (estilo y buenas prácticas)]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Informes QWeb

Última pieza del openacademy completo: generar un **informe PDF** desde un registro. Odoo usa **QWeb**, un motor de plantillas XML. El informe se compone de dos partes: una acción que lo registra y una plantilla que define el contenido.

> [!important]+
> El examen Filmoteca **no pide informes**. Esta nota cierra el temario de la Práctica 5 y prepara una posible variante ("genera un informe de la película/sesión"). Si vas justo de tiempo, repásala por encima y prioriza [[18 - Filmoteca paso a paso]].

## La acción de informe: `ir.actions.report`

<mark style="background: #ADCCFFA6;">`ir.actions.report` registra el informe y lo enlaza al modelo</mark>, de modo que aparezca en el botón `Print` de la ficha.

```xml
<record id="action_session" model="ir.actions.report">
    <field name="name">Session Report</field>
    <field name="model">openacademy.session</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">openacademy.report_session</field>
    <field name="report_file">openacademy.report_session</field>
    <field name="binding_model_id" ref="model_openacademy_session"/>
    <field name="binding_type">report</field>
</record>
```

- `report_type` = `qweb-pdf` (también existe `qweb-html`).
- `report_name`/`report_file` apuntan a la plantilla (mismo identificador).
- `binding_model_id` engancha el informe al menú `Print` del modelo `openacademy.session`.

## La plantilla QWeb: `<template>`

<mark style="background: #ADCCFFA6;">Una plantilla QWeb es HTML con directivas `t-*`</mark> que se evalúan contra los registros. Las tres que necesitas:

- `t-foreach="coleccion" t-as="x"` — bucle (como un `for`).
- `t-field="x.campo"` — imprime el valor de un campo con su formato.
- `t-call="web.html_container"` / `web.external_layout` — envoltorios estándar que dan cabecera/pie de página corporativos.

```xml
<template id="report_session">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="o">
            <t t-call="web.external_layout">
                <div class="page">
                    <h2 t-field="o.name"/>
                    <p>Start: <span t-field="o.start_date"/>,
                       duration: <span t-field="o.duration"/></p>
                    <h3>Attendees:</h3>
                    <ul>
                        <t t-foreach="o.attendee_ids" t-as="attendee">
                            <li><span t-field="attendee.name"/></li>
                        </t>
                    </ul>
                </div>
            </t>
        </t>
    </t>
</template>
```

<mark style="background: #FFB8EBA6;">`docs` es la variable implícita</mark> que QWeb pasa a la plantilla: los registros sobre los que se imprime (`o` es cada uno). El doble `t-foreach` recorre las sesiones y, dentro, sus asistentes.

No olvides añadir el fichero al manifest:

```python
'data': [
    # ...
    'reports/reports.xml',
],
```

> [!info]+
> QWeb es el mismo motor que renderiza las páginas web de Odoo (`views/templates.xml`). Por eso las directivas `t-foreach`/`t-esc`/`t-field` aparecen tanto en informes PDF como en plantillas web. En el laboratorio solo se usa para el informe PDF.

> [!question]- Comprueba: en una plantilla QWeb, ¿qué es `docs` y qué hace `t-foreach`?
> `docs` es la variable implícita con los **registros** sobre los que se imprime el informe. `t-foreach="docs" t-as="o"` los recorre uno a uno (como un `for`); dentro, `t-field="o.campo"` imprime cada campo con su formato.

Con esto cierras el temario técnico de la Práctica 5. Antes de resolver el examen, una nota imprescindible: cómo escribe el código tu profesor, para que tu entrega "suene" como la suya. [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].
