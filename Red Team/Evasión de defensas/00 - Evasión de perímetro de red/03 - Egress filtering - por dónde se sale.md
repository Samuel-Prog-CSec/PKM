---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Post-Explotacion
Descripción: "El lado del perímetro que casi nadie prueba y el que decide si tu shell, tu C2 y tus túneles van a funcionar"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - Descubrir la política de filtrado]]"
Nota siguiente: "[[04 - Fragmentación y evasión a nivel IP y TCP]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Todo el bloque anterior mira hacia **dentro**: qué deja entrar el perímetro. Esta nota mira hacia **fuera**. <mark style="background: #ADCCFFA6;">El *egress filtering* es el control del tráfico que **sale** de la red</mark>, y es el que decide si tu *reverse shell* conecta, si tu *beacon* de C2 llama a casa y si tu túnel de exfiltración funciona. Es el lado que casi nadie prueba en recon —porque desde fuera no se ve— y el que más te condiciona en cuanto pones un pie dentro.

# La asimetría que define el perímetro

Casi todos los perímetros están **duros por fuera y blandos por dentro**: se filtra el *ingress* con cuidado (reglas por servicio, DMZ, WAF) y el *egress* con desgana. La razón es operativa: bloquear salidas rompe cosas legítimas —actualizaciones, telemetría, SaaS— y genera *tickets*, así que la regla que más se repite es <mark style="background: #FFB8EBA6;">«permitir todo lo saliente»</mark>. Ese descuido es tu vía de retorno.

El problema es tuyo, no del defensor: una vez ejecutas código en un host interno, **el paquete que devuelve el control tiene que atravesar el perímetro de salida**. Si el egress está bien cerrado, tu RCE se queda mudo. Por eso el egress se prueba **antes** de necesitarlo, no cuando ya tienes la shell y descubres que no sale.

# Cómo se prueba el egress: el test de todos los puertos

La pregunta es simple —¿por qué puertos y protocolos puedo salir?— pero solo se responde **desde dentro**, contra un oído tuyo en Internet. El patrón es levantar un receptor que escuche en **todos** los puertos y, desde el host interno, intentar alcanzarlo en cada uno:

```shell-session
# En tu VPS: crea la tabla/cadena NAT y redirige TODO el rango a un único listener
$ sudo nft add table ip nat
$ sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority -100 ; }'
$ sudo nft add rule ip nat prerouting tcp dport 1-65535 redirect to :4444
$ ncat -lvk 4444

# Desde el host interno: prueba puertos clave (o barre el rango)
$ for p in 21 22 25 53 80 123 443 445 3389 8080; do
    timeout 2 bash -c "echo test >/dev/tcp/TU_VPS/$p" && echo "$p ABIERTO"
  done
```

<mark style="background: #FFB86CA6;">Cada puerto que responde es una ruta de salida confirmada</mark>. Para no montar infraestructura existe el servicio público **`portquiz.net`**, que escucha en los 65.535 puertos TCP y responde a cualquiera:

```shell-session
$ curl -s portquiz.net:443 -o /dev/null -w '443 OK\n'
$ curl -s portquiz.net:8888 -o /dev/null -w '8888 OK\n'
```

`Egress-Assess` (FortyNorth Security) automatiza esto y además simula **exfiltración real** de datos con formato (tarjetas, SSN) sobre distintos protocolos, para medir no solo si sale el paquete sino si el DLP lo corta. Convierte «el 443 está abierto» en «puedo sacar 10 MB por 443 sin que salte nada».

> [!warning]+ Salir no es lo mismo que llegar
> Un `SYN` que cruza el firewall de salida puede morir después en un **proxy transparente** o un **SWG** que intercepta la sesión. Un `curl` a `portquiz.net:443` que "funciona" puede estar hablando con el proxy corporativo, no con tu VPS. Verifica **extremo a extremo**: que el byte que mandas aparece en tu *listener*, no que la conexión se establece.

# La jerarquía de canales de salida

No todos los puertos abiertos valen lo mismo. El orden de preferencia real:

| Canal | Por qué | Coste de detección |
| --- | --- | --- |
| **443/tcp (HTTPS)** | Casi siempre abierto; el TLS oculta el contenido | Bajo, salvo inspección TLS ([[05 - DPI, inspección TLS y blending de tráfico\|inspección TLS]]) |
| **53 (DNS)** | Sale aunque todo lo demás esté cerrado; obligatorio para resolver | Medio: volumen y entropía delatan ([[10 - DNS tunneling con dnscat2\|dnscat2]]) |
| **80/tcp (HTTP)** | Abierto casi siempre; sin cifrar, el proxy lo lee entero | Medio-alto: el DPI ve el contenido |
| **ICMP** | A veces olvidado en la ACL de salida | Medio ([[11 - ICMP tunneling\|túnel ICMP]]) |
| **Puertos altos directos** | Si el egress es «permitir todo», sale cualquier cosa | El más ruidoso: conexión anómala pura |

