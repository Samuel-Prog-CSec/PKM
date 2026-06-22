---
tags:
  - SIE/Laboratorio
  - SIE/Examen
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[18 - Filmoteca paso a paso]]"
Nota siguiente: "[[20 - Estrategia de examen y autoevaluación]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Variantes y práctica

El examen no será exactamente Filmoteca, pero será **el mismo patrón con otros nombres**. Esta nota generaliza el patrón a otros enunciados plausibles, da un checklist anti-error para la entrega, y cataloga los fallos típicos con su síntoma. Es la nota que conviertes en chuleta mental el día del examen.

## El patrón maestro (reconócelo bajo cualquier disfraz)

<mark style="background: #8000E1A6;">Todos estos enunciados son el mismo módulo: una entidad "maestra" con muchas entidades "detalle", y el detalle enlaza con contactos.</mark>

| Enunciado | Maestro (1) | Detalle (N) | `Many2many` a `res.partner` |
| - | - | - | - |
| openacademy | Curso | Sesión | Asistentes |
| **Filmoteca** | **Película** | **Sesión** | **Asistentes (socios)** |
| Biblioteca | Libro | Préstamo | Socios/lectores |
| Gimnasio | Clase | Reserva | Inscritos |
| Concesionario | Vehículo | Cita de prueba | Clientes |

La receta, idéntica siempre:
1. **Maestro** con sus campos + `detalle_ids = One2many('modulo.detalle', 'maestro_id')`.
2. **Detalle** con sus campos + `maestro_id = Many2one('modulo.maestro', ondelete='cascade')` + `attendee_ids = Many2many('res.partner')`.
3. Vistas tree/form/search del maestro (form con notebook: una pestaña de datos, otra con el `One2many` embebido), y form/tree del detalle.
4. Acción + menú para el maestro; CSV abierto para ambos modelos.

### Ejemplo express: Biblioteca

Aplicando la receta, el modelo se escribe casi sin pensar (cambian los nombres y los tipos según el enunciado):

```python
# -*- coding: utf-8 -*-
from odoo import models, fields

class Libro(models.Model):
    _name = 'biblio.libro'
    name = fields.Char(string="Título", required=True)
    autor = fields.Char(string="Autor")
    isbn = fields.Char(string="ISBN")
    prestamo_ids = fields.One2many('biblio.prestamo', 'libro_id', string="Préstamos")

class Prestamo(models.Model):
    _name = 'biblio.prestamo'
    fecha = fields.Date(string="Fecha", required=True)
    libro_id = fields.Many2one('biblio.libro', ondelete='cascade', string="Libro")
    socio_ids = fields.Many2many('res.partner', string="Socios")
```

<mark style="background: #FF5582A6;">Si reconoces que "Biblioteca" es "Filmoteca con otros nombres", el examen es mecánico.</mark> Lo único que cambia: nombres de modelo/campo y los tipos (¿es `Char`, `Date`, `Integer`?). Todo lo demás (estructura, relaciones, vistas, CSV) se copia del patrón. Fundamento en [[18 - Filmoteca paso a paso]].

> [!success]+
> Esta Biblioteca está **resuelta entera** —enunciado tipo examen, módulo completo (modelos, vistas, seguridad), instalación verificada en Odoo y una ampliación con campo computado y `Selection`— en [[21 - Ejercicio de práctica - Biblioteca (resuelto)]]. Allí el detalle es una "sesión de club de lectura" en vez de un "préstamo", pero el patrón es idéntico. Resuélvelo tú primero y compara después.

## Posible variante de servicios web

Un examen "tipo P4" pediría un script XML-RPC en vez de un módulo. El patrón también es fijo: **conectar → autenticar (uid) → `execute_kw` con un dominio** ([[07 - Servicios web XML-RPC]]). Mini-ejemplo: "lista el nombre y email de los socios de una ciudad pasada por parámetro".

```python
from xmlrpc import client
import sys
server, port, db, user, pwd = "localhost", 8069, "bd", "admin", "admin"
common = client.ServerProxy(f'http://{server}:{port}/xmlrpc/2/common')
uid = common.authenticate(db, user, pwd, {})
models = client.ServerProxy(f'http://{server}:{port}/xmlrpc/2/object')

dominio = [['city', '=', sys.argv[1]]] if len(sys.argv) > 1 else [[]]
for c in models.execute_kw(db, uid, pwd, 'res.partner', 'search_read',
                           [dominio], {'fields': ['name', 'email']}):
    print(c['name'], c['email'])
```

## Checklist anti-error (antes de entregar)

Recórrelo de arriba abajo cuando creas que has terminado:

- <mark style="background: #FF5582A6;">¿El fichero de modelos está importado en la cadena `__init__.py`?</mark> (raíz → `models` → `models.py`).
- ¿Cada modelo nuevo tiene su línea en `ir.model.access.csv`, y el CSV está **activado** (no comentado) en `data` del manifest?
- ¿El `views/<modulo>.xml` está en `data`? ¿La **acción** se declara antes del **menú** que la referencia, y el menú padre antes del hijo?
- ¿El `One2many` tiene su `Many2one` inverso con el nombre exacto del campo?
- ¿Los tipos coinciden con el enunciado? (cuidado con "año"/"hora" como `Char` y "día"/"fecha" como `Date`).
- ¿Aplicaste el ciclo correcto: reiniciar+Upgrade tras tocar `.py`, solo Upgrade tras `.xml`?
- ¿Estás en modo desarrollador y con **Become Superuser** para ver el menú?
- ¿La raíz XML (`<odoo>` o `<openerp>`) está bien abierta y cerrada, con `<data>` dentro?

## Errores típicos y su síntoma

| Síntoma | Causa probable | Arreglo |
| - | - | - |
| El modelo no aparece en `Models` | falta el import en `__init__.py` | añadir `from . import models`, reiniciar+Upgrade |
| "Access Denied" / no veo registros | falta línea en el CSV o está comentado en el manifest | añadir/activar la línea, Upgrade |
| El menú no aparece | no eres Superuser, o el menú va antes que su acción/padre | Become Superuser; reordenar el XML |
| Error al cargar la vista (`Field ... does not exist`) | el campo del XML no existe en el modelo, o tocaste el `.py` sin reiniciar | revisar nombres; reiniciar Odoo + Upgrade |
| Cambié un campo y sigue el viejo | un `Upgrade` no quita columnas | desinstalar+borrar módulo, reiniciar, reinstalar |
| El `One2many` sale vacío | el `Many2one` inverso no existe o el nombre no coincide | corregir el segundo argumento del `One2many` |

> [!success]+
> Si el `Upgrade` no da error, el menú lista registros y las relaciones se navegan (de la película a sus sesiones y de la sesión a sus asistentes), el módulo está bien. Esa es la prueba de fuego del examen práctico.

> [!important]+
> Plan de estudio mínimo para aprobar: domina [[18 - Filmoteca paso a paso]] (constrúyelo a mano una vez en Docker), interioriza el **patrón maestro-detalle-contactos** de esta nota, y ten el **checklist** a mano. Con eso, cualquier variante tipo P6 es mecánica. Último paso: táctica del día del examen y un test de repaso en [[20 - Estrategia de examen y autoevaluación]].
