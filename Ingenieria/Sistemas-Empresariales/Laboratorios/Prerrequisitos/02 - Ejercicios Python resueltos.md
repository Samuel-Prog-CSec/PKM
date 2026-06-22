---
tags:
  - SIE/Laboratorio
  - SIE/Python
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[01 - Python para Odoo]]"
Nota siguiente: "[[03 - Docker para Odoo]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Ejercicios Python resueltos

Los 40 ejercicios oficiales, resueltos **decisión a decisión**. No reproduzco la solución del profesor tal cual: escribo la mía y explico *por qué*, señalando con coral los idioms que <mark style="background: #FF5582A6;">reaparecen al programar en Odoo</mark>. Cada bloque añade un concepto sobre el anterior. Conserva las cabeceras `#!/usr/bin/python3` y `# coding: utf-8` que el profesor pone siempre.

## 1 — Primer programa

```python
print("Hola mundo")
```

`print()` escribe en salida estándar y añade salto de línea. Es la herramienta de depuración nº 1.

## 2-8 — Tipos básicos y operadores

**Ej. 2** (tipos y `type`). Decisión: usar `type()` para *demostrar* el tipado dinámico — Python infiere el tipo del valor.

```python
c = "Hola"; e = 23; r1 = 0.1e-13; r2 = 1.27
for v in (c, e, r1, r2):
    print(v, type(v))
```

**Ej. 3-4** (aritmética y división). La clave es distinguir `/` (división real, siempre `float`) de `//` (división entera). Forzar un operando a `float()` cambia el resultado de `//`:

```python
a, b = 3, 5
print(a / b)        # 0.6
print(a // b)       # 0  (entera)
print(float(a) // b)  # 0.0  (entera pero en float)
print(a % b, a ** b)  # módulo y potencia
```

> [!info]+
> El operador `%` (módulo) lo usarás en el generador del ejercicio 33 y en cualquier comprobación "par/impar". `**` es potencia, no XOR.

**Ej. 5** (cadenas especiales). Tres decisiones: `r"\n"` es *raw string* (no interpreta el escape), `"""..."""` permite multilínea, y una cadena normal con `\n` sí salta de línea.

```python
print("salto\naquí")           # interpreta \n
print(r"\n literal")           # raw: muestra \n
print("""línea 1
línea 2""")                    # triple comilla = multilínea
```

**Ej. 6-8** (operadores con cadenas, booleanos y comparación). `+` concatena y `*` repite cadenas; `and`/`or`/`not` operan sobre booleanos; `==`, `!=`, `<`, `>` devuelven `bool`.

```python
a, b = "aaA", "bbB"
print(a + b, a * 2)            # 'aaAbbB'  'aaAaaA'
print(True and False, True or False, not True)
print(3 == 5, 3 != 5, 3 < 5)
```

## 9-12 — Colecciones

**Ej. 9-10** (listas: indexación, *slicing*, mutabilidad). El *slicing* `l[inicio:fin:paso]` no incluye `fin`; el índice negativo cuenta desde el final. Las listas son **mutables**: se pueden reasignar elementos e incluso rangos.

```python
l = ["cadena", 11, False, [1, 2], 3.0]
print(l[0], l[3][0], l[-1])    # primer elem, sublista[0], último
print(l[0:3], l[0:5:2])        # rebanada y rebanada de 2 en 2
l[2] = True                    # mutar un elemento
l[0:2] = ["nueva", 2]          # mutar un rango
```

**Ej. 11** (tupla, inmutable). La decisión didáctica es *provocar* el error: `t[0] = 1` lanza `TypeError`. <mark style="background: #FFB8EBA6;">Las tuplas se usan en Odoo para `digits=(6, 2)`</mark> precisamente porque no deben cambiar.

**Ej. 12** (diccionario). Acceso por clave, no por posición. <mark style="background: #FF5582A6;">El `dict` es la estructura que más usarás en Odoo</mark> (valores de `create`/`write`).

```python
d = {"Pedro": "Madrid", "Ana": "Barcelona"}
print(d["Ana"])                # Barcelona
d["Pedro"] = "Albacete"        # actualizar valor
```

## 13-18 — Control de flujo

**Ej. 13-14** (`if/elif/else` y ternario). El ternario `valor_si if cond else valor_no` condensa una asignación condicional en una línea — idiom muy usado en campos computados de Odoo.

