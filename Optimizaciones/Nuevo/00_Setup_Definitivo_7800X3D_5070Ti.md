# SETUP DEFINITIVO — 7800X3D / RTX 5070 Ti
## Orden de ejecución

```
FASE 0  →  BIOS (§1)                    45 min   ← antes de instalar Windows
FASE 1  →  Instalación de Windows (§2)  40 min
FASE 2  →  Drivers en orden (§3)        30 min   ← el orden importa
FASE 3  →  Seguridad y virtualización (§4)  20 min
FASE 4  →  Windows: servicios, registro, energía, disco, red, privacidad (§5-§10)  60 min
FASE 5  →  GPU, monitores y gaming (§11-§14)     45 min
FASE 6  →  Periféricos y ventiladores (§15-§16)  30 min
FASE 7  →  Curve Optimizer (§17)                 15 min  ← ruta rápida
           (opcional) validación exhaustiva (§18)  12-14 h desatendidas
```

---

# 1. BIOS / UEFI

<mark style="background: #FF5582A6;">Empieza SIEMPRE por `F5` → Load Optimized Defaults.</mark> Partir de un estado conocido es la mitad del trabajo.

`Supr` o `F2` al arrancar → `F7` para Advanced Mode.

## 1.0 Antes de tocar nada

- [ ] Comprueba la versión de BIOS en la pantalla principal.
- [ ] <mark style="background: #ADCCFFA6;">Regla de actualización de BIOS</mark>: **solo actualiza si el changelog menciona algo que te afecta** (estabilidad de memoria, AGESA con correcciones para tu CPU, seguridad). No actualices "por estar al día": cada flasheo resetea el entrenamiento de memoria y a veces el Curve Optimizer.
- [ ] Tras configurar todo: `Tool` → `ASUS User Profile` → **Save to Profile 1** y **exportar a USB**. Es tu botón de deshacer.

## 1.1 Seguridad y arranque

| Opción                              | Valor                                          | Motivo                                                                                               |
| ----------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Secure Boot**                     | **Enabled** (modo estándar, claves instaladas) | Requisito de Windows 11, base de la cadena de arranque y necesario para varios anti-cheat de kernel  |
| **CSM**                             | **Disabled**                                   | Obligatorio para Secure Boot + GPT                                                                   |
| **AMD fTPM switch**                 | **Enabled (Firmware TPM)**                     | BitLocker, Credential Guard, Windows Hello. El bug de stuttering se corrigió en AGESA 1.2.0.7 (2022) |
| **Erase fTPM NV for factory reset** | **Disabled**                                   | <mark style="background: #FF5582A6;">Si lo activas pierdes las claves de BitLocker</mark>            |
| **IOMMU**                           | **Enabled / Auto**                             | Requerido por VBS/HVCI y por el passthrough en VMs                                                   |
| **SVM Mode**                        | **Enabled**                                    | Imprescindible para VMware y para el hipervisor de Windows                                           |
| **Fast Boot**                       | **Disabled**                                   | Ahorra ~1 s y te impide entrar a la BIOS con `Supr`. No compensa                                     |
| **ErP Ready**                       | **Disabled**                                   | Habilitarlo corta la alimentación USB y el WOL con el equipo apagado                                 |

## 1.2 Memoria — 64 GB DDR5 dual-rank

<mark style="background: #FF5582A6;">Este es el ajuste con más rendimiento en juego de toda la BIOS.</mark>

`Ai Tweaker`:

| Opción                     | Valor                                                          | Motivo                                                                                                                               |
| -------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Ai Overclock Tuner**     | **EXPO I**                                                     | Carga el perfil validado del fabricante. **EXPO II relaja subtimings y suele rendir peor**                                           |
| **DRAM Frequency**         | 🔴 **DDR5-6000** (bajar manualmente desde los 6400 del perfil) | Ver el bloque de abajo                                                                                                               |
| **UCLK DIV1 MODE**         | **UCLK == MEMCLK**                                             | Fuerza el 1:1                                                                                                                        |
| **FCLK Frequency**         | **Auto** (≈2000 MHz)                                           | Tocarlo a mano es la causa nº1 de errores WHEA en AM5                                                                                |
| **CPU SOC Voltage**        | **Manual · 1.20 V** (1.25 V si aparece inestabilidad)          | AMD impuso un **tope duro de 1.30 V** tras los fallos de 2023. Limitarlo evita que la placa aplique 1.30-1.35 V sola con EXPO        |
| **CPU VDDIO / MC Voltage** | **Manual · 1.30 V** (1.35 V si aparece inestabilidad)          | <mark style="background: #FFB86CA6;">No es un raíl de "menos es mejor": demasiado bajo desestabiliza igual que demasiado alto</mark> |
| **DRAM VDD / VDDQ**        | **Auto** (lo que fije EXPO — 1,41 V en este kit)               | No tocar                                                                                                                             |
| **Memory Context Restore** | **Disabled**                                                   | Aunque ponerlo *enabled* ahorra el tiempo del entrenamiento **puede producir errores del stack de memoria**.                         |
| **Power Down Enable**      | **Disabled**                                                   | Deja de depender de lo que decida la placa tras un flasheo.                                                                          |
| **Gear Down Mode / tREFI** | **Auto**                                                       | No tocar sin dominar la materia                                                                                                      |

#### Valores de referencia verificados en este equipo

Estos son los que debe mostrar ZenTimings con la configuración correcta aplicada:

| Campo | Valor correcto | Comentario |
|---|---|---|
| `MCLK` | **3000,00** | 6000 MT/s |
| `UCLK` | **3000,00** | 🔴 **Debe ser igual a MCLK** |
| `FCLK` | **2000,00** | En Auto lo acierta solo |
| `VSOC (SMU)` | **1,20-1,25 V** | Tope duro de AMD: 1,30 V |
| `CPU VDDIO` | **1,30-1,35 V** | Ni "menos es mejor" ni al revés |
| `GDM` / `Cmd2T` | **Enabled / 1T** | Configuración estándar y estable |
| `PowerDown` | **Disabled** (con PDE en Auto) | Ver la fila de arriba |
| `tREFI` | ≈ el valor JEDEC | Si está muy inflado, alguien lo tocó |

### 🔴 Por qué DDR5-6000 y no los 6400 del kit

El controlador de memoria de Zen 4 **no mantiene la relación 1:1 entre UCLK y MEMCLK por encima de 6000 MT/s**. A 6400 el sistema queda en **MCLK 3200 / UCLK 1600**, es decir, **modo 2:1**.

| | MCLK | UCLK | Ratio | Ancho de banda | Latencia |
|---|---|---|---|---|---|
| 6400 CL32 (perfil del kit) | 3200 | 1600 | **2:1** ❌ | +6,7 % | **+10-15 ns** |
| **6000 CL32 (recomendado)** | 3000 | **3000** | **1:1** ✅ | referencia | **63-68 ns** |

El +6,7 % de ancho de banda **no compensa** la penalización de latencia. Por eso DDR5-6000 es el punto dulce de Zen 4 y no 6400. Además tienes **2×32 GB dual-rank**, la configuración que más carga el IMC (AMD especifica oficialmente DDR5-5200 para dos módulos dual-rank).

Los timings CL32 del perfil de 6400 quedan **holgados** a 6000: ganas estabilidad de propina.

**Verificación obligatoria**: instala **ZenTimings** y comprueba `MCLK 3000 / UCLK 3000 / FCLK ~2000`.
<mark style="background: #ADCCFFA6;">Si tu silicio mantuviera 1:1 a 6400 (muy raro), déjalo a 6400.</mark> Manda lo que diga ZenTimings, no la etiqueta del kit.

#### Evidencia medida en este equipo (ZenTimings 1.39 · 19/08/2026)

```
Speed  6400 MT/s   ·   MCLK 3200.00   ·   FCLK 2000.00   ·   UCLK 1600.00
                                                            └── 2:1 confirmado
```

Con este kit concreto (2 × KF564C32-32, dual-rank) y AGESA ComboAm5PI 1.3.0.1b,
el perfil EXPO de 6400 **cae en 2:1**. No es un caso teórico.

| Configuración | Latencia AIDA64 esperada | CAS absoluto |
|---|---|---|
| 6400 CL32 · **2:1** | 75-82 ns | 10,00 ns |
| **6000 CL32 · 1:1** | **66-70 ns** | 10,67 ns |
| 6000 CL30 · 1:1 (apretado) | 63-66 ns | 10,00 ns |

Pierdes 0,67 ns de CAS y recuperas 9-13 ns de latencia total. **El intercambio no está ni cerca de ser discutible.**

**Si 6000 no entra en 1:1** (improbable con FCLK en 2000): baja a **5800**, y en último caso a **5600**.
<mark style="background: #FFF3A3A6;">Un 1:1 a 5600 sigue rindiendo más que un 2:1 a 6400.</mark>

## 1.3 CPU — PBO y Curve Optimizer

`Advanced` → `AMD Overclocking` → `Precision Boost Overdrive`

| Opción | Valor | Motivo |
|---|---|---|
| **Precision Boost Overdrive** | **Advanced** | Necesario para acceder a Curve Optimizer |
| **PBO Limits** | 🔴 **Auto** (**no** Motherboard) | El 7800X3D consume 82-95 W en carga máxima y **nunca llega a su PPT de fábrica (162 W)**. Subir el techo a 230 W es ensanchar una puerta por la que no pasa nadie |
| **PBO Scalar** | **Auto (1X)** | Un scalar alto sube voltaje para ganar MHz que el X3D **no puede dar**: tiene el Fmax bloqueado |
| **Max CPU Boost Clock Override** | **Auto / 0** | El 7800X3D **no admite override positivo de frecuencia**. Ponerlo es inútil |
| **Curve Optimizer** | **Per Core: −10 en los 2 núcleos preferidos · −20 en los otros 6** — ver §17 | Protege exactamente donde falla el CO (mono-hilo) sin perder beneficio térmico. Alternativa sin herramientas: **All Cores −15** |
| **Platform Thermal Throttle Limit** | **85 °C** (o Auto/89 °C si priorizas MT) | Límite duro que **no toca voltajes**: no puede desestabilizar. Cuesta 1-2 % en multihilo y **nada en juegos** |

<mark style="background: #FFF3A3A6;">Dato que cambia toda la estrategia</mark>: en un 7800X3D **PBO no puede darte más MHz**. Lo único que hace es, vía Curve Optimizer, **bajar el voltaje a cada frecuencia** → menos calor → frecuencias altas sostenidas más tiempo. Todo lo demás es ruido.

## 1.4 Gestión de energía del procesador

| Opción | Valor | Motivo |
|---|---|---|
| **Global C-State Control** | **Enabled / Auto** | <mark style="background: #FF5582A6;">NUNCA desactivar.</mark> Cuesta +20 W en idle y +8 °C, y en Zen 4 **no mejora el boost**: los C-states son parte del algoritmo |
| **CPPC** | **Enabled / Auto** | Windows planifica por frecuencia usando CPPC |
| **CPPC Preferred Cores** | **Enabled / Auto** | Envía las cargas mono-hilo al mejor núcleo |
| **SMT Control** | **Enabled / Auto** | <mark style="background: #FF5582A6;">Desactivar SMT pierde un 30-40 % en compilación y VMs</mark> y no da FPS. El mito viene de los 7950X3D de doble CCD |
| **Spread Spectrum** | **Auto** | Requisito de compatibilidad electromagnética. Desactivarlo no da FPS |

## 1.5 PCIe y almacenamiento

| Opción | Valor | Motivo |
|---|---|---|
| **Above 4G Decoding** | **Enabled** | Prerrequisito de Resizable BAR |
| **Re-Size BAR Support** | **Auto / Enabled** | El driver NVIDIA decide por juego. Ganancia real 0-8 % según título |
| **PCIe slot x16** | **Auto (Gen4)** | La 5070 Ti no satura ni Gen4 x16. Forzar Gen5 solo añade riesgo de errores de enlace |
| **ASPM (PCIe / Native)** | **Auto** | Que decida el firmware. <mark style="background: #ADCCFFA6;">No confundir con el «Estado de vínculos PCI Express» del plan de energía de Windows (§7.2): son capas distintas. BIOS = Auto · Windows = Ahorro moderado</mark> |
| **SATA Mode** | **AHCI** | Estándar |
| **NVMe RAID Mode** | **Disabled** | Innecesario y complica el arranque |
| **Onboard WiFi / BT** | Enabled si lo usas · **Disabled si no** | Un dispositivo PCIe menos y menos superficie de ataque |

## 1.6 Q-Fan Control (`F6`)

<mark style="background: #FFB86CA6;">El problema específico del 7800X3D</mark>: el sensor `Tctl` reacciona en menos de un segundo con saltos de 10-20 °C ante cualquier carga momentánea. Si la curva sigue eso literalmente, tienes el "efecto turbina" cada vez que abres el navegador.

La solución **no** es una curva más plana. Son tres cosas a la vez: **histéresis larga**, **la fuente de temperatura correcta para cada ventilador** y **un mínimo razonable**.

### Ventilador de CPU — fuente: **CPU (Tctl)** · modo Manual

| Punto | Temperatura | PWM |
|---|---|---|
| Mínimo | ≤ 50 °C | **30 %** (~600 rpm, inaudible) |
| 1 | 60 °C | **35 %** |
| 2 | 70 °C | **50 %** ← zona de gaming |
| 3 | 78 °C | **70 %** ← compilación / VMs |
| 4 | 85 °C | **90 %** |
| Máximo | 89 °C | **100 %** |

| Parámetro | Valor | Motivo |
|---|---|---|
| **CPU Fan Step Up Time** | **~2-3 s** | Sube con decisión pero ignora picos de menos de 1 s |
| **CPU Fan Step Down Time** | **el máximo disponible (~4-6 s)** | Baja despacio: elimina el efecto yo-yo acústico |
| **CPU Fan Speed Lower Limit** | **200 RPM** | Evita falsas alarmas de "ventilador parado" |

### Ventiladores de caja — fuente: 🔴 **MB / T_Sensor**, nunca CPU

<mark style="background: #FF5582A6;">Error muy común que hay que evitar</mark>: poner los ventiladores de caja a seguir la temperatura de la CPU. Un ventilador de caja **no extrae el calor de la CPU: extrae el calor acumulado en el volumen de la caja**, cuya mayor fuente es la GPU (hasta 300 W frente a los 55-95 W de la CPU).

El sensor de placa es **térmicamente lento por naturaleza** — se mueve unos grados en minutos, no en segundos. Te da la suavidad que buscas **gratis, sin histéresis artificial**.

| Punto | Temp. MB | PWM |
|---|---|---|
| Mínimo | ≤ 35 °C | **30 %** |
| 1 | 40 °C | **40 %** |
| 2 | 45 °C | **55 %** |
| 3 | 50 °C | **75 %** |
| Máximo | 55 °C | **100 %** |

Step Up / Step Down: **el valor más lento disponible** en ambos.

### Flujo de aire

- **Presión ligeramente positiva** (más entrada que salida): menos polvo por rendijas sin filtro, coste térmico ~1 °C.
- Configuración típica: 2-3 frontales de entrada + 1 trasero de salida (+1 superior de salida).
- <mark style="background: #FFB86CA6;">Con un disipador de aire, un ventilador superior de ENTRADA interfiere con el flujo del NH-U9S.</mark> Que el superior sea de salida, o quítalo.
- **Limpia los filtros cada 2-3 meses.** Un filtro obstruido cuesta más grados que todo el tuning de este documento.

## Tabla de cambios
### 1. `Ai Tweaker` — Memoria y voltajes

> ⚠️ **Orden importante**: primero EXPO, luego la frecuencia, y **al final** los voltajes manuales. Al activar EXPO la placa reescribe los voltajes, y si los pones antes te los machaca.

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|1|**Ai Overclock Tuner**|**EXPO I**|En AM5 se llama EXPO (en Intel sería XMP/DOCP). **EXPO II relaja subtimings y rinde peor**|
|2|**DRAM Frequency**|🔴 **DDR5-6000**|Aparece editable tras activar EXPO, mostrando 6400. **Bájalo a 6000**|
|3|**FCLK Frequency**|**Auto**|Debe quedar en 2000 MHz. No lo pongas a mano|
|4|**UCLK DIV1 MODE**|🔴 **UCLK=MEMCLK**|Fuerza el 1:1. Si no aparece aquí, búscalo con `F9`|
|5|**CPU SOC Voltage**|**Manual → `1.20000`**|Tope duro de AMD: 1.30 V. Si hay inestabilidad, sube a `1.25000`|
|6|**CPU VDDIO / MC Voltage**|**Manual → `1.30000`**|Si hay inestabilidad, vuelve a `1.35000`|
|7|**DRAM VDD Voltage**|**Auto**|Lo fija EXPO (1.41 V en tu kit)|
|8|**DRAM VDDQ Voltage**|**Auto**|Idem|
|9|**VDD MISC / Misc Voltage**|**Auto**|No tocar|
|10|**VDDCR CPU Voltage**|**Auto**|🔴 **Nunca manual en un X3D**|
|11|**DRAM Timing Control**|**No entrar**|Los timings del perfil EXPO quedan holgados a 6000|
|12|**Precision Boost Overdrive** (si aparece aquí)|**Auto**|Lo configuras en el menú de AMD (§2). Si lo pones en dos sitios, pueden entrar en conflicto|

