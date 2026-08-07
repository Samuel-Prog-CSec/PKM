---
tags:
  - Proyectos
  - Go
  - Active-Directory
  - Evasion
  - Tipo/Proyecto
Descripción: "Puntúa qué objetos de un dominio huelen a honeytoken antes de tocarlos, invirtiendo la literatura defensiva de despliegue de señuelos para convertirla en heurísticas ofensivas"
Fecha de actualización: 2026-08-04
Nota previa: "[[04 - Planificador de spraying con modelo de bloqueo]]"
Nota siguiente: "[[06 - Cartógrafo de pivoting y alcanzabilidad]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 3
Esfuerzo: 3-4 semanas
---
---

**Nombre propuesto**: `mirage`

La cuenta `svc_sqlbackup` tiene un `SPN` registrado, `Password never expires`, y en el campo `description` pone *"cuenta de servicio SQL — pwd en el share de TI"*. Es el mejor objetivo de Kerberoasting que has visto en el dominio. También es, con bastante probabilidad, <mark style="background: #FFB86CA6;">un honeytoken cuya única función es que la toques y el SOC sepa que estás dentro</mark>.

Los señuelos de identidad son hoy producto de mercado: Microsoft Defender for Identity los integra de serie, Acalvio y compañía los venden, y hay literatura abundante sobre cómo desplegarlos bien. Toda esa literatura es un manual de instrucciones que el atacante puede leer al revés.

# El problema que resuelve

Un ejercicio evasivo se pierde por tocar lo que no había que tocar, y las trampas de identidad son el mecanismo con mejor relación señal/ruido que tiene un defensor: <mark style="background: #ADCCFFA6;">cualquier interacción con un objeto señuelo es sospechosa por definición, así que la alerta se dispara sin falsos positivos y con máxima prioridad</mark>. No hay umbral que superar ni comportamiento que promediar.

Frente a eso, el atacante no tiene nada. BloodHound ordena los caminos por facilidad de explotación, y un señuelo bien puesto es —por diseño— el camino más fácil del grafo. **La herramienta que usas para priorizar te lleva directamente a la trampa.**

# Alcance del proyecto

Un analizador que consume datos de enumeración de AD (recolección propia por LDAP, o el JSON de un `SharpHound`/`SoapHound` ya existente) y emite una puntuación de sospecha por objeto, con las razones desglosadas. No decide por ti: te da el razonamiento para que decidas.

Las heurísticas salen de invertir las guías de despliegue defensivo. Un señuelo tiene que parecer jugoso y a la vez nadie lo usa, y esa contradicción deja huella en los atributos:

| Señal | Por qué delata al señuelo |
| --- | --- |
| `lastLogon` nulo o antiquísimo con `pwdLastSet` reciente | La contraseña se rota (script de mantenimiento del señuelo) pero nadie inicia sesión jamás. Es la contradicción más difícil de disimular |
| `SPN` registrado sin servicio escuchando | Un `SPN` de `MSSQLSvc/host:1433` cuyo host no tiene el 1433 abierto no es una cuenta de servicio real |
| `description` demasiado servicial | Contraseñas insinuadas o rutas a shares en el campo de descripción. Ocurre en la vida real, pero es también el cebo más usado |
| Ausencia total de sesiones y de tickets | El objeto no aparece en ninguna sesión ni en logs de acceso a recursos |
| Antigüedad de creación anómala | Creado en lote junto a otros objetos "jugosos", fuera de la secuencia de altas de la organización |
| ACL demasiado conveniente | Un `GenericAll` de *Domain Users* sobre una cuenta privilegiada no aparece por accidente |
| `objectSid` fuera de la secuencia | Señuelos creados a posteriori rompen la correlación entre RID y fecha de creación de los objetos vecinos |
| Anomalía onomástica | El nombre no sigue el patrón del resto del dominio, o lo sigue *demasiado* bien comparado con las cuentas reales |

La salida útil no es un booleano sino un **triaje**:

```shell-session
$ mirage score --input bloodhound.zip --focus kerberoastable
svc_sqlbackup      RIESGO ALTO   (82/100)
  · lastLogon nunca, pwdLastSet hace 6 días         [+30]
  · SPN MSSQLSvc/srv-db02:1433, puerto cerrado      [+25]
  · description insinúa ubicación de credenciales   [+15]
  · RID 4871 fuera de secuencia temporal            [+12]
svc_iis_pool       riesgo bajo   (14/100)
  · sesiones observadas en 3 hosts los últimos 30 d [-20]
```

# Funcionalidades principales

