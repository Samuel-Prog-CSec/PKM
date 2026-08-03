---
tags:
  - Web/Red-Team
  - PDF-Injection
  - Tipo/Defensa
Descripción: "Todas las vulnerabilidades del sub-tema nacen de dos causas: configuración insegura de la librería y falta de sanitización de la entrada"
Fecha de actualización: 2026-07-16
Nota previa: "[[03 - Arsenal de herramientas para PDF Injection]]"
Nota siguiente: ""
Area: "[[PDF Injection.base|PDF Injection]]"
---
---

Todas las vulnerabilidades del sub-tema nacen de dos causas: **configuración insegura** de la librería y **falta de sanitización** de la entrada. Se atacan en ese orden.

# Configuración segura de la librería

<mark style="background: #FFB8EBA6;">Muchos motores traen ajustes por defecto inseguros</mark> — leer la documentación y endurecer la configuración es obligatorio. Los interruptores críticos (ejemplo con DomPDF):

| Opción (DomPDF) | Riesgo | Valor seguro |
| - | - | - |
| `enable_remote` | SSRF (carga recursos externos) | `false` |
| `isPhpEnabled` | RCE (ejecución de PHP) | `false` |

Como mínimo, sea cual sea la librería, hay que garantizar:

- <mark style="background: #FF5582A6;">JavaScript nunca se ejecuta</mark>.
- El acceso a ficheros locales está prohibido.
- El acceso a recursos externos está prohibido o limitado.

# Sanitizar la entrada

La raíz del bug es que etiquetas HTML del usuario llegan al motor. Dos enfoques:

- **HTML-entity encoding** (lo más seguro): con `htmlentities()` en PHP, `<` pasa a `&lt;` y `>` a `&gt;`, <mark style="background: #8000E1A6;">de modo que ninguna etiqueta HTML se puede inyectar</mark>. Úsalo cuando el usuario no necesita formato.
- **Allowlist de etiquetas**: si se requiere permitir negrita, cursiva o imágenes, sanitizar con una lista blanca (un sanitizador robusto server-side, no un `str_replace`) y combinarlo con la configuración segura de arriba.

# Defensa en profundidad contra la SSRF

> [!important]+ Recursos externos: traerlos por adelantado
> Si la plantilla usa imágenes o CSS externos, <mark style="background: #8000E1A6;">la app debería descargarlos de antemano, guardarlos en local y reescribir el HTML para referenciar la copia local</mark>. Así se pueden aplicar reglas de firewall estrictas que bloqueen **todo** tráfico saliente del servidor de generación, eliminando la SSRF por completo. Si el usuario debe poder cargar recursos externos, usar una **allowlist** de endpoints permitidos para bloquear el acceso a la red interna.

Refuerzos adicionales: ejecutar el generador en un **contenedor aislado** sin red ni ficheros sensibles montados. La misma filosofía de aislamiento que en la [[06 - Prevención de SSRF|prevención de SSRF]].
