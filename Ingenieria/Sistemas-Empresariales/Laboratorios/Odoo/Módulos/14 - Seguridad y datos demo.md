---
tags:
  - SIE/Laboratorio
  - SIE/Modulos
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[13 - Acciones y menús]]"
Nota siguiente: "[[15 - Campos computados y onchange]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Seguridad y datos demo

Dos piezas que cierran un módulo funcional: los **permisos de acceso** (sin ellos, un modelo nuevo es invisible) y los **datos de demostración** (opcionales, útiles para probar).

## Permisos: `ir.model.access.csv`

<mark style="background: #ADCCFFA6;">Cada modelo nuevo necesita al menos una línea de permisos en `security/ir.model.access.csv`, o nadie —ni siquiera `admin`— podrá verlo.</mark> Es un CSV con cabecera fija:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_filmo_pelicula,filmo.pelicula,model_filmo_pelicula,,1,1,1,1
access_filmo_sesion,filmo.sesion,model_filmo_sesion,,1,1,1,1
```

Columna a columna:
- `id` — identificador único de la regla (libre, descriptivo).
- `name` — nombre legible.
- `model_id:id` — el modelo, con el formato `model_<nombre_con_guiones_bajos>`. <mark style="background: #FFB8EBA6;">El `_name` `filmo.pelicula` se referencia como `model_filmo_pelicula`</mark> (el punto pasa a guion bajo, prefijo `model_`).
- `group_id:id` — el grupo al que aplica. **Vacío = todos los usuarios.**
- `perm_read,perm_write,perm_create,perm_unlink` — los cuatro permisos CRUD; `1` concede, `0` deniega.

<mark style="background: #FF5582A6;">Olvidar la línea del CSV (o dejarla comentada en el `data` del manifest) es la causa nº 1 de "creé el modelo pero no aparece" o "error de permisos".</mark> Recuerda activarla en `__manifest__.py` ([[08 - Estructura de un módulo y scaffold]]).

## Permisos por grupo: `res.groups`

Para un control más fino se definen **grupos** y se conceden permisos distintos a cada uno. En `security/security.xml`:

```xml
<odoo>
    <data>
        <record id="group_manager" model="res.groups">
            <field name="name">OpenAcademy / Manager</field>
        </record>
    </data>
</odoo>
```

Y el CSV reparte permisos: el grupo `manager` tiene todo; el resto (grupo vacío) solo lectura:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
course_manager,course manager,model_openacademy_course,group_manager,1,1,1,1
session_manager,session manager,model_openacademy_session,group_manager,1,1,1,1
course_read_all,course all,model_openacademy_course,,1,0,0,0
session_read_all,session all,model_openacademy_session,,1,0,0,0
```

El `security.xml` se carga **antes** que el CSV en el manifest (el CSV referencia al grupo):

```python
'data': [
    'security/security.xml',
    'security/ir.model.access.csv',
    'views/openacademy.xml',
],
```

> [!info]+
> **Dos niveles de seguridad, elige según el enunciado**: el examen Filmoteca usa la versión **simple** (CSV con `group_id` vacío = acceso total para todos), que es lo mínimo para que el módulo funcione. El openacademy de la práctica usa la versión **por grupos** (manager con CRUD, resto solo lectura). Sabe hacer las dos; para aprobar P6 basta la simple. Ver [[17 - Cómo programa el profesor (estilo y buenas prácticas)]].

## Datos de demostración: `demo.xml`

Registros que se cargan solo si la base se creó con demostración. Útiles para no empezar con tablas vacías. Cada registro es un `<record>` con su `model` e `id`, y sus campos:

```xml
<odoo>
    <data>
        <record model="openacademy.course" id="course0">
            <field name="name">Course 0</field>
            <field name="description">Course 0's description

Can have multiple lines
            </field>
        </record>
        <record model="openacademy.course" id="course1">
            <field name="name">Course 1</field>
            <!-- sin descripción -->
        </record>
    </data>
</odoo>
```

Se referencia desde el manifest en la clave `demo` (no en `data`):

```python
'demo': ['demo/demo.xml'],
```

> [!warning]+
> Diferencia `data` vs `demo`: lo de `data` se carga **siempre** (vistas, menús, seguridad); lo de `demo` solo si marcaste "Demo data" al crear la base. No metas vistas en `demo` ni datos de prueba en `data`.

> [!question]- Comprueba: el modelo `biblioteca.libro`, ¿cómo se escribe en la columna `model_id:id` del CSV?
> `model_biblioteca_libro`: prefijo `model_` y los puntos del `_name` convertidos en guiones bajos. Un fallo aquí deja el modelo sin permisos y "no aparece".

> [!question]- Comprueba: ¿qué implica dejar la columna `group_id:id` vacía?
> Que la regla aplica a **todos los usuarios** (acceso global). Es la versión mínima que usa el examen Filmoteca; para acceso por roles pondrías el id de un `res.groups`.

Con seguridad y datos, el módulo ya es completo. Lo que sigue es lógica avanzada (no exigida por el examen pero sí por la práctica): [[15 - Campos computados y onchange]].
