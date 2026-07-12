# Docker en el proyecto

> Nota de estudio para la defensa. Verificado contra los ficheros Compose y Dockerfile reales del repositorio.

---

## 1. ¿Qué es Docker? (breve)

Docker es una herramienta de **contenedores**. Un contenedor es un paquete que incluye una aplicación **junto con todo lo que necesita para ejecutarse** (sistema base mínimo, dependencias, configuración), de forma que corre **igual en cualquier máquina**: el portátil del desarrollador, el servidor de producción o la máquina del tribunal.

Cómo explicarlo:
- Resuelve el clásico *"en mi máquina funciona"*: el contenedor lleva su entorno dentro.
- Es **más ligero que una máquina virtual**: no virtualiza un sistema operativo completo, comparte el núcleo del anfitrión, así que arranca en segundos.
- Una **imagen** es la plantilla (se define con un `Dockerfile`); un **contenedor** es una instancia en ejecución de esa imagen.
- **Docker Compose** orquesta **varios contenedores a la vez** con un solo fichero YAML: en nuestro caso, backend + frontend + Mongo + Redis + Nginx levantados y conectados con un único comando.

**Frase resumen:** *"Docker nos permite levantar toda la plataforma (base de datos, caché, backend, frontend, proxy) con un comando, de forma idéntica en desarrollo y en producción."*

---

## 2. ¿Para qué usamos Docker en el proyecto?

Docker cumple **dos roles a la vez**, y esto es importante tenerlo claro:

1. **Entorno de desarrollo y QA local reproducible.** Con `docker compose up -d` se levanta la plataforma completa sin instalar nada nativo. Todas las sesiones de QA se hacen sobre este stack.
2. **Mecanismo real de despliegue en producción.** La producción **no** es un PaaS gestionado (se descartó Koyeb): es un **VPS Contabo autoalojado** (Ubuntu 24.04) donde corren **los mismos ficheros Compose**. El mismo par `docker-compose.yml` + `docker-compose.prod.yml` levanta staging y producción, cada uno como un proyecto Compose aislado.

> Matiz para la defensa: si te preguntan "¿Docker es solo para desarrollo?", la respuesta es **no** — es también el mecanismo de despliegue real. Lo que cambia entre entornos no es la tecnología (siempre Docker), sino el **overlay de configuración** que se aplica.

---

## 3. ¿Cómo usamos Docker? (arquitectura de la configuración)

### 3.1 Los servicios del stack

El fichero base (`docker-compose.yml`) define el stack completo:

| Servicio | Imagen | Rol |
|---|---|---|
| **frontend** | build propio → Nginx alpine | Sirve la SPA de React y hace de proxy a backend/WebSocket |
| **backend** | build propio → Node 26 alpine | API REST + servidor WebSocket (Socket.IO) |
| **worker** | misma imagen que backend | Proceso **separado** para trabajos asíncronos (BullMQ): retención RGPD, exportaciones, alertas |
| **mongo** | `mongo:7` | Base de datos (como *replica set* de un nodo, para poder usar transacciones) |
| **redis** | `redis:7-alpine` | Caché, tokens, rate limiting, coordinación (ver nota de Redis) |
| **redis-commander** | — | UI de administración de Redis (solo con perfil `debug`) |
| **mongo-express** | — | UI de administración de Mongo (solo con perfil `debug`) |
| *+ 3 servicios de init de Mongo* | — | Preparan el replica set y el usuario (ver punto 4) |

### 3.2 El patrón de *overrides* (base + dev + prod)

Docker Compose permite **fusionar varios ficheros**. Usamos un fichero base y dos *overlays* que solo modifican lo necesario:

