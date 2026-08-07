---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "Tu IP de origen es tu identidad — escalonar la infraestructura, rotar el origen y operar desde algo que puedas quemar sin perder la operación"
Fecha de actualización: 2026-08-04
Nota previa: "[[05 - DPI, inspección TLS y blending de tráfico]]"
Nota siguiente: "[[07 - Low-and-slow y evasión de umbrales]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Todas las notas anteriores tratan **cómo** mandas el paquete. Esta trata **desde dónde**. <mark style="background: #ADCCFFA6;">La infraestructura de ataque es parte del ataque</mark>: la IP de origen es tu identidad ante el defensor, y si operas todo desde una sola dirección, le regalas dos regalos —la correlación (todo lo tuyo cae junto) y el punto único de bloqueo (te corta una vez y estás fuera)—. El diseño de la infraestructura es lo que decide cuánto le cuesta al defensor ambas cosas.

# El origen es tu identidad

Un SOC no reconstruye tu ataque por el contenido de cada paquete, sino **correlacionando por origen**: «esta IP escaneó, luego intentó login, luego abrió una sesión saliente». Una sola IP convierte una cadena de eventos dispersos en <mark style="background: #FFB86CA6;">un caso cerrado con tu nombre</mark>. Y si esa IP es además la de tu C2, cuando la bloquean pierdes la operación entera.

La respuesta no es un truco, es una **arquitectura**: separar funciones en infraestructura distinta y anteponer piezas desechables a las que de verdad importan.

# Infraestructura escalonada

El patrón profesional de la infraestructura de red team separa por función y por "quemabilidad":

- **Recon** en su propia infraestructura, separada del **C2**. El escaneo es lo primero que se detecta; si comparte IP con el C2, quemas el C2 al escanear.
- **Redirectores** delante de todo lo que importa. Un *redirector* es una pieza barata (un VPS, una función *serverless*) que recibe el tráfico y **reenvía al backend real solo lo que cumple tus condiciones**; el resto lo manda a un señuelo o a `example.com`. El defensor ve y bloquea el redirector; tú lo rotas en minutos y **el backend —tu C2 real— sigue vivo y sin exponer**.

```shell-session
# Redirector mínimo con socat: reenvía al C2 real sin exponerlo
$ socat TCP-LISTEN:443,fork,reuseaddr TCP:c2-real.interno:443
```

<mark style="background: #8000E1A6;">Lo que se quema es siempre la capa más externa y más barata</mark>. Los redirectores se hacen con `socat` ([[05 - Redirección de tráfico con Socat|redirección con Socat]]), `nginx`/Apache con `mod_rewrite` filtrando por User-Agent y URI, o funciones de CDN (Cloudflare Workers) que además prestan su reputación.

# Rotación de origen: que no haya un "el origen"

Para las fases que generan muchas peticiones desde fuera —escaneo web, enumeración, *password spraying*— la defensa habitual es el *rate-limiting* y el bloqueo **por IP**. Se derrota repartiendo el origen:

- **`fireprox`** (Black Hills Information Security) monta un **AWS API Gateway** que hace de proxy hacia el objetivo, y <mark style="background: #FF5582A6;">cada petición sale desde una IP distinta del rango de AWS</mark>. Es la forma estándar de anular el *rate-limiting* por IP en un login o una API sin levantar cien VPS.

```shell-session
$ python fire.py --command create --url https://objetivo.com
# → devuelve una URL de API Gateway; el objetivo ve una IP AWS nueva por request
```

- **`ProxyCannon-NG`** levanta instancias EC2 como nodos de salida rotativos para todo tu tráfico.
- **`proxychains-ng`** encadena tu tráfico por una lista de proxies SOCKS/HTTP que tú controlas.
- **Tor** es el último recurso: gratis, pero sus nodos de salida están catalogados, van lentos y muchos objetivos los bloquean de entrada.

