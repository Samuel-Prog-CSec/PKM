---
tags:
  - Blue-Team
  - Zero-Trust
  - Tipo/Defensa
Descripción: "Por qué bloquear solo lo malicioso conocido no basta, y cómo el zero-trust formaliza el 'distrust por defecto' con NIST SP 800-207 y la CISA ZTMM 2.0"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - Sensores defensivos - tipos y colocación]]"
Nota siguiente: "[[03 - Deception defensiva - honeypots, tiger traps y captura en vivo]]"
Area: "[[Doctrina defensiva.base|Doctrina defensiva]]"
---
---

*Cyberjutsu* llama a esto "seguridad xenófoba": el shinobi que intentaba infiltrarse en una aldea medieval japonesa se enfrentaba a comunidades que <mark style="background: #ADCCFFA6;">desconfiaban de cualquier forastero por defecto</mark> — dialecto, vestimenta y costumbres únicas delataban al de fuera. La lección defensiva es que la mayoría de las redes hacen lo contrario: están construidas sobre estándares universales (PnP, DHCP, ARP, SMB) diseñados para **aceptar** lo desconocido sin fricción. El zero-trust es la formalización moderna de la desconfianza que McCarty proponía.

# Bloquear lo malicioso vs. bloquear lo sospechoso

Durante más de una década las organizaciones han consumido *threat feeds* de IPs, dominios y URLs maliciosos conocidos, y bloquearlos es fácil. Pero eso es **block-malicious**: una persecución sin fin de indicadores que el adversario rota a voluntad (la base de la [[01 - Frameworks de threat intelligence y la Pyramid of Pain|Pyramid of Pain]]). Lo difícil, y lo que de verdad protege, es **block-suspicious**: <mark style="background: #FFB86CA6;">denegar por defecto todo lo que no esté explícitamente permitido</mark>.

El experimento del libro sigue funcionando como demostración: haz un `ping` o una consulta DNS externa a un servidor en Corea del Norte (`175.45.178.129`) o Irán. Si responde, tu red <mark style="background: #FF5582A6;">permitió comunicación con un sistema sin ninguna razón de negocio</mark> — y no lo bloqueó porque esas IPs no están en ningún *threat feed* (no han alojado malware conocido). Block-malicious no cubre lo desconocido; deny-by-default sí. El coste es real (14,3 millones de subredes `/24` en IPv4 no se bloquean a mano), y por eso la solución no es una *blacklist* infinita sino una *whitelist* de lo necesario.

# El modelo formal: NIST SP 800-207 y CISA ZTMM 2.0

Lo que en 2021 era una intuición ("xenophobic security") hoy es doctrina con marco. `NIST SP 800-207` (2020) define la arquitectura *zero-trust* bajo el principio <mark style="background: #8000E1A6;">"never trust, always verify"</mark>: ningún activo es de confianza por su ubicación en la red; cada acceso se verifica de forma continua, por identidad, contexto y estado del dispositivo. En EE. UU. dejó de ser opcional con la Orden Ejecutiva 14028 y el memorando `OMB M-22-09` (2022), que lo convirtió en mandato federal.

La `CISA Zero Trust Maturity Model 2.0` (abril de 2023) lo operativiza en **cinco pilares**, tres capacidades transversales y cuatro escalones de madurez:

| Pilar | Qué asegura |
| --- | --- |
| Identity | Verificación fuerte y continua de identidad |
| Devices | Postura y confianza del dispositivo |
| Networks | Microsegmentación, cifrado interno |
| Applications & Workloads | Acceso por aplicación, no por red |
| Data | Clasificación y control centrado en el dato |

Transversales a los cinco: **Visibility & Analytics**, **Automation & Orchestration** y **Governance**. Cada pilar se mide en una escalera de madurez de cuatro peldaños — `Traditional → Initial → Advanced → Optimal` — que permite migrar por etapas en lugar de "encender zero-trust" de golpe.

> [!important]+ Del perímetro a la identidad
> El cambio de fondo respecto al modelo del libro: la unidad de confianza ya no es la **red** (dentro = confiable) sino la **identidad + contexto** de cada petición. Esto responde directamente al punto ciego este-oeste de los [[01 - Sensores defensivos - tipos y colocación|sensores]]: si no hay "dentro" confiable, el movimiento lateral deja de ser gratis.

# El problema no es técnico, es humano

*Cyberjutsu* acierta en que la parte difícil no es la tecnología sino la cultura. Bloquear lo sospechoso choca con la necesidad humana de estímulo: si bloqueas el streaming y las redes sociales, los empleados <mark style="background: #FFB86CA6;">presionan para revertirlo o lo eluden con VPN, túneles o proxies</mark> — aumentando el riesgo. Soluciones que funcionan:

- **Red BYOD / internet separada**: máquinas o segmentos dedicados al uso no laboral, físicamente aislados del intranet — el modelo `NIPRnet` del DoD.
- **ISAC**: unirse a un *Information Sharing and Analysis Center* del sector para compartir listas de sitios/IPs de confianza y reducir el coste de mantener la whitelist.
- **Assurance mutua**: escaneo y red teaming recíproco con los socios de confianza que tienen interconexión directa — el eco del consejo del *Bansenshūkai* de ayudar a los mercaderes de confianza a proteger sus tiendas contra el fuego, para que no se propague al campamento.

El zero-trust no elimina la necesidad de detección ni de deception — la [[03 - Deception defensiva - honeypots, tiger traps y captura en vivo|siguiente nota]] cubre qué hacer con lo que sí logra entrar. Y la contracara ofensiva —cómo el atacante detecta y evade un entorno endurecido— se razona desde [[00 - El mindset del atacante persistente|Doctrina pentesting]].

> [!info]+ Fuentes
> - NIST, [SP 800-207 *Zero Trust Architecture*](https://csrc.nist.gov/pubs/sp/800/207/final), 2020.
> - CISA, [*Zero Trust Maturity Model* v2.0](https://www.cisa.gov/zero-trust-maturity-model), abril 2023.
> - OMB, [M-22-09 *Federal Zero Trust Strategy*](https://zerotrust.cyber.gov/), 2022 (mandato tras EO 14028).
> - Ben McCarty, *Cyberjutsu*, caps. 3 ("Xenophobic Security") y 25 ("Zero-Trust Threat Management"), 2021.
