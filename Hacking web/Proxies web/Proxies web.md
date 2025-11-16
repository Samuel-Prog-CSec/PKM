---
tags:
  - Introduccion
  - Web/Red-Team
  - Pentesting
Fecha de actualización: 2025-11-08
Nota previa:
Nota siguiente:
Area: "[[Web Pentesting.base|Web Pentesting]]"
---
---

# ¿Qué son los proxies web?
Los proxies web son **herramientas especializadas que se pueden configurar entre un navegador/aplicación móvil y un servidor back-end para capturar y ver todas las solicitudes web que se envían entre ambos extremos**, actuando esencialmente como herramientas de intermediario (*MITM*). Mientras que otras aplicaciones de `sniffing de red`, como [[Wireshark]], funcionan analizando todo el tráfico local para ver qué pasa a través de una red. Los proxies web funcionan principalmente con puertos web como, `HTTP/80` y `HTTPS/443`.

<mark style="background: #ADCCFFA6;">Simplifican significativamente el proceso de captura y reproducción de solicitudes web</mark> en comparación con herramientas anteriores basadas en CLI. Una vez configurado un proxy web, podemos ver todas las solicitudes [[HTTP]] realizadas por una aplicación y todas las respuestas enviadas por el servidor back-end. Además, podemos interceptar una solicitud específica para modificar sus datos y ver cómo los maneja el servidor back-end, lo cual es una parte esencial de cualquier prueba de penetración web.

**Dentro de los proxies web podemos encontrar ejemplos como**: [[Burp Suite]] o [[Proxy de ataque OWASP Zed (ZAP)]]
## Usos de los proxies web
Si bien el <mark style="background: #FFB86CA6;">uso principal de los servidores proxy web es capturar y reproducir solicitudes *HTTP*</mark>, tienen muchas otras características que permiten diferentes usos para los servidores proxy web. La siguiente lista muestra algunas de las otras tareas para las que podemos utilizar servidores proxy web:
- **Escaneo de vulnerabilidades de aplicaciones web**
- **Fuzzing web**
- **Rastreo web**
- **Mapeo de aplicaciones web**
- **Análisis de solicitudes web**
- **Pruebas de configuración web**
- **Revisiones de código**