---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo/Vulnerabilidades
Fecha de actualización: 2026-07-18
Nota previa:
Nota siguiente: "[[01 - Escaneo y configuración avanzada]]"
Area: "[[Nessus.base|Nessus]]"
---
---

<mark style="background: #ADCCFFA6;">`Nessus` (de Tenable) es el escáner de vulnerabilidades comercial de referencia</mark>: enorme base de *plugins*, rápido y con buen reporting. Es la herramienta central de una [[01 - Evaluación de vulnerabilidades|evaluación de vulnerabilidades]] de infraestructura. Esta carpeta cubre su uso; el *porqué* del VA vive en `Pentesting/002 - Evaluación de vulnerabilidades`.

# Instalación y arranque

Se descarga el paquete para tu sistema desde la [página de Tenable](https://www.tenable.com/downloads/nessus). La edición gratuita, **`Nessus Essentials`**, requiere solicitar un **código de activación** por correo (limitada a **5 IPs**; el escalón de pago `Essentials Plus` sube a 20 IPs por ~$199/año). Suficiente para aprender y para labs pequeños.

```shell-session
$ sudo dpkg -i Nessus-*-ubuntu*_amd64.deb     # instalar el paquete
$ sudo systemctl start nessusd                # arrancar el servicio
```

> [!warning]+ La versión de HTB está desfasada
> El módulo muestra `Nessus 8.15.1` (2021). <mark style="background: #FF5582A6;">En 2026 va por la rama **10.x**</mark>; descarga siempre la actual de Tenable — cada versión trae *plugins* nuevos (y sin *plugins* al día, un escáner de vulnerabilidades no vale nada).

# Acceso

Tras arrancar, Nessus compila su base de *plugins* (tarda unos minutos la primera vez) y expone su interfaz web:

```text
https://localhost:8834
```

Se accede por navegador, se crea el usuario administrador y, con el código de activación, queda listo. A partir de aquí todo se maneja desde la UI: escaneos, políticas y resultados.

El siguiente paso es configurar y lanzar un escaneo: [[01 - Escaneo y configuración avanzada]].
