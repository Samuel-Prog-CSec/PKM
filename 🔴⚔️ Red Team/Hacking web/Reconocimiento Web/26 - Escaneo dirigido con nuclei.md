---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Fecha de actualización: 2026-06-13
Nota previa: "[[25 - Cloud asset recon]]"
Nota siguiente: "[[27 - Evasión en recon y fuzzing]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El recon y el fuzzing producen una lista de hosts y endpoints vivos; el siguiente paso es comprobar, a escala, cuáles tienen vulnerabilidades **conocidas**. <mark style="background: #ADCCFFA6;">`nuclei` (ProjectDiscovery) es un escáner basado en plantillas `YAML` que envía peticiones definidas en *templates* y reporta coincidencias</mark>. Su valor no está en la herramienta sino en su biblioteca comunitaria —miles de templates de CVEs, exposiciones y *misconfigurations*— que la convierten en el estándar de detección dirigida en bug bounty actual. La [[14 - Automatización del recon|nota de automatización]] lo nombra dentro del pipeline; aquí lo desarrollamos.

# Uso esencial

```shell-session
$ nuclei -u https://target.htb
$ nuclei -l hosts_vivos.txt -severity critical,high
```

Las plantillas se seleccionan por carpeta, por etiqueta o por severidad —escanear con **todo** es ruidoso e ineficaz; lo útil es dirigir:

| Selector | Ejemplo | Para qué |
| - | - | - |
| Por tags | `-tags cve,rce,exposure` | Clases de bug concretas |
| Por carpeta | `-t http/cves/ -t http/exposures/` | CVEs, ficheros expuestos |
| Por severidad | `-severity critical,high` | Filtrar ruido informativo |
| Escaneo auto | `-as` (`-automatic-scan`) | Fingerprint de tecnología → solo templates relevantes |

<mark style="background: #FFB8EBA6;">`exposures/` es de las categorías más rentables</mark>: detecta `.git`/`.env` expuestos, paneles de admin, claves filtradas y backups —el mismo terreno que el [[17 - Fuzzing de directorios y archivos|content discovery]], pero con verificación automatizada—.

# El pipeline: del dominio al hallazgo

La fuerza real aparece encadenando `nuclei` al final del flujo de [[14 - Automatización del recon|recon automatizado]], alimentándolo solo con hosts vivos para no malgastar peticiones:

```shell-session
$ subfinder -d target.htb -silent | dnsx -silent | httpx -silent | nuclei -tags cve,exposure -severity high,critical
```

<mark style="background: #8000E1A6;">`httpx` filtra a los que responden HTTP antes de que `nuclei` gaste un solo template en hosts muertos</mark>. Mantén las plantillas al día con `nuclei -update-templates` (la comunidad publica templates de CVEs nuevas a las pocas horas de salir — ahí está la ventaja en bug bounty).

# Templates propios: de un hallazgo a toda la superficie

Un template es `YAML` con la petición y los *matchers* que confirman la vulnerabilidad. Escribir el tuyo es lo que diferencia a un usuario de `nuclei` de quien lo exprime:

```yaml
id: panel-interno-expuesto
info:
  name: Panel interno expuesto
  severity: medium
http:
  - method: GET
    path:
      - "{{BaseURL}}/internal/admin"
    matchers:
      - type: word
        words:
          - "Internal Dashboard"
```

> [!important]+ Variant analysis: escalar un bug único a un programa entero
> El caso de mayor ROI: encuentras **un** bug a mano (un endpoint vulnerable, una cabecera reveladora, un parámetro inyectable) y escribes un template que lo detecta. Lo lanzas contra **todos** los hosts del programa —y a menudo contra otros programas— y <mark style="background: #FF5582A6;">conviertes un hallazgo puntual en una serie</mark>. Es la forma sistematizada de rentabilizar cada descubrimiento manual.

# Buenas prácticas y límites

> [!warning]+ Ruido, falsos positivos y WAF
> `nuclei` es **ruidoso por diseño**: lanza muchas peticiones con un `User-Agent` reconocible que los WAF detectan y los SOC registran. Tres consecuencias prácticas:
> - Controla el ritmo (`-rl` *rate limit*, `-c` concurrencia) para no ganarte un baneo — ver [[27 - Evasión en recon y fuzzing|la nota de evasión]].
> - <mark style="background: #FFB86CA6;">Verifica siempre a mano</mark> antes de reportar: genera falsos positivos, sobre todo en *matchers* laxos. La [[22 - Validación de hallazgos|validación de hallazgos]] no es opcional.
> - Un escaneo masivo con `nuclei` no es sigiloso; si el engagement exige discreción, dirige plantillas concretas en vez de barrer.

> [!info]+ Fuentes
> - [nuclei](https://github.com/projectdiscovery/nuclei) · [nuclei-templates](https://github.com/projectdiscovery/nuclei-templates) (la biblioteca comunitaria)
> - [Guía de templates](https://docs.projectdiscovery.io/templates/introduction) · `pdtm` para instalar el stack de ProjectDiscovery.

Escanear a escala dispara defensas. Cómo recon y fuzzing esquivan WAFs, rate-limits y baneos es el cierre del sub-tema: [[27 - Evasión en recon y fuzzing]].
