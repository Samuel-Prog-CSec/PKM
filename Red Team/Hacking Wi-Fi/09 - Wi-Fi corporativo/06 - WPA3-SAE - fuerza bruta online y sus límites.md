---
tags:
  - Wi-Fi/WPA3
  - Pentesting/Explotacion
Descripción: "Qué queda contra WPA3-SAE puro: la aritmética real de la fuerza bruta online, por qué el laboratorio de HTB la hace parecer viable y las vías de Dragonblood"
Fecha de actualización: 2026-08-04
Nota previa: "[[05 - WPA3 en modo transición y downgrade]]"
Nota siguiente: "[[07 - Karma y MANA]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Contra un AP en **WPA3-SAE puro** —sin modo transición, con `PMF` obligatorio— desaparecen la deauth, el handshake crackeable y el PMKID. <mark style="background: #ADCCFFA6;">No hay ningún verificador que se pueda atacar offline</mark>, y eso reduce las opciones a tres, todas caras.

# Lo que queda

| Vía | Coste | Viabilidad |
| --- | ----- | ---------- |
| Fuerza bruta **online** | Decenas de intentos/s | Sólo con lista muy dirigida |
| Canal lateral de Dragonblood | Requiere implementación vulnerable | Alta si `sae_pwe=0` |
| Evil twin por colisión de BSSID | Ruidoso, degrada servicio | Último recurso |
| DoS | — | Fuera de alcance en casi todo engagement |

# Fuerza bruta online con `wacker`

