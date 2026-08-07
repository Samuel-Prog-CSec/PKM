---
tags:
  - Wi-Fi/Enterprise
  - MITM
  - Pentesting/Explotacion
Descripción: "Qué probar en una red de invitados abierta: aislamiento de clientes, el portal cautivo y por qué el MITM clásico con sslstrip ya no funciona contra HTTPS"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Reconocimiento de un parque de APs]]"
Nota siguiente: "[[03 - WPA2-PSK en un engagement]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Una red de invitados abierta no tiene contraseña que romper, así que el objetivo cambia: <mark style="background: #ADCCFFA6;">demostrar qué se puede alcanzar **desde dentro** de esa red y si está realmente separada del resto</mark>. Casi siempre el hallazgo no es el portal cautivo, es la segmentación.

# Enumerar desde dentro

Tras asociarse, lo primero es situarse en la topología:

```shell-session
$ ip addr show wlan0
$ ip route
$ sudo nmap -sn -n 200.200.200.0/24
$ sudo nmap --open -T4 -p- 200.200.200.60
```

> [!info]+ `ifconfig` y `route` están deprecados
> HTB usa `ifconfig` y `route -n`, de `net-tools`, sin mantenimiento desde 2011 y ausentes por defecto en distribuciones modernas. Los equivalentes de `iproute2` son `ip addr` e `ip route`. Es el mismo desfase que arrastra todo el path con `iwconfig`/`iwlist`, y está desarrollado en [[04 - Interfaces, chipsets y drivers]].

Lo que se busca, por orden de valor:

| Hallazgo | Qué significa |
| -------- | ------------- |
| Otros clientes alcanzables | **No hay aislamiento de clientes**: se pueden atacar entre sí |
| Rutas hacia rangos internos | La guest no está segmentada del corporativo |
| DNS interno respondiendo | Fuga de nombres internos desde una red pública |
| Servicios en la puerta de enlace | El propio AP o controlador es objetivo — ver [[09 - Explotación del gateway inalámbrico]] |

<mark style="background: #FFB86CA6;">El aislamiento de clientes es la comprobación de un minuto que más veces produce un hallazgo real</mark>. Si un `nmap -sn` sobre el /24 devuelve otros invitados, cualquiera en la sala de espera puede atacar los portátiles de los demás.

# El portal cautivo

Visitar cualquier URL redirige al portal. Antes de intentar saltárselo conviene entender cómo autoriza, porque de ahí sale el bypass:

| Mecanismo | Bypass habitual |
| --------- | --------------- |
| Autorización por **MAC** tras el login | Suplantar la MAC de un cliente ya autorizado |
| Sólo se filtra HTTP/HTTPS | **Túnel DNS** o ICMP hacia fuera |
| Cookie o token de sesión | Robo por MITM en la propia red |
| Sin límite de tiempo por sesión | Reutilización indefinida |

> [!warning]+ Suplantar la MAC de un cliente autorizado provoca DoS
> Es la técnica más citada y tiene un efecto colateral serio: **dos estaciones con la misma MAC en la misma celda** generan colisiones y desconectan al usuario legítimo. En un hospital eso puede afectar a equipamiento clínico. <mark style="background: #FF5582A6;">Es una acción destructiva encubierta</mark>, y en un engagement con DoS fuera de alcance hay que pedir permiso explícito o limitarse a documentar la posibilidad.

El bypass de portales cautivos tiene módulo propio en el path (**299 · Bypassing Wi-Fi Captive Portals**, aún sin extraer); aquí basta con identificar el mecanismo y dejar el desarrollo para cuando ese sub-tema exista, bajo [[Wi-Fi Pentesting.base|Wi-Fi Pentesting]].

# MITM en la red de invitados

Con clientes alcanzables, el siguiente paso es interceptar. `ettercap` sigue vivo —**v0.8.4.1 «Garofalo», abril de 2026**— y hace ARP spoofing sin fricción; `bettercap` cubre lo mismo con mejor ergonomía y soporte IPv6, que Ettercap no tiene.

```shell-session
$ sudo bettercap -iface wlan0
> set arp.spoof.targets 200.200.200.60
> arp.spoof on
> net.sniff on
```

> [!warning]+ El MITM contra HTTPS de 2015 ya no funciona
> HTB propone `sslstrip` y la interceptación SSL de Ettercap como si siguieran siendo viables. En 2026 no lo son:
>
> - **HSTS** hace que el navegador rechace la degradación a HTTP en cualquier sitio que lo declare, y la **lista de precarga** lo aplica incluso en la primera visita.
> - Un **certificado autofirmado** provoca una advertencia que en sitios con HSTS **no se puede saltar**: el navegador no ofrece el botón de continuar.
> - <mark style="background: #FF5582A6;">La técnica sólo funciona contra tráfico HTTP en claro</mark>, que en 2026 es residual… salvo en un sitio muy concreto: **el propio portal cautivo**.
>
> Y esa es la excepción que la hace útil aquí. Un portal cautivo tiene que interceptar la primera petición, así que muchos siguen sirviéndose por HTTP o con un certificado que no valida contra el nombre visitado. Las credenciales que se capturan son las **del portal**, no las de la banca del usuario.

Lo que sí sigue rindiendo en una red abierta:

| Técnica | Por qué funciona todavía |
| ------- | ------------------------ |
| Captura pasiva | En red abierta **todo el tráfico va en claro por radio** |
| Envenenamiento de DNS | Muchos clientes no validan DNSSEC ni usan DoH |
| Suplantación del portal | HTTP por diseño, y el usuario espera un formulario |
| Análisis de metadatos | SNI, DNS y mDNS revelan qué usan los clientes |

<mark style="background: #8000E1A6;">La captura pasiva es el argumento decisivo del informe</mark>: en una red abierta sin OWE, cualquiera con una tarjeta en modo monitor lee el tráfico de todos los invitados sin asociarse siquiera. No hay que atacar nada para demostrarlo.

# La recomendación que cierra el hallazgo

| Problema | Medida |
| -------- | ------ |
| Tráfico legible por radio | **OWE** (*Wi-Fi CERTIFIED Enhanced Open*) |
| Invitados atacándose entre sí | Aislamiento de clientes en el WLAN |
| Guest con ruta al corporativo | VLAN dedicada y ACL de salida |
| Portal por MAC | Sesión ligada a credencial, con caducidad |

OWE ([RFC 8110](https://datatracker.ietf.org/doc/html/rfc8110)) cifra cada sesión con un Diffie-Hellman sin contraseña y elimina de raíz la captura pasiva. Está certificado **desde 2018** y es obligatorio para redes abiertas en 6 GHz, así que presentarlo como novedad está fuera de tiempo — el detalle en [[04 - WPA3, SAE y OWE]].

Su límite conviene decirlo en el mismo informe: **OWE no autentica el AP**, así que un gemelo malvado con el mismo SSID sigue funcionando. Resuelve la escucha pasiva, no la suplantación.
