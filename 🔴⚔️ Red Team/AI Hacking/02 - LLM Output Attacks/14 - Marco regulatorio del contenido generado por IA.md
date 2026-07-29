---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Reporting
Descripción: "La regulación no es materia de pentester, pero sí es materia de informe: cuando una recomendación técnica coincide con una obligación legal con multa asociada, deja de ser una…"
Fecha de actualización: 2026-07-28
Nota previa: "[[13 - Safeguards en producción (Model Armor y ShieldGemma)]]"
Nota siguiente: "[[15 - Detección y evasión en ataques a la salida]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

La regulación no es materia de pentester, pero **sí es materia de informe**: cuando una recomendación técnica coincide con una obligación legal con multa asociada, deja de ser una sugerencia y pasa a ser un requisito. Saber a qué artículo apuntar cambia cómo se prioriza el hallazgo.

El problema que toda esta legislación intenta resolver tiene dos tensiones: **atribuir responsabilidad** —¿el desarrollador del modelo, quien lo despliega, o quien escribió el prompt?— y **no confundir moderación con censura**, especialmente frente a la libertad de expresión.

# Estados Unidos

En EE.UU. difundir desinformación es, con carácter general, **discurso protegido** salvo que cruce a difamación, incitación a la violencia o fraude. Eso limita mucho lo que se puede regular, y la aproximación es fragmentaria:

- **`TAKE IT DOWN Act`** (*Tools to Address Known Exploitation by Immobilizing Technological Deepfakes On Websites and Networks*), firmada el **19 de mayo de 2025**. Criminaliza publicar —o amenazar con publicar— imágenes íntimas no consentidas (`NCII`) a través de un servicio interactivo, e **incluye explícitamente el material generado por IA**. Obliga a las plataformas cubiertas a implantar un mecanismo de notificación y retirada **en el plazo de un año desde su entrada en vigor** y a retirar el material reportado, junto con las copias idénticas conocidas, **en 48 horas**. El incumplimiento se trata como práctica comercial desleal o engañosa bajo la **FTC Act**, lo que le da a la FTC competencia sancionadora directa. Es la respuesta específica a los deepfakes de esa categoría, no una regulación general de la IA.
- **NIST `AI Risk Management Framework`** — buenas prácticas **voluntarias**: características de un sistema de IA fiable y proceso para desarrollarlo y desplegarlo. Sin fuerza legal, pero es el marco de referencia al que apuntan los contratos federales y buena parte de la industria. Ver [[05 - MITRE ATLAS y NIST AI RMF]].
- **FTC** — puede actuar contra prácticas comerciales engañosas. Si un LLM se usa para fraude o publicidad engañosa, hay competencia sancionadora por la vía del consumidor, no de la IA.

# Unión Europea

Dos normas complementarias, con enfoques distintos.

## Digital Services Act (DSA)

Regula **plataformas**, no IA. Aplica a cualquier proveedor de servicios digitales que opere en la UE, esté donde esté establecido. Obligaciones generales:

- Mecanismos de **notificación y retirada** de contenido ilícito.
- **Sistema de apelación** para quien vea su contenido retirado por error.

Y para las plataformas de mayor tamaño, obligaciones reforzadas:

- **Evaluaciones de riesgo periódicas** que deben cubrir explícitamente desinformación y violencia digital.
- **Mitigaciones efectivas** derivadas de esas evaluaciones: cambios en los algoritmos de recomendación, refuerzo de moderación.
- **Transparencia** sobre políticas de moderación, sistemas algorítmicos y segmentación publicitaria.

<mark style="background: #FFB8EBA6;">La DSA cubre todo el contenido ilícito, no solo el generado por IA</mark> — lo que la hace aplicable a los [[10 - Ataques de abuso y desinformación|ataques de abuso]] sin necesidad de que nadie demuestre que hubo un modelo detrás.

## AI Act

El marco específico de IA. Clasifica los sistemas por nivel de riesgo y asigna obligaciones a cada nivel:

