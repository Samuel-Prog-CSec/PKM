---
tags:
  - Blue-Team
  - Deteccion
  - Escaneo/Redes
Descripción: "Qué tipos de sensor existen, por qué colocarlos solo en el egress es un error y cómo detectar sin descifrar en la era de TLS 1.3 y ECH"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Threat modeling, STRIDE y el concepto de guarding]]"
Nota siguiente: "[[02 - Zero-trust - bloquear lo sospechoso, no solo lo malicioso]]"
Area: "[[Doctrina defensiva.base|Doctrina defensiva]]"
---
---

El *Bansenshūkai* recomienda defender un castillo colocando exploradores (`scouts`) escalonados por los caminos de aproximación, no solo guardias en la puerta. Los había de tres tipos: de **olfato** (`kagi`), de **oído** (`monogiki`) y de **pie exterior** (`togiki`), estos últimos operando fuera del perímetro enemigo. La lección para la defensa moderna es la colocación: <mark style="background: #ADCCFFA6;">un sensor solo sirve donde el adversario tiene que pasar</mark>, y el error habitual es ponerlos todos en el mismo sitio.

# Qué es un sensor y de qué tipos

En términos defensivos, un `sensor` es cualquier instrumento que copia actividad para observarla, registrarla y analizarla. Dos configuraciones fundamentales:

- **Pasivo (out-of-band)**: escucha en un `tap`, `SPAN` o `mirror port` que duplica el tráfico. Ve todo pero no puede intervenir; captura `PCAP` para análisis.
- **En línea (in-line)**: el tráfico atraviesa el dispositivo, que puede retrasar, bloquear o alterar el paquete. Detiene ataques, pero es un punto de fallo y de latencia.

Sobre esa base se especializan por tipo de tráfico: `IDS/IPS` para ataques de red, `email gateway` para phishing, `firewall` para IPs y puertos, `proxy` para webs sospechosas, `DLP` para exfiltración, sensores Wi-Fi para señales no autorizadas, y cámaras/sensores físicos para el acceso a los racks. Los agentes de endpoint (`EDR`/`XDR`) también son sensores: recogen eventos del host y los reportan a una plataforma central de análisis.

# El error de colocación: todo al egress

Lo estándar es colocar los sensores "lo más arriba posible" —en el `egress`, normalmente la DMZ— para maximizar el tráfico que ven. El problema es evidente en cuanto se piensa como atacante: <mark style="background: #FFB86CA6;">si el adversario evita el egress o hace un *bridge* hacia dentro de la red, opera libre de inspección</mark>. Y aunque el sensor del egress esté, cada sensor sufre el "problema de la pajita": ve mucho tráfico pero por un campo de captura estrecho, acumulando miles de horas de datos que alguien tiene que procesar. Firmas, algoritmos y ML ayudan, pero generan falsos positivos o tal avalancha de alertas legítimas que equivale a no tener sensores.

> [!warning]+ El punto ciego este-oeste
> Concentrar la detección en el perímetro deja ciego el tráfico **este-oeste** (entre sistemas internos), que es justo donde ocurre el movimiento lateral. Con *cloud*, teletrabajo y `BYOD`, el perímetro clásico se ha disuelto: la doctrina de "todo al egress" es hoy insuficiente por diseño. Esto es lo que empuja hacia el [[02 - Zero-trust - bloquear lo sospechoso, no solo lo malicioso|zero-trust]] y el `NDR` (Network Detection & Response) con visibilidad interna.

# Mejores sensores, inspirados en los scouts

*Cyberjutsu* propone trasladar la lógica de los exploradores ninja:

1. **Modela la red y sus rutas de ataque** antes de colocar nada: dónde entra y sale la información, qué inspecciona cada sensor, dónde hay huecos.
2. **Valida con red/pentest**: contrata un equipo que intente infiltrarse y comprueba qué vieron los sensores antes, durante y después. Un enfoque *purple team* (azul observando al rojo en tiempo real) es especialmente revelador.
3. **Sensores "de olfato" y "de oído"**: monitorizar señales indirectas — por ejemplo, el consumo de CPU o de energía de un sistema para detectar un `cryptominer` cuyo uso no correlaciona con la actividad del usuario.
4. **Sensores pasivos como trampa**: interfaces que nunca deberían usarse configuradas para alertar si se activan — el equivalente digital de la <mark style="background: #8000E1A6;">arena rastrillada que revela las pisadas del intruso</mark>, ideal para detectar movimiento lateral donde no debería haberlo.
5. **Sensores `togiki`**: en cooperación con el ISP, colocar detección **fuera** del propio límite de red para ver lo que los sensores internos no captan.

# El reto moderno: detectar sin descifrar

El consejo original del libro —"bloquea todo el tráfico cifrado que no puedas inspeccionar"— ha envejecido mal. Con `TLS 1.3` ubicuo y `Encrypted Client Hello` (ECH) ocultando incluso el `SNI`, <mark style="background: #FF5582A6;">la inspección por MITM (SSL/TLS inspection) es cada vez más difícil, frágil y cuestionable</mark> — rompe *certificate pinning*, degrada la privacidad y no llega al tráfico con *pinning* estricto. La tendencia defensiva actual no es descifrar, sino **analizar metadatos**: tamaños y tiempos de paquete, huellas de handshake TLS con `JA4+` (de FoxIO, evolución del `JA3` de Salesforce), entropía y cadencia de las conexiones, y correlación con telemetría de endpoint. Se detecta el *cómo se comunica* el C2 sin leer *qué* dice.

Bloquear cifrado a ciegas hoy rompe el negocio; la defensa madura combina visibilidad de endpoint (EDR/XDR), metadatos de red (NDR) y correlación en el SIEM. Las notas base del vault desarrollan las piezas: [[Tipos de análisis de red]], la propia [[IDS-IPS|detección de intrusiones]] y [[Sysmon]] como sensor de host.

La contracara ofensiva —cómo el atacante minimiza la luz, el ruido y la basura que estos sensores capturan— está en la doctrina de evasión de [[00 - El mindset del atacante persistente|Doctrina pentesting]].

> [!info]+ Fuentes
> - Ben McCarty, *Cyberjutsu*, cap. 9 ("Sensors"), 2021.
> - FoxIO, [JA4+ network fingerprinting](https://github.com/FoxIO-LLC/ja4) (sucesor de JA3).
> - IETF, TLS 1.3 (RFC 8446) y [Encrypted Client Hello](https://datatracker.ietf.org/doc/draft-ietf-tls-esni/) (ECH).
