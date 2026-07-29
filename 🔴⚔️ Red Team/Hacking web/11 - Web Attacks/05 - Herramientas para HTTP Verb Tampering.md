---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Verb-Tampering
Descripción: "Set de herramientas para detectar y explotar Verb Tampering de forma sistemática"
Fecha de actualización: 2026-07-15
Nota previa: "[[04 - Detección, evasión y prevención de Verb Tampering]]"
Nota siguiente: "[[06 - Introducción a IDOR]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Set de herramientas para detectar y explotar Verb Tampering de forma sistemática. El vector es simple, así que el valor está en **automatizar** la prueba de todos los métodos contra muchos endpoints.

# Manuales / interactivas

## curl

La navaja para pruebas puntuales: enumerar métodos y disparar el bypass.

```shell-session
# Enumerar métodos aceptados
$ curl -i -s -X OPTIONS http://target/admin/

# Probar un método concreto (efecto de lado sin cuerpo)
$ curl -i -s -X HEAD http://target/admin/reset.php

# Bypass de filtro moviendo el payload a la query string
$ curl -i -s -G "http://target/index.php" --data-urlencode "filename=x; id"
```

## Burp Suite

- <mark style="background: #ADCCFFA6;">**Change Request Method**</mark> (clic derecho en Repeater/Proxy): convierte al instante `GET`↔`POST` reubicando parámetros. El primer paso manual siempre.
- **Intruder**: coloca el marcador de posición en el **verbo** (`§GET§ /admin/reset.php`) y carga una lista de métodos como payload → prueba toda la batería contra un endpoint y ordena por código/longitud.
- Fuzzing de cabeceras de override: marca el valor de `X-HTTP-Method-Override: §PUT§` en Intruder.

# Automatizadas / escalables

## ffuf

`ffuf` acepta la keyword `FUZZ` <mark style="background: #FFB8EBA6;">**también en el método** (`-X FUZZ`)</mark>, algo que pocos conocen. Ideal para barrer métodos contra un endpoint o endpoints contra un método:

```shell-session
# Fuzzear el método contra un endpoint protegido
$ ffuf -w methods.txt -X FUZZ -u http://target/admin/reset.php -mc all -fc 401,403

# methods.txt: GET POST HEAD PUT DELETE PATCH OPTIONS TRACE CONNECT FOOBAR (uno por línea)
```

`-fc 401,403` filtra las respuestas de "acceso denegado"; <mark style="background: #FF5582A6;">lo que quede es un candidato a bypass</mark>. Ver [[15 - Introducción al web fuzzing|ffuf]].

## Nuclei

`nuclei` (ProjectDiscovery) trae plantillas para probar métodos peligrosos y bypass de control de acceso por verbo. Útil en escaneo masivo de bug bounty:

```shell-session
$ nuclei -u http://target -tags http,misconfig,method
$ nuclei -l urls.txt -tags method,exposure    # muchos hosts a la vez
```

Puedes escribir una plantilla propia que reenvíe cada endpoint con `HEAD`/`PUT` y flaguee cuando el código cambie respecto a `GET`.

## nmap

El script NSE `http-methods` enumera y comprueba métodos peligrosos:

```shell-session
$ nmap -p 80,443 --script http-methods --script-args http-methods.url-path='/admin/' target
```

## Otras

| Herramienta | Uso | Nota |
| - | - | - |
| `httpx` | `httpx -l urls.txt -x all -status-code` | Sondeo rápido de qué métodos responden en masa |
| `Nikto` | Reporta métodos habilitados (`PUT`, `TRACE`) | Ruidoso, pero rápido para un primer barrido |
| Metasploit | `auxiliary/scanner/http/options` | Enumera `Allow` en rangos de red |
| OWASP ZAP | Regla *"HTTP Parameter/Method"* + spider | Alternativa libre a Burp |

> [!tip]+ Flujo recomendado en bug bounty
> 1. `httpx`/`nmap` para enumerar métodos en masa. 2. Identificar endpoints con `401`/`403` o filtros. 3. `ffuf -X FUZZ` o Burp Intruder para probar toda la batería + cabeceras de override. 4. Confirmar manualmente con `curl`/Repeater el efecto real (acción ejecutada, filtro saltado). Documentar la petición exacta que logra el bypass.

Con esto cerramos HTTP Verb Tampering. El siguiente sub-tema es [[06 - Introducción a IDOR|IDOR]], la vulnerabilidad de control de acceso más rentable del módulo.

## Referencias

- ProjectDiscovery — [Nuclei](https://github.com/projectdiscovery/nuclei) y [nuclei-templates](https://github.com/projectdiscovery/nuclei-templates)
- ffuf — [wiki oficial](https://github.com/ffuf/ffuf/wiki) (uso de `FUZZ` en método/cabeceras)
- Nmap — [`http-methods` NSE](https://nmap.org/nsedoc/scripts/http-methods.html)
- PortSwigger — [Burp Intruder](https://portswigger.net/burp/documentation/desktop/tools/intruder)
