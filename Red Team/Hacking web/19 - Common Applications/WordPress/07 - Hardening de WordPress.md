---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Enumeracion
  - Tipo/Defensa
Descripción: "Cierro el sub-tema por la cara defensiva, pero leída como atacante: la checklist de *hardening* es la checklist de ataque invertida"
Fecha de actualización: 2026-07-17
Nota previa: "[[06 - Arsenal de herramientas para WordPress]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Joomla]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Cierro el sub-tema por la cara defensiva, pero leída como atacante: <mark style="background: #ADCCFFA6;">la checklist de *hardening* es la checklist de ataque invertida</mark>. Cada medida de abajo tapa una técnica que hemos visto — saber cuáles suelen aplicarse (y cuáles no) te dice dónde merece la pena insistir en un objetivo real.

# Actualizaciones

El principio que más impacto tiene. Como los plugins concentran el ~54% de las CVEs, mantenerlos al día **mata el vector número uno**. WordPress permite auto-actualización del core y opt-in para plugins/temas vía `wp-config.php`/filtros:

```php
define( 'WP_AUTO_UPDATE_CORE', true );
add_filter( 'auto_update_plugin', '__return_true' );
add_filter( 'auto_update_theme', '__return_true' );
```

<mark style="background: #FFB86CA6;">Un objetivo con auto-updates activos cierra la ventana</mark> entre la publicación de una CVE y su explotación — justo la ventana que persigue un cazador. Si ves versiones al día en todo, el camino de "plugin vulnerable conocido" ([[03 - Explotación de plugins vulnerables]]) se estrecha y toca buscar 0-days o lógica.

# Higiene de plugins y temas

- Instalar solo desde fuentes de confianza (WordPress.org), revisando reviews, instalaciones activas y **fecha de última actualización** — un plugin abandonado es deuda de seguridad.
- Auditar y **eliminar** (no solo desactivar) lo que no se use. Recuerda: [[01 - Enumeración de WordPress|un plugin desactivado sigue en disco y es explotable]].

# Plugins de seguridad

Añaden capas que el atacante nota: **Wordfence** (firewall de endpoint + escáner de malware + límite de login), **Solid Security** (ex-iThemes: 2FA, reCAPTCHA, logging de acciones), **Sucuri** (auditoría, monitorización de integridad, escaneo remoto). Fingerprintearlos antes de actuar es parte de [[05 - Detección y evasión en WordPress]].

# Gestión de usuarios

El eslabón que más se ataca:

- **Desactivar el `admin` por defecto** y crear cuentas con nombres no adivinables (rompe la enumeración + spraying de [[02 - Login y fuerza bruta en WordPress]]).
- Contraseñas fuertes y **2FA obligatorio** para todos.
- Principio de **mínimo privilegio**: nadie con más rol del necesario (limita el alcance de una cuenta comprometida).
- Auditar cuentas periódicamente; revocar accesos y **Application Passwords** que ya no se usen.

# Configuración

- Instalar un plugin que **impida la enumeración de usuarios**.
- **Limitar intentos de login** (frena la fuerza bruta por cuenta).
- **Renombrar o reubicar `wp-login.php`** para sacarlo de internet o restringirlo por IP.
- `DISALLOW_FILE_EDIT` para matar el Theme/Plugin File Editor ([[04 - RCE como administrador en WordPress]]).
- **Desactivar `xmlrpc.php` y endpoints REST** que no se usen (corta amplificación, pingback SSRF y enum).

> [!important]+ Lectura del atacante
> Ninguna de estas medidas es infalible y algunas son **teatro**: <mark style="background: #8000E1A6;">ocultar la versión no es un control</mark> (sigue siendo fingerprinteable, [[05 - Detección y evasión en WordPress]]), y renombrar `wp-login.php` se suele delatar en redirecciones. Pero su **presencia o ausencia te informa**: un sitio con `xmlrpc` vivo, versión visible, `admin` existente y sin límite de login es fruta madura; uno con WAF de borde, 2FA y auto-updates exige lógica de negocio, 0-days o cadenas más finas. El *hardening* no elimina la superficie — la reordena.

> [!info]+ Contexto blue team
> Para el equipo defensor, esto se complementa con monitorización (integridad de ficheros, alertas de login) y respuesta. Buena parte encaja con prácticas generales de bastionado de aplicaciones web ([[Endurecimiento de aplicaciones]]).

Con WordPress cubierto de punta a punta — estructura, enumeración, ataque, evasión, herramientas y defensa — el recorrido por los CMS continúa con [[00 - Descubrimiento y enumeración de Joomla|Joomla]].
