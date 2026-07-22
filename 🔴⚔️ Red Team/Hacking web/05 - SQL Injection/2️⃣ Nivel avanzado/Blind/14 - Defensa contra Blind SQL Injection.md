---
tags:
  - Web/Red-Team
  - SQLi
  - Seguridad/Prevencion-Vulnerabilidad
Fecha de actualización: 2026-06-04
Nota previa: "[[13 - Herramientas para Blind SQLi]]"
Nota siguiente:
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La defensa contra la blind SQLi es la misma que contra cualquier SQLi —no hay nada especial en que la inyección sea ciega—. Las medidas base están en la nota canónica de [[09 - Mitigación de SQL Injection|mitigación]]; aquí se resume y se añaden las **contramedidas específicas de MSSQL**, que son las que neutralizan los ataques de este módulo.

# La base: parametrizar (recordatorio)

<mark style="background: #ADCCFFA6;">La defensa real sigue siendo la [[09 - Mitigación de SQL Injection|consulta parametrizada]]</mark>: separar código de datos. En el driver `sqlsrv` de PHP para MSSQL, el cambio es mínimo pero decisivo:

```php
// Vulnerable — concatena la entrada
$sql = "SELECT email FROM accounts WHERE username = '" . $_POST['username'] . "'";
$stmt = sqlsrv_query($conn, $sql);

// Seguro — placeholder + parámetro aparte
$sql = "SELECT email FROM accounts WHERE username = ?";
$stmt = sqlsrv_query($conn, $sql, array($_POST['username']));
```

A esto se suman la validación por allowlist y, contra la inyección de [[07 - SQL Injection de segundo orden|segundo orden]], **sanear también a la salida** los datos que vienen de la base de datos —nunca confiar en lo almacenado—.

# Lo crítico en MSSQL: privilegio mínimo

Cada ataque de este módulo dependía de un privilegio excesivo de la cuenta de la aplicación. <mark style="background: #FF5582A6;">El principio de privilegio mínimo no previene la inyección, pero desactiva su escalada</mark>:

| Ataque MSSQL | Privilegio que lo habilita | Contramedida |
| ------------ | -------------------------- | ------------ |
| [[10 - MSSQL ejecución de comandos con xp_cmdshell\|xp_cmdshell]] (RCE) | rol `sysadmin` (`sa`) | No usar `sa`; cuenta de mínimos privilegios |
| [[11 - MSSQL robo de hashes NetNTLM\|NetNTLM leak]] | `EXECUTE` sobre `xp_dirtree` | Revocar la ejecución de esa función |
| [[12 - MSSQL lectura de archivos\|File read]] (OPENROWSET) | `ADMINISTER BULK OPERATIONS` | No conceder ese permiso |

> [!important]+
> <mark style="background: #FFB86CA6;">Nunca ejecutes las consultas de la aplicación como `sa`</mark>. MSSQL tiene roles de base de datos integrados (`db_datareader`, `db_datawriter`, etc.); la cuenta web debería tener solo el rol `public` más los permisos imprescindibles. Cualquier privilegio extra "por comodidad" será explotado en cuanto exista una inyección.

![Roles de base de datos integrados en SQL Server y sus permisos: db_owner, db_datareader, db_datawriter, db_ddladmin, db_securityadmin, db_accessadmin, db_backupoperator.](https://academy.hackthebox.com/storage/modules/177/defend/1.png)

# Deshabilitar funciones peligrosas

Para una cuenta que no las necesita, se revoca la ejecución de las funciones abusables. Por ejemplo, contra el [[11 - MSSQL robo de hashes NetNTLM|leak de NetNTLM]]:

```sql
REVOKE EXECUTE ON xp_dirtree FROM public
```

> [!warning]+
> No conviene **eliminar** del todo estas funciones (`xp_dirtree`, `xp_cmdshell`): el propio servidor las usa internamente. Lo correcto es **revocar su ejecución** a la cuenta concreta de la aplicación, no desinstalarlas. Y `xp_cmdshell` debe permanecer **deshabilitado** (su estado por defecto) salvo necesidad explícita y justificada.

> [!info]+
> Defensa en profundidad adicional, igual que en la [[09 - Mitigación de SQL Injection|mitigación general]]: desactivar mensajes de error en producción (dificulta el [[02 - Identificar SQLi basada en booleanos|fingerprinting]]), un [[05 - Bypass de protecciones web con SQLMap|WAF]] como capa perimetral, y monitorizar peticiones DNS salientes anómalas desde el servidor de BD (delatan intentos de [[09 - Exfiltración Out-of-Band por DNS|exfiltración OOB]]).

Con esto se cierra la SQLi a ciegas. El último módulo del path lleva la explotación al terreno white-box y a las técnicas más avanzadas: [[01 - Decompilación de archivos Java|SQLi avanzado]].
