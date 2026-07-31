---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "Localizar la IP del servidor de origen detrás de un CDN o WAF y contar los backends de un balanceador para atacar la infraestructura real"
Fecha de actualización: 2026-07-31
Nota previa: "[[27 - Evasión en recon y fuzzing]]"
Nota siguiente:
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

La nota anterior trata cómo pasar **a través** del WAF. Esta trata cómo hacerlo irrelevante. <mark style="background: #ADCCFFA6;">Un CDN o WAF en la nube (Cloudflare, Akamai, AWS WAF) no es un dispositivo delante del servidor: es un cambio de DNS que hace que el tráfico pase por su red antes de llegar al origen</mark>. El servidor real sigue existiendo, sigue teniendo una IP pública y, muy a menudo, sigue aceptando conexiones directas de cualquiera.

Si encuentras esa IP y responde, te saltas de una vez el filtrado de payloads, el *rate limiting*, el bloqueo geográfico y el registro del WAF. No hay payload que evadir porque no hay WAF en el camino.

# Por qué el origen queda expuesto

La causa es de proceso, no de producto. <mark style="background: #FFB8EBA6;">Para poner un sitio detrás de un CDN basta apuntar el DNS; blindar el origen es un paso **aparte** que se olvida</mark>. Tres momentos típicos lo dejan al descubierto:

- El dominio resolvía directamente a la IP del servidor **antes** de contratar el CDN, y ese histórico es público.
- La migración no cambió la IP del origen, así que la IP antigua sigue siendo la buena.
- El firewall del origen nunca se restringió a los rangos del CDN, porque "ya estamos protegidos".

# Vías para localizar el origen

## Histórico DNS

