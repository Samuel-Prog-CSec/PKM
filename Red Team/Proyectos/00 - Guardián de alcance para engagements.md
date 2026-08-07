---
tags:
  - Proyectos
  - Go
  - Pentesting
  - Tipo/Proyecto
Descripción: "Proxy y resolver que rechaza en línea cualquier destino fuera del alcance firmado — el cinturón de seguridad contra el incidente más caro de un engagement"
Fecha de actualización: 2026-08-04
Nota previa: ""
Nota siguiente: "[[01 - Registro de operación a prueba de manipulación]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 1
Esfuerzo: 1-2 semanas
---
---

**Nombre propuesto**: `scopeguard`

El alcance de un engagement vive en un PDF firmado y en la cabeza del operador. Las herramientas no saben nada de él: `nmap` acepta el CIDR que le escribas, `ffuf` sigue el `Location` a donde le lleve, y una wordlist de subdominios resuelve alegremente al CDN de un tercero que nadie autorizó. <mark style="background: #FFB86CA6;">Tocar un sistema fuera de alcance es el incidente que termina un engagement</mark>, y en España encaja directamente en el `art. 197 bis CP` — la autorización del cliente no cubre a la infraestructura del vecino. En bug bounty el coste es distinto pero igual de real: un reporte contra un activo fuera del programa se cierra como *out of scope* y, si molestó a alguien, cuesta la cuenta.

Este es el proyecto más sencillo del catálogo y probablemente el que más veces te va a salvar.

# El problema que resuelve

El fallo nunca es malicioso, es de dedo: un `/16` donde iba un `/24`, un rango heredado de un engagement anterior, un `robots.txt` que apunta a un dominio corporativo distinto. Los controles actuales son **procedimentales** (leerse el RoE, tener cuidado) y por eso fallan bajo presión. Lo que falta es un control **técnico en línea**: algo que esté entre tus herramientas y la red, y que <mark style="background: #ADCCFFA6;">no deje salir un solo paquete hacia un destino que no esté en el alcance declarado</mark>.

# Alcance del proyecto

Un demonio que expone tres superficies —**proxy SOCKS5**, **proxy HTTP/CONNECT** y **resolver DNS**— y valida cada destino contra un fichero de alcance declarativo antes de reenviar nada. Las herramientas se configuran una vez contra él y se olvidan del tema.

El fichero de alcance es el corazón del diseño: un YAML versionable que se genera del RoE y se guarda con las evidencias del engagement.

```yaml
engagement: ACME-2026-Q3
ventana:
  desde: 2026-08-10T09:00:00+02:00
  hasta: 2026-08-24T20:00:00+02:00
incluir:
  - 10.20.0.0/16
  - "*.acme-corp.com"
  - 203.0.113.0/24
excluir:                      # gana siempre sobre incluir
  - 10.20.99.0/24             # entorno de producción de nóminas
  - "vpn.acme-corp.com"
puertos_prohibidos: [3389]    # RDP fuera del alcance por RoE
```

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Validación en dos tiempos (nombre → IP resuelta) | Un dominio autorizado puede resolver a una IP de terceros; validar solo el nombre no basta |
| Precedencia estricta de `excluir` | Las exclusiones del RoE son las que tienen consecuencias legales; nunca deben poder solaparse por un `incluir` más ancho |
| Ventana temporal | Fuera del horario autorizado, todo denegado. Evita el clásico "se me quedó el escáner corriendo el fin de semana" |
| Modo `--dry-run` y modo `--enforce` | Arrancar auditando (ver qué se saldría) antes de bloquear, sin romper el flujo de trabajo el primer día |
| Registro de denegaciones | Cada intento bloqueado, con timestamp y proceso origen. Es la prueba documental de diligencia si el cliente pregunta |
| Aviso de rangos de terceros | Cruzar el alcance contra los rangos publicados de AWS, Azure, GCP y Cloudflare y avisar: <mark style="background: #FF5582A6;">una IP elástica del cliente sigue siendo infraestructura del proveedor</mark>, y probarla suele requerir su autorización aparte |

# Qué existe ya y dónde se queda corto

