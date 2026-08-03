---
tags:
  - Web/Red-Team
  - ReDoS
  - Introduccion
  - Tipo/Introduccion
Descripción: "ReDoS (Regular Expression Denial of Service) explota expresiones regulares mal diseñadas para agotar la CPU del servidor con una entrada corta y maliciosa"
Fecha de actualización: 2026-07-17
Nota previa: ""
Nota siguiente: "[[01 - Explotación, detección y mitigación de ReDoS]]"
Area: "[[ReDoS.base|ReDoS]]"
---
---

<mark style="background: #ADCCFFA6;">ReDoS (Regular Expression Denial of Service) explota expresiones regulares mal diseñadas para agotar la CPU del servidor</mark> con una entrada corta y maliciosa. Una app valida un input contra una regex y responde en tiempo constante; pero con un payload que ataca las ineficiencias del motor, <mark style="background: #FFB86CA6;">la evaluación crece exponencialmente y cuanto más largo el payload, más tarda</mark> — hasta bloquear el proceso. Es un vector barato (una petición) y devastador (caída de servicio).

# El mecanismo: catastrophic backtracking

La mayoría de motores de uso común — PCRE, JavaScript, Python `re`, Java `java.util.regex`, .NET `Regex`, Ruby — usan un **autómata NFA con backtracking**. Cuando un cuantificador falla al final, el motor **rebobina y prueba otras formas de repartir la entrada**. Contra una regex ambigua, una entrada adversaria fuerza a explorar hasta **2^n** particiones antes de rendirse: un solo core al 100%, el *event loop* bloqueado ([Snyk](https://learn.snyk.io/lesson/redos/), [HackTricks](https://hacktricks.wiki/en/pentesting-web/regular-expression-denial-of-service-redos.html)).

El crecimiento es brutal. Para `/A(B|C+)+D/`, casar `ACCCX` cuesta 38 pasos, pero `ACCC…CX` con 16 `C` cuesta **65.553 pasos** ([Snyk](https://learn.snyk.io/lesson/redos/)).

# Regex "malignas": las formas a reconocer

El patrón vulnerable casi siempre tiene **ambigüedad**: un carácter que puede casar por más de un camino repetible.

| Forma | Ejemplo | Por qué |
| - | - | - |
| Cuantificadores anidados | `(a+)+`, `(a*)*`, `([a-z]+)*` | Repetición dentro de repetición |
| Alternancia solapada cuantificada | `(a\|a)+`, `(a\|aa)+`, `(a\|a?)+` | Las ramas casan el mismo char |
| Adyacencia solapada | `.*.*`, `\d+\d+` | Dos cuantificadores compiten por lo mismo |
| Repetición con cola difícil | `(.*a){x}` con x>10 | Rebobina en cada iteración |

<mark style="background: #FF5582A6;">El manejo de espacios en blanco es el ofensor #1 del mundo real</mark>: grupos `\s*`/`.+` opcionales que pueden consumir el mismo espacio ([Doyensec regexploit](https://blog.doyensec.com/2021/03/11/regexploit.html)).

# El caso del lab: un validador de email

La API `/api/check-email?email=` valida contra esta regex, que HTB entrega en la respuesta:

```text
/^([a-zA-Z0-9_.-])+@(([a-zA-Z0-9-])+.)+([a-zA-Z0-9]{2,4})+$/
```

El segundo y tercer grupo hacen comprobaciones iterativas ambiguas. Un email "casi válido" muy largo dispara el backtracking:

```shell-session
$ curl "http://<TARGET>:3000/api/check-email?email=jjjjjjjjjjjjjjjj@cccccccccccccccc.5555555555555555555555555555555555555555."
# la API tarda varios segundos; alargar el payload aumenta el tiempo
```

> [!info]+ Visualizar la regex
> Pegar la expresión en [regex101.com](https://regex101.com) da la explicación paso a paso, y en [jex.im/regulex](https://jex.im/regulex/) la representación visual del autómata — donde los bucles anidados se ven de un vistazo. Herramienta rápida para juzgar si una regex es explotable.

# Incidentes reales (esto tira producciones)

ReDoS no es teórico — ha causado caídas globales:

- <mark style="background: #FFB86CA6;">**Cloudflare, 2 jul 2019 — 27 min de caída global, CPU ~100%**</mark>. Una regla WAF con el sub-patrón `.*(?:.*=.*)`. La solución: migrar de PCRE a **RE2/Rust regex** (tiempo lineal) ([postmortem Cloudflare](https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/)).
- **Stack Overflow, 20 jul 2016 — 34 min de caída**. Una regex de *trim* `^[\s‌]+|[\s‌]+$` sobre un post con ~20.000 espacios iniciales → ~200 millones de comprobaciones ([Snyk](https://learn.snyk.io/lesson/redos/)).
- **`path-to-regexp` — CVE-2024-45296** (2024): alto impacto porque sostiene el *routing* de **Express**; `/:a-:b` genera una regex con backtracking ([Snyk](https://security.snyk.io/vuln/SNYK-JS-PATHTOREGEXP-7925106)). El ejemplo de "sigue pasando en 2024".
- Otros CVEs de librerías masivas: `moment` (CVE-2022-31129), `lodash` (CVE-2020-28500), `ua-parser-js` (CVE-2020-7733).

La caza, explotación y mitigación — con el arsenal de detección — en [[01 - Explotación, detección y mitigación de ReDoS]].
