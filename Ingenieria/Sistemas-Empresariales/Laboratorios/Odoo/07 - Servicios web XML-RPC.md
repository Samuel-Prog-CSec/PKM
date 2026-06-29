---
tags:
  - SIE/Laboratorio
  - SIE/Odoo
  - SIE
Fecha de actualización: 2026-05-31
Nota previa: "[[06 - Operativa compra-venta]]"
Nota siguiente: "[[08 - Estructura de un módulo y scaffold]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Servicios web XML-RPC

Odoo expone una **API externa** por XML-RPC: desde un script Python puedes gestionar bases de datos, autenticarte y operar sobre cualquier modelo sin tocar la interfaz. Esta nota resuelve los ejercicios de la Práctica 4 con su razonamiento. Lo importante de fondo: <mark style="background: #8000E1A6;">las operaciones que usas aquí "desde fuera" (`search`, `read`, `create`, `write`) son el mismo ORM que programarás "desde dentro" en los módulos</mark> — entenderlo aquí facilita [[09 - Modelos y tipos de campo]].

## Los tres servicios y la conexión

<mark style="background: #ADCCFFA6;">Odoo ofrece tres servicios web en `/xmlrpc/2/`: `db` (gestión de bases de datos), `common` (autenticación) y `object` (acceso a los modelos).</mark> Conectar es crear un *proxy* contra el endpoint:

```python
from xmlrpc import client
conn = client.ServerProxy('http://%s:%s/xmlrpc/2/%s' % (server, port, ws))
# server = "localhost", port = 8069, ws = 'db' | 'common' | 'object'
```

## Servicio `db`

Métodos: `list()`, `db_exist(name)`, `create_database(master, name, demo, lang, pwd)`, `duplicate_database(master, orig, new)`, `rename(master, old, new)`, `drop(master, name)`, `change_admin_password(master, pwd)`, `list_lang()`.

**Ejemplo del profesor (`2.py`) — listar bases de datos:**

```python
#!/usr/bin/python3
# coding: utf-8
from xmlrpc import client
server, port = "localhost", 8069
conn = client.ServerProxy('http://%s:%s/xmlrpc/2/%s' % (server, port, 'db'))
for nombre in conn.list():
    print(nombre)
```

> [!warning]+ La master password
> Las operaciones `create_database`, `duplicate_database`, `rename` y `drop` exigen la **clave máster** del servidor (el `admin_passwd` de `odoo.conf`), **no** la del usuario `admin`. <mark style="background: #FFB8EBA6;">En el lab la fijamos a `master` al crear la base de datos</mark> (Práctica 2); en un Odoo recién instalado el valor por defecto es `admin`. En el examen creas tú la BD nueva: **la clave máster que teclees al crear `junio26` es la que deben usar tus scripts**. Si `duplicate`/`rename` devuelven `AccessDenied`, la master es incorrecta.

**Ejercicio 3 — crear una BD pasada por parámetro**, validando que se pasó argumento y que no existe ya. Decisión: `sys.argv` para el parámetro y `db_exist` para no duplicar; mensajes de error claros.

```python
#!/usr/bin/python3
# coding: utf-8
from xmlrpc import client
import sys
server, port, master = "localhost", 8069, "master"
db = client.ServerProxy('http://%s:%s/xmlrpc/2/db' % (server, port))

if len(sys.argv) < 2:
    print("Falta el nombre de la base de datos"); sys.exit()
nombre = sys.argv[1]
if db.db_exist(nombre):
    print("La base de datos ya existe"); sys.exit()

db.create_database(master, nombre, True, 'en_US', 'admin')   # demo=True
print("Creada:", db.list())
```

**Ejercicio 4 — renombrar**: dos parámetros; la `actual` debe existir y la `futura` no.

```python
if len(sys.argv) < 3:
    print("Uso: rename.py <actual> <futura>"); sys.exit()
actual, futura = sys.argv[1], sys.argv[2]
if not db.db_exist(actual):  print("La BD origen no existe"); sys.exit()
if db.db_exist(futura):      print("La BD destino ya existe"); sys.exit()
db.rename(master, actual, futura)
```

**Ejercicio 5 — borrar con confirmación**: pedir `input` antes de la operación destructiva.

