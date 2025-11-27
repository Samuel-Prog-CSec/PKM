---
tags:
Fecha de actualización: 2025-10-10
Nota previa: "[[Parámetros y valores]]"
Nota siguiente: "[[Filtrando la salida]]"
Area: "[[Fuzzing web]]"
---
---

El alojamiento virtual <mark style="background: #FFB86CA6;">permite atender varios sitios web o dominios desde un único servidor o dirección IP</mark>. Cada vhost está asociado con un nombre de dominio o nombre de host único. Cuando un cliente envía una solicitud [[HTTP]], el servidor web examina el `Host` del encabezado para determinar qué contenido de *vhost* entregar. Esto <mark style="background: #ADCCFFA6;">facilita la utilización eficiente de recursos y la reducción de costos</mark>, ya que varios sitios web pueden **compartir la misma infraestructura de servidor**.

Los subdominios, por otro lado, son extensiones de un nombre de dominio principal, creando una estructura jerárquica dentro del dominio. Se utilizan para **organizar diferentes secciones o servicios dentro de un sitio web**. Por ejemplo, `blog.example.com` y `shop.example.com` son subdominios del dominio principal `example.com`. A diferencia de los *vhosts*, los <mark style="background: #ADCCFFA6;">subdominios se resuelven en direcciones IP específicas a través de registros [[🧭 DNS]]</mark> (sistema de nombres de dominio).

| Característica           | Anfitriones virtuales                                                                      | Subdominios                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| **Identificación**       | Identificado por el encabezado `Host` en solicitudes *HTTP*.                               | Identificado por registros *DNS*, que apuntan a direcciones IP específicas.                                       |
| **Propósito**            | Se utiliza principalmente para **alojar varios sitios web en un solo servidor**.           | Se utiliza para **organizar diferentes secciones o servicios dentro de un sitio web**.                            |
| **Riesgos de seguridad** | Los *vhosts* mal configurados pueden exponer aplicaciones internas o datos confidenciales. | Pueden ocurrir vulnerabilidades de toma de control de subdominios si los registros *DNS* están mal administrados. |