**Verificación posterior con ZenTimings:** `MCLK 3000,00 · UCLK 3000,00 · FCLK 2000,00`

---

### 2. `Advanced` → `AMD Overclocking` — PBO y Curve Optimizer

Al entrar te sale un aviso de garantía. **Acepta.**

#### 2.1 `Precision Boost Overdrive`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|13|**Precision Boost Overdrive**|**Advanced**|Necesario para desbloquear lo demás|
|14|**PBO Limits**|🔴 **Auto** (no _Motherboard_)|El 7800X3D consume 82-95 W y nunca llega a sus 162 W de fábrica. Subir el techo no hace nada|
|15|**PBO Scalar Ctrl / PBO Scalar**|**Auto (1X)**|Sube voltaje para ganar MHz que el X3D no puede dar|
|16|**CPU Boost Clock Override**|**Disabled** / **Auto**|El 7800X3D **no admite override positivo**. Fmax bloqueado en ~5050 MHz|
|17|**Max CPU Boost Clock Override(+)**|**0**|Si aparece el campo numérico, déjalo en 0|
|18|**Platform Thermal Throttle Limit**|**Manual → `85`**|Límite duro, **no toca voltajes**: no puede desestabilizar. Cero efecto en juegos. Si prefieres máximo multihilo, déjalo en **Auto (89)**|

#### 2.2 `Curve Optimizer`

> **Antes**: abre **AMD Ryzen Master** en Windows y anota qué núcleos llevan ⭐ **estrella dorada** (mejor) y ⚪ **plateada** (segundo). La numeración de Ryzen Master coincide con la del BIOS.  
> Algunas versiones de AGESA marcan los mejores núcleos aquí mismo en el menú — míralo antes de asumir nada.

|#|Ajuste|Valor|
|---|---|---|
|19|**Curve Optimizer**|**Per Core**|
|20|`Core <preferido nº1>` **Curve Optimizer Sign**|**Negative**|
|21|`Core <preferido nº1>` **Curve Optimizer Magnitude**|**`10`**|
|22|`Core <preferido nº2>` Sign / Magnitude|**Negative** / **`10`**|
|23|**Los otros 6 núcleos** — Sign / Magnitude|**Negative** / **`20`** cada uno|

**Alternativa si no quieres instalar Ryzen Master:**  
`Curve Optimizer` → **All Cores** · `Sign` → **Negative** · `Magnitude` → **`15`**

#### 2.3 `DDR Options` — o directamente con `F9`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|24|**Memory Context Restore**|✅ **Enabled**|Ya lo tienes. POST de ~40 s a ~12-18 s|
|25|**Power Down Enable**|🔧 **Auto**|Ahora lo tienes en _Enabled_. Ahorra <1 W y con MCR causa inestabilidad en kits de 64 GB|
|26|**Memory Interleaving**|**Auto**||
|27|**DRAM ECC** / **Data Poisoning**|**Auto**||

---

### 3. `Advanced` → `AMD CBS` → `CPU Common Options`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|28|**Global C-state Control**|**Auto / Enabled**|🔴 **NUNCA desactivar.** +20 W idle, +8 °C y **0 FPS**. En Zen 4 los C-states son parte del algoritmo de boost|
|29|**CPPC**|**Auto / Enabled**|Windows planifica por frecuencia con esto|
|30|**CPPC Preferred Cores**|**Auto / Enabled**|Manda las cargas mono-hilo al mejor núcleo|
|31|**SMT Control**|**Auto / Enable**|🔴 Desactivarlo pierde 30-40 % en compilación y VMs. El mito viene de los 7950X3D de doble CCD|
|32|**Opcache Control**|**Auto**||
|33|**Core Performance Boost**|**Auto / Enabled**||
|34|**Local APIC Mode**|**Auto**||

#### `Advanced` → `AMD CBS` → `NBIO Common Options`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|35|**IOMMU**|**Enabled**|Requerido por VBS/HVCI y por passthrough en VMs|
|36|**ACS Enable**|**Auto**||
|37|**Enable AER Cap**|**Auto**||

---

### 4. `Advanced` → `CPU Configuration`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|38|**SVM Mode**|✅ **Enabled**|Ya lo tienes. Imprescindible para VMware y el hipervisor de Windows|
|39|**PSS Support**|**Auto / Enabled**||
|40|**NX Mode**|**Enabled**|Protección de ejecución de datos|

---

### 5. `Advanced` → `PCI Subsystem Settings`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|41|**Above 4G Decoding**|✅ **Enabled**|Ya lo tienes. Prerrequisito de ReBAR|
|42|**Re-Size BAR Support**|✅ **Auto** (o Enabled)|Ya lo tienes. El driver NVIDIA decide por juego|
|43|**SR-IOV Support**|**Disabled**|No lo usas|
|44|**PCIEX16_1 Link Speed**|**Auto** (Gen4)|La 5070 Ti no satura ni Gen4 x16. Forzar Gen5 solo añade riesgo|

---

### 6. `Advanced` → TPM y seguridad

#### `Advanced` → `AMD fTPM configuration`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|45|**TPM Device Selection**|**Firmware TPM (fTPM)**|El bug de stuttering se corrigió en AGESA 1.2.0.7 (2022)|
|46|**Erase fTPM NV for factory reset**|🔴 **Disabled**|Si lo activas **pierdes las claves de BitLocker**|

#### `Advanced` → `Trusted Computing`

|#|Ajuste|Valor|
|---|---|---|
|47|**Security Device Support**|**Enable**|
|48|**SHA-1 PCR Bank**|Auto|
|49|**SHA256 PCR Bank**|**Enabled**|

---

### 7. `Advanced` → `Onboard Devices Configuration`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|50|🔴 **Download & Install ARMOURY CRATE app**|🔴 **Disabled**|**Este es el ajuste que reinstala Armoury Crate en Windows solo, incluso tras formatear.** Si no lo desactivas aquí, vuelve siempre. En algunas versiones está en `Tool` → `Armoury Crate`|
|51|**Wi-Fi Controller**|Enabled si lo usas · **Disabled si no**|Un dispositivo PCIe menos y menos superficie|
|52|**Bluetooth Controller**|Enabled si lo usas · Disabled si no|Por tus eventos `BTHUSB`, parece que sí lo usas|
|53|**Realtek LAN Controller**|**Enabled**||
|54|**HD Audio**|**Enabled**||
|55|**LED lighting → When system is in working state**|A tu gusto||
|56|**LED lighting → When system is in sleep/soft-off**|**All ON: Disabled**|Menos consumo con el PC apagado|
|57|**Serial Port / Parallel Port**|**Disabled**|No los usas|

---

### 8. `Advanced` → `APM Configuration`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|58|**ErP Ready**|**Disabled**|Habilitarlo corta la alimentación USB y el WOL con el equipo apagado|
|59|**Restore AC Power Loss**|**Power Off**|O _Last State_ si prefieres que vuelva solo tras un corte|
|60|**Power On By PCI-E**|**Disabled**|Salvo que uses Wake-on-LAN|
|61|**Power On By RTC**|**Disabled**||

---

### 9. `Advanced` → Almacenamiento, USB y red

|#|Ruta|Ajuste|Valor|
|---|---|---|---|
|62|`SATA Configuration`|**SATA Mode**|**AHCI**|
|63|`SATA Configuration`|**NVMe RAID Mode**|**Disabled**|
|64|`USB Configuration`|**Legacy USB Support**|**Auto**|
|65|`USB Configuration`|**XHCI Hand-off**|**Enabled**|
|66|`Network Stack Configuration`|**Network Stack**|**Disabled**|

**Sobre el Network Stack (66):** es el arranque por red (PXE). No lo usas, acorta el POST un par de segundos y quita una superficie de ataque en el arranque. Si algún día montas un lab con PXE, lo reactivas.

---

### 10. `Monitor` → `Q-Fan Configuration`

También accesible con **`F6`** (panel gráfico, más cómodo para las curvas).

#### Ventilador de CPU

|#|Ajuste|Valor|
|---|---|---|
|67|**CPU Q-Fan Control**|**PWM Mode** (el NF-A9 es PWM de 4 pines)|
|68|**CPU Fan Speed Low Limit**|**200 RPM**|
|69|**CPU Fan Profile**|**Manual**|
|70|**CPU Fan Step Up Time**|**~2,4 s** (o el valor más cercano a 2-3 s)|
|71|**CPU Fan Step Down Time**|🔴 **el máximo disponible** (~4-6 s)|

**Curva (4 puntos):**

|Punto|Temperatura|Duty|
|---|---|---|
|Lower|**50 °C**|**30 %**|
|Middle|**70 °C**|**50 %**|
|Upper|**80 °C**|**75 %**|
|Max|**88 °C**|**100 %**|

#### Ventiladores de caja — el cambio importante

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|72|🔴 **Chassis Fan Q-Fan Source** (para cada uno)|🔴 **MB** (o **T_Sensor** si tienes termistor)|**Ahora mismo siguen a la CPU.** Un ventilador de caja extrae el calor del volumen de la caja, cuya mayor fuente es la GPU (300 W), no la CPU (55-95 W)|
|73|**Chassis Fan Q-Fan Control**|**PWM** o **DC** según tus ventiladores||
|74|**Chassis Fan Profile**|**Manual**||
|75|**Chassis Fan Step Up / Down Time**|**el valor más lento disponible** en ambos||
|76|**Chassis Fan Speed Low Limit**|**200 RPM**||

**Curva de caja (4 puntos, sobre temperatura de placa):**

|Punto|Temp. MB|Duty|
|---|---|---|
|Lower|**35 °C**|**30 %**|
|Middle|**45 °C**|**55 %**|
|Upper|**50 °C**|**75 %**|
|Max|**55 °C**|**100 %**|

**Por qué funciona:** el sensor de placa es **térmicamente lento por naturaleza** — se mueve unos grados en minutos, no en segundos. Eso te da la suavidad que buscas sin necesidad de histéresis artificial. El `Tctl` del X3D salta 10-20 °C en menos de un segundo; seguirlo con los ventiladores de caja es lo que produce el efecto turbina.

---

### 11. `Boot`

|#|Ajuste|Valor|Nota|
|---|---|---|---|
|77|**Fast Boot**|**Disabled**|Ahorra ~1 s y te impide entrar a la BIOS con `Supr`|
|78|**Boot Logo Display**|**Auto** o **Disabled**|_Disabled_ te muestra los mensajes de POST, útil para diagnosticar|
|79|**POST Delay Time**|**1-3 s**|Margen para pulsar `Supr`|
|80|**Setup Mode**|**Advanced Mode**|Entra directo al modo avanzado|
|81|`CSM (Compatibility Support Module)` → **Launch CSM**|**Disabled**|Obligatorio para Secure Boot + GPT|
|82|`Secure Boot` → **OS Type**|**Windows UEFI mode**||
|83|`Secure Boot` → **Secure Boot state**|Debe leerse **Enabled**|Si dice _Setup Mode_, entra en `Key Management` → **Install default Secure Boot keys**|
|84|**Boot Option #1**|Tu **Windows Boot Manager**||

---

### 12. `Tool`

| #   | Ajuste                                                     | Acción                                          | Nota                                                    |
| --- | ---------------------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| 85  | **Armoury Crate** → _Download & Install ARMOURY CRATE app_ | 🔴 **Disabled**                                 | Si no lo viste en §7, está aquí. **Verifícalo sí o sí** |
| 86  | **ASUS User Profile**                                      | **Save to Profile 1** con un nombre reconocible | Tu botón de deshacer                                    |
| 87  | **ASUS User Profile** → _Load/Save Profile from/to USB_    | **Exportar a un USB**                           | Por si tienes que hacer CLR_CMOS                        |
| 88  | **ASUS SPD Information**                                   | Solo consulta                                   | Verás los perfiles EXPO del kit                         |

## 1.7 Guardar

`F10` → guardar y reiniciar. Después: `Tool` → `ASUS User Profile` → **Save to Profile 1**.

---

# 2. INSTALACIÓN DE WINDOWS 11 PRO

## 2.1 Medio de instalación

- Descarga la ISO oficial desde `microsoft.com/software-download/windows11`.
- **Rufus** con las opciones por defecto (no desactives los requisitos: tienes TPM y Secure Boot).
- <mark style="background: #ADCCFFA6;">Desconecta el resto de unidades</mark> durante la instalación para que la partición EFI vaya donde toca.

## 2.2 Durante la instalación

| Paso | Elección |
|---|---|
| Edición | **Windows 11 Pro** |
| Particionado | Borrar todas las particiones del disco de destino y **dejar que Windows cree el esquema** (EFI + MSR + Windows + Recovery) |
| Red durante OOBE | **Conectado** — así Windows Update trae drivers básicos y activa el hardware |
| Cuenta | Microsoft o local, a tu gusto. <mark style="background: #FFB86CA6;">Con cuenta local pierdes la copia de la clave de BitLocker en la nube</mark>: si eliges local, guarda la clave tú |
| Privacidad OOBE | **Todo desactivado**: ubicación, buscar mi dispositivo, diagnóstico opcional, experiencias personalizadas, id. de publicidad |
| Personalización de la experiencia | **Omitir** |

## 2.3 Inmediatamente después

```powershell
# Comprobar que no hay limitaciones de arranque heredadas (debe salir limpio)
bcdedit /enum {current}

# Windows Update completo, varias pasadas hasta que no quede nada
# Configuración → Windows Update → Buscar actualizaciones (repetir hasta 0 pendientes)
```

<mark style="background: #FF5582A6;">Nunca uses las casillas "Número de procesadores" ni "Cantidad máxima de memoria" de `msconfig`.</mark> Son herramientas de depuración para simular hardware limitado. No aceleran el arranque: si las marcas, arrancas con menos núcleos y menos RAM.

---

# 3. DRIVERS — EL ORDEN IMPORTA

<mark style="background: #FF5582A6;">Instala en este orden exacto.</mark> El driver de chipset debe ir primero porque instala el proveedor PPM de AMD, que es lo que reprograma el plan Equilibrado de Windows para trabajar con CPPC. Si lo instalas después de todo, algunos ajustes de energía se quedan a medias.

| # | Driver | Origen | Nota |
|---|---|---|---|
| 1 | **AMD Chipset** | `amd.com/support` → tu chipset (B650) | 🔴 **Primero. Reiniciar después** |
| 2 | Windows Update completo | — | Deja que traiga LAN, audio y el básico del iGPU |
| 3 | **NVIDIA Game Ready** | `nvidia.com/drivers` — descarga manual | Instalación personalizada → **Realizar una instalación limpia** |
| 4 | Realtek LAN / Audio | `asus.com` soporte de la placa | Solo si Windows Update no los puso o dan problemas |
| 5 | **NVIDIA App** | `nvidia.com/nvidia-app` | Necesaria para los overrides de DLSS |

## 3.1 Qué NO instalar

| Software | Por qué no |
|---|---|
| 🔴 **Armoury Crate** | Fuente conocida de DPC latency, deja **7 servicios y 6 tareas programadas** residentes, y se autoactualiza sin pedir permiso. Todo lo que necesitas son las curvas de ventilador, y eso lo hacen mejor la BIOS (§1.6) y **FanControl** (§16) |
| 🔴 **Herramientas de "debloat" de terceros** | Ejecutan cientos de cambios no documentados con privilegios SYSTEM. Patrones de fallo habituales: romper Windows Update, romper la Store, desactivar componentes de Defender de forma no evidente. <mark style="background: #FF5582A6;">En un equipo de seguridad, ejecutar un binario no auditado como SYSTEM es exactamente el riesgo que evalúas en tus clientes</mark> |
| 🟠 **AMD Adrenalin completo** | El 7800X3D tiene iGPU, pero tus dos monitores van a la NVIDIA. El básico de Windows Update sobra y te ahorra 3 servicios |
| 🟠 **"Optimizadores" y limpiadores de registro** | Sin excepción |

## 3.2 Software base recomendado

| Herramienta | Para qué |
|---|---|
| **HWiNFO64** | Telemetría de todo. Es la base de cualquier medición |
| **ZenTimings** | Verificar UCLK/MCLK/FCLK y voltajes reales |
| **MSI Afterburner** | Curva V/F de la GPU (§13) |
| **FanControl** | Curvas de ventilador por software, sin telemetría (§16) |
| **CrystalDiskInfo** | SMART del NVMe |
| **CapFrameX** | FPS medio, **1 % low, 0.1 % low**, frametime |
| **AMD Ryzen Master** | Identificar los 2 núcleos preferidos (2 min, luego se desinstala) |
| CoreCycler | Solo para la ruta de validación exhaustiva del Curve Optimizer |
| **OCCT** | CPU, RAM, **VRAM** y fuente. Detecta errores, no solo cuelgues |
| **LatencyMon** | DPC latency |

