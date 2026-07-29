---
tags:
  - SIE/Laboratorio
  - SIE/Python
  - SIE
Descripción: "Odoo está escrito en Python. No hace falta dominar todo el lenguaje para aprobar el laboratorio: hace falta el subconjunto que aparece al programar módulos"
Fecha de actualización: 2026-05-31
Nota previa: ""
Nota siguiente: "[[02 - Ejercicios Python resueltos]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Python para Odoo

Odoo está escrito en Python. No hace falta dominar todo el lenguaje para aprobar el laboratorio: hace falta el subconjunto que aparece al **programar módulos**. Esta nota cubre ese subconjunto y traza el puente que sostiene todo lo demás: <mark style="background: #8000E1A6;">un modelo de Odoo no es más que una clase de Python que hereda de `models.Model`</mark>. Si entiendes clases y herencia, entiendes el 80% de un módulo.

## Qué es Python, en lo que nos importa

<mark style="background: #ADCCFFA6;">Python es un lenguaje interpretado, de tipado dinámico y con indentación significativa</mark>: no se declara el tipo de las variables y los bloques de código se delimitan por sangría (4 espacios), no por llaves. Esto último es la causa de error nº 1 al copiar código de un PDF: si mezclas tabuladores y espacios, Python falla con `IndentationError`.

```python
x = 10          # int, no declaras "int x"
x = "ahora str" # válido: el tipo lo lleva el valor, no la variable
```

## Tipos y colecciones que vas a usar en Odoo

No necesitas todas las estructuras de datos, pero dos son omnipresentes en la API de Odoo:

- <mark style="background: #FFB8EBA6;">El diccionario (`dict`) es cómo se pasan los valores de un registro</mark>: `create` y `write` reciben `{'name': 'Matrix', 'year': '1999'}`; un `onchange` devuelve `{'warning': {...}}`.
- <mark style="background: #FFB8EBA6;">La lista (`list`) es cómo se expresan los dominios de búsqueda</mark>: `[['city', '=', 'Madrid']]`, y la lista de ficheros `data`/`demo` del manifest.

```python
entero   = 1999
texto    = "Neo"
booleano = True
lista    = [1, 2, 3]                 # ordenada, mutable
tupla    = (6, 2)                     # inmutable (p. ej. digits=(6,2))
diccionario = {"name": "Neo", "edad": 37}   # clave → valor
```

Las cadenas formateadas (`f-strings`) son la forma moderna de interpolar: `f"Hola {nombre}"`.

## Funciones

Se definen con `def`, reciben parámetros (con valores por defecto opcionales) y devuelven con `return`. Un **método** es simplemente una función definida dentro de una clase.

```python
def taken_seats(asistentes, plazas):
    if not plazas:
        return 0.0
    return 100.0 * len(asistentes) / plazas
```

## Programación orientada a objetos: el corazón de Odoo

Una **clase** es una plantilla que agrupa datos (atributos) y comportamiento (métodos). Se instancia para crear objetos.

```python
class Persona:
    def __init__(self, nombre, edad):   # constructor
        self.nombre = nombre            # atributo de instancia
        self.edad = edad

    def saludar(self):                  # método; self = la instancia
        return f"Soy {self.nombre}"

p = Persona("Neo", 37)
print(p.saludar())
```

Tres piezas que reaparecen tal cual en Odoo:

- <mark style="background: #ADCCFFA6;">`self` es la referencia a la instancia actual</mark>; todo método de modelo en Odoo lo recibe como primer parámetro y lo recorre (`for r in self:`).
- `__init__` es el constructor. <mark style="background: #FFB8EBA6;">Ojo: en Odoo casi nunca escribes `__init__`</mark>; los campos se declaran como **atributos de clase** (`name = fields.Char()`), y el ORM se encarga de construir los registros.
- La **herencia** permite que una clase derive de otra y reutilice/añada comportamiento.

```python
class Empleado(Persona):                # Empleado hereda de Persona
    def __init__(self, nombre, edad, sueldo=1000):
        super().__init__(nombre, edad)  # llama al constructor del padre
        self.sueldo = sueldo
```

<mark style="background: #8000E1A6;">Cuando en el módulo escribes `class Course(models.Model)`, estás haciendo exactamente esto: heredar de la clase base de Odoo para obtener gratis toda la maquinaria del ORM</mark> (persistencia en PostgreSQL, vistas, permisos). Y `_inherit = 'res.partner'` es herencia aplicada a un modelo que ya existe, para ampliarlo sin tocar su código.

## Decoradores

Un <mark style="background: #ADCCFFA6;">decorador es una marca encima de una función (`@algo`) que modifica o anota su comportamiento</mark>. No necesitas escribir decoradores propios; necesitas reconocer los de Odoo y saber qué registran:

- `@api.depends('seats', 'attendee_ids')` → marca un **campo computado**: recalcula cuando cambian esos campos.
- `@api.onchange('seats')` → dispara el método en el formulario al cambiar el campo, antes de guardar.
- `@api.constrains(...)` / `@api.model` → validaciones e métodos a nivel de modelo.

```python
@api.depends('seats', 'attendee_ids')
def _taken_seats(self):
    for r in self:
        r.taken_seats = 100.0 * len(r.attendee_ids) / r.seats if r.seats else 0.0
```

## Módulos, paquetes e imports

