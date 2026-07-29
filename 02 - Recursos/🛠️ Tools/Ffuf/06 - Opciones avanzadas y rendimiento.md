---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Descripción: "Los flags que convierten ffuf de 'rápido y ruidoso' en 'controlado y encajable en un flujo real': velocidad regulada, peticiones complejas desde Burp, proxy y salida reutilizable"
Fecha de actualización: 2026-07-19
Nota previa: "[[05 - Matching y filtrado de resultados]]"
Nota siguiente: "[[07 - WAF, evasión y arsenal complementario]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

Los flags que convierten `ffuf` de "rápido y ruidoso" en "controlado y encajable en un flujo real": velocidad regulada, peticiones complejas desde Burp, proxy y salida reutilizable.

# Velocidad y cortesía

```shell-session
-t 40            # threads (por defecto 40). Más = más rápido y más ruidoso
-rate 100        # tope de peticiones/segundo (0 = sin límite)
-p 0.1           # retardo entre peticiones; acepta rango aleatorio: -p 0.1-2.0
-timeout 10      # timeout por petición
-maxtime 300     # aborta TODO el proceso a los N segundos
-maxtime-job 60  # aborta cada job individual (clave con -recursion, que lanza un job por dir)
```

<mark style="background: #FFB86CA6;">`-rate` y `-p` no son solo cortesía: son la primera línea de evasión de *rate-limiting*</mark> y de no tumbar un objetivo frágil en producción. En bug bounty, respetar el rate del programa evita el baneo (ver [[07 - WAF, evasión y arsenal complementario]]).

# Peticiones complejas: `-request` desde Burp

<mark style="background: #ADCCFFA6;">El flag más infravalorado</mark>: guardas una petición de Burp a fichero, metes `FUZZ` donde quieras, y `ffuf` reproduce cabeceras, cookies, tokens y cuerpo exactos:

```shell-session
$ ffuf -request req.txt -request-proto https -w wl.txt
```

Resuelve de golpe autenticación, CSRF tokens y cuerpos JSON complicados que a mano son un infierno de `-H`/`-d`.

# Proxy e integración con Burp

```shell-session
-x http://127.0.0.1:8080          # TODO el tráfico por Burp/Caido
-replay-proxy http://127.0.0.1:8080   # solo reenvía los ACIERTOS a Burp
```

<mark style="background: #8000E1A6;">`-replay-proxy` es el patrón pro</mark>: fuzzeas a toda velocidad pero solo los resultados que pasan tus filtros aterrizan en Burp para inspección manual — sin ahogar el proxy con miles de 404.

# Cabeceras, cookies y autenticación

```shell-session
$ ffuf -w wl.txt -u https://target/FUZZ \
       -H 'Authorization: Bearer eyJ...' \
       -H 'User-Agent: Mozilla/5.0' \
       -b 'session=abcd1234'
```

# Salida reutilizable

```shell-session
-o out.json -of json     # formatos: json, ejson, html, md, csv, ecsv, all
-od ./responses/         # vuelca a disco el CUERPO de cada acierto (para revisar luego)
-v                       # incluye la URL completa y redirecciones en la salida
```

Guardar en `json` permite postprocesar con `jq` o alimentar otra herramienta; `-od` conserva las respuestas interesantes para análisis offline. La config repetida se externaliza en `~/.config/ffuf/ffufrc` (o `~/.ffufrc` como *fallback*) o `-config fichero`.

Con el rendimiento bajo control, el último eje —y el que HTB ignora— es sobrevivir a las defensas modernas: [[07 - WAF, evasión y arsenal complementario]].