---

# 4. SEGURIDAD Y VIRTUALIZACIÓN

<mark style="background: #FF5582A6;">Esta sección corrige el error más extendido de las guías de optimización.</mark>

## 4.1 El concepto que hay que entender

> **Desinstalar la característica "Hyper-V" NO apaga el hipervisor.**

El hipervisor de Windows y la característica opcional Hyper-V son cosas distintas:

- **VBS/HVCI carga el hipervisor** por política de Device Guard, con independencia de que Hyper-V esté instalado.
- `Disable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All` solo desinstala **herramientas de gestión, servicios de integración y el rol** — no descarga el hipervisor.
- Para que VMware entre en su **modo nativo (VMM propio)** hacen falta **las dos cosas**:
  `bcdedit /set hypervisorlaunchtype Off` **+** desactivar Integridad de memoria.

El resultado de desinstalar solo la característica es **perder WSL2, Sandbox, Credential Guard y el backend Hyper-V de Docker sin ganar un solo punto de rendimiento en las VMs**.

## 4.2 Configuración recomendada — perfil de máxima seguridad

```powershell
# Vía SOPORTADA para VMware Workstation con VBS activo
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform     -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Opcional: WSL2
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
```

Después: **Seguridad de Windows → Seguridad del dispositivo → Aislamiento del núcleo → Integridad de la memoria = Activado**.

### Credential Guard

```powershell
# 2 = sin bloqueo UEFI (reversible por software, recomendado si haces labs)
# 1 = con bloqueo UEFI (más seguro, para desactivarlo hay que pasar por BIOS)
$p = 'HKLM:\SYSTEM\CurrentControlSet\Control\LSA'
New-Item -Path $p -Force | Out-Null
Set-ItemProperty -Path $p -Name 'LsaCfgFlags' -Value 2 -Type DWord
```

**Verificación tras reiniciar:**
```powershell
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
$dg.SecurityServicesRunning
# 1 = Credential Guard | 2 = Integridad de memoria (HVCI) | 5 = Protección de pila en kernel
```

## 4.3 Lo que se queda como está — no se toca

| Componente | Estado | Motivo |
|---|---|---|
| **Microsoft Defender** | **Activado** | EDR competente y ligero. Impacto en FPS <1 %. Desactivarlo en un equipo que ejecuta binarios de procedencia dudosa es indefendible |
| **SmartScreen** | **Activado** | Coste 0. Se puede saltar puntualmente |
| **Secure Boot / fTPM** | **Activados** | §1.1 |
| **Windows Update** | **Activado** | Usa horas activas y pausas de 1-2 semanas si te preocupa la estabilidad |
| **Mitigaciones de CPU (Spectre/MDS)** | **Sin tocar** | Coste <2 % en Zen 4. Desactivarlas en tu perfil de riesgo es inaceptable |
| **BitLocker** | **Activar** | Trabajas con datos de clientes. Guarda la clave de recuperación **fuera del equipo** |

## 4.4 Volcados de memoria

Sin esto no puedes diagnosticar un reinicio inesperado.

```
sysdm.cpl → Opciones avanzadas → Inicio y recuperación → Configuración
  Escribir información de depuración: VOLCADO DE MEMORIA DEL KERNEL
```

Requiere el **pagefile en C:** (§8.2). Es una de las razones por las que no se desactiva.

---

# 5. SERVICIOS DE WINDOWS

## 5.1 El principio que invalida el 70 % de las guías

> <mark style="background: #FFF3A3A6;">Un servicio en estado "Manual" que no está en ejecución consume exactamente **0 bytes de RAM y 0 % de CPU**.</mark>

Windows 11 usa **inicio por desencadenador**: la mayoría de servicios no arrancan hasta que ocurre un evento concreto (se conecta un dispositivo Bluetooth, se abre un socket, se inserta una tarjeta inteligente). Si el evento nunca ocurre, el servicio nunca se ejecuta.

**Consecuencia**: deshabilitar servicios que ya estaban en Manual **no libera ni un megabyte**. Lo único que cambia es que, si algún día necesitas esa funcionalidad, falla con un error confuso en lugar de arrancar sola.

**Deshabilitar sí tiene un beneficio legítimo, pero es otro: reducción de superficie de ataque.** Para un equipo que se conecta a redes hostiles eso vale mucho más que los megabytes imaginarios — y es el único criterio válido para esta lista.

## 5.2 Lista definitiva

`Win + R` → `services.msc`

### 🟢 Deshabilitar — beneficio real de privacidad o superficie de ataque

| Servicio | Nombre corto | Motivo | Coste |
|---|---|---|---|
| Experiencias del usuario y telemetría asociadas | `DiagTrack` | Único servicio de telemetría con actividad continua real | Feedback Hub y algunos diagnósticos |
| Servicios de Escritorio remoto | `TermService` | Cierra RDP entrante. **El cliente `mstsc` sigue funcionando** | Ninguno si no hospedas RDP |
| Redirector de puerto UM de Escritorio remoto | `UmRdpService` | Idem | Ninguno |
| Detección SSDP | `SSDPSRV` | Reduce exposición a ataques UPnP | Rompe el mapeo automático de puertos (algunos juegos P2P) y DLNA |
| Host de dispositivo UPnP | `upnphost` | Idem | Idem |
| Registro remoto | `RemoteRegistry` | <mark style="background: #ADCCFFA6;">Ya viene deshabilitado por defecto</mark> | Ninguno |
| Servicio de geolocalización | `lfsvc` | Privacidad | "Buscar mi dispositivo" y zona horaria automática |
| Adquisición de imágenes (WIA) | `StiSvc` | Sin escáner | Captura de imagen fija de algunas webcams |
| Uso compartido de red del Reproductor WM | `WMPNetworkSvc` | Obsoleto | Ninguno |
| Administrador de mapas descargados | `MapsBroker` | Si no usas Mapas | App Mapas sin conexión |
| Extensiones y notificaciones de impresora | `PrintNotify` | Solo notificaciones | Ninguno |

### 🟠 Depende de tu uso — decide con criterio

| Servicio | Nombre corto | Deshabilita **solo si** | Lo que rompe |
|---|---|---|---|
| Servidor | `LanmanServer` | No compartes carpetas ni usas recursos administrativos | **C$ / ADMIN$**, compartir carpetas, algunas herramientas con named pipes locales |
| Cola de impresión | `Spooler` | **No usas "Microsoft Print to PDF"** | 🔴 <mark style="background: #FFB86CA6;">Imprimir a PDF deja de funcionar</mark>. Si generas documentación en PDF, **déjalo en Automático** |
| Servicio biométrico | `WbioSrvc` | No usas Windows Hello con huella/cara | Nada (el **PIN usa TPM**, no biometría) |
| Bluetooth (`bthserv`, `BTAGService`, `BthAvctpSvc`) | — | No usas ningún periférico BT | Todo el Bluetooth |
| FrameServer de la Cámara | `FrameServer` | No usas webcam | Teams, Zoom, OBS |
| Plataforma de dispositivos conectados | `CDPSvc` / `CDPUserSvc` | No usas Phone Link ni Compartir cerca | Portapapeles entre dispositivos, notificaciones en algunos builds |
| Zona con cobertura inalámbrica móvil | `icssvc` | — | 🟠 **Es el "Punto de acceso móvil"**: puede interesarte para pruebas de rogue AP |
| Sincronizar host | `OneSyncSvc` | No usas Correo / Calendario / Contactos de Windows | Sincronización de esas apps |

### 🔴 NO tocar — aunque muchas guías digan lo contrario

| Servicio | Por qué la gente lo deshabilita y por qué es un error |
|---|---|
| `SysMain` (Superfetch) | *"Machaca el SSD"*. Falso: en NVMe el coste es despreciable y sigue mejorando el tiempo de apertura de aplicaciones. Su algoritmo detecta el tipo de disco |
| `WSearch` (Windows Search) | Deshabilitarlo rompe la búsqueda del menú Inicio y de Outlook. Lo correcto es **excluir carpetas** (§8.5) |
| `wuauserv` (Windows Update) | Te deja sin parches de seguridad. Usa horas activas y pausas |
| `WinDefend`, `WdNisSvc`, `SecurityHealthService` | §4.3 |
| `BFE` (Motor de filtrado base) | <mark style="background: #FF5582A6;">Sin él no hay firewall, ni IPsec, ni WFP.</mark> Muchas herramientas de red dependen de él |
| `EventLog` | Sin registro de eventos no hay auditoría posible — ni tuya ni de esta puesta a punto |
| `Schedule` (Programador de tareas) | Windows 11 depende de él para funciones básicas |
| `WerSvc` (Informe de errores) | **Necesitas los volcados de fallo** durante la validación (§18) |
| `PcaSvc` (Compat. de programas) | Aplica los shims de compatibilidad. Deshabilitarlo **rompe herramientas antiguas** — relevante en pentesting |
| Servicios Xbox (`XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`) | **Manual es su valor por defecto y no consumen nada.** Deshabilitarlos rompe el login de Xbox Live (Halo, Forza, Game Pass) y **los mandos Xbox** |
| `SCardSvr` / `ScDeviceEnum` (Tarjeta inteligente) | 🟠 **Importante para ti**: YubiKey PIV y smartcards en labs de AD |
| `TapiSrv` (Telefonía) | Manual por defecto. Lo necesitan RAS/VPN |
| `RmSvc` (Admin. de radio) | Con WiFi/BT integrados, gestiona modo avión y el interruptor de radios |
| `Audiosrv` / `AudioEndpointBuilder` | — |
| `DPS`, `WdiSystemHost` | Son los que permiten que Windows autorrepare fallos de red y energía |
| `nvcontainer*` | Panel NVIDIA y G-SYNC |

### Comando de referencia

```powershell
# Deshabilitar el bloque verde (revisa la lista antes de ejecutar)
'DiagTrack','TermService','UmRdpService','SSDPSRV','upnphost','lfsvc',
'StiSvc','WMPNetworkSvc','MapsBroker','PrintNotify' | ForEach-Object {
    Stop-Service $_ -Force -ErrorAction SilentlyContinue
    Set-Service  $_ -StartupType Disabled -ErrorAction SilentlyContinue
}

# Volver cualquiera a su valor por defecto:
# Set-Service <nombre> -StartupType Manual
```

---

# 6. REGISTRO DE WINDOWS

<mark style="background: #FF5582A6;">Regla general: no modificar el registro por defecto.</mark> Cada cambio debe cumplir al menos una condición: existe documentación técnica sólida, hay una mejora medible, resuelve un problema concreto, o reduce una carga innecesaria real.

## 6.1 Lo único que se toca

En una instalación limpia **no hace falta ninguna modificación de registro** para rendimiento. Estas dos son opcionales y de privacidad:

```powershell
# Autologgers ETW de telemetría (impacto de CPU despreciable, ganancia de privacidad pequeña)
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger' -Name Start -Value 0
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog'   -Name Start -Value 0
```

<mark style="background: #ADCCFFA6;">NO toques `TCPIPLOGGER`</mark>: ponerlo a 0 rompe `netsh trace` y el diagnóstico de red, y no aporta nada. Déjalo en **1**.

## 6.2 Tweaks populares que NO se aplican, y por qué

| Tweak | Veredicto | Explicación |
|---|---|---|
| `SystemResponsiveness = 0` | 🔴 **Inerte** | Microsoft documenta literalmente en la referencia de MMCSS: *"Values below 10 and above 100 are clamped to 20"*. **Poner 0 equivale exactamente a dejarlo en 20.** Y aunque funcionase, los motores gráficos **no registran su hilo de render en MMCSS** — quien sí lo hace es el audio, así que el único efecto posible sería arriesgar cortes de sonido |
| `AlwaysUnloadDll = 1` | 🔴 **Obsoleto** | Clave de Windows 98/2000/XP. No implementada desde Vista. Y su justificación ("liberar RAM") es incorrecta: una DLL en caché vive en la *standby list*, que Windows contabiliza como **memoria disponible**. Si funcionara, el efecto sería negativo |
| `NetworkThrottlingIndex = ffffffff` | 🟠 **No es un tweak de gaming** | El throttle de MMCSS limita a **10 paquetes/ms = 10.000 paq/s** y solo mientras hay audio en reproducción. Un juego online usa **60-128 paq/s**: tres órdenes de magnitud por debajo. <mark style="background: #ADCCFFA6;">Sí tiene sentido si capturas tráfico o mueves imágenes de VM con música de fondo</mark> — pero entonces es un ajuste de red, no de FPS |
| `Ndu\Start = 4` | 🔴 **Rompe cosas** | El valor por defecto es **2**. Ponerlo a 4 desactiva el driver de uso de datos y rompe las estadísticas de red del Administrador de tareas |
| Hacks de "scheduler", "input lag", "RAM" y prioridades | 🔴 **No** | Sin documentación, sin mejora medible, y varios pueden dejar sin CPU a drivers y al subsistema de audio |
| "Desbloquear los 6 perfiles de aceleración" (`Attributes = 2`) | 🟢 **Inocuo** | Solo desvela la opción "Modo de mejora del rendimiento del procesador" en la interfaz. En AMD con el driver PPM instalado, el valor por defecto del plan Equilibrado **ya suele ser Agresiva (2)**, así que el cambio no hace nada. Si lo quieres visible, adelante |

---

# 7. PLAN DE ENERGÍA

## 7.1 El plan correcto es Equilibrado

<mark style="background: #BBFABBA6;">Contraintuitivo pero correcto.</mark> Con Zen 4, el **driver PPM de AMD** (incluido en el paquete de chipset, por eso se instala primero) **reprograma el plan Equilibrado de Windows** para trabajar con CPPC: el planificador solicita frecuencia por núcleo con latencias de microsegundos.

| Plan | Idle | Gaming | Multihilo | Veredicto |
|---|---|---|---|---|
| **Equilibrado** | Aparca núcleos, baja a 400-600 MHz, ~25 W paquete | Boost completo bajo demanda | Rendimiento completo | ✅ **CORRECTO** |
| Alto rendimiento | Sin aparcado, ~45-55 W paquete | Idéntico | Idéntico | ❌ +20-30 W, +8 °C, **0 FPS** |
| Ultimate Performance | Peor aún | Idéntico | Idéntico | ❌ Sin ganancia |
| AMD Ryzen Balanced | — | — | — | ❌ Obsoleto: AMD ya no lo instala en Zen 4 |

Los planes "Alto rendimiento" se diseñaron para arquitecturas donde cambiar de estado era lento (Bulldozer, Sandy Bridge). **En Zen 4 solo consiguen que el procesador esté caliente sin hacer nada.**

## 7.2 Configuración avanzada

`Editar plan de energía` → `Cambiar la configuración avanzada de energía`

| Ajuste | Valor | Motivo |
|---|---|---|
| Disco duro → Apagar tras | **0 (nunca)** | Irrelevante en NVMe, pero inocuo |
| **Estado mínimo del procesador** | **0-5 %** | <mark style="background: #FF5582A6;">Si está en 100 %, el CPU nunca baja de frecuencia: +15-20 W permanentes en idle</mark> |
| Estado máximo del procesador | **100 %** | — |
| Modo de mejora del rendimiento | **Agresiva** | Ya suele ser el defecto en AMD |
| Directiva de refrigeración del sistema | **Activa** | Sube el ventilador antes que bajar frecuencia. Correcto en sobremesa |
| **Suspensión selectiva de USB** | **Habilitada** (por defecto) | 🔴 Ver §7.3 |
| **PCI Express → Estado de vínculos** | **Ahorro moderado de energía** | Desactivarlo cuesta 2-5 W sin beneficio de latencia demostrado. Es el ajuste del **sistema operativo**; el de la BIOS (§1.5) se deja en Auto |
| Suspender tras | **Nunca** (0) | VMs, descargas, compilaciones largas |
| **Apagar la pantalla tras** | 🔴 **20 minutos** | Dos monitores encendidos toda la noche son **45-70 W** para nadie, más desgaste del retroiluminado del BenQ |
| Permitir temporizadores de reactivación | **Deshabilitar** | Evita que el equipo despierte solo por mantenimiento |
| Permitir suspensión híbrida | Irrelevante (hibernación off) | — |
| Configuración multimedia | Valores por defecto | Sin efecto medible |
| AMD Power Slider / Gráficos intercambiables | Irrelevante | Ajustes de portátil con APU |

```powershell
powercfg /setactive SCHEME_BALANCED
powercfg /change monitor-timeout-ac 20
powercfg /change standby-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /setactive SCHEME_CURRENT
```

## 7.3 Sobre la suspensión selectiva de USB

<mark style="background: #FFF3A3A6;">Mito muy extendido</mark>: "desactivarla reduce el input lag".

La suspensión selectiva **solo actúa sobre dispositivos inactivos**. Un ratón o teclado en uso envía informes HID continuamente y **nunca entra en ese estado**. No hay latencia que reducir.

