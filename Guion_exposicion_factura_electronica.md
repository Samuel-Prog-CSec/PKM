---
tags:
  - SIE
  - SIE/Exposicion
  - FacturaElectronica
asignatura: Sistemas de Información Empresariales Avanzados (SIEA)
autor: Samuel Blanchart Pérez
duracion_objetivo: 10-15 minutos
palabras_aprox: ~1600 (≈ 12 min a ritmo tranquilo)
---

# Guion de exposición — La factura electrónica

> [!tip] Cómo usar este guion
> - **Lo que está en párrafos normales se lee en voz alta, tal cual.**
> - Los **recuadros de color (callouts)** son notas para ti: **NO se leen**. Indican la diapositiva, el tiempo y qué señalar.
> - Ritmo objetivo: **tranquilo**, con pausas. Unas 130-140 palabras por minuto → el guion completo dura **unos 12 minutos**, dentro del margen de 10-15.
> - Consejo: **memoriza las dos primeras frases** (son los nervios iniciales) y mira al público al empezar y al cerrar cada diapositiva.

---

## 🟦 Diapositiva 1 — Portada

> [!info] Diapositiva 1 · ~40 s · Portada con el título y tu nombre

Buenos días. Mi nombre es Samuel Blanchart y voy a presentar mi trabajo de Sistemas de Información Empresariales Avanzados, dedicado a la factura electrónica. Durante los próximos minutos vamos a ver qué es exactamente una factura electrónica —y qué no lo es—, cómo funciona por dentro y por qué en España y en toda Europa se está convirtiendo, a marchas forzadas, en algo obligatorio. Os adelanto una idea: detrás de un documento tan rutinario como una factura se esconde una de las transformaciones digitales más importantes que están viviendo ahora mismo las empresas.

---

## 🟧 Diapositiva 2 — El problema

> [!info] Diapositiva 2 · ~1 min · La escena del PDF que se teclea a mano

Quiero empezar con una escena que seguro os resulta familiar. Llega una factura en PDF, alguien la abre, lee los datos y los teclea, uno a uno, en el programa de contabilidad. Parece un gesto insignificante. El problema es que ese gesto se repite millones de veces cada día en la economía. Y, multiplicado, se convierte en una de las mayores fuentes de coste administrativo y de errores que tienen las empresas. La factura, además, no es un papel cualquiera: acredita una compraventa y, a la vez, es la base de un montón de obligaciones contables y fiscales. Durante años viajó en papel; después, en PDF. Pero el PDF arrastra el mismo problema que el papel: necesita que una persona lo lea y lo copie a mano. La factura electrónica nace precisamente para acabar con ese cuello de botella.

---

## 🟦 Diapositiva 3 — Qué es (y qué no es)

> [!info] Diapositiva 3 · ~1 min 15 s · Definición; PDF ≠ factura electrónica

Y aquí viene el primer matiz importante, porque casi todo el mundo lo confunde. Una factura electrónica no es mandar la factura por correo, ni adjuntar un PDF. La definición que da la Unión Europea es muy clara: es una factura que se emite, se transmite y se recibe en un formato estructurado, pensado para que una máquina pueda leerlo y procesarlo de principio a fin, sin que nadie reescriba un solo dato. Fijaos en la diferencia. Un PDF o una foto de una factura son documentos digitales, sí, pero no son facturas electrónicas en sentido estricto, porque siguen necesitando que una persona los interprete. La factura electrónica de verdad sustituye esa lectura humana por un diálogo directo entre los sistemas informáticos de las dos empresas. En el fondo, convierte la factura en datos. Y en esa palabra —datos— están casi todas sus ventajas.

---

## 🟦 Diapositiva 4 — Formatos y estándares

> [!info] Diapositiva 4 · ~1 min 15 s · Modelo semántico (EN 16931) vs. sintaxis (Facturae, UBL, CII, EDIFACT)

