---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
Fecha de actualización: 2026-06-23
Nota previa: "[[03 - Ataque al secreto de firma JWT]]"
Nota siguiente: "[[05 - Más ataques JWT - jku, kid y x5c]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

El ataque JWT más elegante y de mayor impacto. <mark style="background: #ADCCFFA6;">La `algorithm confusion` fuerza a la app a verificar la firma con un algoritmo distinto del que la creó</mark>, convirtiendo la clave **pública** —que cualquiera puede obtener— en el secreto con el que forjas tokens.

# La idea: simétrico vs. asimétrico

Recuerda la distinción de [[01 - Introducción a JWT|la intro]]:

- **`RS256` (asimétrico)**: la clave **privada** firma, la **pública** verifica. La pública no es secreta.
- **`HS256` (simétrico)**: la **misma** clave firma y verifica.

El fallo está en las librerías que **eligen el algoritmo a partir del `alg` del token**. El ataque:

1. La app firma con RS256 y verifica con su clave pública `K`.
2. Tú forjas un token con `alg: HS256` y lo firmas con HMAC usando `K` (la clave pública, en texto) como secreto.
3. La app lee `alg: HS256`, toma `K` como clave HMAC y verifica... <mark style="background: #FFB86CA6;">y la verificación pasa, porque firmaste con esa misma `K`.</mark>

<mark style="background: #8000E1A6;">El servidor confía en `K` para verificar firmas RSA, pero al usarla como clave HMAC, te conviertes en alguien capaz de firmar.</mark> Y `K` es pública por diseño.

# Obtener la clave pública

A veces la app la expone directamente:

```shell-session
$ curl https://target/jwks.json                 # o /.well-known/jwks.json
$ curl https://target/.well-known/openid-configuration
```

Si no está publicada, se **deriva** de dos JWTs firmados con la misma clave: matemáticamente, el módulo RSA `n` se recupera del GCD de operaciones sobre dos firmas. La herramienta `rsa_sign2n` lo hace:

```shell-session
$ git clone https://github.com/silentsignal/rsa_sign2n && cd rsa_sign2n/standalone
$ docker build . -t sig2n && docker run --rm -it sig2n
# dentro del contenedor, con 2 JWTs capturados (mismo emisor):
$ python3 jwt_forgery.py <JWT1> <JWT2>
[+] Written to b196...x509.pem        ← clave pública candidata
[+] Tampered JWT: eyJhbGciOiJIUzI1Ni...  ← ya forjado con HS256
```

Captura los dos JWT repitiendo el login en [[05 - Repeater - repetir y modificar peticiones|Burp Repeater]]. La herramienta da varios candidatos de clave; reejecutar con más tokens los reduce, y ya entrega JWTs HS256 de prueba listos.

# Forjar el token

Con la clave pública (formato PEM), forjas el token admin firmando HMAC con ella:

```shell-session
$ jwt_tool <JWT> -X k -pk public.pem -I -pc isAdmin -pv true
```

> [!warning]+ El formato de la clave es quisquilloso
> Al firmar HMAC con la clave pública, el **formato exacto** del PEM importa: un salto de línea final (`\n`) de más o de menos cambia el HMAC y la firma no cuela. Si el ataque "no funciona" pese a tener la clave correcta, prueba variantes con y sin newline final, X.509 vs PKCS1 — `rsa_sign2n` genera ambas precisamente por esto. Nota de tooling: el **CyberChef moderno ya no firma JWT**; usa la [release v9.0.0](https://github.com/gchq/CyberChef/releases/tag/v9.0.0) local, el Encoder de jwt.io o directamente `jwt_tool -X k`.

# Prevención

La raíz es dejar que el token elija el algoritmo. <mark style="background: #FF5582A6;">La defensa: fijar el algoritmo en el servidor</mark> (`verify(token, key, algorithms=["RS256"])`), nunca confiar en el `alg` del header. Es la misma lección que [[02 - Ataques a la verificación de firma JWT|alg:none]]: el servidor, no el atacante, decide cómo se verifica.

> [!info]+ Fuentes
> - [PortSwigger — JWT algorithm confusion](https://portswigger.net/web-security/jwt/algorithm-confusion)
> - [rsa_sign2n (Silent Signal)](https://github.com/silentsignal/rsa_sign2n) · [jwt_tool — key confusion](https://github.com/ticarpi/jwt_tool/wiki/Attack-Methodology)