<mark style="background: #ADCCFFA6;">Excepción legítima</mark>: si un periférico concreto se desconecta aleatoriamente, desmarcar *"Permitir que el equipo apague este dispositivo"* **en ese dispositivo** es una solución válida. Como tweak global de rendimiento, no.

---
---

# 8. ALMACENAMIENTO

## 8.1 Contexto del hardware

El **Kingston NV3** es un SSD **sin DRAM** (usa HMB: mantiene su tabla de traducción en la RAM del sistema) con **caché SLC dinámica** que se agota. Traducción práctica:

| Escenario | Impacto |
|---|---|
| Juegos, arranque de Windows, abrir IDEs | ✅ Ninguno. La lectura aleatoria es excelente |
| Clonar o restaurar snapshots de VMs | ⚠️ Notable: al agotarse la SLC la escritura cae de forma marcada |
| VMs con I/O aleatoria continua | ⚠️ Notable: sin DRAM, la latencia de escritura a QD alto sufre |
| **Disco por encima del 80 % lleno** | 🔴 **Grave**: la SLC dinámica se reduce con el espacio libre |

## 8.2 Configuración

| Elemento | Valor | Motivo |
|---|---|---|
| **TRIM** | **Habilitado** | `fsutil behavior query DisableDeleteNotify` debe devolver **0** |
| **Optimizar unidades** | **Semanal — NO desactivar** | En SSD **no desfragmenta**: envía comandos TRIM de reconsolidación |
| **Espacio libre** | 🔴 **≥ 25 % (≈500 GB)** | No es opcional en un DRAM-less con SLC dinámica |
| **Pagefile** | **Administrado por el sistema en C:** | Ver §8.3 |
| **Hibernación** | **Desactivada** (`powercfg /h off`) | Ver §8.4 |
| **SysMain** | **Habilitado** | §5.2 |
| **Indexación** | **Habilitada con exclusiones** | §8.5 |
| **Caché de escritura del dispositivo** | **Habilitada** (por defecto) | Sin SAI, **no** habilites "Desactivar vaciado del búfer" |
| **Firmware** | Verificar con **Kingston SSD Manager** | — |

## 8.3 El pagefile no se desactiva

<mark style="background: #FFF3A3A6;">Mito</mark>: "con 64 GB de RAM el archivo de paginación sobra".

1. **Windows autoriza reservas de memoria por *commit charge*, no por RAM física.** Aplicaciones que reservan grandes espacios de direcciones (VMware, compiladores, navegadores con muchas pestañas) pueden fallar con "memoria insuficiente" teniendo 40 GB libres.
2. **Sin pagefile no hay volcado de memoria en un BSOD** — justo lo que necesitas conservar durante la validación (§4.5).
3. Ciertos juegos y motores anti-cheat exigen su presencia.
4. **El pagefile no se usa mientras haya RAM libre**: tenerlo no ralentiza nada.

## 8.4 Hibernación — los números reales

| Concepto | Valor |
|---|---|
| Tamaño de `hiberfil.sys` (tipo *full*) | **40 % de la RAM** → ~25,6 GB con 64 GB |
| Resistencia del NV3 2 TB | **≈640 TBW** |
| Hibernaciones para consumir el 1 % de la resistencia | **≈250** |
| Hibernaciones para agotarlo por completo | **≈25.000** (17 al día durante 4 años) |

<mark style="background: #FFF3A3A6;">El argumento de "destruye el SSD" es falso.</mark> Pero **el del espacio sí es válido**, y hay una razón mejor todavía:

**Desactivar la hibernación desactiva también el Inicio rápido (Fast Startup)**, que guarda el estado del kernel entre reinicios. Eso **oculta problemas de drivers, complica el diagnóstico y produce falsos "ya he reiniciado"**. Para un equipo de trabajo técnico, arrancar siempre limpio es preferible.

```powershell
powercfg.exe /hibernate off
```

<mark style="background: #FFB86CA6;">Lo que asumes</mark>: sin suspensión híbrida, un corte de luz durante una suspensión pierde la sesión. Con 64 GB de VMs abiertas eso duele. **Recomendación: apaga en lugar de suspender, o instala un SAI** (que además protege la fuente y el SSD de cortes bruscos).

Alternativa intermedia: `powercfg /h /type reduced` — recuperas Fast Startup con ~13 GB en vez de 25, pero sin hibernación real.

## 8.5 Exclusiones — importante en tu flujo de trabajo

Indexar ficheros `.vmdk` de 40-80 GB o carpetas `node_modules` es I/O de fondo puro desperdicio, y en un SSD sin DRAM se nota más.

**Panel de control → Opciones de indización → Modificar → excluir:**
- La carpeta de VMs de VMware
- Repositorios grandes (`node_modules`, `vendor`, `.git`, `pkg/mod` de Go)
- Carpetas de wordlists y herramientas de varios GB

```powershell
# Defender: SOLO la carpeta de VMs y su proceso.
# NUNCA excluyas la carpeta de descargas ni las herramientas bajadas de Internet.
Add-MpPreference -ExclusionPath    "D:\VMs"
Add-MpPreference -ExclusionProcess "vmware-vmx.exe"
```

## 8.6 Sensor de almacenamiento

`Configuración` → `Sistema` → `Almacenamiento` → `Sensor de almacenamiento`

| Ajuste | Valor |
|---|---|
| Sensor de almacenamiento | **Activado** |
| Limpieza automática de contenido de usuario | **Activado** |
| Ejecutar el sensor | **Durante poco espacio en disco** |
| Papelera de reciclaje | **30 días** |
| 🔴 **Carpeta Descargas** | 🔴 **NUNCA** |

<mark style="background: #FF5582A6;">La regla de Descargas es peligrosa en tu caso concreto</mark>: borra archivos que no se hayan **abierto** en X días. Tu flujo descarga binarios de herramientas, wordlists, exploits de PoC, ISOs e informes que **se usan sin "abrirse"** (se referencian desde scripts, se copian a VMs, se pasan por línea de comandos). Windows los marca como no accedidos y los borra. **Pérdida silenciosa de datos y, en auditoría, pérdida de evidencias.**

## 8.7 Mantenimiento mensual

| Herramienta | Qué mirar | Alarma |
|---|---|---|
| **CrystalDiskInfo** | `Percentage Used` / Salud | Investigar por debajo del 90 % |
| CrystalDiskInfo | `Total Host Writes` | Comparar con los ≈640 TBW |
| CrystalDiskInfo | `Temperature` | > 70 °C sostenido → mejorar disipación M.2 |
| **Kingston SSD Manager** | Firmware | Actualizar solo si el changelog es relevante |

## 8.8 🟠 Recomendación de hardware

Un único NVMe de gama de entrada, sin DRAM, alojando a la vez el sistema, los juegos a 3840×2560, los repositorios y las máquinas virtuales **es el cuello de botella estructural de este equipo** — por delante del disipador.

**Propuesta**: un segundo NVMe con DRAM y TLC (clase KC3000, Fury Renegade, SN850X, 990 Pro o equivalente Gen4/Gen5) **dedicado a VMs y repositorios**, dejando el NV3 para sistema y juegos.

- Arranque y snapshots de VMs sustancialmente más rápidos
- El NV3 deja de llenarse: recuperas margen de SLC y de resistencia
- Aíslas el I/O pesado del disco de sistema
- ~100-160 € por 2 TB

Es **la mejora de hardware con mejor relación coste/beneficio** para este perfil de uso.

---
---

# 9. RED

## 9.1 El principio

Los paquetes de un juego online son **UDP, pequeños (50-200 bytes) y poco frecuentes (60-128 por segundo)**. Prácticamente todas las funciones de descarga (*offloading*) del adaptador están diseñadas para **flujos TCP grandes**. Desactivarlas "para reducir la latencia del juego" es como quitarle el remolque a un camión para ir más rápido en bicicleta: no es que ayude poco, es que **no interviene**.

## 9.2 Configuración del adaptador

`Configuración` → `Red e Internet` → `Configuración de red avanzada` → `Ethernet` → `Más opciones de adaptador` → `Configurar...` → `Opciones avanzadas`

### 🟢 Dejar HABILITADO (contra la mayoría de guías)

| Función | Por qué NO desactivarla |
|---|---|
| **Todos los Checksum Offload** (IPv4/IPv6, TCP/UDP, Rx y Tx) | Descargan el cálculo a la NIC. Desactivarlos **sube el uso de CPU** sin bajar latencia |
| **Descarga de gran envío v2 (LSO)** | Solo afecta a envíos TCP grandes |
| **Moderación de interrupción** | Desactivarla genera una interrupción por paquete → más DPC, más CPU, sin mejora perceptible |
| **Control de flujo** | Evita pérdida de paquetes bajo saturación |
| **Velocidad y dúplex** | <mark style="background: #FF5582A6;">Autonegociación siempre.</mark> Forzarlo a mano es causa clásica de dúplex desajustado |
| **RSS** (si el driver lo expone) | Distribuye interrupciones entre núcleos. Desactivarlo las concentra en el núcleo 0: **eso sí genera picos de DPC** |

### 🔧 Ajustar

| Función                                                     | Valor                                       | Motivo                                                                                                                        |
| ----------------------------------------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Búferes de recepción**                                    | **Máximo disponible** (*4096, normalmente*) | Absorbe ráfagas. Cuesta unos MB de RAM                                                                                        |
| **Búferes de transmisión**                                  | **Máximo disponible** (*4096, normalmente*) | Idem                                                                                                                          |
| **RSC** (si el driver lo expone)                            | **Deshabilitado**                           | El único offload con caso legítimo: agrupa segmentos TCP añadiendo latencia a SSH/RDP interactivo. No afecta al UDP de juegos |
| **Trama Jumbo**                                             | **Deshabilitado (1500)**                    | Solo útil en redes internas controladas de extremo a extremo                                                                  |
| **Reactivar en coincidencia de patrones**                   | **Desactivado**                             | Evita despertares espurios. Deja el **Magic Packet** si usas WOL                                                              |
| EEE / Ethernet ecológico / Gigabit Lite / Power Saving Mode | Indiferente                                 | EEE sale de reposo en microsegundos. Desactivarlos no hace daño ni bien                                                       |

<mark style="background: #ADCCFFA6;">Nota</mark>: el driver Realtek 2.5GbE de esta placa **no expone RSS ni RSC**. Si no los ves, no es un problema: no hay nada que hacer.

Para conocer el <mark style="background: #ADCCFFA6;">máximo posible en los búferes</mark>: 
- Presiona **Windows + X** y abre el **Administrador de dispositivos**.
- Despliega la categoría **Adaptadores de red**.
- Haz clic derecho sobre tu tarjeta de red principal (suele llevar "GbE", "Realtek", "Intel" o "Ethernet" en el nombre) y selecciona **Propiedades**.
- Ve a la pestaña **Opciones avanzadas**.
- Busca en la lista **Búferes de recepción** (Receive Buffers) y luego **Búferes de transmisión** (Transmit Buffers).
- **El truco:** En la casilla de "Valor" a la derecha, borra el número actual y escribe una cifra exageradamente alta, como `9999`.
- Haz clic en cualquier otra opción de la lista de la izquierda (o pulsa Enter). El sistema corregirá automáticamente tu `9999` y lo cambiará por el valor máximo real que soporta tu hardware (por ejemplo, lo bajará a `512`). ¡Ese es tu máximo!

## 9.3 TCP global — no tocar

```powershell
netsh int tcp show global
```

| Parámetro | Valor correcto | Mito |
|---|---|---|
| Receive Window Auto-Tuning | **normal** | *"Ponerlo en disabled reduce lag"* → **falso y dañino**: hunde el throughput en enlaces rápidos |
| Congestion Control Provider | **cubic** (defecto) | — |
| ECN Capability | **disabled** (defecto) | Habilitarlo causa problemas con routers antiguos |

**Mito del 20 % de ancho de banda reservado (QoS)**: la directiva *"Limitar el ancho de banda reservable"* **no reserva ancho de banda permanentemente**. Solo garantiza hasta un 20 % a aplicaciones que lo soliciten explícitamente vía QoS API, y **solo mientras lo solicitan**. Si nadie lo pide, está disponible al 100 %. Cambiarla no aumenta la velocidad.

`sudo netsh int ip set global taskoffload=enabled` es **el valor por defecto**: ejecutarlo no cambia nada.

## 9.4 Diagnóstico

**LatencyMon**, 10 minutos, sistema en reposo con navegador y Discord abiertos (el escenario real).

| Resultado | Interpretación |
|---|---|
| < 500 µs | ✅ Excelente |
| 500-1000 µs | ✅ Correcto |
| 1000-2000 µs | ⚠️ Investigar el driver señalado |
| > 2000 µs | 🔴 Problema real |

**Sospechosos habituales en placas ASUS**, por frecuencia: `AsIO3.sys` / `AsusCertService` (Armoury Crate), drivers RGB, `Wdf01000.sys` asociado a un USB concreto, drivers de red desactualizados, software de captura y overlays.

---
---

# 10. PRIVACIDAD

## 10.1 Sin herramientas de terceros

Todo lo que necesitas está en `Configuración` → `Privacidad y seguridad` y en `gpedit.msc`. **Documentado, reversible y auditable** — a diferencia de un debloater.

| Sección | Ajuste |
|---|---|
| General | **Todo desactivado** (id. de publicidad, seguimiento de inicios de app, contenido sugerido) |
| Voz / Personalización de entrada manuscrita | **Desactivado** |
| Comentarios y diagnósticos | **Datos de diagnóstico opcionales: NO** · **Experiencias personalizadas: NO** · Frecuencia de comentarios: **Nunca** |
| Historial de actividades | **Desactivado** |
| Permisos de aplicaciones | Revisar cámara, micrófono, ubicación uno a uno |
| Buscar en Windows | **Desactivar la búsqueda en la nube** y el historial |

## 10.2 Aplicaciones preinstaladas

```powershell
"*BingNews*", "*BingWeather*", "*ZuneMusic*", "*ZuneVideo*", "*MicrosoftSolitaire*", "*Clipchamp*", "*PowerAutomateDesktop*", "*WindowsFeedbackHub*", "*GetHelp*", "*Todos*" | ForEach-Object { Get-AppxPackage $_ | Remove-AppxPackage }
```

## 10.3 Tareas programadas de telemetría

Coherente con `DiagTrack` deshabilitado. Riesgo nulo, reversible.

```powershell
@(
 '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
 '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
 '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp',
 '\Microsoft\Windows\Application Experience\MareBackup',
 '\Microsoft\Windows\Feedback\Siuf\DmClient',
 '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
 '\Microsoft\Windows\PI\Sqm-Tasks',
 '\Microsoft\Windows\Autochk\Proxy'
) | ForEach-Object {
    $p = Split-Path $_ -Parent; $n = Split-Path $_ -Leaf
    Disable-ScheduledTask -TaskPath "$p\" -TaskName $n -ErrorAction SilentlyContinue | Out-Null
}
```

<mark style="background: #FF5582A6;">NO deshabilitar</mark>: `ScheduledDefrag`, `Chkdsk\*`, `Data Integrity Scan\*`, `SystemRestore\SR`, `Registry\RegIdleBackup`, `Windows Defender\*`, `UpdateOrchestrator\*`, `TPM\*`, `Sysmain\*` ni **`WindowsColorSystem\Calibration Loader`** (es el que aplica los perfiles ICC de tus monitores).

## 10.4 Copilot, Widgets y Recall

`gpedit.msc` → `Configuración del equipo` → `Plantillas administrativas` → `Componentes de Windows`

- **Windows Copilot** → Desactivar
- **Widgets** → Deshabilitar
- **Recall** → `Configuración → Privacidad → Recall y snapshots` → desactivar, o eliminar la característica por completo

---
---

# 11. GPU — PANEL DE CONTROL NVIDIA

Configuración global adaptada a **RTX 5070 Ti + 3840×2560 + 60 Hz sin VRR + máxima calidad visual**.

