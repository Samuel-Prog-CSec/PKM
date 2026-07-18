---
tags:
  - Redes
  - Protocolos
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`SMTP` (*Simple Mail Transfer Protocol*) es el protocolo para **enviar** correo en una red IP</mark>. Funciona entre un cliente y su servidor de salida, y entre dos servidores SMTP (donde uno actúa de cliente). Solo envía; la **recuperación** del correo la hacen [[IMAP-POP3|IMAP o POP3]].

# Puertos

| Puerto | Uso |
| --- | --- |
| `TCP 25` | SMTP clásico (servidor↔servidor). A menudo bloqueado en salida por los ISP (anti-spam). |
| `TCP 587` | *Submission*: correo de usuarios **autenticados**, normalmente con `STARTTLS` para cifrar. |
| `TCP 465` | SMTPS (SMTP sobre TLS directo). |

<mark style="background: #FFB8EBA6;">`STARTTLS` convierte una conexión en texto plano en cifrada</mark> tras el saludo inicial; sin él, las credenciales y el correo viajan en claro.

# Comandos del protocolo

Se dialoga en texto plano (por eso se puede hablar con `telnet`/`nc`):

| Comando | Función |
| --- | --- |
| `HELO` / `EHLO` | Saludo del cliente (`EHLO` = versión extendida, lista capacidades). |
| `MAIL FROM:` | Remitente del sobre. |
| `RCPT TO:` | Destinatario del sobre. |
| `DATA` | Inicia el cuerpo del mensaje (termina con `.` en línea sola). |
| `VRFY` | Verifica si existe un usuario/buzón. |
| `EXPN` | Expande una lista de distribución a sus miembros. |
| `RSET` / `NOOP` / `QUIT` | Reinicia / no-op / cierra. |

# El concepto de *relay*

Un servidor SMTP acepta correo y lo **reenvía** hacia su destino. Un servidor bien configurado solo repite correo de sus propios dominios/usuarios autenticados. <mark style="background: #FF5582A6;">Un **open relay** repite correo de cualquiera hacia cualquiera</mark> — se abusa para spam y phishing suplantando dominios ajenos.

# Relevancia ofensiva

En texto plano y con comandos como `VRFY`/`EXPN`/`RCPT TO`, SMTP filtra **usuarios válidos** del sistema, y un *open relay* permite enviar correo suplantando la organización. La enumeración e interacción (banner, user enum, test de relay) se trata en [[08 - SMTP|Footprinting de SMTP]].