# Gobuster
[[Herramientas#Gobuster|Gobuster]] es una herramienta de línea de comandos versátil reconocida por sus capacidades de [[Directorios y archivos]] y DNS. <mark style="background: #ADCCFFA6;">Sondea sistemáticamente servidores web o dominios de destino para descubrir directorios, archivos y subdominios ocultos</mark>, lo que lo convierte en un activo valioso en evaluaciones de seguridad y pruebas de penetración.

La flexibilidad de `Gobuster` se extiende al fuzzing para varios tipos de contenido:
- **Directorios**: descubrir directorios ocultos en un servidor web.
- **Archivos**: identificar archivos con extensiones específicas (por ejemplo, `.php`, `.txt`, `.bak`).
- **Subdominios**: enumerar subdominios de un dominio determinado.
- **Hosts virtuales (*vhosts*)**: descubrir hosts virtuales ocultos manipulando la cabecera `Host`.

## Fuzzing de Gobuster VHost
Mientras `Gobuster` es conocido principalmente por la enumeración de directorios y archivos, <mark style="background: #8000E1A6;">sus capacidades se extienden al descubrimiento de host virtual</mark> (*vhost*), lo que lo convierte en una herramienta valiosa para evaluar la postura de seguridad de un servidor web.

Vamos a diseccionar el <mark style="background: #FFB8EBA6;">comando de fuzzing de vhost</mark> de `Gobuster`:
```shell-session
$ gobuster vhost -u http://inlanefreight.htb:81 -w /usr/share/seclists/Discovery/Web-Content/common.txt --append-domain
```
> [!important]+
> - `gobuster vhost`: Esta bandera se activa `Gobuster's vhost fuzzing mode`, indicándole que se centre en descubrir hosts virtuales en lugar de directorios o archivos.
> - `-u http://inlanefreight.htb:81`: Esto especifica la URL base del servidor de destino. `Gobuster` utilizará esta URL como base para construir solicitudes con diferentes nombres de vhost. En este ejemplo, el servidor de destino se encuentra en `inlanefreight.htb` y escucha en el puerto 81.
> - `-w /usr/share/seclists/Discovery/Web-Content/common.txt`: Esto apunta al archivo de lista de palabras que `Gobuster` se utilizará para generar posibles nombres de vhost. El `common.txt` La lista de palabras de SecLists contiene una colección de nombres y subdominios de vhost de uso común.
> - `--append-domain`: Esta bandera crucial instruye `Gobuster` para agregar el dominio base (`inlanefreight.htb`) a cada palabra de la lista de palabras. Esto garantiza que `Host` El encabezado de cada solicitud incluye un nombre de dominio completo (por ejemplo, `admin.inlanefreight.htb`), lo cual es esencial para el descubrimiento de vhost.

En esencia, `Gobuster` toma cada palabra de la lista de palabras, le agrega el dominio base y luego envía una solicitud HTTP a la URL de destino con esa modificación `Host` cabecera. Al analizar las respuestas del servidor (por ejemplo, códigos de estado, tamaño de respuesta), `Gobuster` puede identificar válido `vhosts` que podrían no anunciarse ni documentarse públicamente.

Al ejecutar el comando se ejecutará un `vhost scan` contra el objetivo:
```shell-session
$ gobuster vhost -u http://inlanefreight.htb:81 -w /usr/share/seclists/Discovery/Web-Content/common.txt --append-domain

===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:             http://inlanefreight.htb:81
[+] Method:          GET
[+] Threads:         10
[+] Wordlist:        /usr/share/SecLists/Discovery/Web-Content/common.txt
[+] User Agent:      gobuster/3.6
[+] Timeout:         10s
[+] Append Domain:   true
===============================================================
Starting gobuster in VHOST enumeration mode
===============================================================
Found: .git/logs/.inlanefreight.htb:81 Status: 400 [Size: 157]
...
Found: admin.inlanefreight.htb:81 Status: 200 [Size: 100]
Found: android/config.inlanefreight.htb:81 Status: 400 [Size: 157]
...
Progress: 4730 / 4730 (100.00%)
===============================================================
Finished
===============================================================
```

Una vez completado el escaneo, vemos una lista de los resultados. De particular interés son los vhosts con el `200` código de estado. En HTTP, un estado 200 indica una respuesta exitosa, lo que sugiere que el vhost es válido y accesible. Por ejemplo, la línea `Found: admin.inlanefreight.htb:81 Status: 200 [Size: 100]` indica que el vhost `admin.inlanefreight.htb` fue encontrado y respondido con éxito.

## Fuzzing del subdominio con Gobuster
Si bien a menudo se asocia con vhost y descubrimiento de directorios, `Gobuster` También sobresale en la enumeración de subdominios, un paso crucial en el mapeo de la superficie de ataque de un dominio objetivo. Al probar sistemáticamente variaciones de posibles nombres de subdominios, `Gobuster` Puede descubrir subdominios ocultos u olvidados que podrían albergar información valiosa o vulnerabilidades.

Vamos a desglosar el `Gobuster` comando de fuzzing de subdominio:
```shell-session
$ gobuster dns -d inlanefreight.com -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt 
```

- `gobuster dns`: Activa `Gobuster's` Modo de fuzzing DNS, que le indica que se centre en descubrir subdominios.
- `-d inlanefreight.com`: Especifica el dominio de destino (por ejemplo, `inlanefreight.com`) para el cual desea descubrir subdominios.
- `-w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt`: Esto apunta al archivo de lista de palabras que `Gobuster` se utilizará para generar posibles nombres de subdominios. En este ejemplo, utilizamos una lista de palabras que contiene los 5000 subdominios más comunes.

Debajo del capó, `Gobuster` funciona generando nombres de subdominios basados en la lista de palabras, agregándolos al dominio de destino y luego intentando resolver esos subdominios mediante consultas DNS. Si un subdominio se resuelve en una dirección IP, se considera válido y se incluye en la salida.

Ejecutando este comando, `Gobuster` podría producir resultados similares a:
```shell-session
$ gobuster dns -d inlanefreight.com -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt 

===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Domain:     inlanefreight.com
[+] Threads:    10
[+] Timeout:    1s
[+] Wordlist:   /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
===============================================================
Starting gobuster in DNS enumeration mode
===============================================================
Found: www.inlanefreight.com

Found: blog.inlanefreight.com

...

Progress: 4989 / 4990 (99.98%)
===============================================================
Finished
===============================================================
```
> [!success]+
> En la salida, cada línea con el prefijo "*Encontrado:*" indica un <mark style="background: #FF5582A6;">subdominio válido descubierto</mark> por Gobuster.