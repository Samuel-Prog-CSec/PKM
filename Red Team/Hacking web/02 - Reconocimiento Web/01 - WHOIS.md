---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "WHOIS es un protocolo de consulta/respuesta para acceder a las bases de datos que almacenan información sobre recursos de internet registrados —principalmente nombres de…"
Fecha de actualización: 2026-06-02
Nota previa: "[[00 - Reconocimiento web]]"
Nota siguiente: "[[02 - DNS - fundamentos]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
<mark style="background: #ADCCFFA6;">`WHOIS` es un protocolo de consulta/respuesta para acceder a las bases de datos que almacenan información sobre recursos de internet registrados</mark> —principalmente nombres de dominio, pero también bloques de direcciones IP y sistemas autónomos (`ASN`)—. Es, en esencia, la guía telefónica de internet: te dice quién registró un activo y qué infraestructura lo sostiene. Es la primera parada del recon pasivo porque <mark style="background: #FFB8EBA6;">no toca al objetivo</mark>: <mark style="background: #FF5582A6;">preguntas a la base de datos del registro, no al servidor de la víctima</mark>.

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

Los <mark style="background: #ADCCFFA6;">campos de mayor valor ofensivo</mark> no son los contactos —casi siempre redactados hoy—, sino los `Name Servers`, las fechas y el `Registrar`: revelan **infraestructura** y permiten **pivotar** hacia otros activos del mismo dueño.

# Por qué importa en recon

`WHOIS` aporta tres lecturas útiles durante una evaluación:

- **Infraestructura de red**: los `name servers` y las IPs asociadas dan pistas sobre <mark style="background: #FFB86CA6;">dónde se aloja el objetivo</mark>. Servidores DNS propios (`a.ns.facebook.com`) indican que la organización gestiona su propia infraestructura; servidores de un proveedor compartido apuntan a *hosting* gestionado.
- **Antigüedad y legitimidad**: una `Creation Date` lejana y una `Expiry Date` a años vista sugieren un dominio establecido. <mark style="background: #FFB86CA6;">Un dominio registrado hace tres días, con registrante oculto y `name servers` de un *bulletproof hoster*, es una señal inequívoca de infraestructura maliciosa</mark> (phishing, C2) — útil tanto en *threat intel* como para descartar señuelos.
- **Análisis histórico**: servicios como *WhoisFreaks*, *SecurityTrails* o *WhoisXMLAPI* <mark style="background: #FFB86CA6;">guardan registros `WHOIS` antiguos</mark>. Permiten ver cómo cambió la propiedad o los contactos **antes** de que se aplicara la redacción de privacidad.

# Cómo funciona el protocolo

`WHOIS` es un protocolo de texto plano que opera sobre `TCP/43`. El cliente abre una conexión al servidor `WHOIS`, envía el nombre del recurso (un dominio, una IP) terminado en `CRLF` y recibe la respuesta como texto libre. Esa simplicidad explica su mayor defecto: <mark style="background: #FFB8EBA6;">no hay un formato estandarizado de salida</mark>, así que <mark style="background: #ADCCFFA6;">cada registro y cada *registrar* devuelven los campos con etiquetas y orden distintos</mark> —razón por la que parsear `whois` a mano es frágil y `RDAP` (más abajo) lo reemplaza—.

La consulta además suele dar **dos saltos**, según el modelo del registro:

- **Thin WHOIS**: el *registry* del TLD (p. ej. Verisign para `.com`) solo guarda qué *registrar* gestiona el dominio y a qué servidor `WHOIS` preguntar. La salida incluye un `Registrar WHOIS Server`, y el cliente `whois` hace un segundo *referral* a ese servidor para obtener los datos completos. Es el caso de `.com` y `.net`.
- **Thick WHOIS**: el *registry* almacena **todos** los datos de registro y los devuelve en una sola consulta. Es el caso de `.org` y muchos TLD modernos.

