---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[04 - Enumeración de bases de datos con SQLMap]]"
Nota siguiente: "[[06 - Explotación del sistema operativo con SQLMap]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

En 2026 lo raro es un objetivo **sin** protección. Un WAF, *rate limiting* o tokens anti-automatización detendrán a SQLMap si lo lanzas sin más. Esta es la fase donde más se separa el script-kiddie del profesional: SQLMap trae un arsenal de evasión, pero hay que saber elegirlo, encadenarlo y, sobre todo, observar qué bloquea el WAF para adaptarse. Es la cara automatizada de la [[05 - Bypass de caracteres comunes|evasión manual de filtros]].

# Detección del WAF

Al arrancar, SQLMap envía un payload malicioso a un parámetro inexistente (`?pfov=...`) para detectar protección. Un cambio drástico en la respuesta (p. ej. `406 Not Acceptable` de ModSecurity) delata el WAF. Para identificar **cuál** es, usa la librería `identYwaf` (firmas de ~80 WAFs). <mark style="background: #FFB8EBA6;">Saber qué WAF hay delante decide qué tampers usar</mark>. `--skip-waf` omite esta prueba para hacer menos ruido.

# Primera línea: el User-Agent

```shell-session
$ sqlmap -r req.txt --random-agent
```

Si recibes errores `5XX` desde el primer momento, sospecha del User-Agent: <mark style="background: #FF5582A6;">SQLMap envía `User-Agent: sqlmap/x.x` por defecto, que casi todos los WAF bloquean al instante</mark>. `--random-agent` lo cambia por uno de navegador real. Es lo primero que hay que probar, antes que cualquier tamper.

# Tamper scripts: el arsenal principal

<mark style="background: #ADCCFFA6;">Los *tamper scripts* son scripts Python que modifican cada petición justo antes de enviarla</mark>, transformando el payload para esquivar firmas. Se encadenan con `--tamper` (se aplican por prioridad predefinida):

```shell-session
$ sqlmap -r req.txt --tamper=between,randomcase,space2comment
```

Los más útiles:

| Tamper | Transformación |
| ------ | -------------- |
| `space2comment` | Espacios → `/**/` |
| `space2randomblank` | Espacios → carácter en blanco alternativo válido |
| `between` | `>` → `NOT BETWEEN 0 AND #`, `=` → `BETWEEN # AND #` |
| `equaltolike` | `=` → `LIKE` |
| `randomcase` | `SELECT` → `SeLeCt` (evade firmas case-sensitive) |
| `charencode` / `charunicodeencode` | URL/Unicode-encoding de los caracteres |
| `modsecurityversioned` | Envuelve la query en comentario versionado MySQL `/*!...*/` |
| `modsecurityzeroversioned` | Comentario versionado a cero `/*!00000...*/` |
| `symboliclogical` | `AND`/`OR` → `&&`/`\|\|` |
| `versionedmorekeywords` | Encierra cada keyword en comentario versionado MySQL |
| `0eunion` | `<int> UNION` → `<int>e0UNION` |
| `base64encode` | Codifica el payload en Base64 (si el backend lo decodifica) |

`--list-tampers` lista todos con su descripción.

> [!important]+
> No hay un combo universal: depende del WAF y del motor. <mark style="background: #8000E1A6;">Estrategia práctica: identifica el WAF, enruta SQLMap por [[02 - SQLMap sobre peticiones HTTP|Burp con `--proxy`]], y observa qué payload concreto provoca el bloqueo</mark> para elegir el tamper que lo neutraliza. Combos de partida habituales:
> - **MySQL + ModSecurity**: `--tamper=modsecurityversioned,space2comment`
> - **Genérico**: `--tamper=between,randomcase,space2comment`
> - **Filtros de espacios/keywords**: `--tamper=space2comment,versionedmorekeywords`
>
> Para casos raros (segundo orden, encoding propietario) se escriben **tamper scripts a medida** en Python: es la verdadera potencia del sistema.

# Tokens y valores dinámicos

Defensas que también frenan la automatización (sin ser WAFs):

| Mecanismo | Opción | Qué hace |
| --------- | ------ | -------- |
| Token anti-CSRF | `--csrf-token="csrf-token"` | SQLMap parsea cada respuesta y extrae el token fresco para la siguiente petición |
| Valor único requerido | `--randomize=rp` | Aleatoriza el valor del parámetro indicado en cada petición |
| Valor calculado (`h=MD5(id)`) | `--eval="import hashlib; h=hashlib.md5(id).hexdigest()"` | Ejecuta código Python para recalcular el parámetro antes de enviar |

<mark style="background: #FFB86CA6;">`--csrf-token` es imprescindible</mark> contra formularios modernos: si un parámetro contiene `csrf`/`xsrf`/`token`, SQLMap incluso ofrece gestionarlo automáticamente.

# Ocultar la IP y sortear bloqueos por origen

- `--proxy="socks4://IP:PORT"`: enruta por un proxy.
- `--proxy-file=lista.txt`: rota una lista de proxies, saltando los baneados.
- `--tor` + `--check-tor`: usa la red Tor (SOCKS en el puerto 9050/9150) y verifica que está activa.

> [!warning]+
> Rotar IPs ayuda contra *blacklisting*, pero ojo en bug bounty: muchos programas exigen un User-Agent identificable o una IP declarada para no confundirte con un atacante real. Saltarse eso puede violar las reglas.

# Otros bypass

- **`--chunked`**: usa *Transfer-Encoding: chunked*, partiendo el cuerpo POST en trozos de forma que las keywords prohibidas quedan divididas entre chunks y la firma no las ve.
- **HTTP Parameter Pollution (HPP)**: divide el payload entre múltiples valores del mismo parámetro (`?id=1&id=UNION&id=SELECT...`), que algunas plataformas (p. ej. ASP) reconcatenan.

> [!warning]+
> **Realidad 2026**: los WAF modernos (Cloudflare, AWS WAF, Akamai, ModSecurity + OWASP CRS) combinan firmas, *rate limiting* agresivo y modelos de ML. <mark style="background: #FF5582A6;">SQLMap a ciegas con tampers genéricos rara vez atraviesa un WAF cloud bien configurado</mark>; lo que funciona es: detección manual del bypass, tamper a medida para ese WAF, `--delay`/`--time-sec` para no disparar el *rate limiting*, y bajar el ritmo (`--threads=1`). Cuando SQLMap se atasca, [`ghauri`](https://github.com/r0oth3x49/ghauri) suele evadir mejor en blind por su lógica de inyección distinta. Y muchas veces, la inyección manual con [[05 - Bypass de caracteres comunes|técnicas de evasión a mano]] pasa donde la herramienta no.

Si la cuenta del DBMS tiene privilegios suficientes, SQLMap puede ir más allá de los datos y atacar el sistema operativo: [[06 - Explotación del sistema operativo con SQLMap]].
