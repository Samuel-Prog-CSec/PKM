---
tags:
  - Wi-Fi/WPA
  - Seguridad/Contraseñas
  - Pentesting/Explotacion
Descripción: "Por qué las tablas precomputadas de PMK ya casi nunca compensan, qué hace hashcat que las vuelve redundantes y los tres casos donde todavía tienen sentido"
Fecha de actualización: 2026-08-04
Nota previa: "[[06 - Credenciales por defecto y keyspaces de fabricante]]"
Nota siguiente: "[[08 - Cracking de identidades WPA-Enterprise]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

La precomputación aparece en todos los cursos como un truco de aceleración espectacular: se genera una tabla de PMK y luego el crackeo va a *cientos de miles* de contraseñas por segundo en vez de miles. <mark style="background: #ADCCFFA6;">La cifra es cierta y la conclusión es falsa</mark>, porque compara la fase barata de un método con la fase cara del otro.

# Qué se precomputa y por qué se podía

El PMK depende sólo de la contraseña y del SSID:

```text
PMK = PBKDF2(HMAC-SHA1, passphrase, SSID, 4096, 256 bits)
```

Ese cálculo —4096 iteraciones de HMAC-SHA1— es **el 99,9 % del coste** de probar una candidata. Lo que viene después (derivar el PTK y comparar el MIC) es un puñado de operaciones. La idea de `genpmk` es hacer el trabajo caro una vez y guardarlo.

<mark style="background: #FFB8EBA6;">La sal es el SSID, no una cadena aleatoria</mark>. Por eso una tabla sirve para todas las redes que se llamen igual, y por eso no sirve para ninguna que se llame distinto.

# La cuenta que HTB no hace

En el ejemplo de HTB, `cowpatty` resuelve 8.381 candidatas en 0,06 s con la tabla ya hecha. Lo que no se cuenta es **cuánto costó la tabla**: exactamente el mismo PBKDF2 que habría costado crackear directamente. La precomputación no ahorra trabajo, lo **mueve de sitio**.

Para que compense hay que reutilizar la tabla. Y aquí está el problema:

> [!important]+ hashcat ya amortiza el PBKDF2, sin tabla
> En una línea `hc22000`, la **sal es el ESSID**. Cuando hashcat carga varios hashes de la misma red, los agrupa por sal y calcula el PMK **una sola vez por candidata**, contrastándolo después contra todos los hashes de ese grupo. Se ve en su cabecera: `1 unique salts` frente a `N digests`.
>
> <mark style="background: #8000E1A6;">Es decir: el beneficio que justificaba la tabla ya lo da hashcat gratis</mark>, dentro de la misma sesión y sin escribir nada en disco. Diez handshakes de `CorpWiFi` cuestan lo mismo que uno.

Los números redondean el argumento. Generar la tabla de `rockyou.txt` para un SSID a la velocidad de una RTX 4090 en `-m 22000` (2.533,3 kH/s) cuesta **5,7 segundos** — que es, ni más ni menos, lo que cuesta crackear con ese diccionario sin tabla. Y ocupa:

| Concepto | Tamaño |
| -------- | ------ |
| 14,3 M de PMK (32 B cada uno) | 0,43 GB |
| Con la passphrase asociada | ~0,55 GB |
| 1.000 SSID × 1 M palabras | **~30 GB** |

<mark style="background: #FF5582A6;">Medio gigabyte por SSID para ahorrar cinco segundos</mark>. En una GPU moderna la precomputación es, casi siempre, una forma cara de no ganar nada.

# Los tres casos en que sigue teniendo sentido

No es que la técnica esté mal: es que su contexto cambió. Sigue siendo la opción correcta cuando:

