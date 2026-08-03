---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Post-Explotacion
Descripción: "El 'double hop' es el problema de que tus credenciales no viajan al segundo salto"
Fecha de actualización: 2026-07-21
Nota previa: "[[16 - Acceso privilegiado]]"
Nota siguiente: "[[18 - Vulnerabilidades bleeding-edge]]"
Area: "[[AD Escalada y movimiento.base|Escalada y movimiento]]"
---
---

<mark style="background: #ADCCFFA6;">El "double hop" es el problema de que tus credenciales no viajan al segundo salto</mark>. Entras por WinRM/PSRemoting a `HOST-A` con usuario y contraseña; desde ahí intentas alcanzar `HOST-B` (un *share*, otro WinRM) y recibes *Access Denied* aunque las credenciales sean válidas. <mark style="background: #FFB86CA6;">No es un problema de permisos: es que tu credencial no está en HOST-A para reenviarla.</mark>

# Por qué pasa

WinRM autentica con un *network logon*: HOST-A verifica tu identidad contra el DC, pero <mark style="background: #FFB8EBA6;">no almacena tu contraseña</mark>. Cuando desde HOST-A pides un recurso en HOST-B, no hay credencial que presentar (y sin delegación configurada, el ticket Kerberos tampoco se reenvía). El primer salto funciona; el segundo se queda sin nada que ofrecer.

# Workarounds

- **Credenciales explícitas**: crea un `PSCredential` y pásalo con `-Credential` a cada comando dirigido a HOST-B. Tedioso pero funciona.
- **CredSSP**: habilita la delegación de credenciales… pero <mark style="background: #FF5582A6;">CredSSP cachea tu contraseña en HOST-A de forma recuperable</mark> (extraíble con `sekurlsa::` desde LSASS — riesgo de opsec, ver [[25 - Detección y evasión en AD]]), y por eso está desactivado por defecto.
- **Inyectar un TGT (la vía ofensiva limpia)**: con la contraseña o el hash, solicita un TGT y ponlo en memoria (`Rubeus`, o Pass-the-Ticket → [[14 - Pass the Ticket (PtT)]]). Con un TGT válido en la sesión, Kerberos autentica el segundo salto sin cachear nada.

> [!info]+ Te lo encontrarás constantemente
> El double hop aparece en cuanto usas `evil-winrm` o `Enter-PSSession` y tratas de saltar más allá. Si un comando "debería funcionar" y da *Access Denied* desde una sesión remota, sospecha del double hop antes que de los permisos. Cuando el salto es además entre redes distintas, entra en juego el pivoting (módulo `07 - Pivoting y túneles`).
