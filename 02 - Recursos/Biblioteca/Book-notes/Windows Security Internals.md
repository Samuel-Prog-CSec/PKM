---
tags:
  - Biblioteca
  - Windows
Fecha de actualización: 2026-07-22
Autores:
  - James Forshaw
Editorial: No Starch Press
Año: 2024
ISBN: "978-1-7185-0198-0"
Portada: "03 - Archivos/Images/Biblioteca/Windows Security Internals.jpg"
PDF: "[[windowssecurityinternals.pdf]]"
Estado: Pendiente
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Windows Security Internals

![Portada de Windows Security Internals](03 - Archivos/Images/Biblioteca/Windows Security Internals.jpg)

**A Deep Dive into Windows Authentication, Authorization, and Auditing** — todo el libro se enseña con ejemplos ejecutables de `PowerShell`, no solo teoría.

## Sinopsis

Segunda obra de James Forshaw (investigador de Google Project Zero, más de 20 años analizando y explotando vulnerabilidades en Windows) centrada por completo en el modelo de seguridad interno de Windows: tokens, descriptores de seguridad, el proceso de *access check* y cómo se autentica un usuario tanto en local como en red. A diferencia de `Attacking Network Protocols`, aquí cada concepto viene acompañado de comandos `PowerShell` que se pueden lanzar y modificar en el momento — el libro construye desde cero, en la propia consola, cómo Windows concede acceso a un recurso.

La primera parte sienta las bases: arquitectura del kernel de Windows, el `Security Reference Monitor` (SRM) y las aplicaciones de *user-mode* (APIs de Win32, recursos GUI del kernel, rutas de registro, creación de procesos). La segunda —el núcleo del libro— diseca el SRM en profundidad: tokens de acceso (primarios, de impersonación, *sandbox*/`AppContainer`, `UAC`), descriptores de seguridad y `SID`, el proceso completo de *access check* (kernel-mode, user-mode, *sandboxing*, `Central Access Policies`) y auditoría de seguridad (SACL, política de auditoría, *Security Event Log*).

La tercera parte cubre la `Local Security Authority` y la autenticación: bases de datos `SAM`/`LSA`, `Active Directory` (esquema, descriptores de seguridad de objetos de directorio, *claims* y CAP, políticas de grupo), autenticación interactiva (`LsaLogonUser`), autenticación de red (`NTLM`), `Kerberos` y el proveedor `Negotiate`. Cierra con dos apéndices prácticos: montar un dominio de Windows de pruebas y el mapeo completo de alias `SID` en `SDDL`.

## Qué cubre el libro

- Arquitectura del kernel de Windows: `Object Manager`, gestor de memoria, `Code Integrity` y el propio `Security Reference Monitor` (SRM).
- Tokens de acceso: primarios, de impersonación, restringidos, `AppContainer`/*sandbox* y su relación con `UAC`.
- Descriptores de seguridad, `SID` y `ACL`: estructura, lenguaje `SDDL` y manipulación desde `PowerShell`.
- El proceso de *access check* completo (kernel-mode y user-mode), incluidas `Central Access Policies` y *sandboxing*.
- Auditoría de seguridad: política de auditoría, SACL y el *Security Event Log*.
- Bases de datos `SAM`/`LSA`: *RID cycling*, cambio forzado de contraseña, extracción de *hashes* locales.
- `Active Directory`: esquema, descriptores de seguridad de objetos de directorio, *claims* y políticas de grupo.
- Autenticación interactiva, de red (`NTLM`) y `Kerberos`, más el proveedor `Negotiate`.

## Enlace

[[windowssecurityinternals.pdf|Abrir PDF]]

## Notas propias

