# Omarchy

Guía de configuración y afinado de [Omarchy](https://omarchy.org/) (Arch + Hyprland). Objetivo: sistema estable, rápido y que aproveche el hardware, para uso mixto — gaming, desarrollo, bug bounty, ofimática y vídeo.

**Referencias de la comunidad:**
- https://bango29.com/customizing-my-omarchy/
- https://github.com/basecamp/omarchy/discussions/758
- https://www.piyushmehta.com/blog/macos-to-arch-linux-omarchy-developer-productivity
- Ax-Shell (barra alternativa): https://www.youtube.com/watch?v=SvDExqzLtJM

> [!info]+ Las dos máquinas de esta guía
> Los ajustes divergen bastante entre las dos, así que cada apartado marca a cuál aplica.
>
> | | 🖥️ **Sobremesa** | 💻 **Portátil** (HP Pavilion Gaming 16) |
> | - | - | - |
> | CPU | Ryzen 7 7800X3D (8c/16t) | Core i7-10750H (6c/12t) |
> | GPU | RTX 5070 Ti (Blackwell, 16 GB) | GTX 1650 Ti Mobile (4 GB) + iGPU Intel |
> | RAM | 64 GB DDR5 | 16 GB DDR4 |
> | Disco | SSD SATA (Omarchy) + NVMe 2 TB | NVMe 1 TB |
> | Pantallas | BenQ RD280U 3840x2560 (DP, centro) + 1080p 144 Hz (HDMI, izquierda) | eDP interna + externo por HDMI |
> | GPU híbrida | No | **Sí** (`omarchy hw hybrid gpu` → true) |

## Cómo leer esta guía

**El uso es el mismo en las dos máquinas**: gaming, desarrollo, bug bounty (a menudo en VM), ofimática y vídeo. Así que <mark style="background: #8000E1A6;">las divergencias de configuración no vienen del uso, vienen del presupuesto de recursos</mark>. Son tres, y explican por sí solas casi todos los "esto solo en sobremesa" que aparecen abajo:

| Causa de divergencia | Consecuencia práctica |
| - | - |
| **RAM: 64 GB vs 16 GB** | En 🖥️ puedes compilar en RAM y levantar un laboratorio de varias VM a la vez. En 💻 la RAM es el recurso escaso: `zram` bien afinado pasa de detalle a necesidad, y compilar en `tmpfs` es contraproducente |
| **VRAM: 16 GB vs 4 GB** | En 💻 recuperar VRAM del compositor es crítico (§3) y el escalado fraccional se paga; en 🖥️ ninguna de las dos cosas se nota |
| **💻 es híbrida y tiene batería** | Cambia qué GPU renderiza el escritorio, obliga a cuidar suspend/resume, y su ventilador de GPU **no es controlable** por software (§9) |

Qué secciones te importan según lo que vayas a hacer:

| Uso | Secciones |
| - | - |
| **Gaming** | §7 completa · §3 (VRAM, driver) · §6 (planificador, EPP) · §2 (escala y Hz) · §9 (temperaturas) |
| **Desarrollo** | §5 (compilación, TRIM) · §11 (Electron y editores) · §2 (superficie de pantalla) |
| **Bug bounty** | §8 (VM y contenedores) · §5 (RAM y disco para las VM) |
| **Ofimática y vídeo** | §11 (aceleración de vídeo) · §2 (escalado) · §4 (teclado) |
| **Que simplemente no dé problemas** | §1 · §3 (suspend, VRAM) · §5 (TRIM) |

---

# 1. Antes de empezar — verificaciones

## Recargar configuración: quién sí y quién no

<mark style="background: #ADCCFFA6;">Hyprland recarga solo al guardar cualquiera de sus `.conf`</mark>; no hace falta reiniciar. El resto de componentes sí necesitan un empujón explícito:

```shell-session
$ hyprctl reload          # forzar recarga
$ hyprctl configerrors    # SIEMPRE tras editar: si sale vacío, la config es válida
$ omarchy restart waybar  # waybar NO auto-recarga
$ omarchy restart walker
$ omarchy restart terminal
```

> [!warning]+ `hyprctl configerrors` vacío no significa "hizo lo que pedí"
> Hyprland avisa de errores de *sintaxis*, pero corrige en silencio valores imposibles. Ejemplo real: una escala de monitor inválida se redondea a la más cercana válida sin decir nada, y `configerrors` sale limpio. Verifica siempre el efecto con `hyprctl monitors`, no solo la ausencia de errores.

## Actualizar el sistema

```shell-session
$ omarchy update          # Omarchy + paquetes del sistema
$ sudo pacman -Syu        # equivalente a pelo
```

> [!fail]+ Nunca `sudo pacman -Sy` a secas
> `-Sy` sincroniza la base de datos **sin** actualizar los paquetes. El siguiente `pacman -S <algo>` instalará una versión nueva que se enlaza contra librerías que ya no existen en tu disco: es el *partial upgrade*, y <mark style="background: #FFB86CA6;">la causa nº1 de sistemas Arch rotos</mark>. Solo existen dos formas correctas: `-Syu` o `omarchy update`.

## Estado de partida

```shell-session
$ omarchy version
$ hyprctl version
$ omarchy debug --no-sudo --print    # los flags evitan que se cuelgue pidiendo sudo
$ hyprctl monitors                   # nombres de puerto, modos, escala REAL aplicada
$ lspci -d ::03xx                    # GPUs presentes y su dirección PCI
```

> [!important]+ Antes de configurar a mano, comprueba si Omarchy ya lo hizo
> Omarchy no es Arch pelado: su instalador ya resuelve driver NVIDIA, `zram`, `gamemode`, hibernación y bastante más. Media guía de internet sobre "optimizar Arch" está ya aplicada en tu sistema, y aplicarla otra vez solo añade ruido y configuración duplicada. Cada apartado de aquí indica qué es **verificar** y qué es **añadir**.

---

# 2. Hyprland — monitores y escalado

Fichero: `~/.config/hypr/monitors.conf`. Formato: `monitor = <puerto>, <resolución>@<Hz>, <posición>, <escala>`.

## Las tres reglas que rompen todas las configuraciones

**1. Los nombres de puerto no son fiables a ciegas.** Verifícalos con `hyprctl monitors all` (incluye los inactivos). En una GPU con varios DP verás `DP-1`, `DP-2`, `DP-3`… y el reparto cambia según dónde enchufes. Alternativa robusta: usar la **descripción** del monitor, que viaja con el panel y no con el cable:

```shell-session
$ hyprctl monitors | grep description
	description: BNQ BenQ RD280U G7R0497201Q
```

Se usa con prefijo `desc:` y **sin** el `(puerto)` final si aparece: `desc:BNQ BenQ RD280U`.

**2. La escala tiene que dividir la resolución en píxeles enteros.** Del wiki de Hyprland: *"A valid scale must divide your resolution cleanly (without decimals)"*. Con el BenQ de 3840x2560:

| Escala | Resultado lógico | ¿Válida? |
| - | - | - |
| 2 | 1920x1280 | ✅ escala **entera**, la más barata en GPU |
| 2,4 | 1600x**1066,67** | ❌ Hyprland la sube a 2,5 en silencio |
| 2,5 | 1536x1024 | ✅ **la elegida** — interfaz más grande y legible |
| 3 | 1280x**853,3** | ❌ |

<mark style="background: #FF5582A6;">Si pides 2,4 acabas en 2,5 sin que nada te avise</mark> — compruébalo con `hyprctl monitors` (campo `scale:`).

**Decisión: 2,5**, por legibilidad. Pero es la palanca a tocar primero si la GPU va justa: 2 es una escala **entera**, y el escalado fraccional obliga a renderizar a una resolución mayor y reducirla después. La página de Performance del wiki lo dice sin rodeos: si notas lag o uso alto de GPU en el escritorio, prueba escalas enteras (`1` o `2`). En el sobremesa con la 5070 Ti da igual; si algún día conectas este monitor al portátil, bájalo a 2.

**3. La posición se mide en el espacio lógico, ya escalado.** El BenQ a escala 2,5 ocupa **1536x1024**, no 3840x2560. Y el eje X crece hacia la derecha, así que **a la izquierda se va con valores negativos**. Y el eje Y es invertido: negativo = arriba.

## 🖥️ Sobremesa — BenQ 4K+ en el centro, 1080p 144 Hz a la izquierda

```ini
# Principal: BenQ RD280U por DP.
# Escala 2.5 (2.4 es INVÁLIDA: 2560/2.4 no da píxeles enteros y Hyprland la sube a 2.5).
# Si la GPU va justa o el escritorio se siente lento -> bajar a 2 (escala entera, 1920x1280
# lógicos): menos trabajo de escalado, más superficie, interfaz más pequeña.
monitor = desc:BNQ BenQ RD280U, 3840x2560@60, 0x0, 2.5

# Secundario: 1080p 144 Hz por HDMI, a la IZQUIERDA.
# auto-center-left calcula la X negativa y lo centra en vertical (evita el salto
# de ratón que deja alinearlos por el borde superior)
monitor = HDMI-A-1, 1920x1080@144, auto-center-left, 1

# Workspaces fijos por monitor
workspace = 1, monitor:desc:BNQ BenQ RD280U, default:true
workspace = 6, monitor:HDMI-A-1, default:true
```

> [!warning]+ No pongas `GDK_SCALE`
> `env = GDK_SCALE,2` es una variable de X11/GTK3: fuerza a las apps GTK a escalar x2 **por su cuenta**, encima del escalado que ya hace el compositor. Con dos monitores de densidad distinta el resultado es tamaños desajustados en el 4K y todo gigante en el 1080p. En Wayland las apps negocian su escala por monitor vía `fractional-scale-v1` y no necesitan ayuda. Omarchy la deja comentada y solo tiene sentido en un setup de un único monitor "retina" a 2x exactos.

Posiciones manuales, si prefieres no depender de `auto-*`: con el BenQ a escala 2,5 en `0x0`, el secundario va en `-1920x0` (a su izquierda, alineado arriba) o `-1920x-28` (centrado en vertical: (1080−1024)/2 = 28 px de offset).

## 💻 Portátil

```ini
# Pantalla interna + externo a la derecha. `preferred` deja que el EDID decida
monitor = eDP-1, preferred, 0x0, 1.6
monitor = , preferred, auto, 1      # regla comodín para cualquier externo
```

> [!info]+ XWayland y escalado
> Omarchy ya trae `xwayland { force_zero_scaling = true }` en sus defaults. Eso evita que las apps X11 salgan borrosas al escalarlas, a cambio de que se vean pequeñas en un monitor escalado. Para juegos X11/Proton la solución no es pelearse con esto: es lanzarlos dentro de `gamescope` (ver §7).

> [!important]+ Aviso de futuro: `hyprlang` está deprecado
> Desde Hyprland **0.55** el wiki oficial documenta todo en **Lua** (`hl.monitor({ output = "DP-1", ... })`, `hl.env(...)`) y marca los `.conf` de toda la vida como sintaxis legada. Omarchy sigue usando `hyprlang` y funciona perfecto, así que **no reescribas nada a Lua por tu cuenta** — esa migración la hará Omarchy. Pero cuando consultes el wiki verás ejemplos que no se parecen a tus ficheros: la traducción es mecánica (`monitor = A, B, C, D` → `hl.monitor({ output = "A", mode = "B", position = "C", scale = D })`).

---

# 3. NVIDIA

## Lo que Omarchy ya hizo (verificar, no repetir)

Su instalador (`~/.local/share/omarchy/install/config/hardware/nvidia.sh`) detecta la GPU, elige el driver correcto y deja el sistema configurado. Esto es lo que ya está hecho y cómo comprobarlo:

| Qué | Cómo verificarlo |
| - | - |
| Driver + headers del kernel | `pacman -Qs nvidia` → debe salir `nvidia-open-dkms` |
| `modeset` activo | `cat /sys/module/nvidia_drm/parameters/modeset` → `Y` |
| Framebuffer del driver | `cat /sys/module/nvidia_drm/parameters/fbdev` → `Y` |
| Carga temprana de módulos | `cat /etc/mkinitcpio.conf.d/nvidia.conf` |
| Variables de entorno | `cat ~/.config/hypr/envs.conf` |

> [!success]+ `modeset=1` y `fbdev=1` ya no hay que escribirlos
> `modeset` está activado por defecto desde `nvidia-utils` **560.35.03-5** (ArchWiki), y `fbdev` desde el driver **570.86.16** cuando `modeset` está puesto (wiki de Hyprland). Escribirlos a mano en `/etc/modprobe.d/nvidia.conf` es inofensivo, pero es ruido: hoy basta con verificar que ambos devuelven `Y`.

## El driver correcto: `nvidia-open-dkms`, no `nvidia-dkms`

Los módulos de kernel **abiertos** no son una opción alternativa, son el camino principal:

- Wiki de Hyprland: *"For those on the Nvidia 50xx series of graphics cards (5090, 5080, etc) or newer, the open source kernel modules are **REQUIRED**"*.
- ArchWiki: para **Blackwell** (`GBXXX`) y superior la única entrada de la tabla es `nvidia-open` / `nvidia-open-dkms`; **no existe variante propietaria** que soporte esa generación.
- Para Turing y Ampere (GTX 16xx, RTX 20xx/30xx) NVIDIA también los recomienda.

<mark style="background: #8000E1A6;">Es decir: para la RTX 5070 Ti no hay elección, y para la GTX 1650 Ti es igualmente lo recomendado</mark>. Omarchy lo resuelve solo — su detector `omarchy-hw-nvidia-gsp` casa el patrón `RTX [2-5][0-9]{3}` y `GTX 16[0-9]{2}` y tira de `nvidia-open-dkms`. Solo las Maxwell/Pascal/Volta caen al propietario legado (`nvidia-580xx-dkms`).

## Variables de entorno: mínimas, y con el `source` que Omarchy no pone

Van en `~/.config/hypr/envs.conf` (donde las escribe el instalador), **no** al final de `hyprland.conf`. El wiki de Hyprland pide exactamente dos, más una tercera para VA-API:

```ini
# ~/.config/hypr/envs.conf
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct          # solo Turing+ (GSP); en Maxwell/Pascal usar 'egl'
```

> [!fail]+ Bug de Omarchy 3.8.3: ese fichero no se carga nunca
> Verificado en este sistema el 2026-07-25. El instalador de NVIDIA (`install/config/hardware/nvidia.sh`) **escribe** las variables del driver en `~/.config/hypr/envs.conf`… pero <mark style="background: #FF5582A6;">la plantilla de `hyprland.conf` de Omarchy no sourcea ese fichero</mark>. Sourcea el `envs.conf` de **sus propios defaults** (`~/.local/share/omarchy/default/hypr/envs.conf`), que es otro fichero distinto:
>
> ```shell-session
> $ grep -n "envs.conf" ~/.config/hypr/hyprland.conf
> 9:source = ~/.local/share/omarchy/default/hypr/envs.conf     # ← el de Omarchy
> $ grep -rn "config/hypr/envs" ~/.local/share/omarchy/default/hypr/
> (nada)                                                       # ← el tuyo, huérfano
> ```
>
> No es config heredada de una versión vieja: la plantilla actual (`~/.local/share/omarchy/config/hypr/hyprland.conf`) tiene exactamente la misma lista de `source`. **Consecuencia: en cualquier Omarchy con NVIDIA, `NVD_BACKEND=direct` no está aplicado** — o sea, la aceleración de vídeo VA-API cae al backend EGL en vez del directo. El arreglo es una línea en el bloque de configuración propia:
>
> ```ini
> # ~/.config/hypr/hyprland.conf, junto a los demás source de ~/.config/hypr/
> source = ~/.config/hypr/envs.conf
> ```

**Cómo comprobar qué variables llegan de verdad** (y las dos formas equivocadas de intentarlo):

```shell-session
$ printenv | grep -E "NVD_BACKEND|LIBVA_DRIVER_NAME|AQ_DRM_DEVICES"
```

Basta con ejecutarlo en una terminal abierta desde Hyprland, porque hereda su entorno. Lo que **no** funciona:

- **`cat /proc/$(pgrep -x Hyprland)/environ`** → sale vacío de esas variables. Las directivas `env` no modifican el entorno del compositor: se exportan a los procesos que él lanza. El propio Hyprland conserva el entorno con el que lo arrancó `uwsm`.
- **Recargar y volver a mirar** → `hyprctl reload` **añade** variables nuevas, pero no puede *quitar* las que ya se exportaron. Si borras una `env` del fichero, seguirá en el entorno hasta que reinicies la sesión. Para ver el efecto real de un borrado hay que cerrar sesión.

Lo que **sobra** y suele arrastrarse de guías viejas: `GBM_BACKEND` (ya no lo lista el wiki, y en GPU híbrida forzarlo globalmente afecta también a la iGPU) y `XDG_SESSION_TYPE` (lo pone Omarchy en sus defaults). Tenerlas repetidas en `hyprland.conf` *y* en `envs.conf` no rompe nada, pero cuando algo falle no sabrás cuál gana.

## Elegir la GPU: `AQ_DRM_DEVICES` con symlink estable

Primero identifica la GPU cruzando dos comandos. Busca el `Bus-Id` de `nvidia-smi` (p. ej. `00000000:01:00.0`) y localiza ese mismo `01:00.0` en las rutas PCI:

```shell-session
$ nvidia-smi --query-gpu=name,pci.bus_id --format=csv
name, pci.bus_id
NVIDIA GeForce GTX 1650 Ti, 00000000:01:00.0

$ ls -l /dev/dri/by-path/
pci-0000:00:02.0-card -> ../card2      # iGPU Intel
pci-0000:01:00.0-card -> ../card1      # ← la NVIDIA
```

> [!fail]+ No escribas `card1` en la configuración
> Wiki de Hyprland: *"Do not use the `card1` symlink indicated here. It is dynamically assigned at boot and is subject to frequent change"*. <mark style="background: #FF5582A6;">Un día arrancas y `card1` es la integrada</mark> — y el escritorio va en la GPU equivocada, o directamente no arranca. Y `by-path` tampoco sirve como sustituto directo: los `:` de la ruta PCI colisionan con el separador `:` de la propia variable.

La solución oficial es una regla `udev` que cree un nombre propio y estable, atado al **bus PCI** (que no cambia) en vez de al número de card (que sí). Una entrada por GPU:

```sh
# /etc/udev/rules.d/90-gpu-stable-names.rules
KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
KERNEL=="card*", KERNELS=="0000:00:02.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/intel-igpu"
```

Los identificadores se sacan **por driver**, que es más fiable que fiarse de los números de card:

```shell-session
$ for c in /sys/class/drm/card?/; do \
    printf '%-8s driver=%-8s bus=%s\n' "$(basename $c)" \
      "$(basename $(readlink -f $c/device/driver))" \
      "$(basename $(readlink -f $c/device))"; done
card1    driver=nvidia   bus=0000:01:00.0
card2    driver=i915     bus=0000:00:02.0
```

```shell-session
$ sudo udevadm control --reload
$ sudo udevadm trigger --subsystem-match=drm
$ ls -l /dev/dri/nvidia-dgpu /dev/dri/intel-igpu
```

> [!warning]+ Verifica los symlinks ANTES de apuntar `AQ_DRM_DEVICES` a ellos
> Si la variable apunta a un symlink que no existe, Hyprland arranca sin GPU declarada. Y no basta con ver que el enlace existe: comprueba que resuelve **al bus correcto**, porque una regla con el identificador mal escrito crea el symlink apuntando a la GPU equivocada, que es peor que no tenerlo.
>
> ```shell-session
> $ basename $(readlink -f /sys/class/drm/$(readlink /dev/dri/nvidia-dgpu)/device)
> 0000:01:00.0        ← debe coincidir con el bus de la NVIDIA
> ```
>
> Solo entonces:
> ```ini
> env = AQ_DRM_DEVICES,/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu
> ```
> El orden marca la prioridad: la primera es el renderizador primario. Ambas deben estar en la lista si hay monitores colgando de las dos.

**🖥️ Sobremesa** — una sola GPU en uso, la fuerzas y listo:

```ini
env = AQ_DRM_DEVICES,/dev/dri/nvidia-dgpu
```

**💻 Portátil** — aquí la receta se invierte:

> [!important]+ En portátil, el consejo por defecto es la iGPU — pero verifica antes
> Wiki de Hyprland: *"It is generally a good idea for laptops to use the integrated GPU as the primary renderer as this preserves battery life and is practically indistinguishable from using the dedicated GPU on modern systems in most cases"*.
>
> **Ese consejo asume que las salidas de vídeo cuelgan del iGPU, y en muchos portátiles gaming no es así.** Antes de aplicarlo hay que comprobar qué GPU controla cada conector:
>
> ```shell-session
> $ for c in /sys/class/drm/card?/; do card=$(basename $c); \
>     echo "$card -> $(basename $(readlink -f $c/device/driver))"; \
>     for con in /sys/class/drm/${card}-*/; do \
>       echo "   $(basename $con | sed "s/${card}-//") $(cat $con/status)"; done; done
> card1 -> nvidia
>    DP-1 disconnected
>    HDMI-A-1 connected      ← el monitor externo cuelga de la NVIDIA
> card2 -> i915
>    eDP-1 connected         ← solo la pantalla interna
> ```
>
> <mark style="background: #FF5582A6;">Si tu monitor de trabajo está cableado a la dGPU, moverlo al iGPU obliga a copiar cada frame entre GPUs por PCIe</mark>. Con un panel de 3840x2560 son 9,8 Mpx ≈ 39 MB por frame: casi **2 GB/s** de copias sostenidas a 50 Hz. Es el escenario del que avisa el propio wiki: *"This might slow down rendering to secondary monitors and make Hyprland a bit laggy on them"* — solo que ahí el "secundario" es tu pantalla principal.
>
> **Y mide el consumo antes de asumir el argumento de la batería:**
>
> ```shell-session
> $ nvidia-smi --query-gpu=pstate,power.draw,temperature.gpu --format=csv
> P8, 4.25 W, 51                    ← componiendo el escritorio, de un límite de 50 W
> ```
>
> `P8` es el estado de reposo más bajo del driver. Una dGPU moderna **sí baja de estado** aunque sea el renderizador primario: el ahorro real de moverse al iGPU son unos pocos vatios, no la mitad de la batería. Con el portátil enchufado y monitor externo —el uso habitual— el argumento desaparece del todo.
>
> **Criterio**: aplica el consejo del wiki si las salidas cuelgan del iGPU, **o** si usas el portátil de forma habitual sin monitor externo y con batería. Si tu pantalla principal cuelga de la dGPU y trabajas enchufado, deja el escritorio en la NVIDIA: pagarías copias entre GPUs para ahorrar vatios que no estás gastando.
>
> Dos apuntes que siguen valiendo en cualquier caso: **(a)** un monitor cableado a una card debe aparecer en `AQ_DRM_DEVICES` aunque no sea la primaria — el orden marca prioridad, no disponibilidad: `env = AQ_DRM_DEVICES,/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu`. **(b)** si aparecen fallos raros de multi-monitor, la vía de escape del wiki es `env = AQ_FORCE_LINEAR_BLIT,0`.

## Carga temprana de módulos (early KMS)

Omarchy ya lo configura, pero en **GPU híbrida hay un orden que importa**:

```ini
# /etc/mkinitcpio.conf.d/nvidia.conf  →  i915 PRIMERO en sistemas Intel + NVIDIA
MODULES+=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

```shell-session
$ sudo mkinitcpio -P
```

> [!warning]+ Electron colgado un minuto tras arrancar
> Wiki de Hyprland: *"Electron or Chromium-based apps can stall for up to a minute after boot on hybrid graphics systems with an Intel iGPU and an Nvidia dGPU. This can be fixed by loading the `i915` module **before** the Nvidia ones"*. Si abres Obsidian, VS Code o Chromium justo después de encender y se quedan en blanco un rato largo, esto es la causa. Solo aplica al 💻 portátil.

> [!fail]+ Early KMS rompe la hibernación — hay que elegir
> Los dos wikis lo avisan: cargar los módulos NVIDIA en el initramfs hace que **el resume de hibernación falle** (el sistema arranca normal en vez de restaurar la sesión), porque la preservación de VRAM está activa por defecto. No es un bug que se pueda parchear: es una incompatibilidad entre dos cosas que quieren gestionar la VRAM en el arranque.

**Decisión para las dos máquinas: early KMS, sin hibernación.** El razonamiento:

- **La hibernación cuesta disco a lo bruto**: el swapfile debe ser ≥ RAM. En 🖥️ son **64 GB** de SSD dedicados a algo que usarías una vez al mes; en 💻 son 16 GB.
- **Apila puntos de fallo**: hibernar sobre LUKS + Btrfs + NVIDIA propietario en Wayland es la combinación con más historial de resumes corruptos. Y un resume fallido no es "vuelve a arrancar": puede dejar el sistema de ficheros inconsistente si el kernel restaura estado a medias.
- **Lo que ganas es poco**: desde NVMe cifrado el arranque completo son segundos, y para dejar el portátil cerrado un rato ya tienes suspend-to-RAM, que aguanta días.
- **Y ya estás de facto en este lado**: el early KMS está activo (lo puso Omarchy) y la hibernación no funciona.

Estado real de este portátil ahora mismo — hibernación **configurada a un tercio**:

```shell-session
$ omarchy hibernation available; echo "exit=$?"
exit=1                                    # no disponible
$ ls /swap                                # el swapfile que exige el setup
NO existe
$ ls /etc/mkinitcpio.conf.d/omarchy_resume.conf
NO existe                                 # falta el hook `resume` en el initramfs
$ cat /etc/limine-entry-tool.d/resume.conf
KERNEL_CMDLINE[default]+=" resume=/dev/mapper/root resume_offset=3818283"   # ← esto SÍ está
```

O sea: el kernel arranca cada vez buscando una imagen de hibernación en un offset que apunta a un fichero que no existe. **Es inofensivo** (no la encuentra y sigue arrancando), pero es basura de configuración que confunde al diagnosticar.

> [!warning]+ `omarchy hibernation remove` NO limpia este estado
> Lo lógico sería `omarchy hibernation remove`, pero **sale sin hacer nada**. Su primera comprobación es el hook de mkinitcpio, no el drop-in de Limine:
>
> ```bash
> if [[ ! -f /etc/mkinitcpio.conf.d/omarchy_resume.conf ]] || ! grep -q "^HOOKS+=(resume)$" ...; then
>   echo "Hibernation is not set up"; exit 0
> fi
> ```
>
> Un setup que dejó el `resume=` en la línea de arranque **pero no el hook** cae en un punto ciego del script: se declara "no configurado" y no toca nada. Hay que limpiarlo a mano, y el `resume=` vive en **dos** sitios:
>
> ```shell-session
> $ sudo rm /etc/limine-entry-tool.d/resume.conf
> $ sudo sed -i '/resume=/d' /etc/default/limine
> $ sudo limine-mkinitcpio
> ```

> [!fail]+ Cuidado al editar `/etc/default/limine`
> Ese fichero contiene el `cryptdevice=` con el que arranca el sistema. Un `sed` mal puesto = **sistema que no arranca**. Backup y verificación obligatorias antes de regenerar:
>
> ```shell-session
> $ sudo cp /etc/default/limine /root/limine.bak
> $ sudo sed -i '/resume=/d' /etc/default/limine
> $ grep -c KERNEL_CMDLINE /etc/default/limine        # deben quedar 2 líneas
> $ grep -q 'cryptdevice=PARTUUID=' /etc/default/limine && echo "cryptdevice OK"
> $ grep -q 'rootflags=subvol=@'    /etc/default/limine && echo "rootflags OK"
> ```
>
> Solo si las tres comprobaciones pasan, regenerar. Y **agrupa los cambios de línea de arranque**: si vas a añadir `NVreg_PreserveVideoMemoryAllocations` y a quitar el `resume=`, haz las dos ediciones y **una sola** `limine-mkinitcpio` al final.

> [!info]+ Si algún día quieres hibernación de verdad
> `omarchy hibernation setup` lo hace todo bien: crea el subvolumen Btrfs `/swap` con un swapfile del tamaño de la RAM, calcula el `resume_offset` con `btrfs inspect-internal map-swapfile`, añade `HOOKS+=(resume)` y regenera la UKI. Pero **entonces hay que quitar el early KMS** (borrar `/etc/mkinitcpio.conf.d/nvidia.conf` y `sudo mkinitcpio -P`), o el resume no funcionará.
>
> Y ojo con un detalle que engaña: **zram no cuenta como swap para hibernar**. El propio script de Omarchy lo excluye explícitamente (`awk '!/Filename|zram/'`), porque hibernar sobre RAM comprimida que vive en la RAM que quieres volcar no tiene sentido. Con solo zram activo, `omarchy hibernation available` siempre dirá que no.

## Suspender y despertar sin corrupción

Wayland sufre más que X con los defaults de NVIDIA: al suspender, el driver descarta el contenido de la VRAM salvo que se le diga lo contrario, y al despertar aparecen ventanas en negro, texturas corruptas o directamente una sesión muerta. La opción que lo arregla:

```ini
# /etc/limine-entry-tool.d/nvidia.conf
KERNEL_CMDLINE[default]+=" nvidia.NVreg_PreserveVideoMemoryAllocations=1"
```

```shell-session
$ sudo limine-mkinitcpio      # imprescindible: la cmdline va dentro de la UKI (ver §5)
$ sudo systemctl enable nvidia-suspend.service nvidia-resume.service
```

No hay que arrancar los servicios: systemd los invoca cuando toca. **`nvidia-hibernate.service` solo hace falta si hibernas** — con la decisión de arriba (early KMS, sin hibernación) puedes dejarlo fuera; habilitarlo tampoco molesta.

Esto aplica sobre todo al 💻 portátil, donde suspendes a diario. Ojo con el compromiso: preservar la VRAM significa **volcarla a RAM al suspender**, así que suspender y despertar tardan un poco más — el precio de que la sesión sobreviva.

## Recuperar VRAM: el perfil que casi nadie aplica

Los compositores Wayland retienen una cantidad absurda de VRAM sin un perfil de aplicación específico. El ArchWiki documenta recuperar **~2,5 GiB** en niri con este ajuste:

```json
// /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json
{
  "rules": [
    { "pattern": { "feature": "procname", "matches": "Hyprland" },
      "profile": "Limit Free Buffer Pool On Wayland Compositors" }
  ],
  "profiles": [
    { "name": "Limit Free Buffer Pool On Wayland Compositors",
      "settings": [ { "key": "GLVidHeapReuseRatio", "value": 0 } ] }
  ]
}
```

Mide antes y después (hay que reiniciar la sesión):

```shell-session
$ nvidia-smi --query-gpu=memory.used,memory.total --format=csv
memory.used [MiB], memory.total [MiB]
1535 MiB, 4096 MiB          # ← escritorio en reposo, sin perfil aplicado
```

<mark style="background: #FF5582A6;">1,5 GB de 4 GB perdidos en reposo</mark>: en el 💻 portátil eso es la diferencia entre que un juego quepa en VRAM o vaya a tirones. En el 🖥️ sobremesa con 16 GB es menos dramático, pero sigue siendo memoria gratis. **Contra**: `0` es el valor más agresivo y puede costar algo de latencia al reasignar buffers; si notas microtirones al abrir ventanas, prueba `0.4`.

## Modo de persistencia

```shell-session
$ sudo systemctl enable --now nvidia-persistenced
```

> [!info]+ Qué hace realmente (y qué no)
> No "evita que la GPU entre en suspensión profunda": mantiene el estado del driver inicializado **cuando ningún cliente está usando la GPU**. Su caso de uso real son servidores headless con CUDA, donde entre trabajos el driver se descargaría y habría que reinicializar. En un escritorio con Hyprland renderizando siempre hay cliente, así que su efecto práctico aquí es **nulo**. No molesta, pero no esperes rendimiento de él.

---

# 4. Input — teclado y ratón

Fichero: `~/.config/hypr/input.conf`.

```ini
input {
  kb_layout = es
  kb_options = compose:caps      # el default de Omarchy; dejarlo VACÍO lo desactiva

  repeat_rate = 40               # teclas/segundo al mantener pulsado
  repeat_delay = 250             # ms antes de empezar a repetir

  numlock_by_default = true

  sensitivity = 0                # escala de velocidad (-1.0 a 1.0). NO desactiva aceleración
  accel_profile = flat           # ESTO es lo que desactiva la aceleración del ratón

  follow_mouse = 1

  # 💻 Solo portátil — en sobremesa este bloque es código muerto
  touchpad {
    natural_scroll = true
    clickfinger_behavior = true  # click con dos dedos = botón derecho
    scroll_factor = 0.4
    disable_while_typing = true
    tap-to-click = true
  }
}
```

> [!warning]+ `sensitivity = 0` no significa "sin aceleración"
> Es el error de configuración más repetido en Hyprland. `sensitivity` solo multiplica la velocidad del puntero; el **perfil** de aceleración sigue siendo `adaptive` por defecto, que acelera según la rapidez del movimiento. Para gaming, o para cualquier trabajo de precisión, hace falta `accel_profile = flat`: mismo desplazamiento físico → mismo desplazamiento en pantalla, siempre. La diferencia se nota inmediatamente al apuntar.

Reglas de ventana relacionadas — ajustar la velocidad de scroll del touchpad por aplicación. **Verifica la clase real** antes de copiarla, porque una regla que no casa con nada falla en silencio:

```shell-session
$ hyprctl clients | grep class
```

```ini
# Ejemplo con Ghostty. Si tu terminal es Alacritty, esta regla NO hace nada
windowrule = match:class com.mitchellh.ghostty, scroll_touchpad 0.2
```

Gestos del touchpad (💻), comentados por defecto en Omarchy:

```ini
gesture = 3, horizontal, workspace
```

---

# 5. Memoria, disco y compilación

## ZRAM — ya está, pero los `sysctl` no

Omarchy configura `zram` en la instalación. Verifica:

```shell-session
$ zramctl
NAME       ALGORITHM DISKSIZE STREAMS MOUNTPOINT
/dev/zram0 zstd          7.7G      12 [SWAP]

$ cat /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
```

Lo que **falta** son los parámetros del kernel que hacen que se use bien. <mark style="background: #ADCCFFA6;">`zram` es swap en RAM comprimida: intercambiar cuesta descomprimir, no esperar a un disco</mark>, así que las reglas de toda la vida se invierten:

```ini
# /etc/sysctl.d/99-vm-zram-parameters.conf   (valores del ArchWiki)
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

```shell-session
$ sudo sysctl --system
$ sysctl vm.swappiness vm.page-cluster
```

> [!fail]+ `vm.swappiness = 10` con zram es contraproducente
> Ese valor es el consejo correcto para swap **en disco**, donde intercambiar es carísimo y quieres evitarlo. Con zram el coste es CPU, y comprimir páginas frías sale más barato que descartar la caché de ficheros. El ArchWiki pide lo contrario: **180** (por encima de 100, que es el máximo "normal"). Y `vm.page-cluster = 0` es el que más se olvida: el readahead de swap (3 por defecto = 8 páginas de golpe) no aporta nada cuando "leer" es descomprimir, solo quema CPU.

**Tamaño**: `ram / 2` es el default de Omarchy y es sensato. En 🖥️ 64 GB son 32 GB de zram que casi nunca se tocarán — puedes bajarlo a `ram / 4` sin perder nada, pero tampoco ganas mucho: zram solo consume RAM real cuando se usa.

## Presión de caché

```ini
# /etc/sysctl.d/99-vm-cache.conf
vm.vfs_cache_pressure = 50
```

Retiene más tiempo la caché de metadatos (dentries e inodes) en RAM. Con 64 GB tiene sentido: abrir por segunda vez un proyecto grande o un árbol de directorios profundo es notablemente más rápido. Efecto marginal en cargas normales; no es una bala de plata.

## TRIM — comprobar, porque probablemente esté apagado

### Por qué existe TRIM

<mark style="background: #ADCCFFA6;">Un SSD no puede sobrescribir una celda: solo puede escribir en páginas vacías y borrar por bloques enteros</mark> (varios MB, muchas páginas de golpe). Cuando borras un fichero, el sistema operativo solo actualiza sus metadatos — **el SSD sigue creyendo que esos sectores contienen datos válidos**. Con el tiempo el controlador se queda sin páginas vacías y, para escribir cualquier cosa, tiene que leer un bloque entero, mezclarlo con lo nuevo, borrarlo y reescribirlo. Eso es *write amplification*: <mark style="background: #FFB86CA6;">escrituras cada vez más lentas y varios ciclos de desgaste reales por cada escritura lógica</mark>.

TRIM es la orden que rompe ese ciclo: "estos sectores ya no valen". El controlador los mete en su pool libre y los borra en segundo plano, cuando no molesta.

### Comprobar el estado

```shell-session
$ systemctl is-enabled fstrim.timer
disabled                                   # ← nadie emite la orden
$ findmnt / -o OPTIONS | grep -o discard    # sin salida = sin discard continuo
$ cat /proc/cmdline | grep -o allow-discards   # sin salida = LUKS bloquea la orden
```

### Las dos capas, y por qué esto es una decisión binaria

Con Btrfs sobre LUKS la orden tiene que atravesar **dos capas**, y la de cifrado la bloquea por defecto:

```text
fstrim  →  Btrfs  →  dm-crypt (LUKS)  →  SSD
                          ↑
                     descarta la orden si no está allow-discards
```

> [!fail]+ Sin `allow-discards`, `fstrim.timer` no hace nada
> Esto es lo que hay que entender antes de decidir: **`dm-crypt` descarta las órdenes de discard silenciosamente** salvo que se abra el volumen con `allow-discards`. El timer se ejecutará cada semana, `fstrim` reportará que ha recortado gigas, y **el SSD nunca recibirá nada**. No hay error, no hay aviso.
>
> <mark style="background: #8000E1A6;">Así que no hay término medio: o activas `allow-discards` y tienes TRIM, o no lo activas y no tienes TRIM en absoluto</mark>. "Activar solo el timer" no es una opción intermedia, es no hacer nada. Mi redacción anterior sugería lo contrario y era falsa.

### El "versus": qué filtra exactamente

Un volumen LUKS bien cerrado debería parecer **ruido aleatorio uniforme de principio a fin**: sin descifrar, un atacante no puede distinguir un sector con datos de uno vacío. Al permitir discards, los sectores liberados quedan realmente vacíos en la NAND y se vuelven distinguibles.

**Lo que un atacante con el disco apagado puede deducir:**
- Cuánto espacio usas de verdad, y el tamaño del área con datos.
- El tipo de sistema de ficheros, por los patrones característicos que dejan sus estructuras.
- Si consigue **varias imágenes del disco en el tiempo**, qué zonas cambian y cuándo — patrones de actividad.

**Lo que NO puede deducir:** nada del contenido. Ni ficheros, ni claves, ni texto en claro. La confidencialidad de los datos cifrados no se toca.

O sea, el "versus" real es: **rendimiento y vida del SSD** contra **filtrar metadatos estructurales, no datos**. No es "cifrado fuerte contra cifrado débil".

### El factor que decide: cuánto disco usas

Antes de sopesar la fuga, mira la ocupación — es lo que determina si el beneficio existe:

```shell-session
$ df -h /
/dev/mapper/root  952G  106G usados  846G libres   12%
```

<mark style="background: #8000E1A6;">Con el disco al 12% ya tienes sobreprovisionamiento de facto: del 88%</mark>. La *write amplification* aparece cuando el controlador **se queda sin bloques limpios** y tiene que reciclar; con 846 GB de bloques nunca escritos, ese ciclo prácticamente no ocurre. O sea que el beneficio de TRIM hoy es casi nulo, mientras que la fuga de metadatos sería permanente.

**Criterio, por tanto:**

| Ocupación del disco | Qué hacer |
| - | - |
| **< ~70%** | **No activar.** El disco vacío hace de sobreprovisionamiento y TRIM no aporta casi nada. `fstrim.timer` puede quedar habilitado como preparación inerte |
| **> ~70%** | Reconsiderar: aquí el controlador empieza a reciclar bloques de verdad y TRIM sí compensa |
| 🖥️ **Sobremesa** | Cuando lo montes, **activar**: no sale de casa, el modelo de amenaza "alguien se lleva el disco" es remoto, y el SSD SATA de sistema se llenará más que un NVMe de 1 TB al 12% |

### La alternativa: sobreprovisionar a propósito

Si el disco se llena y prefieres no filtrar nada, la mitigación es **dejar del 10 al 20% del SSD sin particionar**. Esos bloques nunca se escriben, así que el controlador siempre tiene un pool de páginas vacías garantizado. No es tan bueno como TRIM, pero elimina la parte más dolorosa del problema y no revela absolutamente nada. Hay que hacerlo al particionar, o encogiendo la partición después.

### Cómo activarlo

Probar **en caliente**, sin tocar el arranque ni reiniciar — así ves el efecto antes de comprometerte:

```shell-session
$ sudo cryptsetup refresh --allow-discards --persistent root
$ sudo fstrim -av
/: 412,3 GiB (442659000320 bytes) trimmed on /dev/mapper/root
```

Para que persista entre arranques hay que **editar** la línea existente en `/etc/default/limine`, añadiendo `:allow-discards` al final del `cryptdevice=`:

```ini
KERNEL_CMDLINE[default]+="cryptdevice=PARTUUID=f737...:root:allow-discards root=/dev/mapper/root ..."
```

```shell-session
$ sudo limine-mkinitcpio          # regenera la UKI con la nueva línea de arranque
$ sudo systemctl enable --now fstrim.timer
```

> [!important]+ Cómo se editan los parámetros del kernel en Omarchy
> Omarchy arranca con **Limine** y una UKI (*Unified Kernel Image*): la línea de arranque no está en un `grub.cfg`, se compila dentro de la imagen. Hay dos sitios y no son intercambiables:
>
> - **Añadir** un parámetro nuevo → un drop-in en `/etc/limine-entry-tool.d/<nombre>.conf` con `KERNEL_CMDLINE[default]+=" mi.parametro=1"`. Es lo que hace Omarchy para el `resume=` de la hibernación.
> - **Modificar** un parámetro que ya existe (como `cryptdevice=`) → hay que editar `/etc/default/limine` directamente. Los drop-ins solo **añaden** texto al final; no pueden reescribir lo que ya está puesto.
>
> En los dos casos, después: `sudo limine-mkinitcpio`. Si te olvidas de ese paso, el cambio no llega al arranque siguiente.
>
> **Cómo verificar que la regeneración funcionó.** Lo que arranca es la UKI (`/boot/EFI/Linux/omarchy_linux.efi`), no `/boot/initramfs-linux.img` — Limine construye la imagen unificada desde un staging en `/tmp` y no actualiza ese `.img`, así que su timestamp induce a pensar que no se ha regenerado nada.
>
> **Y los timestamps de `/boot` tampoco valen para la UKI**: es una partición **vfat**, que guarda tiempos locales sin zona horaria y con granularidad de 2 segundos. Verás fechas que no coinciden con el momento real de la escritura. No intentes verificar nada de `/boot` por su `mtime`.
>
> La comprobación buena es leer la línea de arranque **embebida dentro de la UKI**, que es exactamente lo que el kernel recibirá:
>
> ```shell-session
> $ sudo objcopy -O binary --only-section=.cmdline \
>     /boot/EFI/Linux/omarchy_linux.efi /dev/stdout | tr -d '\0'; echo
> ```
>
> Y después de reiniciar, la prueba definitiva sin necesidad de root:
>
> ```shell-session
> $ cat /proc/cmdline
> ```
>
> En la salida del propio comando, las líneas que confirman el éxito son:
>
> ```text
> ==> Using drop-in configuration file: 'nvidia.conf'    ← leyó tu cambio
> ==> Unified kernel image generation successful
> UKI stored in /boot/EFI/Linux/omarchy_linux.efi
> Updated: /boot/limine.conf
> ```
>
> Los `WARNING: Possibly missing firmware for module` (`xhci_pci_renesas`, `qat_6xxx`…) son ruido normal: firmware de hardware que no tienes. No requieren acción.
>
> Y no hace falta ser root para nada de esto salvo leer `/boot`: Omarchy la monta con `fmask=0077,dmask=0077`, así que un `ls /boot` sin `sudo` **falla en silencio** y parece que el directorio está vacío.

### Alternativa: `discard=async` en Btrfs

En lugar del timer semanal, TRIM continuo como opción de montaje en `/etc/fstab`. Ya no tiene el problema de latencia del `discard` síncrono antiguo. **Sigue necesitando `allow-discards` en LUKS.** Merece la pena si escribes cientos de GB por semana; para uso normal, el timer semanal sobra y molesta menos.

## Opciones de montaje Btrfs

Omarchy instala Btrfs con subvolúmenes (`@ @home @log @pkg`) y `compress=zstd:3`. Dos ajustes opcionales en `/etc/fstab`:

```ini
UUID=<...>  /  btrfs  rw,noatime,compress=zstd:1,ssd,space_cache=v2,subvol=/@  0 0
```

- **`noatime`**: evita registrar la hora de último acceso al leer. La ganancia frente al `relatime` que ya tienes es **marginal** — `relatime` solo actualiza si pasó un día o si el fichero se modificó, así que el 99% de las escrituras ya se evitan. Riesgo bajo pero real: algún software antiguo depende de `atime` (`mutt`, herramientas de limpieza por antigüedad).
- **`compress=zstd:1`** en lugar de `zstd:3`: menos CPU por operación de I/O, mejor para NVMe rápidos donde la CPU es el cuello de botella antes que el disco. A cambio, comprime menos (menos espacio ahorrado). Solo afecta a escrituras **nuevas**; los datos ya escritos mantienen su nivel.

## Compilación de paquetes AUR

```shell-session
$ grep -E "^#?MAKEFLAGS|^#?BUILDDIR" /etc/makepkg.conf
#MAKEFLAGS="-j2"
#BUILDDIR=/tmp/makepkg
```

Los dos comentados. <mark style="background: #FF5582A6;">`MAKEFLAGS` comentado significa compilar con `-j1`: un solo core</mark>. En un 7800X3D estás usando 1 de 16 hilos.

Son **tres ajustes independientes** que atacan tres cuellos de botella distintos. No van juntos por narices:

| Ajuste | Qué hace | Dónde aplicarlo |
| - | - | - |
| `MAKEFLAGS="-j$(nproc)"` | Compila en paralelo con todos los hilos en vez de con uno | **Siempre, las dos máquinas.** Es la mejora grande y no cuesta nada |
| `PKGEXT='.pkg.tar'` | No comprime el `.pkg.tar.zst` resultante | **Siempre.** Ahorra el tiempo de comprimir un fichero que vas a descomprimir acto seguido |
| `BUILDDIR=/tmp/makepkg` | Mueve el directorio de trabajo a RAM | **Solo 🖥️ sobremesa** (ver abajo) |

```ini
# /etc/makepkg.conf.d/local.conf   (fichero propio: sobrevive a las actualizaciones de pacman)
MAKEFLAGS="-j$(nproc)"
PKGEXT='.pkg.tar'

# Solo en máquinas con RAM de sobra (>= 32 GB)
BUILDDIR=/tmp/makepkg
```

**`MAKEFLAGS` es el que de verdad importa.** Pasar de `-j1` a `-j16` en el 7800X3D recorta una compilación de veinte minutos a dos o tres. `BUILDDIR` en RAM ahorra I/O de ficheros temporales, que en un NVMe **ya es rápido**: es la guinda, no el plato. Si solo vas a aplicar uno, aplica `MAKEFLAGS`.

> [!important]+ Por qué `/tmp` en tmpfs no basta, y cuándo `BUILDDIR` es mala idea
> Arch **ya** monta `/tmp` en RAM por defecto (systemd, hasta el 50% de la memoria), así que **no hace falta tocar `/etc/fstab`**. Pero eso no hace que se compile ahí: `makepkg` construye en el directorio actual (`~/.cache/yay/<paquete>/`) salvo que `BUILDDIR` diga otra cosa. Son dos cosas separadas — el tmpfs es el *sitio*, `BUILDDIR` es la *orden de usarlo*.
>
> El riesgo es concreto: el tmpfs crece consumiendo RAM real, y un árbol de fuentes desempaquetado + objetos intermedios de algo como `chromium`, `linux` o cualquier cosa con Electron puede pedir **decenas de GB**. Si el tmpfs se llena, la compilación muere con `No space left on device` — a los cuarenta minutos, y hay que empezar de cero.
>
> Regla práctica: **🖥️ 64 GB → ponlo**, con margen para todo salvo casos extremos. **💻 16 GB → no lo pongas**; con 8 GB de tmpfs disponibles y el navegador abierto, cualquier paquete mediano lo revienta. Si un día necesitas compilar algo enorme en el sobremesa, la vía de escape es puntual: `BUILDDIR=~/build yay -S <paquete>`.

Y de paso, en `/etc/pacman.conf`:

```ini
ParallelDownloads = 15
```

---

# 6. CPU y planificador

## Cómo funciona de verdad el escalado de frecuencia

```shell-session
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
amd-pstate-epp                    # 🖥️  (intel_pstate en 💻)
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
powersave
$ cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
performance
```

> [!important]+ `powersave` NO significa "poco rendimiento"
> Con `amd-pstate-epp` / `intel_pstate` en modo *active* solo existen dos gobernadores, y **no se parecen a sus homónimos clásicos**: se traducen en un *hint* EPP (Energy Performance Preference) para el gobernador que vive dentro del propio silicio. La escala EPP va de 0 (máximo rendimiento) a 255 (máxima eficiencia), y es la CPU la que decide frecuencias en tiempo real según carga, temperatura y potencia disponible.
>
> <mark style="background: #ADCCFFA6;">La combinación medida como óptima para gaming en un 7800X3D es gobernador `powersave` + EPP `performance`</mark>: escalado dinámico completo, sesgado hacia rendimiento. Poner el gobernador en `performance` clava frecuencias altas de forma permanente: más consumo y más temperatura **sin FPS extra**. Y en un X3D es peor negocio que en cualquier otro chip, porque el V-Cache apilado limita voltaje y es especialmente sensible a la temperatura: más calor = menos boost sostenido.

Omarchy trae `power-profiles-daemon` y lo expone en su menú (`Setup`):

```shell-session
$ powerprofilesctl get
$ powerprofilesctl set performance    # ajusta el EPP, no clava el gobernador
```

> [!info]+ 🖥️ Verifica que el driver es `amd-pstate-epp`
> Si `scaling_driver` devuelve `acpi-cpufreq` en lugar de `amd-pstate-epp`, estás perdiendo el escalado moderno: activa **CPPC** en la BIOS de la B650-E (a veces está bajo AMD CBS / Overclocking). Con CPPC habilitado, los kernels actuales cargan `amd-pstate-epp` solos.

## Planificador para gaming: `sched_ext`

<mark style="background: #ADCCFFA6;">Desde el kernel 6.12 se pueden cargar planificadores de CPU escritos en eBPF sin recompilar nada</mark>. `scx_lavd` (*Latency-criticality Aware Virtual Deadline*) está diseñado específicamente para gaming: mide qué tareas son críticas en latencia y las prioriza para reducir stutter.

```shell-session
$ omarchy pkg add scx-scheds          # extra/scx-scheds
$ ls /usr/bin/scx_*                   # planificadores disponibles
$ sudo scx_lavd                       # cargarlo (ocupa la terminal; Ctrl+C lo descarga)
$ scxtop                              # monitor en TUI: qué está activo y cómo se comporta
```

El paquete de Arch trae los binarios pero **no** un servicio systemd. Para dejarlo persistente, una unidad mínima propia:

```ini
# /etc/systemd/system/scx_lavd.service
[Unit]
Description=scx_lavd sched_ext scheduler
After=multi-user.target

[Service]
ExecStart=/usr/bin/scx_lavd
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**A favor**: mejora medible en frametimes y stutter, y **Valve lo embarca en SteamOS** para el Steam Deck — no es un experimento de nicho. El riesgo de rotura es bajo por diseño: el planificador corre como proceso en espacio de usuario y, si muere o se cuelga, <mark style="background: #8000E1A6;">el kernel vuelve solo al planificador estándar (EEVDF)</mark>. No hay pantallazo ni sistema inarrancable; en el peor caso pierdes la mejora a mitad de partida.

**Qué te puede salir mal, concretamente:**

- **No hay servicio oficial**, así que la persistencia la mantienes tú (la unidad de arriba). Si un día no notas la mejora, lo primero es comprobar si el proceso sigue vivo: `pgrep scx_lavd`.
- **Los planificadores van y vienen entre versiones.** El paquete trae hoy `scx_lavd`, `scx_rusty`, `scx_bpfland`, `scx_flash`, `scx_cake`, `scx_cosmos`, `scx_forge`… varios de esos no existían hace un año. Una configuración que funciona hoy puede necesitar revisión tras un `omarchy update`, y los nombres de opciones cambian.
- **Elegir el planificador equivocado empeora las cosas.** Todos suenan a "baja latencia", pero optimizan métricas distintas: `scx_bpfland` rinde mal en cargas **mixtas** (compilar y jugar a la vez), y `scx_rusty` está pensado para servidores multi-socket. Para tu caso es `scx_lavd`, y probar los demás "a ver" es tirar el tiempo.
- **El propio planificador consume algo de CPU**, y la ganancia depende de tener cores libres para repartir. En 🖥️ con 16 hilos hay margen de sobra; en 💻 con 12 hilos y un TDP de portátil el efecto es pequeño y puede quedar dentro del ruido de medición.

Traducción: no es "puede romperte el sistema", es **"es una capa extra que mantener, y tienes que medir si en tu máquina hace algo"**.

> [!important]+ No es una decisión, es un experimento de diez minutos
> La pregunta real no es "¿instalo `scx_lavd`?", es **"¿tengo stutter que arreglar?"** — y eso no se sabe sin medir. Probarlo cuesta cero y se revierte al instante: se lanza en primer plano y `Ctrl+C` lo descarga.
>
> ```shell-session
> $ omarchy pkg add scx-scheds mangohud lib32-mangohud
> $ sudo scx_lavd        # terminal aparte; Ctrl+C para volver a EEVDF
> ```
>
> Diez minutos del mismo juego con y sin él, mirando el **gráfico de frametimes** de `mangohud` — no los FPS medios: el stutter vive en los picos, no en la media. Crea el servicio solo si ves diferencia.
>
> Y calibra la expectativa según la máquina: un portátil de 6 cores con TDP limitado da mucho menos margen a un planificador para repartir mejor que un 7800X3D de 16 hilos. En 💻 es probable que el resultado quede dentro del ruido de medición.

## Térmico

`thermald` (activo por Omarchy) solo sirve en Intel — útil en 💻, irrelevante en 🖥️ AMD.

---

# 7. Gaming

## Base

```shell-session
$ omarchy install gaming steam        # Steam + los drivers lib32 correctos para tu GPU
$ omarchy install gaming gpu lib32    # solo los drivers lib32, si ya tienes Steam
$ omarchy install gaming lutris       # Wine + DXVK (Battle.net, EA, Ubisoft)
$ omarchy install gaming heroic       # Epic, GOG, Amazon
```

Usar los instaladores de Omarchy en lugar de `pacman` a pelo evita el olvido clásico: `lib32-nvidia-utils` y `lib32-vulkan-icd-loader`. **Sin los drivers de 32 bits, Proton y buena parte del catálogo antiguo no arrancan.**

## GameMode

Ya viene instalado y activo en Omarchy. Verifica:

```shell-session
$ systemctl --user is-enabled gamemoded
$ pacman -Qs gamemode
```

En las *Launch Options* del juego en Steam:

```text
gamemoderun %command%
```

## Herramientas que faltan

```shell-session
$ omarchy pkg add gamescope mangohud lib32-mangohud
$ omarchy pkg aur add protonup-qt      # Proton-GE
```

- **`gamescope`**: micro-compositor anidado. El wiki de Hyprland es tajante: *"Using `gamescope` tends to fix any and all issues with Wayland/Hyprland"*. Resuelve de golpe escalado en monitor fraccional, juegos que no entienden Wayland, y captura de ratón rota.
- **`mangohud`**: overlay de FPS, frametimes, temperaturas y uso de VRAM. Sin esto estás optimizando a ciegas — cualquier ajuste de esta guía debería validarse con números, no con sensaciones.

Combinado, con la 💻 forzando la dGPU solo para el juego:

```text
gamemoderun prime-run gamescope -f -W 1920 -H 1080 -r 144 -- mangohud %command%
```

## Ajustes de Hyprland para latencia

```ini
# ~/.config/hypr/looknfeel.conf  (o donde prefieras sobreescribir los defaults)
render {
    direct_scanout = 2          # auto: activo con contenido tipo 'game'
}

misc {
    vrr = 3                     # fullscreen SOLO con content type video/game
}

cursor {
    no_hardware_cursors = 2     # 2 = auto. Es el default: basta con NO forzar 1
}
```

- **`direct_scanout = 2`**: el default es `0`. Cuando un juego ocupa la pantalla completa en solitario, envía su buffer directamente al monitor saltándose la composición → menos latencia. Compruébalo en `hyprctl monitors`: si ves `directScanoutBlockedBy: user settings`, está desactivado.
- **`vrr = 3`** en lugar de `2`: el modo `2` activa VRR en **cualquier** ventana a pantalla completa (incluido un navegador con un vídeo), lo que puede provocar parpadeos; `3` solo lo hace con contenido declarado como vídeo o juego.
- **`no_hardware_cursors`: usar `2` (auto)**, que es el default — es decir, **borrar el bloque `cursor { no_hardware_cursors = true }`** si lo arrastras de una guía antigua. Forzar `true` (=1) significa dibujar el cursor **por software siempre**: el compositor tiene que recomponer y reenviar el frame completo en cada movimiento del ratón, en lugar de dejar que el plano de hardware del monitor superponga el puntero gratis. En `2`, Hyprland lo desactiva solo cuando de verdad hace falta (con tearing activo). El workaround era obligatorio hace unos años (`WLR_NO_HARDWARE_CURSORS`, hoy deprecada e ignorada), pero el problema base está resuelto desde Hyprland 0.4x.
  **Cuándo volver a `1`**: si ves cursores fantasma, un puntero que deja rastro al cambiar de forma, o desincronizado en el monitor secundario. Siguen apareciendo regresiones puntuales de driver (hay reportes con la serie 580 sobre artefactos al cambiar la forma del cursor), así que es un fallback a tener a mano, no una configuración permanente.

> [!warning]+ VRR con NVIDIA: verifica antes de darlo por hecho
> El BenQ RD280U es de 60 Hz fijo — no hay VRR que activar. El 1080p 144 Hz puede tener FreeSync, pero <mark style="background: #FFB8EBA6;">G-Sync Compatible por HDMI con NVIDIA es errático</mark> según modelo de monitor y versión de driver. Comprueba el estado real en `hyprctl monitors` (campo `vrr:`) antes de asumir que funciona.

## Tearing (opcional, competitivo)

Reduce latencia a costa de cortes visibles. Solo tiene sentido sin VRR y en juegos donde cada milisegundo cuenta:

```ini
general {
    allow_tearing = true            # interruptor maestro
}
windowrule = match:class cs2, immediate = true
```

Solo surte efecto en pantalla completa exclusiva y **sin nada más visible** en ese monitor: ninguna notificación, barra u overlay. Si el juego se congela en vez de rasgar, tu driver no soporta tearing y no hay más que hacer.

## 💻 Reparto de GPU en portátil

```shell-session
$ omarchy pkg add nvidia-prime      # aporta el wrapper prime-run
$ prime-run <programa>              # ejecuta solo eso en la NVIDIA
$ nvidia-smi                        # confirma qué procesos están en la dGPU
```

---

# 8. Virtualización y laboratorios

Para bug bounty y pentesting el trabajo va dentro de una máquina aislada, no en el host. Omarchy no trae instalador de KVM, así que esta parte es manual.

## Comprobar que KVM está disponible

```shell-session
$ lscpu | grep -i virtualization
Virtualization:                          VT-x          # AMD-V en 🖥️
$ ls -l /dev/kvm                                       # si no existe, falta activarlo en BIOS
$ cat /sys/module/kvm_intel/parameters/nested          # kvm_amd en 🖥️
Y
```

> [!success]+ La virtualización anidada ya viene activada
> `nested = Y` significa que **puedes correr un hipervisor dentro de una VM**. Importa más de lo que parece: es lo que permite montar un laboratorio de Active Directory dentro de una única VM Windows, o probar herramientas que a su vez virtualizan. En los kernels actuales viene activo por defecto tanto en `kvm_intel` como en `kvm_amd`; si tu salida fuera `N`, se fuerza con `options kvm_intel nested=1` en `/etc/modprobe.d/`.

## Stack de KVM/QEMU

```shell-session
$ omarchy pkg add qemu-full libvirt virt-manager dnsmasq edk2-ovmf swtpm virtiofsd
$ sudo systemctl enable --now libvirtd.socket
$ sudo usermod -aG libvirt $USER          # necesario para gestionar VMs sin sudo
```

Qué aporta cada pieza, porque las tres últimas se olvidan siempre y luego falta algo:

| Paquete | Para qué |
| - | - |
| `qemu-full` | El hipervisor con todos los backends (`qemu-desktop` se queda corto) |
| `libvirt` + `virt-manager` | Gestión y GUI |
| `dnsmasq` | **Imprescindible** para la red NAT por defecto de libvirt; sin él las VM no tienen red |
| `edk2-ovmf` | Firmware **UEFI**. Sin esto solo puedes arrancar VMs en BIOS legacy — y Windows 11 no arranca |
| `swtpm` | TPM emulado, **requisito de Windows 11** |
| `virtiofsd` | Compartir carpetas host↔VM con rendimiento decente |

## Ajustes que de verdad cambian el rendimiento

Lo que hace que una VM se sienta nativa o se sienta lenta:

- **Disco: `virtio-blk` o `virtio-scsi`**, nunca SATA emulado. Y formato **raw** sobre Btrfs con `nodatacow` en el directorio de imágenes: <mark style="background: #FFB8EBA6;">el copy-on-write de Btrfs debajo del copy-on-write de un qcow2 multiplica la fragmentación</mark>.
  ```shell-session
  $ sudo mkdir -p /var/lib/libvirt/images && sudo chattr +C /var/lib/libvirt/images
  ```
  (`chattr +C` solo afecta a ficheros creados **después**; sobre uno existente no hace nada.)
- **Red: `virtio-net`.** El `e1000` emulado desperdicia CPU en cada paquete.
- **CPU: modelo `host-passthrough`.** Sin él la VM no ve AES-NI ni AVX, y todo lo que cifre o comprima dentro va notablemente más lento.
- **Vídeo: `virtio` con 3D si necesitas escritorio fluido.** Para una Kali de terminal, `spice` básico sobra.

## Cuánta RAM asignar

Aquí es donde el uso idéntico en las dos máquinas se topa con la realidad:

| | Presupuesto razonable |
| - | - |
| 🖥️ **64 GB** | Laboratorio completo: DC Windows (8 GB) + workstation (6 GB) + Kali (8 GB) simultáneos, con 40 GB libres para el host. Aquí sí merece la pena mirar **hugepages** si una VM pasa de 16 GB |
| 💻 **16 GB** | Una VM a la vez, 6-8 GB máximo, y cerrando el navegador. Es exactamente el escenario donde <mark style="background: #FF5582A6;">el `zram` con `swappiness = 180` (§5) deja de ser un detalle y evita que el host se congele</mark> |

## VM de Windows: el atajo de Omarchy

```shell-session
$ omarchy windows vm install       # descarga y prepara la VM
$ omarchy windows vm launch        # arranca y conecta por RDP
$ omarchy windows vm status
$ omarchy windows vm stop
```

Levanta Windows en un contenedor Docker con KVM y se conecta con `freerdp`, sin pasar por `virt-manager`. Útil cuando necesitas Windows de forma puntual (una herramienta que solo existe ahí, Visual Studio, comprobar cómo se ve algo en Edge) y no quieres dual boot. Requiere `/dev/kvm` y unos 74 GB libres — el propio comando lo verifica antes de empezar.

## Contenedores: más barato que una VM

Para bug bounty **web**, una VM completa es matar moscas a cañonazos: el target está en la nube y solo necesitas aislar tus herramientas.

```shell-session
$ omarchy pkg add docker docker-compose      # o podman, sin daemon ni root
$ sudo systemctl enable --now docker
$ sudo usermod -aG docker $USER
$ omarchy pkg add distrobox                  # entornos completos sobre contenedores
```

`distrobox` es la opción más cómoda para esto: te da una Kali o una Ubuntu con `$HOME` integrado y las herramientas aisladas del host, arrancando en segundos y sin reservar RAM fija.

> [!warning]+ Aislamiento real: los contenedores no son VMs
> Un contenedor comparte kernel con el host. Para **ejecutar código no confiable** (una muestra de malware, un binario de un target, un exploit que no has leído) eso no es aislamiento suficiente: hace falta una VM. Los contenedores valen para *organizar tus herramientas*, no para *contener a un adversario*.
>
> Y cuidado con la red: `docker` en modo bridge por defecto **crea reglas de iptables** que pueden exponer puertos publicados a tu LAN saltándose el firewall del host. En un laboratorio con targets, comprueba con `ss -tlnp` qué está escuchando de verdad.

> [!important]+ 🖥️ No intentes GPU passthrough con una sola GPU
> Pasar la 5070 Ti a una VM significa **quitársela al host**: Hyprland se queda sin GPU y pierdes la sesión. El passthrough de GPU necesita dos tarjetas (una para el host, una para la VM) o una iGPU que asuma el escritorio. El 7800X3D **sí tiene** gráficos integrados, así que técnicamente es viable, pero es un proyecto en sí mismo (aislamiento de grupos IOMMU, `vfio-pci`, doble monitor o KVM switch) y no algo que se active con un flag. Fuera del alcance de esta guía.

## Snapshots: el hábito que ahorra tardes

En pentesting infectas la VM a propósito. Con `libvirt`:

```shell-session
$ virsh snapshot-create-as kali limpia "estado base"
$ virsh snapshot-revert kali limpia
$ virsh snapshot-list kali
```

Un snapshot **antes de empezar cada engagement** y volver a él al terminar. Ojo: los snapshots internos de `qcow2` degradan el rendimiento si acumulas muchos — dos o tres, no veinte.

---

# 9. GPU — ventiladores, frecuencias y power limit

Sustituto de **MSI Afterburner** (frecuencias, curva de ventilador, power limit) y de **Armoury Crate** (ventiladores de la placa base).

> [!fail]+ Por qué Coolbits y `nvidia-settings` no valen aquí
> Las guías clásicas mandan editar `/etc/X11/xorg.conf.d/` con `Option "Coolbits" "4"` y usar `nvidia-settings` o GreenWithEnvy. **Eso no funciona en Omarchy** y no es cuestión de que falte un paso: el camino está cerrado.
>
> `Coolbits` es una opción del driver **X11**, leída desde `xorg.conf` por el servidor X; en una sesión Wayland pura no hay nadie que la aplique. Y `nvidia-settings` es un cliente X: arranca bajo XWayland, pero **no puede tocar ventiladores ni PowerMizer** porque `NVCtrlLib` depende de X11 y NVML no expone las funciones que necesitaría. Lo mismo hunde a GreenWithEnvy. <mark style="background: #8000E1A6;">En Wayland la solución no es un panel gráfico conectado al servidor gráfico, es un daemon que hable directamente con el driver.</mark>

## CoolerControl — ventiladores (GPU **y** placa base)

Sucesor de Coolero: mismo autor, proyecto renombrado y reescrito (el repositorio antiguo lo dice: *"The Project has undergone a name and implementation change"*). **No instales Coolero**, está abandonado.

```shell-session
$ omarchy pkg aur add coolercontrol
$ sudo systemctl enable --now coolercontrold
$ coolercontrol
```

Funciona en Wayland porque no pasa por el servidor gráfico. De su documentación: *"Fan control works on most cards with the proprietary driver. CoolerControl automatically uses NVML and the CLI tools nvidia-settings/nvidia-smi as a fallback"* — **NVML** es una biblioteca de gestión que habla con el driver directamente, sin sesión gráfica, sin Coolbits.

Y resuelve lo de Armoury Crate en la misma interfaz: lee los ventiladores de la placa vía **hwmon** y permite curvas por sensor (disipador, chasis, GPU) desde una sola app.

Paso previo para los sensores de la placa (una sola vez; crea el servicio él solo):

```shell-session
$ omarchy pkg add lm_sensors
$ sudo sensors-detect
$ sensors                            # verifica que aparece el chip Super-I/O
```

> [!warning]+ 🖥️ Placas AM5 recientes y el chip Nuvoton
> La TUF B650-E usa un Super-I/O de la familia **NCT67xx** (módulo `nct6775`). CoolerControl trae detección Super-I/O propia y carga el módulo al arrancar el daemon, pero su documentación advierte que las placas nuevas a menudo necesitan drivers **fuera del kernel** porque el soporte mainline va por detrás — son drivers de ingeniería inversa, sin documentación del fabricante. Si `sensors` no muestra los ventiladores del chasis, ese es el camino: `nct6687d-dkms-git` o `it87-dkms-git` en el AUR, según el chip que reporte `sensors-detect`.

## LACT — frecuencias, power limit y undervolt

Lo que CoolerControl no cubre. Su daemon también es independiente de la sesión: *"GPU configuration is handled by a system service that does not depend on a graphical session (Wayland/X11)"*.

```shell-session
$ omarchy pkg add lact                 # extra/lact — está en repos oficiales, no en AUR
$ sudo systemctl enable --now lactd
$ lact gui
```

Desde la 0.9 incluye **editor de curva voltaje-frecuencia para NVIDIA**, que es lo más parecido al undervolt por curva de Afterburner.

> [!warning]+ Los límites de LACT en NVIDIA
> - Los **offsets de frecuencia** requieren driver ≥ 565 y no aparecen por debajo de 555.
> - La curva V-F usa <mark style="background: #FFB8EBA6;">funcionalidad del driver completamente indocumentada</mark>: el propio proyecto avisa de *"zero guarantees regarding its stability or safety"*. Ve en pasos pequeños y valida cada uno con carga sostenida.
> - Su wiki de hardware **no lista control de ventiladores para NVIDIA** (solo AMD e Intel). De ahí que hagan falta las dos herramientas: LACT para relojes y potencia, CoolerControl para ventiladores.

## Power limit sin instalar nada

La palanca más rentable en una GPU moderna: bajar el límite de potencia recorta bastante consumo y temperatura perdiendo muy pocos FPS.

```shell-session
$ nvidia-smi -q -d POWER | grep -E "Power Limit|Requested"    # rango permitido
$ sudo nvidia-smi -pl 250                                     # vatios
```

Funciona en Wayland (es NVML puro). Para que persista entre arranques, un servicio systemd o un hook de Omarchy.

> [!fail]+ 💻 En portátil esto no se puede — y no es un problema de configuración
> ```shell-session
> $ nvidia-smi --query-gpu=name,power.limit,power.max_limit,fan.speed --format=csv
> NVIDIA GeForce GTX 1650 Ti, [N/A], 50.00 W, [N/A]
> ```
> `fan.speed [N/A]` y `power.limit [N/A]` significan que <mark style="background: #FFB86CA6;">el ventilador y el límite de potencia los gestiona el controlador embebido (EC) del portátil, no el driver</mark>. El sensor `hp-isa-0000` expone `fan1`/`fan2` en **solo lectura**, con `pwm1: N/A`. Ninguna herramienta de Linux va a controlar eso: harían falta utilidades específicas del fabricante (`nbfc-linux` con un perfil hecho para este modelo concreto) y tampoco está garantizado. **Todo este apartado es exclusivo del 🖥️ sobremesa.**

---

# 10. Firmware y BIOS

## Firmware desde Linux

```shell-session
$ omarchy pkg add fwupd
$ fwupdmgr refresh
$ fwupdmgr get-updates
$ fwupdmgr update
```

Muchos fabricantes (ASUS incluido, según modelo) publican firmware en **LVFS**. Si tu placa no está, queda el método tradicional: descargar la BIOS de la web oficial, USB en FAT32 y **ASUS EZ Flash** desde la propia BIOS — independiente del sistema operativo y el método más seguro.

## 🖥️ Ajustes de BIOS que sí importan

El sistema operativo no puede compensar una BIOS mal configurada.

- **EXPO para la DDR5**: sin activarlo la memoria corre a la velocidad JEDEC base, muy por debajo de lo que compraste. Aviso: en AM5 con **4 módulos** de 64 GB el perfil EXPO alto a menudo **no arranca** — el controlador de memoria del Ryzen sufre con 4 DIMMs. Si no postea, baja un escalón de frecuencia o relaja los timings.
- **Curve Optimizer negativo** (−20 a −30 típico, por core): en un 7800X3D el margen real está aquí, no en subir frecuencias. Menos voltaje → menos temperatura → **más boost sostenido**. Valida con carga larga: un CO inestable da cuelgues difíciles de diagnosticar meses después.
- **CPPC habilitado**: necesario para que el kernel cargue `amd-pstate-epp` en lugar del viejo `acpi-cpufreq` (§6).
- **Resizable BAR**: activado; la 5070 Ti lo aprovecha.

---

# 11. Aplicaciones

## Obsidian y apps Electron

La causa del parpadeo y los artefactos en Electron sobre NVIDIA es que **no usan el protocolo `syncobj`** (explicit sync), no que la aceleración por GPU esté rota. Desactivar la GPU (`--disable-gpu`) esconde el síntoma y de paso te deja el editor renderizando por CPU.

```ini
# ~/.config/obsidian/user-flags.conf
--enable-features=WaylandLinuxDrmSyncobj
--enable-wayland-ime
```

Omarchy ya exporta `ELECTRON_OZONE_PLATFORM_HINT` en sus defaults, así que Obsidian ya corre en Wayland nativo. Con el flag de `syncobj` se cierra el problema de raíz — el wiki de Hyprland cita Obsidian por su nombre entre los confirmados.

Otras apps Electron/CEF que no respeten la variable de entorno:

```text
--enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj --ozone-platform=wayland
```

Para la **CLI de Obsidian**: primero activa los comandos en los ajustes de la app; la app tiene que estar **abierta en el vault** para que la CLI funcione (actúa como cliente del proceso de Obsidian).

## Aceleración de vídeo en el navegador

Con NVIDIA hay que ser explícito; no hay autodetección que funcione sola.

```shell-session
$ omarchy pkg add libva-nvidia-driver libva-utils
$ vainfo                                  # debe listar perfiles H264/VP9/AV1
```

**Firefox** — variables de entorno (además de `LIBVA_DRIVER_NAME=nvidia` y `NVD_BACKEND=direct` de §3):

```ini
env = MOZ_DISABLE_RDD_SANDBOX,1
```

**Chromium / Brave** — en `~/.config/chromium-flags.conf`:

```text
--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs
--ignore-gpu-blocklist
--use-gl=angle
--use-angle=gl
--ozone-platform=wayland
```

> [!warning]+ Verifica que de verdad decodifica en GPU
> El soporte de Chromium sobre `nvidia-vaapi-driver` sigue siendo experimental — el propio wiki de Hyprland dice que *"there has not been much success"*. No te fíes de que los flags estén puestos: abre `chrome://gpu` y, con un vídeo reproduciéndose, mira la columna de decodificación:
> ```shell-session
> $ nvidia-smi dmon -s u
> ```
> Si `dec` se queda a 0 mientras reproduces, sigues decodificando en CPU y los flags no han servido de nada.

---

# Checklist — qué aplicar en cada máquina

Resumen operativo para no releer la guía entera al montar el sobremesa. **Casi todo es común**; las diferencias son las de la tabla de "Cómo leer esta guía".

| Ajuste | § | 🖥️ | 💻 | Nota |
| - | - | - | - | - |
| `sysctl` de zram (swappiness 180, page-cluster 0) | 5 | ✅ | ✅ | En 💻 es lo que evita congelaciones con una VM abierta |
| `MAKEFLAGS="-j$(nproc)"` + `PKGEXT='.pkg.tar'` | 5 | ✅ | ✅ | La mejora más grande y gratis |
| `BUILDDIR=/tmp/makepkg` | 5 | ✅ | ❌ | Revienta con 16 GB |
| `fstrim.timer` | 5 | ✅ | ✅ | **Inútil sin `allow-discards`** |
| `allow-discards` en LUKS | 5 | ✅ | ⚠️ | En 💻, decisión consciente: filtra metadatos |
| Perfil `GLVidHeapReuseRatio` (VRAM) | 3 | ✅ | ✅✅ | Crítico con 4 GB de VRAM |
| `i915` antes de los módulos NVIDIA | 3 | ❌ | ✅ | Solo tiene sentido en GPU híbrida |
| `AQ_DRM_DEVICES` → NVIDIA primaria | 3 | ✅ | ❌ | En 💻 el escritorio va en la Intel |
| Regla `udev` para symlink de GPU | 3 | ✅ | ✅ | `card1` no es estable en ninguna |
| `NVreg_PreserveVideoMemoryAllocations` + servicios suspend | 3 | ➖ | ✅ | En 🖥️ apenas suspendes |
| Early KMS, sin hibernación | 3 | ✅ | ✅ | Decisión tomada; limpiar el `resume=` residual |
| Quitar `no_hardware_cursors = true` | 7 | ✅ | ✅ | El default (auto) es mejor |
| `direct_scanout = 2`, `vrr = 3` | 7 | ✅ | ✅ | `vrr` solo sirve si el panel lo soporta |
| `new_render_scheduling`, blur/shadow off | 7 | ❌ | ✅ | Para GPU justa y batería |
| `scx_lavd` | 6 | ✅ | ➖ | En 💻 la ganancia puede ser ruido |
| CoolerControl + LACT | 9 | ✅ | ❌ | En 💻 el EC no deja controlar nada |
| `nvidia-smi -pl` (power limit) | 9 | ✅ | ❌ | En 💻 devuelve `N/A` |
| Stack KVM/QEMU + `virtio` | 8 | ✅ | ✅ | En 💻, una VM a la vez |
| Escala 2 en lugar de 2,5 | 2 | ❌ | ✅ | Si conectas el BenQ al portátil |
| EXPO / Curve Optimizer / CPPC | 10 | ✅ | ❌ | BIOS de sobremesa |

**Leyenda**: ✅ aplicar · ✅✅ prioritario · ❌ no aplicar · ⚠️ decisión consciente · ➖ opcional, poco efecto

## Estado de aplicación en 💻 (2026-07-25)

**Aplicados y verificados**: `sysctl` de zram (180 / 0 / 125 activos) · `MAKEFLAGS` (12 hilos) · perfil de VRAM · `i915` antes de NVIDIA (UKI regenerada) · `fstrim.timer` (habilitado, **sin efecto hasta decidir `allow-discards`**).

**Limpieza de la config de Hyprland** (backup en `~/.config/hypr/.bak-20260725/`):
- Añadido el `source = ~/.config/hypr/envs.conf` que falta en Omarchy → `NVD_BACKEND=direct` aplicado por primera vez.
- `AQ_DRM_DEVICES` movida a `envs.conf`, con las demás env del driver.
- Eliminados de `hyprland.conf`: `cursor { no_hardware_cursors = true }` (ahora en auto), `GBM_BACKEND`, `XDG_SESSION_TYPE` y las `env` que ya están en `envs.conf`.
- Eliminado `GDK_SCALE` de `monitors.conf`.
- `hyprctl configerrors` limpio. `GBM_BACKEND` y `GDK_SCALE` siguen en el entorno hasta cerrar sesión (una recarga no puede desexportar variables).

**Segunda tanda aplicada** (backups en `/root/omarchy-tune2-backup-*`):
`PKGEXT='.pkg.tar'` · `vfs_cache_pressure = 50` · servicios `nvidia-suspend` y `nvidia-resume` habilitados · `NVreg_PreserveVideoMemoryAllocations=1` · `resume=` residual eliminado de los dos sitios (drop-in + `/etc/default/limine`, con `cryptdevice`/`root`/`rootflags` verificados intactos) · UKI regenerada una sola vez.

**Config de usuario aplicada**: `accel_profile = flat` · `kb_options = compose:caps` · `render:direct_scanout = 2` (ya no bloqueado por config: `directScanoutBlockedBy` pasó de `user settings` a `windowed mode`) · `WaylandLinuxDrmSyncobj` en Obsidian · flags VA-API en **Brave y Chromium** con `--enable-features` fusionado en una línea.

**Decisiones cerradas con datos** (2026-07-25):
- **`allow-discards`: NO.** Disco al 12% → sobreprovisionamiento de facto del 88%, beneficio casi nulo frente a una fuga permanente. Revisar si pasa del ~70%.
- **Escritorio a la iGPU: NO.** El monitor de trabajo cuelga de la NVIDIA (`card1 → HDMI-A-1`) y la dGPU está en `P8` a 4,25 W: se pagarían ~2 GB/s de copias entre GPUs para ahorrar vatios que no se gastan.
- **`scx_lavd`: convertido en medición.** Instalar `mangohud` y probar con un juego delante antes de decidir.

**Symlinks estables de GPU aplicados**: `/etc/udev/rules.d/90-gpu-stable-names.rules` crea `/dev/dri/nvidia-dgpu` (bus `0000:01:00.0`) e `/dev/dri/intel-igpu` (bus `0000:00:02.0`), verificados resolviendo el enlace hasta el bus PCI. `AQ_DRM_DEVICES` ya apunta a los nombres estables, con la NVIDIA primera por la razón documentada arriba. El mismo script sirve tal cual en el sobremesa: detecta por driver, así que allí generará `nvidia-dgpu` y `amd-gpu` (la iGPU del 7800X3D).

**Pendientes**: `vrr = 3` y `new_render_scheduling` (dejados comentados en `looknfeel.conf`, para el sobremesa y para GPU justa respectivamente) · las herramientas de §7/§8/§9 cuando se monte el sobremesa · medir `scx_lavd` con un juego delante.

---

# Fuentes

Verificado contra fuentes primarias (julio 2026). Atribución por reclamación:

- **Hyprland**: [wiki NVIDIA](https://wiki.hypr.land/Nvidia/) (open modules obligatorios en 50xx, `fbdev` por defecto desde 570.86.16, early KMS vs hibernación, `i915` antes de nvidia en híbridas, flickering de Electron y `syncobj`, VA-API) · [wiki Monitors](https://wiki.hypr.land/Configuring/Basics/Monitors/) (escala con divisor limpio, posición en espacio lógico, `auto-center-left`, `desc:`) · [wiki Multi-GPU](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Multi-GPU/) (los `card*` no son estables, regla udev, iGPU primaria en portátiles) · [wiki Variables](https://wiki.hypr.land/Configuring/Basics/Variables/) (`direct_scanout`, `vrr`, `no_hardware_cursors` = auto por defecto) · [wiki Performance](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Performance/) (escalas enteras, `gamescope`) · [wiki Tearing](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/)
- **ArchWiki**: [NVIDIA](https://wiki.archlinux.org/title/NVIDIA) (tabla de drivers por arquitectura, `modeset` por defecto desde 560.35.03-5, early loading, `GLVidHeapReuseRatio`, `PreserveVideoMemoryAllocations`) · [zram](https://wiki.archlinux.org/title/Zram) (swappiness 180, page-cluster 0, watermarks) · [Solid state drive](https://wiki.archlinux.org/title/Solid_state_drive) (fstrim vs discard, LUKS allow-discards)
- **Omarchy**: `~/.local/share/omarchy/install/config/hardware/nvidia.sh` y `bin/omarchy-hw-nvidia-gsp` (detección de GPU y qué configura el instalador) · `bin/omarchy-hibernation-available` (zram no cuenta como swap para hibernar)
- **CoolerControl**: [Hardware Support](https://docs.coolercontrol.org/hardware-support.html) (NVML con fallback a nvidia-smi, sin X11 ni Coolbits; drivers hwmon de placa) · [Getting Started](https://docs.coolercontrol.org/getting-started.html) · [repo antiguo de Coolero](https://github.com/codifryed/coolero) (confirmación del renombrado)
- **LACT**: [repo](https://github.com/ilya-zlobintsev/LACT) · [Hardware Support](https://github.com/ilya-zlobintsev/LACT/wiki/Hardware-Support) (offsets ≥565, sin fan control NVIDIA) · [LACT 0.9 y el editor V-F de NVIDIA](https://www.gamingonlinux.com/2026/04/linux-gpu-tool-lact-gets-a-new-ui-and-a-nvidia-voltage-frequency-curve-editor/)
- **NVIDIA Developer Forums**: [Wayland fan and other GPU controls](https://forums.developer.nvidia.com/t/wayland-fan-and-other-gpu-controls/271320) (por qué `nvidia-settings` no puede en Wayland)
- **CPU**: [amd-pstate en la documentación del kernel](https://docs.kernel.org/admin-guide/pm/amd-pstate.html) (EPP 0–255, gobernadores traducidos a hints)
- **sched_ext**: [scx_lavd](https://sched-ext.com/docs/scheds/rust/scx_lavd) · [repo scx](https://github.com/sched-ext/scx) · [guía de scx para gaming en Arch](https://blog.foulkes.cloud/arch-linux-gaming-scx-scheduler/)
- **VA-API**: [nvidia-vaapi-driver](https://github.com/elFarto/nvidia-vaapi-driver)
