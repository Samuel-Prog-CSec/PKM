---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Session-Puzzling
Descripción: "El caso más realista de session puzzling: no se puede saltar la autenticación de forma directa, pero dos procesos distintos comparten una variable de sesión y, intercalando sus…"
Fecha de actualización: 2026-07-14
Nota previa: "[[15 - Población prematura de sesión]]"
Nota siguiente: "[[17 - Detección, herramientas y prevención de Session Puzzling]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

El caso más realista de session puzzling: no se puede saltar la autenticación de forma directa, pero <mark style="background: #ADCCFFA6;">dos procesos distintos comparten una variable de sesión y, **intercalando sus pasos** (en una misma sesión), se contaminan mutuamente</mark> hasta lograr un account takeover. En engagements reales estos bugs se esconden tras procesos entrelazados y, sin código fuente, se encuentran por **ensayo y error** cruzando flujos.

# Identificación: dos flujos de 3 fases

La app tiene **registro** (3 fases: `register_1/2/3.php`) y **reset de contraseña** (3 fases: `reset_1/2/3.php`). Saltar a `/register_3.php` directamente da error → la **fase actual se guarda en la sesión**. Se confirma:

1. Completo la fase 1 del reset → anoto la cookie.
2. Accedo a la fase 2 del reset con una cookie **inválida** → error "no completaste la fase 1".
3. Con la cookie **válida** → me deja pasar a la fase 3.

Confirmado: <mark style="background: #FF5582A6;">la fase vive en una variable de sesión</mark>. La pregunta: ¿es la **misma** variable en ambos flujos?

# Explotación: interleaving de los dos flujos

Quiero resetear la contraseña del **admin**, pero no sé la respuesta a su **pregunta de seguridad** (fase 2 del reset). Si el registro y el reset usan la misma variable `Phase`, puedo **avanzar la fase del reset usando el registro**:

```text
1. reset_1.php  (Username = admin)     → reset_username = admin ·  Phase = 2
2. register_1.php + register_2.php      → completo el registro ·   Phase = 3
3. reset_3.php                          → Phase == 3 y reset_username == admin
                                           → fijo la contraseña del admin  ✓
```

<mark style="background: #FFB86CA6;">La fase 3 del reset se desbloquea con el progreso del **registro**, saltándose la pregunta de seguridad</mark>. Resultado: reseteo la contraseña del admin → account takeover.

# La raíz en el código: una variable `Phase` para dos flujos

```php
// register_1.php
$_SESSION['reg_username'] = $_POST['Username'];
// ...otros reg_*...
$_SESSION['Phase'] = 2;                 // ← el registro usa 'Phase'
header("Location: register_2.php");
```

```php
// register_2.php
if ($_SESSION['Phase'] !== 2) {          // ← control de fase compartido
    header("Location: login.php?msg=Please complete Phase 1 first"); exit;
}
```

```php
// reset_1.php
$_SESSION['reset_username'] = $user_data['username'];
$_SESSION['Phase'] = 2;                 // ← el reset usa LA MISMA variable 'Phase'
header("Location: reset_2.php");
```

Ambos flujos rastrean su progreso con `$_SESSION['Phase']`. Ejecutándolos a la vez, el contador avanza por un flujo y el otro lo da por bueno. <mark style="background: #8000E1A6;">El control "no saltes fases" se rompe porque las fases de dos máquinas de estado distintas comparten un único contador</mark>.

> [!important] El patrón generalizado: confusión de máquinas de estado
> Siempre que dos flujos multi-paso (registro, reset, checkout, 2FA, KYC) compartan un **contador de paso** o una variable de contexto, se pueden **interleavear**: empiezas uno, avanzas el otro, y usas el estado cruzado para saltarte una comprobación. Es de los session puzzling más valiosos en bug bounty porque termina en ATO y ningún escáner lo ve — hay que **razonar sobre el estado** y cruzar flujos manualmente.

> [!success] Prevención
> - **Namespacing** de variables por flujo: `reg_phase` y `reset_phase` **separadas**, nunca una `Phase` global.
> - Guardar el contexto del flujo en un **token firmado** por paso, no en un contador reutilizable.
> - Validar **coherencia**: la fase 3 del reset debe exigir que las fases 1 **y** 2 **del reset** se completaran, no una fase genérica.
> Detalle completo en [[17 - Detección, herramientas y prevención de Session Puzzling]].

## Referencias

- [PortSwigger — Business logic vulnerabilities](https://portswigger.net/web-security/logic-flaws)
- [OWASP — Session Puzzles (Shay Chen)](https://owasp.org/www-pdf-archive/Session_Puzzles.pdf)
