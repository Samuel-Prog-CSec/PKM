---
tags:
  - Redes
  - Protocolos
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

`IMAP` y `POP3` son los protocolos para **recuperar** correo de un servidor (frente a [[SMTP]], que lo envía). Difieren en filosofía:

- <mark style="background: #ADCCFFA6;">**IMAP** (*Internet Message Access Protocol*) gestiona el correo **online, en el servidor**</mark>: carpetas jerárquicas, sincronización entre varios clientes, preselección de mensajes. El correo vive en el servidor; el cliente es una vista.
- <mark style="background: #ADCCFFA6;">**POP3** (*Post Office Protocol v3*) solo **lista, descarga y borra**</mark>. Típicamente baja el correo al cliente y lo elimina del servidor. Simple y sin carpetas.

# Puertos

| Protocolo | Texto plano | Sobre TLS |
| --- | --- | --- |
| IMAP | `TCP 143` | `TCP 993` (IMAPS) |
| POP3 | `TCP 110` | `TCP 995` (POP3S) |

<mark style="background: #FF5582A6;">En los puertos en claro (143/110) las credenciales y el correo viajan sin cifrar</mark> — sniffables en la red local. Los servidores serios fuerzan TLS (993/995) o `STARTTLS`.

# Comandos

**POP3** (mínimo y secuencial):

| Comando | Función |
| --- | --- |
| `USER` / `PASS` | Autenticación (usuario / contraseña). |
| `STAT` / `LIST` | Nº de mensajes / listado. |
| `RETR n` | Descarga el mensaje `n`. |
| `DELE n` / `QUIT` | Marca borrado / cierra. |

**IMAP** (con etiqueta de comando y estado en servidor):

| Comando | Función |
| --- | --- |
| `a LOGIN user pass` | Autenticación. |
| `a LIST "" *` | Lista carpetas. |
| `a SELECT INBOX` | Selecciona un buzón. |
| `a FETCH n body[]` | Recupera un mensaje. |

# Relevancia ofensiva

El correo es un tesoro: <mark style="background: #8000E1A6;">contiene credenciales, información interna y contexto para pivotar</mark>. Sin TLS, las credenciales se capturan pasivamente; con credenciales válidas, se lee todo el buzón. La interacción, el uso de `openssl`/`curl` y la fuerza bruta se tratan en [[09 - IMAP-POP3|Footprinting de IMAP/POP3]].
