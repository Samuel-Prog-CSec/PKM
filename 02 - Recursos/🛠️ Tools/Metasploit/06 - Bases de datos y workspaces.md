---
tags:
  - Pentesting/Explotacion
  - Metasploit
Descripción: "Metasploit puede respaldarse en una base de datos PostgreSQL que registra todo lo descubierto durante el engagement — hosts, servicios, vulnerabilidades, credenciales y botín"
Fecha de actualización: 2026-07-18
Nota previa: "[[05 - Encoders]]"
Nota siguiente: "[[07 - Plugins y Mixins]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

<mark style="background: #ADCCFFA6;">Metasploit puede respaldarse en una base de datos `PostgreSQL` que registra todo lo descubierto durante el engagement</mark> — hosts, servicios, vulnerabilidades, credenciales y botín. En un pentest real con decenas de máquinas, es la diferencia entre trabajo organizado y caos.

# Setup

```shell-session
$ msfdb init            # crea la base y el usuario (una vez)
$ msfconsole -q
msf6 > db_status        # confirma la conexión
[*] Connected to msf. Connection type: postgresql.
```

<mark style="background: #FFB8EBA6;">Sin `db_status` en verde, comandos como `hosts`, `services` o `creds` no guardan nada</mark> — es el primer chequeo al arrancar.

# Workspaces: un engagement, un workspace

Un `workspace` aísla los datos de cada cliente/objetivo, para no mezclar resultados:

```shell-session
msf6 > workspace                 # lista (el activo lleva *)
msf6 > workspace -a cliente_x    # crea y cambia
msf6 > workspace cliente_x       # cambia a uno existente
msf6 > workspace -d viejo        # borra
```

# Poblar la base: `db_nmap` y `db_import`

Dos vías para llenar la base de hosts y servicios:

```shell-session
# Escaneo directo desde msfconsole (guarda resultados automáticamente)
msf6 > db_nmap -sV -sC 10.10.10.0/24

# Importar resultados de un escaneo externo
msf6 > db_import scan.xml
```

<mark style="background: #8000E1A6;">`db_import` acepta el XML de [[06 - Guardar y explotar resultados|Nmap]] (`-oX`) y de [[02 - Interpretar y exportar resultados|Nessus]]</mark>, entre muchos otros formatos — así el reconocimiento hecho fuera de MSF alimenta el framework sin repetir escaneos.

# Consultar lo recolectado

```shell-session
msf6 > hosts                     # máquinas descubiertas
msf6 > services -p 445           # servicios (filtrable por puerto)
msf6 > vulns                     # vulnerabilidades asociadas
msf6 > creds                     # credenciales capturadas
msf6 > loot                      # ficheros/hashes exfiltrados
msf6 > notes                     # anotaciones por host
```

Los módulos `auxiliary` de escaneo y los `post` de recolección **escriben** en estas tablas automáticamente: un `smb_login` exitoso deja las credenciales en `creds`, un `hashdump` deja los hashes en `loot`.

# Usarla para trabajar más rápido

La verdadera ventaja: **alimentar los módulos desde la base**. En vez de teclear IPs, se filtran hosts y se pasan directamente:

```shell-session
# fijar RHOSTS con todos los hosts que exponen SMB
msf6 > services -p 445 -R
```

<mark style="background: #FFB86CA6;">`-R` fija automáticamente `RHOSTS` con los resultados de la consulta</mark> — encadenar enumeración y explotación sin copiar-pegar IPs.

> [!important]+ OPSEC y limpieza
> La base guarda **credenciales y datos sensibles del cliente** en claro. Al cerrar el engagement, expórtala para el informe y luego **elimínala** (`workspace -d`, o purga la base). Dejar credenciales de un cliente en tu disco es un problema de custodia de datos, no un detalle.

La base organiza el trabajo; los [[07 - Plugins y Mixins|plugins]] lo extienden.