- **Puntuación explicada**, nunca opaca. Cada punto sumado dice qué atributo lo justificó — es lo que permite al operador discrepar con criterio.
- **Calibración contra el propio dominio**: las heurísticas se normalizan sobre la población real. Una organización donde *todas* las cuentas de servicio tienen `lastLogon` vacío convierte esa señal en ruido, y la herramienta debe darse cuenta sola.
- **Modo pasivo puro**: todo se resuelve con lecturas LDAP normales de un usuario autenticado, sin tocar el objeto sospechoso. Consultar el estado de un señuelo no debe ser lo que dispare el señuelo.
- **Verificación lateral no intrusiva**: contrastar un `SPN` con un `TCP connect` al puerto declarado es barato y desambigua mucho, pero ya es tráfico. Debe ser opcional y quedar registrado.
- **Salida enriquecida hacia BloodHound**, marcando los nodos sospechosos para que la priorización visual deje de mentir.

# Qué existe ya y dónde se queda corto

La asimetría es total y es lo que hace interesante el proyecto. Del lado defensivo hay producto maduro y mucha guía publicada —Microsoft documenta las buenas prácticas de honeytoken en Defender for Identity, TrustedSec publicó el patrón de la cuenta trampa para detectar spraying, y hay proyectos que van más lejos y **plantan caminos falsos en el propio grafo de BloodHound** para desviar al atacante—.

Del lado ofensivo no hay nada equivalente. La detección de señuelos se hace hoy por instinto del operador experimentado, y ese instinto no escala a un dominio de 30.000 objetos ni se transfiere a un compañero junior. Convertirlo en heurísticas explícitas y auditables es aportación real.

# Cosas a tener en cuenta

> [!warning]+ Esto genera falsos positivos y hay que asumirlo
> Las cuentas de servicio abandonadas reales se parecen mucho a un señuelo: nadie inicia sesión, la descripción es antigua y el `SPN` apunta a un servidor que ya no existe. <mark style="background: #FF5582A6;">Una herramienta que vete objetivos legítimos te quita hallazgos buenos</mark>. Por eso la salida es una puntuación con razones y no una lista negra: la decisión la toma el operador, la herramienta solo evita que la tome a ciegas.

- **La calibración es la diferencia entre útil e inútil.** Umbrales fijos fallan porque cada dominio tiene su normalidad. La única forma de que las señales signifiquen algo es medirlas contra la distribución del propio dominio.
- **Cuidado con lo que la propia enumeración dispara.** Recolectar sesiones (`-c All` de SharpHound) es ruidoso de por sí y algunas defensas lo alertan. Si el objetivo es no ser visto, la recolección debe limitarse a lo que se saca del DC por LDAP.
- **La contramedida existe y es barata.** Un defensor que lea esto puede darle sesiones sintéticas a sus señuelos y romper la mitad de las heurísticas. Vale la pena decirlo en el informe: <mark style="background: #8000E1A6;">un señuelo detectable es un señuelo inútil, así que este proyecto también es un test de calidad del despliegue de deception del cliente</mark>. Ese doble uso es lo que lo hace muy vendible en un ejercicio *purple*.
- **No es solo AD.** El mismo razonamiento aplica a ficheros canario en shares, claves AWS plantadas en repositorios y entradas señuelo en gestores de contraseñas. Buen camino de ampliación una vez validado el modelo.

# Fuera de alcance

No explota nada ni intenta desactivar señuelos: solo los identifica. Y no pretende certeza — el objetivo es reducir la probabilidad de pisar una trampa, no eliminarla.

# Criterio de terminado

Cuando en un laboratorio con señuelos desplegados según las guías de Microsoft y TrustedSec, mezclados con cuentas de servicio reales y con cuentas abandonadas reales, la herramienta los ordena por sospecha con los señuelos arriba y explica cada punto.

# Conexiones en el vault

La perspectiva defensiva del engaño está en el bloque de doctrina defensiva de Blue Team; la lógica de por qué el defensor invierte en trampas y qué le cuesta al atacante, en [[01 - Frameworks de threat intelligence y la Pyramid of Pain]]. La técnica que más se beneficia de este filtro es el Kerberoasting de [[11 - Kerberoasting]], y el cruce con el planificador de [[04 - Planificador de spraying con modelo de bloqueo]] es directo.

> [!info]+ Fuentes
> - Microsoft, [*Deceptive defense — best practices for identity based honeytokens in Defender for Identity*](https://techcommunity.microsoft.com/blog/microsoftthreatprotectionblog/deceptive-defense-best-practices-for-identity-based-honeytokens-in-microsoft-def/3851641) — cómo se despliegan; leído al revés, cómo se detectan.
> - TrustedSec, [*Detecting Password Spraying with a Honeypot Account*](https://trustedsec.com/blog/detecting-password-spraying-with-a-honeypot-account) — el patrón concreto que este proyecto busca evitar.
> - APT29a, [*Deploying honeytokens in Active Directory & how to trick attackers with deceptive BloodHound paths*](https://apt29a.blogspot.com/2019/11/deploying-honeytokens-in-active.html) — el envenenamiento del grafo, que es el motivo de no fiarse de la priorización por facilidad.
