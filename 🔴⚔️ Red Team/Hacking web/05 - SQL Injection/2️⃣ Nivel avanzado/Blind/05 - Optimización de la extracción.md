---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[04 - Extracción de datos boolean-based]]"
Nota siguiente: "[[06 - Identificar SQLi basada en tiempo]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

El [[04 - Extracción de datos boolean-based|volcado lineal]] funciona pero es inviable: ~95 peticiones por carácter, miles en total. Dos algoritmos reducen eso a **~7 peticiones por carácter**, y el *multithreading* lo acelera aún más. <mark style="background: #FFB86CA6;">No es solo velocidad: menos peticiones significan menos ruido y más posibilidades de no disparar un WAF o un rate limit</mark>.

# Bisección (búsqueda binaria)

En lugar de probar cada valor, se pregunta por **rangos**, partiendo el espacio de búsqueda (0-127) por la mitad en cada paso con `BETWEEN`:

```python
print("[*] Password = ", end='')
for i in range(1, length + 1):
    low, high = 0, 127
    while low <= high:
        mid = (low + high) // 2
        if oracle(f"ASCII(SUBSTRING(password,{i},1)) BETWEEN {low} AND {mid}"):
            high = mid - 1      # el carácter está en la mitad baja
        else:
            low = mid + 1       # está en la mitad alta
    print(chr(low), end='')
    sys.stdout.flush()
print()
```

<mark style="background: #ADCCFFA6;">Cada pregunta descarta la mitad del espacio restante</mark>, así que localizar un carácter entre 128 valores cuesta `log₂(128) = 7` peticiones en lugar de hasta 95. El volcado de `maria` baja de **miles de peticiones a un puñado de cientos** (≈13× menos): la extracción lineal previa gastaba decenas de intentos por carácter, la bisección solo 7.

# SQL-Anding (extracción bit a bit)

Otra vía igual de eficiente: como un carácter ASCII cabe en 7 bits (`0-127` = `0000000-1111111`), se extrae **bit a bit** con un AND a nivel de bits. La pregunta `(ASCII(...) & 2^p) > 0` revela si el bit `p` es 1:

```python
print("[*] Password = ", end='')
for i in range(1, length + 1):
    c = 0
    for p in range(7):          # 7 bits
        if oracle(f"ASCII(SUBSTRING(password,{i},1))&{2**p}>0"):
            c |= 2**p           # activa ese bit
    print(chr(c), end='')
    sys.stdout.flush()
print()
```

Para el carácter `9` (57 = `0111001`), siete preguntas reconstruyen el valor bit a bit. <mark style="background: #FFB8EBA6;">También son ~7 peticiones por carácter</mark>, igual que la bisección. Su ventaja no es la velocidad por petición, sino la **paralelización** (ver más abajo).

# Multithreading: la gran aceleración

El cuello de botella es la latencia de red por petición, no el cómputo. Paralelizar es el siguiente salto, pero hay que respetar las **dependencias**:

| Algoritmo | Bits/preguntas de un carácter | Caracteres entre sí |
| --------- | ----------------------------- | ------------------- |
| Bisección | **Dependientes** (cada paso usa el anterior) → en orden | Independientes → en paralelo |
| SQL-Anding | **Independientes** (cada bit por separado) → en paralelo | Independientes → en paralelo |

<mark style="background: #8000E1A6;">SQL-Anding es idóneo para máxima paralelización</mark>: todas las preguntas de todos los caracteres son independientes, así que pueden lanzarse a la vez (`concurrent.futures.ThreadPoolExecutor`). La bisección paraleliza por carácter pero no dentro de uno.

> [!warning]+
> Más hilos = más rápido, pero también **más ruidoso y más fácil de detectar/bloquear**. <mark style="background: #FF5582A6;">Ajusta la concurrencia al objetivo</mark>: contra un WAF agresivo o con rate limiting, baja a 1-2 hilos y añade `delay`; en un lab o un objetivo tolerante, sube. El equilibrio velocidad/sigilo es una decisión de cada engagement, no un valor fijo.

> [!info]+
> Estos son exactamente los algoritmos que [[SQLMap.base|SQLMap]] y `ghauri` implementan internamente (`--threads` controla la concurrencia). Escribir el oráculo y el algoritmo a mano es lo que permite extraer cuando la herramienta falla —contexto raro, filtro a medida, respuesta que requiere lógica de comparación propia—.

La extracción boolean cubre el caso con diferencia de contenido. Cuando **no hay ninguna** diferencia observable en la respuesta, el único canal que queda es el tiempo: [[06 - Identificar SQLi basada en tiempo]].
