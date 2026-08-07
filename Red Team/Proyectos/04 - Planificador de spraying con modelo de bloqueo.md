---
tags:
  - Proyectos
  - Go
  - Active-Directory
  - Seguridad/Contraseñas
  - Tipo/Proyecto
Descripción: "Modela el riesgo real de bloqueo leyendo los PSO por usuario y la mecánica de badPwdCount, en vez de asumir una política de dominio única como hacen los sprayers actuales"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - Rastreador de flujo de datos de caja negra]]"
Nota siguiente: "[[05 - Detector de señuelos defensivos en Active Directory]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 3
Esfuerzo: 3 semanas
---
---

**Nombre propuesto**: `sprayplan`

Bloquear cuentas durante un engagement es el error que te echa del engagement. Y el detalle incómodo es que <mark style="background: #FFB86CA6;">las herramientas que dicen protegerte de eso solo te protegen del caso fácil</mark>: leen la política de contraseñas del dominio, calculan una cadencia y asumen que esa política aplica a todos los usuarios de la lista. En cualquier dominio con administración seria, esa suposición es falsa.

Este proyecto no es otro sprayer. Es el **modelo de riesgo** que a los sprayers les falta, y puede vivir como herramienta independiente que autoriza —o veta— el plan antes de que se lance el primer intento.

# El problema que resuelve

Hay tres huecos concretos, todos verificables:

**Los PSO rompen la política única.** Las *Fine-Grained Password Policies*, implementadas como `Password Settings Objects`, permiten aplicar umbrales distintos a grupos concretos, y el atributo que manda pasa a ser `msDS-LockoutThreshold` y `msDS-LockoutObservationWindow` del PSO, no el del dominio. El patrón habitual es aplicar la política **más estricta a los administradores** — que son justamente las cuentas que más te interesan y las que más caro sale bloquear. Un sprayer que lee la política de dominio y calcula un intento por ventana puede estar haciendo tres veces los intentos que tolera el PSO de *Tier 0*.

**`badPwdCount` no se replica, pero eso no te da margen.** Es una creencia extendida que repartir los intentos entre varios controladores de dominio multiplica el presupuesto. El comportamiento real: <mark style="background: #ADCCFFA6;">el contador vive en el DC contra el que se autentica, pero ese DC contacta con el PDC para verificar, y el PDC mantiene el valor agregado</mark>. Es decir, el bloqueo puede dispararse aunque ningún DC individual haya llegado al umbral. Repartir la carga te oculta el contador, no te lo amplía — y esa asimetría entre lo que crees y lo que pasa es exactamente cómo se bloquean cuentas.

**El estado inicial se ignora.** Un usuario que ya llega con dos fallos acumulados de esta mañana tiene menos presupuesto que el resto. Sprayear a ciegas sobre la lista completa asume que todos empiezan a cero.

# Alcance del proyecto

Un planificador que produce un **plan ejecutable y auditado**, y opcionalmente lo ejecuta.

**Fase de modelado.** Enumera por LDAP la política de dominio, todos los PSO y sus vínculos (`msDS-PSOAppliesTo`), y resuelve por cada usuario objetivo cuál es su política efectiva teniendo en cuenta la precedencia (`msDS-PasswordSettingsPrecedence`, donde el número más bajo gana, y un PSO vinculado directamente al usuario prevalece sobre uno vinculado a un grupo). Lee además `badPwdCount` y `badPasswordTime` de cada objetivo para conocer el presupuesto real de cada uno.

**Fase de planificación.** Agrupa a los usuarios por política efectiva y calcula una cadencia por grupo, con un margen de seguridad configurable — dejar siempre al menos un intento libre antes del umbral es la práctica sana. Emite el plan antes de tocar nada:

```shell-session
$ sprayplan plan --dc dc01.acme.local --users objetivos.txt --margen 2
Política de dominio       umbral=5  ventana=30m   → 1.847 usuarios   3 intentos/ventana
PSO "Tier0-Admins"        umbral=3  ventana=60m   →    12 usuarios   1 intento/ventana
PSO "Servicio"            umbral=0  ventana=—     →    31 usuarios   sin bloqueo, sin límite

[AVISO] 7 usuarios llegan con badPwdCount > 0 — presupuesto reducido esta ventana
[VETO]  2 usuarios a un intento del bloqueo: svc_backup, a.ferrer — excluidos del plan
Duración estimada para 3 contraseñas: 2 h 10 min
```

# Funcionalidades principales

