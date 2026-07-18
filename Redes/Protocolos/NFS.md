---
tags:
  - Redes
  - Protocolos
  - Linux
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`NFS` (*Network File System*) es el sistema de ficheros en red de Sun Microsystems: acceder a un sistema de ficheros remoto como si fuera local</mark>. Cumple la misma función que [[📂🔗 SMB]] pero es el estándar del mundo **Unix/Linux** y usa un protocolo distinto — un cliente NFS no habla con un servidor SMB ni viceversa.

# Versiones (y su modelo de confianza)

| Versión | Características |
| --- | --- |
| `NFSv2` | Antigua, muy soportada; originalmente todo sobre **UDP**. |
| `NFSv3` | Más features (tamaño de fichero variable, mejor reporte de errores). <mark style="background: #FF5582A6;">Autentica el **equipo cliente**, no al usuario.</mark> |
| `NFSv4` | Como SMB, **el usuario debe autenticarse**. *Stateful*, un solo puerto (2049), *firewall-friendly*. |

<mark style="background: #FFB86CA6;">El talón de Aquiles clásico es NFSv3</mark>: confía en el `UID`/`GID` que dice el cliente. Si el servidor exporta con confianza en la identidad del cliente, cualquiera que controle su propia máquina puede presentarse con el UID que quiera.

# Puertos y dependencias RPC

NFS se apoya en **RPC** (Sun RPC), así que rara vez va solo:

- **`TCP/UDP 111`** — `portmapper`/`rpcbind`: el "directorio" que dice en qué puerto escucha cada servicio RPC.
- **`TCP/UDP 2049`** — `nfsd`, el servicio NFS.
- **`mountd`, `statd`, `lockd`** — servicios RPC auxiliares en puertos dinámicos (los resuelve el portmapper).

Enumerar el `111` con `rpcinfo` revela todo el mapa RPC del host.

# Exports y sus opciones peligrosas

Los recursos compartidos se definen en **`/etc/exports`**:

```text
/srv/share  10.0.0.0/24(rw,no_root_squash,no_subtree_check)
```

Las opciones son el origen de casi todo *finding*:

- **`root_squash`** (por defecto): mapea el `root` remoto a `nobody` — protege.
- **`no_root_squash`**: <mark style="background: #8000E1A6;">el `root` del cliente es `root` en el export</mark> → un atacante que monte puede crear un binario SUID root y escalar. Fallo grave.
- **`rw`** sin restringir la red, `insecure`, `all_squash` mal usado — todos amplían la superficie.

# Relevancia ofensiva

Un export mal configurado da lectura (o escritura) de ficheros de servidores Unix, y `no_root_squash` es una vía directa a **root**. La enumeración (`showmount`, `mount`) y la explotación (UID spoofing, abuso de `no_root_squash`) se tratan en [[06 - NFS|Footprinting de NFS]].
