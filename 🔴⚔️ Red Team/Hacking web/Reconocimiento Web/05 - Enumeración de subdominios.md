---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[04 - Transferencias de zona DNS]]"
Nota siguiente: "[[06 - Fuerza bruta de subdominios]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Bajo el dominio principal (`example.com`) suele esconderse una red de **subdominios**: extensiones que la organización crea para separar funciones o secciones —`blog.example.com`, `shop.example.com`, `mail.example.com`—. <mark style="background: #ADCCFFA6;">Enumerar subdominios es identificar sistemáticamente todos esos hosts</mark>, y es uno de los pasos que más amplía la superficie de ataque.

# Por qué importan tanto

Los subdominios alojan recursos que **no** se enlazan desde la web principal y que a menudo tienen menos vigilancia:

- **Entornos de desarrollo y *staging***: `dev.`, `staging.`, `test.`, `uat.`. <mark style="background: #FFB86CA6;">Con medidas de seguridad relajadas, suelen exponer vulnerabilidades o información sensible</mark> que en producción estaría protegida.
- **Portales de login ocultos**: paneles de administración (`admin.`, `portal.`, `vpn.`) que no deberían ser públicos pero lo son.
- **Aplicaciones legacy**: webs viejas y olvidadas en subdominios, con software desactualizado y `CVE` conocidas.
- **Información sensible**: documentos, datos internos o ficheros de configuración expuestos por descuido.

A esto se suma el premio mayor: <mark style="background: #FF5582A6;">el `subdomain takeover`</mark>. Cuando un subdominio mantiene un `CNAME` apuntando a un servicio externo dado de baja (un bucket S3, un Heroku, un Azure, un GitHub Pages que ya no existe), un atacante puede **reclamar** ese recurso y servir contenido bajo el dominio legítimo de la víctima. Ojo: solo es explotable si el proveedor permite reaprovisionar el recurso liberado **sin verificar propiedad previa** —muchos ya lo mitigan (Azure y GitHub exigen verificación)—, así que no todo `CNAME` colgante es *takeover*: comprueba el *fingerprint* del proveedor (proyecto `can-i-take-over-xyz`) antes de reportar. <mark style="background: #8000E1A6;">El resultado es control total de un host del objetivo</mark> para phishing, robo de cookies o *bypass* de CORS. Es de los hallazgos más reportados —y mejor pagados— en bug bounty.

# Dos enfoques: activo y pasivo

Desde el punto de vista DNS, los subdominios son registros `A`/`AAAA` (o `CNAME` que los aliasan). Hay dos vías para descubrirlos.

## Enumeración activa

Interactúa directamente con los servidores DNS del objetivo:

- **Transferencia de zona** (`AXFR`): un servidor mal configurado vuelca la lista completa de subdominios de una vez. Rara vez funciona hoy, pero cuando lo hace es definitivo — ver [[04 - Transferencias de zona DNS]].
- **Fuerza bruta**: probar sistemáticamente una `wordlist` de nombres candidatos contra el dominio. Es la técnica activa más usada; la detallamos en [[06 - Fuerza bruta de subdominios]].

## Enumeración pasiva

Descubre subdominios sin tocar los servidores del objetivo, consultando fuentes externas:

- **Certificate Transparency logs**: registros públicos de certificados `SSL/TLS` que listan subdominios en el campo `SAN`. La fuente pasiva más rentable, tratada en [[07 - Certificate Transparency logs]].
- **Motores de búsqueda**: con operadores como `site:` filtras subdominios indexados (ver [[12 - Search Engine Discovery]]).
- **Bases de datos agregadas**: servicios que recopilan datos DNS de múltiples fuentes (`VirusTotal`, `crt.sh`, SecurityTrails) y permiten buscar subdominios sin interactuar con el objetivo.

<mark style="background: #FFB8EBA6;">La activa es más completa pero detectable; la pasiva es sigilosa pero incompleta</mark>. La estrategia correcta combina ambas: arrancas pasivo para construir el inventario sin ruido y rematas con fuerza bruta activa sobre lo que falte.

> [!info]+ El stack moderno de subdominios
> En bug bounty el flujo de facto encadena herramientas especializadas, no `dnsenum` suelto:
> 1. **Recolección pasiva**: `subfinder`, `amass enum -passive`, `assetfinder`, `findomain` — agregan decenas de fuentes (CT, APIs, buscadores).
> 2. **Resolución**: `dnsx` o `puredns` filtran cuáles resuelven de verdad.
> 3. **Sondeo HTTP**: `httpx` identifica cuáles sirven web, con título, tecnología y código de estado.
> 4. **Escaneo dirigido**: `nuclei` lanza plantillas sobre los hosts vivos.
> Este pipeline, ejecutado en bucle, es la base del recon continuo.

> [!warning]+ Wildcard DNS
> Si la zona tiene un registro *wildcard* (`*.example.com`), **cualquier** subdominio resuelve a la misma IP, incluso los inexistentes. Una fuerza bruta ingenua devolverá miles de falsos positivos. Las herramientas serias detectan el *wildcard* resolviendo un nombre aleatorio improbable primero y descartando las respuestas que coincidan.

La técnica activa estrella es la fuerza bruta de subdominios con `wordlists`. La abrimos en [[06 - Fuerza bruta de subdominios]].
