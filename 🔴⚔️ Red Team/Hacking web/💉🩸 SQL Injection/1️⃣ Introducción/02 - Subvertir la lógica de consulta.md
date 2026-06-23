---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[01 - Detección de SQL Injection]]"
Nota siguiente: "[[03 - Uso de comentarios]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

El primer uso práctico de una SQL injection no es ejecutar consultas completas, sino **alterar la lógica** de la consulta existente para que devuelva lo que nos interesa. El caso canónico es el [[09 - Bypass de autenticación - modificación de parámetros|bypass de autenticación]]: lograr iniciar sesión sin conocer la contraseña, abusando del operador `OR`. Asume que ya hemos confirmado el punto de inyección y su contexto siguiendo la [[01 - Detección de SQL Injection|metodología de detección]].

# El escenario: un login vulnerable

Un panel de administración valida credenciales con una consulta que combina usuario y contraseña mediante `AND`:

```sql
SELECT * FROM logins WHERE username='admin' AND password='p@ssw0rd';
```

Si el DBMS devuelve una fila, las credenciales son válidas y el código PHP da por buena la sesión. Con la contraseña incorrecta, el `AND` evalúa a `false` y no se devuelve ninguna fila: login fallido. <mark style="background: #ADCCFFA6;">El objetivo del atacante es forzar que la condición del `WHERE` sea siempre verdadera</mark>, independientemente de usuario y contraseña.

# Inyección con `OR`

Una vez detectada la inyección (la comilla simple rompe la query y genera un error de sintaxis), explotamos la **precedencia de operadores**: en SQL, `AND` se evalúa antes que `OR`. Por tanto, basta con que exista **una** condición verdadera unida por `OR` para que toda la cláusula sea verdadera. La condición universalmente verdadera es `'1'='1'`.

Para mantener un número **par de comillas** y no romper la sintaxis, se omite la última comilla del payload, dejando que la comilla original de la consulta la cierre. Inyectando `admin' or '1'='1` en el usuario:

```sql
SELECT * FROM logins WHERE username='admin' or '1'='1' AND password='something';
```

La evaluación, respetando la precedencia:

![Diagrama de la lógica de la inyección OR: la condición '1'='1' unida por OR hace verdadera toda la cláusula WHERE pese a que la contraseña es falsa.](https://academy.hackthebox.com/storage/modules/33/or_inject_diagram.png)

1. **`AND` primero**: `'1'='1' AND password='something'` → `True AND False` → `False`.
2. **`OR` después**: `username='admin' OR False` → `True`, porque el usuario `admin` existe.

El resultado es una fila válida y la sesión se concede como `admin`.

# Bypass sin un usuario válido

¿Y si no conocemos ningún nombre de usuario? Con `notAdmin' or '1'='1` la query falla: `notAdmin` no existe, así que el `OR` queda `False OR False = False`. <mark style="background: #FFB8EBA6;">La solución es inyectar también un `OR` en el campo de contraseña</mark>, de modo que el último operando sea verdadero por sí solo:

```sql
SELECT * FROM logins WHERE username='' OR '1'='1' AND password='' OR '1'='1';
```

Aquí el `OR '1'='1'` final es verdadero independientemente de todo lo anterior, así que el `WHERE` devuelve **todas** las filas de la tabla.

> [!important]+
> Cuando la consulta devuelve múltiples filas, la aplicación suele autenticar al usuario de la **primera fila** —habitualmente `admin`, por ser el `id` más bajo—. <mark style="background: #FFB86CA6;">Por eso `' OR '1'='1` no solo salta el login, sino que tiende a loguear como administrador</mark>. Es un efecto colateral, no una garantía: depende de cómo la app procese el resultado.

Con ambos campos cubiertos, ni siquiera hace falta un usuario de prueba: basta con `' or '1'='1` en los dos campos. La forma más limpia, sin embargo, suele ser comentar el resto de la consulta (siguiente nota).

# La realidad en 2026

> [!warning]+
> Este bypass es **didáctico**, pero raro en producción moderna: un login bien escrito usa consultas parametrizadas (la entrada nunca altera la estructura) y contraseñas con hash —comparar `password='...'` en texto plano ya es un *smell*—. <mark style="background: #8000E1A6;">Donde sigue funcionando es en aplicaciones legacy, paneles internos, dispositivos embebidos (routers, NAS, cámaras) y back-offices a medida</mark>, precisamente los objetivos donde un pentester encuentra más fruta madura. Cuando aparece, el impacto es total: acceso administrativo sin credenciales.

> [!info]+
> Existe un catálogo amplio de payloads de bypass, cada uno adaptado a una estructura de query distinta (comillas dobles, paréntesis, comentarios de distinto motor). La referencia de facto es la sección *Authentication Bypass* de **PayloadsAllTheThings**. Probarlos en orden, observando el cambio de comportamiento, es más rápido que razonar la query a ciegas.

La técnica que generaliza el bypass —y que evita tener que equilibrar comillas manualmente— es comentar el resto de la consulta original: [[03 - Uso de comentarios]].
