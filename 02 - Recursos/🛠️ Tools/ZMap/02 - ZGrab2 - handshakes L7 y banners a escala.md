---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "ZMap dice qué puertos responden; ZGrab2 negocia el protocolo y guarda la transcripción completa del handshake para analizarla offline"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Uso de ZMap - probe modules, blocklist y sharding]]"
Nota siguiente: "[[03 - ZDNS - resolución DNS masiva]]"
Area: "[[ZMap.base|ZMap]]"
---
---

<mark style="background: #ADCCFFA6;">ZGrab2 es un escáner modular de capa de aplicación</mark>: recibe hosts vivos y, por cada uno, completa el diálogo del protocolo que le pidas. La división del trabajo que documenta el propio proyecto es literal — *«ZMap identifica hosts que responden en L4, ZGrab hace los handshakes L7 de seguimiento»*.

Su rasgo diferencial frente a cualquier otro *banner grabber* es que **no resume**: guarda la **transcripción completa** del intercambio —todos los mensajes de un handshake TLS, por ejemplo— en JSON, para analizarla después. Eso convierte un escaneo en un dataset, no en una lista.

# Los 31 módulos de protocolo

| | | | |
| --- | --- | --- | --- |
| AMQP | BACnet | Banner | DNP3 |
| Fox | FTP | HTTP | IMAP |
| IPP | JARM | ManageSieve | Memcached |
| Modbus | MongoDB | MQTT | MSSQL |
| MySQL | NTP | Oracle | POP3 |
| PostgreSQL | PPTP | Redis | Siemens |
| SMB | SMTP | SOCKS5 | SSH |
| Telnet | TLS | | |

Dos observaciones que valen para pentest real:

- <mark style="background: #FFB86CA6;">Están los protocolos industriales que Nmap cubre a medias</mark>: **Modbus, DNP3, BACnet, Siemens (S7) y Fox (Tridium Niagara)**. Si te toca un entorno OT/ICS, ZGrab2 identifica dispositivos que un `-sV` etiqueta como genéricos.
- **JARM** es un módulo propio: genera la huella JARM del servidor TLS, que sirve para agrupar infraestructura por configuración de pila TLS — la técnica que se usa para cazar servidores C2 y también para agrupar activos de un mismo cliente.

# Invocación

## Un solo protocolo

```shell-session
$ echo "pool.ntp.org" | zgrab2 ntp
$ zgrab2 http --help
```

Lee objetivos de `stdin` (o de `--input-file`) y escribe JSON. Un módulo, un puerto.

## Formato de entrada

CSV con hasta cuatro campos, todos opcionales salvo que haya IP o dominio:

```text
IP, DOMAIN, TAG, PORT
```

```text
10.0.0.1
ejemplo.com
10.0.0.1, ejemplo.com
10.0.0.1, , interno, 5678
203.0.113.0/24
```

Los bloques CIDR se expanden solos. `TAG` es lo que permite el disparo condicional del modo múltiple.

## Varios protocolos a la vez

El modo `multiple` con un `.ini` es donde ZGrab2 se separa del resto:

```ini
[Application Options]
output-file="salida.json"
input-file="objetivos.csv"

[http]
name="http80"
port=80
endpoint="/"

[http]
name="http8080"
port=8080
endpoint="/"

[tls]
port=443

[ssh]
port=22
```

```shell-session
$ zgrab2 multiple -c multiple.ini
```

Cada bloque es una pasada independiente con su propio nombre, puerto y opciones. Con `--trigger` y las etiquetas del CSV se aplica un módulo **solo** a los objetivos marcados: útil para no lanzar el módulo de MSSQL contra 200.000 hosts cuando solo 40 tienen el 1433 abierto.

# La cadena completa

```shell-session
# 1) L4: qué responde
$ sudo zmap -p 443 -w scope.txt -B 5M \
    -f saddr --output-filter="success = 1 && repeat = 0" --no-header-row -o vivos.csv

# 2) L7: qué es
$ cat vivos.csv | zgrab2 tls --port 443 -o tls.json

# 3) análisis offline
$ jq -r 'select(.data.tls.status=="success")
         | [.ip, .data.tls.result.handshake_log.server_certificates.certificate.parsed.subject.common_name[0]]
         | @tsv' tls.json | sort -u
```

<mark style="background: #8000E1A6;">El paso 3 es donde está el valor</mark>: como la transcripción está entera en el JSON, puedes preguntar cosas que no decidiste antes de escanear — qué versión de TLS negocia cada host, qué cifrados ofrece, qué SAN tiene el certificado, si la cadena está caducada. Con un escáner que solo guarda un resumen, esas preguntas obligan a repetir el escaneo.

## Qué sacar de ahí en un engagement

- **Nombres del certificado (CN y SAN)** — hostnames internos, dominios hermanos y entornos de preproducción que no salían en el recon pasivo ([[07 - Certificate Transparency logs]]).
- **Versiones de servidor HTTP y cabeceras** — inventario de tecnología para cruzar con CVEs ([[09 - Fingerprinting web]]).
- **Huella JARM** — agrupar hosts por pila TLS idéntica: delata balanceadores, CDNs y, en la práctica, qué hosts son en realidad la misma máquina detrás de IPs distintas.
- **Protocolos que no deberían estar expuestos** — Redis, MongoDB, Memcached y MSSQL sin autenticar son hallazgos de criticidad alta por sí mismos ([[Ataque a servicios comunes.base|ataque a servicios comunes]]).

> [!warning]+ ZGrab2 completa conexiones: esto no es sigiloso
> A diferencia de ZMap, que manda un paquete y se olvida, <mark style="background: #FF5582A6;">ZGrab2 establece la sesión, negocia el protocolo y a veces se autentica</mark>. Cada objetivo tocado deja línea en el log de la aplicación: `access.log` de nginx, log de conexión de SSH, evento de sesión de MSSQL. Es la herramienta correcta para inventariar superficie con permiso, y la equivocada para una fase que quieras discreta. Ver [[04 - Evasión, detección y ética del escaneo a escala]].

> [!important]+ Verifica antes de reportar
> ZGrab2 reporta lo que el servidor **dijo**, y los servidores mienten (banners falsificados, cabeceras `Server` cambiadas, honeypots que fingen ser cualquier cosa). Un hallazgo de ZGrab2 es una hipótesis; confirmarla es trabajo de [[03 - Enumeración de servicios y versiones|Nmap `-sCV`]] o de interacción manual. En un informe, la diferencia entre «el banner dice X» y «se ha verificado X» es la que separa un hallazgo de un falso positivo.

> [!info]+ Estado
> **ZGrab2 v1.0.0 (diciembre de 2025)** es su primer *release* estable tras años en pre-release, con commits en julio de 2026. Verificado el 2026-08-04 contra la API de GitHub.

> [!info]+ Fuente
> [README de ZGrab2](https://github.com/zmap/zgrab2) — relación con ZMap, tabla de los 31 módulos, sintaxis del CSV de entrada, modo `multiple` con `.ini`, `--trigger` y formato JSON de salida.
