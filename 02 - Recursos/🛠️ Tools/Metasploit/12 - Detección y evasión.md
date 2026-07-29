---
tags:
  - Pentesting/Explotacion
  - Pentesting/Post-Explotacion
  - Metasploit
  - Tipo/Deteccion
Descripción: "Metasploit es la herramienta ofensiva más analizada del planeta: cada firma, certificado y patrón por defecto lleva años catalogado por la defensa"
Fecha de actualización: 2026-07-18
Nota previa: "[[11 - MSFvenom]]"
Nota siguiente: "[[13 - Arsenal - automatización y alternativas]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

Metasploit es la herramienta ofensiva más analizada del planeta: cada firma, certificado y patrón por defecto lleva años catalogado por la defensa. <mark style="background: #ADCCFFA6;">Usar MSF "de fábrica" contra un objetivo con EDR es delatarse</mark>. Esta nota cubre cómo se detecta y qué hacer al respecto — el mismo doble enfoque (detección ↔ evasión) que en [[11 - Detección, prevención y evasión|Shells & Payloads]].

# Cómo se detecta Metasploit

## En el endpoint

- <mark style="background: #FFB86CA6;">El `.exe` de [[11 - MSFvenom|msfvenom]] "pelado" (encodeado o no) tiene firma AV inmediata</mark>.
- [[09 - Meterpreter|Meterpreter]] deja rastro de *reflective DLL injection* y, al `migrate`, de *creación de hilos remotos* (`CreateRemoteThread`) — telemetría clásica de EDR.
- Firmas `YARA` para el stub de Meterpreter en memoria.
- Nombres de payload y rutas estándar reconocibles en la línea de comandos.

## En la red

| Artefacto por defecto | Cómo delata |
| --- | --- |
| **Puerto 4444** | El `LPORT` por defecto de MSF — alerta trivial |
| **Certificado TLS del handler** | Autofirmado con valores por defecto conocidos (`JA3/JA4`, campos del cert) |
| **User-Agent** de Meterpreter HTTP | Cadena identificable en el tráfico |
| **Patrón de *staging*** | La descarga del stage tiene forma reconocible |

# Evasión de Firewall / IDS / IPS

La evasión de red se apoya en tres ideas, comunes con la [[07 - Evasión de firewalls, IDS e IPS|evasión de Nmap]]:

- **Puertos permitidos**: `LPORT=443/80/53` en vez de 4444 — el egress los deja pasar y despiertan menos sospecha ([[03 - Reverse shells|puertos de egress]]).
- **Transporte cifrado**: `reverse_https` hace el contenido no inspeccionable por el IDS.
- **Timing y forma**: reducir el ruido, evitar ráfagas reconocibles.

# Reducir la huella de MSF (OPSEC práctica)

Ajustes concretos que cambian los valores por defecto delatores:

```shell-session
# Handler con certificado TLS propio (rompe la firma del cert por defecto)
msf6 > set HandlerSSLCert /ruta/cert.pem
msf6 > set StagerVerifySSLCert true

# Cambiar el User-Agent y el puerto por defecto
msf6 > set HttpUserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
msf6 > set LPORT 443

# Payload stageless: evita el staging detectable
#   windows/x64/meterpreter_reverse_https  (guion bajo)
```

<mark style="background: #8000E1A6;">Cambiar el certificado, el User-Agent y el puerto elimina las firmas de red más obvias</mark>; usar un payload `stageless` quita el patrón de staging. Son mejoras reales, pero **no** convierten a Meterpreter en indetectable frente a un EDR de comportamiento.

# Evasión de AV / EDR moderna

Para el endpoint, la vía no son los [[05 - Encoders|encoders]] (que ya no evaden nada) sino:

- **No entregar el `.exe` de msfvenom**: generar shellcode `-f raw` y cargarlo con un *loader* que cifra e inyecta en memoria evitando los *hooks* del EDR: [[13 - Arsenal - automatización y alternativas|Donut, ScareCrow, Freeze]].
- **Payload discreto**: un `shell/...` en vez de Meterpreter reduce muchísimo la firma cuando no necesitas la API completa.
- **AMSI bypass** y ejecución fileless cuando el vector es PowerShell — desarrollado en [[11 - Detección, prevención y evasión|Shells & Payloads]].

> [!warning]+ El veredicto honesto sobre MSF y EDR
> <mark style="background: #FF5582A6;">Frente a un EDR maduro, ni todos los ajustes de OPSEC salvan a Meterpreter</mark>. Sirven para labs, hosts legacy y objetivos sin defensas serias. Cuando el cliente tiene EDR de verdad, la decisión profesional es **migrar a un C2 diseñado para evadir** ([[13 - Arsenal - automatización y alternativas|Sliver, Havoc, Mythic]]) o usar MSF solo como *multi/handler* para un payload generado por otra herramienta.

# Del lado defensivo (para el informe)

Lo que un pentest debe recomendar al cliente para cazar MSF: EDR con detección de *reflective injection* y *remote thread*, reglas de red para el puerto 4444 y los certificados/JA3 conocidos de Metasploit, egress filtering, y firmas YARA para Meterpreter. Documentar qué se detectó y qué no es el entregable — [reglas de detección de MSF en Sigma/Elastic](https://github.com/SigmaHQ/sigma) son un buen punto de partida.

> [!info]+ Fuentes
> [MITRE ATT&CK](https://attack.mitre.org) · [reglas Sigma](https://github.com/SigmaHQ/sigma) · investigaciones de detección de Meterpreter (Red Canary, Elastic Security Labs). La evasión de red comparte principios con [[08 - Detección de escaneos y evasión moderna|la de Nmap]].

Cierra el sub-tema el [[13 - Arsenal - automatización y alternativas|arsenal moderno]]: automatización de MSF y las alternativas cuando MSF no es la herramienta adecuada.
