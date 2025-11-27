Ya que hemos visto como utilizar la [[🧲 Cláusula de Unión]], vamos a analizar **cómo utilizarla en nuestras inyecciones SQL**. En toda esta sección ==trabajaremos con la siguiente tabla==:

| ==Port code== | ==Port city== | ==Port volume== |
| ------------- | ------------- | --------------- |
| CN-SHA        | Shangai       | 37.13           |
| CN-SHE        | Shenzhen      | 23.97           |


# Detectar el número de columnas
Antes de continuar y explotar consultas basadas en uniones, **necesitamos encontrar la cantidad de columnas seleccionadas por el servidor**. Existen ==dos métodos para detectar la cantidad de columnas==:
- Usando `ORDER BY`
- Usando `UNION`


## Usando ORDER BY
La primera forma de detectar el número de columnas es a través de la función `ORDER BY`. Tenemos que **inyectar una consulta que ordene los resultados por una columna que especificamos**, es decir, columna 1, columna 2, etc., ==hasta que obtengamos un error que indique que la columna especificada no existe==.

Por ejemplo, podemos comenzar con `order by 1`, ordenar por la primera columna y tener éxito, ya que la tabla debe tener al menos una columna. Luego, haremos `order by 2` y luego `order by 3` hasta que alcancemos un número que devuelva un error o la página no muestre ningún resultado, lo que significa que este número de columna no existe. **La última columna exitosa por la que ordenamos correctamente nos da el número total de columnas**.

Si fallamos en `order by 4`, ==esto significa que la tabla tiene tres columnas==, que es el número de columnas por las que pudimos ordenar correctamente. Ejemplo del payload:

```sql
' order by 1-- -
```
==**Recordatorio**: agregamos un guion adicional (`-`) al final, para mostrarle que hay un espacio después de (`--`).==


## Usando UNION
El otro método consiste en **intentar una inyección de unión con un número diferente de columnas** hasta que obtengamos los resultados correctamente. El primer método siempre devuelve los resultados hasta que se produce un error, mientras que este método ==siempre devuelve un error hasta que se obtiene un resultado correcto==. Podemos empezar inyectando una consulta `UNION` de 3 columnas:

```SQL
cn' UNION select 1,2,3-- -
```
**Recibimos un error que dice que el número de columnas no coincide**: "*The used SELECT statements have a different number of columns.*"

Entonces, ==podemos probar con cuatro columnas== y obtenemos la siguiente respuesta:
```SQL
cn' UNION select 1,2,3,4-- -
```
**Respuesta**: 

| ==Port code== | ==Port city== | ==Port volume== |
| ------------- | ------------- | --------------- |
| 2             | 3             | 4               |
**Esta vez obtenemos los resultados correctamente**, lo que significa que una vez más la tabla tiene 4 columnas. El número que vemos es el número de la columna.


# Lugar de la inyección
Si bien una consulta puede devolver varias columnas, la aplicación web puede mostrar solo algunas de ellas. Por lo tanto, si inyectamos nuestra consulta en una columna que no se imprime en la página, no obtendremos su resultado. Es por eso que necesitamos determinar qué columnas se imprimen en la página, para determinar dónde colocar nuestra inyección. En el ejemplo anterior, si bien la consulta inyectada devolvió 1, 2, 3 y 4, solo vimos 2, 3 y 4 que se mostraban en la página como datos de salida: