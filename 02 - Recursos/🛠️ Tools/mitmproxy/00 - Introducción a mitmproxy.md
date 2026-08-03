---
tags:
  - Proxies
  - Protocolos
  - Redes
  - Tipo/Introduccion
Descripción: "Proxy de interceptación programable en Python: los siete modos de operación, cuándo gana a Burp y cómo se instala el certificado de CA"
Fecha de actualización: 2026-08-03
Nota previa: 
Nota siguiente: "[[01 - Addons de mitmproxy para protocolos binarios]]"
Area: "[[mitmproxy.base|mitmproxy]]"
---
---

`mitmproxy` es un proxy de interceptación **programable**. Donde [[Burp Suite.base|Burp]] y [[ZAP.base|ZAP]] apuestan por una GUI potente para trabajo web manual, mitmproxy apuesta por <mark style="background: #ADCCFFA6;">scriptabilidad en Python y modos de operación que Burp no cubre</mark> — en particular el proxy TCP y UDP en crudo, que es lo que lo convierte en el sustituto natural de `Canape` para protocolos que no son HTTP.

Versión verificada: **12.2.3** (12 de mayo de 2026).

## Los tres binarios

| Binario | Interfaz | Para qué |
| - | - | - |
| `mitmproxy` | TUI interactiva en consola | Explorar e interceptar a mano por SSH |
| `mitmweb` | Interfaz web | Lo mismo, con navegador |
| **`mitmdump`** | Sin interfaz, como `tcpdump` | **Automatización y addons**. El que más se usa |

## Modos de operación

Es donde está la diferencia real frente a otras herramientas:

| Modo | Invocación | Cuándo |
| - | - | - |
| **regular** | `--mode regular` (por defecto) | El cliente está configurado para usar proxy HTTP |
| **reverse** | `--mode reverse:https://api.objetivo.com` | El cliente no admite proxy; te pones delante del servidor |
| **transparent** | `--mode transparent` | Con redirección por `nftables`; recupera el destino con `SO_ORIGINAL_DST` |
| **socks5** | `--mode socks5` | El cliente habla SOCKS |
| **upstream** | `--mode upstream:http://proxy:8080` | Encadenar con otro proxy (p. ej. Burp detrás) |
| **local** | `--mode local:curl` | Intercepta el tráfico de **procesos concretos** de la máquina, sin tocar la red |
| **raw_tcp / raw_udp** | `--mode reverse:tcp://host:puerto` | **Protocolos que no son HTTP** |

Los dos últimos son los que no tienen equivalente en Burp. **`local` es el que más tiempo ahorra**: usa APIs de bajo nivel del sistema para redirigir el tráfico de un proceso, así que la aplicación **no sabe que está siendo interceptada** y no hay que tocar ni su configuración ni la red. Resuelve de un plumazo el problema de [[04 - Redirigir el tráfico hacia tu proxy]] cuando el objetivo corre en tu misma máquina.

```shell-session
$ mitmdump --mode local                 # todo el equipo
$ mitmdump --mode local:curl            # solo curl, por nombre de ejecutable
$ mitmdump --mode local:1337            # solo ese PID
$ mitmdump --mode local:curl,wget       # lista
$ mitmdump --mode local:!firefox        # todo MENOS firefox (el ! niega)
```

Disponible en Windows, Linux y macOS, con una implementación distinta por plataforma.

```shell-session
# Proxy inverso TCP crudo hacia un servicio propietario
$ mitmdump --mode reverse:tcp://10.10.10.5:12345@4444 \
           --set connection_strategy=lazy -s addon.py

# Interceptar solo lo que hace un proceso concreto
$ mitmdump --mode local:cliente_propietario

# Transparente, con la redirección hecha por nftables
$ mitmdump --mode transparent --showhost
```

> [!important]+ `connection_strategy=lazy` para protocolos donde habla primero el servidor
> Por defecto, mitmproxy conecta con el servidor **antes** de leer nada del cliente. Con muchos protocolos binarios el servidor envía un *banner* nada más aceptar, o el cliente espera antes de hablar, y eso desincroniza el proxy. `lazy` retrasa la conexión saliente hasta que hace falta. Si un protocolo «no funciona a través de mitmproxy», esto es lo primero que hay que probar.

## El certificado de CA

mitmproxy genera su propia CA en `~/.mitmproxy/` la primera vez que arranca:

```text
mitmproxy-ca-cert.pem      ← para instalar en el cliente (Linux, curl, Python)
mitmproxy-ca-cert.cer      ← Windows
mitmproxy-ca-cert.p12      ← con clave privada
```

Instalación en el cliente:

```shell-session
# El propio mitmproxy sirve una página con los certificados
#   → navegar a http://mitm.it con el proxy configurado

# Linux (Debian/Ubuntu), almacén del sistema
$ sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitm.crt
$ sudo update-ca-certificates

# Herramientas que ignoran el almacén del sistema
$ export REQUESTS_CA_BUNDLE=~/.mitmproxy/mitmproxy-ca-cert.pem   # Python requests
$ export NODE_EXTRA_CA_CERTS=~/.mitmproxy/mitmproxy-ca-cert.pem  # Node.js
$ export SSL_CERT_FILE=~/.mitmproxy/mitmproxy-ca-cert.pem        # curl, Go
```

> [!warning]+ Nunca dejes instalada una CA de pruebas
> Quien tenga la clave privada de `~/.mitmproxy/` puede interceptar **cualquier** conexión TLS de esa máquina. Desinstala el certificado al terminar el trabajo, y **no lo instales nunca en un equipo que uses para otra cosa**. Usa una VM o un contenedor desechable.

Para clientes que hacen *pinning*, la CA no basta: hay que ir por Frida o por parcheo ([[08 - Detección y evasión del análisis activo]]).

## Frente a Burp y ZAP

| | mitmproxy | Burp | ZAP |
| - | - | - | - |
| Protocolos no-HTTP | **Sí** (raw TCP/UDP) | Con extensiones, incómodo | No |
| Automatización | **Python nativo** | Extensiones Java/Python/Kotlin | Scripts, API |
| Escáner de vulnerabilidades | No | Sí (Pro) | Sí |
| Repeater / Intruder | Limitado | **Sí, es su fuerte** | Sí |
| Consumo de recursos | Muy bajo | Alto | Medio |
| En CI o headless | **Ideal** | Con Enterprise | Con daemon |

No compiten: se encadenan. `mitmdump --mode upstream:http://127.0.0.1:8080` mete a Burp detrás, así que mitmproxy resuelve el transporte raro y Burp hace el trabajo web.

## Guardar y reproducir

```shell-session
$ mitmdump -w sesion.mitm                    # grabar
$ mitmdump -nr sesion.mitm                   # releer sin abrir proxy
$ mitmdump -nr sesion.mitm -w filtrado.mitm "~u /api/"   # filtrar
$ mitmdump --server-replay sesion.mitm       # hacerse pasar por el servidor
$ mitmdump --client-replay sesion.mitm       # repetir las peticiones del cliente
```

`--server-replay` es especialmente útil para analizar un cliente sin tener el servidor: reproduce las respuestas grabadas.

> [!info]+ Fuentes
> - [mitmproxy — Modes of Operation](https://docs.mitmproxy.org/stable/concepts-modes/) y [Certificates](https://docs.mitmproxy.org/stable/concepts-certificates/).
> - Versión verificada el 2026-08-03 contra `api.github.com/repos/mitmproxy/mitmproxy/releases/latest`.
