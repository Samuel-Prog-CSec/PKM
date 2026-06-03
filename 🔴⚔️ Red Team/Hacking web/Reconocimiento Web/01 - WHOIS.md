---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[00 - Reconocimiento web]]"
Nota siguiente: "[[02 - DNS - fundamentos]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">`WHOIS` es un protocolo de consulta/respuesta para acceder a las bases de datos que almacenan información sobre recursos de internet registrados</mark> —principalmente nombres de dominio, pero también bloques de direcciones IP y sistemas autónomos (`ASN`)—. Es, en esencia, la guía telefónica de internet: te dice quién registró un activo y qué infraestructura lo sostiene. Es la primera parada del recon pasivo porque <mark style="background: #FFB8EBA6;">no toca al objetivo</mark>: preguntas a la base de datos del registro, no al servidor de la víctima.

# Qué contiene un registro WHOIS

| Campo | Significado |
| - | - |
| `Domain Name` | El propio dominio (p. ej. `example.com`) |
| `Registrar` | Empresa donde se registró el dominio (GoDaddy, Namecheap, Amazon…) |
| `Registrant Contact` | Persona u organización que registró el dominio |
| `Administrative Contact` | Responsable de la gestión del dominio |
| `Technical Contact` | Responsable de incidencias técnicas |
| `Creation / Expiry Date` | Fechas de alta y caducidad del registro |
| `Name Servers` | Servidores DNS autoritativos que resuelven el dominio |

Los campos de mayor valor ofensivo no son los contactos —casi siempre redactados hoy—, sino los `Name Servers`, las fechas y el `Registrar`: revelan **infraestructura** y permiten **pivotar** hacia otros activos del mismo dueño.

# Por qué importa en recon

`WHOIS` aporta tres lecturas útiles durante una evaluación:

- **Infraestructura de red**: los `name servers` y las IPs asociadas dan pistas sobre dónde se aloja el objetivo. Servidores DNS propios (`a.ns.facebook.com`) indican que la organización gestiona su propia infraestructura; servidores de un proveedor compartido apuntan a *hosting* gestionado.
- **Antigüedad y legitimidad**: una `Creation Date` lejana y una `Expiry Date` a años vista sugieren un dominio establecido. <mark style="background: #FFB86CA6;">Un dominio registrado hace tres días, con registrante oculto y `name servers` de un *bulletproof hoster*, es una señal inequívoca de infraestructura maliciosa</mark> (phishing, C2) — útil tanto en *threat intel* como para descartar señuelos.
- **Análisis histórico**: servicios como WhoisFreaks, SecurityTrails o WhoisXMLAPI guardan registros `WHOIS` antiguos. Permiten ver cómo cambió la propiedad o los contactos **antes** de que se aplicara la redacción de privacidad.

# Cómo funciona el protocolo

`WHOIS` es un protocolo de texto plano que opera sobre `TCP/43`. El cliente abre una conexión al servidor `WHOIS`, envía el nombre del recurso (un dominio, una IP) terminado en `CRLF` y recibe la respuesta como texto libre. Esa simplicidad explica su mayor defecto: <mark style="background: #FFB8EBA6;">no hay un formato estandarizado de salida</mark>, así que cada registro y cada *registrar* devuelven los campos con etiquetas y orden distintos —razón por la que parsear `whois` a mano es frágil y `RDAP` (más abajo) lo reemplaza—.

La consulta además suele dar **dos saltos**, según el modelo del registro:

- **Thin WHOIS**: el *registry* del TLD (p. ej. Verisign para `.com`) solo guarda qué *registrar* gestiona el dominio y a qué servidor `WHOIS` preguntar. La salida incluye un `Registrar WHOIS Server`, y el cliente `whois` hace un segundo *referral* a ese servidor para obtener los datos completos. Es el caso de `.com` y `.net`.
- **Thick WHOIS**: el *registry* almacena **todos** los datos de registro y los devuelve en una sola consulta. Es el caso de `.org` y muchos TLD modernos.

<mark style="background: #8000E1A6;">El modelo *thin* implica que un mismo dominio puede dar respuestas distintas según a qué servidor preguntes</mark>: el del *registry* es más escueto que el del *registrar*. Si una consulta te devuelve poca información, fuerza el servidor del *registrar* con `whois -h <servidor> <dominio>`.

# `whois` en la práctica

La forma más directa de consultar es la utilidad de línea de comandos `whois`, disponible en los gestores de paquetes de Linux:

```shell-session
$ sudo apt update && sudo apt install whois -y
```

Una consulta sobre un dominio devuelve el registro completo:

