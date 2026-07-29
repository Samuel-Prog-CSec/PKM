---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Explotacion
Descripción: "Más allá del bypass de login, la LDAP injection permite extraer datos del directorio —usuarios, contraseñas, atributos internos—"
Fecha de actualización: 2026-07-16
Nota previa: "[[02 - Bypass de autenticación con LDAP]]"
Nota siguiente: "[[04 - Evasión de filtros en LDAP Injection]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

Más allá del bypass de login, la LDAP injection permite **extraer datos del directorio** —usuarios, contraseñas, atributos internos—. Hay dos casos: cuando la aplicación **muestra** los resultados (extracción directa con `*`) y cuando **no** los muestra pero responde distinto (extracción ciega, bit a bit, como en la [[05 - XPath ciega y basada en tiempo|blind XPath]]).

# Exfiltración con resultados visibles

Si la app refleja el resultado de la búsqueda, el comodín `*` lo vuelca todo. Sobre un filtro como `(&(uid=admin)(objectClass=account))`, inyectar `*` en el `uid`:

```ldap
(&(uid=*)(objectClass=account))
```

devuelve **todas** las cuentas. Si el punto de inyección cae en una cláusula `OR`, el efecto es el mismo — un `(objectClass=*)` fuerza a listar todas las entradas:

```ldap
(|(objectClass=organization)(objectClass=*))
```

# Explotación ciega (sin resultados visibles)

El caso realista: la app no muestra datos, pero <mark style="background: #ADCCFFA6;">responde de forma distinta según la consulta devuelva algo o no</mark> (p. ej. "modo mantenimiento" vs "credenciales inválidas"). Esa diferencia es el oráculo. LDAP no tiene `sleep`, así que —igual que en XPath— necesitamos ese indicador de comportamiento.

**Fuerza bruta de la contraseña carácter a carácter** con filtros de subcadena (`valor*`):

```ldap
(&(uid=htb-stdnt)(password=a*))     # ¿empieza por 'a'? → no
(&(uid=htb-stdnt)(password=p*))     # ¿empieza por 'p'? → sí
(&(uid=htb-stdnt)(password=p@*))    # segundo carácter → '@'
```

Se itera todo el charset (letras, dígitos, especiales) por posición hasta que ningún carácter da positivo → contraseña completa.

**Exfiltrar otros atributos** inyectando una cláusula `OR`. Con usuario `htb-stdnt)(|(description=*` y contraseña `invalid)`:

```ldap
(&(uid=htb-stdnt)(|(description=*)(password=invalid)))
```

<mark style="background: #8000E1A6;">Como la contraseña es falsa, el `OR` inyectado solo es verdadero si la condición del `description` lo es</mark> → se aplica la misma fuerza bruta carácter a carácter a cualquier atributo (`description`, `mail`, `userPassword`…).

**Enumerar qué atributos existen**: un comodín sobre el atributo (`(atributo=*)`) devuelve positivo solo si el atributo existe en la entrada, permitiendo descubrir el esquema antes de extraerlo.

> [!warning]+ Atributos case-insensitive
> <mark style="background: #FFB8EBA6;">La mayoría de atributos LDAP son insensibles a mayúsculas</mark>, así que la fuerza bruta te da el valor pero no necesariamente el *casing* correcto. Si necesitas el valor exacto (una contraseña que luego se usará en otro sistema case-sensitive), habrá que fuerza-brutear también las mayúsculas.

> [!important]+ Automatiza
> Iterar posición × charset a mano es inviable. Un script (bucle que construye el filtro de subcadena, envía la petición y lee el oráculo) es obligatorio; ver [[05 - Arsenal de herramientas LDAP]]. Misma lógica que la [[04 - Extracción de datos boolean-based|extracción boolean-based en SQLi]].

Antes de las herramientas, lo que marca la diferencia en un objetivo con defensas: la [[04 - Evasión de filtros en LDAP Injection|evasión de filtros]].
