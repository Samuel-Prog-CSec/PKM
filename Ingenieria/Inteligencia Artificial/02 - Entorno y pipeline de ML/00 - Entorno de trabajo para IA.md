---
tags:
  - IA
  - IA/Pipeline
  - Tipo/Introduccion
Descripción: "Montar el entorno de trabajo para ML tiene dos aristas: la práctica —que las dependencias no se peleen entre sí— y la de seguridad —que ese entorno es, en sí mismo, una…"
Fecha de actualización: 2026-07-28
Nota previa: "[[07 - Modelos de difusión]]"
Nota siguiente: "[[01 - Librerías de Python para IA]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

Montar el entorno de trabajo para ML tiene dos aristas: la práctica —que las dependencias no se peleen entre sí— y la de seguridad —que ese entorno es, en sí mismo, una superficie de ataque que aparece expuesta en engagements reales con más frecuencia de la esperable.

# Conda y el aislamiento de dependencias

<mark style="background: #ADCCFFA6;">`Miniconda` es un instalador mínimo que aporta el gestor de paquetes `conda` y un Python base, sin la batería completa de librerías que trae `Anaconda`.</mark> Se prefiere sobre `pip` puro en ML por un motivo concreto: <mark style="background: #FFB8EBA6;">`conda` gestiona también dependencias binarias no-Python</mark> — CUDA, MKL, BLAS— que son justamente donde `pip` falla al montar un entorno con GPU.

Instalación por plataforma:

```powershell-session
C:\> Set-ExecutionPolicy RemoteSigned -scope CurrentUser
C:\> irm get.scoop.sh | iex
C:\> scoop bucket add extras
C:\> scoop install miniconda3
C:\> conda --version
```

```shell-session
$ brew install --cask miniconda          # macOS
$ conda --version
```

```shell-session
$ wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
$ chmod +x Miniconda3-latest-Linux-x86_64.sh
$ ./Miniconda3-latest-Linux-x86_64.sh -b -u
$ eval "$(/home/$USER/miniconda3/bin/conda shell.$(ps -p $$ -o comm=) hook)"
```

## Configuración inicial

```shell-session
$ conda init
$ conda config --add channels conda-forge
$ conda config --add channels pytorch
$ conda config --add channels nvidia          # solo con GPU NVIDIA
$ conda config --set channel_priority strict
$ conda config --set auto_activate_base false # evita el prefijo (base) permanente
```

