---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
Descripción: "El componente system cubre el hardware, el sistema operativo, la configuración y —lo que lo hace específico— la infraestructura de despliegue del modelo"
Fecha de actualización: 2026-07-28
Nota previa: "[[09 - Ataques a los componentes de aplicación]]"
Nota siguiente: "[[11 - Superficie de ataque por familia de modelos]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

El componente `system` cubre el hardware, el sistema operativo, la configuración y —lo que lo hace específico— **la infraestructura de despliegue del modelo**. Aplican los riesgos tradicionales, más una capa propia que en la práctica es donde están los compromisos totales más rápidos.

# Riesgos tradicionales

Configuraciones por defecto o mal ajustadas: puertos abiertos, ACLs débiles, interfaces administrativas expuestas, credenciales por defecto. Son fáciles de encontrar porque se automatizan con escáner, y llevan a acceso no autorizado a la infraestructura subyacente.

Las TTPs son las de siempre: escaneo de servicios y versiones con `Nmap`, escáneres de vulnerabilidades, `password spraying` contra interfaces administrativas expuestas, y fuerza bruta contra credenciales o claves.

# La capa específica: infraestructura de ML expuesta

<mark style="background: #FF5582A6;">Aquí está el hallazgo que más veces convierte un engagement de IA en un compromiso completo, y no tiene nada que ver con atacar el modelo.</mark> El stack de MLOps se diseñó asumiendo redes internas de confianza: la mayoría de estos servicios **no traen autenticación por defecto** y acaban expuestos por una regla de firewall mal puesta, un despliegue en la nube apresurado o un port-forward olvidado.

| Servicio | Puerto habitual | Qué expone |
| - | - | - |
| `Ray` (dashboard / jobs API) | 8265 | Envío de trabajos: ejecución de código Python arbitrario |
| `MLflow` (tracking server) | 5000 | Experimentos, artefactos, modelos. **Sin autenticación por defecto** |
| `TorchServe` (API de gestión) | 8081 | Registro de modelos desde URL remota |
| `Triton Inference Server` | 8000/8001/8002 | Repositorio de modelos y control de carga |
| `vLLM` / servidores OpenAI-compatibles | 8000 | Inferencia, y a menudo endpoints de administración |
| `Ollama` | 11434 | Descarga y ejecución de modelos |
| `JupyterLab` | 8888 | Ejecución de código interactiva — ver [[00 - Entorno de trabajo para IA]] |
| `Kubeflow` / pipelines | varios | Orquestación del entrenamiento |

## Casos con explotación documentada

