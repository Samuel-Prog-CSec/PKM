---
tags:
  - Redes
  - Protocolos
  - Linux
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`SSH` (*Secure Shell*) es el protocolo criptográfico estándar para administrar sistemas en remoto sobre una red insegura</mark>. Sustituyó a `telnet` y a las [[R-services|r-services]] precisamente porque **cifra** toda la sesión. Escucha en **`TCP/22`** y su implementación dominante es **OpenSSH** (config en `/etc/ssh/sshd_config`).

# Qué ofrece

- **Shell** remota cifrada.
- **Transferencia de ficheros**: `scp` y `sftp`.
- **Túneles / port forwarding** (local, remoto y dinámico/SOCKS) — clave para [[02 - Local y dynamic port forwarding con SSH|pivoting]].

# El handshake (por qué importa al auditar)

1. Intercambio de versiones (`SSH-2.0-OpenSSH_8.9`).
2. **Key exchange** (Diffie-Hellman y derivados): negocian una clave de sesión.
3. **Host key**: el servidor prueba su identidad con su clave pública; el cliente la verifica (y la fija en `known_hosts`).
4. Negociación de **cifrados/MAC**.
5. **Autenticación** del usuario.

<mark style="background: #FF5582A6;">SSH-1 es inseguro y está obsoleto</mark>; hoy todo debe ser SSH-2. Los algoritmos débiles (KEX, host-key, ciphers) se auditan con `ssh-audit`.

# Métodos de autenticación

| Método | Descripción |
| --- | --- |
| `password` | Usuario + contraseña. Fuerza bruta posible. |
| `publickey` | Par de claves asimétricas; la privada nunca viaja. El más seguro. |
| `keyboard-interactive` | Challenge-response (a veces MFA). |
| `host-based` | Confianza entre hosts (poco común). |
| `GSSAPI` | Kerberos/AD. |

# Relevancia ofensiva

Un SSH es objetivo de fuerza bruta (si permite `password`), de reutilización de claves privadas filtradas (ver [[02 - Recursos cloud]]) y de auditoría de algoritmos débiles. La enumeración (`ssh-audit`, métodos de auth) se trata junto a Rsync y R-services en [[15 - Gestión remota Linux]].
