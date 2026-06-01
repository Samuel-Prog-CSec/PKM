---
tags:
  - SIE/Laboratorio
  - SIE/Odoo
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[04 - Instalación con Docker]]"
Nota siguiente: "[[06 - Operativa compra-venta]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Administración funcional de Odoo

Antes de programar conviene moverse con soltura por la interfaz: instalar módulos, gestionar usuarios y permisos, y manejar los datos maestros (contactos y productos). Es la Práctica 2 desde el punto de vista del administrador. Todo se hace con el usuario `admin` sobre la base de datos `bd` creada en [[04 - Instalación con Docker]].

## Instalación de apps

<mark style="background: #ADCCFFA6;">Odoo es modular: solo instalas los módulos que vas a usar.</mark> Desde el menú **Apps** verás la rejilla de aplicaciones; cada tarjeta tiene un botón **Install**. Instala **CRM**, **Sales** e **Inventory**.

![[odoo-05-apps-grid.png]]

Para auditar lo instalado, despliega **Filters** y marca `Installed`; repítelo filtrando por `Apps` (módulos principales) y por `Extra` (módulos secundarios).

> [!info]+
> CRM instala el modelo de contactos enriquecido; Sales y Inventory aportan productos, stock y órdenes. La Práctica 3 ([[06 - Operativa compra-venta]]) necesita además **Purchase**. Sin estas apps, los menús de contactos/productos/órdenes no aparecen.

## Modo desarrollador

Para administrar y, sobre todo, para programar, necesitas el **modo desarrollador**. Entra en `Settings → General Settings`: la configuración se organiza por aplicación (columna izquierda: CRM, Sales, Inventory…) y por secciones (Users, Companies, Languages, Business Documents…):

![[odoo-05-general-settings.png]]

Baja del todo hasta la sección **Developer Tools** y pulsa **Activate the developer mode**:

![[odoo-05-developer-mode.png]]

<mark style="background: #FF5582A6;">Desbloquea las herramientas técnicas</mark>: ver modelos y campos (`Settings → Technical → Database Structure → Models`), inspeccionar vistas y acciones, y —clave para módulos— la opción **Become Superuser**.

Con el modo activo, la barra superior de `Settings` gana acceso a `Users & Companies`, `Translations` y `Technical` (no aparecían antes).

## Gestión de usuarios y grupos

<mark style="background: #ADCCFFA6;">En Odoo los permisos se conceden por pertenencia a grupos, no usuario por usuario.</mark> Operaciones de la práctica:

- **Ver usuarios**: `Settings → Users & Companies → Users`; abre `demo` y `admin` y revisa las pestañas **Access Rights** y **Preferences**.
- **Crear usuario**: crea `demo2` y asígnalo a los grupos `Sales / User: All Documents` e `Invoicing / Billing`. La contraseña se fija con `Actions → Change Password`.
- **Filtrar por grupo**: `Filters → Add Custom Filter` permite listar a qué grupos pertenece un usuario (`Users contains admin`) o qué usuarios hay en un grupo.

La lista de usuarios (`Settings → Users & Companies → Users`):

![[odoo-05-usuarios-lista.png]]

Al abrir un usuario, la pestaña **Access Rights** concentra sus permisos por aplicación (Sales, Inventory, Accounting…) y los botones inteligentes muestran sus *Groups* / *Access Rights* / *Record Rules*:

![[odoo-05-usuario-form.png]]

Los **grupos** del sistema (`Settings → Users & Companies → Groups`, solo visible en modo desarrollador) — fíjate en la nomenclatura `Aplicación / Nivel`, p. ej. `Sales / Administrator`:

![[odoo-05-grupos-lista.png]]

> [!important]+
> Este modelo grupo→permiso es exactamente lo que programarás en `ir.model.access.csv` y `res.groups` al dar seguridad a un módulo. Ver [[14 - Seguridad y datos demo]]. La administración por interfaz y la seguridad por código son las dos caras de lo mismo.

## Idiomas

`Settings → Translations → Languages`: busca **Spanish / Español** y pulsa `Activate/Update`. El idioma se cambia por usuario en `Menú del usuario → Preferences`. Odoo es multilingüe: las traducciones de los módulos se cargan a demanda.

## Administración de contactos (`res.partner`)

<mark style="background: #ADCCFFA6;">Los contactos viven en el modelo `res.partner`</mark> — el mismo que enlazarás como asistentes (`Many2many`) o instructores en tu módulo. Se clasifican con **categorías (tags)**, que pueden ser jerárquicas (padre/hijo):

- `Contacts → Configuration → Contact Tags`: lista las categorías hijas de `Vendor` (`Filters: Parent Category is "Vendor"`).
- Crea la categoría `Cliente VIP` con padre `Mis clientes`.
- Crea un contacto que sea **compañía** y pertenezca a `Cliente VIP`; fíltralo con `Tag contains "Cliente VIP"`.

![[odoo-05-contact-tags.png]]

<mark style="background: #FFB8EBA6;">Un contacto es compañía o persona según el campo `is_company`</mark>, y una persona se asocia a su empresa por el campo `parent_id`. Ambos campos reaparecen en los ejercicios de servicios web ([[07 - Servicios web XML-RPC]]).

## Administración de productos

Los productos también se clasifican por **categoría** (`category`):

- `Inventory → Configuration → Product Categories`: lista las categorías; las hijas de `All` se filtran con `Parent Category is "All"`.
- `Inventory → Products` con `Group by: Product Category` agrupa el catálogo.
- Crea un producto `NuevoProd` en una categoría nueva `All / NuevaCat` con `Internal Reference: NP`, `Sales price: 10`, `Cost: 7`.

![[odoo-05-product-categories.png]]

De cada producto importan, para la operativa, su **referencia interna**, sus **precios** (venta y compra, distintos) y su **stock** (cantidad disponible y prevista). Eso es justo lo que moverás en los flujos de compra y venta: [[06 - Operativa compra-venta]].
