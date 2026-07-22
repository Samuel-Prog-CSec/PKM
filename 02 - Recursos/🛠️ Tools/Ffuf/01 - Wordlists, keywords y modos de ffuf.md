---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-19
Nota previa: "[[00 - Introducción a ffuf]]"
Nota siguiente: "[[02 - Fuzzing de directorios y archivos con ffuf]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

`FUZZ` es el keyword por defecto, pero `ffuf` admite **varias listas con nombres propios** y distintos **modos** de combinarlas. Dominar esto es lo que separa un fuzz de una posición de un ataque de credenciales multi-posición.

# Keywords: renombrar la posición

Con `-w lista:KEYWORD` cambias el marcador. Útil para legibilidad y **obligatorio** cuando hay varias listas:

```shell-session
$ ffuf -w users.txt:USER -w pass.txt:PASS \
       -u https://target/login -X POST \
       -d 'username=USER&password=PASS' \
       -H 'Content-Type: application/x-www-form-urlencoded'
```

# Modos de combinación (`-mode`)

Cuando hay más de una lista, el modo decide cómo se emparejan:

| Modo | Comportamiento | Nº peticiones | Uso típico |
| --- | --- | --- | --- |
| `clusterbomb` *(def. multi)* | Producto cartesiano: **todas** las combinaciones | `len(A) × len(B)` | Probar cada user con cada pass |
| `pitchfork` | Emparejamiento **1:1**: `A[i]` con `B[i]` | `len(A)` | Credenciales ya emparejadas (user↔pass) |
| `sniper` *(v2)* | **Una** lista, prueba cada posición marcada de una en una | `len(A) × posiciones` | Fuzz de un único punto (estilo Burp Sniper) |

<mark style="background: #FFB86CA6;">`clusterbomb` explota rápido</mark>: dos listas de 1000 = un millón de peticiones. Para *password spraying* o pares conocidos, `pitchfork` es órdenes de magnitud más eficiente.

```shell-session
# clusterbomb explícito (el defecto con múltiples listas)
$ ffuf -w u.txt:USER -w p.txt:PASS -mode clusterbomb -u ... 
# pitchfork: A[0]+B[0], A[1]+B[1]...
$ ffuf -w u.txt:USER -w p.txt:PASS -mode pitchfork -u ...
```

# Extensiones automáticas (`-e`)

Añade sufijos a cada palabra sin duplicar la lista — clave para buscar archivos:

```shell-session
$ ffuf -w wl.txt -u https://target/FUZZ -e .php,.bak,.old,.txt,.zip
```

# Entrada por stdin y comentarios

<mark style="background: #ADCCFFA6;">`-w -` lee la wordlist de `stdin`</mark>, lo que encadena `ffuf` con otras herramientas:

```shell-session
$ assetfinder target.com | ffuf -w - -u https://FUZZ -mc 200
$ ffuf -w wl.txt -ic ...        # -ic ignora líneas de comentario (#) en la lista
```

La elección de la `wordlist` pesa más que la velocidad de la herramienta — el catálogo (`SecLists`, `raft-*`, listas por tecnología) está en [[16 - Herramientas de fuzzing]]. Con las listas dominadas, la técnica más usada: [[02 - Fuzzing de directorios y archivos con ffuf|directorios y archivos]].