| Nivel | Qué incluye | Obligaciones |
| - | - | - |
| **Riesgo inaceptable** | Puntuación social, sistemas manipulativos que causan daño significativo, explotación de vulnerabilidades | **Prohibidos** |
| **Alto riesgo** | Sanidad, educación, empleo, aplicación de la ley, infraestructuras críticas | Gestión de riesgos, gobernanza de datos, **supervisión humana**, documentación, registro |
| **Riesgo limitado** | Sistemas que interactúan con personas o generan contenido — **aquí caen los LLM** | **Transparencia**: informar de que el contenido es generado por IA, marcar los deepfakes, salvaguardas contra el uso indebido |
| **Riesgo mínimo** | Filtros de spam, videojuegos | Sin regulación específica |

## Calendario — actualizado a julio de 2026

<mark style="background: #FF5582A6;">Aviso: el calendario original del AI Act ha cambiado, y cualquier material anterior a mediados de 2026 lo tiene mal.</mark>

El **Digital Omnibus on AI** —propuesto por la Comisión en noviembre de 2025, con acuerdo provisional el 7 de mayo de 2026, aprobado por el Parlamento el 16 de junio y por el Consejo el 29 de junio, en vigor desde julio de 2026— aplazó buena parte de las obligaciones:

| Fecha | Qué aplica |
| - | - |
| 1 ago 2024 | Entrada en vigor del AI Act |
| 2 feb 2025 | Prohibiciones de riesgo inaceptable y obligaciones de alfabetización en IA |
| 2 ago 2025 | Obligaciones para modelos de propósito general (GPAI), gobernanza y régimen sancionador |
| **2 ago 2026** | **Obligaciones de transparencia del art. 50** — las que aplican a los LLM |
| **2 dic 2026** | Transparencia del art. 50(2) para sistemas preexistentes y **nuevas prácticas prohibidas** |
| **2 dic 2027** | Alto riesgo del Anexo III *(aplazado desde el 2 ago 2026)* |
| **2 ago 2028** | Alto riesgo del Anexo I — IA embebida en productos regulados |

Las **sanciones** llegan hasta **35 M € o el 7 % de la facturación mundial anual** para prácticas prohibidas, y hasta 15 M € o el 3 % para el incumplimiento de la mayoría del resto de obligaciones. Es el orden de magnitud del RGPD, y es lo que hace que estas fechas importen en un informe.

> [!important]+ Lo que hay que llevarse a un engagement
> <mark style="background: #8000E1A6;">Para un despliegue de LLM en la UE, la fecha operativa es el **2 de agosto de 2026** y el artículo es el **50**.</mark> Las obligaciones de transparencia son concretas y verificables durante un pentest:
> - ¿Se informa al usuario de que está hablando con un sistema de IA?
> - ¿Se marca el contenido generado o manipulado por IA, incluidos los deepfakes?
> - ¿Hay salvaguardas documentadas contra la generación de contenido ilícito?
>
> Un hallazgo formulado como *"el despliegue no cumple el art. 50 del AI Act, aplicable desde agosto de 2026, con sanciones de hasta el 3 % de la facturación"* se prioriza solo. El aplazamiento del alto riesgo a diciembre de 2027 **no afecta** a estas obligaciones.

# Cómo usarlo al redactar

- **Comprobar el nivel de riesgo del sistema** antes de opinar. Un chatbot de soporte es riesgo limitado; el mismo modelo cribando currículums es **alto riesgo** (empleo, Anexo III) y arrastra obligaciones de supervisión humana y gobernanza de datos. La diferencia la marca el caso de uso, no la tecnología — y es exactamente el escenario del segundo lab SMTP de [[05 - Inyección indirecta en RAG, email y web|inyección indirecta]].
- **Anclar la recomendación en la obligación** cuando coincidan. "Implementar supervisión humana sobre las decisiones automatizadas" es una buena práctica; "…que además es obligación del art. 14 para sistemas de alto riesgo" es un requisito.
- **No dar asesoramiento jurídico.** El papel del pentester es señalar el desajuste técnico y la norma aplicable; la evaluación legal la hace el departamento correspondiente. Marcarlo así en el informe evita malentendidos.
- **Fechar la afirmación.** Este calendario ya ha cambiado una vez; conviene escribir "a fecha de este informe" y la fecha de consulta.
