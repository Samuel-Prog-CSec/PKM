---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Una URL GET suelta es la excepción. En un objetivo real la petición vulnerable lleva cookies de sesión, cabeceras concretas y a menudo un cuerpo POST o JSON. Errores tontos…"
Fecha de actualización: 2026-06-04
Nota previa: "[[01 - Interpretación de la salida de SQLMap]]"
Nota siguiente: "[[03 - Tuning del ataque]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

Una URL `GET` suelta es la excepción. En un objetivo real la petición vulnerable lleva cookies de sesión, cabeceras concretas y a menudo un cuerpo POST o JSON. <mark style="background: #FF5582A6;">Errores tontos —olvidar la cookie, mal formatear el POST— impiden detectar una SQLi que sí existe</mark>. Por eso el flujo profesional es capturar la petición completa y pasársela a SQLMap tal cual.

# El flujo profesional: petición capturada con `-r`

La forma más fiable es interceptar la petición real con [[02 - Interceptación de peticiones|Burp o Caido]], guardarla en un fichero y lanzarla con `-r`:

```shell-session
$ sqlmap -r req.txt
```

El fichero contiene la petición HTTP entera (método, ruta, cabeceras, cookies, cuerpo). <mark style="background: #ADCCFFA6;">Así SQLMap reproduce exactamente la petición autenticada</mark>, sin que falte ningún header. En Burp: `Copy to file` sobre la petición; en caido, exportar la request. <mark style="background: #FFB8EBA6;">Con `-r`, SQLMap detecta y prueba **automáticamente** todos los parámetros (query, cuerpo, cookies)</mark>; el asterisco (`id=*`) solo hace falta para **forzar** un punto de inyección no estándar (un segmento de la ruta, una cabecera) y también funciona con `-u`/`--data`.

> [!info]+
> Atajo rápido para casos simples: en las DevTools del navegador (panel Network), `Copy as cURL`, pegar en la terminal y cambiar `curl` por `sqlmap`. SQLMap acepta la misma sintaxis de cabeceras (`-H`) que cURL.

# `GET` y `POST`

- **GET**: `-u "http://host/vuln.php?id=1"`.
- **POST**: `--data 'uid=1&name=test'` (prueba ambos parámetros).
- **Acotar a un parámetro**: `-p uid`, o marcarlo con `*` dentro de los datos: `--data 'uid=1*&name=test'`.

Acotar al parámetro ya confirmado a mano es buena práctica: reduce peticiones y ruido.

# Cabeceras, cookies y método

```shell-session
$ sqlmap ... --cookie='PHPSESSID=ab4530f4a7d10448457fa8b0eadac29c'
$ sqlmap ... --method PUT --data='id=1'
```

`--cookie`, `--referer`, `-A/--user-agent` y `-H` fijan cabeceras. <mark style="background: #FFB8EBA6;">Para inyectar en una cabecera o cookie (no solo en parámetros), se marca con `*`</mark>: `--cookie="id=1*"`. Esto cubre los SQLi modernos que viven en `X-Forwarded-For`, `Referer` o cookies usadas en consultas de logging.

> [!warning]+
> <mark style="background: #FFB86CA6;">`--random-agent` es casi obligatorio hoy</mark>: por defecto SQLMap envía `User-Agent: sqlmap/x.x`, que muchísimos WAF/IPS bloquean al instante. `--random-agent` escoge un User-Agent de navegador real del repertorio interno. (`--mobile` imita un smartphone.) Es la primera medida de evasión, antes incluso de los [[05 - Bypass de protecciones web con SQLMap|tamper scripts]].

# Cuerpos JSON y XML (APIs modernas)

SQLMap detecta y procesa cuerpos `JSON` (`{"id":1}`) y `XML` de forma "relajada". Para un body JSON simple basta `--data`; para uno complejo, `-r` con la petición capturada:

```http
POST /api/articles HTTP/1.1
Host: www.example.com
Content-Type: application/json

{"data":[{"id":"1","attributes":{"title":"x"}}]}
```

```shell-session
$ sqlmap -r req.txt
JSON data found in HTTP body. Do you want to process it? [Y/n/q] Y
```

<mark style="background: #8000E1A6;">Esto es clave en 2026</mark>: gran parte de la superficie de inyección vive hoy en endpoints de API con cuerpos JSON, no en formularios clásicos. SQLMap los testea sin necesidad de aplanar manualmente el JSON.

# Depurar cuando algo falla

| Opción | Para qué |
| ------ | -------- |
| `--parse-errors` | Muestra los errores del DBMS que se parsean, revelando por qué falla un payload. |
| `-v 3` … `-v 6` | Sube la verbosidad: `-v 3` muestra los payloads; `-v 6`, las peticiones/respuestas completas. |
| `-t /tmp/traffic.txt` | Vuelca todo el tráfico (peticiones y respuestas) a un fichero para inspección. |
| `--proxy=http://127.0.0.1:8080` | Enruta todo el tráfico por Burp/caido para repetir y analizar a mano. |

> [!important]+
> `--proxy` hacia Burp/caido es la combinación más potente para depurar y para evasión: <mark style="background: #FF5582A6;">ves cada payload que SQLMap envía, puedes repetirlo manualmente y ajustar el [[05 - Bypass de protecciones web con SQLMap|tamper]] observando qué bloquea el WAF</mark>. `-v 3` cumple lo mismo en consola cuando no quieres levantar el proxy.

Con la petición bien construida, el siguiente control es **cuánto** y **cómo** ataca SQLMap: [[03 - Tuning del ataque]].
