---
tags:
  - SIE/Laboratorio
  - SIE/Examen
  - SIE
Descripción: "Esta es la nota que tienes abierta durante el examen"
Fecha de actualización: 2026-05-31
Nota previa: "[[21 - Ejercicio de práctica - Biblioteca (resuelto)]]"
Nota siguiente: ""
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Cheatsheet de examen (chuleta operativa)

Esta es la nota que tienes **abierta durante el examen**. No explica teoría: te dice **qué hacer, en qué orden, y dónde saltar** si necesitas el detalle. Cada enlace `[[nota#sección]]` te lleva directo al bloque exacto — no pierdas tiempo leyendo lo que no toca.

El examen tipo: **4 ejercicios, 2,5 h, 10 puntos**. Dos de Odoo (uso + módulo) y dos de Python (API externa). Base de datos **nueva con datos demo** llamada `junio26`.

> [!important]+ Qué se entrega en cada tipo
> - **Ejercicios de Odoo (uso/módulo):** capturas de pantalla y/o ficheros que demuestren el resultado.
> - **Ejercicios de programación (Python):** los ficheros `.py` **y** la captura/fichero de texto con el resultado de la ejecución.
> - **Módulo:** el `.zip` del módulo + capturas. **Debe entregarse una versión que funcione** (mejor un módulo que instala y muestra datos que uno "perfecto" que no arranca).

## Antes de empezar — pre-vuelo (5 min)

1. **Levanta Odoo** (Docker) y comprueba `http://localhost:8069`. El `docker-compose` del lab monta `./addons:/mnt/extra-addons` y arranca con `--dev=reload` ([[04 - Instalación con Docker]]).
2. **Crea la BD `junio26`** desde *Manage Databases*: idioma **inglés**, marca el checkbox **"Demo data"**, email/password **`admin`** / **`admin`**. <mark style="background: #FF5582A6;">La **clave máster** que teclees aquí es la que usarán tus scripts del Ej. 2</mark> (en el lab la fijamos a `master`).
3. **Activa el modo desarrollador**: `Settings → Activate the developer mode`. Lo necesitas para descubrir modelos/campos (Ej. 3) y para ver tu menú (Ej. 4). → [[05 - Administración funcional#Modo desarrollador]]
4. **Ten listas las plantillas**: una carpeta `addons/` y dos esqueletos `.py` (uno de servicio `db`, otro de `common`+`object`) abiertos para copiar.

> [!warning]+ La master password (Ej. 2)
> `duplicate_database`, `rename`, `drop`, `create_database` exigen la **clave máster** del servidor (`admin_passwd`), **no** la del usuario `admin`. Es la que pusiste al crear la BD (lab: `master`; Odoo de fábrica: `admin`). Si el script da `AccessDenied`, la master está mal.

## Reparto de tiempo orientativo (2,5 h = 150 min)

| Ejercicio | Puntos | Tiempo | Por qué |
| - | - | - | - |
| Ej. 4 — Módulo | 4 | ~60 min | Es el que más vale; empieza por aquí cuando el entorno ya está listo. |
| Ej. 1 — Uso Odoo | 2 | ~25 min | Mecánico si sigues el flujo; muchas capturas. |
| Ej. 2 — Python BD | 2 | ~25 min | Copiar el script resuelto y adaptar nombres. |
| Ej. 3 — Python listado | 2 | ~20 min | Igual; cuidado con el *gotcha* Many2one. |
| Repaso/entrega | — | ~20 min | Comprobar capturas, zip del módulo, resultados. |

> [!tip]+ Orden recomendado
> Pre-vuelo → **Ej. 4** (lo más caro, con la cabeza fresca) → **Ej. 1** (mientras Odoo ya está abierto) → **Ej. 2 y 3** (scripts). Si te atascas en una vista del módulo, **déjalo funcionando con lo básico** y pasa al siguiente; vuelves al final. Detalle táctico en [[20 - Estrategia de examen y autoevaluación#Cómo afrontar el examen (orden de trabajo)]].

---

## Ejercicio 1 — Uso de Odoo: compra (2 pts)

**Pide:** instalar **CRM, Purchase, Inventory**; crear una orden de compra (proveedor *Lumber Inc*, 5 × *Corner Desk Right Sit* a 500 €); entregar **a)** la orden, **b)** stock real y virtual **antes** de recibir, **c)** lista de recepción (*Picking Operations*), **d)** la factura (*Bill*) confirmada.

