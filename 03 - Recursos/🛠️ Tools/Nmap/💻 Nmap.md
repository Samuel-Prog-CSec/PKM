---
tags:
  - "#Pentesting/Enumeracion"
  - Linux
  - Windows
  - "#Escaneo/Redes"
Fecha de actualización: 2025-08-31
Nota previa:
Nota siguiente: "[[🕵️‍♂️ Hosts]]"
Area: "[[1️⃣ Enumeracion]]"
---
---

**Nmap** es una herramienta de escaneo de puertos y análisis de redes de código abierto que se utiliza para identificar hosts y servicios en una red. 

*https://nmap.org*

Nmap es una de las herramientas de seguridad más populares y potentes de la actualidad, y se utiliza en pruebas de [[Pentesting]], hacking ético, administración de redes y otros propósitos relacionados con la seguridad de la red.


# Cheatsheet

| **Comando**                            | **Descripción**                                                                                        |
| :------------------------------------- | :----------------------------------------------------------------------------------------------------- |
| `nmap <host>`                          | Escaneo de host simple                                                                                 |
| `nmap -p 1-1000 <host>`                | Escaneo de un rango de puertos                                                                         |
| `nmap -p- <host>`                      | Escaneo de todos los puertos                                                                           |
| `nmap -F <host>`                       | Escaneo de los 100 puertos más comunes                                                                 |
| `nmap -sV <host>`                      | Escaneo de servicios y versiones                                                                       |
| `nmap -T5 -F -n <host>`                | Escaneo rápido sin resolución de DNS                                                                   |
| `nmap -O <host>`                       | Escaneo de sistemas operativos                                                                         |
| `nmap --script vuln <host>`            | Escaneo de scripts de vulnerabilidades                                                                 |
| `nmap --script <script_name> <host>`   | Escaneo de scripts específicos                                                                         |
| `nmap -sS <host>`                      | Escaneo sigiloso (no genera registros en destino, no es el más sigiloso, pero es rápido que el `-sA`)  |
| `nmap -sU <host>`                      | Escaneo UDP                                                                                            |
| `nmap -sn <network>`                   | Escaneo de hosts vivos en una red                                                                      |
| `nmap -oX output.xml <host>`           | Guardar resultados en formato XML                                                                      |
| `nmap -Pn <host>`                      | Escaneo sin ping (útil para saltarse firewalls que bloquean ICMP)                                      |
| `nmap -A <host>`                       | Escaneo avanzado y agresivo (incluye `-O`, `-sV`, `--traceroute` y scripts por defecto [`-sC`])        |
| `nmap --open <host>`                   | Muestra solo los puertos abiertos                                                                      |
| `nmap -p <puerto> --reason <host>`     | Muestra la razón por la cual un puerto está en un estado específico (abierto, cerrado, filtrado, etc.) |
| `nmap --top-ports 100 <host>`          | Escanea los 100 puertos más comunes (similar a `-F`, pero puedes ajustar el número de puertos)         |
| `nmap --script firewall-bypass <host>` | Detecta si es posible saltar un firewall                                                               |
| `nmap --script discovery <host>`       | Usa scripts de descubrimiento (DNS, SNMP, NetBIOS, etc.)                                               |
| `nmap -sA <host>`                      | Escaneo ACK para detectar reglas de firewall                                                           |
| `nmap -sW <host>`                      | Escaneo de ventana TCP (para detección de firewall)                                                    |
| `nmap -sI <zombie_host> <target>`      | Escaneo de IP Idle (para evitar ser detectado)                                                         |
| `nmap --script http-enum <host>`       | Enumera directorios y archivos en servidores HTTP                                                      |
