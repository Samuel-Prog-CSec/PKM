---
tags:
  - SIE/Laboratorio
  - SIE/Odoo
  - SIE/Docker
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[03 - Docker para Odoo]]"
Nota siguiente: "[[05 - Administración funcional]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Instalación de Odoo con Docker

Con Docker dominado, levantar Odoo es escribir un `docker-compose.yml` y arrancar. Esta nota cubre la arquitectura de Odoo, los dos `docker-compose` del laboratorio (Odoo 14 y Odoo 11) y la gestión inicial de bases de datos.

## Arquitectura de Odoo

<mark style="background: #ADCCFFA6;">Odoo es una aplicación cliente/servidor de tres capas: un cliente web (navegador), un servidor de aplicación en Python y una base de datos PostgreSQL.</mark> Por eso el despliegue es **multicontenedor**: un servicio para Odoo y otro para PostgreSQL. Es el mismo patrón "aplicación + base de datos" del ejemplo MySQL+WordPress de [[03 - Docker para Odoo]].

Odoo es además un **ERP modular**: el núcleo es pequeño y la funcionalidad (CRM, Ventas, Inventario, Contabilidad…) se añade instalando módulos/apps. Esto conecta con la teoría de la asignatura — ver [[Tema 2 - Soluciones de negocio]].

## docker-compose para Odoo 14

```yaml
version: '2'
services:

  db:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - POSTGRES_DB=postgres

  odoo:
    image: odoo:14
    depends_on:
      - db
    ports:
      - "8069:8069"
    tty: true
    command: -- --dev=reload
    volumes:
      - ./addons:/mnt/extra-addons
```

Lectura del fichero, línea a línea:
- `db` usa `postgres:13`; las variables `POSTGRES_*` crean el usuario/clave que Odoo usará para conectarse. <mark style="background: #FFB8EBA6;">Odoo localiza la base de datos por el nombre del servicio (`db`)</mark>, gracias a la red interna de Compose.
- `odoo` usa `odoo:14`, `depends_on: db` (arranca PostgreSQL primero), publica el puerto `8069`.
- `command: -- --dev=reload` activa el **modo desarrollo**: Odoo recarga el código Python al detectar cambios, sin reiniciar el servidor. Imprescindible al programar módulos.
- `volumes: ./addons:/mnt/extra-addons` monta tu carpeta local `addons` donde Odoo busca módulos personalizados. <mark style="background: #FF5582A6;">Es el puente para que tu módulo aparezca dentro del contenedor.</mark>

Tras crear el fichero:

```shell-session
$ mkdir addons && chmod 777 addons
$ docker compose up -d
```

Comprueba en `http://localhost:8069` (o la IP de la VM).

> [!warning]+
> En Mac con chip ARM (M1/M2/M3) hay que añadir `platform: linux/amd64` al servicio `odoo` para que la imagen `amd64` funcione bajo emulación. En Windows/Linux no hace falta.

> [!warning]+ Troubleshooting habitual al arrancar
> - **`port is already allocated` (8069)**: tienes otro Odoo —o cualquier proceso— ocupando el puerto. Cámbialo (`"8169:8069"`) o para lo que lo use. Lo mismo con `5432` si publicaras PostgreSQL.
> - **El módulo/datos no aparecen**: casi siempre la carpeta `addons` no está bien montada o sin permisos. Verifica el `volumes:` y haz `chmod 777 addons`.
> - **Ver qué pasa por dentro**: `docker compose logs -f odoo` muestra el arranque en vivo (`HTTP service (werkzeug) running on ...:8069` = listo). Es lo primero que miro cuando "no carga".
> - **Empezar de cero**: `docker compose down -v` borra contenedores **y volúmenes** (pierdes las bases de datos). Útil para una instalación limpia; peligroso si querías conservarlas.

## docker-compose para Odoo 11 (simultáneo)

Se puede tener otra versión a la vez: basta cambiar el puerto del host (8070) y usar volúmenes nombrados para no chocar.

```yaml
version: '2'
services:

  web:
    image: odoo:11.0
    depends_on:
      - db
    ports:
      - "8070:8069"
    volumes:
      - odoo11-web-data:/var/lib/odoo
      - ./addons:/mnt/extra-addons

  db:
    image: postgres:9.4
    environment:
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo11-db-data:/var/lib/postgresql/data/pgdata

volumes:
  odoo11-web-data:
  odoo11-db-data:
```

Diferencias frente a Odoo 14 (útiles para entender el versionado): imagen `odoo:11.0` con `postgres:9.4` (cada rama de Odoo exige su versión de PostgreSQL), el servicio se llama `web`, el puerto del host es `8070`, y la persistencia se hace con **volúmenes nombrados** (`odoo11-web-data`, `odoo11-db-data`) en lugar del `bind mount` de datos.

> [!info]+
> Para las prácticas 5 y 6 (programación de módulos) el profesor recomienda **crear un contenedor nuevo**: un directorio aparte con su propio `docker-compose.yml` y su `addons`, para no mezclar con el trabajo previo. Es un consejo de higiene, no un requisito técnico.

## Gestión de bases de datos

Al conectar por primera vez, Odoo muestra el **gestor de bases de datos** en:

```text
http://localhost:8069/web/database/manager#action=database_manager
```

Desde ahí se puede **crear, duplicar, restaurar y borrar** bases de datos, y fijar la **clave máster** (la contraseña que protege estas operaciones). La primera vez, como no hay ninguna base de datos, Odoo te lleva directo al formulario de creación (y te genera una clave máster aleatoria que puedes sustituir):

![[odoo-04-crear-bd-form.png]]

Operaciones del laboratorio:

1. Fija la clave máster como `master`.
2. Crea una base de datos `bd`, en inglés, **marcando "Demo data"** (datos de demostración). Email/usuario `admin`, contraseña `admin`.

![[odoo-04-crear-bd-relleno.png]]

3. <mark style="background: #FFB8EBA6;">Al crearla con demo data, Odoo genera dos usuarios: `admin` (clave la que pusiste, `admin`) y `demo` (clave `demo`).</mark>
4. Duplica `bd` en `bd_copia` y comprueba que ambas son accesibles.

> [!warning]+
> Crear la base de datos **con datos demo tarda unos minutos** (Odoo instala los módulos base y carga los registros de demostración). Es normal que el navegador "se quede pensando"; no recargues a mitad. Puedes seguir el progreso con `docker compose logs -f odoo` (`Modules loaded.` = terminado).

Tras crearla, Odoo te lleva al **login**; entra con `admin` / `admin`:

![[odoo-04-login.png]]

Y ya estás dentro, en la pantalla principal con el selector de aplicaciones:

![[odoo-04-home.png]]

> [!important]+
> Marcar **"Demo data"** es decisivo para el laboratorio: los datos de prueba (contactos, productos, órdenes) que usarán las prácticas 3, 4 y 5 solo existen si la base de datos se creó con demostración. Sin ellos, los ejercicios de servicios web y de relaciones se quedan sin registros con los que trabajar.

Con Odoo instalado y la base de datos creada, pasamos a configurarlo: [[05 - Administración funcional]].