No hay una herramienta consolidada para esto — es un hueco real, no una idea que otros ya cubrieron. Lo que existe son piezas sueltas:

- Los **matchers de scope de bug bounty** (los que consumen el JSON de programas de HackerOne o Bugcrowd) resuelven la parte de *decidir* si algo está en alcance, pero son bibliotecas de filtrado offline: no interceptan tráfico.
- **Burp Suite** tiene *Target scope* y sabe restringir su propia actividad, pero solo cubre lo que pasa por Burp. `nmap`, `netexec`, `nuclei` o un script propio se lo saltan por completo.
- El nicho donde más se ha escrito últimamente es el de los **agentes de pentesting con IA**, donde el *scope drift* (que el agente se vaya del objetivo por su cuenta) se ataca precisamente así: interceptando HTTP y DNS y rechazando lo no aprobado. Es la misma idea aplicada a un operador distinto — y una extensión natural del proyecto.

# Cosas a tener en cuenta

> [!warning]+ El TOCTOU del DNS es el fallo de diseño evidente
> Si validas el nombre y luego dejas que la herramienta resuelva por su cuenta, el control no existe: entre tu comprobación y la conexión real hay una resolución que no controlas. **El resolver tiene que estar dentro del guardián** y ser el único que las herramientas usan, devolviendo `NXDOMAIN` para lo que esté fuera de alcance. Es la diferencia entre un control y un adorno.

- **No es un control de seguridad, es un control de errores.** Un operador con permisos locales se lo salta en dos comandos, y está bien que así sea. Diseñar contra un atacante interno aquí es perder el tiempo y complicar la herramienta; el adversario es tu propio despiste a las 3 de la mañana.
- **IPv6 no es opcional.** Un objetivo con registro `AAAA` se sale del control si solo filtras IPv4, y es un fallo silencioso. En Go, usa `net/netip` (`netip.Addr`, `netip.Prefix`) en lugar del viejo `net.IP`/`net.IPNet`: es agnóstico de familia, comparable y sin asignaciones.
- **La resolución hay que cachearla con el TTL correcto**, porque un objetivo con DNS round-robin puede resolver a una IP autorizada y a otra que no lo esté. Ante ambigüedad, denegar y avisar — nunca "una de las dos vale".
- **Los rangos cloud caducan.** La IP elástica que hoy es del cliente mañana es de otro. Si el alcance se define por IP en cloud, la verificación de propiedad debe hacerse en el momento del test, no al firmar el contrato.

# Fuera de alcance

No es un proxy de interceptación (para eso está Burp), no reescribe tráfico y no hace `TLS MITM`. Solo decide *pasa* o *no pasa*. Mantener ese alcance es lo que lo hace terminable en dos semanas.

# Criterio de terminado

Presentable en el portfolio cuando: un `nmap` con un `/16` que incluye rangos excluidos se ejecuta y **solo** toca lo autorizado; el log de denegaciones es legible por un cliente no técnico; y existe un test que demuestra que el bypass por resolución externa está cerrado.

# Conexiones en el vault

El alcance y sus consecuencias legales están en [[03 - Pre-engagement I - contratos, NDA y scoping]] y [[01 - Marco legal y regulatorio del pentesting]]; las reglas de compromiso que traducen a `excluir` viven en [[04 - Pre-engagement II - RoE y kick-off]]. El registro de denegaciones alimenta el [[01 - Registro de operación a prueba de manipulación]], el siguiente proyecto.

> [!info]+ Fuentes
> - PTES, [Pre-engagement Interactions](https://pentest-standard.readthedocs.io/en/latest/preengagement_interactions.html) — definición formal del alcance y las exclusiones (consultado 2026-08-04).
> - Aikido Security, [How Aikido Secures AI Pentesting Agents and Prevents Scope Drift](https://www.aikido.dev/blog/ai-pentesting-agent-security) — el patrón de interceptar HTTP y DNS para acotar un operador autónomo (2026).
> - Documentación de Go, paquete [`net/netip`](https://pkg.go.dev/net/netip) — tipos de dirección modernos frente a `net.IP`.
