---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Tipo/Deteccion
Descripción: "Por qué el firewalking falla contra un perímetro moderno, dónde sigue funcionando muy bien, y cómo lo ve el defensor"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Implementaciones vivas del firewalking]]"
Nota siguiente:
Area: "[[Firewalk.base|Firewalk]]"
---
---

El firewalking tiene veintiocho años y se sigue enseñando sin decir cuándo funciona. Esta nota fija eso: dónde está muerto, dónde sigue siendo la mejor herramienta que hay, y qué deja en los logs.

# Por qué falla contra un perímetro moderno

## 1. No hay router detrás del filtro

<mark style="background: #FF5582A6;">Es la causa número uno y es estructural</mark>. La técnica necesita que **alguien** detrás del firewall expire el TTL y devuelva el `ICMP Time Exceeded`. En las arquitecturas de hoy ese alguien no existe:

- **Cloud** (AWS/Azure/GCP): entre el *security group* y la instancia no hay un salto que enrute. El *security group* descarta o entrega, sin intermediarios.
- **DMZ pequeñas**: el firewall es la última interfaz antes del servidor.
- **Firewalls en modo bridge/transparente**: no decrementan TTL ni son un salto.

Sin ese router, todas las sondas devuelven silencio y el resultado es indistinguible de "todo bloqueado".

## 2. ICMP saliente bloqueado

Filtrar el ICMP de salida es *hardening* de manual. Si el router de detrás no puede mandar el `Time Exceeded` hacia Internet, el oráculo desaparece. Muchos perímetros lo hacen precisamente por esto.

## 3. Inspección con estado

Un NGFW descarta cualquier segmento que no pertenezca a una sesión conocida. Las sondas de firewalking son huérfanas por definición, así que **ni siquiera se evalúan contra la ACL de puertos**: se tiran antes por no tener estado.

## 4. Rutas inestables y normalización

- **ECMP, balanceo, multihoming**: tus sondas van por caminos distintos y el conteo de saltos deja de ser fiable.
- **Normalización de TTL**: algunos firewalls reescriben el TTL de los paquetes que atraviesan, precisamente para romper el *fingerprinting* y estas técnicas.
- **NAT y proxies**: reescriben o terminan la conexión.

> [!warning]+ El error de interpretación caro
> <mark style="background: #FFB86CA6;">Silencio total ≠ política restrictiva</mark>. Con cualquiera de los cuatro factores anteriores el resultado es el mismo: nada. Antes de concluir nada, **valida el método**: sondea un puerto que sepas permitido (el 443 del web público). Si tampoco produce respuesta, la técnica no aplica en ese camino — y eso es lo que hay que escribir en el informe, no una lista de puertos bloqueados que en realidad no has medido.

# Dónde sigue funcionando muy bien

<mark style="background: #8000E1A6;">El firewalking no está muerto: se ha movido de sitio</mark>. Su terreno hoy es el **interior**, donde las condiciones sí se dan:

| Escenario | Por qué funciona |
| --- | --- |
| **Segmentación entre VLANs** | Hay routers/L3 switches reales entre segmentos, con ACLs y sin inspección de estado. |
| **Redes OT/ICS** | Filtrado por ACLs de router, arquitecturas antiguas, ICMP interno permitido. |
| **Post-explotación** | Desde un host comprometido, mapear a dónde puede llegar esa red antes de intentar pivotar ([[Pivoting y túneles.base\|pivoting]]). |
| **Validar la microsegmentación** | Comprobar si lo que el cliente cree que está separado lo está de verdad. |

Ese último caso es el más valioso profesionalmente. <mark style="background: #ADCCFFA6;">"La segmentación de red no coincide con la política documentada" es un hallazgo de arquitectura</mark>, con impacto explicable a dirección y coste real de remediación — bastante por encima de un puerto abierto en el ranking de lo que le importa a un cliente ([[Documentación y reporting.base|reporting]]).

# Cómo lo ve el defensor

## La firma es rara y por eso se detecta bien

El tráfico de firewalking no se parece a nada legítimo:

- **Muchos paquetes con TTL bajo y variable** hacia el mismo destino. `traceroute` legítimo hace esto, pero contra **un** destino y con pocos paquetes; el firewalking lo hace contra **muchos puertos**.
- **Sondas que caducan sistemáticamente** justo detrás del perímetro. Cada una genera un `ICMP Time Exceeded` que el propio router registra.
- **Ráfagas de ICMP tipo 11 salientes** hacia un mismo origen externo: es la señal más limpia, y la ve el router, no el firewall.
- **Sin seguimiento**: ninguna de esas "conexiones" avanza nunca a un handshake completo.

`Suricata` y `Zeek` detectan el patrón por umbral sobre paquetes con TTL anómalo y por el volumen de ICMP tipo 11 generado. Y el propio dispositivo que filtra registra los descartes: <mark style="background: #FF5582A6;">un firewall con logging de denegaciones te ve puerto por puerto</mark>, con tu IP y la lista exacta de lo que intentaste.

## En qué categoría cae

Es *Network Service Discovery* ([T1046](https://attack.mitre.org/techniques/T1046/)) en ATT&CK, con solape con el reconocimiento de infraestructura de red. Nada que un equipo azul maduro no tenga cubierto.

> [!important]+ No es una técnica sigilosa
> Se vende como reconocimiento "pasivo-ish" porque no toca al objetivo final. Es engañoso: <mark style="background: #FFB8EBA6;">tocas el firewall y todos los routers del camino, generas ICMP y quedas en el log de denegaciones</mark>. Úsalo cuando el objetivo sea *entender la política* y el ruido esté asumido, no como parte de una fase que quieras discreta.

# Contramedidas (lo que recomiendas en el informe)

Ordenadas por eficacia real:

1. **Denegar por defecto y filtrar con estado.** Un NGFW con inspección de estado invalida la técnica de raíz, porque las sondas huérfanas mueren antes de la ACL.
2. **Bloquear el `ICMP Time Exceeded` saliente** hacia redes no confiables. Elimina el oráculo. Tiene coste: rompe el `traceroute` legítimo y complica el diagnóstico de MTU, así que se aplica en el perímetro, no en el interior.
3. **Normalizar el TTL** en el dispositivo perimetral (reescribir a un valor fijo). Rompe además el *fingerprinting* pasivo de sistema operativo.
4. **Registrar y alertar** sobre volúmenes anómalos de ICMP tipo 11 salientes y de denegaciones por origen.
5. **Revisar las ACLs internas**, que es donde la técnica sí funciona. La mayoría de las reglas que el firewalking encuentra abiertas de más son residuos de migraciones que nadie limpió.

> [!success]+ Cómo redactar el hallazgo
> No reportes "el firewalking reveló los puertos X, Y, Z". Reporta la **política**: «el filtro del salto 5 (10.0.1.1) permite tráfico entrante a los puertos 445, 3389 y 5985 hacia el segmento de servidores, sin que existan servicios publicados en ellos. Esas reglas permiten movimiento lateral desde la DMZ si un host de esa zona resulta comprometido». Eso último es lo que hace accionable el hallazgo.

> [!info]+ Fuentes
> - Prerrequisitos y limitaciones declarados en [`firewalk.nse`](https://github.com/nmap/nmap/blob/master/scripts/firewalk.nse) de Nmap.
> - Detección por comportamiento y umbral en [[08 - Detección de escaneos y evasión moderna]]; MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/).
> - Doctrina de perímetro y egress filtering en [[00 - El perímetro moderno - firewall, NGFW, IDS-IPS, NDR y WAF]].
