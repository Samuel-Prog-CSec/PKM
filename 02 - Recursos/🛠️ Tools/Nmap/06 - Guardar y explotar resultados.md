---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Guardar cada escaneo no es opcional en un engagement: sirve para comparar técnicas, alimentar otras herramientas y, sobre todo, aportar evidencia en el informe"
Fecha de actualización: 2026-07-18
Nota previa: "[[05 - Rendimiento y timing]]"
Nota siguiente: "[[07 - Evasión de firewalls, IDS e IPS]]"
Area: "[[Nmap.base|Nmap]]"
---
---

<mark style="background: #FF5582A6;">Guardar cada escaneo no es opcional en un engagement</mark>: sirve para comparar técnicas, alimentar otras herramientas y, sobre todo, aportar **evidencia** en el informe. Un hallazgo sin el output que lo respalda no existe de cara al cliente. Nmap escribe en tres formatos, cada uno con su propósito.

# Los tres formatos

| Flag | Extensión | Para qué |
| --- | --- | --- |
| `-oN` | `.nmap` | *Normal*: legible por humanos, igual que la salida en pantalla. |
| `-oG` | `.gnmap` | *Greppable*: una línea por host, ideal para `grep`/`awk`. |
| `-oX` | `.xml` | *XML*: formato máquina, el que consumen otras herramientas. |
| `-oA` | los tres | Guarda en todos a la vez con un prefijo común. |

```shell-session
$ sudo nmap 10.129.2.28 -p- -oA target
$ ls
target.gnmap  target.nmap  target.xml
```

Sin ruta completa, los ficheros caen en el directorio actual. <mark style="background: #ADCCFFA6;">En la práctica se usa siempre `-oA`</mark>: cuesta lo mismo y te deja los tres para lo que surja.

## Greppable: extracción rápida

El formato `.gnmap` pone puertos y estados en una línea, perfecto para *scripting*:

```shell-session
$ cat target.gnmap
Host: 10.129.2.28 () Status: Up
Host: 10.129.2.28 () Ports: 22/open/tcp//ssh///, 25/open/tcp//smtp///, 80/open/tcp//http/// Ignored State: closed (4)
```

Es *legacy* (Nmap ya no lo evoluciona) pero sigue siendo cómodo para sacar, por ejemplo, la lista de IPs con el 445 abierto y encadenarla al siguiente ataque. Para procesamiento serio, el XML es el formato correcto.

## XML → informe HTML

El `.xml` estructura todo el escaneo (host, estado, puerto, servicio, razón). Con `xsltproc` se convierte en un **informe HTML** limpio, presentable incluso a gente no técnica:

```shell-session
$ xsltproc target.xml -o target.html
```

> [!success]+ El HTML es material directo para el informe
> Abrir `target.html` en el navegador da una vista clara y estructurada de los resultados. <mark style="background: #FFB86CA6;">Es un artefacto listo para adjuntar a la documentación</mark> del pentest sin trabajo extra — enlaza con la fase de [[Documentación y reporting]].

# Explotar la salida en el pipeline

El valor real está en **encadenar** el resultado hacia el siguiente paso:

```shell-session
# Sacar solo IPs vivas para un segundo escaneo dirigido
$ sudo nmap 10.129.2.0/24 -sn -oG - | awk '/Up$/{print $2}' > live.txt
$ sudo nmap -iL live.txt -sCV -oA enum

# Extraer puertos abiertos de un host y re-escanear solo esos con scripts
$ ports=$(grep -oP '\d{1,5}(?=/open)' target.gnmap | paste -sd,)
$ sudo nmap 10.129.2.28 -p$ports -sCV -oA target_deep
```

# Enfoque profesional 2026

- **Importar a otras herramientas**: el XML se carga en `Metasploit` con `db_import target.xml` (puebla la base de `hosts`/`services` para el resto del engagement — ver [[Metasploit.base|Metasploit]]), y lo consumen Faraday, DefectDojo o dashboards propios.
- **Parsers dedicados**: `nmap-parse-output` (XML → CSV/lista de puertos/HTML moderno), `nmaptocsv`, o un `xmlstarlet` rápido baten al `grep` sobre `.gnmap` cuando hay muchos hosts. Ver [[09 - Arsenal de herramientas de escaneo]].
- **Reanudar**: `--resume target.gnmap` continúa un escaneo interrumpido; `--append-output` no pisa ficheros previos.
- **Higiene de evidencia**: nombra los ficheros por objetivo/fase (`enum_dmz_tcp`, `enum_dmz_udp`) y consérvalos — son la trazabilidad del test y la base del [[Documentación y reporting|informe]].

Referencia de formatos: [nmap.org/book/output.html](https://nmap.org/book/output.html).