```python
a, b = 11, 10
if a == b:   print("igual")
elif a < b:  print("menor")
else:        print("mayor")

par = "par" if a % 2 == 0 else "impar"   # ← este patrón reaparece en Odoo
```

**Ej. 15-18** (`while`, concatenar listas, `input`+`break`, `for`). Resuelvo el 16 más limpio que la versión con lista auxiliar del profesor, usando `range`:

```python
# 15: contar de 20 a 1
i = 20
while i > 0:
    print(i); i -= 1

# 16: misma secuencia en una lista (mi versión, más directa)
l = list(range(20, 0, -1))     # [20, 19, ..., 1]

# 17: pedir palabras hasta "fin"
while True:
    if input("> ") == "fin":
        break

# 18: recorrer la lista
for x in l:
    print(x)
```

> [!info]+
> El profesor construye la lista del 16 concatenando con `l = l + laux` dentro de un `while`. Funciona, pero `range(20, 0, -1)` o un `for` con `append` es lo idiomático. Lo señalo como ejemplo de "su solución vs. la forma limpia".

## 19-21 — Funciones

`*args` recoge un número variable de argumentos en una tupla; `return a, b` devuelve una tupla que se puede **desempaquetar**.

```python
def suma(p1, p2):
    return p1 + p2             # sirve para números y para cadenas

def parametros(*args):         # número variable
    for a in args: print(a)
    print(args)                # la tupla completa

def sum_prod(x, y):
    return x + y, x * y        # devuelve tupla
s, p = sum_prod(3, 6)          # desempaquetado
```

## 22-23 — Orientación a objetos (el puente a Odoo)

**Ej. 22 — clase `Contador`** con rango. Decisión clave: validar el rango en `__init__` y mantener el invariante en cada método. <mark style="background: #8000E1A6;">Esta lógica "no salirse de un rango" es idéntica a la del `onchange` de plazas en Odoo</mark> (ejercicio del módulo openacademy).

```python
class Contador:
    """Contador acotado a [menor, mayor]."""
    def __init__(self, inicial, menor, mayor):
        self.menor, self.mayor = menor, mayor
        self.contador = max(menor, min(inicial, mayor))   # encajar en rango

    def incrementa(self, inc=1):
        self.contador = min(self.contador + inc, self.mayor)

    def decrementa(self):
        self.contador = max(self.contador - 1, self.menor)
```

**Ej. 23 — herencia `Persona → Empleado → Jefe`** con atributos privados. El prefijo `__` (doble guion bajo) hace el atributo "privado" (name mangling). `super().__init__(...)` invoca al constructor del padre.

```python
class Persona:
    def __init__(self, nombre, edad):
        self.__nombre = nombre      # privado
        self.__edad = edad
    def get_nombre(self): return self.__nombre
    def get_edad(self):   return self.__edad

class Empleado(Persona):
    def __init__(self, nombre, edad, sueldo=1000):
        super().__init__(nombre, edad)
        self.__sueldo = sueldo
    def get_sueldo(self): return self.__sueldo

class Jefe(Empleado):
    def __init__(self, nombre, edad):
        super().__init__(nombre, edad, 3000)   # sueldo prefijado
```

<mark style="background: #FF5582A6;">Esta cadena de herencia es exactamente el mecanismo de `class Course(models.Model)` y de `_inherit` en Odoo.</mark> Si dominas el ejercicio 23, dominas la base del desarrollo de módulos. Ver [[01 - Python para Odoo]].

## 24-26 — Revisitando objetos (métodos de colecciones)

`dict.get(clave, defecto)` evita el `KeyError`; `.keys()`/`.values()`/`.items()` recorren el diccionario. Las listas tienen `insert`, `index`, `reverse`, `sort`; las cadenas `replace`, `split`, `upper`.

```python
D = {"a": 1, "b": 2}
print(D.get("z", "No está"))          # defecto si la clave no existe
"abacada".replace("a", "A"); "a,b,c".split(",")
L = [1, 2, 3]; L.insert(1, 4); L.index(4); L.reverse(); L.sort()
```

## 27-33 — Programación funcional

**Ej. 27** (funciones como objetos). Una función puede devolver otra función (las funciones son *first-class*); se guardan en un `dict` para despachar por clave.

