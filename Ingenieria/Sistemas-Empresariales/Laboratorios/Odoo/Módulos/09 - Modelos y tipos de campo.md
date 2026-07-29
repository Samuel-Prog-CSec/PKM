---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Descripción: "Un modelo es la unidad central de un módulo: define una 'tabla' de la base de datos y sus columnas"
Fecha de actualización: 2026-05-27
Nota previa: "[[08 - Estructura de un módulo y scaffold]]"
Nota siguiente: "[[10 - Relaciones entre modelos]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Modelos y tipos de campo

Un **modelo** es la unidad central de un módulo: define una "tabla" de la base de datos y sus columnas. Aquí defines los datos; las vistas ([[12 - Vistas XML]]) deciden cómo se muestran.

## Definir un modelo

<mark style="background: #ADCCFFA6;">Un modelo es una clase Python que hereda de `models.Model` y declara su identificador en el atributo `_name`.</mark> Ese `_name` (con punto, p. ej. `openacademy.course`) se traduce internamente a la tabla `openacademy_course` en PostgreSQL.

```python
# -*- coding: utf-8 -*-
from odoo import models, fields, api

class Course(models.Model):
    _name = 'openacademy.course'

    name = fields.Char(string="Title", required=True)
    description = fields.Text()
```

Tres cosas que conectan con [[01 - Python para Odoo]]:
- `class Course(models.Model)` es **herencia**: obtienes gratis toda la maquinaria del ORM (guardar en BD, vistas por defecto, permisos).
- <mark style="background: #FFB8EBA6;">Los campos son **atributos de clase**, no se asignan en un `__init__`.</mark> Esta es la diferencia clave con una clase Python normal: declaras `name = fields.Char(...)` directamente en el cuerpo de la clase.
- Importas `api` solo si vas a usar decoradores (`@api.depends`, `@api.onchange`); si el modelo es de campos simples, basta `from odoo import models, fields`. El profesor lo importa pero no siempre lo usa.

> [!info]+
> Al instalar el módulo, Odoo crea automáticamente campos internos que no declaras: `id`, `create_date`, `create_uid`, `write_date`, `write_uid`. Los puedes ver en `Settings → Technical → Database Structure → Models`. No los toques: son del ORM.

## Tipos de campo

Cada columna se declara con `fields.<Tipo>(...)`. Los tipos escalares más usados:

| Tipo | Para qué | Ejemplo |
| - | - | - |
| `Char` | texto corto (1 línea) | `fields.Char(string="Title", required=True)` |
| `Text` | texto largo (multilínea) | `fields.Text()` |
| `Integer` | entero | `fields.Integer(string="Number of seats")` |
| `Float` | decimal | `fields.Float(digits=(6, 2), help="Duration in days")` |
| `Boolean` | sí/no | `fields.Boolean(default=True)` |
| `Date` | fecha | `fields.Date(default=fields.Date.today)` |
| `Datetime` | fecha y hora | `fields.Datetime()` |
| `Selection` | lista cerrada de opciones | `fields.Selection([('a','A'),('b','B')])` |

Modelo `Session` del laboratorio, que reúne varios tipos:

```python
class Session(models.Model):
    _name = 'openacademy.session'

    name = fields.Char(required=True)
    start_date = fields.Date(default=fields.Date.today)
    duration = fields.Float(digits=(6, 2), help="Duration in days")
    seats = fields.Integer(string="Number of seats")
    active = fields.Boolean(default=True)
```

## Atributos comunes de un campo

Se pasan como argumentos al constructor del campo:

- `string` — etiqueta visible en la interfaz. <mark style="background: #FFB8EBA6;">Si no lo pones, Odoo deriva la etiqueta del nombre del campo</mark> (`start_date` → "Start Date"). Por eso el profesor a veces lo omite.
- `required=True` — obligatorio; la BD rechaza guardar sin valor.
- `default` — valor por defecto; puede ser un literal (`True`) o una función (`fields.Date.today`, sin paréntesis: pasas la función, no su resultado).
- `help` — texto de ayuda al pasar el ratón.
- `digits=(total, decimales)` — precisión de un `Float`.

> [!warning]+
> `default=fields.Date.today` va **sin paréntesis**: pasas la función para que Odoo la llame en cada registro nuevo. Con `fields.Date.today()` (con paréntesis) fijarías la fecha del día de instalación para *todos* los registros — error sutil.

> [!important]+
> Convención del profesor a imitar en el examen: **nombre interno del campo en inglés** (`name`, `description`, `start_date`) y **`string=` en español** si la interfaz va en español (`string="Resumen"`). Internamente inglés, de cara al usuario el idioma del enunciado. Ver [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].

> [!question]- Comprueba: ¿por qué `default=fields.Date.today` se escribe sin paréntesis?
> Porque pasas la **función**, y Odoo la llama por cada registro nuevo (la fecha del día de creación). Con `fields.Date.today()` (con paréntesis) evaluarías la fecha **una sola vez**, al instalar, y todos los registros nacerían con esa misma fecha.

> [!question]- Comprueba: el enunciado dice "el año del libro puede ser texto". ¿Qué tipo declaras?
> `Char`. Aunque parezca un número, si el enunciado lo permite como texto, `fields.Char` es lo correcto (un año como "1977" no necesita aritmética). Mismo criterio: "hora" como `Char` y "día/fecha" como `Date`.

Un modelo aislado sirve de poco: lo potente es relacionarlo con otros. Siguiente: [[10 - Relaciones entre modelos]].
