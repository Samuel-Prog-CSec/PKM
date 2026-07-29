---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - IDOR
Descripción: "Localizada la referencia, el objetivo es extraer los datos de todos los usuarios, no solo de uno"
Fecha de actualización: 2026-07-15
Nota previa: "[[07 - Identificación de IDORs]]"
Nota siguiente: "[[09 - Bypass de referencias codificadas]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Localizada la referencia, el objetivo es <mark style="background: #FFB86CA6;">extraer los datos de **todos** los usuarios, no solo de uno</mark>. Aquí está el impacto real de un IDOR: una fuga masiva automatizada.

# El escenario: parámetro inseguro

App *Employee Manager*. Estamos logueados como `uid=1`. Al pulsar *Documents* vamos a `/documents.php?uid=1`, que lista nuestros ficheros con nombres predecibles:

```html
/documents/Invoice_1_09_2021.pdf
/documents/Report_1_10_2021.pdf
```

El nombre incluye el `uid` y el mes/año → esto ya es un **static file IDOR** (podríamos fuzzear nombres). Pero hay algo mejor: el `uid` viaja como parámetro `GET` que el back-end usa como referencia directa. Al cambiar a `?uid=2`, la página **parece** igual (mismo layout), pero los enlaces son otros:

```html
/documents/Invoice_2_08_2020.pdf
/documents/Report_2_12_2020.pdf
```

> [!warning]+ Atención a los detalles
> El error clásico es asumir que "la página no cambia → sigue mostrando lo mío". Vigila **tamaño de respuesta, source y enlaces**: un IDOR silencioso devuelve `200 OK` con datos ajenos sin ningún mensaje de "acceso concedido". Un parámetro filtro (`uid_filter=1`) también se puede manipular **o eliminar** para volcar todo de golpe.

# Enumeración masiva

Acceder manualmente a `uid=3,4,5...` no escala con miles de empleados. Opciones: [[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|Burp Intruder / ZAP Fuzzer]], `ffuf`, o un script. Primero aislamos el enlace del documento con un patrón único (cada enlace empieza por `<li class='pure-tree_link'>`):

```shell-session
$ curl -s "http://SERVER_IP:PORT/documents.php?uid=3" | grep -oP "\/documents.*?.pdf"
/documents/Invoice_3_06_2020.pdf
/documents/Report_3_01_2020.pdf
```

`grep -oP "\/documents.*?.pdf"` extrae solo las rutas con un regex *non-greedy*. Ahora un bucle recorre los `uid` y descarga todo con `wget`:

```bash
#!/bin/bash
url="http://SERVER_IP:PORT"

for i in {1..10}; do
    for link in $(curl -s "$url/documents.php?uid=$i" | grep -oP "\/documents.*?.pdf"); do
        wget -q "$url/$link"
    done
done
```

Al ejecutarlo descargamos los documentos de los empleados 1-10. <mark style="background: #8000E1A6;">Un solo bucle convierte un IDOR puntual en una exfiltración completa</mark>.

# Enfoque moderno (más allá del bash de HTB)

En bug bounty real, el script casero se sustituye por herramientas que gestionan concurrencia, rate limiting y detección de hits válidos:

- **ffuf** para barrer el ID y filtrar por lo que cambia:

```shell-session
$ ffuf -w <(seq 1 1000) -u "http://target/documents.php?uid=FUZZ" \
    -H "Cookie: session=..." -mc 200 -ac
```

`-ac` (auto-calibration) y filtros por tamaño (`-fs`) separan los hits reales del ruido. Para detectar el IDOR, lo clave es el **diff**: comparar respuestas para ver cuáles devuelven datos distintos a los tuyos.

- **Burp Intruder** con *Grep – Extract* configurado sobre el enlace del documento: extrae automáticamente los nombres de fichero por cada `uid` y los tabula.
- **Rangos no secuenciales**: si los IDs no son `1..N` sino aleatorios pero cortos, genera wordlists (`crunch`, `seq`, o IDs recolectados de respuestas/JS). Con `UUID`s, busca fugas del identificador antes de fuzzear (los `UUID` no se enumeran por fuerza bruta de forma práctica).
- **Rate limiting / detección**: espacia las peticiones (`-p` en ffuf), rota identidad si procede, y ojo con los WAF que detectan la enumeración secuencial — ver [[12 - Detección, evasión y prevención de IDOR|evasión]].

> [!tip]+ Criterio de "hit" válido
> No te fíes del código de estado: muchos IDOR devuelven `200` siempre. Ordena por **longitud/contenido de la respuesta** y quédate con las que difieren de la línea base (tu propio usuario). Ese diff es la señal del acceso no autorizado.

Hasta aquí, referencias en claro. ¿Y si están codificadas o hasheadas? Eso lo vemos en [[09 - Bypass de referencias codificadas|bypass de referencias codificadas]].

## Referencias

- PortSwigger — [IDOR labs](https://portswigger.net/web-security/access-control/idor)
- ffuf — [wiki](https://github.com/ffuf/ffuf/wiki)
- HTB Academy — *Web Attacks* (base, 2021)
