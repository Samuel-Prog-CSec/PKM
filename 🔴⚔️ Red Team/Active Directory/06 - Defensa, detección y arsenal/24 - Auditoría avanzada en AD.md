---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[23 - Hardening de Active Directory]]"
Nota siguiente: "[[25 - Detección y evasión en AD]]"
Area: "[[AD Defensa y arsenal.base|Defensa y arsenal]]"
---
---

Auditar la postura de AD sirve a los dos bandos: al defensor para medir su exposición, y al pentester para <mark style="background: #ADCCFFA6;">obtener en minutos un mapa de misconfiguraciones del dominio</mark>. Estas herramientas complementan a BloodHound.

# PingCastle

El escáner de postura de AD de referencia. Puntúa el dominio, detecta misconfiguraciones y las mapea a un modelo de madurez:

```shell-session
$ PingCastle.exe --healthcheck
```

<mark style="background: #FFB86CA6;">En 5 minutos te da un informe con las rutas de riesgo del dominio</mark> — de lo primero que conviene correr. (HTB lo etiqueta como "fin de soporte 2023", pero **Netwrix adquirió PingCastle en agosto 2024** — el repo se movió a `github.com/netwrix/pingcastle`, la edición community sigue gratis y el proyecto está muy activo en 2026.)

# AD Explorer (Sysinternals)

Permite navegar AD y, sobre todo, <mark style="background: #FFB8EBA6;">crear *snapshots* para analizar offline y comparar en el tiempo</mark> — útil para detectar cambios (persistencia, nuevas ACLs) entre dos momentos.

# Group3r y ADRecon

- `Group3r`: audita GPOs buscando misconfiguraciones y credenciales (<mark style="background: #FF5582A6;">el terreno de las GPP y los scripts de [[19 - Configuraciones erróneas varias]]</mark>).
- `ADRecon`: genera un informe Excel exhaustivo del dominio (usuarios, grupos, trusts, políticas) — foto completa de un vistazo.

> [!info]+ También del lado azul
> `Purple Knight` (Semperis) y el propio BloodHound se usan en modo defensivo para cazar rutas de ataque antes que el atacante. Si el cliente ya corre estas herramientas, tus técnicas ruidosas se detectarán antes — razón de más para el sigilo de [[25 - Detección y evasión en AD]].
