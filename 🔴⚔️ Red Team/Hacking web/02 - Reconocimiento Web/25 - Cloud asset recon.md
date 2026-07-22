---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-13
Nota previa: "[[24 - Fuzzing de APIs]]"
Nota siguiente: "[[26 - Escaneo dirigido con nuclei]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El recon de DNS, subdominios y `vhosts` mapea lo que la organización publica por nombre, pero <mark style="background: #ADCCFFA6;">deja fuera buena parte de la superficie moderna: los activos alojados en la nube</mark> —buckets de almacenamiento, blobs, funciones serverless, registries—. Estos recursos rara vez cuelgan de un subdominio bonito; viven en el espacio de nombres del proveedor (`s3.amazonaws.com`, `blob.core.windows.net`) y son <mark style="background: #FFB86CA6;">una de las fuentes de fugas de datos más frecuentes en bug bounty</mark>. HTB no cubre este recon; en un programa real es de primera línea.

# Almacenamiento de objetos: el objetivo principal

El *object storage* mal configurado es el clásico. Cada proveedor tiene su esquema de URL y su modelo de permisos:

| Proveedor | Formato de URL | Servicio |
| - | - | - |
| AWS | `https://<bucket>.s3.amazonaws.com` · `s3://<bucket>` | S3 |
| Google Cloud | `https://storage.googleapis.com/<bucket>` | GCS |
| Azure | `https://<cuenta>.blob.core.windows.net/<contenedor>` | Blob Storage |

<mark style="background: #FFB8EBA6;">El nombre del bucket suele ser predecible</mark>: `nombre-empresa`, `empresa-backups`, `empresa-dev`, `assets-empresa`, `empresa-prod-logs`. Esa previsibilidad es justo lo que explota la enumeración.

## Descubrir buckets

- **Permutación de nombres** sobre el nombre de la org y sus productos: la herramienta de referencia es <mark style="background: #ADCCFFA6;">`cloud_enum`</mark> (multi-proveedor: AWS/Azure/GCP) y `S3Scanner` para S3/GCS. Generan variantes (`-dev`, `-staging`, `-backup`) y comprueban existencia y permisos.
- **Buscadores de buckets públicos**: `grayhatwarfare` indexa buckets abiertos y sus ficheros — una consulta por palabra clave de la org puede dar un *hit* directo sin escanear nada.
- **Extracción de fuentes ya recopiladas**: rastrea referencias a `s3.amazonaws.com`/`blob.core.windows.net` en el [[10 - Crawling web|HTML/JS crawleado]], en las [[13 - Web Archives|URLs históricas]] y en [[12 - Search Engine Discovery|GitHub/dorking]] — las apps filtran las URLs de sus propios buckets constantemente.

```shell-session
$ python3 cloud_enum.py -k nombre-empresa -k empresa --disable-azure
$ s3scanner scan --bucket nombre-empresa-backups
```

## Qué probar y qué impacto tiene

Confirmado un bucket, lo que cuenta es el **permiso**:

- <mark style="background: #FF5582A6;">**Listado** público (`READ` sobre el bucket)</mark> → enumeras todos los objetos: backups, dumps, `.env`, credenciales.
- **Lectura** de objetos → descargas el contenido aunque no puedas listar (si conoces nombres).
- <mark style="background: #FFB86CA6;">**Escritura** pública (`WRITE`)</mark> → el hallazgo más crítico: si el bucket sirve contenido del sitio (JS, imágenes), subir un fichero malicioso puede derivar en **XSS almacenado o RCE** sobre los usuarios de la web. Súbelo solo si el programa lo permite y con un PoC inocuo.

# Recon por organización: ASN, Shodan y Censys

Más allá de los buckets, conviene mapear toda la huella cloud de la org:

- **ASN → rangos IP**: identifica el `Autonomous System` de la organización (`asnmap` de ProjectDiscovery, `bgp.he.net`) y resuelve sus rangos para escanearlos con [[09 - Fingerprinting web|httpx]]/`naabu`.

  > [!warning]+ El ASN engaña en entornos cloud
  > <mark style="background: #FFB8EBA6;">Si el objetivo está en AWS/GCP/Azure, las IPs pertenecen al **proveedor**, no a la org</mark>, así que el ASN apunta a Amazon, no a tu objetivo, y escanear ese rango es inútil (y fuera de scope). El ASN solo rinde cuando la empresa tiene rango propio (banca, telcos, on-premise). En cloud puro, pivota a Shodan/Censys por certificado y favicon.

- **Shodan / Censys / FOFA** por organización: filtra por `org`, por `ssl.cert.subject.CN`, o por el [[09 - Fingerprinting web|hash del favicon]] para encontrar paneles, servicios expuestos y hosts cloud que no aparecen en DNS. Es el equivalente "por contenido" del recon por nombre.
- **Otros activos**: funciones (Lambda/Cloud Functions) tras un API Gateway, contenedores y `registries` expuestos, snapshots públicos. Suelen aflorar al fingerprintear los rangos o en las respuestas de la propia app.

> [!important]+ Scope antes que nada
> Los activos cloud tienen reglas de *scope* propias y a veces ambiguas: un bucket puede pertenecer a un tercero (CDN, proveedor SaaS) y quedar fuera del programa. <mark style="background: #8000E1A6;">Verifica la titularidad antes de tocar nada</mark> y respeta la política del proveedor (AWS exige autorización para ciertos tests). Demuestra el impacto con lo mínimo —listar un objeto, leer un fichero no sensible— y nunca exfiltres datos reales de clientes.

> [!info]+ Fuentes y herramientas
> - [cloud_enum](https://github.com/initstring/cloud_enum) · [S3Scanner](https://github.com/sa7mon/S3Scanner) · [grayhatwarfare](https://buckets.grayhatwarfare.com/)
> - [asnmap](https://github.com/projectdiscovery/asnmap) (ProjectDiscovery) · [Shodan](https://www.shodan.io/) · [Censys](https://search.censys.io/)
> - [HackTricks Cloud](https://cloud.hacktricks.xyz/) — metodología por proveedor.

Con la superficie completa mapeada —DNS, subdominios, vhosts, APIs y ahora activos cloud—, el paso natural es **escanearla** en busca de vulnerabilidades conocidas de forma dirigida: [[26 - Escaneo dirigido con nuclei]].
