---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Descripción: "Mover FUZZ a los parámetros descubre superficie que no se ve navegando: parámetros ocultos que activan funciones de debug, admin=true, endpoints de API sin documentar"
Fecha de actualización: 2026-07-19
Nota previa: "[[03 - Fuzzing de dominios con ffuf]]"
Nota siguiente: "[[05 - Matching y filtrado de resultados]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

Mover `FUZZ` a los parámetros descubre superficie que no se ve navegando: parámetros ocultos que activan funciones de debug, `admin=true`, endpoints de API sin documentar. Se hace en dos fases — descubrir el **nombre** del parámetro y luego fuzzear su **valor**.

# Nombre de parámetro (GET)

`FUZZ` en la clave del query string:

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
       -u "https://target/api/user?FUZZ=1" -fs 42
```

<mark style="background: #FFB86CA6;">Un parámetro válido cambia la respuesta</mark> (tamaño, código o contenido) frente al `Size` uniforme de los inválidos — por eso el `-fs`/`-ac` es imprescindible aquí (ver [[05 - Matching y filtrado de resultados]]).

# Nombre de parámetro (POST)

Igual, pero en el cuerpo y con el `Content-Type` correcto:

```shell-session
$ ffuf -w burp-parameter-names.txt -u https://target/api/user \
       -X POST -d 'FUZZ=1' \
       -H 'Content-Type: application/x-www-form-urlencoded' -fs 42
```

Para APIs JSON, `FUZZ` va en la clave del objeto:

```shell-session
$ ffuf -w params.txt -u https://target/api/user \
       -X POST -d '{"FUZZ":"test"}' \
       -H 'Content-Type: application/json' -fr '"error"'
```

# Valor de parámetro

Conocido el parámetro, fuzzeas su **valor** para encontrar IDs válidos, ficheros, o disparar comportamientos:

```shell-session
# Descubrir IDs válidos (base de IDOR)
$ ffuf -w ids.txt -u "https://target/api/invoice?id=FUZZ" -mc 200 -fs 0
# Fuzzear un valor de fichero (base de LFI/path traversal)
$ ffuf -w /usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt \
       -u "https://target/?page=FUZZ" -mr "root:x:"
```

<mark style="background: #ADCCFFA6;">El fuzzing de valores es la puerta a IDOR, LFI, SQLi y lógica de negocio</mark>: aquí `ffuf` deja de ser "content discovery" y se vuelve un motor de pruebas de vulnerabilidad. La metodología de parámetros vive en [[19 - Fuzzing de parámetros y valores]] y las APIs en [[24 - Fuzzing de APIs]].

> [!info]+ Herramientas dedicadas a parámetros ocultos
> Para descubrimiento de parámetros a fondo, `ffuf` compite con herramientas especializadas: **`x8`** (Rust, detecta parámetros que solo cambian el comportamiento sutilmente), **`Arjun`** (Python) y **`param-miner`** (extensión de Burp, imbatible para *cache poisoning* y cabeceras ocultas). Cuándo usar cada una, en [[07 - WAF, evasión y arsenal complementario]].

El hilo conductor de todo lo anterior —distinguir el acierto del ruido— se sistematiza ahora: [[05 - Matching y filtrado de resultados]].