<mark style="background: #8000E1A6;">La regla es salir por el puerto que más se parece al tráfico normal de ese host</mark>: un servidor web saliendo por 443 no llama la atención; una base de datos abriendo una sesión saliente a una IP nueva por 8443, sí. El canal ideal no es el que está abierto, sino el que además **es esperable** en ese origen.

## Cuando solo sale DNS

El caso extremo, y más común de lo que parece: el host no tiene salida directa a Internet, pero **resuelve nombres** —tiene que hacerlo para funcionar—. Ahí el DNS es el único canal, y se tuneliza con [[10 - DNS tunneling con dnscat2|dnscat2]] o `iodine`. Es lento y ruidoso (la exfiltración por subdominios genera un volumen de consultas anómalo), pero **sale de sitios de los que nada más sale**. El mecanismo, los límites de ancho de banda y su detección están en el [[00 - Introducción al pivoting y los túneles|bloque de pivoting y túneles]].

# El egress moderno: proxy obligatorio e inspección

Las redes corporativas serias ya no permiten salida directa: **todo el tráfico saliente pasa por un proxy o un SWG** (Zscaler, Netskope, Palo Alto Prisma). Eso cambia el juego:

- **No hay ruta directa**: un `reverse shell` a una IP cruda no sale porque no hay *default route* a Internet; solo el proxy tiene salida. Tu canal tiene que hablar **HTTP/S a través del proxy** (respetando `HTTP CONNECT`, autenticación NTLM/Kerberos incluida).
- **El proxy registra y categoriza**: cada destino queda en un log con URL, categoría y usuario. Un dominio recién registrado o sin categorizar se bloquea o se marca. Aquí entra la **infraestructura con reputación** ([[06 - Rotación de origen e infraestructura sacrificable|dominios envejecidos y categorizados]]).
- **Inspección TLS**: si el SWG rompe el TLS con su CA en el endpoint, el 443 deja de ser opaco. La respuesta es **fundirse con SaaS legítimo** —C2 sobre servicios permitidos (`Slack`, `Teams`, GitHub)— y fingerprints TLS de navegador real ([[05 - DPI, inspección TLS y blending de tráfico|DPI e inspección TLS]]).

<mark style="background: #FF5582A6;">Frente a un egress con proxy e inspección, el canal ya no se elige por "qué puerto sale" sino por "a qué servicio permitido me puedo parecer"</mark>.

# El egress es la casa del defensor

Merece decirlo aquí porque cambia la prioridad: el punto de salida es **donde el *blue team* tiene la mejor telemetría**. Un escaneo entrante se pierde entre el ruido de Internet; una conexión saliente a un destino nuevo, periódica (el *beaconing* de un C2), con un fingerprint TLS que no es de navegador, destaca sobre una línea base de tráfico conocido. La detección de *beaconing*, el volumen de DNS y los logs de proxy son sensores baratos y muy eficaces ([[01 - Sensores defensivos - tipos y colocación|sensores defensivos]] · [[08 - Cómo te ve el defensor|cómo te ve el defensor]]). Por eso el egress se trata con el mismo cuidado que el resto de la cadena, no como un detalle de conectividad.

> [!important]+ Regístralo: el egress permisivo es un hallazgo
> Un perímetro que deja salir por cualquier puerto es una **debilidad reportable**, no solo tu comodidad. Formúlalo por su impacto: *«El filtrado de salida permite conexiones a Internet por cualquier puerto TCP desde el segmento de servidores, habilitando canales de C2 y exfiltración arbitrarios; se recomienda restringir el egress a los destinos y puertos estrictamente necesarios y forzar el resto a través de un proxy inspeccionado.»* Es de los hallazgos con mejor relación impacto/coste de remediación ([[06 - Cómo redactar un hallazgo|cómo redactar un hallazgo]]).

> [!warning]+ Lo legal, otra vez
> Probar el egress implica **sacar datos** de la red del cliente hacia infraestructura tuya. Aunque sean datos de prueba, en un engagement hay que tenerlo autorizado por escrito y acotado en el RoE ([[04 - Pre-engagement II - RoE y kick-off|RoE]]); en bug bounty, la exfiltración suele estar explícitamente prohibida ([[01 - Reglas, legalidad y conducta|reglas y conducta]]).

> [!info]+ Fuentes
> Marco de técnicas en MITRE ATT&CK: [T1071](https://attack.mitre.org/techniques/T1071/) *Application Layer Protocol*, [T1048](https://attack.mitre.org/techniques/T1048/) *Exfiltration Over Alternative Protocol* y [T1572](https://attack.mitre.org/techniques/T1572/) *Protocol Tunneling*. Herramienta de prueba de egress y exfiltración: [Egress-Assess](https://github.com/FortyNorthSecurity/Egress-Assess) (FortyNorth Security); servicio público de todos los puertos: `portquiz.net`. Los túneles concretos (DNS, ICMP, SOCKS) viven en el [[00 - Introducción al pivoting y los túneles|bloque de pivoting]]; el guardado de la infraestructura de salida, en [[06 - Rotación de origen e infraestructura sacrificable]].
