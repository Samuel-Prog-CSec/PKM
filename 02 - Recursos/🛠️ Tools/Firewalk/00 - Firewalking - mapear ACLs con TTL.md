---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Tipo/Introduccion
Descripción: "La técnica que interroga al firewall en vez de al host: qué deja pasar una ACL, deducido del TTL y de un ICMP Time Exceeded"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Implementaciones vivas del firewalking]]"
Area: "[[Firewalk.base|Firewalk]]"
---
---

Un escaneo de puertos normal te dice cosas **del host**. <mark style="background: #ADCCFFA6;">El *firewalking* te dice cosas **del filtro**: qué puertos deja atravesar una ACL, independientemente de si al otro lado hay algo escuchando</mark>. Es una distinción con consecuencias operativas grandes, y la técnica sigue siendo la forma más limpia de mapear reglas de filtrado.

La publicaron **Mike Schiffman y David Goldsmith en 1998** junto con la herramienta `firewalk`. El binario original está muerto —última versión alrededor de 2002— pero la técnica no, y hoy se ejecuta con las implementaciones de [[01 - Implementaciones vivas del firewalking]].

# El mecanismo

Todo se apoya en una propiedad del reenvío IP: <mark style="background: #8000E1A6;">un router que recibe un paquete con `TTL = 1` lo descarta y devuelve un **ICMP Time Exceeded** (tipo 11)</mark>. Eso es lo que hace funcionar a `traceroute`, y es lo que el firewalking usa como oráculo.

## Fase 1 — medir la distancia al filtro

Primero hay que saber a cuántos saltos está el dispositivo que filtra. Se hace con un `traceroute` normal hacia el objetivo: el último salto que responde antes del silencio suele ser el firewall (o el router inmediatamente anterior).

```
tú ── R1 ── R2 ── R3 ── [FIREWALL] ── R4 ── objetivo
 1     2      3     4         5         6       7
```

## Fase 2 — sondear con el TTL justo

Se manda una sonda al puerto que quieres probar con **`TTL = distancia_al_firewall + 1`**. Dos desenlaces:

| La ACL… | Qué pasa | Qué recibes |
| --- | --- | --- |
| **Permite** el puerto | El firewall reenvía. El paquete llega a `R4` con `TTL = 0` y expira ahí | <mark style="background: #FF5582A6;">**ICMP Time Exceeded desde R4**</mark> → la regla lo deja pasar |
| **Bloquea** el puerto | El firewall lo descarta | **Silencio** → la regla lo filtra |

```
  TTL=6, puerto 80  ──▶ [FIREWALL: permite 80] ──▶ R4 (TTL=0) ──▶ ICMP Time Exceeded ──▶ tú
  TTL=6, puerto 23  ──▶ [FIREWALL: deniega 23] ──✗                                        (silencio)
```

<mark style="background: #FFB86CA6;">La clave: la respuesta la genera un router **detrás** del firewall, no el objetivo</mark>. Por eso el objetivo puede estar apagado, no existir o ignorar todo, y la técnica sigue funcionando: no estás preguntando por el host, estás preguntando por la regla.

# Por qué eso importa en un pentest

## Distingue "cerrado" de "filtrado" a nivel de política

Un escaneo devuelve `filtered` y ahí se acaba la información. El firewalking te dice **qué política concreta** hay: qué puertos atraviesan el perímetro hacia esa red, aunque nadie los use todavía.

## Encuentra el hueco que aún no está ocupado

Este es el uso más rentable. Si la ACL permite el `445` hacia un segmento pero ahora mismo no hay ningún SMB escuchando, un escaneo de puertos **no ve nada**. El firewalking sí ve la regla. <mark style="background: #8000E1A6;">Eso es exactamente lo que necesitas saber cuando llegues a la post-explotación</mark>: por dónde podrás sacar tráfico o pivotar cuando controles un host de esa red ([[Pivoting y túneles.base|pivoting y túneles]]).

## Mapea segmentación interna

Es donde más funciona hoy. Un firewall perimetral moderno está afinado para no filtrar información; un router interno con ACLs entre VLANs, no tanto. Verificar que la segmentación interna es la que el cliente cree que es —y documentar dónde no lo es— es un hallazgo de arquitectura, de los que valen más en un informe que un puerto abierto ([[Documentación y reporting.base|reporting]]).

# Qué necesita para funcionar

> [!warning]+ Cuatro condiciones, y las cuatro fallan a menudo
> 1. **Tiene que haber un router detrás del firewall.** Si el firewall es el último salto antes del objetivo, no hay ningún dispositivo que expire el TTL y devuelva el ICMP. <mark style="background: #FF5582A6;">La técnica se queda ciega</mark>. Es lo habitual en una DMZ pequeña o en cloud.
> 2. **Ese router tiene que poder mandar ICMP Time Exceeded hacia fuera.** Bloquear el ICMP saliente es *hardening* de manual desde hace años.
> 3. **La ruta tiene que ser estable.** Con ECMP, balanceo o multihoming, tus sondas van por caminos distintos y el conteo de saltos deja de significar nada.
> 4. **Sin NAT ni proxies por el medio** que reescriban el paquete o terminen la conexión.

Hay una quinta condición implícita: los firewalls **con estado** descartan cualquier segmento que no pertenezca a una sesión conocida, así que las sondas basadas en `ACK` o flags sueltos ni siquiera llegan a evaluarse contra la ACL de puertos. La técnica nació contra filtros sin estado y ese es su terreno natural.

> [!important]+ Cómo leer un resultado vacío
> Que el firewalking no devuelva nada **no significa que el firewall lo bloquee todo**: puede significar que falta cualquiera de las cuatro condiciones. Antes de escribir una conclusión, comprueba que un puerto que *sabes* abierto (el 443 del servidor web público, por ejemplo) sí produce respuesta. Si tampoco la produce, la técnica no aplica en ese camino y hay que decirlo así, no inventar una política.

# La relación con el ACK scan

El `-sA` de [[07 - Evasión de firewalls, IDS e IPS#Leer las reglas del firewall - el ACK scan (`-sA`)|Nmap]] responde una pregunta parecida con otro mecanismo: manda un `ACK` suelto y mira si vuelve un `RST` (no filtrado) o silencio (filtrado). Se complementan:

| | ACK scan (`-sA`) | Firewalking |
| --- | --- | --- |
| Oráculo | `RST` del **objetivo** | ICMP Time Exceeded de un **router intermedio** |
| Necesita el objetivo vivo | Sí | **No** |
| Identifica **qué** dispositivo filtra | No | **Sí** (por número de salto) |
| Sobrevive a un firewall con estado | No | No |

Usar los dos y contrastar es lo que da una imagen fiable del perímetro.

> [!info]+ Fuentes
> - Mike Schiffman y David Goldsmith — *Firewalk: An Active Reconnaissance Tool* (1998), técnica original y herramienta `firewalk` (Packet Factory), hoy sin mantenimiento.
> - Implementación viva y documentada: el script NSE [`firewalk.nse`](https://github.com/nmap/nmap/blob/master/scripts/firewalk.nse) de Nmap, cuyo mecanismo se detalla en [[01 - Implementaciones vivas del firewalking]].
