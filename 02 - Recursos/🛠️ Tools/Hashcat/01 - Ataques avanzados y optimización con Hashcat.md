---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-18
Nota previa: "[[00 - Introducción a Hashcat]]"
Nota siguiente: 
Area: "[[Hashcat.base|Hashcat]]"
---
---

Donde Hashcat despliega su potencia es en los ataques dirigidos: máscaras que explotan la estructura de las contraseñas y reglas que mutan wordlists a velocidad de GPU.

# Ataques de máscara

<mark style="background: #ADCCFFA6;">Una máscara define el **patrón** de los candidatos usando charsets</mark>, en vez de probar todo el espacio a ciegas:

| Token | Charset |
| --- | --- |
| `?l` | `a-z` |
| `?u` | `A-Z` |
| `?d` | `0-9` |
| `?s` | símbolos |
| `?a` | todos los anteriores |

```shell-session
# Patrón típico de política: Mayúscula + 5 minúsculas + 2 dígitos (Winter22)
$ hashcat -m 1000 -a 3 hashes.txt '?u?l?l?l?l?l?d?d'

# Charset personalizado (-1) y su uso (?1)
$ hashcat -m 1000 -a 3 -1 '?l?d' hashes.txt '?1?1?1?1?1?1'

# Incremento de longitud (prueba 1..N caracteres)
$ hashcat -m 1000 -a 3 --increment hashes.txt '?a?a?a?a?a?a?a?a'
```

<mark style="background: #FFB86CA6;">La máscara brilla cuando conoces la política de contraseñas del objetivo</mark> ([[16 - Políticas y gestores de contraseñas|password policy]]): si exige "mayúscula + minúsculas + 2 dígitos", una máscara dirigida rompe en minutos lo que la fuerza bruta ciega no rompería en días.

# Reglas: multiplicar la wordlist

Las reglas aplican transformaciones (capitalizar, `leet`, añadir sufijos) a cada palabra:

```shell-session
$ hashcat -m 1000 -a 0 hashes.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

| Ruleset | Uso |
| --- | --- |
| `best64.rule` | El equilibrio por defecto |
| `rockyou-30000.rule` | Amplio |
| `OneRuleToRuleThemAll` | El más agresivo (comunidad) |

<mark style="background: #8000E1A6;">`rockyou.txt` + una buena regla rompe la enorme mayoría de contraseñas humanas reales</mark> — más eficiente que fuerza bruta pura. La creación de reglas propias, en [[01 - Wordlists y reglas personalizadas]].

# Optimización

```shell-session
$ hashcat -m 1000 -a 0 -O -w 3 hashes.txt rockyou.txt   # kernel optimizado, workload alto
$ hashcat -b -m 1000                                     # benchmark del tipo de hash
```

> [!warning]+ Cuidado con `-O`
> <mark style="background: #FF5582A6;">`-O` (optimized kernel) acelera mucho pero **limita la longitud máxima** de contraseña</mark> (típicamente a 31 chars o menos según el hash). Para passphrases largas puede saltarse candidatos válidos. `-w 3`/`-w 4` sube el *workload* (menos interactividad, más velocidad) — ideal en un rig dedicado, no en tu portátil de trabajo.

# Sesiones y reanudación

```shell-session
$ hashcat --session=eng1 -m 1000 -a 0 hashes.txt rockyou.txt -r best64.rule
$ hashcat --session=eng1 --restore      # reanudar tras un corte
```

> [!success]+ Estrategia de cracking (orden de eficiencia)
> 1. **Wordlist + reglas** (`rockyou` + `best64`) — rompe la mayoría en minutos.
> 2. **Máscara dirigida** según la política conocida.
> 3. **Wordlists específicas** del objetivo ([[01 - Wordlists y reglas personalizadas|cewl, mutaciones]]).
> 4. **Fuerza bruta / incremental** solo como último recurso.
> Empezar por fuerza bruta pura es de novato: casi siempre pierdes contra una wordlist con reglas.

El arsenal completo y la comparativa con [[00 - Introducción a John the Ripper|John]] cierran el toolkit de cracking, integrado en [[18 - Arsenal de herramientas|ataques a contraseñas]].