`wacker` ([blunderbuss-wctf/wacker](https://github.com/blunderbuss-wctf/wacker)) conduce un `wpa_supplicant` parcheado para encadenar intentos SAE contra el AP:

```shell-session
$ sudo python3 wacker.py --wordlist rockyou.txt --ssid StarLight-SEC \
      --bssid D8:D4:3D:E1:29:D5 --interface wlan0 --freq 2412
```

`--freq` va en MHz, no en número de canal: canal 1 es `2412`, canal 6 es `2437`, canal 11 es `2462`. El mapeo completo está en [[01 - Bandas, canales y regulación del espectro]].

Como cada intento necesita una interfaz ocupada durante todo el intercambio, se paraleliza repartiendo el diccionario:

```shell-session
$ ./split.sh 4 /opt/rockyou.txt
$ for i in 0 1 2 3; do
    sudo python3 wacker.py --wordlist rockyou.txt.aa$i --ssid StarLight-SEC \
        --bssid D8:D4:3D:E1:29:D5 --interface wlan$i --freq 2412 &
  done
```

# La aritmética que HTB omite

El README de `wacker` documenta su propio rendimiento: **79,41 intentos por segundo**. Con eso:

| Ritmo | `rockyou` completo | Con 4 interfaces |
| ----- | ------------------ | ---------------- |
| 79,4/s (documentado por el autor) | 50,2 h | 12,5 h |
| 20/s (AP real, sin rate limiting agresivo) | 8,3 días | 49,8 h |
| 5/s (AP con anti-clogging activo) | 33,2 días | 8,3 días |

> [!warning]+ Los 79 intentos/s del README son sobre radios **simuladas**
> El propio README documenta su entorno de pruebas: `modprobe mac80211_hwsim radios=4`. <mark style="background: #FF5582A6;">Ahí no hay capa física</mark>: ni propagación, ni colisiones, ni reintentos, ni el retardo que introduce un AP real al construir su `Commit`.
>
> Y lo mismo vale para el laboratorio de HTB. En su salida de `airmon-ng` se lee `mac80211_hwsim — HTB Chipset of 802.11 radio(s) for mac80211`: **todo el path corre sobre radios virtuales**. Por eso su fuerza bruta contra WPA3 "encuentra la contraseña al cabo de un rato" y por eso conviene no extrapolar los tiempos del laboratorio a un engagement real.

<mark style="background: #8000E1A6;">La conclusión operativa: la fuerza bruta online contra SAE **no es un ataque de diccionario, es un ataque de lista corta**</mark>. Un diccionario dirigido de 50.000 candidatas se agota en ~42 minutos a 20 intentos/s; `rockyou` no se agota nunca dentro de una ventana de cinco días. La construcción de esa lista corta —variantes del ESSID, jerga del cliente, keyspaces de fabricante— está en [[05 - Wordlists dirigidas a redes Wi-Fi]].

# Por qué el AP puede frenarte

SAE incluye por diseño un mecanismo contra el abuso: cuando el AP acumula intercambios a medias, responde con un **anti-clogging token** que el cliente debe devolver en su siguiente `Commit`. Añade una ida y vuelta por intento y encarece la fuerza bruta.

Además, cada intento fallido es un evento registrable. A diferencia del crackeo offline, <mark style="background: #FFB86CA6;">aquí **todo** queda en los registros del controlador</mark>: miles de autenticaciones fallidas desde la misma MAC son la firma más obvia que puede dejar un auditor.

# La vía que realmente rompió WPA3

*Dragonblood* (Vanhoef y Ronen, IEEE S&P 2020) no atacó SAE por fuerza bruta, sino por **canal lateral** en la derivación del `PWE`:

| Ataque | CVE | Mecanismo |
| ------ | --- | --------- |
| Canal lateral por tiempo | `CVE-2019-9494` | El bucle *hunting-and-pecking* tarda distinto según la contraseña |
| Canal lateral por caché | `CVE-2019-9494` | Los patrones de acceso a memoria filtran la iteración |
| Curvas Brainpool | `CVE-2019-13377` | Fuga adicional con grupos concretos |
| Downgrade de grupo | `VU#871675` | Forzar un grupo criptográfico más débil |

Lo relevante es que **estas fugas convierten SAE en atacable offline**: con suficientes medidas de tiempo se reconstruye la contraseña con un diccionario, sin volver a tocar el AP.

La contramedida es **hash-to-element**, que deriva el PWE en tiempo constante. En `hostapd` se activa con `sae_pwe`:

| Valor | Significado |
| ----- | ----------- |
| `0` | Sólo hunting-and-pecking — **el valor por defecto**, vulnerable |
| `1` | Sólo hash-to-element |
| `2` | Ambos |

<mark style="background: #FF5582A6;">Que el valor por defecto siga siendo el vulnerable</mark> es la razón por la que este vector no es histórico. H2E sólo es obligatorio en 6 GHz y Wi-Fi 7. Comprobar `sae_pwe` es, junto con `transition_disable`, la pregunta de auditoría que más rinde contra un despliegue WPA3 — detalle en [[04 - WPA3, SAE y OWE]].

# Evil twin por colisión de BSSID

La última opción es levantar un AP con **el mismo ESSID y el mismo BSSID** que el legítimo, ofreciendo WPA2. Los clientes ven un AP que anuncia dos configuraciones incompatibles y muchos acaban sin poder conectar.

Es el escenario que HTB llama *"collider evil twin"*. Conviene ser explícito sobre lo que es: <mark style="background: #FFB8EBA6;">un ataque de denegación de servicio con un portal encima</mark>. Se combina con un segundo AP abierto y atractivo para recoger a los clientes expulsados.

En un engagement con DoS fuera de alcance —lo normal, y obligatorio en un hospital— **esto no se lanza sin autorización expresa y ventana acordada**. La alternativa defendible es documentar que el ataque es posible, con la evidencia del reconocimiento, sin ejecutarlo.

# Qué reportar

Si WPA3-SAE aguanta, el informe debe decirlo como lo que es: **el control funcionó**. Y aun así quedan preguntas de configuración que sí producen hallazgos:

| Comprobación | Hallazgo si falla |
| ------------ | ----------------- |
| `sae_pwe` | Canal lateral de Dragonblood explotable |
| `transition_disable` | Downgrade a WPA2 posible para clientes ya autenticados |
| `PMF` obligatorio | Debería estar por definición en WPA3; verificar que no se relajó |
| Longitud de la passphrase | La fuerza bruta online sólo amenaza a contraseñas triviales |
| Registro de fallos de autenticación | Si nadie los mira, un atacante puede insistir semanas |

La última es la más olvidada: **el control que hace inviable la fuerza bruta online no es criptográfico, es la detección**. Un AP que no alerta tras diez mil intentos fallidos regala tiempo ilimitado.