<mark style="background: #8000E1A6;">El modelo *thin* implica que un mismo dominio puede dar respuestas distintas según a qué servidor preguntes</mark>: el del *registry* es más escueto que el del *registrar*. <mark style="background: #FF5582A6;">Si una consulta te devuelve poca información, fuerza el servidor</mark> del *registrar* con `whois -h <servidor> <dominio>`.

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
> Desde el `GDPR` (2018), <mark style="background: #FF5582A6;">ICANN obliga a redactar los datos personales del registrante en la mayoría de dominios</mark>. Hoy verás `REDACTED FOR PRIVACY` o el genérico de un servicio de privacidad (`Domains By Proxy`, `Whois Privacy`) en lugar del contacto real. La <mark style="background: #ADCCFFA6;">información de personas rara vez está disponible directamente</mark>; lo que sigue siendo fiable son `name servers`, fechas, `registrar`, `ASN` y el estado del dominio.

El sucesor técnico de `WHOIS` es <mark style="background: #ADCCFFA6;">`RDAP` (Registration Data Access Protocol): el mismo dato de registro servido en `JSON` estructurado y estandarizado</mark> (las consultas públicas son anónimas igual que en `whois`; la autenticación de `RDAP` es opcional, solo para acceso a datos no públicos). <mark style="background: #FF5582A6;">ICANN fijó el *sunset* de `WHOIS` (puerto 43) en los gTLD a partir de enero de 2025</mark>, así que en 2026 `RDAP` es la fuente primaria —no solo "lo cómodo para scripting"— y `whois` sobre algunos gTLD puede ya no responder. Donde `whois` devuelve texto libre que varía por registro, `RDAP` devuelve un objeto parseable. Al ser un protocolo [[01-APIs REST (principios y características)|REST]], la forma más directa de consultar recursos es <mark style="background: #FFB8EBA6;">mediante peticiones web</mark>. El servicio `rdap.org` funciona como un _bootstrap_, <mark style="background: #FFB86CA6;">redirigiendo tu petición automáticamente al servidor autoritativo correcto sin que tengas que adivinarlo</mark>.

Para *scripting* y recon automatizado, prefiere `RDAP`: no tienes que parsear formatos distintos por cada TLD.

**Consulta básica de un dominio**:
```bash
curl -s https://rdap.org/domain/facebook.com | jq .
```

**Consulta de una IP para extraer el bloque de red** (útil para expandir superficie):
```Bash
curl -s https://rdap.org/ip/157.240.0.1 | jq .
```

**Consulta directa de un Sistema Autónomo** (`ASN`):
```bash
curl -s https://rdap.org/autnum/32934 | jq .
```

## Alternativa: Cliente CLI nativo
Si se prefiere una <mark style="background: #ADCCFFA6;">vista en la terminal sin tener que parsear el JSON</mark> con `jq`, se puede instalar el cliente oficial de línea de comandos, que procesa el *JSON* y lo presenta de forma legible (similar al `whois` clásico).
```bash
sudo apt update && sudo apt install rdap -y
```

```
rdap facebook.com
```

## Cómo interpretar la salida JSON de RDAP (Mapeo WHOIS)
En `RDAP`, la información de alto valor para recon se encuentra distribuida en claves y _arrays_ específicos. Equivalencias de los campos clásicos de `WHOIS`:

### 1. Infraestructura de Red (`nameservers`)
Equivale a los `Name Servers`. Es un _array_ que <mark style="background: #ADCCFFA6;">contiene los servidores DNS autoritativos</mark>.

**Extracción de los nombres de dominio de los servidores DNS**:
```bash
curl -s https://rdap.org/domain/facebook.com | jq -r '.nameservers[].ldhName'
```

### 2. Fechas Clave (`events`)
Sustituye a `Creation Date` y `Expiry Date`. Contiene un _array_ de <mark style="background: #ADCCFFA6;">objetos indicando el registro, expiración y última modificación</mark>.

Extracción limpia de las **acciones y sus fechas**:
```bash
curl -s https://rdap.org/domain/facebook.com | jq -r '.events[] | "\(.eventAction): \(.eventDate)"'
```