La más directa. Servicios como [SecurityTrails](https://securitytrails.com), ViewDNS o Censys guardan todos los registros `A` a los que ha resuelto un dominio. <mark style="background: #FF5582A6;">La IP anterior a la fecha de alta en el CDN suele ser el origen, y sigue viva</mark> porque nadie la decomisionó.

```shell-session
$ curl -s "https://api.securitytrails.com/v1/history/target.com/dns/a" -H "APIKEY: $ST_KEY" | jq
```

## Certificados TLS

El origen presenta su propio certificado a quien conecte por IP. Cruzando los *Certificate Transparency logs* ([[07 - Certificate Transparency logs|CT logs]]) con datos de escaneo de Internet se localizan hosts que sirven ese mismo certificado fuera del CDN:

```shell-session
$ censys search 'services.tls.certificates.leaf_data.subject_dn: "CN=target.com"'
$ cloudflair --censys-api-id <id> --censys-api-secret <secret> target.com
```

## Hash del favicon

Un truco barato y muy eficaz: Shodan indexa el `MurmurHash3` del favicon en base64. <mark style="background: #8000E1A6;">Si el origen sirve el mismo favicon que el sitio público, buscarlo por hash lo saca sin tocar el objetivo</mark>.

```shell-session
$ shodan search 'http.favicon.hash:-1234567890'
```

## Registros y subdominios que no pasan por el CDN

Casi nunca se pone todo detrás del CDN. Lo que suele quedar fuera:

- **`MX` y `SPF`**: el correo rara vez pasa por el CDN, y con frecuencia sale del mismo rango —o del mismo host— que la web.
- **Subdominios olvidados**: `dev`, `staging`, `test`, `cpanel`, `vpn`, `mail`, `old`. La enumeración de [[05 - Enumeración de subdominios|subdominios]] es aquí un multiplicador: basta uno sin proteger para revelar el rango.

## Filtración desde el propio servidor

Cualquier función que haga que el servidor **inicie** una conexión saliente delata su IP: *webhooks*, importadores de URL, renderizadores de PDF, verificadores de enlaces y, sobre todo, un [[01 - Introducción a SSRF|SSRF]]. Apunta la funcionalidad a un *collaborator* propio y la IP que aparece en el callback es la del origen, no la del CDN.

# Confirmar el candidato

Una IP candidata no vale nada hasta que se verifica que sirve el sitio. Se fuerza la cabecera `Host` para que el servidor entregue el *virtual host* correcto:

```shell-session
$ curl -sk -H "Host: target.com" https://<IP-CANDIDATA>/ | md5sum
$ curl -sk -H "Host: target.com" https://<IP-CANDIDATA>/ -o /dev/null -w "%{http_code}\n"
```

Si el cuerpo coincide con el del sitio público, es el origen.

> [!warning]+ Falsos negativos al verificar
> <mark style="background: #FF5582A6;">Un origen bien configurado puede devolver una página de *challenge*, un `403` o un `redirect` al dominio en vez del contenido</mark>, y eso hace descartar por error una IP que sí era la buena. Antes de tirarla, prueba por HTTP y HTTPS, con y sin SNI (`--resolve target.com:443:<IP>`), y compara tamaños de respuesta en vez de exigir igualdad exacta.

# Balanceadores: cuántos servidores hay realmente

Un problema hermano: detrás de una sola IP puede haber **N backends**. Importa más de lo que parece — <mark style="background: #FFB86CA6;">si un backend está parcheado y otro no, tu exploit funcionará de forma intermitente y lo descartarás como falso positivo</mark>, y una sesión puede "perderse" simplemente porque la siguiente petición cayó en otro servidor.

Señales que delatan varios backends, todas por observación pasiva de las respuestas:

| Señal | Qué mirar |
| - | - |
| Deriva del reloj | La cabecera `Date` retrocede entre peticiones consecutivas |
| Cabeceras inconsistentes | `Server`, `X-Powered-By` o el orden de las cabeceras cambian |
| `ETag` / `Last-Modified` | Valores distintos para el mismo recurso estático |
| Cookies de afinidad | `AWSALB`, `BIGipServer...`, `JSESSIONID` con sufijo de nodo |

> [!info]+ Las herramientas clásicas están muertas
> `lbd` y `halberd` aparecen en muchos apuntes, pero `halberd` requiere Python 2 y `lbd` no se mantiene. Hoy el trabajo se hace con peticiones repetidas y `curl -sD -`, o con `httpx -probe -td` para comparar la huella de las respuestas. La detección de balanceo es análisis de cabeceras, no una herramienta.

# Impacto, defensa y alcance

Encontrar el origen accesible **es un hallazgo reportable por sí mismo**, no solo un medio: anula la inversión completa del cliente en su WAF. La mitigación tiene dos partes, y solo la primera se suele aplicar:

1. **Firewall del origen** restringido a los rangos publicados del CDN (Cloudflare y Akamai los publican).
2. **Autenticación de origen**: *Authenticated Origin Pulls* en Cloudflare o equivalente, para que el origen solo acepte conexiones con el certificado de cliente del CDN. Sin esto, cualquiera que descubra los rangos del CDN —que son públicos— sigue pudiendo llegar.

Además, tras blindar el origen hay que **rotar su IP**: si la antigua está en el histórico DNS, el firewall nuevo protege una dirección que ya nadie necesita.

> [!warning]+ Verifica el alcance antes de tocar la IP
> <mark style="background: #FF5582A6;">La IP del origen puede pertenecer a un *hosting* compartido o a un tercero</mark>, y atacarla directamente te saca del alcance autorizado — con las consecuencias legales del caso. Comprueba el `whois` y el ASN del candidato y contrástalo con el alcance del engagement o del programa **antes** de lanzar nada contra él.

En OPSEC, ir al origen es un arma de doble filo: esquiva el registro del WAF, pero <mark style="background: #FFB8EBA6;">el propio servidor registra peticiones desde una IP externa con una cabecera `Host` que no cuadra con su tráfico normal</mark> —que siempre llega del CDN—. En un cliente con detección madura, eso es una anomalía trivial de alertar.

> [!info]+ Fuentes
> - [Uncovering CloudFlare — HackTricks](https://hacktricks.wiki/en/network-services-pentesting/pentesting-web/uncovering-cloudflare.html)
> - [Identifying a server's origin IP — Intigriti](https://www.intigriti.com/researchers/blog/hacking-tools/identifying-servers-origin-ip)
> - [CloudFlair](https://github.com/christophetd/CloudFlair) (pivote por certificado vía Censys) · [bypass-firewalls-by-DNS-history](https://github.com/vincentcox/bypass-firewalls-by-DNS-history) (histórico DNS)

Con la superficie mapeada, escaneada, la evasión planificada y la infraestructura real identificada, termina la fase de descubrimiento. El siguiente paso del path es **explotar** lo encontrado —[[00 - Introducción a SQL Injection|inyección]], [[00 - Introducción a XSS|XSS]], [[00 - Introducción a Command Injection|command injection]], autenticación y lógica— sobre el mapa de endpoints y parámetros que estas notas han construido.
