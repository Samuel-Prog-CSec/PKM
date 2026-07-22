---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Proxies
Fecha de actualización: 2026-06-23
Nota previa: "[[06 - Codificación y decodificación]]"
Nota siguiente: "[[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

El proxy no es solo para el navegador. <mark style="background: #ADCCFFA6;">Cualquier herramienta CLI o cliente pesado se puede enrutar por Burp/ZAP</mark> apuntando su proxy a `http://127.0.0.1:8080`. Esto te da transparencia total sobre lo que esas herramientas envían — y la capacidad de interceptarlo, repetirlo y modificarlo con todas las features del proxy.

> [!warning]+ Solo cuando lo necesites
> Proxyficar una herramienta la **ralentiza** (todo pasa por el MITM). Hazlo para **investigar o depurar** su tráfico, no para uso normal. Y desactívalo cuando termines.

# proxychains: el método universal

[`proxychains`](https://github.com/haad/proxychains) fuerza el tráfico de **cualquier** comando a través de un proxy, sin que la herramienta tenga que soportarlo nativamente. Es la vía más simple. Edita `/etc/proxychains.conf`, comenta la línea final y añade tu proxy:

```text
#socks4         127.0.0.1 9050
http 127.0.0.1 8080
```

Y antepones `proxychains -q` (el `-q` silencia su ruido) al comando:

```shell-session
$ proxychains -q curl http://target:port
```

La petición de `curl` aparece en el proxy como cualquier otra:

![Petición GET de curl interceptada en la pestaña Proxy de Burp tras enrutarla con proxychains.](https://academy.hackthebox.com/storage/modules/110/proxying_proxychains_curl.png)

# Proxy nativo de cada herramienta

Muchas herramientas traen su propia opción de proxy. Algunos ejemplos:

| Herramienta | Cómo |
| - | - |
| `curl` | `curl -x http://127.0.0.1:8080 ...` |
| `Metasploit` | `set PROXIES HTTP:127.0.0.1:8080` en el módulo |
| `nmap` | `--proxies http://127.0.0.1:8080` (experimental; si falla, `proxychains`) |
| `ffuf` / `feroxbuster` | `-x http://127.0.0.1:8080` |
| `sqlmap` | `--proxy=http://127.0.0.1:8080` |

```shell-session
msf6 auxiliary(scanner/http/robots_txt) > set PROXIES HTTP:127.0.0.1:8080
msf6 auxiliary(scanner/http/robots_txt) > run
```

# Por qué importa hoy

<mark style="background: #FFB86CA6;">Más allá del lab, proxyficar herramientas es la columna del testing moderno de lo que no es un navegador</mark>:

- **APIs y clientes pesados**: ver qué manda realmente una app de escritorio o un binario al back-end.
- <mark style="background: #FF5582A6;">**Móvil**</mark>: enrutar un emulador Android/iOS por Burp es **la** forma de auditar apps móviles (instalando antes el [[01 - Instalación y configuración del proxy|certificado CA]] en el dispositivo).
- **Depurar scanners**: ver y replicar en [[05 - Repeater - repetir y modificar peticiones|Repeater]] exactamente qué petición disparó un hallazgo de `nuclei`, `sqlmap` o un script propio.

> [!info]+ Fuentes
> - [proxychains-ng](https://github.com/rofl0r/proxychains-ng) · [PortSwigger — proxying other tools / mobile](https://portswigger.net/burp/documentation/desktop/mobile)