| Opción | Valor | Motivo |
|---|---|---|
| **Modo de control de energía** | 🔴 **Normal** | <mark style="background: #FF5582A6;">"Máximo rendimiento preferido" a nivel global cuesta 20-40 W y 8-12 °C en idle y NO da un solo FPS con V-Sync a 60 Hz.</mark> Si un juego concreto muestra oscilación de relojes, crea un **perfil por juego** |
| **Modo de baja latencia** | **Ultra** | Con V-Sync ON gestiona la cola y auto-limita. Se ignora solo cuando el juego tiene Reflex |
| **Sincronización vertical** | **Activado** | Obligatorio: el RD280U no tiene Adaptive Sync |
| **Frecuencia máxima de fotograma** | **60** | 🔴 Ver §14.2: capar a 58 sin VRR genera judder |
| **Tecnología del monitor** | **Actualización fija** (BenQ) · **G-SYNC Compatible** (Keep Out) | Se configura **por monitor** |
| **Frecuencia de actualización preferida** | **La más alta disponible** | Inocuo a 60 Hz |
| **Filtrado anisotrópico** | **×16** | Coste ≈0, ganancia clara en superficies oblicuas |
| **Filtrado de texturas – Calidad** | **Alta calidad** | Desactiva las optimizaciones de muestreo |
| **Filtrado – Diferencia de LOD** | 🔴 **Permitir** (no "Fijación") | Ver el bloque de abajo |
| **Filtrado – Optimización trilineal / muestreo anisotrópico** | **Desactivadas** | Redundantes con "Alta calidad" |
| **Escalado de imagen** | **Desactivado** | Renderiza por debajo de nativo |
| **FXAA / MFAA / AA transparencia** | **Desactivados** | Legacy DX9/DX11. FXAA además emborrona |
| **AA – Modo** | **Controlado por la aplicación** | — |
| **Oclusión ambiental** | **Desactivado** | El AO por driver solo funciona en DX9 |
| **Triple búfer** | **Desactivado** | Solo aplica a OpenGL |
| **Caché de sombreadores** | **10 GB** | Reduce el stutter de compilación de shaders |
| **Optimización enlazada (threaded)** | **Automático** | Forzarlo rompe algunos motores |
| **Método Vulkan/OpenGL** | **Automático** | "Preferir nativo" desactiva la capa DXGI que algunos títulos necesitan para overlays |
| **Compatibilidad OpenGL GDI** | **Preferir rendimiento** | — |
| **DSR / Factores DLDSR** | **Desactivado** globalmente | Perfiles puntuales por juego (§13.4) |
| **CUDA – Política de memoria** | **Por defecto** global · **"Sin respaldo del sistema"** en los 3-4 juegos más pesados | Ver abajo |

## 11.1 Por qué "Permitir" y no "Fijación" en el LOD

"Fijación" (Clamp) impide que una aplicación aplique un *mip LOD bias* negativo. Era un buen consejo en juegos DX9 antiguos con *shimmering*... **en 2008**.

<mark style="background: #FFF3A3A6;">Hoy es contraproducente</mark>: **DLSS, DLAA, FSR y prácticamente todo TAA moderno aplican deliberadamente un mip bias negativo** calculado a partir del factor de escala. Es un requisito de diseño: sin él, al renderizar a menor resolución interna las texturas se verían borrosas y el reconstructor temporal no tendría detalle que recuperar. Forzar Clamp compite con ese mecanismo y produce exactamente lo que quieres evitar: **texturas más blandas**.

La estabilidad temporal la aporta el **modelo transformer de DLSS**, que es mucho mejor herramienta para ese fin.

<mark style="background: #ADCCFFA6;">Excepción legítima</mark>: si juegas a algo pre-2012 en DX9 con shimmering visible, crea un **perfil por juego** con Clamp. Nunca global.

## 11.2 Sobre la política de memoria CUDA

El comportamiento por defecto ("usar la memoria del sistema como respaldo") **evita cierres por falta de VRAM**, pero cuando se activa el rendimiento **se desploma** (de 60 FPS a 5-15 con stuttering severo), porque la GPU pasa a leer texturas por PCIe.

Con **16 GB a 3840×2560**, algunos títulos AAA con texturas ultra + ray tracing pueden rozar el límite. Recomendación:

- **Global**: valor por defecto (respaldo activo). Evita cierres en aplicaciones de trabajo, CUDA y VMs.
- **Por juego, en los 3-4 más pesados**: **"Prefer No Sysmem Fallback"**. Si te pasas de VRAM, el juego avisa o baja texturas en lugar de convertirse en una presentación de diapositivas. Es información diagnóstica, no un fallo.

---
---

# 12. GPU — NVIDIA APP

| Opción | Valor | Motivo |
|---|---|---|
| **Anulación de DLSS – Modelo** | **Última versión (Latest)** | Aplica el **transformer de 2ª generación (DLSS 4.5)**: 5× la potencia de cómputo del anterior y procesamiento en espacio lineal → menos ghosting, bordes más limpios, mejor estabilidad temporal |
| **Anulación – Super Resolución** | 🔴 **Usar la configuración de la aplicación** | <mark style="background: #FFB86CA6;">No fuerces DLAA globalmente</mark>: decide por juego (§13.3) |
| **Anulación – Generación de fotogramas** | 🔴 **Desactivada** | §14.3 |
| **Ray Reconstruction** | **Última versión** | Mejor denoising en títulos con path tracing |
| **RTX Dynamic Vibrance** | **Desactivado** | Altera la precisión de color |
| **RTX Video Super Resolution** | **Activado, calidad 3-4** | Mejora de forma real el vídeo web por debajo de 1080p |
| **RTX Video HDR** | **Desactivado** | Ninguno de tus monitores tiene HDR aprovechable (§13.2) |
| **Superposición / overlay** | **Desactivado** si no lo usas | Un hook menos en cada juego |

---
---

# 13. GPU — UNDERVOLT Y CURVA V/F

## 13.1 Perfiles (MSI Afterburner)

| Perfil | Voltaje | Frecuencia | Uso |
|---|---|---|---|
| **1 — "Eficiencia"** (por defecto) | **850 mV** | **2500 MHz** | Uso diario. Entrega los mismos 60 FPS con 15-25 W menos |
| **2 — "Máximo"** (puntual) | 925 mV | 2650-2700 MHz | Solo si un título no llega a 60 FPS ni con DLSS Quality |

**Cómo aplicarlo:**
1. `Ctrl+F` para abrir el editor de curva
2. Selecciona el punto de 850 mV y súbelo a 2500 MHz, `Enter`
3. Selecciona todos los puntos a la derecha (`Shift` + arrastrar) y aplánalos con `Ctrl+Enter`
4. Aplicar (✓) y guardar en un perfil
5. <mark style="background: #FFB86CA6;">Marca "Aplicar al inicio de Windows" solo cuando lleves 2 semanas sin incidencias</mark>

**Power Limit y Temp Limit: por defecto.** Con un objetivo firme de 60 FPS, entregar los mismos fotogramas con menos vatios es objetivamente mejor.

## 13.2 Memoria de la GPU — el detalle que casi nadie explica

La memoria **GDDR6X y GDDR7 de NVIDIA incorpora detección de errores con reintento (EDR)**. Cuando una transacción falla su comprobación, **no produce un artefacto ni un cuelgue: se reintenta**.

<mark style="background: #FF5582A6;">Consecuencias contraintuitivas:</mark>

1. **Un overclock de memoria inestable no da pantallazos ni artefactos. Da MENOS rendimiento, silenciosamente.**
2. **Existe un "codo"**: subes el offset, el rendimiento sube... hasta un punto donde empieza el reintento masivo y el rendimiento **cae** mientras el reloj sigue subiendo.
3. **"Llevo meses sin que se cuelgue" no demuestra absolutamente nada.**

### Protocolo del codo (45 min)

| Paso | Acción |
|---|---|
| 1 | Fija el core al perfil "Eficiencia" y **no lo toques** durante toda la prueba |
| 2 | Ejecuta **3DMark Steel Nomad** (o Port Royal, que carga más la memoria) con memoria a **+0**. Anota la puntuación |
| 3 | Repite con **+400, +600, +800, +1000, +1200**. **Tres pasadas por escalón**, usa la mediana |
| 4 | Grafica puntuación vs offset. **El codo es donde la curva deja de subir o empieza a bajar** |
| 5 | Offset final = **el punto del codo menos 200 MHz** |
| 6 | **OCCT → VRAM test, 30 minutos** en el candidato final. **Cero errores** es el único resultado aceptable |

<mark style="background: #ADCCFFA6;">Atajo razonable</mark>: si no te apetece el test, deja la memoria en **+400**. Pierdes un 0-1 % que no vas a ver a 60 FPS y eliminas la incógnita. Un overclock de memoria sin validar en un equipo cuyo objetivo es "estabilidad absoluta" es una contradicción.

## 13.3 DLSS — decisión por juego, no global

**Estado del arte (2026)**: DLSS 4.5 introduce el transformer de 2ª generación, que hace la penalización de bajar de DLAA a Quality o Balanced **mucho menor que hace dos años**. NVIDIA afirma que Performance es ya comparable al nativo.

### Regla de decisión para 3840×2560 (9,83 Mpx) con objetivo de 60 FPS

| Situación | Configuración | Resolución interna |
|---|---|---|
| **Va sobrado (>90 FPS nativo)**: indies, pre-2020, estrategia | **DLAA** + modelo Latest | 3840 × 2560 |
| **Va justo (60-90 FPS)**: AAA sin RT pesado | **DLSS Quality** (67 %) | 2573 × 1715 |
| **No llega (40-60 FPS)**: UE5 con Lumen, RT activo | **DLSS Balanced** (58 %) | 2227 × 1485 |
| **Muy lejos (<40 FPS)**: path tracing | **DLSS Performance** (50 %) + **Ray Reconstruction** | 1920 × 1280 |
| Extremo | Bajar ajustes gráficos **antes** de ir a Ultra Performance | — |

<mark style="background: #FFB86CA6;">Por qué no DLAA en todo</mark>: a 9,83 Mpx, DLAA cuesta el 100 % de la carga de rasterizado. En un UE5 con Lumen, la diferencia entre DLAA y DLSS Quality con el transformer de 2ª gen es **apenas perceptible a 164 PPI**, mientras que la diferencia de rendimiento es del **35-45 %**. Cambiar 40 FPS por 60 estables es una mejora de experiencia mucho mayor.

### Ajustes complementarios

| Tecnología | Valor | Motivo |
|---|---|---|
| **NVIDIA Reflex** | **On** (no "On + Boost") | §14.1. "Boost" sube el consumo para ganar 1-2 ms que a 60 Hz no compensan |
| **Ray Reconstruction** | **Activado** en títulos con RT/PT | Sustituye los denoisers artesanales |
| **Nitidez / Sharpening** | **Desactivado o mínimo** | El transformer no lo necesita. <mark style="background: #FF5582A6;">Nunca combines el afilado del driver con DLSS</mark> |

## 13.4 DSR / DLDSR

**Solo por juego, en títulos ligeros y antiguos.** A 3840×2560, el factor 1.78× son 5120×3413 (17,5 Mpx): solo viable en juegos con 15+ años. **No combinar con DLSS.**

---
---

# 14. GAMING A 3840 × 2560 @ 60 Hz

## 14.1 El dato que determina toda la estrategia

<mark style="background: #FF5582A6;">El BenQ RD280U no tiene VRR.</mark> Esto invalida la mayoría de consejos que circulan, porque casi todos asumen G-SYNC.

En un panel de refresco fijo solo hay tres configuraciones coherentes:

| Estrategia | Tearing | Latencia | Frametime | Veredicto |
|---|---|---|---|---|
| **A. V-Sync ON + Reflex ON** | ❌ Ninguno | Baja | ✅ Perfecto (16,67 ms clavados) | ✅ **RECOMENDADA** |
| **B. V-Sync ON + Baja latencia Ultra** | ❌ Ninguno | Media-baja | ✅ Perfecto | ✅ Alternativa sin Reflex |
| **C. V-Sync OFF + cap a 60** | ✅ Visible | La más baja | Bueno | Solo competitivo |
| ~~D. Cap a 58 con V-Sync~~ | ❌ Ninguno | Media | 🔴 **Judder periódico** | 🔴 **Incorrecta** |

### Configuración recomendada

**En el juego:**

| Ajuste | Valor |
|---|---|
| V-Sync | **Activado** |
| NVIDIA Reflex | **Activado (On)** |
| Limitador de FPS interno | Desactivado |
| Modo de pantalla | **Pantalla completa exclusiva** cuando esté disponible |

**Por qué funciona**: Reflex no es un limitador de FPS, es un mecanismo que **sincroniza cuándo la CPU envía trabajo a la GPU** para que la cola de render esté prácticamente vacía al presentar. Con V-Sync activo, la mayor parte de la latencia tradicional viene precisamente de esa cola acumulada. Reflex la elimina.

Resultado: **eliminación total de tearing y consistencia perfecta de frametime, con latencia cercana a V-Sync desactivado.**

| Configuración | Latencia total estimada @60 Hz |
|---|---|
| V-Sync ON, sin Reflex ni LLM | ~65-85 ms |
| V-Sync ON + LLM Ultra | ~45-60 ms |
| **V-Sync ON + Reflex ON** | **~35-50 ms** |
| V-Sync OFF, cap 60 | ~30-45 ms (con tearing) |

<mark style="background: #ADCCFFA6;">Perspectiva honesta</mark>: a 60 Hz el propio periodo de refresco son 16,67 ms. La diferencia entre A y C es de **aproximadamente un fotograma**. Perceptible en un shooter competitivo, irrelevante en un RPG o en WoW. Si un título concreto se te hace pesado, prueba la C **en ese título**, no globalmente.

## 14.2 Por qué NO capar a 58 FPS

Con V-Sync activo y el motor generando 58 fotogramas frente a 60 refrescos, el compositor **repite un fotograma dos veces por segundo**:

```
16,7 · 16,7 · 16,7 … 33,3 … 16,7 · 16,7 … 33,3 …
                      ↑ repetición      ↑ repetición
```

Dos micro-tirones por segundo, perceptibles en paneos de cámara. Se sacrifica suavidad **para proteger una ventana VRR que no existe**.

*(Capar a refresco − 2/3 sí es la práctica correcta **con** G-SYNC/FreeSync: evita que la tasa toque el techo y active V-Sync. Es un buen consejo aplicado al hardware equivocado.)*

## 14.3 Frame Generation: NO en el monitor de 60 Hz

Frame Generation inserta fotogramas interpolados entre dos renderizados reales. Para hacerlo **debe retener el fotograma más reciente** hasta generar el intermedio, lo que introduce una latencia estructural de ~medio fotograma base más el tiempo de inferencia.

**El problema a 60 Hz es aritmético:**

| Configuración | Fotogramas reales/s | Latencia base | Percibido |
|---|---|---|---|
| 60 FPS nativos | **60** | 16,7 ms | Referencia |
| 60 FPS con FG 2× | **30** | 33,3 ms | **≈ el doble** + coste de FG |
| 60 FPS con MFG 3× | **20** | 50 ms | Mucho peor |
| 60 FPS con MFG 4×/6× | 15 / 10 | 66 / 100 ms | Inaceptable |

Con el techo en 60 fotogramas mostrados, activar FG **no añade fotogramas: sustituye reales por interpolados**. Misma fluidez visual, **respuesta de 30 FPS**, más artefactos en bordes y HUD, y **0,5-1,5 GB de VRAM** extra que con 16 GB a 3840×2560 no sobran.

<mark style="background: #BBFABBA6;">Regla práctica</mark>: **usa FG solo si la tasa base sin FG es ≥60 FPS y el panel refresca ≥120 Hz.** En tu equipo eso solo se cumple en el Keep Out (1080p, 180 Hz, con VRR).

Dato revelador: el **Dynamic Multi Frame Generation** de DLSS 4.5 ajusta el multiplicador para igualar el refresco, y NVIDIA lo documenta explícitamente para pantallas de **120 a 360 Hz+**. En un panel de 60 Hz el multiplicador óptimo que calcularía sería 1×. **La propia tecnología está de acuerdo.**

## 14.4 Ajustes in-game que más aportan

Para las prioridades declaradas (nitidez, ausencia de shimmering, estabilidad temporal, claridad a larga distancia):

| Ajuste | Prioridad | Por qué |
|---|---|---|
| **Calidad de texturas: Máxima** | 🥇 Altísima | Coste ≈0 si cabe en VRAM. Es lo que más se nota a 164 PPI. **Vigila los 16 GB** |
| **Filtrado anisotrópico ×16** | 🥇 Alta | Coste ≈0. Define suelos y carreteras |
| **Distancia de dibujado / LOD: Máxima** | 🥇 Alta | Ataca directamente la "claridad a larga distancia" y elimina *pop-in* |
| **Calidad de sombras: Alta (no Ultra)** | 🥈 Media | El salto Alta→Ultra cuesta 10-15 % por una diferencia mínima |
| **RT de reflejos** | 🥈 Media | Gran impacto visual en superficies húmedas y metálicas. Caro |
| **RT de iluminación global** | 🥉 Variable | El más caro. Solo si el juego llega a 60 con él |
| **Oclusión ambiental** | Media | La del juego, **nunca la del driver** |
| **Motion Blur** | **Desactivar** | Reduce la nitidez percibida |
| **Aberración cromática / Grano / Viñeta** | **Desactivar** | Degradan nitidez y precisión de color por diseño |

## 14.5 Presupuesto de rendimiento realista

| Tipo de juego | Configuración | ¿60 FPS? |
|---|---|---|
| Competitivos (CS2, Valorant, Overwatch) | Nativo/DLAA, todo alto | ✅ Muy sobrado |
| MMO (WoW, FFXIV) | DLAA o DLSS Quality | ✅ Sobrado |
| AAA 2023-2025 sin RT pesado | DLSS Quality, ultra | ✅ Sí |
| AAA 2026 con RT | DLSS Quality/Balanced, RT medio-alto | ✅ Probable |
| UE5 con Lumen + Nanite | DLSS Balanced, ajustes altos | ⚠️ Justo |
| Path tracing (Cyberpunk PT, Alan Wake 2 PT) | DLSS Performance + Ray Reconstruction | ⚠️ Puede que no |