Para que dos empresas se intercambien facturas de forma automática, sus sistemas tienen que entenderse. Y aquí conviene separar dos cosas que se confunden mucho. Una es el modelo semántico: qué información lleva una factura y qué significa cada dato —quién emite, la base imponible, el IVA, el vencimiento—. Otra es la sintaxis: cómo se escribe todo eso en un fichero concreto. Europa ha fijado un modelo semántico común, la norma EN 16931, y permite que cada país use distintas sintaxis siempre que sean «traducibles» a ese modelo. En España la sintaxis de referencia es Facturae, un formato en XML que mantiene la propia Administración. Pero también se admiten otros: UBL, que es el que usa la red europea Peppol; CII, habitual en el comercio internacional; o EDIFACT, el veterano del intercambio de datos. La idea de fondo es elegante: un único idioma común y varios «acentos» permitidos.

---

## 🟦 Diapositiva 5 — Cómo funciona: ciclo de vida y firma

> [!info] Diapositiva 5 · ~1 min 10 s · Señala el diagrama del ciclo de vida (Figura 1) al hablar de las etapas

¿Y cómo es la vida de una factura electrónica? La tenéis resumida en este esquema. Nace en el sistema de gestión del emisor, normalmente un ERP, que vuelca los datos en el formato elegido. Después se firma electrónicamente, y con esa firma queda sellada. Se transmite al receptor, que la valida automáticamente: comprueba la firma, la estructura y que los datos cuadran, y la acepta o la rechaza. Si la acepta, se contabiliza, se paga y se conserva durante el plazo legal. Esa cadena automatizada es justo lo que la diferencia de un simple PDF. Una palabra sobre la firma electrónica, que es la que da confianza al sistema: garantiza tres cosas a la vez. Que sabemos quién emitió la factura, que nadie la ha manipulado y que el emisor no puede negar después haberla emitido. Si alguien cambia una sola cifra, la firma deja de ser válida.

---

## 🟧 Diapositiva 6 — Cómo se conectan todos: el modelo de cuatro esquinas

> [!info] Diapositiva 6 · ~1 min · Señala el diagrama de las cuatro esquinas (Figura 2)

Queda una pregunta práctica: si hay miles de empresas y varios formatos, ¿cómo se conectan todas entre sí sin volverse locas? La respuesta es este modelo, el de las «cuatro esquinas». El emisor entrega su factura a su plataforma; esa plataforma la envía, a través de una red de interoperabilidad, a la plataforma del receptor; y esta se la entrega al destinatario. La red europea Peppol funciona así: te conectas una sola vez y puedes facturar a cualquiera, igual que un teléfono te deja llamar a cualquier número sin pactar nada con cada persona. En España, además, habrá una solución pública y gratuita de la Agencia Tributaria, que servirá también de gran repositorio de facturas. Quien no quiera usar una plataforma privada quedará conectado a la pública por defecto. La meta es que nadie se quede fuera por no poder pagarlo.

---

## 🟦 Diapositiva 7 — Marco normativo en España: tres regímenes

> [!info] Diapositiva 7 · ~1 min 20 s · Las tres columnas (B2G / B2B / Veri*factu)

Vamos ahora a la parte normativa, que es donde más confusión hay. En España conviven tres regímenes distintos, y conviene no mezclarlos. El primero es la factura al sector público: si trabajas para la Administración, facturarle de forma electrónica es obligatorio desde 2015, a través de la plataforma FACe. El segundo, y el más importante, es la factura entre empresas: la ley «Crea y Crece» y, sobre todo, el Real Decreto 238/2026, que se publicó en marzo de este año, extienden la obligación a todo el tejido empresarial. Y el tercero es Veri*factu, que es distinto: no regula cómo se intercambian las facturas, sino los requisitos que deben cumplir los programas de facturación para evitar el fraude, con medidas como un código QR en cada factura. Quedaos con la idea: tres normas, tres objetivos. Sector público, empresas entre sí, y programas antifraude.

---

## 🟧 Diapositiva 8 — Calendario y Europa: ViDA

> [!info] Diapositiva 8 · ~1 min 15 s · Señala la línea temporal (Figura 3). Recalca la cifra de 11.000 millones