```python
if len(sys.argv) < 2:           print("Falta el nombre"); sys.exit()
nombre = sys.argv[1]
if not db.db_exist(nombre):     print("No existe"); sys.exit()
if input(f"¿Borrar {nombre}? (s/n) ") == "s":
    db.drop(master, nombre); print("Borrada")
```

> [!warning]+
> `drop` es irreversible. El `input` de confirmación no es un capricho del enunciado: es la práctica correcta ante cualquier operación destructiva (la misma idea que `unlink` en el ejercicio 12).

## Servicio `common`

`authenticate(db, login, password, {})` devuelve el **uid** (o `False`); `version()` y `about()` dan información del servidor.

**Ejercicio 7 — version y about:**

```python
common = client.ServerProxy('http://%s:%s/xmlrpc/2/common' % (server, port))
print(common.version())
print(common.about(True))
```

## Servicio `object`: `execute_kw` y dominios

Un único método para todo: `execute_kw(db, uid, pwd, modelo, método, args, kw=None)`. El `método` es una de las operaciones del ORM y `args` lleva sus parámetros. <mark style="background: #ADCCFFA6;">Un dominio es una lista de criterios `[['campo', 'operador', 'valor'], ...]`</mark>; varias condiciones en la lista se combinan con AND por defecto.

| Operador             | Significado                                   |
| -------------------- | --------------------------------------------- |
| `=`, `!=`            | igualdad / desigualdad                        |
| `>`, `<`, `>=`, `<=` | comparación                                   |
| `like`, `ilike`      | subcadena (ilike = sin distinguir mayúsculas) |
| `in`, `not in`       | pertenencia a una lista                       |
| `'&'` ,`'\|'` ,`'!'` | AND / OR / NOT explícitos (notación prefija)  |

```
models.execute_kw(db, uid, pwd, modelo, método, args [, kwargs])
```

|Posición|Qué es|Ejemplo|
|---|---|---|
|`db, uid, pwd`|el «bloque credencial» (se repite en cada llamada)|`"junio26", uid, "admin"`|
|`modelo`|`str`: el modelo Odoo|`'purchase.order'`|
|`método`|`str`: la operación del ORM|`'search_read'`|
|`args`|`list`: los parámetros posicionales del método|`[[]]`|
|`kwargs`|`dict` opcional: parámetros con nombre|`{'fields': ['name']}`|

### Las operaciones del ORM (el `método`)

| Método                        | Recibe                  | Devuelve           |
| ----------------------------- | ----------------------- | ------------------ |
| `search`                      | un dominio              | `list` de **ids**  |
| `search_count`                | un dominio              | `int` (cuántos)    |
| `read`                        | ids + `fields`          | `list` de **dict** |
| `search_read` (find completo) | dominio + `fields`      | `list` de **dict** |
| `create`                      | un `dict` de valores    | el **id** nuevo    |
| `write` (es un update)        | ids + `dict` de valores | `True`             |
| `unlink` (es un delete)       | ids                     | `True`             |

```python
ids   = obj.execute_kw(db, uid, pwd, 'res.partner', 'search', [[['is_company','=',True]]])
recs  = obj.execute_kw(db, uid, pwd, 'res.partner', 'read', [ids], {'fields': ['name','city']})
# search + read en un paso:
recs  = obj.execute_kw(db, uid, pwd, 'res.partner', 'search_read',
                       [[['is_company','=',True]]], {'fields': ['name','city']})
nuevo = obj.execute_kw(db, uid, pwd, 'res.partner', 'create', [{'name':'ACME'}])
obj.execute_kw(db, uid, pwd, 'res.partner', 'write', [[nuevo], {'city':'Madrid'}])
obj.execute_kw(db, uid, pwd, 'res.partner', 'unlink', [[nuevo]])
```

## Ejemplo del profesor (`8.py`) — compañías por ciudad

Busca contactos que son compañías, filtrando por ciudad si se pasa parámetro, y muestra nombre y ciudad:

```python
#!/usr/bin/python3
# coding: utf-8
from xmlrpc import client
import sys
server, port = "localhost", 8069
dbname, user, pwd = "bd", "admin", "admin"

common = client.ServerProxy('http://%s:%s/xmlrpc/2/common' % (server, port))
uid = common.authenticate(dbname, user, pwd, {})
models = client.ServerProxy('http://%s:%s/xmlrpc/2/object' % (server, port))

if len(sys.argv) > 1:
    dominio = [['city', '=', sys.argv[1]], ['is_company', '=', True]]
else:
    dominio = [['is_company', '=', True]]

ids = models.execute_kw(dbname, uid, pwd, 'res.partner', 'search', [dominio])
companias = models.execute_kw(dbname, uid, pwd, 'res.partner', 'read',
                              [ids], {'fields': ['name', 'city']})
for c in companias:
    print("{0:<20s} {1}".format(c['city'], c['name']))
```

