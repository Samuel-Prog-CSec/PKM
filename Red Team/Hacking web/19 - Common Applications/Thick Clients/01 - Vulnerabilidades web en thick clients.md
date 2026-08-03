---
tags:
  - Web/Red-Team
  - Thick-Clients
  - Pentesting/Explotacion
Descripción: "Los thick clients de arquitectura three-tier (cliente ↔ servidor de aplicación ↔ BD) son susceptibles a vulnerabilidades web como SQL injection y path traversal"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Ataque a thick clients]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de ColdFusion]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Los thick clients de arquitectura **three-tier** (cliente ↔ servidor de aplicación ↔ BD) son susceptibles a vulnerabilidades web como **SQL injection** y **path traversal**. La jugada maestra: <mark style="background: #FFB86CA6;">el cliente es tuyo — se **decompila, modifica y recompila** para enviar peticiones arbitrarias, saltándose cualquier control client-side</mark>.

# Reconfigurar el cliente (y saltar la firma del JAR)

Escenario (basado en el box *Fatty* de HTB): un `fatty-client.jar` obtenido de un FTP anónimo. Se extrae el JAR y se edita el `beans.xml` (config de Spring) para corregir el puerto del servidor. Pero el JAR está **firmado** (hashes SHA-256 en `META-INF/MANIFEST.MF`):

```powershell
# 1) Editar beans.xml (constructor-arg value = "1337")
# 2) Eliminar los SHA-256-Digest de MANIFEST.MF y borrar META-INF/*.RSA y *.SF
# 3) Reempaquetar
C:\> jar -cmf .\META-INF\MANIFEST.MF ..\fatty-client-new.jar *
```

# Path traversal editando el cliente

El cliente filtra `/` en la entrada, pero el filtro está **en el cliente**. Se decompila con **JD-GUI**, se edita `ClientGuiTest.java` para enviar `..` en vez de la carpeta fija, se recompila (`javac`) y se rearma el JAR:

```java
ClientGuiTest.this.currentFolder = "..";
response = ClientGuiTest.this.invoker.showFiles("..");
```

<mark style="background: #8000E1A6;">Así se navega el filesystem del servidor y se descarga el `fatty-server.jar`</mark> (modificando la función `open()` del cliente para escribir la respuesta a disco).

# SQL injection bypassando el hash

Decompilando el server, el login concatena el `username` sin sanitizar:

```java
"SELECT id,username,email,password,role FROM users WHERE username='" + user.getUsername() + "'"
```

El *gotcha*: la contraseña se envía como `sha256(username+password+"clarabibimakeseverythingsecure")`, así que un `' or '1'='1` clásico falla en la comparación del hash. La solución es una **UNION** que fabrica un usuario falso con la contraseña **controlada** (y se modifica el cliente para enviar el password en claro):

```text
# username:
abc' UNION SELECT 1,'abc','a@b.com','abc','admin
# password: abc
```

La query devuelve un usuario `admin` con password `abc`; como el cliente envía `abc`, la comparación cuadra → <mark style="background: #FF5582A6;">login como `admin`</mark>.

> [!important]+ La lección transferible
> Todo control que viva en el cliente (validación de entrada, campos ocultos, filtros, restricciones de rol) es **bypassable** recompilando el binario. El servidor debe validar y sanitizar **todo**. Es la misma raíz que la [[00 - Introducción a SQL Injection|SQLi]] y el [[00 - Introducción a File Inclusion|path traversal]] web, solo que el "navegador" es un `.jar`/`.exe` que editas a tu gusto.

Volviendo a los *app servers*, un clásico lleno de CVEs: [[00 - Descubrimiento y enumeración de ColdFusion|ColdFusion]].
