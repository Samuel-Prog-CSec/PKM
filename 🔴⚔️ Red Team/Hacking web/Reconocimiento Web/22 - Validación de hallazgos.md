---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - Fuzzing
Fecha de actualización: 2026-06-02
Nota previa: "[[21 - Filtrado de la salida de fuzzing]]"
Nota siguiente: "[[23 - APIs web e identificación de endpoints]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El fuzzing lanza una red amplia y genera pistas, pero <mark style="background: #FFB8EBA6;">no todo hallazgo es una vulnerabilidad real</mark>: el proceso produce falsos positivos —anomalías inofensivas que disparan el detector del fuzzer sin suponer riesgo—. Por eso la validación es un paso obligatorio del flujo, no un extra.

# Por qué validar

- **Confirmar la vulnerabilidad**: asegurarte de que es real y no una falsa alarma.
- **Entender el impacto**: evaluar la severidad y las consecuencias para la aplicación.
- **Reproducir**: poder replicarla de forma consistente, base para el fix y para el informe.
- **Reunir evidencia**: pruebas que convenzan a desarrolladores o *stakeholders*.

# Verificación manual

La vía más fiable es manual, en tres pasos:

1. **Reproducir la petición**: reenviar con `curl`, el navegador o un proxy ([[Proxies web|Burp/Caido]]) la misma petición que disparó la respuesta rara durante el fuzzing.
2. **Analizar la respuesta**: examinar con cuidado en busca de mensajes de error, contenido inesperado o comportamiento que se desvíe de lo normal.
3. **Explotación / PoC**: si pinta bien, demostrar la vulnerabilidad en un entorno controlado, con autorización.

# Ejemplo: un `/backup/` accesible

El fuzzer encontró `/backup/` con `200 OK`. Los directorios de backup suelen contener dumps de base de datos, ficheros de configuración con claves o código fuente. Primero confirmamos si es navegable:

```shell-session
$ curl http://IP:PORT/backup/
```

Si el servidor devuelve un listado de archivos, has confirmado un `directory listing`:

```html
<h2>Index of /backup/</h2>
<a href="backup.sql">backup.sql</a>  2024-Jun-12 14:00  0.2K
<div class="foot">lighttpd/1.4.76</div>
```

# Validación responsable con cabeceras

En vez de descargar el contenido sensible, <mark style="background: #8000E1A6;">examina solo las cabeceras con `curl -I`</mark> para confirmar que el fichero tiene contenido sin exfiltrarlo:

```shell-session
$ curl -I http://IP:PORT/backup/password.txt

HTTP/1.1 200 OK
Content-Type: text/plain;charset=utf-8
Content-Length: 171
Server: lighttpd/1.4.76
```

- `Content-Type: text/plain` confirma el tipo de fichero (`application/sql` sería un dump, `application/zip` un backup comprimido).
- <mark style="background: #FFB86CA6;">`Content-Length: 171` indica que el fichero **no está vacío**</mark> y probablemente contiene datos — preocupante dado el nombre y la ubicación. Un `Content-Length: 0` sería un fichero vacío, sospechoso pero sin riesgo directo.

El listado + las cabeceras prueban el riesgo sin tocar el contenido confidencial.

> [!important]+ PoC de impacto mínimo
> El objetivo es <mark style="background: #FF5582A6;">demostrar la existencia del fallo sin causar daño ni exfiltrar datos sensibles</mark>. Si sospechas un `SQLi`, no extraigas la base de datos: lanza una consulta inofensiva que devuelva la **versión** del motor. Si encuentras un backup, confirma su tamaño por cabeceras en lugar de descargarlo. Reúne la evidencia justa para convencer al cliente respetando los límites éticos y legales — y, en bug bounty, las reglas del programa.

> [!warning]+ De dónde vienen los falsos positivos
> Antes de cantar un hallazgo, descarta las causas habituales de ruido que ya pasaron el [[21 - Filtrado de la salida de fuzzing|filtrado]]: respuestas *soft-404* (la app devuelve `200` con una página de "no encontrado"), `wildcard` DNS/vhost, páginas de bloqueo de un `WAF` que imitan respuestas válidas, y *redirects* genéricos. La validación manual existe precisamente para no reportar ninguno de estos como vulnerabilidad — un `404` reportado como hallazgo quema tu credibilidad en un informe o un programa de bug bounty.

Hemos cubierto el fuzzing de rutas, parámetros y hosts en aplicaciones web tradicionales. El último frente, cada vez más dominante, son las **APIs**: cómo identificar y fuzzear sus endpoints. Eso es [[23 - APIs web e identificación de endpoints]].
