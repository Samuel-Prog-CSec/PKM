---
tags:
  - Redes
  - Protocolos
  - Wi-Fi/802.11
Descripción: "Cómo se numeran los canales en 2,4/5/6 GHz, qué límites de potencia y DFS impone cada dominio regulatorio y cómo los aplica el kernel de Linux"
Fecha de actualización: 2026-08-01
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">802.11 opera en bandas de **uso común**: no hacen falta licencia ni asignación individual, pero sí respetar unos límites técnicos —frecuencia, potencia, ciclo de trabajo— que fija cada regulador nacional</mark>. Esos límites no son burocracia: determinan qué canales ve una tarjeta, con qué potencia puede transmitir y, en un pentest, dónde acaba lo legal.

# Cómo se numera un canal

Un canal no es más que una frecuencia central y un ancho de banda alrededor. La numeración es una fórmula, no una tabla arbitraria:

| Banda | Fórmula del centro | Rango de canales |
| ----- | ------------------ | ---------------- |
| 2,4 GHz | `2407 + 5n` MHz | 1–13 (14 = 2484 MHz, sólo Japón) |
| 5 GHz | `5000 + 5n` MHz | 36–177 |
| 6 GHz | `5950 + 5n` MHz | 1–233 (canal 2 = 5935 MHz, excepción) |

<mark style="background: #FFB8EBA6;">La separación entre centros consecutivos en 2,4 GHz es de 5 MHz, pero el canal ocupa 20 MHz</mark>. De ahí el solapamiento crónico de la banda: sólo caben tres canales verdaderamente disjuntos.

- **Dominio FCC** (11 canales): 1, 6 y 11 no se solapan.
- **Dominio ETSI** (13 canales): 1, 5, 9 y 13 tampoco, lo que da cuatro en Europa.

> [!important]+ Consecuencia operativa
> Un barrido pasivo que salte sólo por 1, 6 y 11 en Europa **se pierde redes** que estén en 5, 9 o 13. `airodump-ng` salta por todos los canales del dominio activo, pero si se fija un subconjunto con `-c` hay que fijar el correcto para la región.

# La banda de 5 GHz y el DFS

5 GHz ofrece muchos más canales disjuntos de 20 MHz y menos ruido doméstico, a costa de peor propagación a través de obstáculos. Se divide en sub-bandas U-NII con reglas distintas:

| Sub-banda | Frecuencias | Canales | Régimen en la UE |
| --------- | ----------- | ------- | ---------------- |
| U-NII-1 | 5150–5250 MHz | 36–48 | Sólo interiores, 200 mW EIRP |
| U-NII-2A | 5250–5350 MHz | 52–64 | Interiores, DFS + TPC obligatorios |
| U-NII-2C | 5470–5725 MHz | 100–144 | 1 W EIRP, DFS + TPC obligatorios |
| U-NII-3 | 5725–5850 MHz | 149–165 | **No armonizada** para RLAN en la UE |
| U-NII-4 | 5850–5925 MHz | 169–177 | Reservada a V2X (ITS). No es Wi-Fi en la UE |

<mark style="background: #FFB8EBA6;">Los canales 149–165 son los que un pentester ve en equipamiento importado o mal configurado</mark>: existen en el dominio FCC y **no** en el europeo. Un AP emitiendo en el canal 157 dentro de la UE está fuera de norma, y eso es un hallazgo por sí mismo — además de una pista de que alguien tocó el dominio regulatorio del equipo.

`DFS` (*Dynamic Frequency Selection*) existe porque esas frecuencias las comparten radares meteorológicos y militares. Antes de emitir, el AP debe escuchar el canal durante un **CAC** (*Channel Availability Check*) de 60 segundos —600 en la sub-banda 5600–5650 MHz, reservada a radar meteorológico— y, si detecta un pulso de radar, abandonar el canal y no volver en 30 minutos. `TPC` (*Transmit Power Control*) obliga a reducir la potencia cuando no hace falta el máximo.

<mark style="background: #FF5582A6;">Para un atacante, un canal DFS es un canal donde no puede aparecer un AP falso sin más</mark>: montar un *evil twin* ahí exige respetar el CAC o violar la norma de forma evidente. Y a la inversa, es un buen sitio donde un defensor puede detectar radios que no lo respetan.

# La banda de 6 GHz

Es la novedad de Wi-Fi 6E y 7, y donde más divergen los reguladores.

- **EEUU (FCC, 2020)**: 5925–7125 MHz completos, 1200 MHz de espectro.
- **Unión Europea**: sólo la mitad baja, **5945–6425 MHz** (U-NII-5), abierta por la [Decisión de Ejecución (UE) 2021/1067](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:32021D1067), con dos clases de dispositivo: **LPI** (*Low Power Indoor*, 200 mW EIRP, sólo interiores, sin antena externa) y **VLP** (*Very Low Power*, 25 mW EIRP, permitido en exteriores).

