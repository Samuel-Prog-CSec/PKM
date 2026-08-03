---
tags:
  - Wi-Fi/WPS
  - Tipo/Deteccion
  - Pentesting/Explotacion
Descripción: "Qué registra un AP y un WIDS ante cada vector WPS, cómo se ordenan los ataques por ruido y qué controles recomendar"
Fecha de actualización: 2026-08-01
Nota previa: "[[10 - DoS contra WPS con MDK4]]"
Nota siguiente: "[[12 - Arsenal y estado de WPS en 2026]]"
Area: "[[WPS.base|WPS]]"
---
---

WPS deja un rastro distinto al del resto de ataques Wi-Fi: <mark style="background: #ADCCFFA6;">no son tramas forjadas sino **intercambios EAP legítimos que fallan**, y eso queda registrado en el propio AP</mark>, no sólo en un sensor externo. Un router doméstico apunta los intentos WPS fallidos aunque nadie esté vigilando el espectro.

# Qué se registra

## En el AP

Casi todo el equipamiento con WPS lleva su propio contador — es la base del bloqueo por intentos. En los que exponen registro:

```text
WPS: Enrollee failed authentication, PIN attempt 3/3
WPS: AP Setup Locked due to excessive PIN failures
hostapd: WPS-FAIL msg=8 config_error=0 reason=1 (Registrar failed)
```

<mark style="background: #FF5582A6;">Un `AP Setup Locked` en el log es evidencia directa de un ataque de fuerza bruta</mark>, con marca de tiempo y, en muchos firmwares, la MAC de origen. Es la prueba más limpia que puede encontrar un defensor.

## En un WIDS

| Vector | Firma |
| ------ | ----- |
| **Fuerza bruta online** | Decenas o cientos de asociaciones seguidas de intercambios EAP-WPS incompletos desde una misma MAC |
| **Pixie Dust** | **Una** asociación y un intercambio que se corta tras M3. Casi indistinguible de un cliente que abandona |
| **PIN nulo** | Un intercambio con PIN vacío. Firma específica si el WIDS inspecciona los atributos WPS |
| **Lista de PINs por defecto** | Intentos espaciados, cada uno desde una sesión nueva. Detectable por acumulación, no por ráfaga |
| **PBC** | Registro exitoso desde un dispositivo no inventariado. Genera un evento `WPS-SUCCESS` |
| **DoS con MDK4** | Miles de autenticaciones por segundo desde MAC aleatorias. Imposible de confundir |

## Lo que delata en cualquier caso

- **`reaver` no aleatoriza la MAC entre intentos** salvo que se le pida con `-M`. Once mil intentos desde la misma dirección son un único identificador para correlacionar todo el ataque.
- **El OUI del adaptador.** `00:c0:ca` es ALFA; un WIDS que vea ese prefijo intentando WPS no necesita más análisis.
- **La cadencia mecánica.** Un intento cada segundo exactamente, sin pausas humanas, durante horas.

# Orden de los vectores por ruido

```mermaid
graph LR
    A["Recon pasivo<br/>wash · airodump --wps"] --> B["Pixie Dust<br/>1 intercambio"]
    B --> C["PIN nulo<br/>1 intento"]
    C --> D["PINs por defecto<br/>decenas, espaciados"]
    D --> E["Fuerza bruta<br/>hasta 11.000"]
    E --> F["DoS con MDK4<br/>miles/segundo"]
    style A fill:#4a8,color:#fff
    style B fill:#8a4,color:#fff
    style E fill:#fa4
    style F fill:#ff5582,color:#fff
```

<mark style="background: #8000E1A6;">Ese orden es el mismo que el de eficacia esperada</mark>, lo cual es una coincidencia afortunada: lo más silencioso es también lo que más rápido resuelve cuando funciona. Ir directo a la fuerza bruta es peor por ambos criterios.

# Evasión

## No transmitir mientras no haga falta

El reconocimiento WPS completo —versión, modo, estado de bloqueo, fabricante y modelo— <mark style="background: #FFB8EBA6;">se obtiene sólo de los beacons, sin emitir nada</mark>. `wash -i mon0` y `airodump-ng --wps` son pasivos. Toda la fase de decisión ocurre sin dejar rastro.

## Un intercambio, no once mil

Es la evasión de verdad. Pixie Dust y el PIN nulo consumen un intercambio cada uno; una lista de PINs por defecto, unas decenas. Frente a eso, la fuerza bruta completa es un evento imposible de ocultar. **Elegir bien el vector evade más que cualquier ajuste de temporización.**

