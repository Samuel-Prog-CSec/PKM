---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "La SQLi de segundo orden ocurre cuando la entrada del usuario se almacena de forma segura y, más tarde, se usa sin sanear en otra consulta"
Fecha de actualización: 2026-06-04
Nota previa: "[[06 - SQL Injection basada en errores]]"
Nota siguiente: "[[08 - PostgreSQL lectura y escritura de archivos]]"
Area: "[[SQLi Avanzado.base|SQLi Avanzado]]"
---
---

La SQLi de **segundo orden** ocurre cuando la entrada del usuario se **almacena** de forma segura y, **más tarde**, se usa sin sanear en otra consulta. <mark style="background: #ADCCFFA6;">El payload no se inyecta y detona en la misma petición, sino en dos pasos separados</mark>: primero se guarda, después se dispara desde otra funcionalidad. Es de los SQLi que más sobreviven en aplicaciones modernas, precisamente porque es difícil de detectar.

# La tercera vulnerabilidad de BlueBird (`/profile`)

El endpoint `/profile/{id}` ejecuta dos consultas:

```java
// 1) Segura: parametrizada
sql = "SELECT username, name, description, email, id FROM users WHERE id = ?";
user = jdbcTemplate.queryForObject(sql, new Object[]{id}, ...);

// 2) Vulnerable: concatena el email obtenido de la consulta anterior
sql = "SELECT ... FROM posts JOIN users ... WHERE email = '" + user.getEmail() + "' ORDER BY ...";
```

<mark style="background: #FFB8EBA6;">El `email` no viene directo de la petición, sino de la base de datos</mark> (resultado de la primera query). Aun así es vulnerable: se concatena. Si logramos controlar el `email` almacenado de un usuario, controlamos esa segunda consulta.

# Input tracing: ¿dónde se guarda el email?

La clave de detectar second-order es **rastrear el origen** del dato. ¿Dónde se puede fijar el `email`? Se busca un `UPDATE` que lo modifique:

```shell-session
$ grep -irnE 'UPDATE.*email' .
ProfileController.java:70: sql = "UPDATE users SET name = ?, description = ?, email = ?";
```

El endpoint `/profile/edit` permite cambiar el email del usuario logueado. <mark style="background: #8000E1A6;">Crucialmente, ese `UPDATE` está **parametrizado** (seguro al escribir)</mark> —no hay inyección al guardar—. La inyección ocurre al **leer** ese valor en `/profile`. Dos funcionalidades distintas: una almacena, otra detona.

# Explotación: dos peticiones

Explotar second-order es como cualquier SQLi, salvo que **fijar el payload** y **dispararlo** son peticiones separadas:

1. **Almacenar**: en `/profile/edit`, poner el payload como email. La query objetivo devuelve una lista de posts, así que un `UNION` encaja:
   ```sql
   ' UNION SELECT 1,2,3,4,5--
   ```
2. **Disparar**: cargar la propia página `/profile/{id}`, que ejecuta la consulta vulnerable con el email almacenado.

Al dispararlo, los [[04 - Búsqueda de errores SQL en los logs|logs]] revelan un error de tipos: `UNION types character varying and integer cannot be matched`. Las columnas `text, posted_at_nice, username, name` son `VARCHAR` y `author_id` es `INTEGER`. Se ajusta el payload con los tipos correctos:

```sql
' UNION SELECT '1','2','3','4',5--
```

Y la inyección funciona. <mark style="background: #FFB86CA6;">Igualar los tipos de columna (no solo el número) es esencial en motores estrictos como PostgreSQL</mark>.

> [!important]+
> <mark style="background: #FF5582A6;">Por qué el second-order es de los SQLi que más perduran en 2026</mark>: los escáneres automáticos (y muchos pentests superficiales) prueban cada parámetro de forma aislada y observan la respuesta **inmediata**. El second-order no produce efecto inmediato —el payload se guarda sin error— y se manifiesta en otra petición, a otro endpoint. Detectarlo exige **conectar** la funcionalidad que almacena con la que consume, algo que solo se ve con análisis de flujo de datos (manual o con [[02 - Búsqueda de strings en el código|SAST/taint analysis]]). Por eso la revisión white-box y el *input tracing* son tan valiosos.

> [!info]+
> Casos reales típicos de second-order: un `username` elegido en el registro (parametrizado) usado luego en una query de logging concatenada; un campo de perfil reflejado en un panel de administración; datos importados de una API externa. La defensa: <mark style="background: #8000E1A6;">tratar **todo** dato como no confiable, también el que viene de la propia base de datos</mark> —parametrizar siempre, incluso al releer—.

Más allá de extraer datos, con privilegios PostgreSQL permite tocar el sistema de ficheros: [[08 - PostgreSQL lectura y escritura de archivos]].