- **`docker-compose.yml` (base)** → define todo y es **funcional por sí solo**. `docker compose up -d` levanta el sistema con credenciales por defecto.
- **`docker-compose.dev.yml` (desarrollo)** → añade **hot-reload**: monta el código fuente como volumen, usa `nodemon` en el backend, el servidor de desarrollo de Vite en el frontend (puerto 5173), abre el puerto de depuración de Node (9229) y **sube el límite de memoria** (Vite se moría con SIGKILL con el límite de 128 MB de producción).
- **`docker-compose.prod.yml` (producción/staging en el VPS)** → endurece: `restart: always`, **deja de exponer puertos internos** (Mongo, Redis y el backend no se publican al anfitrión, solo el frontend por loopback), sube límites de memoria (Mongo a 2 GB para la caché WiredTiger), activa rotación de logs y exige contraseñas sin valores por defecto.

Se usa así: `docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d` (dev) o `-f docker-compose.prod.yml` (prod).

**Perfiles:** las UIs de administración (Redis Commander, Mongo Express) están marcadas con `profiles: [debug]`, así que **no arrancan** salvo que lo pidas con `docker compose --profile debug up -d`. Evita exponer herramientas de depuración por accidente.

### 3.3 Los Dockerfiles (builds multi-etapa)

Ambos *Dockerfiles* usan **multi-stage build**.

Las builds multi-etapa (_multi-stage builds_) son una técnica de Docker para **conseguir imágenes finales muchísimo más ligeras, rápidas y seguras, separando el proceso de creación en distintas "fases" dentro de un mismo `Dockerfile`.**

Para entenderlo de forma muy sencilla, imagínalo como construir una casa:
- **Fase de obra (Build):** Traes camiones, hormigoneras, andamios y herramientas pesadas. Ensucchas mucho y ocupas mucho espacio para levantar el edificio.
- **Fase de entrega (Producción):** Una vez terminada la casa, retiras los andamios, te llevas la hormigonera y limpias los escombros. Al cliente solo le entregas la casa limpia, no las herramientas que usaste para construirla.

Sin _multi-stage_, tu imagen de Docker se quedaría con los "andamios y la hormigonera" dentro para siempre, pesando quizás 1 GB. Con _multi-stage_, creas una etapa temporal para compilar/instalar, **coges únicamente el resultado final** y **lo pasas a una imagen nueva y vacía que pesará apenas 100 MB**.

- **Backend** (`node:26-alpine`): tres etapas (`deps` / `development` / `production`). La imagen de producción instala **solo dependencias de producción**, corre como **usuario no-root** (`USER node`) y expone un `HEALTHCHECK` HTTP contra `/health`.
- **Frontend** (build → Nginx): etapa `builder` con Node compila la SPA con Vite; la etapa final es un `nginx:alpine` que **solo sirve los ficheros estáticos** ya compilados. Es la forma correcta de servir una SPA en producción (no se usa el servidor de desarrollo).

### 3.4 Nginx (dos capas)

- **Nginx dentro del contenedor frontend**: sirve la SPA (`try_files ... /index.html` para el enrutado del lado cliente) y hace de **proxy inverso interno** hacia el backend (`/api/` y `/socket.io/`). Incluye compresión `gzip_static` (sirve los `.gz` pre-generados en build, cero CPU en runtime), caché de assets con hash (`immutable`, 1 año) e `index.html` sin caché (para recoger versiones nuevas tras un deploy), rate limiting por IP y cabeceras de seguridad + CSP.
- **Nginx en el propio VPS** (fuera del repo, documentado): termina **HTTPS/TLS** (Certbot/Let's Encrypt), habla **HTTP/2** y reparte hacia los contenedores frontend de staging y producción por loopback. Por eso hay **doble proxy**, y el backend se configura con `TRUST_PROXY_HOPS=2` para leer bien la IP real del cliente.

---

## 4. Cosas interesantes para comentar

**a) El "baile de arranque" de MongoDB (lo más técnico y lucido).**
Queríamos usar **transacciones** en Mongo, que exigen un *replica set*, y a la vez **autenticación**. Combinar ambas cosas en Docker es sorprendentemente delicado, así que hay una **cadena de 3 servicios de inicialización idempotentes**:
1. Uno genera una vez un *keyfile* (clave de autenticación interna del replica set).
2. Otro crea el usuario root aprovechando la "*localhost exception*" de Mongo (comparte el *network namespace* del contenedor Mongo para que `127.0.0.1` sea realmente local).
3. Otro ejecuta `rs.initiate()` para iniciar el replica set.