> [!warning]+
> El profesor nombra `object` al proxy del servicio `object`. `object` es un **builtin** de Python (la clase base de todo): usarlo como variable lo "pisa" en ese ámbito. Funciona, pero es mala práctica; aquí uso `models` (el nombre que emplea la documentación oficial de Odoo). Si en el examen replicas su estilo, al menos sé consciente de la sombra.

## Ejercicios de contactos resueltos

Reutilizan `uid`, `models`, `dbname`, `pwd` ya definidos.

**Ejercicio 9 — contactos que NO son compañía y NO son de la ciudad dada; mostrar nombre, ciudad y email.** Decisión: dominio con `!=` y `search_read` para hacerlo en un paso; salir con error si no hay parámetro.

```python
if len(sys.argv) < 2:
    print("Falta la ciudad"); sys.exit()
dominio = [['is_company', '=', False], ['city', '!=', sys.argv[1]]]
for c in models.execute_kw(dbname, uid, pwd, 'res.partner', 'search_read',
                           [dominio], {'fields': ['name','city','email']}):
    print(c['name'], c['city'], c['email'])
```

**Ejercicio 10 — todos los contactos (compañías y personas), nombre y email.** Dominio vacío `[[]]` = sin filtro.

```python
for c in models.execute_kw(dbname, uid, pwd, 'res.partner', 'search_read',
                           [[]], {'fields': ['name','email']}):
    print(c['name'], c['email'])
```

**Ejercicio 11 — crear compañía y persona de contacto asociada.** La clave es el campo `parent_id`: <mark style="background: #FF5582A6;">se asocia la persona a la compañía pasando el `id` de la compañía en `parent_id`</mark>. Crear solo si no existe.

```python
existe = models.execute_kw(dbname, uid, pwd, 'res.partner', 'search',
                           [[['name','=','ACME'], ['is_company','=',True]]])
if not existe:
    cia = models.execute_kw(dbname, uid, pwd, 'res.partner', 'create',
                            [{'name':'ACME', 'is_company':True}])
    models.execute_kw(dbname, uid, pwd, 'res.partner', 'create', [{
        'name':'Ana Pérez', 'parent_id':cia, 'type':'contact',
        'street':'C/ Mayor 1', 'zip':'02001', 'city':'Albacete',
        'phone':'967000000', 'email':'ana@acme.com'}])
```

**Ejercicio 12 — borrar el contacto creado, con confirmación.**

```python
ids = models.execute_kw(dbname, uid, pwd, 'res.partner', 'search',
                        [[['name','=','Ana Pérez']]])
if not ids:
    print("No existe")
elif input("¿Borrar el contacto? (s/n) ") == "s":
    models.execute_kw(dbname, uid, pwd, 'res.partner', 'unlink', [ids])
```

**Ejercicio 13 — contactos del cliente "Azure Interior": nombre, tipo, ciudad y email.** Se filtran por `parent_id` resolviendo primero el id de la compañía.

```python
cia = models.execute_kw(dbname, uid, pwd, 'res.partner', 'search',
                        [[['name','=','Azure Interior'], ['is_company','=',True]]])
for c in models.execute_kw(dbname, uid, pwd, 'res.partner', 'search_read',
                           [[['parent_id','=',cia[0]]]],
                           {'fields': ['name','type','city','email']}):
    print(c['name'], c['type'], c['city'], c['email'])
```

## Ejercicio 14 — productos en 4 columnas

Mostrar referencia interna, nombre, precio de venta y tipo de todos los productos, alineados en columnas. El modelo es `product.template`; los campos se descubren con el **modo desarrollador** (necesita la app `Purchase`).

```python
for p in models.execute_kw(dbname, uid, pwd, 'product.template', 'search_read',
        [[]], {'fields': ['default_code','name','list_price','type']}):
    print("{0:<10} {1:<30} {2:>8} {3}".format(
        p['default_code'] or '-', p['name'], p['list_price'], p['type']))
```

