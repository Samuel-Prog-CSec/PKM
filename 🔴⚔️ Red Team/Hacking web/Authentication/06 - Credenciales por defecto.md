---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[05 - Bypass de protecciones anti-fuerza-bruta]]"
Nota siguiente: "[[07 - Reset de contraseña vulnerable]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Antes de forzar nada, prueba lo obvio. <mark style="background: #ADCCFFA6;">Muchísimas aplicaciones y dispositivos se instalan con credenciales por defecto que nunca se cambian</mark>, dando acceso autenticado sin esfuerzo. OWASP lo lista como paso obligado del [Testing for Default Credentials](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/04-Authentication_Testing/02-Testing_for_Default_Credentials). Es *low-hanging fruit*, pero sigue siendo de los hallazgos más rentables, sobre todo en superficies internas y paneles olvidados.

# Dónde viven las credenciales por defecto

<mark style="background: #FFB8EBA6;">No es solo `admin:admin` en un router.</mark> En 2026 el problema se concentra en:

- **Paneles de administración** de CMS y frameworks (Tomcat `tomcat:tomcat`, Jenkins, Grafana `admin:admin`, BookStack `admin@admin.com:password`).
- **Dispositivos de red e IoT** — routers, cámaras, DVR, impresoras, ICS/SCADA.
- **Bases de datos y servicios** — `root` sin contraseña en MySQL/Mongo expuestos, `postgres:postgres`, Redis sin auth.
- **Infra y CI/CD** — consolas de Kubernetes, paneles de despliegue, entornos de staging clonados de producción.

# Cómo obtenerlas

| Recurso | Qué ofrece |
| - | - |
| [CIRT.net](https://www.cirt.net/passwords) | Base histórica de credenciales por defecto por fabricante |
| [SecLists Default-Credentials](https://github.com/danielmiessler/SecLists/tree/master/Passwords/Default-Credentials) | `default-passwords.txt` para fuzzing |
| [SCADAPASS](https://github.com/scadastrangelove/SCADAPASS) | Credenciales por defecto de equipos industriales |
| Búsqueda dirigida | `"<producto> default credentials"` → la doc de instalación suele revelarlas |

<mark style="background: #FFB86CA6;">Identifica primero el producto y versión</mark> (fingerprinting, banners, favicon hash) y busca **sus** credenciales concretas, en vez de tirar una lista genérica. Un favicon o un `Server:` header te dicen qué buscar en la doc oficial.

# Automatización

Probar credenciales por defecto a escala es trabajo de herramienta:

```shell-session
$ nuclei -u https://target -t http/default-logins/        # plantillas de login por defecto
$ changeme -t http://target                                # escáner dedicado a default creds
```

- <mark style="background: #FFB86CA6;">`nuclei`</mark> tiene una categoría entera de plantillas `default-logins` que prueban las credenciales conocidas de cada producto que detecta.
- `changeme` y `default-http-login-hunter` automatizan el mismo chequeo contra paneles HTTP.
- En bug bounty, **Shodan/Censys** localizan paneles expuestos a internet (`http.title:"Login"`, `product:"..."`) sobre los que probar el default.

> [!warning]+ El "cambiaron la contraseña pero no el usuario"
> Aunque cambien la contraseña por defecto, conservar el **usuario** por defecto (`admin`, `root`, `sa`) ya estrecha el ataque a la mitad: te ahorras la [[01 - Enumeración de usuarios|enumeración]] y atacas solo la contraseña. Reportar el usuario por defecto retenido es válido como debilidad de *defense-in-depth*.

> [!info]+ Fuentes
> - [OWASP WSTG — Testing for Default Credentials](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/04-Authentication_Testing/02-Testing_for_Default_Credentials)
> - [nuclei (ProjectDiscovery)](https://github.com/projectdiscovery/nuclei) · [changeme](https://github.com/ztgrace/changeme) · [SCADAPASS](https://github.com/scadastrangelove/SCADAPASS)