<mark style="background: #FFF3A3A6;">Expectativa correcta</mark>: el cuello de botella dominante es **la GPU**. El 7800X3D está muy por encima de lo necesario para alimentar 60 FPS a esta resolución. **La optimización de CPU de este documento no te dará FPS en juegos** — te dará menos calor, menos ruido y compilaciones más rápidas.

---

# 15. MONITORES Y CALIDAD VISUAL

## 15.1 🔴 La recomendación de mayor impacto, y es gratis

> **Lee la documentación en el BenQ. Deja el Keep Out para vídeo y como pantalla secundaria.**

| | BenQ RD280U | Keep Out XGM27X |
|---|---|---|
| **Densidad de píxeles** | **164 PPI** | 81,6 PPI |
| Píxeles por carácter de texto | **~4× más** | referencia |
| Panel para texto | IPS (subpíxeles RGB uniformes) | **VA** (gamma dependiente del ángulo, *smearing* en negros) |
| Acabado | **Nano Matte** (antirreflejos sin cristalización) | Brillo estándar |
| Relación de aspecto | **3:2** — 2560 px de alto | 16:9 — 1080 px de alto |
| Modos de lectura | **ePaper, Coding Dark, Coding Light, M-book** | Ninguno |

<mark style="background: #FF5582A6;">Ninguna configuración de software compensa 82 PPI en un panel VA.</mark> Si pasas horas leyendo documentación, este cambio de hábito supera a todo lo demás de este documento junto. Coste: **0 €**.

El RD280U está diseñado literalmente por BenQ para programadores: modo ePaper para lectura prolongada, relación 3:2 que muestra un 33 % más de líneas de texto que un 16:9 a igual anchura, y cuatro veces la densidad.

## 15.2 HDR: desactivado en ambos

| Requisito para HDR aprovechable | BenQ RD280U | Keep Out XGM27X |
|---|---|---|
| Brillo pico | 400 nits ❌ (harían falta ≥600) | Sin certificación ❌ |
| Atenuación local | **Ninguna** ❌ | Ninguna ❌ |
| Contraste nativo | 1200:1 | VA ~3000:1, mejor pero sin dimming |

**DisplayHDR 400 es una etiqueta de "acepta señal HDR10", no de "reproduce HDR".** Sin atenuación local ni brillo pico, activar HDR en Windows produce **negros elevados, aspecto lavado y — lo más importante para ti — el contenido SDR (documentación, IDE, escritorio) pasa por un mapeo de tonos que reduce la precisión de color**.

Consecuencia directa: **RTX Video HDR desactivado** en la NVIDIA App.

## 15.3 BenQ RD280U (DisplayPort) — principal

### En el monitor (OSD)

| Ajuste | Documentación / código | Gaming / vídeo |
|---|---|---|
| **Modo de imagen** | **Coding (Dark o Light)** o **ePaper** | **sRGB** o **User** |
| **Modo de color** | **sRGB** para trabajo con color | Display P3 / User |
| **Brillo** | **~120 cd/m²** en habitación normal | 150-200 cd/m² |
| **Contraste** | **Por defecto** | Por defecto |
| **Nitidez** | 🔴 **Valor neutro** (normalmente 5/10) | Neutro |
| **Temperatura de color** | **Normal (≈6500 K)** o User calibrado | Normal |
| **Gamma** | **2.2** | 2.2 |
| **MoonHalo** | **Activado, intensidad baja** | Opcional |
| **Low Blue Light / Flicker-free** | Activados | Activados |

<mark style="background: #FF5582A6;">Nunca subas la nitidez del OSD</mark>: genera halos artificiales alrededor del texto. El panel es de 164 PPI; no necesita ayuda.

El panel cubre **95 % DCI-P3**. Sin acotar, los colores sRGB se ven **sobresaturados**. Por eso el modo sRGB para trabajo con color — o mejor, la gestión automática de color de Windows (§15.5).

### En Windows

| Ajuste | Valor |
|---|---|
| Resolución | **3840 × 2560 (nativa)** |
| Frecuencia | **60 Hz** |
| **Escala** | **150 %** (efectivo 2560 × 1707) |
| Alternativas | 175 % si te cuesta leer · 200 % da el texto más nítido (escalado entero) pero deja poco escritorio |
| **HDR** | **Desactivado** |

### En NVIDIA (`Cambiar resolución`)

| Ajuste | Valor | Motivo |
|---|---|---|
| **Formato de color de salida** | **RGB** | <mark style="background: #FF5582A6;">Nunca YCbCr 4:2:2 en escritorio</mark>: destroza la nitidez del texto por submuestreo de croma |
| **Rango dinámico de salida** | **Completo (Full, 0-255)** | "Limitado" eleva los negros y aplasta los blancos |
| **Profundidad de color** | **10 bpc** | DP 1.4 (HBR3) tiene ancho de banda de sobra a esta resolución. Reduce el *banding* en degradados |
| Cable | **DisplayPort certificado VESA DP 1.4** | Un cable malo produce parpadeos y caídas de enlace intermitentes |

## 15.4 Keep Out XGM27X (HDMI) — secundario

Con 81,6 PPI en un panel VA, el objetivo es **minimizar los defectos**, no maximizar nada.

| Ajuste | Valor | Motivo |
|---|---|---|
| **Resolución** | **1920 × 1080 nativa** | Cualquier otra cosa la interpola |
| **Escala Windows** | **100 %** | A 82 PPI, escalar reduce escritorio sin ganar nitidez |
| **Frecuencia** | **180 Hz** | Aunque sea secundario: el cursor y el desplazamiento de texto son mucho más suaves. **Sin coste** |
| **G-SYNC Compatible** | **Activar** en el panel NVIDIA | Es el único de los dos con VRR |
| **Formato de color NVIDIA** | **RGB · Rango completo · 8 bpc** | HDMI 2.1b va sobrado a 1080p180 |
| **Nitidez del monitor** | **Valor neutro** | En VA, subirla crea halos muy visibles en texto |
| **Overdrive** | **Nivel medio, nunca el máximo** | El máximo genera *overshoot*: halos inversos al desplazar |
| **Contraste dinámico / DCR / Black Equalizer** | **Desactivados** | Cambian el brillo de forma impredecible y rompen la gamma |
| **Gamma / Temperatura** | **2.2 / Usuario ≈6500 K** | Los VA económicos tienden a verde: si el OSD lo permite, baja un par de puntos el verde |
| **Brillo** | **Igualado al del BenQ** | El desequilibrio entre pantallas es la principal causa de fatiga en setups de dos monitores |
| **HDR** | **Desactivado** | §15.2 |

### Para ver vídeo y series

- **RTX Video Super Resolution: Activado, calidad 3-4.** Mejora de forma real el contenido web por debajo de 1080p (mucho streaming entrega 720p adaptativo).
- Reproductor: **mpv** o **MPC-HC + madVR** para control total de escalado y gestión de color. Para streaming, el navegador con VSR activo.
- **Desactiva cualquier "modo película"** del monitor que aplique suavizado o interpolación.

## 15.5 Windows — ajustes comunes

| Ajuste                                       | Valor                                                 | Motivo                                                                                                                                                                                                                         |
| -------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **ClearType**                                | **Activado y calibrado en CADA monitor por separado** | `cttune.exe`. La calibración es por pantalla                                                                                                                                                                                   |
| **Administración de color automática (ACM)** | **Activada si está disponible**                       | `Configuración → Pantalla → Pantalla avanzada`. Hace que las apps SDR se rendericen con gestión de color en paneles de gama amplia. **Es la solución moderna a la sobresaturación**, mejor que forzar el modo sRGB del monitor |
| **Perfil ICC**                               | El del fabricante, o uno calibrado                    | Un colorímetro (Calibrite / X-Rite) es la única forma de precisión real                                                                                                                                                        |
| Escalado mixto (150 % + 100 %)               | Sin problema en Win11                                 | VSCode y Zed son DPI-aware                                                                                                                                                                                                     |

<mark style="background: #ADCCFFA6;">Consumo en idle con dos monitores</mark>: dos pantallas con refrescos distintos (60 y 180 Hz) pueden impedir que la GPU baje el reloj de memoria en reposo, subiendo el idle de ~15 W a ~35-45 W. Compruébalo en HWiNFO ("Memory Clock" con el escritorio en reposo). Si ocurre y te importa, prueba a bajar el secundario a 120 Hz y vuelve a medir. **No sacrifiques los 180 Hz sin haber medido primero.**

---

# 16. PERIFÉRICOS Y VENTILADORES POR SOFTWARE

## 16.1 Ratón y teclado

| Ajuste | Valor | Motivo |
|---|---|---|
| **Velocidad del puntero** | **6/11** | ✅ Único valor **sin multiplicador de escala** en Windows |
| **Mejorar la precisión del puntero** | **Desactivado** | ✅ Elimina la aceleración → mapeo 1:1 real |
| **Polling rate del ratón** | **1000 Hz** | 4000/8000 Hz elevan de forma medible el uso de CPU y los DPC. A 60 Hz (16,7 ms por fotograma), la diferencia entre 1 ms y 0,125 ms de muestreo es **indetectable** |
| **Retraso y velocidad de repetición del teclado** | **Corto / Rápida** | <mark style="background: #ADCCFFA6;">Ojo con la etiqueta</mark>: esto **no es input lag**, es autorrepetición de tecla mantenida. Es una mejora real de **productividad editando código**, y cero en gaming |
| **Administración de energía de HID y USB** | **Por defecto (marcado)** | §7.3 |

## 16.2 Aplicaciones de inicio

`Ctrl+Shift+Esc` → `Inicio`. Objetivo: **solo driver de audio, driver de GPU y tu gestor de contraseñas**. Todo lo demás se lanza cuando haga falta.

## 16.3 FanControl (recomendado)

**FanControl** (gratuito, código abierto, sin telemetría) permite lo que ninguna BIOS puede:

1. Curvas **"Mix"** que toman el **máximo entre la temperatura de la GPU y la del VRM**
2. **Suavizado temporal explícito** (media móvil de 20-30 s)
3. Histéresis independiente de subida y bajada
4. Fuentes distintas por ventilador

| Ventilador | Fuente | Curva | Suavizado |
|---|---|---|---|
| Frontales (entrada) | **GPU Temperature** | 30 % ≤50 °C → 45 % 60 °C → 65 % 70 °C → 90 % 78 °C | **30 s** |
| Trasero / superior (salida) | **Mix(max) de GPU y VRM** | 30 % ≤45 °C → 50 % 55 °C → 75 % 65 °C | **30 s** |
| CPU (opcional) | CPU Tctl | Curva de §1.6 | **10 s** |

**Beneficio adicional: te permite no instalar Armoury Crate.** Menos servicios residentes, menos DPC latency, menos actualizaciones no solicitadas.

## 16.4 Ventilador de la GPU

**Curva de fábrica — no tocar.** Las curvas de fábrica de las RTX 50 son razonables. Si quieres silencio, actúa sobre el **undervolt** (§13.1), no sobre la curva.

## 16.5 Temperaturas objetivo

| Componente | Escenario | Objetivo | Alarma |
|---|---|---|---|
| **CPU (Tctl)** | Idle | 35-45 °C | > 55 °C |
| | Gaming | 58-70 °C | > 80 °C |
| | Cinebench MT | 80-88 °C | 89 °C sostenido |
| **GPU (Core)** | Idle | 32-42 °C | > 50 °C |
| | Gaming 60 FPS cap | 55-68 °C | > 78 °C |
| **GPU (Hotspot)** | Carga | < 90 °C | > 100 °C |
| **GPU (VRAM GDDR7)** | Carga | < 85 °C | > 95 °C |
| **SSD NVMe** | Carga | < 65 °C | > 72 °C |
| **VRM de placa** | Carga | < 70 °C | > 90 °C |

## 16.6 El disipador

Noctua clasifica el **NH-U9S** para el 7800X3D como **"upgrade-optional / oc1"** (recorrido de overclock limitado). Los que obtienen **oc3** son NH-D15 G2, NH-D15 chromax.black y la familia NH-U12A.

| Escenario | Consumo CPU | Temperatura esperada | ¿Suficiente? |
|---|---|---|---|
| Idle / escritorio | 20-30 W | 35-45 °C | ✅ Sobrado |
| Lectura, IDE, navegación | 25-40 W | 40-50 °C | ✅ Sobrado |
| **Gaming 4K+** | **55-75 W** | **58-70 °C** | ✅ **Perfecto** |
| VMware, 2-3 VMs | 50-70 W | 60-72 °C | ✅ Bien |
| Compilación `-j16` | 82-95 W | 78-86 °C | ⚠️ Justo |
| Cinebench MT / Prime95 | 85-95 W | 82-88 °C | ⚠️ Al límite |

**Veredicto**: para gaming (donde estás limitado por GPU) y desarrollo, **es perfectamente adecuado**. El techo real no es térmico sino acústico: un ventilador de 92 mm tiene que girar rápido para mover el mismo aire que uno de 120/140.

<mark style="background: #BBFABBA6;">No lo cambies todavía.</mark> Aplica el Curve Optimizer (§17, 15 minutos), mide, y decide con datos. Si el ruido en compilaciones largas molesta, la respuesta correcta **no es un ventilador más rápido sino más área de disipación** (NH-U12A ≈ 3-5 °C mejor a igual ruido; NH-D15 G2 ≈ 8-12 °C mejor).

**Comprobación que sí merece la pena**: verifica el backplate AM5 y el kit de montaje correctos, y que la pasta térmica no tenga más de 2 años. Un montaje mediocre cuesta más grados que todo el tuning de este documento.

---
---

# 17. CURVE OPTIMIZER

## 17.0 Elige tu ruta antes de tocar nada

Hay **dos formas correctas** de hacer esto, y la diferencia no es técnica sino de cuánto tiempo estás dispuesto a invertir. Elegir mal es lo que produce configuraciones frágiles.

| | **RUTA A — Una sola pasada** | **RUTA B — Per-core validado** |
|---|---|---|
| Tiempo | **15 minutos** | 12-14 h desatendidas + iteraciones |
| Herramientas | Ryzen Master (2 min, luego lo borras) | Ryzen Master + CoreCycler + OCCT |
| Beneficio térmico | **−4 a −7 °C** en multihilo | −5 a −8 °C |
| Rendimiento multihilo | **+2 a +4 %** | +3 a +5 % |
| Margen de estabilidad | **Amplio por diseño** | Ajustado y verificado |
| Para quién | <mark style="background: #BBFABBA6;">**La mayoría de la gente. Recomendada.**</mark> | Quien disfruta el proceso |

<mark style="background: #FFF3A3A6;">La Ruta A captura ~85 % del beneficio con el 3 % del esfuerzo.</mark> La Ruta B existe porque el último 15 % es real, pero exige encontrar el límite de cada núcleo — y eso es, por definición, iterar hasta que algo falle.

> **Aviso que evita el error más común:** *per-core sin validación no es mejor que all-core sin validación.* Toda la ventaja del per-core es **ajustar cada núcleo a su límite**, y no puedes conocer ese límite sin buscarlo. Aplicar −30 al núcleo "peor" a ciegas es una apuesta, no una optimización.

## 17.1 El mecanismo — qué hace realmente y qué no

<mark style="background: #FF5582A6;">El Curve Optimizer NO sube tu frecuencia máxima.</mark> El 7800X3D tiene el **Fmax bloqueado en ~5050 MHz** y ningún ajuste de PBO lo cambia. [HV — confirmado en el análisis de SkatterBencher, que documenta explícitamente que *"Curve Optimizer doesn't increase the CPU's maximum boost frequency"*]

Lo único que hace es **bajar el voltaje solicitado a cada frecuencia**. La cadena de efectos es:

```
menos voltaje  →  menos calor  →  el algoritmo de boost encuentra más margen térmico
               →  sostiene frecuencias altas MÁS TIEMPO
```

Es decir: no ganas MHz de pico, ganas **MHz efectivos sostenidos**. En una CPU con un disipador de 92 mm clasificado `oc1`, eso importa más que en un equipo con refrigeración líquida.

## 17.2 El modo de fallo — por qué importa el margen

<mark style="background: #FF5582A6;">El Curve Optimizer negativo no falla bajo carga completa: falla en idle y en carga mono-hilo baja.</mark>

El motivo es que en esa zona el procesador opera en la parte baja de la curva V/F, donde el offset tiene proporcionalmente **mucho más peso** sobre el voltaje resultante. En carga multihilo el voltaje base es más alto y el mismo offset queda absorbido.

**Síntomas característicos:**

