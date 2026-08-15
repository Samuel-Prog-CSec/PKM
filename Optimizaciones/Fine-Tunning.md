# Fine Tunning procesador (AMD)
https://www.youtube.com/watch?v=GFxSUXzwU4I
https://www.youtube.com/watch?v=4JXvewurhks
https://www.youtube.com/watch?v=rY2nlI84S0E
https://www.youtube.com/watch?v=N60M36PRHsY

---

# Fine Tunning GPU (NVIDIA)
https://www.youtube.com/watch?v=biwZbY2Hrig
https://www.youtube.com/watch?v=JS5eaKS62q4

# Mantenimiento y mejora de GPU NVIDIA (física)
https://www.youtube.com/watch?v=ZG5-vKaJuf4

# Tunning placa base
Para dejar tu ASUS TUF Gaming B650-E Wi-Fi configurada a la perfección, vamos a tocar todos los frentes: memoria, CPU, comunicación con la gráfica y gestión de ventiladores. Al tener la BIOS en su última versión, te aseguras la máxima compatibilidad y estabilidad con tu hardware.

Reinicia, pulsa `Supr` o `F2` para entrar en la BIOS, y pulsa `F7` para ir al **Advanced Mode**. Aquí tienes la hoja de ruta definitiva:

## 1. Optimización de la Memoria RAM (64GB DDR5)
En la pestaña **Ai Tweaker**, vamos a ajustar la memoria para que rinda al máximo y, sobre todo, para evitar que Windows tarde una eternidad en arrancar (un problema común en la plataforma AM5 con 64GB de RAM).
- **Ai Overclock Tuner -> EXPO I:** Esto carga las frecuencias y latencias óptimas de fábrica de tus módulos DDR5.
- **VDDCR SOC Voltage -> Manual Mode (1.20V - 1.25V):** Al activar EXPO, las placas base suelen meter demasiado voltaje al controlador de memoria (SoC), a veces rondando los 1.35V. Limitarlo a 1.20V o 1.25V es totalmente estable y le quita varios grados de temperatura al procesador, protegiendo la delicada caché 3D.
- _Uso de la lupa (F9)_ - Busca **Memory Context Restore** y ponlo en **Enabled**. Haz lo mismo buscando **Power Down Enable** y ponlo en **Enabled**. Esto evita que la placa base "entrene" la memoria DDR5 en cada encendido, reduciendo el tiempo de arranque de 40 segundos a apenas 10-15 segundos.

## 2. Undervolt y Rendimiento del Ryzen 7 7800X3D
Vamos a aplicar el ajuste para que el procesador dé más rendimiento consumiendo menos energía y manteniéndose mucho más fresco.
- Ve a **Advanced** > **AMD Overclocking** > **Precision Boost Overdrive**.
- **Precision Boost Overdrive -> Advanced**.
- **PBO Limits -> Motherboard**: Permite que la placa entregue la energía de forma óptima según sus propios componentes térmicos.
- Entra en **Curve Optimizer**:
    - Curve Optimizer: **All Cores**
    - All Core Curve Optimizer Sign: **Negative**
    - All Core Curve Optimizer Magnitude: **-20** (o -30 si ves que el sistema es totalmente estable a largo plazo). Esto recorta la curva de voltaje de los núcleos. Al estar más frío, el procesador mantendrá frecuencias de reloj más altas por sí solo durante más tiempo.

## 3. Comunicación máxima con la RTX 5070 Ti
Para jugar a 4K, la gráfica necesita poder acceder a la información sin embudos.
- Ve a **Advanced** > **PCI Subsystem Settings**.
- **Above 4G Decoding -> Enabled**.
- **ReSize BAR Support -> Auto / On**. Esto permite que el 7800X3D acceda a los 16GB (o la VRAM total que tenga tu modelo de 5070 Ti) de memoria de video de una sola vez, en lugar de hacerlo en pequeños bloques de 256MB. Aumenta directamente los _frames_ por segundo y reduce el _stuttering_ (tirones).

## 4. Virtualización a nivel de hardware
- Ve a **Advanced** > **CPU Configuration**.
- **SVM Mode -> Enabled**. Activar el hipervisor a nivel físico es vital para levantar las máquinas virtuales de los laboratorios de pentesting y defensa Blue Team sin cuellos de botella ni errores de recursos compartidos.

## 5. Configuración de ventiladores (Q-Fan Control)
Para rematar, vamos a hacer que el sistema sea silencioso y eficiente. Pulsa **F6** para abrir el panel **Q-Fan Control**.

Por defecto, las placas ASUS tienen curvas de ventilación muy agresivas que hacen que los ventiladores peguen acelerones molestos (el clásico sonido de turbina) cada vez que abres un programa, porque los Ryzen suben de temperatura muy rápido en picos cortos.
- Selecciona todos tus ventiladores del chasis y el del disipador de la CPU.
- Activa la opción de **Curva Manual**.
- Ajusta los puntos de la gráfica para que los ventiladores se mantengan a una velocidad plana y silenciosa (por ejemplo, 30-40% de potencia) hasta los **65 °C**.
- A partir de los 65 °C, haz que la curva suba gradualmente hasta el 100% de potencia al alcanzar los **85 °C - 89 °C**.
- Ajusta el **Step Up / Step Down time** (si tu BIOS lo permite en ese panel) a unos 2 o 3 segundos. Esto actúa como un amortiguador, evitando que los ventiladores se aceleren instantáneamente ante un pico de calor de medio segundo.

De esta forma, el equipo será prácticamente inaudible mientras programas en Go o Python o haces tareas de escritorio, pero la disipación escalará de forma agresiva y eficiente para sacar el calor de la caja en medio de una raid en WoW o durante cargas de trabajo pesadas.

Una vez tengas todo esto cambiado, pulsa **F10** para guardar los cambios y reiniciar. Tendrás el sistema rindiendo a su máximo potencial de fábrica, de forma inteligente y térmica.