| Funcionalidad | Detalle |
| --- | --- |
| Resolución de política efectiva por usuario | PSO vinculados a usuario y a grupo, con precedencia correcta |
| Lectura del estado previo | `badPwdCount` y `badPasswordTime` contra el PDC, que es quien tiene el valor bueno |
| Veto automático | Excluye del plan a quien esté a menos del margen configurado del umbral |
| Simulación sin tráfico | `--dry-run` completo: el plan se valida sin un solo intento de autenticación |
| Reloj honesto | La ventana se cuenta desde `badPasswordTime`, no desde que arrancó la herramienta |
| Registro de decisiones | Por qué se excluyó cada cuenta. Es material de informe y de defensa si algo se bloquea igualmente |

# Qué existe ya y dónde se queda corto

**`DomainPasswordSpray`** (PowerShell) y **`SharpSpray`** (C#) ya obtienen automáticamente la *observation window* del dominio y limitan los intentos a uno por ventana; `SharpSpray` además excluye a las cuentas que están a un intento del bloqueo. Es honesto reconocerlo: <mark style="background: #FFB8EBA6;">la parte básica del problema está resuelta desde hace años y este proyecto no la reinventa</mark>.

Lo que ninguno de los dos hace es resolver PSO por usuario, distinguir grupos con políticas distintas dentro de la misma lista de objetivos, ni modelar el estado inicial de cada cuenta. Y esa es precisamente la parte que rompe engagements en dominios grandes, que son donde se hace pentesting de verdad.

# Cosas a tener en cuenta

> [!warning]+ Leer los PSO requiere permisos que quizá no tengas
> Los objetos PSO viven en `CN=Password Settings Container,CN=System,DC=…` y por defecto **solo los administradores del dominio pueden leerlos**. Con una cuenta de usuario raso vas a obtener un resultado vacío que parece decir "no hay PSO". <mark style="background: #FF5582A6;">Tratar "no puedo leerlo" como "no existe" es el fallo que bloquea cuentas</mark>: si la lectura falla, el planificador tiene que degradar a la política más conservadora que conozca y decirlo en voz alta, no asumir la del dominio.

- **Entra ID juega con otras reglas.** El *smart lockout* de Entra bloquea por combinación de usuario y ubicación, tiene su propia ventana y no expone contadores por LDAP. Si el objetivo es híbrido, el modelo del dominio no cubre la mitad de la superficie; mejor declararlo fuera de alcance en la primera versión que fingir que aplica.
- **El reloj de la ventana no se reinicia con un éxito.** Una autenticación correcta pone `badPwdCount` a cero, pero mientras no la haya, la ventana corre desde el último fallo. Un planificador que cuenta desde su propio arranque acumula deriva y acaba solapando ventanas.
- **Cruzar con el detector de señuelos.** Una cuenta trampa bien puesta no se bloquea nunca y está ahí para que la toques: el spraying es el disparador clásico. Antes de lanzar el plan conviene pasar la lista por el proyecto siguiente y marcar lo sospechoso — es la integración natural entre ambos.
- **Los grupos protegidos generan telemetría distinta.** Los fallos contra cuentas de `Protected Users` o de *Tier 0* suelen tener alertas dedicadas en el SIEM. El plan debería poder ordenar los objetivos para dejar lo ruidoso al final, cuando ya no importe.

# Fuera de alcance

No implementa el ataque contra otros protocolos (SMB, Kerberos, OWA, SMTP) más allá de lo mínimo para validar el modelo; el objetivo es el planificador, no un sprayer multiprotocolo. Tampoco cubre Entra ID en la primera versión.

# Criterio de terminado

Cuando en un laboratorio con al menos dos PSO de umbrales distintos vinculados a grupos solapados, el planificador resuelve correctamente la política efectiva de cada usuario, y una campaña completa termina con cero cuentas bloqueadas y con la exclusión de las que llegaban con el contador alto.

# Conexiones en el vault

La técnica base está en [[07 - Password Spraying - visión general]] y su ejecución en [[10 - Password Spraying interno]]; la enumeración de la que parte el modelo, en [[08 - Enumerar políticas de contraseñas]] y [[09 - Construir la lista de usuarios objetivo]].

> [!info]+ Fuentes
> - Fox-IT, [*Further abusing the badPwdCount attribute*](https://blog.fox-it.com/2017/11/28/further-abusing-the-badpwdcount-attribute/) — mecánica real de replicación del contador y el papel del PDC.
> - Microsoft Learn, documentación de *Fine-Grained Password Policies* — atributos `msDS-LockoutThreshold`, `msDS-LockoutObservationWindow`, `msDS-PasswordSettingsPrecedence` y reglas de precedencia.
> - `dafthack/DomainPasswordSpray` y `iomoath/SharpSpray` — estado del arte del que parte este proyecto (consultado 2026-08-04).