| Síntoma | Cuándo | Qué significa |
|---|---|---|
| Reinicio espontáneo **sin pantallazo azul** | Escritorio, idle, de madrugada | 🔴 El clásico. Offset demasiado agresivo |
| `WHEA-Logger` 18 / 19 | Cualquier momento | 🔴 Error de hardware corregido. El sistema no cae, pero falla |
| Cuelgue al despertar de suspensión | Transición de estado | 🔴 Idem |
| Cierre de aplicación sin explicación | Cargas ligeras | 🟠 Sospechoso |
| Cuelgue durante Cinebench o Prime95 | Carga completa | 🟡 Raro con CO. Mira antes temperatura y alimentación |

> **"Llevo tres meses jugando sin problemas" NO es evidencia de estabilidad.** Jugar carga los ocho núcleos a voltaje medio-alto: es justo el escenario donde el CO negativo *no* falla.

<mark style="background: #FFF3A3A6;">Corolario práctico</mark>: la seguridad de un CO no se mide por lo agresivo que sea, sino por **cuánto margen le dejas al mejor núcleo**, que es donde Windows manda las cargas mono-hilo.

---

# RUTA A — UNA SOLA PASADA (recomendada)

## 17.3 La idea

Como el fallo ocurre en mono-hilo, y las cargas mono-hilo van **por diseño de CPPC a los dos núcleos preferidos**, basta con:

> **Proteger esos dos núcleos y dejar los otros seis con un offset normal.**

El calor lo generan los ocho a la vez en multihilo, así que apenas pierdes beneficio térmico:

| | Offset | Núcleos |
|---|---|---|
| Preferidos (CPPC 1 y 2) | **−10** | 2 |
| Resto | **−20** | 6 |
| **Promedio ponderado en multihilo** | **−17,5** | — |

**−17,5 de media** frente a los −20 de un all-core plano: prácticamente el mismo beneficio térmico, con **el doble de margen exactamente donde ocurren los fallos**.

## 17.4 Paso 1 — identificar los dos núcleos preferidos (2 minutos)

Instala **AMD Ryzen Master** (oficial de AMD). En la vista principal verás:

- ⭐ **Estrella dorada** sobre el mejor núcleo
- ⚪ **Estrella plateada** sobre el segundo mejor

Anota los dos números y **cierra Ryzen Master**. Puedes desinstalarlo después: solo lo necesitabas para esto.

<mark style="background: #ADCCFFA6;">La numeración de Ryzen Master coincide con la del BIOS</mark> (`Core 0`…`Core 7`). No la confundas con los procesadores lógicos de Windows, que van de 0 a 15 (núcleo N = lógicos 2N y 2N+1).

**Método alternativo sin instalar nada**: lanza una carga mono-hilo (CPU-Z → Bench → Single Thread) y mira en HWiNFO64 qué núcleo se lleva la carga y alcanza el reloj más alto. Ese es el preferido nº1.

## 17.5 Paso 2 — aplicar en BIOS (10 minutos)

```
Advanced → AMD Overclocking → (Accept) → Precision Boost Overdrive

  Precision Boost Overdrive .......... Advanced
  PBO Limits ......................... Auto
  PBO Scalar ......................... Auto (1X)
  Max CPU Boost Clock Override ....... Auto / 0
  Platform Thermal Throttle Limit .... Manual → 85

  Curve Optimizer .................... Per Core

    Core <preferido nº1>  → Sign: Negative → Magnitude: 10
    Core <preferido nº2>  → Sign: Negative → Magnitude: 10
    Los otros 6 núcleos   → Sign: Negative → Magnitude: 20
```

`F10` → guardar. Después: `Tool` → `ASUS User Profile` → **Save to Profile 1**.

### Sobre el límite térmico de 85 °C

<mark style="background: #BBFABBA6;">Es un complemento de riesgo cero.</mark> `Platform Thermal Throttle Limit` es un **límite duro que no toca voltajes**: solo puede reducir, nunca desestabilizar.

| Escenario | Efecto |
|---|---|
| Gaming (58-70 °C) | **Ninguno.** No lo alcanzas |
| VMs, uso normal | **Ninguno** |
| Compilación larga, Cinebench | −1 a −2 % de rendimiento, **pico térmico y ruido acotados** |

Si prefieres el máximo rendimiento en multihilo, déjalo en **Auto (89 °C)**. Si priorizas silencio y temperatura, **85** es la elección correcta.

## 17.6 Paso 3 — la red de seguridad (esfuerzo: cero)

No es un test iterativo. Es una sola cosa:

> **Una noche, deja el PC encendido en el escritorio sin apagarlo.**

El idle prolongado es exactamente el escenario donde falla el CO negativo. Por la mañana:

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddDays(-2)} |
  Where-Object { $_.ProviderName -match 'WHEA|Kernel-Power' -and $_.Id -in 41,17,18,19,20 } |
  Select-Object TimeCreated, Id, ProviderName
```

**Vacío = has terminado.** No hay más que hacer.

Después, simplemente **vigila durante 2-3 semanas**. Si aparece un reinicio espontáneo sin pantallazo azul, aplica la tabla de abajo **una vez** y olvídate.

## 17.7 Si algo falla — el síntoma te dice qué hacer

| Síntoma | Acción (una sola vez) |
|---|---|
| Reinicio en escritorio, idle o al despertar | Los **dos preferidos**: −10 → **−5** |
| WHEA 18/19 esporádico | Los **dos preferidos**: −10 → **−5** |
| Cuelgue bajo carga completa (Cinebench, compilación) | Los **seis restantes**: −20 → **−15** |
| Sigue fallando tras lo anterior | **Todo a 0** y descarta memoria (§18.2) y alimentación antes de volver al CO |

<mark style="background: #ADCCFFA6;">No conviertas esto en una espiral de ajuste fino.</mark> Si necesitas más de dos correcciones, tu silicio no es bueno para undervolt y la respuesta correcta es dejarlo en 0 o en un −10 all-core plano.

## 17.8 Variante ultra-simple

Si ni siquiera quieres instalar Ryzen Master:

```
Curve Optimizer .................... All Cores
All Core Curve Optimizer Sign ...... Negative
All Core Curve Optimizer Magnitude . 15
```

**−15 all-core** es el valor que aguanta prácticamente cualquier 7800X3D sin validación. Peor que la Ruta A —dejas 1-2 °C sobre la mesa—, pero mucho mejor que un −20 o −25 aplicado a ciegas.

<mark style="background: #FF5582A6;">Lo que NO se hace nunca</mark>: aplicar −25 o −30 all-core "porque a un tío de un foro le funciona". Los valores de Curve Optimizer son **específicos de cada unidad de silicio**; no se copian.

---

# RUTA B — PER-CORE VALIDADO (solo si te apetece el proceso)

## 17.9 Valores de partida

```
Curve Optimizer → Per Core

  Mejor núcleo (CPPC 1) ..... −15
  2º mejor (CPPC 2) ......... −18
  Núcleos medios (3-6) ...... −25
  Dos peores (7-8) .......... −30
```

## 17.10 Validación con CoreCycler

Esto es lo que separa "no se cuelga" de "es estable".

```ini
# config.ini de CoreCycler
stressTestProgram = YCRUNCHER
mode              = SFT
runtimePerCore    = 6m
numberOfThreads   = 1
skipCoreOnError   = 1
```

**Al menos 3 ciclos completos** (≈2,5 h por ciclo con 8 núcleos, ~7 h en total, desatendidas). CoreCycler carga **un núcleo cada vez**: es el escenario exacto donde falla el CO negativo.

Cada núcleo que falle → **súbele el offset 3 puntos** y repite solo ese núcleo.

Después: **8 h de idle nocturno** + OCCT CPU Extreme 1 h + 5 arranques en frío + 3 ciclos de suspensión, todo con el visor de eventos limpio (§18.4).

## 17.11 Margen de seguridad

<mark style="background: #FF5582A6;">Cuando encuentres el límite de cada núcleo, retrocede 2-3 puntos.</mark> Un CO que pasa las pruebas justo en el límite fallará cuando suba la temperatura ambiente en verano o cuando actualices el AGESA.

---

## 17.12 Beneficio esperado — las tres configuraciones

| | Temp. multihilo | Rendimiento MT | Gaming | Riesgo sin validar |
|---|---|---|---|---|
| Stock (CO en 0) | referencia | referencia | referencia | — |
| **−15 all-core** (§17.8) | **−3 a −5 °C** | +1 a +3 % | 0-1 % | **Muy bajo** |
| **Ruta A: −10/−20** (§17.3) | **−4 a −7 °C** | **+2 a +4 %** | 0-1 % | **Bajo** |
| Ruta B: per-core validado | −5 a −8 °C | +3 a +5 % | 0-1 % | Bajo (tras validar) |
| ~~−25/−30 all-core sin validar~~ | −6 a −8 °C | +3 a +5 % | 0-1 % | 🔴 **Alto** |

<mark style="background: #FFF3A3A6;">Expectativa correcta sobre el gaming</mark>: el 7800X3D está limitado por caché y memoria, no por MHz, y a 3840×2560 con V-Sync a 60 Hz el cuello de botella es la GPU. **El Curve Optimizer no te va a dar FPS.** Te va a dar menos calor, menos ruido y compilaciones algo más rápidas. Esa es toda la promesa, y se cumple.

# 18. VALIDACIÓN Y ESTABILIDAD

> <mark style="background: #FF5582A6;">"No se cuelga" ≠ "es estable".</mark> Un sistema estable no produce **ni un solo error corregido, ni un evento WHEA, ni un fallo de aplicación no explicado, en ningún escenario** — incluidos los que casi nadie prueba: idle prolongado, arranque en frío y salida de suspensión.

## 18.1 CPU

### Si has seguido la RUTA A (§17.3) — validación mínima

| Prueba | Duración | Esfuerzo | Aprobado |
|---|---|---|---|
| **Idle prolongado** | Una noche | 🥇 **Cero: solo no apagues el PC** | 0 reinicios, 0 WHEA |
| Uso normal vigilado | 2-3 semanas | Cero | Sin reinicios inexplicados |

<mark style="background: #BBFABBA6;">Con una configuración conservadora por diseño, esto es suficiente.</mark> El idle prolongado es exactamente el escenario donde falla el CO negativo; si lo pasa, lo demás casi nunca aparece.

### Si has seguido la RUTA B (§17.9) — validación exhaustiva

| Prueba | Duración | Qué detecta | Aprobado |
|---|---|---|---|
| **CoreCycler + y-cruncher SFT** | 3 ciclos (~7 h) | 🥇 **Inestabilidad del CO en carga mono-hilo. La prueba clave** | 0 errores |
| **Idle prolongado** | 8 h (de noche) | 🥇 **El modo de fallo típico del CO negativo** | 0 reinicios, 0 WHEA |
| y-cruncher VST | 1 h | Estabilidad CPU+RAM combinada | 0 errores |
| OCCT CPU (Extreme, AVX2) | 1 h | Estabilidad bajo potencia máxima | 0 errores |
| Prime95 Small FFTs | 30 min | Temperatura máxima alcanzable | < 89 °C sostenido |
| Cinebench 2024 MT ×5 seguidos | 30 min | Consistencia bajo carga sostenida | Variación < 2 % |
| Arranque en frío | 5 ciclos | Entrenamiento de memoria | 5/5 sin fallo |
| Suspensión / reanudación | 3 ciclos | Transiciones de estado de energía | 3/3 correctos |

## 18.2 RAM

| Prueba | Duración | Aprobado |
|---|---|---|
| **TestMem5, perfil `absolut`** | 1 ciclo (~1,5 h) | 0 errores |
| y-cruncher VST | 1 h | 0 errores |
| OCCT Memory | 1 h | 0 errores |
| **5 arranques en frío** | — | Timings **idénticos** en ZenTimings las 5 veces |
| MemTest86 (solo si hay dudas) | 4 pasadas (~6 h) | 0 errores |

## 18.3 GPU

| Prueba | Duración | Qué valida |
|---|---|---|
| **OCCT VRAM test** | 30 min | 🥇 **Errores de memoria de vídeo.** Insustituible para validar el offset |
| OCCT 3D Adaptive | 30 min | Estabilidad del núcleo bajo carga variable (más exigente que carga constante) |
| 3DMark Steel Nomad Stress Test | 20 bucles | Consistencia de fotogramas: **debe superar el 97 %** |
| Port Royal ×3 por escalón | — | Test del codo de memoria (§13.2) |
| Gaming real prolongado | 2 h × 3 sesiones | El único test que reproduce cargas irregulares reales |

Señales de un OC de memoria por encima del codo: **puntuación que baja al subir el offset**, artefactos puntuales en texturas, o TDR del driver.

## 18.4 Comprobación de eventos — el filtro correcto

<mark style="background: #FFB86CA6;">Cuidado</mark>: los IDs 18/19/20 los reutilizan `WindowsUpdateClient`, `TPM`, `Wininit` y `Kernel-Boot`. Un filtro solo por ID produce **cientos de falsos positivos**. Filtra por **proveedor**:

```powershell
$since = (Get-Date).AddDays(-30)
@(
  @{N='WHEA (error de hardware)'; P='Microsoft-Windows-WHEA-Logger';  I=@(1,17,18,19,20,46,47)}
  @{N='Apagado inesperado';       P='Microsoft-Windows-Kernel-Power';  I=@(41)}
  @{N='BugCheck / BSOD';          P='Microsoft-Windows-WER-SystemErrorReporting'; I=@(1001)}
  @{N='Cierre inesperado';        P='EventLog';                        I=@(6008)}
  @{N='Driver GPU reiniciado';    P='Display';                         I=@(4101)}
  @{N='Error de disco';           P='disk';                            I=@(7,11,51,153)}
) | ForEach-Object {
    $ev = Get-WinEvent -FilterHashtable @{LogName='System';ProviderName=$_.P;StartTime=$since} -EA SilentlyContinue |
          Where-Object Id -in $_.I
    "{0,-30} {1}" -f $_.N, @($ev).Count
}
```

**Cualquier resultado distinto de 0 invalida la configuración.** Los WHEA 18/19 son errores de hardware **corregidos**: el sistema no se cae, pero está fallando.

## 18.5 Sistema completo

Antes de dar la configuración por buena, **una semana de uso normal** con:

- [ ] 20+ arranques y apagados
- [ ] 3+ ciclos de suspensión / reanudación
- [ ] Al menos un ciclo de Windows Update
- [ ] Sesiones largas de VMware con 2-3 VMs simultáneas
- [ ] Compilaciones largas
- [ ] Conexión y desconexión de todos los periféricos
- [ ] Visor de eventos: **0 WHEA · 0 Kernel-Power 41 · 0 BugCheck · 0 nvlddmkm 4101**

## 18.6 Metodología de medición

**Regla de oro**: una diferencia menor del **3 %** en FPS medio o del **5 %** en 1 % low **no es una mejora, es ruido**. Repite cada medida 3 veces y usa la mediana.

**Aplica los cambios por grupos y mide entre grupos.** Si aplicas 40 cambios y algo empeora, no tienes forma de saber cuál fue.

### Métricas — no uses "rendimiento" como palabra genérica

Diferencia siempre entre: FPS medio · **1 % low** · **0.1 % low** · frametime · input latency · frecuencia efectiva · frecuencia máxima · consumo · temperatura · ruido · utilización · estabilidad · tiempo de arranque · tiempo de apertura de aplicaciones · rendimiento multinúcleo · rendimiento mononúcleo.

Una optimización puede mejorar una y empeorar otra.

---
---

# 19. MANTENIMIENTO

| Frecuencia | Acción |
|---|---|
| **Semanal** | Visor de eventos con el filtro de §18.4 |
| **Mensual** | CrystalDiskInfo: `Percentage Used`, `Total Host Writes`, temperatura |
| **Mensual** | Limpieza de filtros de polvo |
| **Trimestral** | Repetir Cinebench + 3DMark y comparar con el baseline. Una caída >5 % indica degradación de pasta térmica, polvo o throttling |
| **Trimestral** | Revisar aplicaciones de inicio y servicios reaparecidos tras actualizaciones |
| **Semestral** | Revisar si hay BIOS con mejoras de estabilidad relevantes |
| **Anual** | Valorar cambio de pasta térmica |
| **Tras cada actualización mayor de Windows** | Verificar: VBS activo, servicios no reactivados, plan de energía intacto, registro intacto |
| **Tras cada driver NVIDIA** | Verificar que el panel de control mantiene los ajustes globales (a veces se resetean) |

## Umbrales de alarma

| Métrica | Verde | Ámbar | Rojo |
|---|---|---|---|
| Tctl CPU en gaming | < 72 °C | 72-80 °C | > 82 °C |
| Tctl CPU en Cinebench | < 85 °C | 85-89 °C | 89 °C sostenido |
| GPU Core | < 70 °C | 70-78 °C | > 80 °C |
| GPU Hotspot | < 90 °C | 90-100 °C | > 100 °C |
| GPU VRAM | < 85 °C | 85-95 °C | > 95 °C |
| SSD | < 60 °C | 60-70 °C | > 72 °C |
| Eventos WHEA / semana | **0** | 1 | ≥2 |
| DPC latency máxima | < 500 µs | 500-1500 µs | > 2000 µs |
| Consistencia 3DMark stress | > 98 % | 97-98 % | < 97 % |
| SSD `Percentage Used` | < 5 % | 5-20 % | > 50 % |

---
---

# 20. ANEXO A — LO QUE NUNCA SE HACE

Lista de tweaks populares que **no** se aplican, con el motivo en una línea.

| Tweak | Por qué no |
|---|---|
| **Deshabilitar C-States** | +20 W en idle, +8 °C, **0 FPS**. En Zen 4 los C-states son parte del algoritmo de boost |
| **Plan Alto rendimiento / Ultimate Performance** | Idem, y en Zen 4 no aportan nada sobre Equilibrado |
| **Deshabilitar SMT** | Pierdes 30-40 % en compilación y VMs. Ganancia en juegos ≈0 |
| **`msconfig` → Número de procesadores / Memoria máxima** | Herramientas de **depuración**, no de optimización. Si las marcas, arrancas con menos hardware |
| **Deshabilitar el pagefile** | Fallos de *commit* en VMware y compiladores, y sin volcados de fallo |
| **Deshabilitar SysMain o la indexación por completo** | Mito. Rompe la búsqueda. Lo correcto es excluir carpetas |
| **RAMMap / "liberadores de RAM" de forma cíclica** | Vacían la caché que acelera el sistema. Ver §20.1 |
| **Deshabilitar Defender, SmartScreen o las mitigaciones de CPU** | Indefendible en un equipo de seguridad |
| **`netsh int tcp set global autotuninglevel=disabled`** | Hunde el throughput en enlaces rápidos |
| **Deshabilitar offloads de red "por latencia"** | Suben el uso de CPU sin bajar la latencia de juego (§9.1) |
| **Frame Generation en un panel de 60 Hz** | Duplica la latencia sin añadir fluidez (§14.3) |
| **Deshabilitar fTPM o Secure Boot** | Pierdes BitLocker, Credential Guard y anti-cheat |
| **Polling rate 8000 Hz** | Más CPU y DPC; imperceptible a 60 Hz |
| **Forzar prioridades "Alta" / "Tiempo real"** | Puede dejar sin CPU a drivers y al subsistema de audio |
| **Overclock de BCLK en AM5** | Desincroniza PCIe y USB. Riesgo alto de corrupción |
| **Forzar PCIe Gen5 en el slot de la GPU** | La 5070 Ti no satura ni Gen4 x16. Ganancia 0-1 %, riesgo de errores de enlace |
| **Herramientas de debloat de terceros** | §3.1 |
| **"Optimizar" el registro con utilidades** | Sin excepción |

## 20.1 Sobre "liberar RAM"

| Técnica | ¿Ayuda? | Explicación |
|---|---|---|
| **Vaciar la Standby List** (RAMMap) | ❌ **Empeora** | La standby list es **caché de ficheros ya leídos**, contabilizada como *memoria disponible*. Vaciarla obliga a releer todo desde disco |
| **"Optimizadores de RAM" de terceros** | ❌ Empeoran | Fuerzan el vaciado del working set a disco para que el Administrador de tareas muestre un número más bajo. Resultado: más I/O y aplicaciones más lentas |
| **Forzar descarga de DLLs** (`AlwaysUnloadDll`) | ❌ No hace nada | §6.2 |
| **Matar procesos del sistema** | ❌ Peligroso | — |
| **Cerrar aplicaciones que no usas** | ✅ Sí | La única técnica que funciona |
| **Reiniciar tras días de uso** | ✅ Marginal | Solo si hay una fuga de memoria real |

> <mark style="background: #FFF3A3A6;">**"Memoria libre" es memoria desperdiciada.**</mark> Windows usa deliberadamente la RAM no asignada como caché de disco. Un sistema con 64 GB y 45 GB "en uso" (mayoritariamente caché) funciona **mejor** que el mismo con 55 GB "libres".

<mark style="background: #ADCCFFA6;">Único uso legítimo de RAMMap</mark>: **benchmarking con caché fría**, para que dos mediciones partan del mismo estado.
1. Descargar [RAMMap](https://learn.microsoft.com/es-es/sysinternals/downloads/rammap)
2. Abrir `RAMMap64.exe`
3. `Empty` → `Empty Standby List`

<mark style="background: #FF5582A6;">NO EJECUTAR CÍCLICAMENTE.</mark>

---
---

# 21. ANEXO B — NAVEGADOR (Brave)

Ajustes defendibles, sin extensiones milagrosas.

| Ajuste | Valor | Motivo |
|---|---|---|
| **Shields** | Agresivo para bloqueo de anuncios y rastreadores | — |
| **Aceleración por hardware** | **Activada** | Descarga el render a la GPU. Desactivarla sube el uso de CPU |
| **Precarga de páginas** | Preferencia personal | Consume ancho de banda y da privacidad a cambio de latencia percibida |
| **WebRTC IP handling policy** | **Default public interface only** | Evita la fuga de la IP local. Relevante en tu perfil |
| **Brave Rewards / Wallet / VPN / News** | **Desactivados** | Servicios y tareas de fondo que no usas |
| **Servicios de Brave Update** | **Manual** | Ya lo hace por defecto; no lo deshabilites o te quedas sin parches |
| **Perfiles separados** | Uno para trabajo, otro para OSINT/pentesting | Aísla cookies, sesiones y huella |

<mark style="background: #ADCCFFA6;">No apliques "hardenings" de `brave://flags` copiados de foros.</mark> Rompen sitios de forma impredecible y no dan privacidad medible sobre lo que ya hacen los Shields.

