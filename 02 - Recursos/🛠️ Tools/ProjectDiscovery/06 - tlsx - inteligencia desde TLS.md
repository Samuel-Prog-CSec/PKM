---
tags:
  - Pentesting/Enumeracion
  - Recon
  - Criptografia
Descripción: "Los certificados regalan nombres internos, dominios hermanos y misconfiguraciones — y un CIDR entero se convierte en lista de hostnames"
Fecha de actualización: 2026-08-04
Nota previa: "[[05 - httpx - sondeo y fingerprinting HTTP a escala]]"
Nota siguiente: "[[07 - uncover - recon pasivo vía motores de búsqueda]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

<mark style="background: #ADCCFFA6;">`tlsx` hace el handshake TLS y extrae todo lo que el servidor cuenta por el camino</mark>: certificado, nombres, versión negociada, cifrado, huellas. Acepta ASN, CIDR, IP, dominio o URL como entrada.

Su mejor uso no es auditar TLS —aunque también sirve— sino **descubrir superficie**: los certificados son la fuente de nombres de host más fiable que existe, porque un servidor tiene que presentarlos para funcionar.

# El truco central: de un CIDR a una lista de nombres

```shell-session
$ echo 173.0.84.0/24 | tlsx -san -cn -silent -resp-only
$ echo 173.0.84.0/24 | tlsx -san -cn -silent -resp-only | dnsx -silent | httpx -silent
```

Esa cadena de tres herramientas es una de las cosas más rentables de todo el recon. Lo que hace:

1. `tlsx` se conecta al 443 de las 256 direcciones del rango.
2. De cada certificado saca el **Common Name** y los **Subject Alternative Names**.
3. `dnsx` comprueba cuáles resuelven de verdad.
4. `httpx` mira qué hay en cada uno.

<mark style="background: #8000E1A6;">Aparecen nombres que ninguna fuente pasiva conocía</mark>: entornos internos, hosts de administración, dominios de otras marcas del mismo grupo y sistemas de preproducción. El certificado tiene que listarlos para que el navegador no proteste, así que no se pueden esconder.

`-dns` extrae directamente los hostnames únicos de los certificados, y `-sa/-scan-all-ips` prueba todas las IPs a las que resuelve un nombre, que es lo que hace falta con balanceadores.

# Detección de misconfiguraciones

```shell-session
$ tlsx -l hosts.txt -expired -self-signed -mismatched -revoked -untrusted -silent
```

| Flag | Hallazgo |
| --- | --- |
| `-expired` | Certificado caducado |
| `-self-signed` | Autofirmado |
| `-mismatched` | El nombre no corresponde con el host |
| `-revoked` | Revocado |
| `-untrusted` | Cadena no verificable |
| `-wc`, `-wildcard-cert` | Certificado comodín |

Cada uno es reportable por sí mismo, pero <mark style="background: #FFB86CA6;">lo más útil es lo que **implican**</mark>. Un certificado autofirmado o con nombre desparejado en un host público suele señalar un servicio interno expuesto por accidente — el equipo que lo montó no esperaba que se llegara desde fuera. Un comodín (`*.objetivo.com`) filtrado significa que **cualquier host que lo tenga puede suplantar a todos los demás** del dominio.

# Huellas: JARM y JA3

```shell-session
$ echo objetivo.com | tlsx -jarm -silent
$ echo objetivo.com | tlsx -ja3 -silent
$ subfinder -d objetivo.com -silent | tlsx -tls-version -cipher -silent
```

- **JARM** identifica al **servidor** por cómo responde a una batería de *Client Hello* distintos. Dos hosts con el mismo JARM comparten pila y configuración TLS: <mark style="background: #8000E1A6;">es la forma de descubrir que veinte IPs distintas son en realidad el mismo balanceador, o que un host tras CDN y una IP "suelta" son la misma máquina</mark>. Fuera del recon, es la técnica estándar para cazar servidores C2.
- **JA3** es la huella del **cliente**. Aquí sirve sobre todo para entender qué te identifica a ti — ver [[09 - Evasión, rate-limiting y detección de la suite]].

# Modos de conexión

`-sm/-scan-mode` elige la librería TLS:

| Modo | Librería | Cuándo |
| --- | --- | --- |
| `auto` (por defecto) | Prueba y cae hacia atrás | Uso normal |
| `ctls` | `crypto/tls` de Go | Objetivos modernos |
| `ztls` | `zcrypto/tls` | <mark style="background: #FFB8EBA6;">Servidores viejos con TLS 1.0/1.1 y cifrados obsoletos</mark> |
| `openssl` | OpenSSL del sistema | Máxima compatibilidad |

Esto importa más de lo que parece: la librería estándar de Go **rechaza** conexiones a servidores con configuraciones muy antiguas, así que un `tlsx` en modo `ctls` puede reportar "no responde" un host que sí está vivo y que es precisamente el más vulnerable. En infraestructura legacy, `-sm openssl` o `-sm ztls`.

`-ps/-pre-handshake` (solo `ztls`) corta tras el `ServerHello`: más rápido y menos intrusivo, porque no completa el handshake.

# Rendimiento

| Flag | Por defecto |
| --- | --- |
| `-c`, `-concurrency` | **300** |
| `-timeout` | segundos |
| `-retry` | reintentos |
| `-delay` | retardo por hilo |
| `-p`, `-port` | **443** |

> [!warning]+ 300 hilos por defecto es mucho
> Es un valor pensado para barrer rangos deprisa. Contra un objetivo pequeño, 300 conexiones TLS simultáneas es indistinguible de un ataque de agotamiento de recursos — <mark style="background: #FF5582A6;">el handshake TLS es caro para el servidor, mucho más que para ti</mark>. Baja `-c` y usa `-delay` en objetivos que no sean rangos grandes.

## No solo el 443

```shell-session
$ tlsx -l hosts.txt -p 443,8443,993,995,465,3389,5986 -silent -san -cn
```

Los servicios con TLS que no son web son donde salen los hallazgos que nadie más mira: **IMAPS/POP3S** (993/995), **SMTPS** (465), **RDP** (3389), **WinRM sobre HTTPS** (5986). Sus certificados suelen llevar el **nombre real de la máquina y el dominio interno** — material directo para la fase de Active Directory ([[02 - Enumeración inicial del dominio]]).

# Salida

```shell-session
$ echo objetivo.com | tlsx -json -silent | jq .
$ tlsx -l hosts.txt -san -cn -so -serial -hash sha256 -tc -json -o tls.jsonl
```

`-tc/-tls-chain` guarda la cadena completa y `-cert/-certificate` incluye el PEM en el JSON — evidencia verificable para el informe, con emisor, validez y huellas.

> [!success]+ El bucle de realimentación completo
> ```shell-session
> $ asnmap -org "ACME Corp" -silent \
>   | tlsx -san -cn -silent -resp-only -p 443,8443 \
>   | anew nombres.txt \
>   | dnsx -silent -a -resp-only -auto-wildcard \
>   | httpx -silent -sc -title -td -json -o superficie.json
> ```
> Del nombre de la organización a un inventario web, pasando por los certificados. `anew` acumula solo lo nuevo, así que repetir el bucle hace crecer la superficie sin duplicar trabajo.

> [!info]+ Fuente
> [README de tlsx](https://github.com/projectdiscovery/tlsx) — modos de conexión (`auto`/`ctls`/`ztls`/`openssl`), sondas de certificado y de misconfiguración, JARM/JA3, `-c 300` por defecto, `-pre-handshake` y los ejemplos de encadenado. Fundamentos del protocolo en [[HTTPs-TLS.base|HTTPS y TLS]].