```shell-session
$ whois facebook.com

   Domain Name: FACEBOOK.COM
   Registrar WHOIS Server: whois.registrarsafe.com
   Updated Date: 2024-04-24T19:06:12Z
   Creation Date: 1997-03-29T05:00:00Z
   Registry Expiry Date: 2033-03-30T04:00:00Z
   Registrar: RegistrarSafe, LLC
   Domain Status: clientTransferProhibited serverDeleteProhibited [...]
   Name Server: A.NS.FACEBOOK.COM
   Name Server: B.NS.FACEBOOK.COM
   DNSSEC: unsigned
   Registrant Organization: Meta Platforms, Inc.
   Registrant Name: Domain Admin
```

Cómo leer esta salida:

- **Registro**: `RegistrarSafe, LLC`, alta en 1997, caducidad en 2033 → dominio veterano y legítimo.
- **Propietario**: `Meta Platforms, Inc.` como organización y `Domain Admin` como contacto. Coherente con un activo corporativo grande.
- **`Domain Status`**: los flags `clientTransferProhibited`, `serverDeleteProhibited`, etc. son candados `EPP` que <mark style="background: #FFB8EBA6;">protegen el dominio frente a transferencias, borrados o cambios no autorizados</mark> — práctica estándar en organizaciones que cuidan su superficie.
- **`Name Servers`**: todos bajo `facebook.com`, lo que confirma que Meta gestiona su propio DNS.

> [!info]+ `Domain Status` (códigos EPP)
> Los estados que empiezan por `client*` los fija el *registrar*; los `server*` los fija el *registry*. Un dominio sin `clientTransferProhibited` es más susceptible a *domain hijacking* por transferencia no autorizada — dato relevante si evalúas la postura de seguridad de la organización, no solo su app web.

# El gran matiz moderno: GDPR y RDAP

HTB presenta `WHOIS` como vía para identificar personal clave (nombres, correos, teléfonos). <mark style="background: #FF5582A6;">Eso es en gran medida historia</mark>:

> [!warning]+ La redacción de datos rompió el WHOIS clásico
> Desde el `GDPR` (2018), ICANN obliga a redactar los datos personales del registrante en la mayoría de dominios. Hoy verás `REDACTED FOR PRIVACY` o el genérico de un servicio de privacidad (`Domains By Proxy`, `Whois Privacy`) en lugar del contacto real. La información de **personas** rara vez está disponible directamente; lo que sigue siendo fiable son `name servers`, fechas, `registrar`, `ASN` y el estado del dominio.

El sucesor técnico de `WHOIS` es <mark style="background: #ADCCFFA6;">`RDAP` (Registration Data Access Protocol): el mismo dato de registro servido en `JSON` estructurado y estandarizado</mark> (las consultas públicas son anónimas igual que en `whois`; la autenticación de `RDAP` es opcional, solo para acceso a datos no públicos). <mark style="background: #FF5582A6;">ICANN fijó el *sunset* de `WHOIS` (puerto 43) en los gTLD a partir de enero de 2025</mark>, así que en 2026 `RDAP` es la fuente primaria —no solo "lo cómodo para scripting"— y `whois` sobre algunos gTLD puede ya no responder. Donde `whois` devuelve texto libre que varía por registro, `RDAP` devuelve un objeto parseable:

```shell-session
$ curl -s https://rdap.org/domain/facebook.com | jq '.events, .nameservers[].ldhName'
```

Para *scripting* y recon automatizado, prefiere `RDAP`: no tienes que parsear formatos distintos por cada TLD.

# Pivotar: reverse WHOIS y WHOIS de IPs

Dos técnicas que convierten `WHOIS` de dato suelto en motor de expansión de superficie:

- **Reverse WHOIS**: buscar todos los dominios registrados por el mismo correo, organización o registrante. Plataformas como WhoisXMLAPI o SecurityTrails permiten consultar "qué más posee este dueño" y <mark style="background: #8000E1A6;">expandir el alcance desde un dominio a toda la cartera de la empresa</mark> —origen frecuente de activos olvidados en bug bounty—.
- **WHOIS de IPs y ASN**: consultar una IP en los registros regionales (`ARIN`, `RIPE`, `APNIC`) devuelve el bloque de red y el `ASN` que lo posee. Desde el `ASN` obtienes **todos** los rangos IP de la organización, candidatos a escaneo posterior.

```shell-session
$ whois 157.240.0.1 | grep -iE 'netname|origin|orgname'
```

El dato de registro fija **quién** y **dónde** vive el objetivo. El siguiente paso es resolver **cómo** se traduce ese dominio en servicios concretos: el sistema `DNS`, que abrimos en [[02 - DNS - fundamentos]].
