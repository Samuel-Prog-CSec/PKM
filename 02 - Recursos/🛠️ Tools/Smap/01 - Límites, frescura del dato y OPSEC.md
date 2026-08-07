---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - OSINT
  - Tipo/Deteccion
Descripción: "Los datos llegan a tener 7 días, no hay IPv6 y el objetivo nunca te ve — pero Shodan sí registra tus consultas"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Smap - escaneo pasivo con datos de Shodan]]"
Nota siguiente:
Area: "[[Smap.base|Smap]]"
---
---

`Smap` es la única herramienta de este arsenal donde la pregunta "¿cómo evado el firewall?" no aplica: **no hay nada que evadir porque no hay tráfico hacia el objetivo**. Lo que sí hay son límites en el dato y una traza distinta, y eso es lo que toca entender.

# Los límites, declarados por el propio proyecto

| Límite | Consecuencia |
| --- | --- |
| **Datos de hasta 7 días de antigüedad** | Un puerto listado puede llevar una semana cerrado. Uno abierto ayer no aparece. |
| **Sin soporte IPv6** | En una red *dual-stack* solo ves la mitad — y suele ser la mitad mejor protegida. |
| **Identificación de software poco fiable sin `--active`** | El CPE viene del banner que Shodan capturó, con sus errores. |
| **`--active` necesita Nmap instalado** | Y en ese momento dejas de ser pasivo. |

## La frescura es el límite que importa

<mark style="background: #FF5582A6;">Siete días es mucho tiempo en infraestructura</mark>. En ese margen caben un despliegue, una migración, un parche y un incidente. Las dos direcciones del error:

- **Falso positivo**: reportas un puerto que ya está cerrado. En un informe es un hallazgo que el cliente no puede reproducir, y eso te cuesta credibilidad en toda la entrega.
- **Falso negativo**: das por limpia una superficie que se abrió después del último escaneo de Shodan. Es el error caro.

Además, InternetDB **no sondea los 65.535 puertos**: cubre un subconjunto de puertos comunes. Un servicio en un puerto exótico sencillamente no está en la base.

> [!important]+ La regla de redacción
> <mark style="background: #8000E1A6;">Un dato de `Smap` es una **hipótesis fechada**, no un hallazgo</mark>. En el informe: «según Shodan InternetDB (consultado el 2026-08-04), el host expone el puerto 3389» — y si vas a afirmar que está abierto, confírmalo activamente. Es la misma disciplina que con [[07 - uncover - recon pasivo vía motores de búsqueda|uncover]] y con cualquier fuente de segunda mano ([[Documentación y reporting.base|documentación y reporting]]).

## Verificación con `--active`

```shell-session
$ smap --active -Pn -sV --version-light 1.1.1.1
```

Toma los puertos que Shodan reporta e invoca a **Nmap** para comprobarlos. Es lo correcto antes de reportar, y conviene ser consciente del cambio de naturaleza:

> [!warning]+ `--active` te devuelve al mundo visible
> A partir de ese flag hay paquetes reales hacia el objetivo, con tu IP y con todas las implicaciones de [[07 - Evasión de firewalls, IDS e IPS|evasión de firewalls]] y [[08 - Detección de escaneos y evasión moderna|detección]]. La ventaja es que el escaneo va **dirigido** —solo a los puertos que Shodan ya listaba— y por tanto es mucho más pequeño y silencioso que un barrido a ciegas. Sigue siendo un escaneo, y sigue necesitando estar en scope.

# La traza que sí dejas

No hacia el objetivo, pero no es cero:

- **Shodan registra tus consultas** contra la IP desde la que preguntas. InternetDB no pide clave, así que no hay una cuenta a la que asociarlo, pero el proveedor ve tu origen y su volumen.
- **Resolución DNS**: si le pasas nombres en vez de IPs, tu resolutor los resuelve y eso sí genera consultas. Con `--iterative` en otras herramientas iría directamente al DNS del cliente ([[03 - ZDNS - resolución DNS masiva]]); aquí no, pero conviene saber de dónde sale cada consulta.
- **El objetivo no ve absolutamente nada.** Ni un paquete, ni una línea de log, ni una alerta.

<mark style="background: #FFB86CA6;">Esa asimetría es la razón de que el recon pasivo sea la primera fase de cualquier engagement serio</mark>: recoges lo que hay sin gastar ni un gramo de sigilo, y llegas a la fase activa con objetivos concretos en vez de un barrido.

# El límite conceptual: no ves lo que Shodan no mira

Aunque los datos fueran de hoy mismo, seguiría habiendo un hueco estructural. Shodan escanea **Internet público**. Fuera de su alcance queda:

- Infraestructura **interna** (todo un pentest de red interna).
- Servicios detrás de **VPN** o de listas blancas por IP.
- Hosts que **filtran el rango de escaneo de Shodan** — y bloquear a los escáneres masivos conocidos es una práctica de *hardening* cada vez más común, precisamente para no aparecer indexado.
- **Puertos raros** fuera de su conjunto de sondeo.
- Todo lo que exija **interacción** (autenticación, vhosts, rutas concretas).

> [!important]+ Y por eso hay dos fuentes de ceguera opuestas
> Un host que **no está** en Shodan puede significar "no expone nada" o "se protege bien y no quiere estar indexado". Lo segundo es, en sí mismo, información sobre la madurez del cliente — y significa que ahí la fase activa importa más, no menos. La comparación entre lo pasivo y lo activo es un hallazgo por derecho propio ([[07 - uncover - recon pasivo vía motores de búsqueda]]).

# Dependencia de un servicio de terceros

> [!warning]+ Riesgo operativo real
> `Smap` es un envoltorio sobre una API gratuita que Shodan puede limitar, cambiar o cerrar cuando quiera. El proyecto es pequeño (`s0md3v/Smap`, v0.2.0-rc de abril de 2026, un solo autor). <mark style="background: #FF5582A6;">No lo metas en el camino crítico de una automatización sin plan B</mark> — y el plan B natural es [[04 - naabu - descubrimiento de puertos|`naabu -passive`]], que usa exactamente la misma fuente desde un proyecto con mucho más mantenimiento detrás.

> [!info]+ Fuente
> [README de Smap](https://github.com/s0md3v/Smap) — limitaciones declaradas (7 días de antigüedad, sin IPv6, fiabilidad del *fingerprinting* sin `--active`, dependencia de Nmap para la verificación). Metodología de recon pasivo en [[08 - Detección de escaneos y evasión moderna]].