> [!info]+
> `"{0:<10}"` alinea a la izquierda en 10 caracteres, `"{2:>8}"` a la derecha en 8: así salen las columnas cuadradas. `default_code` es la "Internal Reference" y `list_price` el "Sales Price" — nombres internos que solo descubres con el modo desarrollador.

## ¿Cómo descubrir los nombres técnicos de los `fields`?
### Método 1 — Modo desarrollador (en la web)

Es lo que pide explícitamente el enunciado del examen. Actívalo en _Settings → Activate the developer mode_. Con él activo, tienes dos vías:

- **Pasar el ratón** por encima de un campo en un formulario → un tooltip muestra su _nombre técnico_ y su tipo.
- _Settings → Technical → Database Structure → Models_ → busca `purchase.order` (o el modelo) → pestaña _Fields_: la lista completa de campos con nombre, etiqueta y tipo.

### Método 2 — `fields_get` (la forma del programador)

El servicio `object` tiene un método, `fields_get`, que **te describe todos los campos de un modelo**. Le pides solo lo que te interesa (la etiqueta y el tipo):

```Python
campos = models.execute_kw(dbname, uid, pwd, 'purchase.order', 'fields_get',
                           [], {'attributes': ['string', 'type']})
```

Devuelve un `dict` `{nombre_tecnico: {'string': etiqueta, 'type': tipo}}`. Filtrando los 4 del enunciado en tu `junio26` sale **exactamente** esto:

```
name             type=char         label=Order Reference
partner_id       type=many2one     label=Vendor
amount_total     type=monetary     label=Total
date_approve     type=datetime     label=Confirmation Date
```

#### Función para filtrar los `label`
```Python
label = ['Confirmation Date', 'Total', 'Vendor'] # Los que nos digan en el enunciado

for n, info in campos.items():
    if info['string'] in label:
        print(label[label.index(info['string'])], ' -> ', n, info['type'])
```

## Tipo Odoo → qué devuelve por XML-RPC

Esta es la chuleta que de verdad importa. El **tipo** del campo decide el valor que recibes en Python:

| Tipo (Odoo)             | Devuelve si tiene valor       | Si está vacío |
| ----------------------- | ----------------------------- | ------------- |
| `char`, `text`, `html`  | `str`                         | `False`       |
| `integer`               | `int`                         | `0`           |
| `float`, `monetary`     | `float`                       | `0.0`         |
| `boolean`               | `True` / `False`              | `False`       |
| `date`                  | `str` `'YYYY-MM-DD'`          | `False`       |
| `datetime`              | `str` `'YYYY-MM-DD HH:MM:SS'` | `False`       |
| `selection`             | `str` (la clave interna)      | `False`       |
| `many2one`              | `[id, "nombre"]` (lista)      | `False`       |
| `one2many`, `many2many` | `[id, id, …]` (lista de ids)  | `[]`          |

## Ejercicio tipo examen — órdenes de compra en 4 columnas

Variante del ejercicio 14 sobre el modelo de compras, tal como lo pide el examen: mostrar en 4 columnas alineadas el **nombre/código**, el **proveedor** (`Vendor`), el **total** (`Total`) y la **fecha de confirmación** (`Confirmation Date`) de **todas** las órdenes de compra. El modelo es `purchase.order`.

```python
#!/usr/bin/python3
# coding: utf-8
from xmlrpc import client
server, port = "localhost", 8069
dbname, user, pwd = "junio26", "admin", "admin"

common = client.ServerProxy('http://%s:%s/xmlrpc/2/common' % (server, port))
uid = common.authenticate(dbname, user, pwd, {})
models = client.ServerProxy('http://%s:%s/xmlrpc/2/object' % (server, port))

ordenes = models.execute_kw(dbname, uid, pwd, 'purchase.order', 'search_read',
    [[]], {'fields': ['name', 'partner_id', 'amount_total', 'date_approve']})

print("{0:<12} {1:<28} {2:>12} {3}".format("Pedido", "Proveedor", "Total", "Confirmacion"))
for o in ordenes:
    proveedor = o['partner_id'][1] if o['partner_id'] else '-'
    fecha = o['date_approve'] or '-'
    print("{0:<12} {1:<28} {2:>12.2f} {3}".format(o['name'], proveedor, o['amount_total'], fecha))
```