> [!warning]+ Ojo con el canal `defaults`: no es gratis en entorno profesional
> Muchas guías —incluida la de HTB— incluyen `conda config --add channels defaults`. <mark style="background: #FF5582A6;">Desde el cambio de condiciones de marzo de 2024, el uso del canal `defaults` (el repositorio de Anaconda, `repo.anaconda.com`) requiere licencia comercial de pago en organizaciones de 200 o más empleados</mark>, incluidas públicas y sin ánimo de lucro. Ha habido reclamaciones de licencia retroactivas a empresas que lo usaban sin saberlo.
>
> `conda-forge`, mantenido por la comunidad y alojado en `anaconda.org`, **queda fuera** de ese requisito. Para trabajo profesional, la configuración segura es usar `conda-forge` exclusivamente y no añadir `defaults`. Detalle en las [condiciones de uso de Anaconda](https://www.anaconda.com/legal). Alternativa limpia si no se necesitan binarios CUDA gestionados: `miniforge`, que trae `conda` preconfigurado solo con `conda-forge`.

## Entornos virtuales

Un entorno por proyecto. Aísla dependencias, permite reproducir el montaje en otra máquina y evita romper el Python del sistema.

```shell-session
$ conda create -n ai python=3.11
$ conda activate ai
$ conda deactivate
```

Paquetes base del stack:

```shell-session
$ conda install -y numpy scipy pandas scikit-learn matplotlib seaborn transformers datasets tokenizers accelerate evaluate huggingface_hub nltk
$ conda install -y pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia
$ conda update --all    # no actualiza lo instalado con pip
```

> [!info]+ La alternativa moderna: `uv`
> Desde 2024-2025 **`uv`** (de Astral, los autores de `ruff`) se ha convertido en el gestor de paquetes y entornos de Python más rápido del ecosistema — órdenes de magnitud por encima de `pip` y `conda` resolviendo dependencias. Para proyectos Python puros es hoy la opción por defecto. `conda` mantiene su ventaja donde hay que resolver toolchains binarios (CUDA, compiladores, librerías científicas compiladas), que es el caso de un entorno de deep learning con GPU. Merece la pena conocer ambos y elegir según si el proyecto tiene dependencias nativas o no.

# JupyterLab

<mark style="background: #ADCCFFA6;">Entorno de desarrollo interactivo basado en web donde el código se ejecuta por celdas</mark>, mezclando código, texto y visualizaciones en un mismo documento. Es el estándar de facto en ciencia de datos por lo que facilita la iteración: se ejecuta un fragmento, se ve el resultado, se ajusta.

```shell-session
$ conda install -y jupyter jupyterlab notebook ipykernel
$ jupyter lab
```

Un `notebook` se organiza en celdas de código, de markdown o crudas. `Shift + Enter` ejecuta la celda activa.

## El estado es global, y eso muerde

<mark style="background: #8000E1A6;">Un notebook mantiene estado entre celdas: variables, funciones e importaciones persisten mientras el `kernel` viva.</mark> Es lo que lo hace cómodo y también lo que produce el fallo más común: **ejecutar celdas fuera de orden**.

```python
x = 1          # celda 1
print(x)       # celda 2 -> 1
```

Si se edita la celda 1 a `x = 2` y se reejecuta, la celda 2 imprimirá `2` — pero si no se reejecuta la 1, el estado en memoria no coincide con lo que el código dice. <mark style="background: #FFB8EBA6;">Un notebook que "funciona" puede no funcionar al ejecutarlo de arriba abajo desde cero</mark>, y ese es el fallo de reproducibilidad clásico. La comprobación obligatoria antes de dar por bueno un análisis: **reiniciar el kernel y ejecutar todo en orden**.

`Kernel → Restart Kernel` limpia el estado sin cerrar JupyterLab; `Restart Kernel and Clear All Outputs` borra además las salidas.

# El entorno de ML como objetivo

Aquí está el ángulo que ninguna guía de instalación cubre, y que sí aparece en engagements:

> [!important]+ Un JupyterLab expuesto es ejecución de código remota
> <mark style="background: #FFB86CA6;">JupyterLab ejecuta código arbitrario por diseño.</mark> Un servidor accesible sin autenticación no es una configuración débil: es una shell interactiva pública, con los permisos del usuario que lo lanzó y acceso a los datos y credenciales de esa máquina. Hay campañas documentadas de minado de criptomoneda y de despliegue de malware que se dedican exclusivamente a buscar instancias de Jupyter abiertas.
>
> Qué buscar en un pentest:
> - Puerto `8888/tcp` (y adyacentes) accesible; comprobar si pide token o contraseña.
> - Un `notebook` server escuchando en `0.0.0.0` en vez de `127.0.0.1` — típico al arrancar en un contenedor o VM sin pensarlo.
> - Tokens de sesión filtrados en logs, en historiales de shell, en capturas de pantalla de documentación interna o en la salida del propio arranque.
> - Instancias tras un proxy inverso con la autenticación mal configurada.
>
> Desde dentro, un `kernel` de Jupyter da acceso al sistema de ficheros, a la red interna y a cualquier credencial montada en el entorno — que en máquinas de ML suele incluir claves de acceso a buckets con los datasets y a los registros de modelos.

Dos vectores más del propio ecosistema:

- **Cadena de suministro de paquetes.** `pip install` desde PyPI ejecuta código en la instalación si el paquete lo define. El *typosquatting* sobre nombres del stack de ML (`nunpy`, `sklean`, `pytorc`) es un clásico que sigue funcionando. Fijar versiones, usar un índice interno y revisar lo que se instala en máquinas con acceso a datos sensibles.
- **Secretos en los `.ipynb`.** Un notebook guarda **las salidas** junto al código. Claves de API impresas durante una prueba, `DataFrames` con datos personales o volcados de configuración quedan serializados en el JSON del fichero y viajan al repositorio. Es una fuente recurrente de fugas en repos públicos: al revisar un repositorio en un engagement, los `.ipynb` merecen una pasada específica.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con el cambio de licencia del canal `defaults`, la alternativa `uv` y la sección de seguridad del entorno, ausentes en el original.
- [Anaconda — Legal / Terms of Service](https://www.anaconda.com/legal) — requisito de licencia comercial para organizaciones de 200+ empleados (consultado 2026-07-28).
- [JupyterLab Documentation](https://jupyterlab.readthedocs.io/en/latest/getting_started/overview.html).
