---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Post-Explotacion
Descripción: "El registro de conversaciones con un LLM es la joya que nadie clasificó: acumula PII, credenciales y datos regulados en una tabla que se trató como si fuera un log de acceso"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Rogue actions y agencia excesiva]]"
Nota siguiente: "[[06 - Model deployment tampering]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">El registro de conversaciones con un LLM es la joya que nadie clasificó.</mark> Acumula PII, credenciales pegadas por el usuario, información médica y financiera, y fragmentos de código propietario — todo en una tabla que el equipo de desarrollo trató como si fuera un log de acceso, sin cifrado, sin retención y sin control de acceso digno.

Dos problemas se combinan aquí y conviene separarlos porque se reportan distinto:

- **Manejo excesivo de datos** — la aplicación recoge o almacena más de lo que necesita. Es un problema de diseño y de cumplimiento normativo.
- **Almacenamiento inseguro** — lo que hay guardado no está protegido. Es un problema técnico.

<mark style="background: #8000E1A6;">El primero multiplica el impacto del segundo</mark>: si la aplicación no hubiera pedido el número de tarjeta, la base de datos expuesta sería una molestia y no una brecha PCI.

# Manejo excesivo: el chatbot como aspirador de datos

En el laboratorio `Pixel Forge`, el chatbot ofrece recomendar una consola **según la condición médica del usuario**, y le pide el número de tarjeta para tramitar el pedido.

Ambas cosas son fallos de diseño con consecuencias legales antes que técnicas:

- Un dato de salud es categoría especial bajo el `RGPD` (art. 9) y `PHI` bajo `HIPAA`. Recogerlo en una caja de chat de una tienda de consolas no tiene base legal razonable.
- Un `PAN` de tarjeta introducido en un chat entra en el alcance de `PCI DSS 4.0`, con requisitos de cifrado, enmascarado, segmentación y retención que **ningún sistema de logging de conversaciones cumple por defecto**.

El principio que se viola es el de **minimización de datos** (`RGPD` art. 5.1.c): recoger solo lo estrictamente necesario para la finalidad. Un LLM conversacional lo viola de forma estructural, porque el canal es texto libre y el usuario mete lo que quiera aunque no se lo pidan.

> [!important]+ El hallazgo que casi nadie reporta
> Aunque la aplicación no pida datos sensibles, **los usuarios los pegan**. Claves de API, volcados de logs con tokens, fragmentos de código con credenciales embebidas, historiales clínicos. Si el sistema no detecta y redacta esos datos antes de persistirlos, está construyendo un repositorio de secretos por acumulación. La recomendación concreta es un paso de **redacción de PII y secretos en la ingesta del log**, con herramientas tipo `Presidio` o detección de patrones tipo `gitleaks` aplicada al texto de la conversación.

# Almacenamiento inseguro: la parte aburrida que paga

La comprobación es de pentest web clásico. Fuerza bruta de directorios con extensiones de base de datos y de respaldo:

```shell-session
$ gobuster dir -u http://<SERVER_IP>:<PORT>/ \
    -w /opt/useful/seclists/Discovery/Web-Content/raft-small-words.txt \
    -x .db,.sqlite,.sqlite3,.sql,.bak,.txt,.json,.jsonl

/login       (Status: 200) [Size: 1183]
/register    (Status: 200) [Size: 1197]
/storage.db  (Status: 200) [Size: 8876]
/store       (Status: 200) [Size: 4153]
```

`/storage.db` es descargable sin autenticación y contiene el volcado completo:

```sql
CREATE TABLE `llm_queries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `ip_address` text NOT NULL,
  `query` text NOT NULL,
  `response` text NOT NULL,
  PRIMARY KEY (`id`)
);