```python
def operacion(op):
    funcs = {"+": lambda a, b: a + b, "*": lambda a, b: a * b}
    return funcs[op]
print(operacion("+")(3, 5))    # 8
```

**Ej. 28-30** (`map`, `filter`, `reduce`). `map` aplica una función a cada elemento; `filter` selecciona los que cumplen un predicado; `reduce` (de `functools`) acumula a un único valor.

```python
from functools import reduce
print(list(map(lambda n, m: n + m, [1,2,3], [10,20,30])))   # [11,22,33]
print(list(filter(lambda n: n > 2, [1,2,3,4])))             # [3,4]
print(reduce(lambda x, y: x * y, [1,2,3,4]))                # 24
```

**Ej. 31-32** (*list comprehension*). Forma compacta y legible de construir listas; <mark style="background: #FF5582A6;">aparece en dominios y filtros de Odoo</mark>.

```python
print([n for n in [1,2,3,4] if n > 2])          # filtrar: [3,4]
print([n + m for n, m in zip([1,2,3], [10,20,30])])  # sumar posición a posición
```

> [!info]+
> El profesor empareja las listas con `if l.index(n) == l2.index(m)` dentro de un doble `for`. `zip()` hace lo mismo de forma directa y sin el riesgo de `index()` con elementos repetidos. Es una mejora de su solución que conviene conocer.

**Ej. 33** (generador). `yield` produce valores bajo demanda sin construir toda la lista en memoria.

```python
def multiplos(mult, ini, fin):
    n = ini + (mult - ini % mult) % mult     # primer múltiplo ≥ ini
    while n <= fin:
        yield n
        n += mult

for x in multiplos(5, 0, 50): print(x)
```

## 34 — Excepciones

Capturar tipos concretos (`IndexError`, `KeyError`) es mejor que un `except` genérico: solo atrapas el error que esperas.

```python
try:
    print([0,1,2][5])
except IndexError:
    print("Índice fuera de rango")

try:
    print({"a": 1}["c"])
except KeyError:
    print("Clave inexistente")
```

## 35-36 — Módulos y paquetes

`if __name__ == "__main__":` separa el código que se ejecuta solo al lanzar el fichero directamente del que se importa. <mark style="background: #8000E1A6;">Es el mismo mecanismo `from . import ...` que enlaza los `__init__.py` de un módulo Odoo.</mark>

```python
# multiplo.py
def fmultiplo(mult, ini, fin):
    n = ini + (mult - ini % mult) % mult
    while n <= fin:
        yield n; n += mult

if __name__ == "__main__":          # solo al ejecutar directamente
    print("Generador de múltiplos")
    for i in fmultiplo(5, 0, 30): print(i)
```

Un **paquete** es un directorio con `__init__.py`; se importa `import mult` y se accede con `mult.multiplo.fmultiplo(...)`.

## 37-40 — Entrada/salida, ficheros y expresiones regulares

`sys.argv` da los argumentos de línea de comandos (`argv[0]` es el nombre del programa); `open()` + `with` gestiona ficheros cerrándolos solos; `re.search` busca un patrón en cada línea.

```python
# 37: leer números hasta 0, capturar errores
import sys
while True:
    try:
        if int(input("> ")) == 0:
            raise SystemExit
    except ValueError:
        print("No es un número")
    except SystemExit:
        print("Fin"); break

# 39: contar líneas y mostrar la segunda  (with cierra el fichero solo)
with open("listado") as f:
    lineas = f.readlines()
print(len(lineas), lineas[1])

# 40: líneas que casan con una ER pasada por parámetro
import re
try:
    patron = sys.argv[1]
    with open("listado") as f:
        for l in f:
            if re.search(patron, l):
                print("Match", l, end="")
except IndexError:
    print("Introduce un parámetro")
```

> [!warning]+
> El profesor abre el fichero con `open(...)` + `f.close()` manual. Yo uso `with open(...) as f:` porque garantiza el cierre aunque salte una excepción. Ambas se aceptan; la primera es la que verás en sus soluciones.

> [!important]+
> Idioms de estos 40 ejercicios que volverás a ver en Odoo: el `dict` para pasar valores, la *list comprehension* y el ternario en lógica de campos, la **herencia de clases** (ejercicios 22-23) como base de los modelos, y `sys.argv` para los scripts de [[07 - Servicios web XML-RPC]].

Siguiente prerrequisito: [[03 - Docker para Odoo]].