1. **Separación de hardware.** El rig con GPU no puede recibir los datos del cliente, o al revés. Se generan PMK donde hay potencia y se atacan donde están los hashes, sin mover el diccionario ni los handshakes completos.
2. **SSID por defecto muy repetido.** `linksys`, `NETGEAR`, `MOVISTAR_XXXX`, `dlink`: la tabla sí se reutiliza entre objetivos distintos porque el nombre se repite en todo el país. Es la lógica de las tablas históricas de la **Church of WiFi**, que cubrían el millón de palabras más común contra los 1.000 SSID más frecuentes.
3. **Un ESSID enorme con muchos handshakes** y un flujo que no puede cargarlos todos en la misma sesión de hashcat — un campus con miles de clientes, por ejemplo.

Fuera de esos tres casos, la tabla es peso muerto.

# Cómo se hace hoy, si hace falta

Conviene saber que <mark style="background: #FF5582A6;">las herramientas de generación masiva han desaparecido</mark>: `genpmk` murió con `cowpatty` en 2018, y `wlangenpmkocl` —el generador OpenCL que traía `hcxtools`— **ya no está en el repositorio** (verificado el 2026-08-04: cero coincidencias). No es casualidad; es que dejó de tener demanda por lo explicado arriba.

Lo que queda es el consumo, con el modo `22001` de hashcat:

| Modo | Entrada | Uso |
| ---- | ------- | --- |
| `22000` | Contraseñas | El caso normal |
| `22001` | **PMK de 256 bits en hex** | Tabla heredada, o PMK obtenido por otra vía |

```shell-session
$ hashcat -m 22001 hash.hc22000 pmk-lista.txt
```

Ese modo tiene un uso frecuente que no es precomputación: si se recupera un PMK por un camino lateral —volcado de memoria de un cliente, un `wpa_supplicant.conf` con `pmk=`, o una herramienta que sólo entrega el PMK— se valida contra el handshake sin conocer la contraseña. <mark style="background: #FFB86CA6;">Y con el PMK basta para descifrar el tráfico</mark>: la passphrase es un lujo para el informe.

## Verificar la PSK sin conectarse

`hcxpmktool` no genera tablas: **confirma** una contraseña contra una línea de hash, offline y en un instante. Es la forma correcta de cerrar el paso de verificación sin asociarse a la red del cliente:

```shell-session
$ hcxpmktool -l "$(head -1 hash.hc22000)" -p 'CandidataRecuperada'   # -l espera UNA línea
$ echo $?     # 0 = confirmada · 2 = no confirmada · 1 = error
```

Sirve además para resolver la ambigüedad de un par `challenge`: si el hash venía de un AP falso, `hcxpmktool` dice que la contraseña casa con **ese** material, pero sólo una asociación real contra el AP legítimo —o un par `authorized`— confirma que la red la acepta. Su propia ayuda avisa de que **no aplica correcciones de nonce**, así que con un hash marcado `0x80` puede dar un negativo falso.

# El sustituto real: candidatas derivadas del hash

Lo que hoy ocupa el hueco de "acelerar sin fuerza bruta" no es precomputar, sino **generar menos candidatas y mejores**. `hcxpsktool` produce, a partir del propio fichero de hashes, las candidatas triviales asociadas a ese ESSID y esa MAC:

```shell-session
$ hcxpsktool -c hash.hc22000 --maconly | sort -u | wc -l
$ hcxpsktool -c hash.hc22000 --netgear --weakpass | sort -u > candidatas.txt
```

Unos miles de candidatas contra medio gigabyte de tabla, y con mucha más probabilidad de acierto. El detalle está en [[06 - Credenciales por defecto y keyspaces de fabricante]].

> [!info]+ Dónde sí sobrevive el precómputo: WPA3
> Contra [[04 - WPA3, SAE y OWE|SAE]] no hay handshake crackeable offline, así que la precomputación de PMK no aplica. Pero **SAE-PK** sí es vulnerable a precomputación de otro tipo: se generan pares de claves hasta que la huella coincide con una passphrase corta. Vanhoef y otros lo documentan en [ACNS 2024](https://papers.mathyvanhoef.com/acns2024.pdf). Es la misma idea —pagar cómputo por adelantado— aplicada a un objetivo distinto.
