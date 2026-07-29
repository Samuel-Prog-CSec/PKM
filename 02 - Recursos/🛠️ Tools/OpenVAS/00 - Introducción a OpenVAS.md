---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo/Vulnerabilidades
  - Tipo/Introduccion
Descripción: "OpenVAS (de Greenbone AG, antes Greenbone Networks) es el escáner de vulnerabilidades open-source de referencia, la alternativa gratuita a Nessus"
Fecha de actualización: 2026-07-18
Nota previa:
Nota siguiente: "[[01 - Escaneo y exportación]]"
Area: "[[OpenVAS.base|OpenVAS]]"
---
---

<mark style="background: #ADCCFFA6;">`OpenVAS` (de Greenbone AG, antes Greenbone Networks) es el escáner de vulnerabilidades **open-source** de referencia</mark>, la alternativa gratuita a [[00 - Introducción a Nessus|Nessus]]. Es una parte del **Greenbone Vulnerability Manager** (`GVM`), también libre, y soporta escaneo **autenticado y no autenticado**.

# Instalación

En una distro de seguridad (Kali/Parrot) se instala vía paquete y se auto-configura:

```shell-session
$ sudo apt install gvm
$ sudo gvm-setup       # descarga feeds de NVTs/SCAP/CERT y genera la contraseña de admin
$ sudo gvm-start
```

> [!warning]+ Instalación moderna
> `gvm-setup` descarga los *feeds* (los ~150k tests de vulnerabilidad, `NVTs`), lo que tarda un buen rato la primera vez. <mark style="background: #FF5582A6;">Greenbone recomienda hoy la **Community Edition en contenedores Docker**</mark> como método soportado; el paquete `gvm` de Kali sigue siendo el más rápido para aprender. Sin *feeds* actualizados (`sudo greenbone-feed-sync`), los resultados envejecen igual que en cualquier escáner.

# Acceso

La interfaz web es el **Greenbone Security Assistant** (`GSA`), en:

```text
https://localhost:9392
```

Se entra con el usuario `admin` y la contraseña que generó `gvm-setup`. Desde ahí se gestionan objetivos, tareas de escaneo y resultados. El flujo de escaneo y exportación está en [[01 - Escaneo y exportación]].
