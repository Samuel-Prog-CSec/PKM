---
tags:
  - SIE/Laboratorio
  - SIE/Docker
  - SIE
Descripción: "Docker es el segundo prerrequisito instrumental: no levantarás Odoo a mano, lo levantarás como contenedores"
Fecha de actualización: 2026-05-27
Nota previa: "[[02 - Ejercicios Python resueltos]]"
Nota siguiente: "[[04 - Instalación con Docker]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Docker para Odoo

Docker es el segundo prerrequisito instrumental: no levantarás Odoo a mano, lo levantarás como **contenedores**. Esta nota cubre lo que necesitas para entender *qué* arranca el `docker-compose.yml` de Odoo y *por qué* — y resuelve los ejercicios de la Práctica 1 con su razonamiento.

## Imagen vs. contenedor

<mark style="background: #ADCCFFA6;">Una imagen es una plantilla de solo lectura con el SO base, la aplicación y sus dependencias; un contenedor es una instancia en ejecución de esa imagen.</mark> La analogía exacta: la imagen es el programa ejecutable (estático) y el contenedor es el proceso (dinámico). Docker aprovecha el kernel del host (virtualización ligera), por eso arranca en segundos frente a una máquina virtual.

> [!info]+
> Diferencia con una VM: la máquina virtual lleva un sistema operativo completo; el contenedor comparte el kernel del anfitrión y solo empaqueta la app y sus librerías. Resultado: menos recursos, más rapidez, portabilidad ("build once, run anywhere").

## CLI esencial

```shell-session
$ docker run -it ubuntu /bin/bash   # crea+ejecuta contenedor interactivo
$ docker ps                          # contenedores en ejecución
$ docker ps -a                       # todos (parados incluidos)
$ docker image ls                    # imágenes locales
$ docker exec [cont] [orden]         # ejecuta una orden dentro
$ docker logs [cont]                 # ver el log (depuración)
$ docker start/stop/rm [cont]        # arrancar / parar / borrar contenedor
$ docker rmi [imagen]                # borrar imagen
```

Detalle que importa: `docker ps` usa la columna **CONTAINER ID** (o NAME) para referenciar el contenedor en el resto de órdenes. <mark style="background: #FFB8EBA6;">Cada `docker run` crea un contenedor *nuevo*</mark>: si ejecutas la misma imagen tres veces tendrás tres contenedores. Para reusar uno parado, `docker start`.

## Crear una imagen a partir de un contenedor (`commit`)

Ejercicio P1: arrancar `ubuntu`, instalar `nano`, y "congelar" ese estado en una imagen nueva.

```shell-session
$ docker run -it ubuntu /bin/bash
# apt-get update && apt-get install --yes nano
# exit
$ docker commit -m "ubuntu+nano" -a "A. Garcia" CONTAINER_ID ubuntu-nano:latest
```

Decisión: `commit` sirve para guardar cambios manuales, pero **no es reproducible** (nadie sabe qué hiciste dentro). Por eso en la práctica se prefiere el `Dockerfile`.

## Crear una imagen a partir de un `Dockerfile`

Mismo resultado que `commit`, pero declarativo y versionable:

```dockerfile
# Ubuntu+nano
FROM ubuntu
LABEL org.opencontainers.image.authors=a@gmail.com
RUN apt-get update
RUN apt-get install --yes nano
```

```shell-session
$ docker build -t ubuntu-nano:latest .
```

`FROM` fija la imagen base, `RUN` ejecuta órdenes durante la construcción, `LABEL` añade metadatos. <mark style="background: #8000E1A6;">La imagen oficial `odoo:14` se construye exactamente así: parte de Debian, instala Python, PostgreSQL-client y Odoo.</mark> Tú no escribirás el Dockerfile de Odoo, pero entender `FROM`/`RUN` explica qué hay dentro de esa imagen.

## Mapeo de puertos

Una app dentro del contenedor escucha en un puerto; para acceder desde el host hay que **publicarlo** con `-p host:contenedor`:

```shell-session
$ docker run -d --name web-test -p 8100:8000 crccheck/hello-world
# accesible en http://localhost:8100  → redirige al 8000 del contenedor
```

<mark style="background: #FF5582A6;">Esto es exactamente lo que hace `"8069:8069"` en el compose de Odoo</mark>: publica el puerto 8069 del contenedor en el 8069 del host. Para tener dos Odoo a la vez, basta cambiar el lado del host (`"8070:8069"`). Ver [[04 - Instalación con Docker]].

## Volúmenes: persistencia y código compartido

Las imágenes son capas de solo lectura; el contenedor añade una capa de lectura-escritura **efímera** (al borrar el contenedor se pierden los cambios). <mark style="background: #ADCCFFA6;">Un volumen es un directorio persistente, fuera de esa capa efímera, accesible desde el contenedor.</mark> Hay tres formas:

```shell-session
# 1) Bind mount: monta un directorio del host
$ docker run -it -v $HOME:/mnt ubuntu        # lectura-escritura
$ docker run -it -v $HOME:/mnt:ro ubuntu     # :ro = solo lectura

# 2) Volumen con nombre (gestionado por Docker)
$ docker volume create my-volume
$ docker run -it -v my-volume:/data-volume ubuntu

# 3) Compartir el volumen de otro contenedor
$ docker run -it --volumes-from ubuntu1 ubuntu
```

<mark style="background: #8000E1A6;">El `bind mount` es la pieza clave para programar módulos: el compose de Odoo monta `./addons:/mnt/extra-addons`, de modo que el código que escribes en tu carpeta local aparece dentro del contenedor donde Odoo lo busca.</mark> El volumen con nombre se usa para que PostgreSQL no pierda la base de datos al recrear el contenedor.

## Docker Compose: varios contenedores a la vez

Una app real son varios servicios (base de datos + servidor). Gestionarlos uno a uno con `docker run` es incómodo; `docker-compose.yml` los define todos en un fichero declarativo:

```yaml
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8000:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
volumes:
  db_data:
```

Claves a reconocer (son las mismas del compose de Odoo): `services` (cada contenedor), `image`, `ports`, `volumes`, `environment` (configuración por variables), `depends_on` (orden de arranque). El servicio `wordpress` localiza la base de datos por el **nombre del servicio** (`db:3306`): Docker Compose crea una red interna donde cada servicio es resoluble por su nombre.

```shell-session
$ docker compose up        # crea y arranca (log en consola; Ctrl-C para)
$ docker compose up -d     # en segundo plano (libera el terminal)
$ docker compose stop      # parar
$ docker compose down      # parar y eliminar contenedores/redes
```

> [!warning]+
> Tres trampas reales del laboratorio:
> - **Indentación**: el YAML solo admite **espacios**, nunca tabuladores. Un tab rompe el fichero.
> - **Directorio**: las órdenes `docker compose` deben ejecutarse en el directorio que contiene el `docker-compose.yml`.
> - **Permisos de `addons`**: tras crear la carpeta hay que darle permisos (`chmod 777 addons`); y el `scaffold` crea los ficheros como `root`, por eso luego harás `docker exec -u root ...` y un `chown`. Ver [[08 - Estructura de un módulo y scaffold]].

Con Docker claro, ya puedes levantar Odoo: [[04 - Instalación con Docker]].