> [!important]+ ShadowRay — CVE-2023-48022
> Ray es el framework de cómputo distribuido detrás de buena parte de los entrenamientos a gran escala. <mark style="background: #FFB86CA6;">Su API de envío de trabajos no exige autenticación: cualquiera que alcance el dashboard puede enviar código Python arbitrario para que se ejecute en el clúster.</mark>
>
> Anyscale sostiene que es comportamiento esperado —Ray asume una red de confianza—, así que **no hay parche**: la mitigación es de despliegue. Eso no ha impedido la explotación masiva: [Oligo Security documentó cientos de clústeres comprometidos](https://www.oligo.security/blog/shadowray-attack-ai-workloads-actively-exploited-in-the-wild), con actividad desde septiembre de 2023, y la campaña ha evolucionado hasta convertirse en un botnet auto-propagante integrado en kits de explotación automatizados.
>
> El impacto es máximo por lo que hay en un clúster de entrenamiento: GPUs (minado y cómputo gratis), los datasets, los modelos, y **las credenciales de nube montadas en el entorno** para acceder al almacenamiento.

> [!important]+ ShellTorch — CVE-2023-43654 y encadenados
> En `TorchServe`, la API de gestión escucha por defecto de forma accesible y sin autenticación, y permite registrar un modelo indicando una **URL remota**. Encadenando esa exposición con un SSRF, se consigue que el servidor descargue y cargue un modelo controlado por el atacante — y cargar un modelo es ejecutar código, por lo descrito en [[01 - Redes neuronales]].
>
> El resultado es una cadena completa hasta RCE con CVSS 9.8, y se encontraron miles de instancias públicamente expuestas, incluidas de organizaciones muy grandes.

**`MLflow`** merece mención propia: no implementa autenticación por defecto, y la exposición pública es habitual. Ha acumulado múltiples vulnerabilidades de *path traversal* y bypass de autenticación que permiten leer ficheros arbitrarios del servidor — claves SSH y credenciales de AWS incluidas — sin autenticarse. Es de las pocas superficies donde un simple escaneo de Shodan sigue dando resultados.

> [!warning]+ El patrón común: el formato de modelo ejecuta código al cargarse
> En diciembre de 2024, JFrog publicó **22 vulnerabilidades** en `MLflow`, `H2O`, `PyTorch` y `MLeap`. La mitad eran variantes del mismo problema: <mark style="background: #8000E1A6;">el formato de modelo del framework ejecuta código nativo al ser cargado</mark>.
>
> Es exactamente la deserialización insegura descrita en [[03 - Entrenamiento y evaluación del clasificador de spam]], generalizada a todo el ecosistema. Cualquier componente que **cargue** un modelo desde una ruta o URL que un tercero controle es un candidato a RCE, y esa es la comprobación que hay que hacer sistemáticamente en cada servicio del stack.

## Qué buscar, en orden

1. **Puertos del stack de ML** accesibles desde la red del engagement. Merece la pena añadirlos explícitamente al escaneo: no están en los perfiles por defecto.
2. **Autenticación** en cada uno. La ausencia total es lo normal, no la excepción.
3. **Puntos donde el servicio carga un modelo** desde ruta o URL controlable.
4. **Secretos en el entorno** de los procesos de inferencia y entrenamiento: claves de API del proveedor del modelo, credenciales de almacenamiento, tokens de registro de modelos. <mark style="background: #FFB8EBA6;">Robar la clave de API del proveedor es un hallazgo económico directo</mark>: consumo ilimitado facturado al cliente.
5. **Artefactos de modelo** accesibles: buckets, registros, imágenes de contenedor con el modelo empaquetado.

# Agotamiento de recursos

Un modelo es caro de ejecutar, así que la denegación de servicio es barata. Se consigue con volumen de peticiones o con entradas diseñadas para maximizar el cómputo — entradas largas que llenan la ventana de contexto, peticiones que fuerzan generaciones extensas, o cadenas de razonamiento largas en modelos que las soportan.

Dos impactos que conviene separar en el informe:

- **Disponibilidad** — el servicio deja de responder a usuarios legítimos.
- **Coste** — <mark style="background: #FFB86CA6;">con escalado automático o pago por uso, el ataque no tumba el servicio: dispara la factura.</mark> Es la *denial of wallet*, y en despliegues en la nube suele ser el impacto más realista y el más fácil de demostrar sin causar una caída.

Y un uso táctico que el material señala y merece subrayarse: **el agotamiento de recursos sirve de cortina de humo**. Mientras el equipo de seguridad atiende la caída, hay margen para explotar otro componente con mucha menos vigilancia.

> [!info]+ El artefacto del modelo como vector de ejecución
> La vía más directa de RCE en infraestructura de ML no es un servicio expuesto, sino el propio fichero del modelo: `pickle` ejecuta código al deserializar, y `torch.load` lo hereda. Detalle en [[11 - Pickle y la deserialización insegura de modelos]] y [[13 - Ejecución del ataque de esteganografía]].

# Encaje con el resto

Este componente es el que mejor conecta con el pentest tradicional, y conviene abordarlo con el arsenal de siempre: descubrimiento de servicios y versiones con `Nmap`, evaluación de vulnerabilidades, revisión de configuración, y las técnicas de [[00 - Introducción a la escalada de privilegios en Linux]] una vez dentro del host de inferencia.

<mark style="background: #FF5582A6;">En un engagement con tiempo limitado, esta capa suele dar el mejor retorno.</mark> Conseguir un `jailbreak` estable puede llevar días; encontrar un `Ray` o un `MLflow` sin autenticar lleva un escaneo, y el impacto es órdenes de magnitud mayor.

## Fuentes

- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con el inventario de servicios del stack de MLOps y sus puertos, los casos ShadowRay y ShellTorch, el patrón de carga de modelo como RCE y la *denial of wallet*, ausentes en el original.
- [Oligo Security — ShadowRay: First Known Attack Campaign Targeting AI Workloads Exploited In The Wild](https://www.oligo.security/blog/shadowray-attack-ai-workloads-actively-exploited-in-the-wild) (CVE-2023-48022, consultado 2026-07-28).
- [Oligo Security — ShellTorch: Critical Vulnerabilities in TorchServe](https://www.oligo.security/shelltorch) (CVE-2023-43654, consultado 2026-07-28).
