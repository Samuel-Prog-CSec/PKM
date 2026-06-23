---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Brute-Forcing
Fecha de actualización: 2026-06-23
Nota previa: "[[03 - Medusa y alternativas modernas]]"
Nota siguiente: "[[05 - Defensas y evasión]]"
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
---

Una wordlist genérica como `rockyou` lanza una red ancha y reza. <mark style="background: #ADCCFFA6;">Una wordlist dirigida se construye con lo que sabes del objetivo</mark> —su nombre, su empresa, su jerga, su web— y multiplica la tasa de acierto reduciendo el espacio. Contra "Thomas Edison en su empresa", `xato-net-10-million-usernames.txt` no va a contener su usuario; un esquema generado a su medida, sí.

# Usuarios: de un nombre a todas sus variantes

`username-anarchy` genera permutaciones de un nombre (formato `first.last`, `flast`, `f.last`, iniciales, `leet`...):

```shell-session
$ ./username-anarchy Jane Smith > jane_usernames.txt
# janesmith, smithjane, jane.smith, j.smith, js, jsmith, smithj...
```

> [!important]+ Antes de generar, infiere el esquema
> Más potente que generar 50 variantes es <mark style="background: #FF5582A6;">deducir el esquema de usuario de la organización a partir de **un** correo conocido</mark>. Si `john.doe@empresa.com` aparece en la web o en LinkedIn, el esquema es `first.last` y puedes generar el usuario exacto de cualquier empleado que enumeres. Herramientas como `linkedin2username` automatizan el paso de "lista de empleados" a "lista de usuarios" con ese formato. Esto enlaza con la [[01 - Enumeración de usuarios|enumeración de usuarios]]. <mark style="background: #FFB8EBA6;">Aviso operativo: `linkedin2username` necesita una sesión autenticada de LinkedIn y se rompe a menudo por cambios anti-scraping</mark> — ten plan B (recolección manual + `username-anarchy`, o `hunter.io` para el esquema de correo).

# Contraseñas a partir de OSINT

`CUPP` (Common User Passwords Profiler) construye una lista personalizada a partir de un perfil OSINT (nombre, apodo, pareja, mascota, fechas, aficiones):

```shell-session
$ cupp -i
> First Name: Jane
> Birthdate (DDMMYYYY): 11121990
> Pet's name: Spot
...
[+] Saving dictionary to jane.txt, counting 46790 words.
```

Produce mutaciones: capitalización, reverso, fechas, concatenaciones, sufijos especiales, `leet` (`j4n3`, `Jane1994!`).

> [!warning]+ CUPP funciona, pero está anticuado y es ruidoso
> CUPP genera decenas de miles de candidatas con mutaciones poco realistas, inflando el ataque. En 2026 los profesionales usan generadores mantenidos y con reglas más finas:
> - <mark style="background: #FFB86CA6;">`psudohash`</mark> (t3l3machus) — el sustituto moderno de CUPP, mutaciones realistas y control de años/símbolos.
> - `Mentalist` — GUI por grafos: encadenas nodos (base words → case → append → leet) y exporta la wordlist o las reglas de `hashcat`.
> - `pydictor` — base configurable, plugins y diccionario de ingeniería social (`--sedb`).

# A partir del propio sitio: `CeWL`

El recurso que HTB olvida aquí. <mark style="background: #FFB8EBA6;">`CeWL` rastrea la web del objetivo y extrae su vocabulario</mark>: nombres de producto, jerga interna, lemas. Esas palabras son candidatas a contraseña que ninguna lista genérica tiene.

```shell-session
$ cewl -d 2 -m 5 -w site-words.txt https://target.com   # profundidad 2, palabras ≥5 letras
$ cewl -d 2 --with-numbers -e --email_file emails.txt -w site.txt https://target.com
```

`-e` además cosecha correos (más usuarios para enumerar). El resultado se mete luego por un mutador (`psudohash`, reglas de `hashcat`) para añadir años y símbolos.

# Filtrar a la política y mutar

La lista generada se recorta a la política de contraseñas conocida (mín. longitud, tipos de carácter) para no malgastar intentos. Con `grep` encadenado, como en [[01 - Tipos de ataque - diccionario, híbrido y máscara|tipos de ataque]]:

```shell-session
$ grep -E '^.{6,}$' jane.txt | grep -E '[A-Z]' | grep -E '[a-z]' | grep -E '[0-9]' \
    | grep -E '([!@#$%^&*].*){2,}' > jane-filtered.txt   # 46k → ~7.9k
```

Las dos listas (usuarios + contraseñas filtradas) se lanzan ya contra el login con [[02 - Hydra|Hydra]] o [[03 - Medusa y alternativas modernas|ffuf]]:

```shell-session
$ hydra -L jane_usernames.txt -P jane-filtered.txt -f IP -s PORT \
    http-post-form "/:username=^USER^&password=^PASS^:F=Invalid credentials"
```

<mark style="background: #8000E1A6;">El flujo profesional es: enumerar usuarios → inferir esquema → `CeWL`/OSINT para semillas → mutar con reglas → filtrar a la política → lanzar.</mark> Cada paso recorta el espacio y sube la probabilidad. El inventario de herramientas, en [[06 - Arsenal de herramientas para Brute Forcing]].

> [!info]+ Fuentes
> - [username-anarchy](https://github.com/urbanadventurer/username-anarchy) · [linkedin2username](https://github.com/initstring/linkedin2username)
> - [psudohash](https://github.com/t3l3machus/psudohash) · [Mentalist](https://github.com/sc0tfree/mentalist) · [pydictor](https://github.com/LandGrey/pydictor)
> - [CeWL](https://github.com/digininja/CeWL)
