---
tags:
  - Redes
  - Protocolos
Descripción: "SNMP (*Simple Network Management Protocol*) sirve para monitorizar y gestionar dispositivos de red —routers, switches, servidores, IoT— y también para cambiar su configuración…"
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`SNMP` (*Simple Network Management Protocol*) sirve para monitorizar y gestionar dispositivos de red</mark> —routers, switches, servidores, IoT— y también para cambiar su configuración en remoto. Un **agente** SNMP en el dispositivo responde consultas y ejecuta comandos de control sobre **`UDP 161`** (`162` para *traps*, avisos que el agente envía sin que se los pidan).

# MIB y OID: cómo se nombra la información

- **`MIB`** (*Management Information Base*): el "diccionario" jerárquico, independiente del fabricante, que describe qué se puede consultar. Es un árbol de objetos.
- **`OID`** (*Object Identifier*): la dirección de cada nodo del árbol, en notación con puntos (`1.3.6.1.2.1.1.1.0` = descripción del sistema). Cada OID apunta a un dato concreto (procesos, software, interfaces…).

# Versiones (y su seguridad)

| Versión | Seguridad |
| --- | --- |
| `SNMPv1` | Sin cifrado. Autenticación por *community string* en **texto plano**. |
| `SNMPv2c` | Igual de inseguro (community string en claro), pero añade operaciones masivas (`GetBulk`). |
| `SNMPv3` | <mark style="background: #FFB8EBA6;">Autenticación **y** cifrado</mark> (usuario/contraseña + privacidad). Más seguro, más complejo. |

# Community strings: la "contraseña"

<mark style="background: #FF5582A6;">En v1/v2c, la *community string* es toda la autenticación</mark>, y viaja en claro:

- **`public`** — por defecto, acceso de **lectura** (read-only).
- **`private`** — por defecto, acceso de **lectura y escritura** (read-write → cambiar config del dispositivo).

Que sigan en sus valores por defecto es de los findings más comunes en infraestructura de red.

# Relevancia ofensiva

Un SNMP con una community string adivinable es una **fuga masiva de información**: procesos en ejecución (¡con sus argumentos de línea de comandos, a veces contraseñas!), software instalado, usuarios, interfaces de red y rutas. Con `private`, además, se puede reconfigurar el dispositivo. La enumeración (`snmpwalk`, `onesixtyone`, `braa`) se trata en [[10 - SNMP|Footprinting de SNMP]].
