---
tags:
  - Redes
  - Protocolos
  - Linux
Descripción: "Rsync es una utilidad de copia y sincronización de ficheros rápida y versátil, muy usada para backups y espejos"
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`Rsync` es una utilidad de copia y **sincronización** de ficheros rápida y versátil</mark>, muy usada para backups y espejos. Transfiere solo las diferencias entre origen y destino (algoritmo *delta*), lo que la hace muy eficiente.

# Modos de funcionamiento

- **Sobre SSH** (lo habitual y seguro): `rsync -avz -e ssh ...`. Va cifrado por el túnel [[SSH]].
- **Daemon rsync** en **`TCP/873`**: rsync corriendo como servicio con **módulos** (directorios exportados) definidos en `/etc/rsyncd.conf`. Este modo es el interesante ofensivamente.

# Módulos y su (falta de) control de acceso

Un módulo es un directorio compartido con un nombre. La config puede exigir usuario/contraseña o **no exigir nada**:

```text
[backups]
    path = /srv/backups
    read only = false
    # sin 'auth users' → acceso anónimo
```

<mark style="background: #FF5582A6;">Un módulo sin autenticación permite listar y descargar (o subir) su contenido a cualquiera</mark> que llegue al 873.

# Relevancia ofensiva

El daemon rsync mal configurado filtra backups completos, config y credenciales, y si es escribible permite plantar ficheros (p. ej. una clave SSH en `authorized_keys`). La enumeración (`nmap`, listado de módulos) se trata en [[15 - Gestión remota Linux]].
