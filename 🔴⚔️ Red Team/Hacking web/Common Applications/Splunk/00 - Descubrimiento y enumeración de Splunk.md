---
tags:
  - Web/Red-Team
  - Splunk
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a Jenkins]]"
Nota siguiente: "[[01 - Ataques a Splunk]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Splunk es una herramienta de analítica de logs usada como SIEM</mark>. Custodia datos sensibles (logs, credenciales, telemetría) y <mark style="background: #FFB86CA6;">suele correr como `root` (Linux) o `SYSTEM` (Windows)</mark>, así que un RCE en Splunk es un `foothold` privilegiado. Es habitual en interno, raro en externo. El foco no son sus CVEs —históricamente pocas— sino la **autenticación débil o nula** y el abuso de funcionalidad.

# Fingerprinting

```shell-session
$ sudo nmap -sV 10.129.201.50
8000/tcp  open  ssl/http  Splunkd httpd            # interfaz web
8089/tcp  open  ssl/http  Splunkd httpd            # puerto de gestión / REST API
```

`8000` (web) + `8089` (gestión) es la firma de Splunk. En versiones antiguas las **credenciales por defecto `admin:changeme`** aparecen incluso en la propia página de login; en versiones nuevas se fijan al instalar (probar `admin`, `Welcome1`, `Password123`…).

# El agujero clásico: Splunk Free

> [!important]+ La trial que se convierte en barra libre
> <mark style="background: #FF5582A6;">Splunk Enterprise trial se convierte automáticamente en la versión **Free** tras 60 días, y la Free **no requiere autenticación**</mark>. Un admin que probó Splunk y lo olvidó deja una instancia sin login accesible a cualquiera. Encontrar un Splunk "olvidado" en el informe de [[01 - Descubrimiento y enumeración de aplicaciones|Aquatone/EyeWitness]] es una vía de entrada directa.

# El vector de RCE: scripted inputs

Con acceso admin (o a un Splunk Free), Splunk ejecuta código de varias formas; la más directa son los **scripted inputs**, pensados para integrar Splunk con fuentes de datos ejecutando scripts (su STDOUT alimenta Splunk). <mark style="background: #8000E1A6;">Como Splunk trae Python instalado en todas las plataformas, un scripted input con un reverse shell en Python da RCE inmediato</mark> — detalle en [[01 - Ataques a Splunk]].

> [!info]+ Modernización: Splunk sí ha tenido RCEs recientes
> HTB afirma que Splunk "apenas sufre vulnerabilidades", pero eso ya no es cierto: <mark style="background: #FFB86CA6;">**CVE-2023-46214** (RCE por subida de XSLT inseguro) y **CVE-2022-43571** (RCE)</mark> son ejemplos recientes. Aun así, el vector **más durable** sigue siendo el abuso de funcionalidad (scripted inputs / apps custom), que funciona con independencia de la versión. Herramientas: [`reverse_shell_splunk`](https://github.com/0xjpuff/reverse_shell_splunk), los módulos de Splunk en Metasploit, y `nuclei -tags splunk`.