### 3. Estados de Seguridad (`status`)
Equivale a `Domain Status`. Muestra los _flags_ o <mark style="background: #ADCCFFA6;">códigos EPP que protegen el dominio contra transferencias no autorizadas</mark> (`clientTransferProhibited`) o borrados.

**Extracción del estado**:
```bash
curl -s https://rdap.org/domain/facebook.com | jq -r '.status[]'
```

### 4. Entidades y Contactos (`entities`)
Reemplaza al `Registrar` y a los contactos. Aquí encontrarás <mark style="background: #ADCCFFA6;">quién gestiona el dominio</mark>. Aunque los <mark style="background: #FFB8EBA6;">datos de individuos suelen estar ocultos por GDPR</mark>, la <mark style="background: #FF5582A6;">empresa registradora siempre aparece</mark>. *RDAP* utiliza el estándar `jCard` (*vCard* en *JSON*) para los datos de contacto, lo que lo hace <mark style="background: #FFB86CA6;">un poco más verboso de parsear a mano</mark>.

Extracción de los **roles asignados a las entidades vinculadas al dominio**:
```bash
curl -s https://rdap.org/domain/facebook.com | jq -r '.entities[] | .roles[]'
```

# Pivotar: reverse WHOIS y WHOIS de IPs

<mark style="background: #ADCCFFA6;">Pivotar es el arte de usar un dato pequeño para descubrir activos desconocidos</mark> (_Shadow IT_). Es una de las vías principales para encontrar vulnerabilidades fuera del alcance habitual que otros investigadores pasan por alto.
## A) Reverse WHOIS (Aumentar el alcance de dominios)
- **Concepto:** Una consulta WHOIS/RDAP tradicional es **directa** (metes el dominio `ejemplo.com` y obtienes el dueño/datos). El **Reverse WHOIS** <mark style="background: #FFB86CA6;">invierte el proceso</mark>: <mark style="background: #FFB8EBA6;">metes un dato específico</mark> (correo, nombre de organización, teléfono o ID de registrador) y te devuelve **todos los dominios registrados con ese mismo dato**.

### Ejemplo práctico:
1. **Punto de partida:** Estás evaluando una empresa cuyo alcance es `*.empresa.com`.
2. **Obtención del pivote:** Consultas una base de datos histórica de WHOIS/RDAP y descubres que en 2017 (<mark style="background: #FF5582A6;">antes del GDPR</mark>) registraron un dominio usando el correo `dev-team@empresa-holding.net` o el nombre de organización `Empresa Corp LLC`.
3. **Pivote (Reverse WHOIS):** <mark style="background: #ADCCFFA6;">Consultas un servicio de Reverse WHOIS</mark> (como *SecurityTrails*, *Whoxy* o *WhoisXMLAPI*) buscando ese correo o nombre exacto.
4. **Resultado del pivote:** Descubres 4 <mark style="background: #FFB8EBA6;">dominios adicionales que pertenecen a la misma organización</mark> pero que no conocías:
    - `empresa-stage.io`
    - `empresa-api-dev.com`
    - `portal-empleados-antiguo.net`
5. **Impacto en Bug Bounty:** Has <mark style="background: #ADCCFFA6;">ampliado la superficie de ataque hacia dominios secundarios que suelen tener menos controles de seguridad</mark> o software desactualizado.

### ¿Siempre hay que hacer Reverse WHOIS?
**Definitivamente no.** El _Reverse WHOIS_ (buscar qué otros dominios comparten el mismo correo, teléfono o nombre de registrador) fue la técnica reina del OSINT en su momento, <mark style="background: #FF5582A6;">pero hoy tiene limitaciones claras</mark>.

#### Cuándo SÍ aporta valor:
- **Atribución de actores de amenazas:** Si analizas infraestructura antigua de un ciberdelincuente que cometió el error de<mark style="background: #ADCCFFA6;"> reutilizar un correo, teléfono o alias de registro en varios dominios</mark>.
- **Investigación pre-2018:** Si <mark style="background: #ADCCFFA6;">rastreas dominios que fueron registrados antes de la entrada en vigor del GDPR</mark> y conservas snapshots de esa época.
- **Pivote por datos poco comunes:** A veces el pivote no es por correo, sino por <mark style="background: #ADCCFFA6;">campos menos obvios como servidores de nombre (_Name Servers_) muy específicos o registradores de nicho</mark>.

