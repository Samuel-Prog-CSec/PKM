---
tags:
  - Web/Red-Team
  - Tomcat
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "Apache Tomcat es un servidor web open-source que aloja aplicaciones Java (Servlets y JSP), usado por frameworks como Spring"
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a Drupal]]"
Nota siguiente: "[[01 - Ataques a Tomcat]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Apache Tomcat es un servidor web open-source que aloja aplicaciones Java</mark> (Servlets y JSP), usado por frameworks como Spring. <mark style="background: #FFB8EBA6;">Aparece más en pentest interno que externo</mark>, y suele encabezar los "High Value Targets" de un EyeWitness — casi siempre hay al menos una instancia con credenciales débiles o por defecto, un `foothold` excelente hacia la red interna.

# Fingerprinting

```shell-session
# La cabecera Server o una página inválida (tras reverse proxy) filtra la versión
$ curl -sI http://app-dev.inlanefreight.local:8080/invalid | grep -i server

# La página /docs por defecto (rara vez eliminada) revela la versión
$ curl -s http://app-dev.inlanefreight.local:8080/docs/ | grep -i tomcat
<title>Apache Tomcat 9 (9.0.30) - Documentation Index</title>
```

# Ficheros clave

La estructura de Tomcat esconde dos ficheros críticos en `conf/`:

- **`web.xml`** (*deployment descriptor*): mapea rutas → clases (`<servlet-mapping>`). <mark style="background: #FF5582A6;">Objetivo prioritario ante un LFI</mark> — revela servlets, clases y lógica sensible (`WEB-INF/classes/...`).
- **`tomcat-users.xml`**: credenciales y roles del manager.

```xml
<role rolename="manager-gui" />
<user username="tomcat" password="tomcat" roles="manager-gui" />
<user username="admin" password="admin" roles="manager-gui,admin-gui" />
```

Los roles del manager: `manager-gui` (GUI HTML), `manager-script` (API HTTP), `manager-jmx`, `manager-status`.

# Enumeración: el manager

El objetivo es `/manager` y `/host-manager`. Se localizan con fuzzing o directamente:

```shell-session
$ gobuster dir -u http://web01.inlanefreight.local:8180/ -w /usr/share/dirbuster/wordlists/directory-list-2.3-small.txt
/manager (Status: 302)
/host-manager (Status: 302)
```

<mark style="background: #FFB86CA6;">Con acceso al manager (por credenciales débiles o brute force) se sube un `.war` con una JSP web shell → RCE</mark> sobre el host. Detalle en [[01 - Ataques a Tomcat]].

> [!info]+ Versión → CVE (modernización)
> Más allá de las default creds, fijar la versión abre CVEs potentes: <mark style="background: #FFB86CA6;">**Ghostcat (CVE-2020-1938)**</mark> — el conector **AJP (puerto 8009)** permite leer/incluir ficheros de la webapp (`WEB-INF/web.xml`) y, con upload, RCE; y **CVE-2017-12617** (RCE por `PUT` de un `.jsp` con `readonly=false`). En 2026: `nuclei -tags tomcat`, el módulo `auxiliary/scanner/http/tomcat_mgr_login` de Metasploit para el brute, y `ajpy`/nuclei para Ghostcat. Un `8009/tcp open ajp13` en el [[01 - Descubrimiento y enumeración de aplicaciones|escaneo]] es señal directa de Ghostcat.

Con el manager y la versión mapeados, pasamos a la explotación: [[01 - Ataques a Tomcat]]. El `web.xml` conecta con [[00 - Introducción a File Inclusion|File Inclusion]], y el conector CGI con la nota de [[00 - Ataque a Tomcat CGI|Attacking Tomcat CGI]].
