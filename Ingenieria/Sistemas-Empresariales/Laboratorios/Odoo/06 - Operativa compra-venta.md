---
tags:
  - SIE/Laboratorio
  - SIE/Odoo
  - SIE
Fecha de actualización: 2026-05-27
Nota previa: "[[05 - Administración funcional]]"
Nota siguiente: "[[07 - Servicios web XML-RPC]]"
Area: "[[Laboratorios.base|Laboratorios]]"
---
---

# Operativa de compra y venta

Esta nota recorre los flujos de negocio de extremo a extremo (Práctica 3): cómo una compra y una venta atraviesan inventario, facturación y contabilidad. Es la visión "usuario final" de Odoo, y muestra en vivo por qué un ERP integra todos los departamentos sobre una única base de datos ([[Tema 2 - Soluciones de negocio]]).

> [!important]+
> Para el **examen de programación (P6) esto es contexto, no materia evaluable**: el examen pide construir un módulo, no operar flujos. Pero entender el ciclo de un documento (presupuesto → confirmado → entregado → facturado → pagado) ayuda a comprender qué modelan los objetos de Odoo. Léelo una vez; no es donde más debes invertir de cara al examen.

Requiere las apps **CRM, Inventory, Sales y Purchase** y la base de datos con demo. Todo con el usuario `admin`.

## Navegación de datos: filtros y agrupación

Antes de los flujos, soltura con las listas (modelo `res.partner` y productos):

- Filtros predefinidos **Companies** vs **Individuals**; vistas **kanban** y **list**.
- **Group by** para agrupar (p. ej. personas por compañía).
- Búsqueda con **AND/OR**: `City is "Fremont" or City is "Fairfield"` (unión) frente a dos condiciones encadenadas (intersección). <mark style="background: #FFB8EBA6;">Esta lógica de dominios es la misma que usarás por API</mark> en [[07 - Servicios web XML-RPC]].
- **Favorites → Save current search** guarda un filtro para reutilizarlo.

El menú **Contacts** en vista kanban, con los filtros predefinidos (Companies / Individuals) y la barra de búsqueda donde se aplican filtros y agrupaciones:

![[odoo-06-contactos-kanban.png]]

## Stock: on hand vs. forecasted

<mark style="background: #ADCCFFA6;">Cada producto tiene dos cantidades: la disponible real (*on hand*) y la prevista (*forecasted*)</mark>, que anticipa entradas (compras) y salidas (ventas) pendientes. Observar cómo cambian estas dos cifras es la mejor forma de entender el efecto de cada paso del flujo.

En la ficha de un producto, esas cantidades aparecen como **botones inteligentes** en la cabecera (`On Hand`, `Forecasted`), que además abren el detalle de movimientos:

![[odoo-06-producto-stock.png]]

## Flujo de compra (reproducible)

Producto `Drawer Black`, proveedor `Gemini Furniture`, cantidad 10, precio unitario 19. El documento de partida es una **Request for Quotation** (`Purchases → Create`): cabecera con el proveedor y, en la pestaña *Products*, las líneas con producto, cantidad y precio.

![[odoo-06-rfq-form.png]]

1. Comprueba el **stock** inicial de `Drawer Black`.
2. `Purchases`: crea una **Request for Quotation (RFQ)** con ese proveedor, producto, cantidad y precio. Imprime la RFQ (PDF).
3. **Confirm Order**: la RFQ pasa a orden de compra confirmada.
4. <mark style="background: #8000E1A6;">El stock *on hand* sigue siendo 0, pero el *forecasted* sube a 10</mark>: la entrada está prevista pero aún no ha llegado.
5. **Receive Products → Validate**: registras la recepción física. Imprime el albarán (`Print Picking Operations`).
6. Ahora el *on hand* refleja las 10 unidades; revisa los movimientos en `Product Moves`.
7. **Create Bill**, confírmala e imprímela. **Register Payment** eligiendo `Cash` como diario.
8. Para ver contabilidad completa, añade `admin` al grupo `Technical / Show Full Accounting Features`. En `Invoicing → Dashboard`, <mark style="background: #FFB8EBA6;">el balance de `Cash` es −190</mark> (10 × 19, salida de dinero).

## Flujo de venta (reproducible)

Cliente `Ready Mat`, producto `Conference Chair (Steel)`, cantidad 10, precio 20.

1. `Sales → Quotations`: crea un **presupuesto** con ese cliente, producto, cantidad y precio.
2. **Confirm Sale**: el presupuesto pasa a orden de venta confirmada. Imprime (PDF).
3. Revisa el stock real y previsto del producto: la venta resta del *forecasted*.
4. **Delivery → Validate**: planificas y validas la entrega; imprime el albarán. El *on hand* baja.
5. **Create Invoice** como `Regular Invoice`, confírmala e imprímela.
6. **Register Payment** del cliente con método `Cash`.
7. En `Invoicing → Dashboard`, <mark style="background: #FFB8EBA6;">el balance de `Cash` es 10</mark> (la venta entró 200 y antes la compra restó 190).

> [!success]+
> Si los balances de `Cash` cuadran (−190 tras la compra, +10 tras la venta), has seguido el ciclo completo correctamente. Esos números son la "comprobación de éxito" de la práctica.

## Qué llevarse de aquí para el examen

No memorices los pasos de la interfaz. Quédate con que <mark style="background: #FF5582A6;">cada documento (RFQ, orden, factura, albarán) es un registro de un modelo, con estados y relaciones</mark> — exactamente lo que vas a *programar* a partir de [[08 - Estructura de un módulo y scaffold]]. Antes, una última pieza de Odoo "desde fuera": [[07 - Servicios web XML-RPC]].