---
---

# 22. CONFIGURACIÓN MAESTRA — CHECKLIST DE UNA PÁGINA

## BIOS
```
Load Optimized Defaults → configurar → Save to Profile 1 + USB

SEGURIDAD     Secure Boot ON · CSM OFF · fTPM ON · IOMMU ON · SVM ON
              Fast Boot OFF · ErP OFF
MEMORIA       EXPO I · DRAM 6000 · UCLK==MEMCLK · FCLK Auto
              SOC 1.20 V · VDDIO/MC 1.30 V · MCR Enabled · PDE Auto
CPU           PBO Advanced · Limits AUTO · Scalar Auto · Boost Override 0
              Curve Optimizer PER CORE: -10 en los 2 preferidos (Ryzen Master)
              -20 en los otros 6   |   alternativa simple: ALL CORES -15
              Platform Thermal Throttle Limit 85
ENERGÍA       Global C-State ON · CPPC ON · Preferred Cores ON · SMT ON
              Spread Spectrum Auto
PCIe          Above 4G ON · ReBAR Auto · Slot Auto (Gen4) · ASPM Auto (BIOS)
              AHCI · NVMe RAID OFF
VENTILADORES  CPU: fuente CPU · 30/50 · 35/60 · 50/70 · 70/78 · 90/85 · 100/89
              StepUp 2-3 s · StepDown máximo · Lower Limit 200 rpm
              CAJA: fuente MB/T_Sensor · 30/35 · 40/40 · 55/45 · 75/50 · 100/55
              StepUp y StepDown al valor más lento
```

## Windows
```
DRIVERS       1. Chipset AMD (reiniciar) → 2. Windows Update → 3. NVIDIA limpio
              4. Realtek si hace falta → 5. NVIDIA App
              NO: Armoury Crate · debloaters · Adrenalin completo

SEGURIDAD     HypervisorPlatform ON · VirtualMachinePlatform ON
              Integridad de memoria ON · Credential Guard (LsaCfgFlags 2)
              Defender ON · SmartScreen ON · BitLocker ON
              Volcado de memoria del KERNEL
              Entrada de arranque dual "Laboratorio (sin VBS)"

SERVICIOS     Disabled: DiagTrack · TermService · UmRdpService · SSDPSRV
                        upnphost · lfsvc · StiSvc · WMPNetworkSvc
                        MapsBroker · PrintNotify
              NO TOCAR: SysMain · WSearch · wuauserv · WinDefend · BFE
                        EventLog · Schedule · WerSvc · PcaSvc · Xbox(Manual)
                        SCardSvr · TapiSrv · RmSvc · Audiosrv · nvcontainer

REGISTRO      SQMLogger 0 · DiagLog 0 · TCPIPLOGGER **1** · nada más

ENERGÍA       Plan EQUILIBRADO · mín 0-5 % · máx 100 % · Boost Agresiva
              Refrigeración Activa · USB selective suspend HABILITADA
              PCIe ASPM Moderado (Windows) · Disco 0 · Suspender 0
              PANTALLAS 20 min · Temporizadores de reactivación OFF
              powercfg /h off

DISCO         TRIM ON · Optimizar semanal ON · Pagefile gestionado
              ≥25 % libre · Storage Sense: Papelera 30 d · DESCARGAS NUNCA
              Exclusiones de indexación y Defender para VMs

RED           Autonegociación · offloads ON · Interrupt Moderation ON
              Buffers al máximo · RSC OFF (si existe) · Jumbo OFF
              WakeOnPattern OFF · TCP autotuning NORMAL

PRIVACIDAD    Diagnóstico opcional OFF · Historial OFF · Copilot/Widgets OFF
              Recall eliminado · 8 tareas de telemetría deshabilitadas
              Apps preinstaladas quitadas con Remove-AppxPackage
```

## GPU
```
PANEL NVIDIA  Energía NORMAL · Baja latencia ULTRA · V-Sync ON · Cap 60
              Monitor: Fija (BenQ) / G-SYNC Compatible (Keep Out)
              Aniso ×16 · Filtrado Alta calidad · LOD PERMITIR
              Escalado imagen OFF · FXAA/MFAA/AO OFF · Triple búfer OFF
              Caché shaders 10 GB · Threaded Auto · Vulkan Auto
              CUDA: por defecto global / "sin respaldo" en 3-4 juegos

NVIDIA APP    Modelo DLSS: LATEST · Super Resolución: config de la app
              Frame Generation: OFF · Ray Reconstruction: Latest
              Dynamic Vibrance OFF · Video Super Resolution ON (3-4)
              Video HDR OFF · Overlay OFF

AFTERBURNER   Perfil 1 "Eficiencia": 850 mV / 2500 MHz (curva aplanada)
              Perfil 2 "Máximo":     925 mV / 2650 MHz
              Memoria: +400 (o el codo −200 si haces el test)
              Power/Temp Limit: por defecto
```

## Monitores
```
BenQ RD280U   3840×2560 @ 60 Hz · Escala 150 % · RGB · Full · 10 bpc
(DisplayPort) HDR OFF · ClearType calibrado · ACM ON
              OSD: Coding/ePaper para leer · sRGB para color
              ~120 cd/m² · Nitidez NEUTRA · Gamma 2.2 · 6500 K · MoonHalo bajo

Keep Out      1920×1080 @ 180 Hz · Escala 100 % · RGB · Full · 8 bpc
(HDMI)        G-SYNC Compatible ON · HDR OFF · ClearType recalibrado
              Nitidez NEUTRA · Overdrive medio · DCR/Black Equalizer OFF
              Gamma 2.2 · 6500 K · Brillo igualado al BenQ

⭐ DOCUMENTACIÓN EN EL BENQ, VÍDEO EN EL KEEP OUT
```

## Gaming (por juego)
```
V-Sync ON (in-game) · Reflex ON (no Boost) · limitador interno OFF
Pantalla completa exclusiva · Frame Generation OFF
DLSS: DLAA >90 FPS · Quality 60-90 · Balanced 40-60 · Performance <40
Ray Reconstruction ON en RT/PT · Sharpening OFF
Texturas / Aniso / Distancia de dibujado: MÁXIMAS
Sombras: ALTA (no Ultra)
Motion Blur / Aberración cromática / Grano / Viñeta: OFF
```

## Periféricos
```
Puntero 6/11 · Precisión del puntero OFF · Polling 1000 Hz
Repetición de teclado al máximo (productividad, no input lag)
Administración de energía de HID/USB: POR DEFECTO
Inicio: solo audio, GPU y gestor de contraseñas
```

## Validación

MÍNIMA (ruta A) — esfuerzo prácticamente nulo
```
Una noche con el PC encendido en idle ........ 0 reinicios
TestMem5 absolut x1 .......................... 0 errores   (tras tocar memoria)
5 arranques en frío .......................... timings idénticos en ZenTimings
Visor de eventos (filtro por proveedor) ...... 0 WHEA · 0 KP-41 · 0 4101
```

EXHAUSTIVA (ruta B, o si algo falla)
```
CoreCycler + y-cruncher SFT x3 ciclos ........ 0 errores
Idle nocturno 8 h ............................ 0 reinicios
OCCT VRAM 30 min + OCCT CPU Extreme 1 h ...... 0 errores
3DMark Steel Nomad Stress .................... > 97 %
3 suspensiones / reanudaciones ............... 3/3 correctas
```

---

## Expectativa realista tras aplicar todo

| Métrica | Cambio |
|---|---|
| FPS medio en juegos | **0 %** (bloqueado a 60 por V-Sync) |
| **1 % low y 0.1 % low** | **Mejora clara** |
| **Consistencia de frametime** | **Mejora clara** |
| Rendimiento multihilo | **+2 a +4 %** |
| Rendimiento mono-hilo | 0 a +1 % |
| **Temperatura CPU en carga** | **−5 a −8 °C** |
| **Consumo en idle** | **−25 a −45 W** |
| **Ruido en escritorio y gaming** | **Reducción notable** |
| Estabilidad | **De supuesta a verificada** |

| Escenario | Consumo total (pared) | Tctl CPU | GPU |
|---|---|---|---|
| Idle / escritorio | **65-95 W** | 35-45 °C | 32-42 °C |
| Lectura, IDE | 80-120 W | 40-50 °C | 32-45 °C |
| Compilación `-j16` | 190-240 W | 78-86 °C | 35-45 °C |
| VMware, 3 VMs | 150-200 W | 60-72 °C | 35-45 °C |
| **Gaming 60 FPS bloqueados** | **220-330 W** | 58-70 °C | 55-68 °C |
| Carga completa CPU+GPU | 400-450 W | 82-88 °C | 68-75 °C |

<mark style="background: #BBFABBA6;">El titular</mark>: en juegos no verás más FPS porque el equipo ya va sobrado para 60 Hz. Lo que consigues es **un equipo más frío, más silencioso, que consume bastante menos cuando no hace nada, con una imagen más consistente y con la estabilidad demostrada en lugar de supuesta.**

---

## Referencias primarias

- [AMD — Ryzen 7 7800X3D](https://www.amd.com/en/products/processors/desktops/ryzen/7000-series/amd-ryzen-7-7800x3d.html) — Tjmax 89 °C, DDR5-5200 con 2 módulos
- [NVIDIA — RTX 5070 Family](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5070-family/) — 16 GB GDDR7, TGP 300 W
- [BenQ — RD280U](https://www.benq.com/en-us/monitor/programming/rd280u/spec.html) — 164 PPI, **sin Adaptive Sync**, DisplayHDR 400
- [Noctua — Compatibilidad 7800X3D](https://www.noctua.at/en/compatibility/by-components/cpus/amd-ryzen-7-7800x3d) — NH-U9S rating **oc1**
- [Microsoft — MMCSS](https://learn.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service) — *"Values below 10 and above 100 are clamped to 20"*
- [Microsoft — VBS / Win32_DeviceGuard](https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity)
- [Broadcom — Limitations of Host VBS Mode](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/25H2/using-vmware-workstation-pro/running-workstation-on-a-hyper-v-enabled-host/limitations-of-host-vbs-mode.html)
- [Igor's Lab — Ryzen 7000 memory tuning](https://www.igorslab.de/en/ryzen-7000-tuning-guide-infinity-fabric-expo-dual-rank-samsung-and-hynix-ddr5-in-practice-test-with-benchmarks-recommendations/) — *"beyond 6000 Mbps, the UCLK automatically goes into 1/2:1 mode"*
- [Tom's Hardware — AMD limita SoC a 1.3 V](https://www.tomshardware.com/news/amd-issues-follow-up-statement-on-ryzen-burnout-issues-limits-soc-voltages)
- [NVIDIA — DLSS 4.5](https://www.nvidia.com/en-us/geforce/news/dlss-4-5-dynamic-multi-frame-gen-6x-2nd-gen-transformer-super-res/) — MFG dinámico documentado para 120-360 Hz+
- [NVIDIA — DLSS overrides en NVIDIA App](https://nvidia.custhelp.com/app/answers/detail/a_id/5620/~/enabling-dlss-4-overrides-in-nvidia-app)
- [TechPowerUp — Kingston NV3](https://www.techpowerup.com/review/kingston-nv3/) · [TweakTown — NV3 2TB](https://www.tweaktown.com/reviews/10828/kingston-nv3-2tb-ssd-powerful-bargain/index.html)

---

*v3.0 — 19/08/2026. Versiones de referencia: Windows 11 Pro 25H2 (26200.9168) · NVIDIA 610.88 · AMD Chipset 8.08.12.551 · ASUS BIOS 3881 (AGESA ComboAM5 PI 1.3.0.1b) · DLSS 4.5 · VMware Workstation Pro 25H2. Revisar tras cualquier actualización mayor de estos componentes.*