> [!warning]+ El gotcha que tira a todo el mundo: los Many2one
> Un campo `Many2one` (como `partner_id`) **no** devuelve texto: `search_read` lo entrega como lista `[id, "nombre"]`. <mark style="background: #FF5582A6;">Para imprimir el proveedor necesitas `o['partner_id'][1]`, no `o['partner_id']`</mark>. Y si la orden no tiene proveedor el valor es `False`; de ahí el `if o['partner_id'] else '-'`. Igual con las fechas que pueden venir vacías: <mark style="background: #FFB8EBA6;">`date_approve` solo se rellena al **confirmar** el pedido</mark> — las RFQ en borrador lo tienen a `False`.

> [!info]+ Cómo descubrir el modelo y los campos
> Activa el **modo desarrollador** ([[05 - Administración funcional#Modo desarrollador]]). Con él, al pasar el ratón sobre un campo del formulario de la orden ves su nombre técnico; o ve a `Settings → Technical → Database Structure → Models`, busca `purchase.order` y revisa sus campos. Equivalencias del enunciado: `Vendor` = `partner_id`, `Total` = `amount_total`, `Confirmation Date` = `date_approve`, nombre/código = `name`. Necesitas la app `Purchase` instalada.

## Ejercicio tipo examen — copia y renombrado de BD con confirmación

Fusiona los ejercicios 3-5 en el flujo exacto del examen: recibe **un** argumento (el nombre de la BD), comprueba que existe, la **duplica** a `<bd>.copia` (solo si el destino no existe), lista las BDs, pide **confirmación** para renombrar la original a `<bd>_renombrada` (solo si el destino no existe), y lista de nuevo.

```python
#!/usr/bin/python3
# coding: utf-8
from xmlrpc import client
import sys

server, port, master = "localhost", 8069, "master"
db = client.ServerProxy('http://%s:%s/xmlrpc/2/db' % (server, port))

# 1) Exactamente un parámetro
if len(sys.argv) != 2:
    print("Uso: %s <nombre_bd>" % sys.argv[0]); sys.exit()
nombre = sys.argv[1]

# 2) La BD de origen debe existir
if not db.db_exist(nombre):
    print("La base de datos '%s' no existe" % nombre); sys.exit()

# 3) Copia -> <nombre>.copia, solo si el destino no existe
copia = nombre + ".copia"
if db.db_exist(copia):
    print("No se copia: '%s' ya existe" % copia)
else:
    db.duplicate_database(master, nombre, copia)
    print("Copia creada: '%s'" % copia)

# 4) Listado de bases de datos
print("Bases de datos:", db.list())

# 5) Confirmación para renombrar -> <nombre>_renombrada
renombrada = nombre + "_renombrada"
if input("¿Renombrar '%s' a '%s'? (s/n) " % (nombre, renombrada)) == "s":
    if db.db_exist(renombrada):
        print("No se renombra: '%s' ya existe" % renombrada)
    else:
        db.rename(master, nombre, renombrada)
        print("Renombrada: '%s' -> '%s'" % (nombre, renombrada))
else:
    print("Renombrado cancelado")

# 6) Listado final
print("Bases de datos:", db.list())
```

> [!warning]+
> `duplicate_database` y `rename` necesitan la **master password** correcta (callout de la sección `Servicio db`). Además, Odoo no renombra ni duplica una BD con **sesiones abiertas**: si falla, cierra sesión en el navegador o reinicia Odoo. El nombre `bd.copia` con punto es válido.

> [!question]- Comprueba: ¿qué diferencia hay entre hacer `search` y luego `read`, frente a `search_read`?
> `search` devuelve solo los **ids** que cumplen el dominio; `read` recibe esos ids y devuelve los **campos**. `search_read` hace ambas cosas en **una sola llamada** — más eficiente cuando solo quieres leer.

> [!question]- Comprueba: por API, ¿cómo asocias una persona de contacto a su compañía?
> Pasando el `id` de la compañía en el campo `parent_id` al crear la persona: `create([{'name':'Ana', 'parent_id': id_compania}])`. Es el campo que enlaza persona↔compañía en `res.partner`.

> [!important]+
> Patrón común a todos los ejercicios: **conectar → autenticar (uid) → `execute_kw`** con un dominio. Si dominas `search`/`read`/`create`/`write`/`unlink` y los dominios, dominas el ORM, que es exactamente lo que vas a definir al programar modelos. Entras a la parte central: [[08 - Estructura de un módulo y scaffold]].