En España la trasposición vive en el **CNAF**, la nota **UN-167**, que remite directamente a las condiciones técnicas del anexo de esa Decisión. Las bandas clásicas son las notas **UN-85** (2,4 GHz, 2400–2483,5 MHz) y **UN-128** (5 GHz, 5150–5350 y 5470–5725 MHz) ([Cuadro Nacional de Atribución de Frecuencias · digital.gob.es](https://digital.gob.es/en/telecomunicaciones-infraestructuras-digitales/areas-interes/espectro-radioelectrico/cuadro-nacional-atribucion-frecuencias)).

<mark style="background: #8000E1A6;">La restricción LPI de "sólo interiores y sin antena externa" significa que una tarjeta USB con antena de alta ganancia apuntando a un edificio ajeno en 6 GHz está fuera de norma por diseño</mark>, independientemente de lo que se haga con ella.

# Cómo lo aplica Linux

El kernel no confía en el usuario para esto: `cfg80211` guarda las reglas y las hace cumplir. La arquitectura tiene tres piezas ([kernel.org · Wireless regulatory](https://wireless.docs.kernel.org/en/latest/en/developers/regulatory.html)):

- **`wireless-regdb`** — la base de datos de reglas por país, distribuida como fichero binario firmado (`regulatory.db`).
- **`cfg80211`** — el subsistema del kernel que aplica las reglas al driver.
- **`CRDA`** — el agente de espacio de usuario que hacía de puente. Es **opcional desde el kernel 4.15**: hoy el kernel carga `regulatory.db` directamente por la API de firmware, así que en un sistema moderno no hace falta tener CRDA instalado.

El dominio activo se puede fijar de tres formas, y la más restrictiva gana: por el driver (algunos lo traen quemado en EEPROM), por el `country IE` que el AP anuncia en sus beacons, o a mano.

```shell-session
$ iw reg get
global
country ES: DFS-ETSI
        (2400 - 2483 @ 40), (N/A, 20), (N/A)
        (5150 - 5250 @ 80), (N/A, 23), (N/A), NO-OUTDOOR, AUTO-BW
        (5250 - 5350 @ 80), (N/A, 20), (0 ms), NO-OUTDOOR, DFS, AUTO-BW
        (5470 - 5725 @ 160), (N/A, 26), (0 ms), DFS, AUTO-BW
        (5945 - 6425 @ 160), (N/A, 23), (N/A), NO-OUTDOOR, wmmrule=ETSI
        (57000 - 66000 @ 2160), (N/A, 40), (N/A)
```

Las banderas de cada regla son lo que hay que leer:

| Bandera | Significado |
| ------- | ----------- |
| `NO-IR` | *No Initiating Radiation* — se puede escuchar, pero no transmitir sin haber oído antes a alguien. Impide levantar un AP o enviar *probe requests* en ese canal |
| `DFS` | Exige CAC y abandono ante radar |
| `NO-OUTDOOR` | Sólo interiores |
| `PASSIVE-SCAN` | Escaneo pasivo obligatorio (bandera legada, hoy expresada como `NO-IR`) |
| `AUTO-BW` | El ancho se puede ampliar si las reglas contiguas lo permiten |

El segundo número de cada paréntesis es la potencia máxima en **dBm de EIRP**: 20 dBm = 100 mW en 2,4 GHz, 23 dBm = 200 mW en 5150–5250 y en 6 GHz.

> [!warning]+ El truco de `iw reg set BO` no es una técnica, es una infracción
> Cambiar el dominio a Bolivia o a otro país permisivo para desbloquear canales y potencia es un clásico de los foros. Tiene tres problemas. Primero, **es ilegal**: emitir fuera de las condiciones del CNAF es una infracción de la Ley General de Telecomunicaciones, sancionable con independencia de que el engagement esté autorizado. Segundo, **es ruidoso**: transmitir en un canal DFS sin CAC o con potencia fuera de norma es exactamente lo que un WIDS busca. Y tercero, **el cliente no lo pidió**: el alcance de un pentest Wi-Fi no incluye interferir el espectro de terceros.
>
> El dominio `00` (*world*) no es lo contrario sino lo más restrictivo: marca casi todo como `NO-IR` porque el kernel no sabe dónde está.

# Lo que decide el alcance de una captura

Tres cosas limitan lo que se ve desde una posición, y ninguna es la potencia del atacante:

- **El canal donde esté el objetivo.** Una tarjeta escucha un canal a la vez. El salto de canal (*channel hopping*) da cobertura a costa de perder tramas: si el AP está en el canal 36 y la tarjeta va saltando, se pierde el *handshake* que ocurra mientras está en el 100.
- **La banda que soporte el chipset.** Una tarjeta de 2,4 GHz es ciega ante el 80 % del despliegue moderno. Con Wi-Fi 7 y MLO el problema se agrava: <mark style="background: #FFB86CA6;">un cliente puede estar hablando por 5 y 6 GHz a la vez, y una captura de una sola banda contiene una conversación incompleta</mark>.
- **El ancho de canal.** Capturar un canal de 20 MHz cuando el AP transmite en 160 MHz deja fuera las tramas que usen las sub-portadoras superiores.

Los detalles de qué tramas viajan por esos canales están en [[02 - Arquitectura 802.11 y la trama MAC]]. La parte operativa —qué tarjeta comprar, cómo poner el modo monitor y cómo fijar el canal— vive en [[04 - Interfaces, chipsets y drivers]] y [[05 - Modos de operación y modo monitor]].
