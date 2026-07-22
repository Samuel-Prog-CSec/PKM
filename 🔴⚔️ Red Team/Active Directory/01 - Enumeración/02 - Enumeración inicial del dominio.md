---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[01 - Reconocimiento y enumeración externa]]"
Nota siguiente: "[[03 - Enumeración de controles de seguridad]]"
Area: "[[AD Enumeración.base|Enumeración]]"
---
---

Punto de partida del *assumed breach*: una IP en la red interna, **sin credenciales todavía**. Esta fase dibuja el terreno —qué hosts hay, cuál es el `Domain Controller`, qué usuarios existen y qué se ve vulnerable— haciendo <mark style="background: #FFB8EBA6;">el menor ruido posible</mark>, porque aún no tienes nada que perder y sí una posición que quemar.

# Identificar hosts

Empieza **pasivo**. Con `tcpdump`/Wireshark y `Responder` en modo análisis escuchas el tráfico *broadcast* del segmento (ARP, mDNS, LLMNR, NBT-NS) y mapeas hosts sin emitir un paquete dirigido:

```shell-session
$ sudo responder -I ens224 -A
```

<mark style="background: #ADCCFFA6;">El flag `-A` pone Responder en modo *analyze*: observa y registra, pero no envenena</mark> — la forma más sigilosa de descubrir quién habla en la red. El envenenamiento activo llega en [[06 - Envenenamiento LLMNR y NBT-NS]].

Cuando puedas pasar a **activo**, un barrido rápido:

```shell-session
$ fping -asgq 172.16.5.0/23
$ nxc smb 172.16.5.0/23
```

<mark style="background: #FF5582A6;">`nxc smb <rango>` (NetExec) es el caballo de batalla moderno</mark>: en una línea da hostname, dominio, versión de SO, si exige *SMB signing* y si habla SMBv1 — todo lo necesario para localizar el DC y marcar objetivos de *relay*. La enumeración SMB a fondo (share hunting, sesiones nulas) está en [[05 - SMB]].

> [!info]+ NetExec, no CrackMapExec
> `NetExec` (`nxc`) es el fork mantenido de `CrackMapExec`, abandonado en 2023. Misma sintaxis, más protocolos (LDAP, MSSQL, WinRM, RDP, SSH, FTP) y bugs corregidos. Úsalo en su lugar siempre.

# Localizar el Domain Controller

El DC se delata por sus puertos: `88` (Kerberos), `389`/`636` (LDAP/LDAPS), `3268` (Global Catalog), `53` (DNS) y `445` (SMB). `nxc smb` marca el host como `(DC)` y muestra el dominio; un `nmap -p88,389,445,636,3268` lo confirma. <mark style="background: #FFB86CA6;">Apunta su IP: es el destino de casi todo lo que viene después.</mark>

# Identificar usuarios sin credenciales

Con una lista de nombres (de OSINT en [[01 - Reconocimiento y enumeración externa]], o diccionarios como `jsmith.txt`), `Kerbrute` valida qué usuarios existen abusando de la pre-autenticación Kerberos:

```shell-session
$ kerbrute userenum -d INLANEFREIGHT.LOCAL --dc 172.16.5.5 usernames.txt
```

<mark style="background: #FFB86CA6;">Kerbrute distingue "el usuario no existe" de "existe"</mark> por la respuesta del KDC a un `AS-REQ`, **sin** probar contraseñas. Es más sigiloso que un spraying: no genera eventos `4625` (fallo de logon), aunque sí deja `4768` con código de fallo en el DC.

> [!warning]+ Una palabra de cautela
> El escaneo activo (nmap agresivo, barridos amplios) es ruidoso y dispara IDS/IPS en entornos reales. Empieza pasivo, escala a activo solo lo justo, y olvida el "escanea todo el /16 con `-A`" del laboratorio.

# Marcar vulnerabilidades a la vista

Durante el barrido anota lo evidente: SO fuera de soporte (EternalBlue en Windows 7/2008), `SMBv1` habilitado, *SMB signing* no requerido (habilita *NTLM relay* → [[06 - Envenenamiento LLMNR y NBT-NS]]) o servicios anómalos. No hace falta explotar aún; es munición para las fases siguientes.
