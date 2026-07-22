---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[06 - Envenenamiento LLMNR y NBT-NS]]"
Nota siguiente: "[[08 - Enumerar políticas de contraseñas]]"
Area: "[[AD Ataques de credenciales.base|Ataques de credenciales]]"
---
---

<mark style="background: #ADCCFFA6;">El *password spraying* prueba UNA contraseña contra MUCHOS usuarios</mark>, al revés que la fuerza bruta (muchas contraseñas contra un usuario). El motivo es puramente defensivo: <mark style="background: #FFB86CA6;">evitar el bloqueo de cuentas</mark>. El concepto general —spraying vs stuffing vs *defaults*, patrones de contraseña— ya está en [[04 - Password spraying, stuffing y defaults]]; aquí va el flujo concreto contra un dominio.

# Por qué no fuerza bruta

Cualquier dominio serio tiene política de bloqueo: tras N fallos la cuenta se bloquea. Probar 50 contraseñas contra `jsmith` la bloquea al quinto intento. <mark style="background: #8000E1A6;">Spraying le da la vuelta</mark>: una sola contraseña (`Welcome1`) contra los 2.000 usuarios del dominio se queda muy por debajo del umbral de cada cuenta, y basta con que **una** persona la use.

# El flujo en AD

1. Obtén la **política de contraseñas** → [[08 - Enumerar políticas de contraseñas]] (umbral de bloqueo y ventana de observación).
2. Construye la **lista de usuarios** → [[09 - Construir la lista de usuarios objetivo]].
3. Elige 1-2 contraseñas plausibles.
4. **Rocía** respetando la ventana de observación → [[10 - Password Spraying interno]].
5. Un acierto reabre la enumeración con un usuario nuevo — el bucle de siempre.

# Elegir la contraseña

Las que funcionan siguen patrones humanos y respetan la política mínima:

- Estación + año: `Autumn2025!`, `Winter2026`.
- Empresa + número: `Inlanefreight1`, `Freight2026!`.
- Clásicos: `Welcome1`, `Password123!`, `Changeme123`.

> [!warning]+ Spraying mal hecho = DoS + engagement quemado
> Si ignoras el umbral y la ventana, <mark style="background: #FF5582A6;">bloqueas cientos de cuentas de golpe</mark>: interrumpes el negocio (posible DoS) y avisas al SOC. Nunca rocíes sin haber leído antes la política en [[08 - Enumerar políticas de contraseñas]].
