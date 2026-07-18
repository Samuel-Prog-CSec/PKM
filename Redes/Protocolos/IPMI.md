---
tags:
  - Redes
  - Protocolos
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`IPMI` (*Intelligent Platform Management Interface*) es un estándar de gestión de hardware que funciona como un subsistema **autónomo**</mark>, independiente del BIOS, la CPU, el firmware y el SO del host. Permite a los administradores gestionar y monitorizar un servidor **aunque esté apagado o colgado**, mediante una conexión de red directa al hardware, sin necesidad de una shell del SO.

# El BMC

IPMI lo implementa el **`BMC`** (*Baseboard Management Controller*): un microcontrolador embebido en la placa con su propia CPU, memoria y stack de red. Los productos comerciales que lo exponen son omnipresentes en datacenter: **Dell iDRAC**, **HP iLO**, **Supermicro IPMI**, IBM IMM.

# Puerto y usos

- **`UDP 623`** — el servicio IPMI.
- Se usa para: modificar el BIOS antes de arrancar el SO, gestionar el host **totalmente apagado**, y recuperar un host tras un fallo. Fuera de eso, monitoriza temperatura, voltajes, ventiladores, etc.

# Por qué es un objetivo crítico

<mark style="background: #FFB86CA6;">Controlar el BMC es controlar el hardware por debajo del SO</mark>: montar medios virtuales, reiniciar, acceder a la consola KVM, reinstalar el sistema. Además:

- Los BMC **rara vez se parchean** (firmware olvidado) y arrastran vulnerabilidades históricas.
- Vienen con **credenciales por defecto** (Supermicro `ADMIN/ADMIN`, Dell iDRAC `root/calvin`).
- El propio protocolo IPMI 2.0 tiene un fallo de diseño que **filtra hashes de contraseña sin autenticación**.

# Relevancia ofensiva

Comprometer un IPMI = comprometer el servidor a nivel hardware, y por tanto su SO. La extracción de hashes (RAKP), el *cipher 0* y las credenciales por defecto se tratan en [[14 - IPMI|Footprinting de IPMI]].
