---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - JWT
Descripción: "Si la app sí verifica la firma, hay otra vía: conocer el secreto de firma permite calcular firmas válidas para tokens forjados"
Fecha de actualización: 2026-06-23
Nota previa: "[[02 - Ataques a la verificación de firma JWT]]"
Nota siguiente: "[[04 - Confusión de algoritmos JWT]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

Si la app **sí** verifica la firma, hay otra vía: <mark style="background: #ADCCFFA6;">conocer el secreto de firma permite calcular firmas válidas para tokens forjados.</mark> Funciona contra los algoritmos simétricos (`HS256/384/512`), donde la misma clave firma y verifica — y donde los desarrolladores meten secretos débiles con demasiada frecuencia.

# Por qué el secreto HMAC es atacable

`HS256` usa HMAC: una clave secreta compartida. Si esa clave es una contraseña corta, una palabra, un valor por defecto de un tutorial (`secret`, `your-256-bit-secret`, `changeme`) o una key filtrada en el repo, se **crackea offline**. A diferencia de RSA, no hay clave privada de 2048 bits que romper, solo un string que el dev eligió mal.

Confirma primero que el token es simétrico mirando el `alg` (`HS256`). Entonces el ataque es crackeo offline puro, sin tocar el servidor.

# Crackear con hashcat

El modo `16500` de `hashcat` es para JWT. Guarda el token y tíralo contra una wordlist:

```shell-session
$ echo -n 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiaHRiLXN0ZG50Ii...' > jwt.txt
$ hashcat -m 16500 jwt.txt rockyou.txt
$ hashcat -m 16500 jwt.txt rockyou.txt --show
eyJ...WTW0:rayruben1          ← secreto recuperado
```

<mark style="background: #FFB86CA6;">Es rapidísimo</mark>: HMAC es un hash veloz (millones de intentos/seg en GPU), así que la velocidad solo depende de la wordlist. Para secretos JWT conviene una lista especializada además de `rockyou`:

```shell-session
$ jwt_tool <JWT> -C -d jwt.secrets.list      # crackeo con jwt_tool
```

La wordlist [`jwt.secrets.list`](https://github.com/wallarm/jwt-secrets) (Wallarm) recopila secretos por defecto de frameworks y tutoriales — el primer sitio donde mirar, antes que `rockyou`.

# Forjar el token

Con el secreto en mano, eres el servidor. Manipulas el payload y firmas con la clave recuperada en [jwt.io](https://jwt.io), CyberChef o jwt_tool:

```shell-session
$ jwt_tool <JWT> -S hs256 -p 'rayruben1' -T    # edita claims y firma con el secreto
```

<mark style="background: #8000E1A6;">El resultado es un JWT con firma **válida** y `isAdmin: true`</mark> — indistinguible de uno legítimo. El servidor lo verifica correctamente y concede el acceso.

> [!important]+ La defensa es trivial pero se incumple
> Un secreto HMAC debe ser **aleatorio y largo** (≥256 bits de un CSPRNG), no una contraseña memorizable. La RFC lo exige, pero los devs copian el `secret` del ejemplo de la doc. Por eso este ataque sigue funcionando en producción. Para eliminarlo de raíz, muchas apps migran a algoritmos asimétricos (`RS256`) — que, mal configurados, abren la [[04 - Confusión de algoritmos JWT|confusión de algoritmos]].

> [!info]+ Fuentes
> - [PortSwigger — Brute-forcing secret keys](https://portswigger.net/web-security/jwt#brute-forcing-secret-keys-using-hashcat)
> - [hashcat — mode 16500](https://hashcat.net/wiki/) · [jwt-secrets wordlist (Wallarm)](https://github.com/wallarm/jwt-secrets) · [jwt_tool](https://github.com/ticarpi/jwt_tool)
