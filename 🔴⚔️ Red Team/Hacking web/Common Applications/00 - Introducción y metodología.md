---
tags:
  - Web/Red-Team
  - Introduccion
  - Common-Applications
Fecha de actualización: 2026-07-16
Nota previa: ""
Nota siguiente: "[[01 - Descubrimiento y enumeración de aplicaciones]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Las aplicaciones comunes —CMS, servlet containers, herramientas de monitorización, ticketing, repositorios de código— son de los *footholds* más rentables en un pentest</mark>, tanto interno como externo. A menudo son "la vía de entrada" a un entorno por lo demás bien mantenido: una versión desactualizada, unas credenciales por defecto o una funcionalidad abusable bastan para pasar de "no tengo nada" a ejecución de comandos.

# La metodología (el hilo del módulo)

Toda aplicación se aborda con el mismo esquema, y por eso las notas de cada app siguen la misma estructura:

1. **Descubrir y enumerar** — identificar la aplicación y, sobre todo, su **versión** (fingerprinting). Ver [[01 - Descubrimiento y enumeración de aplicaciones]].
2. **Explotar**, por dos vías complementarias:
   - **Vulnerabilidades públicas conocidas** de esa versión (SQLi, XSS, RCE, LFI, unrestricted file upload) → buscar el CVE/exploit.
   - <mark style="background: #FFB86CA6;">**Abuso de funcionalidad legítima** para lograr RCE</mark> — subir un plugin/tema, usar una *script console*, crear una tarea programada, cargar un `.war`. Es la habilidad más **durable**: funciona incluso en aplicaciones que no has visto nunca, cuando no hay CVE a mano.

# Las aplicaciones que cubrimos

| Categoría | Aplicaciones |
| - | - |
| CMS | WordPress, Joomla, Drupal |
| Servlet / Dev | Tomcat, Jenkins |
| Monitorización / SIEM | Splunk, PRTG |
| Ticketing / Repos | osTicket, GitLab |
| Otras | ColdFusion, CGI/Shellshock, thick clients, LDAP, IIS |

> [!info]+ Por qué sigue vigente en 2026
> Lejos de ser "apps viejas", estas siguen siendo objetivos de primera en bug bounty y red team: <mark style="background: #FFB8EBA6;">WordPress mueve ~40% de la web, Jenkins/GitLab son el corazón del CI/CD, y Splunk custodia datos sensibles</mark>. Credenciales por defecto, versiones sin parchear y abuso de funcionalidad son hallazgos constantes. La diferencia hoy: más despliegues en cloud/contenedores, y el foco creciente en la **cadena de suministro** (comprometer un Jenkins/GitLab es pivotar a toda la organización).

> [!info]+ Setup del lab
> Los ejercicios usan *vhosts* (`app.inlanefreight.local`, `dev...`, `blog...`) sobre una misma IP. Hay que añadirlos al `/etc/hosts` local tras spawnear el target:
> ```shell-session
> $ IP=10.129.42.195
> $ printf "%s\t%s\n" "$IP" "app.inlanefreight.local dev.inlanefreight.local blog.inlanefreight.local" | sudo tee -a /etc/hosts
> ```

El primer paso, común a todas las apps, es descubrirlas y enumerarlas: [[01 - Descubrimiento y enumeración de aplicaciones]].