INSERT INTO `llm_queries` VALUES
(5,1,'172.17.0.1','Awesome. In that case I want to order the PhantomArc SP.
My credit card number is 4777752566795752 ','Unable to place order.');
```

<mark style="background: #FFB86CA6;">Tres categorías de dato regulado en una sola fila: dirección IP (dato personal bajo RGPD), contenido de la conversación y un PAN completo en claro.</mark>

Ampliar la lista de extensiones respecto a la de HTB tiene sentido: los formatos habituales de persistencia de conversaciones hoy son `.jsonl`, `.json` y `.sqlite3`, no `.db`.

## El caso real: DeepSeek, enero de 2025

> [!info]+ Fuente: [Wiz Research — *Exposed DeepSeek Database Leaking Sensitive Information*](https://www.wiz.io/blog/wiz-research-uncovers-exposed-deepseek-database-leak) (29-ene-2025)
> Una instancia de `ClickHouse` accesible públicamente en dos subdominios de DeepSeek, **sin autenticación**, con control total sobre las operaciones de base de datos. Más de un millón de líneas de log con historial de chat en texto plano, claves secretas y detalles del backend. Un atacante podía además ejecutar consultas para exfiltrar ficheros locales del servidor.

Es exactamente el escenario del laboratorio, a escala de una empresa valorada en miles de millones, y con el mismo origen: <mark style="background: #FFB8EBA6;">un servicio de datos del stack desplegado con su configuración por defecto, que no trae autenticación</mark>. Es el mismo patrón de la infraestructura de MLOps expuesta que se detalla en [[10 - Ataques a los componentes de sistema]] y en [[07 - Vulnerabilidades en el stack de ML]].

# La superficie que HTB no cubre: `embeddings` y bases vectoriales

En un despliegue con `RAG`, el almacén de datos que importa no es la tabla de conversaciones sino la **base vectorial**. Y ahí hay dos problemas específicos.

## Los `embeddings` no son anónimos

Existe la creencia extendida de que un vector es una representación irreversible del texto, y por tanto que almacenar `embeddings` de documentos sensibles es aceptable. **Es falso.**

> [!info]+ Fuente: Morris et al., [*Text Embeddings Reveal (Almost) As Much As Text*](https://arxiv.org/abs/2310.06816) (EMNLP 2023)
> El método `vec2text` reconstruye el texto original a partir de su `embedding` mediante corrección iterativa, recuperando literalmente hasta el 92 % de textos cortos de 32 tokens. Sobre notas clínicas, recupera nombres completos de pacientes en la mayoría de los casos.

<mark style="background: #FF5582A6;">Un volcado de la base vectorial es equivalente a un volcado de los documentos originales</mark>, y debe reportarse con la misma severidad. Esto es `LLM08: Vector and Embedding Weaknesses` del `OWASP LLM Top 10` 2025, una categoría que no existía en la edición 2023 sobre la que está escrito el módulo de HTB.

## Los almacenes vectoriales se despliegan sin autenticación

`Chroma`, `Qdrant`, `Weaviate` y `Milvus` siguen el mismo patrón que el resto del stack de datos: arrancan sin autenticación y se aseguran "después". Los puertos a incluir en el escaneo:

| Servicio | Puerto por defecto | Nota |
| - | - | - |
| `Chroma` | 8000 | Sin auth por defecto; API REST completa |
| `Qdrant` | 6333 (REST) / 6334 (gRPC) | Auth por clave API opcional, desactivada por defecto |
| `Weaviate` | 8080 | Anónimo habilitado por defecto |
| `Milvus` | 19530 | Auth desactivada por defecto |
| `Elasticsearch` / `OpenSearch` con `k-NN` | 9200 | Suele reutilizar el clúster existente |

Además del volcado, un almacén vectorial escribible permite **envenenar el contexto** que recupera el agente: es `ASI06: Memory & Context Poisoning` y el vector natural para las [[05 - Inyección indirecta en RAG, email y web|inyecciones indirectas]].

## Telemetría fuera de la frontera de confianza

Un tercer punto de fuga que rara vez se audita: las plataformas de observabilidad de LLM (`LangSmith`, `Langfuse`, `Helicone`, `Weights & Biases`) reciben **el `prompt` y la respuesta completos**, incluido lo que el usuario pegó. En muchos despliegues eso significa que las conversaciones salen a un SaaS de terceros con un acuerdo de tratamiento que nadie revisó. Es un hallazgo de cumplimiento con evidencia técnica trivial: basta mirar las peticiones salientes de la aplicación.

# Mitigaciones

- **Minimización** — no pedir lo que no se necesita, y **redactar en la ingesta** lo que el usuario aporte de más. Es la única mitigación que reduce el impacto de todas las demás fallas a la vez.
- **Clasificar el almacén de conversaciones** con el nivel del dato más sensible que puede contener, no con el que se espera que contenga. En la práctica: el mismo nivel que la base de datos de clientes.
- **Retención agresiva y automática.** Un log de conversaciones sin política de borrado crece sin límite y aumenta el impacto de cualquier brecha futura. Días o semanas, no años.
- **Cifrado en reposo y control de acceso** sobre la tabla de conversaciones y sobre la base vectorial, tratada como dato en claro.
- **Anonimización y privacidad diferencial** cuando esos datos alimenten reentrenamiento — que es el caso habitual y el que además abre la puerta al [[00 - El pipeline de datos y su superficie de ataque|envenenamiento]].
- **Segmentación de red** para los servicios de datos del stack. `ClickHouse`, `Chroma` y compañía no deberían tener ruta desde Internet, con o sin autenticación.

> [!warning]+ Cifrado homomórfico: el matiz que HTB omite
> El material original propone `Homomorphic Encryption` como forma de operar sobre datos cifrados sin descifrarlos. Es matemáticamente cierto y **operativamente irrelevante** para casi cualquier despliegue de 2026: el sobrecoste sigue siendo de dos a cuatro órdenes de magnitud sobre la inferencia en claro. Existen nichos reales —consultas cifradas contra bases vectoriales, inferencia privada sobre modelos pequeños en banca y salud— y hay avances con `TFHE` y aceleración por hardware, pero recomendarlo como mitigación general en un informe resta credibilidad. Si el requisito es que el proveedor no vea los datos, lo que se despliega hoy es **inferencia en entorno de ejecución confiable** (`TEE`: Intel TDX, AMD SEV-SNP, NVIDIA Confidential Computing en Hopper y Blackwell), que es lo que hay detrás de las ofertas de "computación confidencial" de los grandes proveedores.
