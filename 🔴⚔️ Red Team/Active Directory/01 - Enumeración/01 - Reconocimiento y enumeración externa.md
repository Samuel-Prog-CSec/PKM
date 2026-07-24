---
tags:
  - Active-Directory
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[00 - Introducción a la enumeración y ataques en AD]]"
Nota siguiente: "[[02 - Enumeración inicial del dominio]]"
Area: "[[AD Enumeración.base|Enumeración]]"
---
---

En una evaluación *assumed breach* el reconocimiento externo no busca el acceso inicial (ya lo damos por hecho), pero sigue aportando: <mark style="background: #ADCCFFA6;">el recon externo mapea la huella pública de la organización</mark> y produce insumos que alimentan directamente las fases internas —formatos de usuario para el *password spraying*, credenciales filtradas para reutilizar y servicios expuestos (VPN, OWA, RDWeb) que explican por dónde entró el atacante que simulamos—.

Buena parte de estas técnicas ya está desarrollada en el módulo de footprinting; aquí las miramos con la lente concreta de "qué de esto me sirve para atacar el dominio".

> [!info]+ No duplicar: ver footprinting
> El recon de dominio, personal y cloud está detallado en [[00 - Principios y metodología de enumeración]], [[01 - Reconocimiento de dominio]], [[03 - Enumeración de personal]] y [[02 - Recursos cloud]]. Esta nota resume, enlaza y añade el enfoque AD.

# Qué buscamos

| Dato | Ejemplos | Por qué importa en AD |
| --- | --- | --- |
| Espacio de direcciones | ASN, *netblocks*, rangos cloud | Delimita el objetivo; localiza portales expuestos. |
| Info DNS | dominios, subdominios, MX/TXT | Revela el nombre AD, VPN, correo (OWA), servidores. |
| Esquema de nombres | formato de email/usuario (`j.doe`, `jdoe`) | <mark style="background: #FFB86CA6;">Se convierte en la lista de usuarios para el spraying.</mark> |
| Datos de la organización | empleados, cargos, ofertas de empleo | Nombres → usuarios; y el stack técnico que anuncian. |
| Tecnología en uso | EDR, VPN, SSO, versiones | Anticipa defensas (¿CrowdStrike? ¿MDI?). |
| Datos filtrados | *breaches*, *pastes*, repos | <mark style="background: #FF5582A6;">Credenciales reutilizables o patrones de contraseña.</mark> |

# Dónde y cómo (2026)

- **ASN / netblocks**: `whois`, [bgp.he.net](https://bgp.he.net), `amass intel -org "<nombre>"`. Traduce el nombre de la empresa a rangos IP propios (no los cloud).
- **DNS y subdominios**: *certificate transparency* (`crt.sh`), `subfinder`, `amass enum`, `dnsx`, y viewdns.info para históricos. <mark style="background: #FFB8EBA6;">La CT es hoy la fuente pasiva más rica</mark>: los certificados delatan subdominios internos (`vpn.`, `mail.`, `adfs.`, `sharepoint.`).
- **OSINT de personal**: LinkedIn + `crosslinked`/`linkedin2username` para derivar el formato de usuario. Las **ofertas de empleo** son oro: piden "experiencia con Active Directory, Microsoft Defender for Identity, CrowdStrike" → te dicen qué te vas a encontrar dentro.
- **Fugas y credenciales**: `DeHashed`, HaveIBeenPwned, `IntelligenceX`/`LeakCheck` (`pwndb` está archivado desde 2022, ya no vale), compilaciones de *breaches*. Alimentan spraying y *credential stuffing*.
- **Documentos y repos**: Google dorks (`site: filetype:`), GitHub/GitLab por secretos, metadatos de PDFs/Office (usuarios internos, rutas).

<mark style="background: #8000E1A6;">Todo esto es un bucle</mark>: un subdominio revela un servicio, el servicio revela una tecnología, la tecnología revela usuarios, los usuarios revelan el formato — y el formato se convierte en tu primer diccionario de spraying.

# Cómo alimenta el ataque a AD

El recon externo entrega, en concreto, tres cosas accionables:

1. **Lista de usuarios** a partir del formato de email → base de [[09 - Construir la lista de usuarios objetivo]] y del [[07 - Password Spraying - visión general|password spraying]].
2. **Credenciales candidatas** de *breaches* → prueba directa contra servicios expuestos y contra el dominio.
3. **Vectores de acceso** externos (VPN, OWA/EWS, RDWeb, Citrix) → el punto de apoyo que en *assumed breach* asumimos, pero que conviene documentar.

> [!warning]+ Pasivo primero
> El recon pasivo (CT, OSINT, *breaches*) no toca la infraestructura del objetivo y es prácticamente indetectable. En cuanto haces DNS activo, escaneo de puertos o consultas a portales, generas tráfico y logs. En un engagement con componente sigiloso, agota lo pasivo antes de tocar nada.