> [!warning]+ Rotar la IP no rota lo demás
> Cambiar de IP cada petición no sirve de nada si tu **fingerprint TLS** ([[05 - DPI, inspección TLS y blending de tráfico|JA4]]), tu User-Agent o tu **dominio** siguen siendo los mismos: el defensor correlaciona por el indicador más estable que dejes. La rotación de origen se combina con el *blending* de la nota anterior, no lo sustituye.

# La reputación es un activo operativo

No todas las IPs pesan igual ante la *threat intel*. Una dirección **residencial sospechosa o ya catalogada** como escáner dispara solo con existir; una **IP limpia de un rango cloud reputado** pasa desapercibida. Es el matiz que hace que el hallazgo `PortProbeUnprotectedPort` de AWS GuardDuty **exija que tu IP figure como escáner conocido** para saltar ([[08 - Detección de escaneos y evasión moderna|detección en la nube]]): con infraestructura limpia, no salta.

Lo mismo con los **dominios**: los SWG bloquean o marcan lo recién registrado y lo sin categorizar. La contramedida es **envejecer y categorizar** el dominio antes de usarlo (registrarlo con semanas de antelación, conseguir que las categorizadoras lo clasifiquen como benigno) para que el proxy corporativo lo deje pasar. Un dominio "limpio" con su certificado válido de Let's Encrypt es infraestructura preparada, no improvisada.

# Higiene y coordinación

> [!important]+ Reglas mínimas de infraestructura
> - **Nunca reutilices IPs ni dominios entre clientes** — una quema arrastra a la otra y mezcla evidencia de dos engagements.
> - **Un dominio/redirector desechable por campaña**, no uno para todo.
> - **VPS sacrificables**: asume que cada pieza externa acabará quemada y diséñala para poder tirarla sin perder nada.
> - **Da por hecho la queja de abuso**: un escaneo agresivo genera *abuse reports* al proveedor de tu VPS; ten infraestructura de repuesto.

La otra cara es la **coordinación**. En un pentest o red team **anunciado**, entregar al *blue team* la lista de tus IPs de origen (*deconflicting*) no es hacer trampa: es evitar que una alerta tuya se confunda con un incidente real y active la respuesta a incidentes ([[03 - Coordinación de operadores y deconflicting|deconflicting]]). Y en un ejercicio de emulación, la elección de infraestructura puede ser deliberada para **imitar a un actor concreto** o, al revés, para no atribuirse a él por error ([[02 - Atribución y operaciones de bandera falsa|atribución y banderas falsas]]).

<mark style="background: #FFB8EBA6;">Esto sube al atacante en la Pirámide del Dolor</mark>: las IPs y dominios son indicadores baratos de rotar, pero obligar al defensor a detectarte por comportamiento —y no por un origen fijo— es exactamente lo que encarece su trabajo ([[01 - Frameworks de threat intelligence y la Pyramid of Pain|Pyramid of Pain]]).

> [!info]+ Fuentes
> Diseño de infraestructura (redirectores, capas y categorización de dominios): [Red Team Infrastructure Wiki](https://github.com/bluscreenofjeff/Red-Team-Infrastructure-Wiki) (Jeff Dimmock), la referencia comunitaria del tema. Rotación de IP: [fireprox](https://github.com/ustayready/fireprox) (Black Hills Information Security), [ProxyCannon-NG](https://github.com/proxycannon/proxycannon-ng), [proxychains-ng](https://github.com/rofl0r/proxychains-ng). Técnicas MITRE ATT&CK: [T1090](https://attack.mitre.org/techniques/T1090/) *Proxy*, [T1583](https://attack.mitre.org/techniques/T1583/) *Acquire Infrastructure*, [T1584](https://attack.mitre.org/techniques/T1584/) *Compromise Infrastructure*, [T1665](https://attack.mitre.org/techniques/T1665/) *Hide Infrastructure*. El arsenal concreto, en [[09 - Arsenal de evasión de perímetro]].