Todo esto tiene fechas, y esta línea temporal las resume. La obligación entre empresas no llega de golpe: se aplicará de forma escalonada, primero a las grandes —las que facturan más de ocho millones— y después al resto, entre 2027 y 2028. En paralelo, Veri*factu entra en 2027. Pero nada de esto se entiende sin Europa. La Unión Europea aprobó en 2025 un gran paquete llamado ViDA, «el IVA en la era digital». ViDA convierte la factura electrónica en la base de un sistema que vigila el IVA casi en tiempo real para luchar contra el fraude. Y pone dos fechas en el horizonte: 2030, cuando será obligatoria para el comercio entre países de la Unión, y 2035, cuando todos los sistemas nacionales tendrán que estar alineados. Por daros una cifra que impresiona: Bruselas calcula que esto reducirá el fraude del IVA en hasta once mil millones de euros al año.

---

## 🟦 Diapositiva 9 — Ventajas y retos

> [!info] Diapositiva 9 · ~1 min · Dos columnas: ventajas / retos

Hagamos un balance honesto. ¿Qué ganamos? Ahorro de costes, menos errores, cobros más rápidos, integración directa con los sistemas de la empresa y una herramienta potentísima contra el fraude. La factura deja de ser papeleo y pasa a ser información útil. Pero no todo es sencillo. Adaptarse cuesta dinero y formación, sobre todo para autónomos y pequeñas empresas; por eso la ley prevé ayudas y plazos escalonados. La convivencia de varios formatos obliga a que las plataformas se entiendan entre sí. Y la conservación segura durante años, con sus firmas y certificados, añade exigencias técnicas. En resumen: un cambio que merece la pena, pero que hay que preparar bien.

---

## 🟦 Diapositiva 10 — Conclusiones

> [!info] Diapositiva 10 · ~1 min · Las ideas para llevarse a casa

Y termino con las ideas que me gustaría que os llevarais. Primera: una factura electrónica no es un PDF; es la factura convertida en datos estructurados que viajan solos entre sistemas. Segunda: la clave de todo es la interoperabilidad, hablar un idioma común, y para eso existe la norma europea. Tercera: en España conviven tres regímenes —sector público, empresas y antifraude— y todos van en la misma dirección que marca Europa con ViDA. Y la idea final, la que conecta con la asignatura: la factura electrónica es mucho más que un trámite. Es una pieza más de esa transformación hacia empresas que se gobiernan con datos. Algo tan cotidiano como una factura se ha convertido, casi sin darnos cuenta, en una palanca estratégica.

---

## ⬛ Diapositiva 11 — Cierre

> [!info] Diapositiva 11 · ~20 s · «Gracias / ¿Preguntas?»

Y hasta aquí mi exposición. Muchas gracias por vuestra atención. Quedo encantado de responder cualquier pregunta que tengáis.

---

> [!warning]- Preparación del turno de preguntas (NO se lee — repásalo antes)
> Algunas preguntas probables y una respuesta breve para cada una:
>
> - **¿Un PDF firmado digitalmente ya es una factura electrónica?** No en sentido estricto. Aunque esté firmado, el PDF no es un formato estructurado: sigue necesitando que una persona lo lea. Sí lo sería un formato híbrido como Factur-X, que mete un XML dentro del PDF.
> - **¿Qué diferencia hay entre Veri*factu y la factura electrónica B2B?** Son cosas distintas. Veri*factu regula cómo deben comportarse los programas de facturación (antifraude); la factura B2B regula cómo se intercambian las facturas entre empresas. Una empresa puede estar sujeta a las dos.
> - **¿Esto afecta a los autónomos?** Sí. La obligación entre empresas alcanza también a los autónomos, aunque con plazos más largos y con una solución pública gratuita para no penalizar a los más pequeños.
> - **¿Y si una empresa ya está en el SII?** El SII (Suministro Inmediato de Información del IVA) es un sistema de reporte casi en tiempo real; quienes están en él quedan fuera de la obligación de Veri*factu, pero no de la factura electrónica B2B.
> - **¿Por qué tantos formatos?** Por herencia histórica (EDI, sectores) y por las particularidades de cada país. La norma europea EN 16931 es justo lo que permite que todos esos formatos se "traduzcan" a un modelo común.
> - **Fuente de los datos normativos:** Real Decreto 238/2026 (BOE, 31-03-2026), Ley 18/2022, Real Decreto 1007/2023 y su aplazamiento por el RDL 15/2025, y el paquete ViDA de la Comisión Europea (2025).
