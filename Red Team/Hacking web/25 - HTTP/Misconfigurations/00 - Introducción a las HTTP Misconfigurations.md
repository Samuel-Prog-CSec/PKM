---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP
  - Tipo/Introduccion
Descripción: "Este módulo no ataca la aplicación en aislamiento, sino su despliegue real: los sistemas que la rodean —cachés web, proxies inversos, balanceadores— y las peculiaridades del…"
Fecha de actualización: 2026-07-14
Nota previa: ""
Nota siguiente: "[[01 - Introducción a Web Cache Poisoning]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Este módulo no ataca la aplicación en aislamiento, sino su **despliegue real**: los sistemas que la rodean —**cachés web**, **proxies inversos**, **balanceadores**— y las peculiaridades del propio protocolo [[HTTP]]. <mark style="background: #ADCCFFA6;">Mirar la web holísticamente, con toda su infraestructura, expone una superficie de ataque que no existe cuando analizas el código en solitario</mark>. Son bugs de configuración e interpretación, no de lógica de negocio, y por eso escapan al escáner y aparecen tarde en un pentest.

Cubre tres ataques muy presentes en aplicaciones modernas, cada uno con su ciclo de **detección → explotación → prevención**.

# Web Cache Poisoning

Las webs con mucho tráfico usan **cachés** que se sitúan entre el cliente y el servidor: guardan una copia local de un recurso y la sirven en peticiones posteriores, aliviando la carga del backend. El [[01 - Introducción a Web Cache Poisoning|Web Cache Poisoning]] explota misconfiguraciones de esa caché combinadas con otra vulnerabilidad de la app para **envenenar la copia cacheada y servir contenido malicioso a todos los usuarios** que pidan ese recurso. <mark style="background: #FFB86CA6;">A menudo basta con que la víctima **visite** la página para ser comprometida</mark>, y convierte vulnerabilidades que serían inofensivas (un XSS no explotable directamente) en armas de alcance masivo.

# Host Header Attacks

La cabecera **`Host`** es obligatoria desde HTTP/1.1: indica a qué dominio va la petición, imprescindible cuando un mismo servidor aloja varios dominios (*virtual hosting*). El problema surge cuando la aplicación <mark style="background: #FFB8EBA6;">usa el valor del `Host` para tomar decisiones de seguridad</mark> — comprobaciones de autorización o construcción de URLs absolutas. Manipulando el `Host`, un atacante puede saltarse controles ([[07 - Bypass de autenticación por Host Header|auth bypass]]) o forzar la generación de enlaces envenenados ([[08 - Password Reset Poisoning|password reset poisoning]]). Los [[06 - Introducción a los Host Header Attacks|Host Header Attacks]] son un caso de libro de "no confíes en input controlable por el cliente".

# Session Puzzling

Como HTTP es **stateless**, las aplicaciones usan **variables de sesión** para dar contexto entre peticiones (sobre todo para autenticación sin reenviar credenciales cada vez). El [[12 - Introducción a Session Puzzling|Session Puzzling]] surge del **manejo incorrecto de esas variables de sesión** y desemboca en <mark style="background: #FFB86CA6;">bypass de autenticación o account takeover</mark>. Sus causas típicas: reutilizar la misma variable de sesión en procesos distintos, **poblarla prematuramente** antes de completar la autenticación, o valores por defecto inseguros.

> [!info] Por qué importan en bug bounty
> Estos tres vectores son terreno de **PortSwigger Research** (James Kettle popularizó el cache poisoning práctico y los host header attacks). Son bugs de infraestructura que muchos programas de bug bounty valoran alto porque afectan a **muchos usuarios a la vez** y suelen pasar desapercibidos a las herramientas automáticas. Requieren entender el flujo completo: front-end, caché, back-end.

# Hoja de ruta

| Bloque | Notas | Idea central |
| - | - | - |
| **Web Cache Poisoning** | [[01 - Introducción a Web Cache Poisoning\|01]]–[[05 - Detección, herramientas y prevención de Cache Poisoning\|05]] | Envenenar la copia cacheada vía entradas *unkeyed* |
| **Host Header Attacks** | [[06 - Introducción a los Host Header Attacks\|06]]–[[11 - Detección, herramientas y prevención de Host Header Attacks\|11]] | Abusar de la confianza en la cabecera `Host` |
| **Session Puzzling** | [[12 - Introducción a Session Puzzling\|12]]–[[17 - Detección, herramientas y prevención de Session Puzzling\|17]] | Corromper variables de sesión mal gestionadas |

Cada bloque cierra con una nota de **detección, herramientas y prevención**, el enfoque operativo que necesitas para llevarlo a un engagement real. El prerrequisito conceptual —estructura de peticiones, cabeceras, cachés, statelessness— vive en [[HTTP]].

## Referencias

- [PortSwigger — Web cache poisoning](https://portswigger.net/web-security/web-cache-poisoning)
- [PortSwigger — HTTP Host header attacks](https://portswigger.net/web-security/host-header)
- HTB Academy — *Abusing HTTP Misconfigurations* (módulo base de estas notas)
