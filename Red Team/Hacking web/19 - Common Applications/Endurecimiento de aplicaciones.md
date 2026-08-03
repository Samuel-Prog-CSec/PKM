---
tags:
  - Web/Red-Team
  - Common-Applications
Descripción: "La cara defensiva del módulo. El primer paso de cualquier organización es un inventario de aplicaciones preciso (internas y externas) — sin saber qué existe, no se sabe qué…"
Fecha de actualización: 2026-07-16
Nota previa: "[[Other Notable Applications]]"
Nota siguiente: ""
Area: "[[Common Applications.base|Common Applications]]"
---
---

La cara defensiva del módulo. <mark style="background: #FF5582A6;">El primer paso de cualquier organización es un **inventario de aplicaciones** preciso</mark> (internas y externas) — sin saber qué existe, no se sabe qué proteger. Herramientas como Nmap y EyeWitness sirven también al *blue team*, y el inventario destapa *shadow IT*, apps deprecadas y sorpresas (un Splunk *trial* convertido en Free sin autenticación).

# Hardening general

- **Autenticación segura**: contraseñas fuertes, <mark style="background: #FFB86CA6;">cambiar/deshabilitar las cuentas admin por defecto</mark> (crear una custom), y **2FA obligatorio** para admins.
- **Control de acceso**: los paneles/login **no accesibles desde Internet** salvo justificación (IP whitelist, VPN, localhost); permisos de fichero/carpeta que denieguen subidas/despliegues.
- **Deshabilitar funcionalidad peligrosa**: edición de PHP en WordPress, Script Console de Jenkins, CGI de Tomcat, nombres 8.3 de IIS, JavaScript server-side de MongoDB.
- **Actualizaciones y backups** regulares.
- **Monitorización de seguridad** + **WAF** (capa extra, no bala de plata).
- **Integración LDAP/AD (SSO)**: centraliza credenciales, mejora auditoría y política de contraseñas.

# Hardening específico por aplicación

| Aplicación | Medida |
| - | - |
| **WordPress** | Plugin de seguridad **WordFence** (monitorización, bloqueo, 2FA, country blocking) |
| **Joomla** | **AdminExile**: exige una clave secreta en la URL del admin (`/administrator?miclave`) |
| **Drupal** | Deshabilitar, ocultar o **mover** la página de login del admin |
| **Tomcat** | Limitar `/manager` y `/host-manager` a **localhost**; si deben exponerse, IP whitelist + contraseña fuerte + usuario no estándar |
| **Jenkins** | Permisos con el plugin **Matrix Authorization Strategy** |
| **Splunk** | Cambiar la contraseña por defecto y licenciar correctamente (para forzar autenticación) |
| **PRTG** | Mantener actualizado y cambiar el `prtgadmin` por defecto |
| **osTicket** | Limitar el acceso desde Internet |
| **GitLab** | Restricciones de registro (aprobación de admin, dominios permitidos/denegados) |

> [!info]+ La lección del módulo
> <mark style="background: #8000E1A6;">Estas aplicaciones rara vez caen por una vulnerabilidad exótica; caen por lo básico</mark>: una credencial por defecto en el Tomcat Manager, una versión de hace tres años, un repo GitLab abierto con una clave SSH, o una impresora con creds por defecto de la que sacar credenciales LDAP. Endurecer es disciplina operativa: **inventario, mínimo privilegio, parcheo, y no exponer lo que no hace falta** (¿ese repo tiene que ser público? ¿el ticketing accesible desde fuera?). Enlaza con la prevención específica de cada inyección: [[08 - Prevención de XPath Injection|XPath]], [[06 - Prevención de LDAP Injection|LDAP]], [[09 - Prevención de NoSQL injection|NoSQL]], [[10 - Prevención de SQL Injection|SQLi]].
