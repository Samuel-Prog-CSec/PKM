---
tags:
  - Web/Red-Team
  - Pentesting
Fecha de actualización: 2025-10-08
Nota previa: "[[Fuzzing web]]"
Nota siguiente: "[[Directorios y archivos]]"
Area: "[[Fuzzing web]]"
---
---

# Instalación de Go, Python y PIPX
Necesitamos tener *Go* y *Python* instalados para estas herramientas. Instálelos de la siguiente manera si aún no los tiene instalados.

`pipx` es una herramienta de línea de comandos diseñada para simplificar la instalación y gestión de aplicaciones Python. Agiliza el proceso creando entornos virtuales aislados para cada aplicación, garantizando que las dependencias no entren en conflicto. Esto significa que puedes instalar y ejecutar múltiples aplicaciones Python sin preocuparte por problemas de compatibilidad. `pipx` También facilita la actualización o desinstalación de aplicaciones, manteniendo su sistema organizado y libre de desorden.

Si está utilizando un sistema basado en Debian (como Ubuntu), puede instalar Go, Python y PIPX utilizando el administrador de paquetes APT.
1. Abra una terminal y actualice sus listas de paquetes para asegurarse de tener la información más reciente sobre las versiones más nuevas de los paquetes y sus dependencias.
   ```shell-session
    $ sudo apt update
    ```

2. Utilice el siguiente comando para instalar Go:
   ```shell-session
    $ sudo apt install -y golang
    ```

3. Utilice el siguiente comando para instalar Python:
   ```shell-session
    $ sudo apt install -y python3 python3-pip
    ```

4. Utilice el siguiente comando para instalar y configurar pipx:
   ```shell-session
    $ sudo apt install pipx
    $ pipx ensurepath
    $ sudo pipx ensurepath --global
    ```

5. Para asegurarte de que Go y Python estén instalados correctamente, puedes consultar sus versiones:
   ```shell-session
    $ go version
    $ python3 --version
    ```

---

# FFUF
`FFUF` (`Fuzz Faster U Fool`) es un<mark style="background: #ADCCFFA6;"> fuzzer web rápido escrito en *Go*.</mark> Se destaca por enumerar rápidamente directorios, archivos y parámetros dentro de aplicaciones web. Su<mark style="background: #FFB8EBA6;"> flexibilidad, velocidad y facilidad de uso</mark> lo convierten en uno de los favoritos entre los profesionales y entusiastas de la seguridad.

Puedes instalarlo `FFUF` usando el siguiente comando:
```shell-session
$ go install github.com/ffuf/ffuf/v2@latest
```

## Casos de uso

| Caso de uso                               | Descripción                                                                                                       |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Enumeración de directorios y archivos** | Identificar rápidamente directorios y archivos ocultos en un servidor web.                                        |
| **Descubrimiento de parametros**          | Buscar y pruebar parámetros dentro de aplicaciones web.                                                           |
| **Ataques de fuerza bruta**               | Realizar ataques de fuerza bruta para descubrir credenciales de inicio de sesión u otra información confidencial. |

---

# Gobuster
`Gobuster` es otro fuzzer de archivos popular. Es <mark style="background: #ADCCFFA6;">conocido por su velocidad y simplicidad</mark>, lo que lo convierte en una excelente opción tanto para principiantes como para usuarios experimentados.

Puedes instalarlo `GoBuster` usando el siguiente comando:
```shell-session
$ go install github.com/OJ/gobuster/v3@latest
```

## Casos de uso

| Caso de uso                            | Descripción                                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Descubrimiento de contenido**        | Escanear y encuentrar rápidamente contenido web oculto, como directorios, archivos y hosts virtuales. |
| **Enumeración de subdominios DNS**     | Identificar subdominios de un dominio de destino.                                                     |
| **Detección de contenido *WordPress*** | Utilizar listas de palabras específicas para encontrar contenido relacionado con WordPress.           |

---

# FeroxBuster
`FeroxBuster` es una <mark style="background: #ADCCFFA6;">herramienta de descubrimiento de contenido rápida y recursiva</mark> escrita en *Rust*. Está diseñado para el descubrimiento por fuerza bruta de contenido no vinculado en aplicaciones web, lo que lo hace <mark style="background: #FFB86CA6;">particularmente útil para identificar directorios y archivos ocultos</mark>. <mark style="background: #8000E1A6;">Es más una herramienta de "navegación forzada</mark>" que un fuzzer como `ffuf`.

Para instalar `FeroxBuster`, puedes utilizar el siguiente comando:
```shell-session
$ curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | sudo bash -s $HOME/.local/bin
```

## Casos de uso

| Caso de uso                                  | Descripción                                                                                          |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Escaneo recursivo**                        | Realizar escaneos recursivos para descubrir directorios y archivos anidados.                         |
| **Descubrimiento de contenido no vinculado** | Identificar contenido que no esté vinculado dentro de la aplicación web.                             |
| **Escaneos con alto rendimiento**            | Beneficiarse del rendimiento de *Rust* para realizar descubrimientos de contenido de alta velocidad. |

---

# wfuzz/wenum
`wenum` es una bifurcación mantenida activamente de `wfuzz`, una herramienta de fuzzing de línea de comandos altamente versátil y poderosa conocida por su flexibilidad y opciones de personalización. Es particularmente adecuado para el fuzzing de parámetros, ya que le permite probar una amplia gama de valores de entrada en aplicaciones web y descubrir posibles vulnerabilidades en la forma en que procesan esos parámetros.

Actualmente existen complicaciones a la hora de instalar `wfuzz`, para que puedas sustituirlo por `wenum` en cambio. Los comandos son intercambiables y siguen la misma sintaxis, por lo que simplemente puedes reemplazar comandos de `wenum` con los de `wfuzz` si es necesario.

Se utilizarán los siguientes comandos `pipx`, una herramienta para instalar y administrar aplicaciones Python en entornos aislados, para instalar `wenum`. Esto garantiza un entorno limpio y consistente para `wenum`, evitando posibles conflictos de paquetes:
```shell-session
$ pipx install git+https://github.com/WebFuzzForge/wenum
$ pipx runpip wenum install setuptools
```

## Casos de uso

| Caso de uso                               | Descripción                                                                                                       |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Enumeración de directorios y archivos** | Identificar rápidamente directorios y archivos ocultos en un servidor web.                                        |
| **Descubrimiento de parametros**          | Buscar y probar parámetros dentro de aplicaciones web.                                                            |
| **Ataques de fuerza bruta**               | Realizar ataques de fuerza bruta para descubrir credenciales de inicio de sesión u otra información confidencial. |