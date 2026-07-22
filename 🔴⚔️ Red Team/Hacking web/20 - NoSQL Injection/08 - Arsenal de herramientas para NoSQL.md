---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[07 - Evasión de filtros y WAF en NoSQL]]"
Nota siguiente: "[[09 - Prevención de NoSQL injection]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

La NoSQLi combina tres frentes de tooling: **fuzzing** con wordlists para detectar, **herramientas dedicadas** para confirmar, y **scripts a medida** para la explotación ciega/SSJI (donde de verdad se hace el trabajo).

# Fuzzing con wordlists

Se lanzan `payloads` NoSQLi conocidos y se busca una respuesta **anómala** (distinto tamaño, código o tiempo). Wordlists útiles:

- `seclists/Fuzzing/Databases/NoSQL.txt`
- `nosqlinjection_wordlists/mongodb_nosqli.txt`

Con `wfuzz` (o el más moderno [`ffuf`](https://github.com/ffuf/ffuf)), poniendo `FUZZ` donde va el valor:

```shell-session
$ wfuzz -z file,/usr/share/seclists/Fuzzing/Databases/NoSQL.txt -u http://target/index.php -d '{"trackingNum": FUZZ}'
```

<mark style="background: #FFB86CA6;">La señal: un `payload` cuya respuesta cambia de tamaño</mark>. En el ejemplo, `{"$gt":""}` devolvió 136 caracteres frente a los 35 del resto → candidato claro a confirmar a mano.

# NoSQLMap — y por qué ya no es la mejor opción

[`NoSQLMap`](https://github.com/codingo/NoSQLMap) identifica NoSQLi automáticamente. Ejemplo contra un login (parámetro `password`):

```shell-session
$ python2 nosqlmap.py --attack 2 --victim 127.0.0.1 --webPort 80 --uri /index.php \
    --httpMethod POST --postData email,admin@mangomail.com,password,qwerty \
    --injectedParameter 1 --injectSize 4
...
Exploitable requests:
{'email': 'admin@mangomail.com', 'password[$ne]': 'hQPH...'}
{'email': 'admin@mangomail.com', 'password[$gt]': ''}
```

> [!warning]+ NoSQLMap está desactualizado (moderniza)
> <mark style="background: #FF5582A6;">NoSQLMap es **Python 2** y está prácticamente sin mantenimiento</mark> — instalarlo en 2026 es un dolor (pip2, dependencias muertas). El reemplazo actual es <mark style="background: #ADCCFFA6;">[`nosqli`](https://github.com/Charlie-belmer/nosqli) (de Charlie Belmer)</mark>, escrito en Go, mantenido, que detecta y explota NoSQLi de forma limpia:
> ```shell-session
> $ nosqli scan -t "http://target/index.php" -r request.txt
> ```

# Burp Suite y scripts propios

Burp Pro tiene una **extensión NoSQLi Scanner** (BAppStore) para escaneo automático, e **Intruder** para pilotar la extracción char-by-char o la [[06 - Server-Side JavaScript Injection|búsqueda binaria]]. Pero para blind/SSJI, <mark style="background: #8000E1A6;">el script Python del oráculo (notas [[05 - Extracción de datos ciega y automatización|05]] y [[06 - Server-Side JavaScript Injection|06]]) sigue siendo lo más fiable y afinable</mark>.

> [!important]+ La herramienta detecta; el script explota
> `nosqli`/NoSQLMap confirman la inyección y encuentran el operador, pero la exfiltración real (blind con `$regex`, SSJI con `charCodeAt` + binary search) casi siempre termina en un script a medida. Como en el resto del PKM: la automatización acelera la detección, el conocimiento manual cierra la explotación.

> [!info]+ Fuentes
> [SecLists](https://github.com/danielmiessler/SecLists) · [NoSQLMap](https://github.com/codingo/NoSQLMap) · [`nosqli`](https://github.com/Charlie-belmer/nosqli) · [HackTricks — NoSQL injection](https://book.hacktricks.wiki/en/pentesting-web/nosql-injection.html) · [PayloadsAllTheThings — NoSQL Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/NoSQL%20Injection/).