## Rotar la identidad

Reaver lo trae integrado, y es la forma cómoda de hacerlo — cambia el último dígito de la MAC **en cada intento**, sin parar el ataque:

```shell-session
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -M -vv
```

<mark style="background: #8000E1A6;">`-M, --mac-changer` ataca las dos cosas a la vez</mark>: rompe la correlación en el WIDS y reinicia los contadores de bloqueo de los AP que cuentan por MAC de origen — ver [[04 - APs con bloqueo y rate limiting]].

Para un cambio manual entre bloques de intentos:

```shell-session
$ sudo ip link set mon0 down
$ sudo macchanger -a mon0        # MAC aleatoria con OUI plausible
$ sudo ip link set mon0 up
```

`macchanger -a` mantiene un OUI de fabricante real, a diferencia de `-r`, que genera un prefijo que puede no corresponder a nadie — y un OUI inexistente es tan llamativo como el de fábrica del adaptador.

## Parecer un cliente normal

```shell-session
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -w -E -vv
```

| Opción | Efecto |
| ------ | ------ |
| `-w, --win7` | Se hace pasar por un *registrar* de **Windows 7**: los atributos WPS que envía coinciden con los de un cliente doméstico real |
| `-E, --eap-terminate` | Cierra cada sesión con un `EAP FAIL` limpio en lugar de dejarla colgada |

<mark style="background: #FFB86CA6;">Los dos reducen la anomalía del intercambio</mark>. `-w` cambia la huella de los atributos —un WIDS que perfile registrars conocidos ve un Windows 7 en lugar de una herramienta— y `-E` evita el rastro de decenas de sesiones EAP abandonadas a medias, que es un patrón sin equivalente legítimo. Existen para compatibilidad con APs quisquillosos, pero el efecto secundario en sigilo es real.

## Espaciar y aprovechar el ruido ajeno

```shell-session
$ sudo reaver -i mon0 -b <BSSID> -c 1 -d 30 -r 5:120 --max-attempts=1 -p <PIN>
```

Treinta segundos entre intentos y dos minutos de pausa cada cinco. Diluye la cadencia en el tráfico normal y evita el bloqueo. Y en horario de oficina, con decenas de dispositivos asociándose y desasociándose, unos pocos intentos WPS espaciados pasan mucho más desapercibidos que a las tres de la madrugada.

## Lo que no evade nada

> [!warning]+ Tres falsas evasiones
> **Bajar la potencia** no oculta el ataque: el AP tiene que recibir las tramas para responder, así que sigue registrándolas. Sólo dificulta la triangulación.
>
> **Cambiar de herramienta** —de reaver a bully— no cambia la firma: el patrón detectable es la secuencia de intercambios EAP fallidos, no la implementación que los genera.
>
> **El DoS para desbloquear** es lo contrario de la evasión. Cambia una alerta de seguridad por una alerta de disponibilidad, que además llega a más gente.

# Detección desde el lado defensivo

Lo que recomendar en el informe, por orden de eficacia:

1. **Desactivar WPS.** Elimina la superficie entera y hace irrelevante todo lo demás. Verificarlo después con `wash`, no fiarse del interruptor de la interfaz web.
2. **Alertar sobre `WPS-FAIL` y `AP Setup Locked`** en el syslog del AP o del controlador. Son eventos raros en operación normal: cualquier ráfaga es un ataque.
3. **Alertar sobre `WPS-SUCCESS`.** Un registro correcto desde un dispositivo no inventariado es un compromiso, no un evento de rutina. Es la única detección que cubre PBC y Pixie Dust, que apenas generan fallos.
4. **Inventariar qué APs tienen WPS.** En despliegues grandes suele haber equipos de sucursal o repetidores con el firmware de serie que nadie revisó.

> [!important]+ El punto ciego de la detección basada en fallos
> Casi toda la detección de WPS se basa en **contar intentos fallidos**. <mark style="background: #FFB86CA6;">Pixie Dust no falla nunca: hace un intercambio, obtiene los hashes y calcula el PIN fuera de línea</mark>. Cuando vuelve, lo hace con el PIN correcto y se registra a la primera. Para el AP es un cliente legítimo. Ése es el argumento que cierra la discusión de "tenemos bloqueo por intentos, estamos cubiertos": no lo están.

Las herramientas de todo el módulo y el estado del ecosistema están en [[12 - Arsenal y estado de WPS en 2026]].
