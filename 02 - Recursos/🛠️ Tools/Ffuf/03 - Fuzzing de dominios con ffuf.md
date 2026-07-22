---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-19
Nota previa: "[[02 - Fuzzing de directorios y archivos con ffuf]]"
Nota siguiente: "[[04 - Fuzzing de parámetros y valores con ffuf]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

`ffuf` fuzzea dominios de dos formas que **la gente confunde constantemente** y que encuentran cosas distintas: *subdomain fuzzing* (contra el DNS público) y *vhost fuzzing* (contra la cabecera `Host` de una IP conocida).

# Subdomain fuzzing: contra el DNS

Colocas `FUZZ` en el nombre de host; `ffuf` resuelve cada candidato:

```shell-session
$ ffuf -w subdomains.txt -u https://FUZZ.target.com -mc 200,301,302
```

<mark style="background: #ADCCFFA6;">Solo encuentra subdominios que **resuelven en DNS**</mark> — los registrados públicamente. Es fuerza bruta de DNS por HTTP; se complementa con la enumeración pasiva de [[05 - Enumeración de subdominios]] y [[06 - Fuerza bruta de subdominios]].

# Vhost fuzzing: contra la cabecera `Host`

Aquí `FUZZ` va en la cabecera `Host`, apuntando siempre a la **misma IP**:

```shell-session
$ ffuf -w subdomains.txt -u https://target.com -H "Host: FUZZ.target.com"
```

<mark style="background: #FFB86CA6;">Descubre *virtual hosts* servidos por esa IP que **no están en el DNS público**</mark> — entornos `dev`, `staging`, paneles internos que solo responden si pides el `Host` correcto. Es de las técnicas más rentables en bug bounty. Fundamento en [[08 - Virtual Hosts]] y método en [[20 - Fuzzing de vhosts y subdominios]].

# La diferencia, en una tabla

| | Subdomain fuzzing | Vhost fuzzing |
| --- | --- | --- |
| `FUZZ` en | El hostname (se resuelve) | La cabecera `Host` (IP fija) |
| Encuentra | Subdominios en **DNS público** | Vhosts **ocultos** en una IP |
| Requiere | Resolución DNS | Conocer la IP objetivo |

> [!warning]+ El *gotcha* nº1 del vhost fuzzing: filtrar el vhost por defecto
> Al variar el `Host`, el servidor responde su **página por defecto** (mismo tamaño) para todo lo que no coincida con un vhost real → la salida se llena de falsos `200`. **Hay que filtrar ese tamaño**: lanza una petición con un `Host` basura, anota su `Size`, y fíltralo:
> ```shell-session
> $ ffuf -w subs.txt -u https://target.com -H "Host: FUZZ.target.com" -fs 8452
> ```
> O deja que la **autocalibración** lo aprenda sola con `-ac` — ver [[05 - Matching y filtrado de resultados]].

Cambiando `FUZZ` de la ruta y el host a los parámetros, se ataca la lógica de la aplicación: [[04 - Fuzzing de parámetros y valores con ffuf]].
