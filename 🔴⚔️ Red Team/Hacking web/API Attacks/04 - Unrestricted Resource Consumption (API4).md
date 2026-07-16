---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Fecha de actualización: 2026-07-15
Nota previa: "[[03 - Broken Object Property Level Authorization (API3)]]"
Nota siguiente: "[[05 - Broken Function Level Authorization (API5)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Una API es vulnerable a `Unrestricted Resource Consumption` si <mark style="background: #ADCCFFA6;">no limita las peticiones que consumen recursos</mark> — ancho de banda, CPU, memoria, almacenamiento. Estos recursos cuestan dinero, así que el impacto no es solo `DoS`, sino <mark style="background: #FFB86CA6;">daño económico directo</mark> (*denial-of-wallet*). En el lab: `CWE-400: Uncontrolled Resource Consumption` en una subida de ficheros.

# Escenario: upload sin límites

Como supplier con rol `SupplierCompanies_UploadCertificateOfIncorporation`, tenemos `POST /api/v1/supplier-companies/certificates-of-incorporation`, que guarda el certificado (`PDF`) en disco **indefinidamente**.

## Sin validación de tamaño → DoS de disco

Generamos un fichero de 30 MB de bytes aleatorios con extensión `.pdf` y lo subimos:

```shell-session
$ dd if=/dev/urandom of=certificateOfIncorporation.pdf bs=1M count=30
```

La API lo acepta y confirma el tamaño. Como **no valida el tamaño ni implementa rate-limiting**, repetir la subida en bucle <mark style="background: #FF5582A6;">llena todo el disco del servidor</mark> → denegación de servicio y coste para el negocio.

## Sin validación de extensión → hosting de malware

Probamos a subir un `.exe` de 10 MB:

```shell-session
$ dd if=/dev/urandom of=reverse-shell.exe bs=1M count=10
```

También lo acepta: <mark style="background: #8000E1A6;">el endpoint no valida la extensión</mark>. Los ficheros se guardan en `wwwroot/SupplierCompaniesCertificatesOfIncorporations`.

## Abusar del comportamiento por defecto (ASP.NET Core)

La API es ASP.NET Core, donde **los ficheros estáticos de `wwwroot` son públicos por defecto**. Descargamos el `.exe` que acabamos de subir sin autenticación:

```shell-session
$ curl -O http://TARGET/SupplierCompaniesCertificatesOfIncorporations/reverse-shell.exe
```

Implicaciones: si enumeramos los nombres de fichero del directorio (y otros de `wwwroot`), accedemos a certificados/datos de otros suppliers. Y podemos usar la API como <mark style="background: #FFB86CA6;">almacenamiento en la nube para malware</mark> distribuido a víctimas — o social-engineerear a un admin para que ejecute el `.exe` (un reverse shell real de `msfvenom`) → [[06 - LFI + File Upload a RCE|RCE por upload]].

> [!warning]+ El vector "aburrido" que más cuesta dinero
> En bug bounty de APIs, la falta de rate-limiting en operaciones caras (subidas, generación de PDFs/reports, envío de emails/SMS, endpoints que llaman a IA/pago) es un hallazgo **muy rentable** hoy: en infra cloud con auto-scaling, un atacante puede disparar la factura (*denial-of-wallet*) sin tumbar nada. También aplica a la [[04 - Denegación de servicio (DoS) y Batching|amplificación por batching en GraphQL]].

# Prevención

- **Validar tamaño** (límite máximo), **extensión** y **contenido** de los ficheros (no fiarse de la extensión: comprobar *magic bytes*). Ver [[00 - Introducción a los File Upload Attacks|File Upload]].
- **Antivirus** (p. ej. `ClamAV`) escaneando el contenido antes de guardar.
- **Rate-limiting** y cuotas por usuario en toda operación costosa.
- **No servir** los uploads desde un directorio público; requerir autorización para descargarlos.

Siguiente: [[05 - Broken Function Level Authorization (API5)|BFLA]].

## Referencias

- OWASP — [API4:2023 Unrestricted Resource Consumption](https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/)
- MITRE — [CWE-400](https://cwe.mitre.org/data/definitions/400.html)
- HTB Academy — *API Attacks* (base, 2024)