Todos son **idempotentes**: si ya está hecho, no hacen nada. Es un buen ejemplo de resolver un problema real de infraestructura de forma robusta.

**b) `depends_on` con condiciones, no solo con orden.**
Los servicios no solo arrancan en orden: el backend **espera a que Mongo y Redis estén *sanos*** (`service_healthy`, comprobado con *healthchecks* reales) y a que la inicialización de Mongo **haya terminado con éxito** (`service_completed_successfully`). Esto evita el clásico problema de "el backend arranca antes de que la BD esté lista y peta".

**c) Endurecimiento de los contenedores (seguridad).**
- Contenedores con **sistema de ficheros de solo lectura** (`read_only: true`) + `tmpfs` únicamente en las rutas que necesitan escribir.
- **Límites de memoria** por servicio.
- **Usuarios no-root** en backend y Nginx.
- En producción, los servicios internos (Mongo, Redis, backend) **no publican puertos al anfitrión**; solo el frontend, y atado a `127.0.0.1` detrás del Nginx del VPS.

**d) El bug del bundle que "horneaba localhost" (muy buen ejemplo de decisión de diseño).**
Vite **incrusta las variables `VITE_*` en el JavaScript en tiempo de build**. Si pusiéramos una URL absoluta (`http://localhost:5000`), quedaría fija en el bundle y en producción el navegador intentaría conectar a localhost. La solución fue **no hornear ningún host**: en el build de Docker se pasa `VITE_API_URL=/api` (ruta **relativa**) y `VITE_SOCKET_URL=` (vacío). Como el Nginx del contenedor ya proxea `/api` y `/socket.io`, el navegador resuelve contra **el mismo dominio que le sirvió la página** — localhost en desarrollo, el dominio del VPS en producción — sin necesidad de un build distinto por entorno.

**e) Aislamiento multi-entorno en un solo host.**
Staging y producción conviven en el **mismo VPS** sin pisarse porque todos los recursos con estado (volúmenes de Mongo/Redis, red, puertos) son **parametrizables por variables de entorno**. Cada entorno es un proyecto Compose independiente (`-p eduplay-staging` / `-p eduplay-prod`) con sus propios datos aislados.

**f) Despliegue automatizado.**
El deploy lo hace un **runner self-hosted de GitHub Actions en el propio VPS**: al hacer push, ejecuta `docker compose ... up -d --build`, lanza un *smoke test* contra `/api/health/ready` y hace **rollback automático** si falla. Staging además se **auto-apaga por la noche** (timer de systemd a las 22:00, usando `stop` para preservar los datos) para ahorrar recursos.

---

## 5. Preguntas típicas y respuesta rápida

- **"¿Por qué separaste el `worker` del backend?"** → Los trabajos pesados/asíncronos (retención de datos RGPD, exportaciones, detección de alertas) no deben competir por CPU/memoria con el servidor que atiende a los usuarios. Son procesos independientes que comparten la misma imagen pero escalan y fallan por separado.
- **"¿Docker en producción? ¿No es solo para desarrollo?"** → Es ambas cosas. Producción es un VPS autoalojado que corre exactamente los mismos Compose con un overlay de endurecimiento. La reproducibilidad dev↔prod es precisamente la ventaja.
- **"¿Por qué Mongo como replica set si solo hay un nodo?"** → Porque las **transacciones** de MongoDB requieren replica set. No es por alta disponibilidad, es por integridad transaccional (varias escrituras que deben confirmarse juntas o ninguna).
- **"¿Cómo evitas exponer la base de datos?"** → En producción Mongo y Redis no publican puerto al host; solo son accesibles dentro de la red interna de Docker. Al exterior solo sale el frontend, tras el Nginx con TLS del VPS.
