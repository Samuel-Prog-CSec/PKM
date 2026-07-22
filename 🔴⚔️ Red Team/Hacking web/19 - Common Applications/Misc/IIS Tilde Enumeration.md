---
tags:
  - Web/Red-Team
  - IIS
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a ColdFusion]]"
Nota siguiente: "[[Attacking LDAP]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Windows genera nombres cortos **8.3** (`NOMBRE~1.EXT`) para compatibilidad</mark>. Ciertas versiones de IIS permiten sondear esos nombres cortos con el carácter tilde `~`, revelando ficheros y directorios **aunque el listado esté desactivado**.

# La técnica: narrowing carácter a carácter

Se prueba cada carácter tras el `~` y se observa el código de respuesta (200 = existe un nombre corto que empieza así):

```http
/~s   → 200   (algo empieza por "s")
/~se  → 200
/~sec → 200
...   → hasta secret~1
```

Los ficheros se distinguen con el número: `somefile.txt` → `somefi~1.txt`, y un segundo `somefile1.txt` → `somefi~2.txt`.

# Enumeración

```shell-session
$ nmap -p- -sV -sC --open 10.129.224.91
80/tcp  open  http  Microsoft IIS httpd 7.5
```

En lugar de probar a mano, **IIS-ShortName-Scanner** (Java) lo automatiza:

```shell-session
$ java -jar iis_shortname_scanner.jar 0 5 http://10.129.204.231/
|_ Result: Vulnerable!
|_ Identified directories: ASPNET~1, UPLOAD~1
|_ Identified files: CSASPX~1.CS, TRANSF~1.ASP
```

# Del nombre corto al completo

El scanner da los **6 primeros caracteres** (`TRANSF~1.ASP`); falta el resto. Se genera una wordlist filtrando por ese prefijo y se fuerza con gobuster:

```shell-session
$ egrep -r ^transf /usr/share/wordlists/* | sed 's/^[^:]*://' > /tmp/list.txt
$ gobuster dir -u http://10.129.204.231/ -w /tmp/list.txt -x .aspx,.asp
/transfer.aspx (Status: 200)
```

<mark style="background: #FF5582A6;">Se descubre `transfer.aspx`</mark> — un fichero que no aparecía por ningún lado. Su valor real: encontrar `.config`, `.bak`, backups y páginas ocultas.

> [!info]+ Alcance y defensa
> Afecta a IIS con la creación de nombres 8.3 activa (por defecto en Windows antiguos; la box **Bounty** de HTB lo ilustra con IIS 7.5). Sigue apareciendo en 2026 en servidores legacy. Otras herramientas: `sns.py`, `nuclei -tags iis`. Defensa: `fsutil 8dot3name set 1` (los ficheros ya creados conservan su nombre corto).

Siguiente en las *Misc Applications*, la inyección contra directorios: [[Attacking LDAP]].