#### Cuándo NO vale la pena (o es inútil):
- **El muro del GDPR y Privacy Guards:** Desde 2018, la inmensa mayoría de los registros tienen los datos de contacto redactados o enmascarados detrás de servicios como _Withheld for Privacy_ o _Domains By Proxy_. Hacer un Reverse WHOIS del correo `select-privacy@proxy.com` te <mark style="background: #FFB8EBA6;">devolverá medio millón de dominios que no tienen relación alguna entre sí</mark>.
- **Sistemas modernos de infraestructura dinámicos:** Si buscas infraestructura activa y relacionada, hoy en día hay alternativas **mucho más limpias y efectivas**.

### Alternativas modernas al Reverse WHOIS
Si tu objetivo es mapear infraestructura relacionada o descubrir activos pertenecientes a un mismo objetivo, estas <mark style="background: #FFB86CA6;">técnicas suelen superar al WHOIS moderno</mark>:
1. **Certificate Transparency (CT) Logs:** <mark style="background: #ADCCFFA6;">Buscar certificados *SSL*/*TLS* emitidos para un dominio o organización</mark> (vía _crt.sh_ o _Censys_). <mark style="background: #FFB8EBA6;">Revela subdominios y dominios agrupados en el mismo certificado</mark> **San** (*Subject Alternative Name*).
2. **Passive DNS:** Mapear <mark style="background: #FFB8EBA6;">qué dominios han resuelto históricamente a las mismas direcciones IP</mark>.
3. **Favicon / JARM Fingerprinting:** Agrupar servidores o aplicaciones web que comparten el <mark style="background: #FFB8EBA6;">mismo hash de icono</mark> (_favicon_) o la <mark style="background: #FFB8EBA6;">misma huella TLS</mark> (_JARM_).

## B) WHOIS de IPs y ASN (Identificar rangos de red propios)
- **Concepto:** Los dominios son solo nombres legibles; la infraestructura real se ejecuta sobre direcciones IP. El **WHOIS de IP / ASN** <mark style="background: #ADCCFFA6;">sirve para averiguar qué bloque numérico de red (CIDR) y qué Número de Sistema Autónomo (`ASN`) pertenecen a la organización objetivo</mark>.

### Ejemplo práctico:
1. **Punto de partida:** Tienes el dominio principal `objetivo.com`.
2. **Resolución DNS:** Resuelves `objetivo.com` a su dirección *IP* actual: `198.51.100.45`.
3. **Pivote (IP WHOIS / RDAP):** Le ejecutas un *RDAP* a la *IP*:
    ```bash
    curl -s https://rdap.org/ip/198.51.100.45 | jq -r '.name, .cidr0_cidrs'
    ```
4. **Resultado del pivote:** La respuesta no solo te habla de esa *IP*, sino del <mark style="background: #FFB86CA6;">bloque completo asignado por el registro regional</mark> (*ARIN*/*RIPE*):
    - **Nombre del bloque (`netname`):** `OBJETIVO-NET-INTERNAL`
    - **Rango CIDR:** `198.51.100.0/24` (<mark style="background: #FFB8EBA6;">256 direcciones IP</mark>)
    - **ASN asignado:** `AS65535`
5. **Impacto en Bug Bounty:** En lugar de probar un solo servidor web (`198.51.100.45`), <mark style="background: #FF5582A6;">ahora sabes que la empresa posee todas las direcciones del rango</mark> `198.51.100.0/24`. Puedes pasar a realizar <mark style="background: #FFB86CA6;">descubrimientos de puertos y servicios en todo el segmento de red</mark> para encontrar paneles de administración expuestos, bases de datos o servicios no documentados.

El dato de registro fija **quién** y **dónde** vive el objetivo. El siguiente paso es resolver **cómo** se traduce ese dominio en servicios concretos: el sistema `DNS`, que abrimos en [[02 - DNS - fundamentos]].
