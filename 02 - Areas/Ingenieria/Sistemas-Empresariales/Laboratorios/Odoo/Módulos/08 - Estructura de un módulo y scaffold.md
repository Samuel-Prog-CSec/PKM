---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[07 - Servicios web XML-RPC]]"
Nota siguiente: "[[09 - Modelos y tipos de campo]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Estructura de un módulo y scaffold

Empieza el núcleo del examen: programar un módulo Odoo. Un **módulo** (o *addon*) es un directorio con una estructura fija de ficheros Python y XML que Odoo carga. Esta nota cubre cómo generarlo y qué hace cada pieza. El ejemplo de referencia del laboratorio es `openacademy`; el examen pedirá uno equivalente ([[18 - Filmoteca paso a paso]]).

## Generar el esqueleto con `scaffold`

Odoo trae un generador que crea la estructura vacía. Con el contenedor arrancado:

```shell-session
$ docker exec -itu root [contenedor] /usr/bin/odoo scaffold [modulo] /mnt/extra-addons
$ sudo chown -R $USER:$USER [directorio del modulo]
```

- `[contenedor]` es el nombre o ID del contenedor de Odoo; `[modulo]` el nombre (p. ej. `openacademy`). El módulo se crea dentro de `addons`, que está montado en `/mnt/extra-addons`.
- <mark style="background: #FFB8EBA6;">`scaffold` crea los ficheros como `root`</mark> (de ahí `-u root`); por eso el `chown` posterior te devuelve la propiedad para poder editarlos desde el host.
- Si el scaffold falla, el profesor ofrece un esqueleto descargable (`openacademy_vacio.zip`) en el campus.

Para que Odoo vea el módulo nuevo, en `Apps` hay que pulsar **Update Apps List** (solo visible en [[05 - Administración funcional|modo desarrollador]]):

![[odoo-08-update-apps-list.png]]

Después, quitando el filtro "Apps" del buscador, tu módulo aparece con su botón **Install** (el nombre técnico bajo el título confirma que Odoo lo reconoce):

![[odoo-08-filmo-en-apps.png]]

## Estructura de directorios

```text
openacademy/
├── __manifest__.py        # metadatos: qué es y qué ficheros carga
├── __init__.py            # importa los subpaquetes Python (models, controllers)
├── models/
│   ├── __init__.py        # from . import models
│   └── models.py          # definición de modelos (clases)
├── views/
│   └── openacademy.xml     # vistas, acciones y menús (XML)
├── security/
│   └── ir.model.access.csv # permisos de acceso por modelo
├── demo/
│   └── demo.xml            # datos de demostración
└── controllers/            # rutas web (no se usa en openacademy/filmo)
```

<mark style="background: #ADCCFFA6;">La regla de oro: Python (`.py`) define el comportamiento (modelos), XML define la presentación (vistas, menús) y los datos; el CSV define la seguridad.</mark>

## `__manifest__.py`: el carné del módulo

Declara los metadatos y, sobre todo, **qué ficheros se cargan y en qué orden**:

```python
{
    'name': "openacademy",
    'summary': "Short summary",
    'description': "Long description",
    'author': "My Company",
    'category': 'Uncategorized',
    'version': '0.1',
    'depends': ['base'],          # módulos requeridos antes que este
    'data': [                      # se cargan SIEMPRE (en orden)
        'security/ir.model.access.csv',
        'views/openacademy.xml',
    ],
    'demo': [                      # se cargan SOLO con datos de demostración
        'demo/demo.xml',
    ],
}
```

Claves que importan:
- `depends`: lista de módulos previos. `['base']` es el mínimo; si extiendes contactos necesitarás que `base` esté (ya lo está).
- `data`: ficheros XML/CSV que se cargan siempre, **en el orden de la lista** — el orden importa (la seguridad antes que las vistas que la usan).
- `demo`: datos que solo se cargan si la base se creó con demostración.

> [!warning]+
> El esqueleto que genera `scaffold` deja la línea `'security/ir.model.access.csv'` **comentada** en `data`. Es la causa nº 1 de "mi modelo no aparece o da error de permisos". <mark style="background: #FF5582A6;">Descoméntala (o añádela) en cuanto definas un modelo.</mark> El profesor la activa siempre — ver [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].

## `__init__.py`: qué carga Python

Encadenan los imports para que Odoo encuentre tus clases:

```python
# openacademy/__init__.py
from . import models

# openacademy/models/__init__.py
from . import models
```

Si tu fichero de modelos no está en esta cadena de imports, <mark style="background: #FF5582A6;">el modelo simplemente no existe para Odoo</mark> — sin error llamativo. Es lo primero que se revisa cuando "no aparece el menú".

## El ciclo de actualización (memorízalo)

> [!important]+
> Cómo se aplican los cambios, según el tipo de fichero (lo recalca el profesor y reaparece en cada nota):
> - **Cambias un `.py`** (modelos/lógica): **detén y vuelve a arrancar Odoo** + **Upgrade** del módulo.
> - **Cambias un `.xml`** (vistas/datos): basta con **Upgrade** del módulo.
> - **Eliminas o cambias el tipo de un campo**: **desinstala y borra** el módulo, reinicia Odoo y **reinstálalo** (un `Upgrade` no quita columnas de la base de datos).
>
> Y para *ver* los menús nuevos hay que ser superusuario: modo desarrollador → **Become Superuser**.

Con la estructura clara, definimos el primer modelo: [[09 - Modelos y tipos de campo]].
