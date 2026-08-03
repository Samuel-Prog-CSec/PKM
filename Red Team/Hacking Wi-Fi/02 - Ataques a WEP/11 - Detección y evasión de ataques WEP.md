---
tags:
  - Wi-Fi/WEP
  - Tipo/Deteccion
  - Pentesting/Explotacion
Descripción: "Qué firma deja cada ataque a WEP, por qué el entorno donde sobrevive WEP rara vez tiene detección y cómo minimizar el impacto operativo"
Fecha de actualización: 2026-08-01
Nota previa: "[[10 - Cracking - PTW, FMS y KoreK]]"
Nota siguiente: "[[12 - WEP en 2026 y arsenal]]"
Area: "[[WEP.base|WEP]]"
---
---

Los ataques a WEP son, con diferencia, **los más ruidosos** del pentesting Wi-Fi: cientos de tramas por segundo inyectadas durante minutos. <mark style="background: #ADCCFFA6;">La paradoja es que el entorno donde WEP sobrevive suele carecer por completo de capacidad de detección</mark>, así que el ruido rara vez tiene consecuencias — pero el **impacto operativo** sí las tiene, y ése es el riesgo real.

# La firma de cada ataque

| Ataque | Qué se ve en el aire |
| ------ | -------------------- |
| **ARP Replay** | El **mismo paquete cifrado** retransmitido cientos de veces por segundo, con IV idéntico en la inyección |
| **Fragmentación** | Ráfagas de fragmentos de 8 bytes desde una MAC, seguidas de reensamblados |
| **ChopChop** | Miles de tramas **truncadas con ICV inválido**, cada una un byte más corta |
| **Fake auth** | Autenticaciones y asociaciones repetidas desde una MAC que nunca envía datos útiles |
| **Café Latte** | Un **BSSID duplicado** en el aire: dos APs con la misma dirección |
| **Deauth** | Ráfagas de `reason code 7` |

<mark style="background: #FF5582A6;">ChopChop es la más inconfundible</mark>: un flujo sostenido de paquetes con ICV inválido no tiene ninguna explicación legítima. Un AP con contadores de error los registra, y un WIDS lo marcaría de inmediato — si lo hubiera.

# Lo que sí detecta el equipamiento antiguo

Aunque no haya WIDS, los propios dispositivos llevan contadores:

```text
WEP ICV errors: 48213
Excessive retries on interface ath0
Duplicate IV detected
```

Un salto de decenas de miles de errores de ICV en pocos minutos es evidencia clara. En routers con syslog remoto, esos contadores llegan a algún sitio; el problema es que casi nadie los mira.

# Por qué el ruido importa menos aquí

El razonamiento es honesto y conviene tenerlo claro antes de decidir cómo trabajar:

- **WEP implica equipamiento anterior a 2004.** Ni `PMF`, ni detección de rogue AP, ni telemetría al controlador — muchas veces ni siquiera hay controlador.
- **Suele estar en segmentos aislados**: una VLAN industrial, una red de invitados olvidada, un armario de sótano. Nadie monitoriza esos segmentos.
- **El ataque dura minutos.** Aunque algo lo registre, la ventana de reacción es demasiado corta.

Eso **no** significa que dé igual lo que se haga.

# El riesgo real: el impacto operativo

> [!warning]+ Lo que se rompe, no lo que se detecta
> Inyectar 500 paquetes por segundo en una red de 11 Mb/s **satura el medio**. Y las redes que aún usan WEP no son redes de invitados: son <mark style="background: #FFB86CA6;">lectores de códigos de barras en un almacén, PLCs en una planta, telemetría de equipamiento médico</mark>. Tumbar esa red durante cinco minutos puede parar una línea de producción.
>
> Y hay algo peor que el ruido: **el AP puede colgarse**. Equipamiento de 2003 con firmware original no está preparado para recibir decenas de miles de tramas malformadas. Un AP que no vuelve a arrancar es un incidente que se atribuye al pentest, y en un entorno industrial puede no haber repuesto.

Medidas concretas para reducirlo:

```shell-session
# Limitar el ritmo de inyección
$ sudo aireplay-ng -3 -x 200 -b <BSSID> -h <MAC> wlan0mon
```

`-x 200` baja de los ~500 pps por defecto a 200. Tarda el doble —cuatro minutos en lugar de dos— y reduce sustancialmente la saturación del medio. <mark style="background: #8000E1A6;">En una red de producción, esos dos minutos extra no cuestan nada y evitan una llamada</mark>.

Y en el pre-engagement, fijar por escrito:

- **Ventana horaria** fuera de producción.
- **Contacto técnico** localizable durante la prueba.
- **Criterio de parada**: si el AP deja de responder, se detiene y se avisa.
- Si el sistema es crítico y no admite interrupción, **documentar la vulnerabilidad sin explotarla**. Un AP anunciando `ENC: WEP` en un beacon ya es evidencia suficiente para el informe.

# Evasión, en lo que aplica

Poco margen, pero no nulo:

**Capturar pasivamente todo lo posible.** Con un cliente activo generando tráfico normal, `airodump-ng` puede reunir los 40.000 IVs sin inyectar nada. Tarda 15–30 minutos en lugar de 2, y es completamente indetectable.

**Preferir Café Latte cuando haya cliente.** El ataque ocurre entre el atacante y el cliente; el AP y su red **no participan**, así que no hay saturación del medio de producción ni riesgo de tumbar el AP. Ver [[08 - Café Latte y ataques al cliente]].

**No usar la MAC de fábrica.** `00:c0:ca` es ALFA. En una red con inventario de dispositivos, un OUI de adaptador de pentest es lo primero que destaca. `macchanger -a` mantiene un OUI plausible — [[08 - Bypass de filtrado MAC]].

**Fragmentación antes que ChopChop.** Segundos frente a minutos, y muchas menos tramas inválidas.

# Detección, para el lado defensivo

Recomendaciones, en orden de utilidad real:

1. **Retirar WEP.** No hay mitigación parcial. Cualquier otra recomendación es paliativa.
2. **Si el equipamiento no puede migrarse** —el caso industrial habitual— aislarlo: VLAN dedicada, sin encaminamiento hacia el resto de la red, y tratarla como segmento no confiable. <mark style="background: #FFB8EBA6;">La red WEP se asume comprometida y se diseña alrededor de eso</mark>.
3. **Monitorizar los contadores de error de ICV** del AP y alertar sobre saltos anómalos. Es lo único que detecta ChopChop en equipamiento sin WIDS.
4. **Alertar sobre BSSID duplicados**, que delatan Café Latte y evil twin.
5. **Limitar el alcance físico**: bajar la potencia de emisión al mínimo que cubra el área operativa. En una planta industrial es viable y reduce la superficie a quien esté físicamente dentro.

> [!important]+ Cómo redactarlo
> El hallazgo de WEP no compite con otros por severidad: **es acceso completo a la red en minutos, con independencia de la clave**. Si además esa red encamina hacia sistemas de producción, el hallazgo es de máxima criticidad y la recomendación es la sustitución del equipamiento, con el aislamiento como medida provisional mientras se planifica.

El estado del ecosistema y el arsenal completo están en [[12 - WEP en 2026 y arsenal]].
