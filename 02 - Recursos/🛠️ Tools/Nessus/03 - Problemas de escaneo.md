---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo
Fecha de actualización: 2026-07-18
Nota previa: "[[02 - Interpretar y exportar resultados]]"
Nota siguiente:
Area: "[[Nessus.base|Nessus]]"
---
---

Nessus es potente, pero <mark style="background: #FF5582A6;">un escaneo mal planteado puede tumbar servicios, dar falsos positivos o no devolver nada</mark>. Estas precauciones aplican a Nessus y a cualquier escáner (ver también [[05 - Escaneo de vulnerabilidades#Detección y ruido (importa incluso en un VA)|el ruido del escaneo]]).

# Antes de escanear: comunicar

<mark style="background: #FFB86CA6;">Habla siempre con el cliente (o los responsables internos) antes</mark>:

- ¿Hay **hosts sensibles o legacy** que excluir del escaneo?
- ¿Hay **hosts de alta disponibilidad** que convenga escanear por separado, **fuera de horario laboral** o con una configuración distinta para evitar impacto?

Acordar esto por escrito evita convertir un VA rutinario en un incidente de disponibilidad.

# Impacto en la red

Un escaneo agresivo puede:

- **Saturar** enlaces o dispositivos de red con miles de sondas simultáneas.
- **Tumbar dispositivos frágiles**: <mark style="background: #8000E1A6;">equipos OT/SCADA, impresoras, sistemas embebidos y appliances legacy</mark> son famosos por caerse ante un escaneo normal. Un DoS accidental es un incidente, no un hallazgo.
- Devolver **falsos positivos** o **ningún resultado** si la config no es la adecuada.

# Mitigar

- **Excluir** de antemano los hosts frágiles identificados.
- **Reducir la concurrencia** y la tasa de sondas en la pestaña *Advanced* / la política de escaneo.
- **Ventanas de escaneo** pactadas (noche/fin de semana) para sistemas críticos.
- Preferir **credentialed + safe checks** (ver [[01 - Escaneo y configuración avanzada]]): menos intrusivo y más preciso.
- Probar la configuración contra un entorno no productivo antes de lanzarla en producción.

> [!important]+ Regla de oro
> Ante la duda sobre si un sistema aguantará el escaneo, **no lo escanees a ciegas**: pregunta, exclúyelo o trátalo aparte. La disponibilidad del cliente no es negociable por un poco más de cobertura.
