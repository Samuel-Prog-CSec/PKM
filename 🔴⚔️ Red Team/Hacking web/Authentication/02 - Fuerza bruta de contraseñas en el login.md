---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[01 - Enumeración de usuarios]]"
Nota siguiente: "[[03 - Fuerza bruta de tokens de reset]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Con un [[01 - Enumeración de usuarios|usuario válido]] confirmado, el login depende solo de la contraseña. La mecánica de la fuerza bruta (Hydra, ffuf, wordlists) vive en [[00 - Introducción al brute forcing|Brute Forcing]]; aquí está lo específico de atacar un login real: ajustar la lista a la política y, sobre todo, **el spraying**, que es lo que de verdad compromete organizaciones.

# Ajustar la wordlist a la política

Si la app muestra su política (ej. "mín. 10 caracteres, una mayúscula, una minúscula, un dígito"), lanzar `rockyou` entero malgasta el 99% de los intentos en contraseñas que el sistema ni acepta. Recórtala antes:

```shell-session
$ awk 'length($0) >= 10 && /[a-z]/ && /[A-Z]/ && /[0-9]/' rockyou.txt > custom.txt
$ wc -l custom.txt        # 14.3M → ~150k (−99%)
```

Con el usuario conocido y el mensaje de error identificado, `ffuf` sobre el parámetro de contraseña:

```shell-session
$ ffuf -w custom.txt -u http://target/index.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=FUZZ" -fr "Invalid username"
[Status: 302] FUZZ: Buttercup1
```

<mark style="background: #FFB8EBA6;">Forzar un único usuario solo funciona si no hay lockout.</mark> Contra cualquier app con bloqueo de cuenta, este ataque se agota a los 3-5 intentos. Por eso el ataque real invierte el problema.

# Password spraying: la técnica que sí funciona

<mark style="background: #ADCCFFA6;">El `password spraying` prueba **pocas** contraseñas muy probables contra **muchos** usuarios</mark>, en vez de muchas contraseñas contra un usuario. Cada cuenta recibe 1-2 intentos → nunca dispara el lockout, mientras barres toda la organización.

El flujo:

1. Enumerar el máximo de usuarios válidos ([[01 - Enumeración de usuarios]], OSINT, LinkedIn).
2. Elegir 1-3 contraseñas con alta probabilidad estacional o contextual: `Empresa2026!`, `Primavera2026`, `Welcome1`, el nombre de la ciudad sede.
3. Probar **una** contraseña contra **todos** los usuarios. Esperar. Probar la siguiente horas después.

```shell-session
$ ffuf -w users.txt:UF -u http://target/login -X POST \
    -d "username=UF&password=Empresa2026!" -fr "Invalid"
```

> [!warning]+ El spraying es ruidoso a su manera
> Repartir entre usuarios esquiva el lockout por cuenta, pero <mark style="background: #FFB86CA6;">una sola IP intentando el mismo password contra 500 usuarios es la firma clásica que detecta el SOC</mark>. En un engagement con detección activa: rota la IP ([[05 - Defensas y evasión|fireprox]]), introduce *jitter* y reparte en ventanas largas (1 password al día). El sigilo importa más que la velocidad.

# Credential stuffing: reutilización de contraseñas

Variante con credenciales reales filtradas: <mark style="background: #8000E1A6;">si tienes pares `user:pass` de una brecha previa, los pruebas tal cual</mark> aprovechando que la gente reutiliza. No "adivina" nada — explota que el mismo password vale en varios servicios. Con un volcado de `Have I Been Pwned` / combolists, es uno de los vectores más efectivos contra usuarios concretos.

La protección de todo esto (rate limiting, lockout) y cómo se evade, en [[05 - Bypass de protecciones anti-fuerza-bruta]]. El arsenal (Hydra, ffuf, Burp Intruder, fireprox), en [[06 - Arsenal de herramientas para Brute Forcing]].

> [!info]+ Fuentes
> - [PortSwigger — Password-based vulnerabilities](https://portswigger.net/web-security/authentication/password-based)
> - [MITRE ATT&CK — Password Spraying (T1110.003)](https://attack.mitre.org/techniques/T1110/003/) · [Credential Stuffing (T1110.004)](https://attack.mitre.org/techniques/T1110/004/)
