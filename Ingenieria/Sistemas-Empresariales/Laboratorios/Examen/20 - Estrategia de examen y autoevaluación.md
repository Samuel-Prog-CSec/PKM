---
tags:
  - SIE/Laboratorio
  - SIE/Examen
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[19 - Variantes y práctica]]"
Nota siguiente: "[[21 - Ejercicio de práctica - Biblioteca (resuelto)]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Estrategia de examen y autoevaluación

Sabes el contenido y tienes el patrón ([[19 - Variantes y práctica]]). Esta última nota es para **ejecutar bien el día del examen** y para **comprobar que de verdad lo dominas**: primero táctica, luego un test de autoevaluación con las respuestas colapsadas.

## Cómo afrontar el examen (orden de trabajo)

<mark style="background: #FF5582A6;">El error más caro es ponerse a teclear sin haber diseñado el modelo de datos.</mark> Sigue este orden:

1. **Lee el enunciado dos veces** y subraya: entidades (¿qué modelos?), campos (¿qué tipos?), relaciones (¿quién tiene a quién?) y qué pantallas piden.
2. **Dibuja el modelo de datos** en papel: maestro `1—N` detalle, detalle `N—N` contactos. Decide tipos siguiendo el enunciado al pie de la letra (¿"año" es texto o número? ¿"fecha" es `Date`?).
3. **Scaffold** y estructura: `__manifest__.py` (activa el CSV), `__init__.py`.
4. **Modelos primero, TODOS los campos y relaciones** antes de actualizar ([[10 - Relaciones entre modelos]]).
5. **CSV de seguridad** (una línea por modelo) — sin esto no verás nada.
6. **Vistas** (tree, form con notebook, search), **acción** y **menú** (acción antes que menú).
7. **Instala/Upgrade** y comprueba contra las pantallas pedidas. Crea un par de registros de prueba.

> [!important]+
> **Gestión del tiempo** (orientativa para una práctica tipo P6): ~15% diseño (pasos 1-2), ~50% modelos+vistas (3-6), ~20% instalar y depurar (7), ~15% margen. Si te atascas en una vista, deja el módulo *funcionando* con lo básico y pule después: un módulo que instala y muestra datos puntúa más que uno "perfecto" que no arranca.

## La parte escrita / de diseño

Muchos enunciados piden **describir el módulo** además de programarlo. Qué escribir, breve y concreto:

- **Modelos y campos**: tabla con cada modelo, sus campos y tipos, y cuáles son obligatorios.
- **Relaciones**: la frase "una película tiene muchas sesiones (`One2many`/`Many2one`); una sesión tiene muchos asistentes (`Many2many` a `res.partner`)", con el `ondelete` justificado.
- **Vistas/menú**: qué vistas defines y cómo se navega (menú → acción → tree → form).
- Si sabes el modelo de datos, esta parte se escribe sola — es el diagrama del Paso 0 de [[18 - Filmoteca paso a paso]] en palabras.

## Qué cuesta puntos (revisa antes de entregar)

Repasa el checklist completo en [[19 - Variantes y práctica]]. Los tres que más caen: modelo **sin línea en el CSV**, fichero de modelos **sin importar** en `__init__.py`, y tocar el `.py` **sin reiniciar** Odoo antes del `Upgrade`.

## Autoevaluación

Tápate la respuesta e intenta contestar antes de desplegar el callout. Si fallas más de un tercio de un bloque, vuelve a la nota correspondiente.

### Python y Docker

> [!question]- En Odoo, ¿por qué se dice que "un modelo es una clase"? ¿Dónde se declaran sus campos?
> Un modelo es una clase Python que hereda de `models.Model`; hereda toda la maquinaria del ORM. Los campos se declaran como **atributos de clase** (`name = fields.Char()`), no dentro de un `__init__`. Ver [[01 - Python para Odoo]].

> [!question]- ¿Qué hace `volumes: ./addons:/mnt/extra-addons` en el compose de Odoo?
> Monta (bind mount) tu carpeta local `addons` dentro del contenedor en `/mnt/extra-addons`, que es donde Odoo busca módulos personalizados. Es el puente para que tu módulo aparezca en Odoo. Ver [[03 - Docker para Odoo]].

> [!question]- ¿Diferencia entre imagen y contenedor?
> La imagen es la plantilla de solo lectura (como un ejecutable); el contenedor es una instancia en ejecución de esa imagen (como un proceso). Cada `docker run` crea un contenedor nuevo.

