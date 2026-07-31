---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
Descripción: "La taxonomía conceptual se traduce en tres técnicas que de verdad usas contra un login: diccionario (el caballo de batalla), híbrido (diccionario mutado) y máscara (brute force…"
Fecha de actualización: 2026-06-23
Nota previa: "[[00 - Introducción al brute forcing]]"
Nota siguiente: "[[02 - Hydra]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
---

La [[00 - Introducción al brute forcing|taxonomía conceptual]] se traduce en tres técnicas que de verdad usas contra un login: **diccionario** (el caballo de batalla), **híbrido** (diccionario mutado) y **máscara** (brute force acotado a un patrón). La fuerza bruta exhaustiva pura queda relegada a keyspaces diminutos.

# Diccionario: la técnica de cabecera

<mark style="background: #ADCCFFA6;">Un `dictionary attack` prueba una lista precompilada de contraseñas probables en vez de recorrer todo el espacio.</mark> Funciona porque la gente elige contraseñas memorizables: palabras, nombres, patrones (`qwerty`, `password123`). Su eficacia depende **por completo** de la calidad de la wordlist.

Wordlists de referencia para login web (vienen en Kali/Parrot o se sacan de [SecLists](https://github.com/danielmiessler/SecLists)):

| Wordlist                                    | Contenido                                   | Uso                                      |
| ------------------------------------------- | ------------------------------------------- | ---------------------------------------- |
| `rockyou.txt`                               | ~14M de contraseñas de la brecha de RockYou | El diccionario por defecto               |
| `2023-200_most_used_passwords.txt`          | Top 200 reutilizadas                        | Primer barrido rápido y sigiloso         |
| `darkweb2017_top-10000.txt`                 | Top 10k de filtraciones                     | Equilibrio cobertura/velocidad           |
| `top-usernames-shortlist.txt`               | Usuarios más comunes                        | Fase de [[01 - Enumeración de usuarios]] |
| `Default-Credentials/default-passwords.txt` | `user:pass` de fábrica                      | [[06 - Credenciales por defecto]]        |

<mark style="background: #FF5582A6;">La wordlist genérica es el plan B; la que de verdad rompe cuentas es la dirigida.</mark> En un engagement, construyes la lista con lo recolectado en [[00 - Reconocimiento web|recon]]: nombre de la empresa y variantes, nombres de empleados, jerga del sector, año en curso. Eso se cubre en [[04 - Generación de wordlists]].

También está la posibilidad de usar <mark style="background: #FFB86CA6;">`Python` para lanzar el ataque de fuerza bruta</mark> usando una *wordlist*:
```Python
import requests 
ip = "127.0.0.1" 
port = 1234

passwords = requests.get("https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Passwords/Common-Credentials/500-worst-passwords.txt").text.splitlines()

# Intentar cada contraseña de la lista
for password in passwords: 
	print(f"Attempted password: {password}") 
	
	# Enviar una solictud de POST al servidor
	response = requests.post(f"http://{ip}:{port}/dictionary", data={'password': password}) 
	
	# Comprobar si el servidor responde con status OK y si contiene la flag
	if response.ok and 'flag' in response.json(): 
		print(f"Correct password found: {password}") 
		print(f"Flag: {response.json()['flag']}") 
		break
```

# Fuerza bruta pura: solo con keyspace diminuto

Recorrer todo el espacio `online` solo es viable cuando es minúsculo. El caso típico: un **PIN de 4 dígitos** (10.000 combinaciones) o un código OTP. Un script trivial lo agota en segundos:
```python
import requests

for pin in range(10000):
    p = f"{pin:04d}"        # 0000 → 9999, con ceros a la izquierda
    r = requests.get(f"http://{ip}:{port}/pin?pin={p}")
    if r.ok and 'flag' in r.json():
        print(f"PIN: {p} → {r.json()['flag']}")
        break
```

<mark style="background: #FFB8EBA6;">El mismo principio sostiene el [[04 - Fuerza bruta de códigos 2FA y MFA|brute force de códigos 2FA]]</mark>: 6 dígitos son solo un millón de combinaciones, crackeables en minutos **si** no hay rate limiting. La defensa aquí nunca es la longitud, sino el límite de intentos.

# Híbrido: diccionario + mutación

Las políticas de cambio periódico de contraseña generan un patrón explotable: el usuario "decora" su contraseña anterior en vez de cambiarla. `Summer2023` se convierte en `Summer2023!` o `Summer2024`.
![[Modificar_Contraseña.webp]]

<mark style="background: #FFB86CA6;">El `hybrid attack` captura esas variantes</mark>: parte del diccionario y le aplica mutaciones (sufijos, `leet`, años). Hay dos formas de generarlas.

**La forma de HTB — filtrar con `grep` a una política.** Si conoces la política (mín. 8, una mayúscula, una minúscula, un dígito), recortas la wordlist a lo que cumple, reduciendo drásticamente el espacio:

```shell-session
$ grep -E '^.{8,}$' darkweb2017_top-10000.txt | grep -E '[A-Z]' | grep -E '[a-z]' | grep -E '[0-9]' > policy.txt
$ wc -l policy.txt
89 policy.txt
```
Respecto al `regex`: 
- La expresión regular `^.{8,}$` actúa como un filtro, asegurando que <mark style="background: #FFB8EBA6;">solo las contraseñas que contienen al menos 8 caracteres</mark> pasen.
- La expresión regular `[A-Z]` asegura que <mark style="background: #FFB8EBA6;">cualquier contraseña que no tenga una letra mayúscula sea descartada</mark>.
- La expresión regular `[a-z]` sirve como filtro, <mark style="background: #FFB8EBA6;">conservando solo las contraseñas que incluyen al menos una letra minúscula</mark>.
- La expresión regular `[0-9]` actúa como filtro, asegurando que las <mark style="background: #FFB8EBA6;">contraseñas que contienen al menos un dígito numérico se conserven</mark>.

De 10.000 a 89 candidatas: un <mark style="background: #FF5582A6;">ataque mucho más rápido y enfocado</mark>.

**La forma moderna — reglas de mutación.** Encadenar `grep` filtra, pero no **genera** variantes nuevas. Para eso, el estándar son las reglas de `hashcat`/`John`, que mutan cada palabra (capitalizar, añadir años, `leet`...) y se pueden volcar a stdout para alimentar a un cracker `online` como [[02 - Hydra|Hydra]] o [[03 - Medusa y alternativas modernas|ffuf]]:

```shell-session
$ hashcat --stdout rockyou.txt -r /usr/share/hashcat/rules/best64.rule > mutated.txt
$ john --wordlist=base.txt --rules=Jumbo --stdout > mutated.txt
```

> [!important]+ Genera offline, lanza online
> Las reglas de `hashcat`/`John` se diseñaron para crackeo offline, pero `--stdout` las convierte en un **generador de wordlists**. Mutas en local a toda velocidad y luego lanzas la lista resultante —ya acotada— contra el login. Mezclar ambos mundos es el flujo profesional para el brute force web dirigido.

# Máscara: brute force con plantilla

Cuando conoces el **formato** exacto (p. ej. "Nombre + 2 dígitos" o el patrón corporativo `Empresa@NN`), un `mask attack` recorre solo ese molde en lugar de todo el charset. La notación de `hashcat` define cada posición:

| Token | Significado |
| - | - |
| `?l` / `?u` | minúscula / mayúscula |
| `?d` / `?s` | dígito / símbolo |
| `?a` | todos los imprimibles |

```shell-session
$ hashcat -a 3 -1 ?u?l 'Company?1?l?l?d?d?d' --stdout > masked.txt
```

<mark style="background: #8000E1A6;">La máscara es brute force "con plantilla"</mark>: conocer la política convierte un espacio inabordable en uno recorrible. Generación de patrones y wordlists a medida con `crunch`, `CeWL` y compañía, en [[04 - Generación de wordlists]].

> [!info]+ Fuentes
> - [SecLists — Passwords](https://github.com/danielmiessler/SecLists/tree/master/Passwords) (wordlists)
> - [hashcat — rule-based attack](https://hashcat.net/wiki/doku.php?id=rule_based_attack) · [mask attack](https://hashcat.net/wiki/doku.php?id=mask_attack)
