---
tags:
  - Wi-Fi
  - Pentesting/Post-Explotacion
Descripción: "Descifrar capturas WEP y WPA con la clave conocida, limpiar cabeceras 802.11 y el requisito del handshake que hace fallar el proceso"
Fecha de actualización: 2026-08-01
Nota previa: "[[04 - Aireplay-ng]]"
Nota siguiente: "[[06 - Aircrack-ng]]"
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`airdecap-ng` toma una captura cifrada y la clave de la red, y produce una captura en claro</mark>. Es el paso que convierte un `.cap` lleno de tramas 802.11 opacas en tráfico analizable — y por tanto el paso que convierte "he recuperado la contraseña" en un hallazgo con impacto demostrable.

# Qué hace

Tres operaciones distintas:

- **Limpiar cabeceras** de una captura de red abierta, dejando sólo el tráfico de red.
- **Descifrar WEP** con la clave en hexadecimal.
- **Descifrar WPA/WPA2** con la frase de paso o la `PMK`.

En todos los casos escribe un fichero nuevo con el sufijo `-dec.cap`; el original no se toca.

| Opción | Función |
| ------ | ------- |
| `-l` | No eliminar la cabecera 802.11 |
| `-b <bssid>` | Filtrar por BSSID del AP |
| `-e <essid>` | ESSID de la red objetivo |
| `-p <pass>` | Frase de paso WPA/WPA2 |
| `-k <pmk>` | `PMK` en hexadecimal |
| `-w <key>` | Clave WEP en hexadecimal |
| `-o <fichero>` | Fichero de salida (por defecto `<origen>-dec`) |
| `-c <fichero>` | Fichero aparte para los **paquetes WEP corruptos** |

<mark style="background: #FFB8EBA6;">`-c` es más útil de lo que parece en una auditoría WEP</mark>: separa los paquetes que no descifran bien, que suelen ser los inyectados por el propio ataque o los capturados con errores. Ver el volumen de corruptos frente al total es un buen indicador de la calidad de la captura y, por tanto, de la posición desde la que se hizo.

# El antes y el después

Sin descifrar, Wireshark sólo ve `802.11`: ni protocolo real, ni IPs, ni nada útil en la columna de información.

![Captura Wireshark cifrada mostrando sólo tramas 802.11 sin protocolo identificable](https://academy.hackthebox.com/storage/modules/222/airdecap-ng/Wireshark_1.JPG)

Tras `airdecap-ng`, aparecen ARP, DHCP, TCP, HTTP y las direcciones IP reales:

![La misma captura descifrada mostrando ARP, DHCP, TCP y direcciones IP](https://academy.hackthebox.com/storage/modules/222/airdecap-ng/Wireshark_2.JPG)

<mark style="background: #FFB86CA6;">Ese salto es exactamente el impacto que hay que llevar al informe</mark>: no "la contraseña era débil", sino "con la contraseña recuperada se leyó el tráfico de los clientes, incluidas estas credenciales en claro".

# Uso

## Red abierta: quitar el envoltorio inalámbrico

```shell-session
$ sudo airdecap-ng -b 00:14:6C:7A:41:81 opencapture.cap

Total number of stations seen            4
Total number of packets read           251
Number of plaintext data packets       251
```

Útil para pasar una captura de red abierta a herramientas que esperan Ethernet y no entienden radiotap.

## WEP

```shell-session
$ sudo airdecap-ng -w 1234567890ABCDEF HTB-01.cap
```

La clave va en hexadecimal, sin separadores. Una WEP de 64 bits son 10 dígitos hex; una de 128 bits, 26.

## WPA/WPA2

```shell-session
$ sudo airdecap-ng -p 'Contrasena123' HTB-01.cap -e "CyberCorp"

Total number of stations seen            6
Total number of packets read           356
Total number of WPA data packets       121
Number of decrypted WPA packets        121
```

<mark style="background: #FFB8EBA6;">El `-e` con el ESSID es obligatorio</mark>, no opcional: la `PMK` se deriva de la frase de paso **y del ESSID** mediante `PBKDF2`, así que sin el nombre exacto de la red la derivación da un valor distinto y no descifra nada. Un ESSID con espacios o mayúsculas mal copiadas produce el mismo fallo silencioso.

Con `-k` se puede pasar la `PMK` directamente, lo que ahorra recalcular `PBKDF2` en capturas grandes y sirve cuando se obtuvo la `PMK` pero no la contraseña.

# El requisito que HTB no menciona

> [!warning]+ Sin el 4-way handshake de un cliente, su tráfico no se descifra
> Es el fallo más frecuente y el material de HTB lo omite por completo. En WPA/WPA2 <mark style="background: #FF5582A6;">cada cliente tiene su propia `PTK`, derivada de la `PMK` **más los dos nonces y las dos MAC** intercambiados en el handshake</mark>. Conocer la contraseña da la `PMK`, que es común a toda la red, pero no basta: para descifrar el tráfico de un cliente concreto hace falta que **su** handshake esté en la captura.
>
> El síntoma es una salida que lee cientos de paquetes WPA y descifra cero:
> ```
> Total number of WPA data packets       842
> Number of decrypted WPA packets          0
> ```
> No es un problema de contraseña ni de ESSID: falta el handshake de ese cliente. La solución es capturar de nuevo forzando su reconexión, o aceptar que ese tráfico no se recupera.
>
> El tráfico **broadcast y multicast** sí se descifra con la `GTK`, que es de grupo — por eso a veces aparece algo descifrado aunque falten los handshakes individuales.

# La alternativa: descifrar en Wireshark

Para análisis interactivo, Wireshark descifra al vuelo sin generar un fichero intermedio. En *Preferences ▸ Protocols ▸ IEEE 802.11*, activar *Enable decryption* y añadir la clave:

| Tipo | Formato |
| ---- | ------- |
| `wpa-pwd` | `contraseña:ESSID` |
| `wpa-psk` | La `PMK` en hexadecimal (64 caracteres) |
| `wep` | La clave WEP en hexadecimal |

Ventajas sobre `airdecap-ng`: se puede cambiar la clave sin reprocesar, se conservan las cabeceras 802.11 junto al contenido descifrado —útil para correlacionar tramas de gestión con tráfico— y se aplican los filtros de Wireshark sobre el resultado. La limitación es la misma: sin handshake, no hay `PTK`. Ver [[Wireshark]].

<mark style="background: #8000E1A6;">La regla práctica: `airdecap-ng` para producir un artefacto que entregar o procesar con otras herramientas, Wireshark para investigar</mark>.

# Qué buscar en la captura descifrada

Una vez en claro, el trabajo es el de cualquier análisis de tráfico interno, y lo que sostiene el informe suele ser:

- **Credenciales en protocolos sin TLS** — HTTP básico, FTP, Telnet, SNMP, LDAP simple. Enlaza con [[12 - Credenciales en red - tráfico y shares]].
- **Segmentación real** — qué VLAN, qué gateway, qué alcanza el cliente. Si desde la red de invitados se ve tráfico de la corporativa, el hallazgo es la segmentación, no el Wi-Fi.
- **Inventario de dispositivos** — DHCP, mDNS y NetBIOS revelan nombres de host, sistemas operativos y roles sin escanear nada.
- **Tráfico de gestión de los AP** — a veces el propio AP habla con su controlador en claro.

Cómo llegar a la clave que hace falta aquí es [[06 - Aircrack-ng]].