### Administración y servicios web

> [!question]- ¿Qué tres servicios web ofrece Odoo por XML-RPC y para qué sirve cada uno?
> `db` (gestión de bases de datos), `common` (autenticación: `authenticate` devuelve el `uid`) y `object` (acceso a modelos vía `execute_kw`). Ver [[07 - Servicios web XML-RPC]].

> [!question]- ¿Cómo buscarías por API los contactos que son compañías de Madrid?
> `models.execute_kw(db, uid, pwd, 'res.partner', 'search', [[['city','=','Madrid'], ['is_company','=',True]]])`. El dominio es una lista de criterios `['campo','operador','valor']` combinados con AND.

> [!question]- ¿Para qué sirve el campo `parent_id` en `res.partner`?
> Asocia una persona de contacto a su compañía: al crear el contacto se pasa `'parent_id': id_de_la_compañía`.

### Desarrollo de módulos

> [!question]- ¿Qué tres campos relacionales hay y cuándo usar cada uno?
> `Many2one` (N→1, crea la clave foránea; lleva `ondelete`), `One2many` (1→N, reflejo inverso de un `Many2one`, no crea columna), `Many2many` (N↔N, tabla intermedia). Ver [[10 - Relaciones entre modelos]].

> [!question]- Tienes `sesion_ids = fields.One2many('filmo.sesion', 'pelicula_id')`. ¿Qué DEBE existir para que funcione?
> Un campo `Many2one` llamado exactamente `pelicula_id` en el modelo `filmo.sesion`, apuntando a `filmo.pelicula`. Sin ese inverso, el `One2many` no funciona.

> [!question]- ¿Por qué tu modelo nuevo "no aparece" en Odoo? Da tres causas.
> 1) No está importado en la cadena `__init__.py`. 2) Falta su línea en `ir.model.access.csv` (o el CSV está comentado en el manifest). 3) No has hecho Become Superuser / no reiniciaste tras tocar el `.py`. Ver [[14 - Seguridad y datos demo]].

> [!question]- ¿Qué hay que hacer tras cambiar `models.py`? ¿Y tras cambiar el XML?
> Tras `.py`: **parar y reiniciar Odoo + Upgrade**. Tras `.xml`: solo **Upgrade**. Tras eliminar/cambiar el tipo de un campo: desinstalar+borrar módulo, reiniciar, reinstalar.

> [!question]- ¿Cómo se estructura una vista form con pestañas y una tabla embebida de los hijos?
> `<form><sheet>` con un `<group>` de campos y un `<notebook>` con varias `<page>`; en una página, un `<field name="hijo_ids">` con un `<tree>` dentro. Ver [[12 - Vistas XML]].

> [!question]- En el CSV de seguridad, ¿qué significa dejar `group_id:id` vacío?
> Que la regla aplica a **todos los usuarios** (acceso global). Es la versión mínima que usa el examen.

> [!question]- ¿Orden correcto en el XML: menú antes o después de su acción? ¿Y el menú hijo respecto al padre?
> La **acción antes** que el menú que la referencia; el **menú padre antes** que sus hijos. El XML se carga de arriba abajo.

### Patrón del examen

> [!question]- Enunciado "Gestión de una biblioteca: libros y préstamos; a cada préstamo se asocian socios". Di los modelos, relaciones y tipos clave.
> `biblio.libro` (maestro) `1—N` `biblio.prestamo` (detalle) vía `prestamo_ids`/`libro_id` (`ondelete='cascade'`); `prestamo` `N—N` `res.partner` vía `socio_ids` (`Many2many`). Es Filmoteca con otros nombres. Ver [[19 - Variantes y práctica]].

> [!question]- ¿Qué es lo mínimo que debe tener tu módulo para puntuar (no "perfecto", sino aprobado)?
> Modelos con sus campos y relaciones, CSV con una línea por modelo, una vista form/tree, una acción y un menú, todo declarado en el manifest. Que **instale sin error y muestre datos** es lo que más puntúa.

> [!success]+
> Si puedes contestar estas preguntas de carrerilla y montar la Filmoteca a mano sin mirar, estás listo. La prueba definitiva: resuelve un enunciado **nuevo** de cero en [[21 - Ejercicio de práctica - Biblioteca (resuelto)]] antes de mirar la solución. Índice del tema: [[Laboratorios.base|MOC de Laboratorios]].