**Receta** (flujo completo reproducible en [[06 - Operativa compra-venta#Flujo de compra (reproducible)]]):

1. **Apps** → instala *CRM*, *Purchase*, *Inventory* ([[05 - Administración funcional#Instalación de apps]]).
2. *Purchase → Create*: proveedor **Lumber Inc**; en pestaña *Products* la línea **Corner Desk Right Sit**, cantidad **5**, precio **500**. → **captura (a)** de la RFQ/orden.
3. **Confirm Order** → la RFQ pasa a orden de compra.
4. Abre la ficha del producto y mira los botones **On Hand** (real) y **Forecasted** (virtual): <mark style="background: #8000E1A6;">antes de recibir, el real no cambia y el virtual sube en 5</mark>. → **captura (b)**. ([[06 - Operativa compra-venta#Stock: on hand vs. forecasted]])
5. **Receive Products → Validate** la recepción; **Print → Picking Operations** (albarán). → **captura (c)**.
6. **Create Bill**, **Confirm** la factura de proveedor. → **captura (d)**.

> [!success]+ Comprobación
> Real (On Hand) = sin cambio antes de la recepción; Forecasted = +5. Tras *Validate*, On Hand sube. La *Bill* queda en estado *Posted*. Si lo entregas con esas 4 capturas, el ejercicio está.

---

## Ejercicio 2 — Python: copia/renombrado de BD (2 pts)

**Pide:** script con **1 parámetro** (nombre de BD); si no se pasa, error. Comprobar si existe. Si existe: **copiar** a `<bd>.copia` (solo si no existe el destino) + mensaje; **listar** BDs; pedir **confirmación** y **renombrar** a `<bd>_renombrada` (solo si no existe el destino) + mensaje; si cancela, mensaje; **listar** BDs.

➡️ **Script completo, listo para copiar:** [[07 - Servicios web XML-RPC#Ejercicio tipo examen — copia y renombrado de BD con confirmación]]

Estructura mental (servicio `db`, no necesita `authenticate`):

```python
from xmlrpc import client
import sys
server, port, master = "localhost", 8069, "master"     # master = la del pre-vuelo
db = client.ServerProxy('http://%s:%s/xmlrpc/2/db' % (server, port))

if len(sys.argv) != 2: print("Falta el parámetro"); sys.exit()   # validación
# db.db_exist(x) -> bool | db.list() -> [..] | db.duplicate_database(master, a, b) | db.rename(master, a, b)
```

- Ejecuta: `python ejercicio2.py junio26`
- Recuerda los **mensajes** en cada rama (copiado / ya existe / cancelado).
- Mecánica de `sys.argv` / `input` en [[01 - Python para Odoo#Python para los scripts de la API externa (lo que piden los ejercicios)]].

> [!warning]+
> No puedes duplicar/renombrar una BD con **sesión abierta** en el navegador → cierra sesión o reinicia Odoo si falla. La master incorrecta da `AccessDenied`.

---

## Ejercicio 3 — Python: listado de órdenes de compra (2 pts)

**Pide:** mostrar en **4 columnas alineadas** el nombre/código, el **Vendor**, el **Total** y la **Confirmation Date** de **todas** las órdenes de compra. Activar modo desarrollador para sacar modelo y campos.

➡️ **Script completo, listo para copiar:** [[07 - Servicios web XML-RPC#Ejercicio tipo examen — órdenes de compra en 4 columnas]]

Equivalencias (modelo `purchase.order`):

| Enunciado | Campo técnico |
| - | - |
| nombre/código | `name` |
| Vendor | `partner_id` |
| Total | `amount_total` |
| Confirmation Date | `date_approve` |

> [!warning]+ EL gotcha (te tira el ejercicio): los Many2one
> `partner_id` es un **Many2one** → `search_read` lo devuelve como **`[id, "nombre"]`**, no como texto. <mark style="background: #FF5582A6;">Imprime `o['partner_id'][1]`</mark> (y maneja `False` si está vacío: `o['partner_id'][1] if o['partner_id'] else '-'`). `date_approve` solo existe si el pedido está **confirmado** (las RFQ en borrador lo tienen a `False`).

- Patrón: `common.authenticate(...)` → `uid` → `models.execute_kw(db, uid, pwd, 'purchase.order', 'search_read', [[]], {'fields':[...]})`.
- Descubrir campos: modo desarrollador → pasar el ratón por el campo, o `Settings → Technical → Database Structure → Models`.
- Alineación de columnas: `"{0:<12} {1:<28} {2:>12.2f} {3}".format(...)` → [[01 - Python para Odoo#Python para los scripts de la API externa (lo que piden los ejercicios)]].

---

## Ejercicio 4 — Módulo Odoo (4 pts)

**Reconoce el patrón:** maestro `1—N` detalle, y el detalle `N—N` contactos. Es **Filmoteca con otros nombres** ([[19 - Variantes y práctica#El patrón maestro (reconócelo bajo cualquier disfraz)]]). Para "Ajedrez": **competición** (maestro) — **partida** (detalle) — **contrincantes** (`Many2many` a `res.partner`, máx. 2).

**Orden de trabajo (no teclees sin diseñar):** [[20 - Estrategia de examen y autoevaluación#Cómo afrontar el examen (orden de trabajo)]]

1. **Diseña** modelos/campos/tipos en papel ([[18 - Filmoteca paso a paso#Paso 0 — Leer el enunciado y diseñar los datos]]). Ojo a los **tipos** que fija el enunciado ("hora"/"año" suelen ser `Char`; "fecha"/"día" `Date`).
2. **Scaffold** → [[18 - Filmoteca paso a paso#Paso 1 — Entorno y scaffold]]:
   ```shell-session
   $ docker exec -itu root <contenedor> /usr/bin/odoo scaffold ajedrez /mnt/extra-addons
   ```
3. **`__manifest__.py`**: `'depends': ['base']`, y en `'data'` activa **`security/ir.model.access.csv`** y **`views/ajedrez.xml`**.
4. **`__init__.py`** (raíz → `from . import models`; y `models/__init__.py` → `from . import models`). Sin esto, el modelo no existe.
5. **Modelos** (esqueleto del patrón — adapta nombres/tipos):
   ```python
   # -*- coding: utf-8 -*-
   from odoo import models, fields, api
   from odoo.exceptions import ValidationError

   class Competicion(models.Model):
       _name = 'ajedrez.competicion'
       name = fields.Char(string="Competicion", required=True)
       lugar = fields.Char(string="Lugar")
       fecha = fields.Date(string="Fecha de comienzo")
       partida_ids = fields.One2many('ajedrez.partida', 'competicion_id', string="Partidas")

   class Partida(models.Model):
       _name = 'ajedrez.partida'
       numero = fields.Integer(string="Numero")
       dia = fields.Date(string="Dia")
       hora = fields.Char(string="Hora")
       competicion_id = fields.Many2one('ajedrez.competicion', ondelete='cascade', string="Competicion")
       contrincante_ids = fields.Many2many('res.partner', string="Contrincantes")

       @api.constrains('contrincante_ids')
       def _check_contrincantes(self):
           for r in self:
               if len(r.contrincante_ids) > 2:
                   raise ValidationError("El máximo de contrincantes es 2")
   ```
   - El `One2many` **necesita** su `Many2one` inverso con el **nombre exacto** (`competicion_id`).
   - **Constraint / límite** (las dos variantes, y por qué el modal del enunciado es un `onchange`): [[15 - Campos computados y onchange#Validar un máximo (máx. 2 contrincantes)]].
6. **CSV de seguridad** — una línea por modelo (`group_id` vacío = todos):
   ```csv
   id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
   access_ajedrez_competicion,ajedrez.competicion,model_ajedrez_competicion,,1,1,1,1
   access_ajedrez_partida,ajedrez.partida,model_ajedrez_partida,,1,1,1,1
   ```
7. **Vistas + acción + menú** (form con `<notebook>`, tree, search): copia la estructura de [[18 - Filmoteca paso a paso#Paso 0 — Leer el enunciado y diseñar los datos|Filmoteca]] (el fichero completo está en su **Apéndice**). Detalle de cada vista en [[12 - Vistas XML#Vista form (formulario)]] y [[12 - Vistas XML#Vista tree (listado)]]. **La acción se declara antes del menú**; el menú padre antes del hijo.
8. **Instala/Upgrade y comprueba** → [[18 - Filmoteca paso a paso#Paso 7 — Instalar y comprobar]]. *Update Apps List* → busca el módulo → *Install*. Crea un registro de prueba con sus detalles y contactos.

> [!tip]+ Diferencias "Ajedrez" vs Filmoteca (lo único que cambias)
> - El **tree de partidas** muestra también la competición (incluye `competicion_id` como columna).
> - El **form de partida** reparte en dos `<group>` lado a lado ("Partida": competición/número; "Horario": día/hora) + la lista de contrincantes.
> - Añades el **constraint** de máx. 2. Todo lo demás es el patrón calcado.

---

## Caja de pánico — errores típicos y arreglo

(Tabla completa: [[19 - Variantes y práctica#Errores típicos y su síntoma]]. Checklist de entrega: [[19 - Variantes y práctica#Checklist anti-error (antes de entregar)]]. Qué cuesta puntos: [[20 - Estrategia de examen y autoevaluación#Qué cuesta puntos (revisa antes de entregar)]].)

| Síntoma | Causa / arreglo |
| - | - |
| El modelo no aparece | falta `from . import models` en la cadena `__init__.py` → añadir, **reiniciar + Upgrade**. |
| "Access Denied" / no veo registros | falta la línea en `ir.model.access.csv` o está comentado en el manifest. |
| El menú no sale | no estás en **modo desarrollador** / Superuser, o el menú va antes que su acción/padre. |
| `Field ... does not exist` al cargar vista | nombre de campo mal, o tocaste el `.py` **sin reiniciar** Odoo. |
| Cambié un campo y sigue el viejo | un Upgrade no quita columnas → **desinstala + borra módulo + reinicia + reinstala**. |
| `One2many` sale vacío | el `Many2one` inverso no existe o el nombre no coincide. |
| Script Python: `AccessDenied` | **master password** incorrecta (Ej. 2). |
| Script: proveedor sale como `[7, 'Lumber Inc']` | es un **Many2one** → usa `o['campo'][1]` (Ej. 3). |
| Vista no carga / XML | raíz `<odoo>` **o** `<openerp>` bien abierta/cerrada, `<data>` dentro. No mezcles raíces. |

> [!important]+ Regla de oro del ciclo
> Tras tocar **`.py`** → **parar + reiniciar Odoo + Upgrade**. Tras tocar **`.xml`** → solo **Upgrade**. Es el error que más cae.

## Referencia rápida — campos y relaciones

| Tipo | Para qué |
| - | - |
| `fields.Char` | texto corto (nombre, hora, año, ISBN). |
| `fields.Text` | texto largo / multilínea (resumen). |
| `fields.Integer` / `fields.Float` | número entero / decimal (`digits=(6,2)`). |
| `fields.Date` / `fields.Datetime` | fecha / fecha+hora. |
| `fields.Boolean` | sí/no (`active` es especial: archiva el registro). |
| `fields.Selection` | lista cerrada de opciones. |
| `Many2one('modelo', ondelete='cascade')` | N→1, crea la clave foránea. Devuelve `[id, "nombre"]` por API. |
| `One2many('modelo', 'campo_inverso')` | 1→N, reflejo de un `Many2one`. No crea columna. |
| `Many2many('res.partner')` | N↔N (contactos/participantes), tabla intermedia. |

> [!info]+ Fundamentos enlazados
> Relaciones → [[10 - Relaciones entre modelos]] · Tipos de campo → [[09 - Modelos y tipos de campo]] · Vistas → [[12 - Vistas XML]] · Acciones/menús → [[13 - Acciones y menús]] · Seguridad CSV → [[14 - Seguridad y datos demo]] · API externa → [[07 - Servicios web XML-RPC]]. Índice del tema: [[Laboratorios.base|MOC de Laboratorios]].
