---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo/Vulnerabilidades
Fecha de actualización: 2026-07-18
Nota previa: "[[00 - Introducción a Nessus]]"
Nota siguiente: "[[02 - Interpretar y exportar resultados]]"
Area: "[[Nessus.base|Nessus]]"
---
---

# Crear un escaneo

`New Scan` ofrece plantillas (*scan templates*) en tres categorías:

- **Discovery** — `Host Discovery`: identifica hosts vivos y puertos abiertos (el equivalente a un [[01 - Host Discovery|barrido con Nmap]], como paso previo).
- **Vulnerabilities** — el grueso: `Basic Network Scan`, escaneos web, específicos por producto.
- **Compliance** — auditorías contra estándares ([[02 - Estándares de evaluación|PCI, CIS…]]).

Al configurar un `Basic Network Scan` se rellenan los objetivos y se afinan tres pestañas: **Discovery** (qué puertos/métodos de descubrimiento), **Assessment** (profundidad: web apps, fuerza bruta, etc.) y **Advanced** (rendimiento y concurrencia — clave para no saturar la red).

# Scan Policies (plantillas reutilizables)

<mark style="background: #ADCCFFA6;">Una *scan policy* es una configuración de escaneo guardada</mark> que luego aparece como plantilla propia. Permite estandarizar escenarios: un escaneo **lento y evasivo**, uno **enfocado a web**, o uno **por cliente** con su juego de credenciales. Reutilizar políticas ahorra tiempo y garantiza consistencia entre assessments.

# Plugins

Los **plugins** son las comprobaciones individuales de Nessus (una por vulnerabilidad conocida). Se pueden habilitar/deshabilitar por familias para acotar el escaneo. <mark style="background: #FF5582A6;">Mantenerlos actualizados es lo que hace útil a Nessus</mark>: un plugin desactualizado no detecta lo nuevo.

# Escaneo con credenciales (lo más importante)

<mark style="background: #8000E1A6;">Un escaneo **credentialed** cambia la calidad por completo</mark>: Nessus se autentica (SSH, SMB, WinRM, BBDD, SNMP…) y ve por dentro el host — parches instalados, versiones exactas, configuración. Resultado: **muchos menos falsos positivos y menos ruido** que un escaneo de red a ciegas (no tiene que inferir vulnerabilidades bombardeando el servicio). Es el estándar profesional para un VA serio; configúralo en `Credentials` dentro del escaneo o la política.

Con el escaneo lanzado, toca leer y exportar lo que produce: [[02 - Interpretar y exportar resultados]].
