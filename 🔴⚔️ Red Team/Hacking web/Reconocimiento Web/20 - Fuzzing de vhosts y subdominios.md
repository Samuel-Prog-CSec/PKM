---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Fuzzing
Fecha de actualización: 2026-06-02
Nota previa: "[[19 - Fuzzing de parámetros y valores]]"
Nota siguiente: "[[21 - Filtrado de la salida de fuzzing]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

La última posición que fuzzear es el propio **host**. Dos técnicas relacionadas pero distintas, ya introducidas en el bloque de recon: el fuzzing de `Virtual Hosts` (cabecera `Host`) y el de subdominios (resolución DNS).

# Vhost vs subdominio (recordatorio)

| Característica | Virtual Hosts | Subdominios |
| - | - | - |
| **Identificación** | Por la cabecera `Host` de la petición | Por registros DNS que apuntan a IPs |
| **Propósito** | Servir varios sitios en una sola IP | Organizar secciones/servicios de un dominio |
| **Riesgo** | Un vhost mal configurado <mark style="background: #FFB86CA6;">expone aplicaciones internas o datos sensibles</mark> | `subdomain takeover` por DNS mal gestionado |

La diferencia operativa clave —vhost fuzzing encuentra hosts que **no** están en DNS— se detalla en [[08 - Virtual Hosts]]; el descubrimiento de subdominios por DNS, en [[05 - Enumeración de subdominios]] y [[06 - Fuerza bruta de subdominios]]. Aquí vemos el ángulo de **fuzzing** con herramientas.

# VHost fuzzing con `gobuster`

`gobuster vhost` envía peticiones variando la cabecera `Host` contra la IP. Primero mapeas el nombre base en `/etc/hosts`:

```shell-session
$ echo "IP inlanefreight.htb" | sudo tee -a /etc/hosts
$ gobuster vhost -u http://inlanefreight.htb:81 \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt --append-domain

Found: admin.inlanefreight.htb:81 Status: 200 [Size: 100]
```

- `vhost`: activa el modo de descubrimiento de vhosts.
- `-u`: URL base del servidor (IP y puerto).
- `--append-domain`: añade el dominio base a cada palabra para construir el `Host` completo (`admin.inlanefreight.htb`). Imprescindible en versiones modernas.

<mark style="background: #ADCCFFA6;">Los vhosts con `200` son los válidos</mark>: `admin.inlanefreight.htb` respondió correctamente. `gobuster vhost` calcula la *baseline* por ti y solo reporta lo que difiere.

# VHost fuzzing con `ffuf` (y el problema de la baseline)

HTB usa `gobuster`, pero en la práctica `ffuf` es más habitual — y obliga a entender el problema central del vhost fuzzing. Se pone `FUZZ` en la cabecera `Host`:

```shell-session
$ ffuf -u http://IP:81/ -H "Host: FUZZ.inlanefreight.htb" \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

> [!warning]+ El servidor responde a TODO
> Aquí está el truco: el servidor devuelve su vhost **por defecto** ante cualquier `Host` desconocido, así que sin filtrar verás **todos** los nombres como `200` — miles de falsos positivos. <mark style="background: #FF5582A6;">Tienes que establecer la *baseline* (el tamaño/palabras de la respuesta por defecto) y filtrarla</mark>:
> ```shell-session
> $ ffuf -u http://IP:81/ -H "Host: FUZZ.inlanefreight.htb" -w subs.txt -fs 100
> ```
> `-fs 100` descarta toda respuesta de 100 bytes (la del vhost por defecto), dejando solo los vhosts reales. Esta lógica de *match/filter* es la columna del [[21 - Filtrado de la salida de fuzzing]].

# Subdomain fuzzing con `gobuster dns`

A diferencia del vhost, el modo `dns` **resuelve** cada candidato por DNS: solo aparecen los subdominios con registro real.

```shell-session
$ gobuster dns -d inlanefreight.com \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt

Found: www.inlanefreight.com
Found: blog.inlanefreight.com
```

- `dns`: modo de enumeración de subdominios.
- `-d`: dominio objetivo.
- Cada línea `Found:` es un subdominio que resuelve.

> [!warning]+ Gotcha de versión: `-d` cambió de significado
> En las últimas versiones de `gobuster`, `-d` define el **retardo** entre peticiones, no el dominio. Para el dominio usa `--do` / `--domain`. Un fallo silencioso aquí hace que el escaneo no enumere nada — comprueba tu versión con `gobuster version`.

Vhost (cabecera `Host`, no resuelve DNS) frente a subdominio (resuelve DNS): usa **ambos** contra un objetivo, porque encuentran cosas distintas.

Todas las técnicas vistas generan ruido. La habilidad que separa un fuzzing útil de una lista inservible es **filtrar la salida**: [[21 - Filtrado de la salida de fuzzing]].