`import` trae código de otro fichero; `from x import y` trae un nombre concreto. En un módulo Odoo esto se materializa en los `__init__.py`: `from . import models` hace que Python (y por tanto Odoo) cargue tu fichero `models.py`. Un directorio con `__init__.py` es un **paquete**. Por eso, <mark style="background: #FF5582A6;">si tu modelo no aparece en Odoo, lo primero que debes revisar es si está importado en la cadena de `__init__.py`</mark>.

## Excepciones

`try` / `except` captura errores en tiempo de ejecución para no abortar el programa. En la API externa (servicios web) capturarás `ValueError`, `IndexError`, etc. Dentro de un módulo, Odoo ofrece sus propias excepciones para abortar una operación con un mensaje al usuario:

```python
from odoo.exceptions import ValidationError, UserError
raise ValidationError("El año no puede ser negativo")
```

## Python para los scripts de la API externa (lo que piden los ejercicios)

Los ejercicios de **API externa** del examen (gestión de BD y listados de datos) son **scripts de consola**: reciben argumentos, validan, conectan por XML-RPC, recorren resultados y los imprimen. La parte XML-RPC (conectar, `authenticate`, `execute_kw`) vive en [[07 - Servicios web XML-RPC]]; aquí va el Python "de alrededor" que necesitas para que el script aguante el enunciado.

### Argumentos de línea de comandos (`sys.argv`)

`sys.argv` es la lista de argumentos; `sys.argv[0]` es el nombre del script, así que el primer parámetro real es `sys.argv[1]`. <mark style="background: #FF5582A6;">Casi todos los enunciados empiezan por "valida que se ha pasado el parámetro"</mark>:

```python
import sys
if len(sys.argv) != 2:                       # se exige exactamente 1 parámetro
    print("Uso: %s <nombre_bd>" % sys.argv[0])
    sys.exit()                               # corta el programa
nombre = sys.argv[1]
```

- `len(sys.argv) != 2` → "exactamente un parámetro" (el script + 1). Para "al menos uno" sería `< 2`.
- `sys.exit()` aborta limpiamente; úsalo tras imprimir el mensaje de error en cada validación que falle.

### Confirmación del usuario (`input`)

Para operaciones destructivas o irreversibles (borrar/renombrar una BD), el enunciado pide **confirmar** antes de actuar:

```python
if input("¿Seguro? (s/n) ") == "s":
    ...  # acción
else:
    print("Operación cancelada")
```

### Salida en columnas alineadas

El "muestra en 4 columnas bien alineadas" se resuelve con el **formato de campo** de Python. Tres notaciones equivalentes (el profesor usa la primera):

```python
nombre, ciudad, precio = "ACME", "Madrid", 19.5
print("{0:<20s} {1:<15} {2:>8.2f}".format(nombre, ciudad, precio))  # estilo profe (.format)
print(f"{nombre:<20} {ciudad:<15} {precio:>8.2f}")                  # f-string (moderno)
print("%-20s %-15s %8.2f" % (nombre, ciudad, precio))               # estilo % (C)
```

- `:<20` alinea a la **izquierda** en 20 caracteres; `:>8` a la **derecha** en 8; `:^10` centra.
- `.2f` = 2 decimales para `float`. Combinado, `>8.2f` = "derecha, ancho 8, 2 decimales".
- Imprime primero una fila de cabecera con los mismos anchos y las columnas cuadran.

### Capturar errores (`try`/`except`)

La API lanza excepciones si la conexión falla o el servidor devuelve un error. Envuelve lo arriesgado:

```python
import sys, xmlrpc.client
try:
    uid = common.authenticate(db, user, pwd, {})
except ConnectionRefusedError:
    print("¿Está Odoo levantado en ese puerto?"); sys.exit()
except xmlrpc.client.Fault as e:
    print("Error del servidor:", e.faultString); sys.exit()
```

> [!info]+ Esqueleto mental de un script de API
> `imports` → leer/validar `sys.argv` → datos de conexión (`server`, `port`, y `master` o `user`+`pwd`) → crear el `ServerProxy` del servicio (`db`, o `common`+`object`) → operación → imprimir resultados. Tienes los **dos scripts completos resueltos** (listado de `purchase.order` y copia/renombrado de BD) en [[07 - Servicios web XML-RPC]], y más práctica de `sys.argv`, ficheros e `input` en [[02 - Ejercicios Python resueltos]].

> [!info]+
> Estilo del profesor: su código Python es deliberadamente informal (no sigue PEP 8 al pie de la letra) — cabeceras `#!/usr/bin/python3` + `# coding: utf-8`, comentarios en español, variables cortas (`l`, `c`, `n`), sin espacios alrededor del `=`. Para los ejercicios lo replicaremos donde convenga, pero en el código del módulo conviene un estilo limpio. Ver [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].

> [!important]+
> Resumen operativo del puente Python → Odoo: **clase = modelo**, **herencia = `models.Model` / `_inherit`**, **atributo de clase = campo**, **método con `self` = lógica del modelo**, **decorador = registro de comportamiento en el ORM**, **`__init__.py` = qué se carga**. Con esto entras a [[08 - Estructura de un módulo y scaffold]] sin sorpresas.

Practica estos conceptos resolviendo los ejercicios oficiales: [[02 - Ejercicios Python resueltos]].
