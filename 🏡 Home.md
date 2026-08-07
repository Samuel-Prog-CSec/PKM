---
cssclasses:
  - home
Descripción: "Panel de entrada del vault: áreas, progreso real de certificaciones, qué toca ahora, buscador y deuda de mantenimiento"
Fecha de actualización: 2026-07-31
---

```dataviewjs
/* ══════════════════════════════════════════════════════════════════════════
   BLOQUE 1 · Hero · Áreas · Certificaciones · Qué toca ahora
   ---------------------------------------------------------------------------
   TODO sale de dos sitios y ninguno se escribe a mano aquí:
     · los contadores, del índice de Dataview
     · el progreso y los pendientes, de las casillas de `📋 Temario`
   ══════════════════════════════════════════════════════════════════════════ */

const TEMARIO = "📋 Temario";

/* Encabezados reservados del temario: no son catálogos de módulos, así que
   se parsean aparte y NO alimentan «Qué toca ahora».
     · «Plan de estudio» → las tareas con fechas (panel propio, más abajo)
     · «Ejes»            → las fichas de los ejes (las lee el bloque 2)      */
const SECCION_PLAN = "plan de estudio";
const SECCION_EJES = "ejes";
const RESERVADAS = [SECCION_PLAN, SECCION_EJES];

/* ── Iconos (Lucide, el set nativo de Obsidian) ──────────────────────────
   SVG y no emoji: hay un plugin del vault que reescribe los emoji a
   <img class="emoji"> sin retirar el glifo, y el icono sale duplicado.    */

const SVG = (d) =>
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" ' +
  'stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
  'stroke-linejoin="round" aria-hidden="true">' + d + "</svg>";

const ICONOS = {
  crosshair: SVG('<circle cx="12" cy="12" r="10"/><line x1="22" x2="18" y1="12" y2="12"/><line x1="6" x2="2" y1="12" y2="12"/><line x1="12" x2="12" y1="6" y2="2"/><line x1="12" x2="12" y1="22" y2="18"/>'),
  escudo:    SVG('<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>'),
  red:       SVG('<rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/><path d="M12 12V8"/>'),
  cpu:       SVG('<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M15 2v2"/><path d="M15 20v2"/><path d="M2 15h2"/><path d="M2 9h2"/><path d="M20 15h2"/><path d="M20 9h2"/><path d="M9 2v2"/><path d="M9 20v2"/>'),
  libros:    SVG('<path d="m16 6 4 14"/><path d="M12 6v14"/><path d="M8 8v12"/><path d="M4 4v16"/>'),
  llave:     SVG('<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>'),
};

/* ── Áreas del vault ────────────────────────────────────────────────────── */

const AREAS = [
  { icon: ICONOS.crosshair, nombre: "Red Team",   accent: "red",
    desc: "Web, pentesting, AD, IA ofensiva, evasión y desarrollo",
    base: "Red Team/Red-Team.base", carpeta: "Red Team" },

  { icon: ICONOS.escudo,    nombre: "Blue Team",  accent: "blue",
    desc: "Incidentes, análisis de red y logs, defensa de sistemas de IA",
    base: "Blue Team/Blue-Team.base", carpeta: "Blue Team" },

  { icon: ICONOS.red,       nombre: "Redes",      accent: "teal",
    desc: "Fundamentos de protocolo: el «cómo funciona» del footprinting",
    base: "Redes/Redes.base", carpeta: "Redes" },

  { icon: ICONOS.cpu,       nombre: "Ingeniería", accent: "amber",
    desc: "Bases de datos, IA/ML, full-stack y sistemas empresariales",
    base: "Ingenieria/Ingenieria.base", carpeta: "Ingenieria" },

  { icon: ICONOS.libros,    nombre: "Recursos",   accent: "violet",
    desc: "Biblioteca, plantillas, lenguajes y decisiones estructurales",
    base: "02 - Recursos/Recursos.base", carpeta: "02 - Recursos" },

  { icon: ICONOS.llave,     nombre: "Arsenal",    accent: "green",
    desc: "Referencia por herramienta: Nmap, Burp, Metasploit, Hashcat…",
    base: "02 - Recursos/🛠️ Tools/Tools.base", carpeta: "02 - Recursos/🛠️ Tools",
    contarCarpetas: true, unidad: "herramientas" },
];

/* Las certificaciones NO se declaran aquí: se descubren leyendo el temario.
   Esto solo fija el color de las que ya existían, para que no cambien de
   tono al añadir otra. Una sigla nueva coge el siguiente color libre. */
const COLOR_FIJO = { CPTS: "red", COAE: "violet", CWES: "green", CWEE: "amber" };
const PALETA = ["blue", "teal", "amber", "green", "violet", "red"];

/* ── Utilidades ─────────────────────────────────────────────────────────── */

const esc = (s) => String(s).replace(/[&<>"]/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

function medir(area) {
  const paginas = dv.pages('"' + area.carpeta + '"');
  if (!area.contarCarpetas) return paginas.length;
  const profundidad = area.carpeta.split("/").length;
  const sub = new Set();
  for (const p of paginas) {
    const trozos = p.file.folder.split("/");
    if (trozos.length > profundidad) sub.add(trozos[profundidad]);
  }
  return sub.size;
}

/* Quita lo que el plugin Tasks cuelga al final (✅ 2026-07-31, prioridades,
   fechas de inicio…), el tachado de los saltados y la ruta tras el guion
   largo: "28 · Attacking… — `ruta` ✅ 2026-07-31" → "28 · Attacking…". */
function limpiar(texto) {
  return String(texto)
    .replace(/[✅➕🛫⏳📅🔁⏫🔼🔽⏬🆔⛔🏁][^\n]*$/u, "")
    .replace(/~~/g, "")
    .split(" — ")[0]
    .trim();
}

/* Una línea del plan de estudio a objeto. Todo menos la tarea es opcional:
   `- [/] Tarea [[bloque]] 🛫 2026-08-01 📅 2026-08-20 ⏫ [esfuerzo:: 8h]`   */
function parsearTarea(marca, resto) {
  const campo = (nombre) => {
    const m = resto.match(new RegExp("\\[" + nombre + "\\s*::\\s*([^\\]]+)\\]", "i"));
    return m ? m[1].trim() : null;
  };
  const fecha = (emoji) => {
    const m = resto.match(new RegExp(emoji + "\\s*(\\d{4}-\\d{2}-\\d{2})"));
    return m ? dv.date(m[1]) : null;
  };
  const enlace = resto.match(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/);

  /* El título es lo que queda tras quitar wikilink, emojis de Tasks y
     campos inline. */
  const titulo = resto
    .replace(/\[\[[^\]]+\]\]/g, "")
    .replace(/\[[^\]:]+::[^\]]*\]/g, "")
    .replace(/[🛫📅⏳➕✅❌🔁]\s*\d{4}-\d{2}-\d{2}/g, "")
    .replace(/[🔺⏫🔼🔽⏬]/g, "")
    .replace(/\s{2,}/g, " ")
    .trim();

  const prioridad = /🔺|⏫/.test(resto) ? 3 : /🔼/.test(resto) ? 2 : /🔽|⏬/.test(resto) ? 1 : 0;
  const estado =
    marca === undefined ? "pendiente" :
    marca.toLowerCase() === "x" ? "hecha" :
    marca === "/" ? "curso" :
    marca === "-" ? "cancelada" : "pendiente";

  return {
    titulo,
    estado,
    prioridad,
    bloque: enlace ? enlace[1].trim() : null,
    inicio: fecha("🛫"),
    limite: fecha("📅"),
    esfuerzo: campo("esfuerzo"),
    depende: campo("depende"),
    nota: campo("nota"),
  };
}

/* Lee el temario CRUDO y lo parsea a mano. Se hace así, y no con
   `file.tasks`, por dos motivos:
     · Obsidian normaliza el subpath de un heading y se come el `·`, que es
       justo lo que distingue "CPTS · Penetration Tester" de una sección
       auxiliar;
     · los saltados son ítems SIN casilla, y Dataview no los indexa como
       tareas, así que no habría forma de contarlos.
   El resultado: añadir un `## SIGLA · Nombre` al temario basta para que
   aparezca su anillo. No hay ninguna lista de certificaciones que tocar. */
function parsearTemario(crudo) {
  const secciones = [];
  const plan = [];
  let actual = null;
  let enPlan = false;
  let nLinea = -1;

  for (const linea of crudo.split("\n")) {
    nLinea++;
    const encabezado = linea.match(/^##\s+(.+?)\s*$/);
    if (encabezado) {
      const titulo = encabezado[1].trim();
      const clave = titulo.toLowerCase();
      enPlan = clave === SECCION_PLAN;
      if (RESERVADAS.includes(clave)) { actual = null; continue; }

      const trozos = titulo.split("·").map((s) => s.trim());
      const esCertificacion = trozos.length > 1 && trozos[0].length > 0;
      actual = {
        sigla: esCertificacion ? trozos[0] : null,
        nombre: esCertificacion ? trozos.slice(1).join(" · ") : titulo,
        desc: "",
        hechos: 0,
        saltados: 0,
        pendientes: [],
      };
      secciones.push(actual);
      continue;
    }

    /* Las tareas del plan llevan metadatos y se parsean aparte. Se guarda el
       número de línea: es lo que permite marcarlas desde la Home sin tener
       que buscar la tarea por su texto (que puede repetirse). */
    if (enPlan) {
      const tarea = linea.match(/^\s*[-*]\s+\[(.)\]\s*(.+)$/);
      if (tarea) plan.push({ ...parsearTarea(tarea[1], tarea[2]), linea: nLinea });
      continue;
    }

    if (!actual) continue;                      // el callout de cabecera

    /* `- [x] texto`, `- [ ] texto` o `- texto` (sin casilla = saltado). */
    const item = linea.match(/^\s*[-*]\s+(?:\[(.)\]\s*)?(.+)$/);
    if (item) {
      const marca = item[1];
      const texto = limpiar(item[2]);
      if (!texto) continue;
      if (marca === undefined || marca === "-") actual.saltados++;
      else if (marca.toLowerCase() === "x") actual.hechos++;
      else actual.pendientes.push(texto);
      continue;
    }

    /* Primer párrafo bajo el encabezado: la descripción de la certi. */
    const suelta = linea.trim();
    if (!actual.desc && suelta && !suelta.startsWith(">") && !suelta.startsWith("#")) {
      actual.desc = suelta;
    }
  }

  /* Color: el fijo si la sigla ya lo tenía, si no el siguiente de la paleta. */
  let libre = 0;
  for (const s of secciones.filter((x) => x.sigla)) {
    s.accent = COLOR_FIJO[s.sigla.toUpperCase()] || PALETA[libre++ % PALETA.length];
  }

  return {
    certis: secciones.filter((s) => s.sigla),
    auxiliares: secciones.filter((s) => !s.sigla),
    plan,
    modulos: secciones.reduce(
      (n, s) => n + s.hechos + s.saltados + s.pendientes.length, 0),
  };
}

/* Localiza el temario y lo parsea.
   El archivo se resuelve por `metadataCache` y NO por `dv.page()`: la Home se
   abre en el arranque de Obsidian, y ahí el índice de Dataview todavía se
   está montando. Con `dv.page()` el bloque llegaba a pintar los anillos a
   0/0 durante un instante hasta el siguiente refresco. Si aun así la lectura
   sale vacía, se reintenta un par de veces antes de darla por buena. */
async function leerTemario() {
  const archivo = app.metadataCache.getFirstLinkpathDest(TEMARIO, "");
  if (!archivo) return null;

  let resultado = null;
  for (let intento = 0; intento < 4; intento++) {
    resultado = parsearTemario(await app.vault.cachedRead(archivo));
    if (resultado.modulos > 0) return resultado;
    await new Promise((listo) => setTimeout(listo, 220));
  }
  return resultado;
}

try {
  const ahora = dv.luxon.DateTime.now().setLocale("es");
  const fechaLarga = ahora.toFormat("cccc d 'de' LLLL 'de' yyyy");
  const totalNotas = dv.pages().length;
  const conArea = dv.pages().where((p) => p.Area).length;

  /* ── Hero ─────────────────────────────────────────────────────────────── */

  const chispas = [8, 21, 34, 47, 58, 66, 79, 88, 94]
    .map((x, i) => '<span class="pkm-spark" style="--x:' + x + '%;--d:' + (i * 1.6).toFixed(1) + 's"></span>')
    .join("");

  dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-hero">
<div class="pkm-hero-mesh"></div>
<div class="pkm-hero-grid"></div>
<div class="pkm-hero-scan"></div>
${chispas}
<div class="pkm-eyebrow">Segundo cerebro · seguridad ofensiva</div>
<h1 class="pkm-title">Todo lo que sé, a dos clics</h1>
<p class="pkm-tagline">Notas atómicas de referencia profesional para pentesting y bug bounty. Escritas para ejecutar, no para aprobar un examen.</p>
<div class="pkm-stats">
<span class="pkm-stat"><b>${totalNotas}</b> notas</span>
<span class="pkm-stat"><b>${AREAS.length}</b> áreas</span>
<span class="pkm-stat"><b>${conArea}</b> indexadas en un .base</span>
<span class="pkm-stat">${esc(fechaLarga)}</span>
</div>
</div>`);

  /* ── Grid de áreas ────────────────────────────────────────────────────── */

  const tarjetas = AREAS.map((a) => {
    const n = medir(a);
    const unidad = a.unidad || (n === 1 ? "nota" : "notas");
    return `<a class="internal-link pkm-card" data-accent="${a.accent}" href="${esc(a.base)}" data-href="${esc(a.base)}" aria-label="${esc(a.nombre)}">
<span class="pkm-card-inner"></span>
<span class="pkm-card-icon">${a.icon}</span>
<span class="pkm-card-name">${esc(a.nombre)}</span>
<span class="pkm-card-desc">${esc(a.desc)}</span>
<span class="pkm-card-foot"><span class="pkm-card-count">${n}</span> ${esc(unidad)}</span>
</a>`;
  }).join("");

  dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-section">
<div class="pkm-h">Áreas del vault</div>
<div class="pkm-grid">${tarjetas}</div>
</div>`);

  /* ── Certificaciones · un anillo por cada `## SIGLA · Nombre` ─────────── */

  const temario = await leerTemario();
  const enlaceTemario = `<a class="internal-link" href="${esc(TEMARIO)}">el temario</a>`;

  if (!temario) {
    dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-section">
<div class="pkm-h">Certificaciones</div>
<div class="dataview-error-box">No encuentro <b>${esc(TEMARIO)}</b>. El progreso sale de esa nota; sin ella no hay nada que calcular.</div>
</div>`);
  } else {
    const R = 32;                          // radio del anillo
    const C = (2 * Math.PI * R).toFixed(1);
    const pendientes = [];                 // se reutiliza en "qué toca ahora"

    const anillos = temario.certis.map((c, i) => {
      const total = c.hechos + c.pendientes.length;   // los saltados no entran
      const pct = total ? Math.round((c.hechos / total) * 100) : 0;
      const offset = (C * (1 - pct / 100)).toFixed(1);

      for (const texto of c.pendientes) {
        pendientes.push({ sigla: c.sigla, accent: c.accent, texto });
      }

      const partes = [];
      if (c.desc) partes.push(esc(c.desc));
      if (c.saltados) partes.push(`${c.saltados} saltado${c.saltados > 1 ? "s" : ""}`);

      return `<div class="pkm-cert" data-accent="${c.accent}">
<div class="pkm-ring">
<svg viewBox="0 0 76 76"><circle class="pkm-ring-bg" cx="38" cy="38" r="${R}"/><circle class="pkm-ring-fg" cx="38" cy="38" r="${R}" style="--c:${C};--o:${offset};--d:${(i * 0.14).toFixed(2)}s"/></svg>
<span class="pkm-ring-txt">${pct}%</span>
</div>
<div class="pkm-cert-body">
<div class="pkm-cert-top"><span class="pkm-cert-name" title="${esc(c.nombre)}">${esc(c.sigla)}</span><span class="pkm-cert-num">${c.hechos}/${total}${total && c.hechos >= total ? " ✓" : ""}</span></div>
<div class="pkm-cert-sub">${partes.join(" · ")}</div>
</div>
</div>`;
    }).join("");

    dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-section">
<div class="pkm-h">Certificaciones<span class="pkm-h-note">${temario.certis.length} en ${enlaceTemario}</span></div>
<div class="pkm-certs">${anillos || '<div class="dataview-error-box">Ninguna sección con formato <code>## SIGLA · Nombre</code> en el temario.</div>'}</div>
</div>`);

    /* ── Qué toca ahora · lo sin marcar, en el orden del temario ───────── */

    const cabecera = pendientes.length
      ? `<span class="pkm-h-note">${pendientes.length} módulo${pendientes.length > 1 ? "s" : ""} sin marcar en ${enlaceTemario}</span>`
      : `<span class="pkm-h-note">nada pendiente en ${enlaceTemario}</span>`;

    let items = pendientes.map((p, i) => `<div class="pkm-next-item" data-accent="${p.accent}">
<span class="pkm-next-n">${i + 1}</span>
<span class="pkm-next-txt"><b>${esc(p.sigla)}</b> · ${esc(p.texto)}</span>
</div>`).join("");

    /* Las secciones sin `·` que añadas al temario no llevan anillo:
       aportan aquí su primer pendiente. */
    for (const aux of temario.auxiliares) {
      if (!aux.pendientes.length) continue;
      const resto = aux.pendientes.length - 1;
      items += `<div class="pkm-next-item" data-accent="teal">
<span class="pkm-next-n">↻</span>
<span class="pkm-next-txt"><b>${esc(aux.nombre)}</b> · ${esc(aux.pendientes[0])}${resto ? ` <span class="pkm-muted">(+${resto} por delante)</span>` : ""}</span>
</div>`;
    }

    if (!items) {
      items = `<div class="pkm-next-item" data-accent="green"><span class="pkm-next-n">✓</span><span class="pkm-next-txt">Todo el temario marcado. Toca examen.</span></div>`;
    }

    dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-section">
<div class="pkm-h">Qué toca ahora ${cabecera}</div>
<div class="pkm-next">${items}</div>
</div>`);

    /* ── Plan de estudio · reparto, plazos y cuellos de botella ────────── */

    const hoy = dv.luxon.DateTime.now().startOf("day");
    const dias = (f) => (f ? Math.round(f.startOf("day").diff(hoy, "days").days) : null);

    const tareas = temario.plan.map((t) => {
      const restan = dias(t.limite);
      const desdeInicio = dias(t.inicio);
      const viva = t.estado === "pendiente" || t.estado === "curso";

      /* Plazo consumido: 0 % el día de inicio, 100 % el día del límite.
         Sin fecha de inicio no hay ventana que medir. */
      let consumido = null;
      if (t.inicio && t.limite) {
        const total = t.limite.diff(t.inicio, "days").days;
        consumido = total > 0
          ? Math.max(0, Math.min(100, Math.round(((0 - desdeInicio) / total) * 100)))
          : (restan < 0 ? 100 : 0);
      }

      /* El diagnóstico es lo que convierte la lista en un panel de control. */
      let alerta = null;
      if (t.estado === "hecha") alerta = null;
      else if (t.estado === "cancelada") alerta = null;
      else if (restan !== null && restan < 0) alerta = "vencida";
      else if (t.depende) alerta = "bloqueada";
      else if (desdeInicio !== null && desdeInicio <= 0 && t.estado === "pendiente") alerta = "sin arrancar";
      else if (consumido !== null && consumido >= 60 && t.estado === "pendiente") alerta = "en riesgo";

      return { ...t, restan, consumido, alerta, viva };
    });

    /* Orden: primero lo que arde, luego por fecha límite. «Bloqueada» NO
       adelanta puesto: una tarea que espera a otra no es urgente — urgente
       es la que la desbloquea, y esa entra por su propia fecha. */
    const peso = { vencida: 0, "sin arrancar": 1, "en riesgo": 2 };
    const vivas = tareas.filter((t) => t.viva).sort((a, b) => {
      /* `?? 8` y no `a.alerta ? … : 8`: una alerta que no esté en `peso`
         (como «bloqueada») devuelve undefined, y `undefined - 8` es NaN,
         que deja el orden a merced del algoritmo de sort. */
      const pa = peso[a.alerta] ?? 8, pb = peso[b.alerta] ?? 8;
      if (pa !== pb) return pa - pb;
      if (a.restan === null) return 1;
      if (b.restan === null) return -1;
      return a.restan - b.restan;
    });

    const cuenta = (f) => tareas.filter(f).length;
    const enCurso = cuenta((t) => t.estado === "curso");
    const vencidas = cuenta((t) => t.alerta === "vencida");
    const bloqueadas = cuenta((t) => t.alerta === "bloqueada");
    const estaSemana = cuenta((t) => t.viva && t.restan !== null && t.restan >= 0 && t.restan <= 7);
    const hechas = cuenta((t) => t.estado === "hecha");

    /* Carga: suma de las horas de lo que sigue vivo. */
    const horas = vivas.reduce((n, t) => {
      const m = String(t.esfuerzo ?? "").match(/([\d.]+)\s*h/i);
      return n + (m ? parseFloat(m[1]) : 0);
    }, 0);

    const chivato = (n, etiqueta, tono) =>
      `<div class="pkm-kpi" data-tono="${tono}"><span class="pkm-kpi-n">${n}</span><span class="pkm-kpi-t">${etiqueta}</span></div>`;

    const ESTADOS = {
      pendiente: ["Pendiente", "pend"],
      curso: ["En progreso", "curso"],
      hecha: ["Hecha", "hecha"],
      cancelada: ["Cancelada", "cancel"],
    };

    /* Las últimas cerradas se siguen mostrando, atenuadas: si al marcar una
       tarea desapareciera del todo, un clic por error sería irreversible
       desde aquí. Su círculo también cicla, así que se deshace en un clic. */
    const cerradas = tareas
      .filter((t) => t.estado === "hecha" || t.estado === "cancelada")
      .slice(-4);

    const pintarFila = (t) => {
      const [rotulo, clase] = ESTADOS[t.estado];
      /* El plazo que le tocaría estando viva: se guarda aparte para poder
         restaurarlo al reabrir una tarea sin esperar a que Dataview
         reconstruya el bloque. */
      const plazoVivo = t.restan === null ? "sin fecha"
        : t.restan < 0 ? `${Math.abs(t.restan)} d de retraso`
        : t.restan === 0 ? "vence hoy"
        : `${t.restan} d`;
      const plazo = t.estado === "hecha" ? "hecha"
        : t.estado === "cancelada" ? "cancelada"
        : plazoVivo;

      const marcas = [];
      if (t.alerta) marcas.push(`<span class="pkm-tag-alerta" data-a="${t.alerta}">${t.alerta}</span>`);
      /* Las tres prioridades se muestran, no solo la alta: si solo se pinta
         la urgente, no hay forma de distinguir «media» de «sin marcar». */
      const PRIO = { 3: "alta", 2: "media", 1: "baja" };
      if (PRIO[t.prioridad]) {
        marcas.push(`<span class="pkm-tag-prio" data-p="${PRIO[t.prioridad]}">${PRIO[t.prioridad]}</span>`);
      }
      if (t.esfuerzo) marcas.push(`<span class="pkm-tag-info">${esc(t.esfuerzo)}</span>`);

      const pie = [];
      if (t.depende) pie.push(`<b>Depende de:</b> ${esc(t.depende)}`);
      if (t.nota) pie.push(esc(t.nota));

      const destino = t.bloque ? esc(t.bloque) : null;
      const titulo = destino
        ? `<a class="internal-link" href="${destino}" data-href="${destino}">${esc(t.titulo)}</a>`
        : esc(t.titulo);

      return `<div class="pkm-tarea" data-estado="${clase}" data-estado-nombre="${t.estado}" data-linea="${t.linea}"${t.alerta ? ` data-alerta="${t.alerta}"` : ""}>
<span class="pkm-tarea-estado" role="button" tabindex="0" title="${rotulo} — pulsa para cambiar"></span>
<div class="pkm-tarea-cuerpo">
<div class="pkm-tarea-top"><span class="pkm-tarea-titulo">${titulo}</span>${marcas.join("")}</div>
${t.consumido !== null ? `<div class="pkm-tarea-barra"><div class="pkm-tarea-fill" style="width:${t.consumido}%"></div></div>` : ""}
${pie.length ? `<div class="pkm-tarea-pie">${pie.join(" · ")}</div>` : ""}
</div>
<span class="pkm-tarea-plazo" data-vivo="${esc(plazoVivo)}">${plazo}</span>
</div>`;
    };

    const filas = vivas.map(pintarFila).join("") + cerradas.map(pintarFila).join("");

    /* Apunta al encabezado, no solo a la nota: abre directamente la sección. */
    const anclaPlan = TEMARIO + "#Plan de estudio";
    const enlacePlan = `<a class="internal-link" href="${esc(anclaPlan)}" data-href="${esc(anclaPlan)}">el plan</a>`;

    const seccion = dv.container.createDiv({ cls: "pkm-section" });
    seccion.insertAdjacentHTML("beforeend", `
<div class="pkm-h">Plan de estudio<span class="pkm-h-note">${vivas.length} viva${vivas.length === 1 ? "" : "s"} · ${hechas} cerrada${hechas === 1 ? "" : "s"} · pulsa el círculo para cambiar de estado · edita en ${enlacePlan}</span></div>
<div class="pkm-kpis">
${chivato(vencidas, vencidas === 1 ? "vencida" : "vencidas", vencidas ? "mal" : "ok")}
${chivato(enCurso, "en progreso", "curso")}
${chivato(estaSemana, "vencen en 7 días", estaSemana ? "aviso" : "ok")}
${chivato(bloqueadas, bloqueadas === 1 ? "bloqueada" : "bloqueadas", bloqueadas ? "aviso" : "ok")}
${chivato(horas ? horas + " h" : "—", "carga pendiente", "info")}
</div>
${filas ? `<div class="pkm-tareas">${filas}</div>`
        : `<div class="dataview-error-box">Sin tareas vivas. Añádelas bajo <code>## Plan de estudio</code> en ${enlacePlan}.</div>`}
<div class="pkm-plan-pie"><button class="pkm-btn" type="button">+ Nueva tarea</button><span class="pkm-plan-nota">Se añade al final de <code>## Plan de estudio</code> y se abre para que la edites</span></div>`);

    /* ── Marcar desde la Home ──────────────────────────────────────────────
       El círculo de estado cicla pendiente → en progreso → hecha → pendiente
       y reescribe la línea del temario. Se usa `vault.process`, que lee y
       escribe de forma atómica: si tienes el temario abierto y editando, no
       se pisan los cambios. Al cerrar una tarea se le pone la fecha `✅`,
       igual que hace el plugin Tasks (tiene `setDoneDate` activado). */

    const CICLO = { " ": "/", "/": "x", x: " ", "-": " " };
    const SIMBOLO = { pendiente: " ", curso: "/", hecha: "x", cancelada: "-" };

    async function ciclarEstado(nLinea, estadoActual) {
      const archivo = app.metadataCache.getFirstLinkpathDest(TEMARIO, "");
      if (!archivo) return;
      const nuevo = CICLO[SIMBOLO[estadoActual]] ?? " ";
      const hoyISO = dv.luxon.DateTime.now().toFormat("yyyy-MM-dd");

      await app.vault.process(archivo, (contenido) => {
        const lineas = contenido.split("\n");
        let l = lineas[nLinea];
        if (!l || !/^\s*[-*]\s+\[.\]/.test(l)) return contenido;   // se movió: no tocar

        l = l.replace(/^(\s*[-*]\s+\[)(.)(\])/, `$1${nuevo}$3`);
        l = l.replace(/\s*✅\s*\d{4}-\d{2}-\d{2}/g, "");           // fecha previa fuera
        if (nuevo === "x") l = l.trimEnd() + " ✅ " + hoyISO;

        lineas[nLinea] = l;
        return lineas.join("\n");
      });
    }

    /* Pintado optimista. Dataview reconstruye el bloque en su propio ciclo
       (`refreshInterval`, 2500 ms por defecto), así que esperar a que vuelva
       hace que cada clic parezca colgado un par de segundos. Se repinta la
       fila en el acto, se escribe, y se pide a Dataview que refresque ya.
       Si la escritura falla, la fila vuelve a su estado anterior. */
    const CLASE = { pendiente: "pend", curso: "curso", hecha: "hecha", cancelada: "cancel" };
    const SIGUIENTE = { pendiente: "curso", curso: "hecha", hecha: "pendiente", cancelada: "pendiente" };

    for (const marca of seccion.querySelectorAll(".pkm-tarea-estado")) {
      marca.addEventListener("click", async (ev) => {
        ev.preventDefault();
        ev.stopPropagation();

        const fila = ev.currentTarget.closest(".pkm-tarea");
        const nLinea = Number(fila.dataset.linea);
        if (Number.isNaN(nLinea)) return;

        const previo = fila.dataset.estadoNombre;
        const nuevo = SIGUIENTE[previo] ?? "pendiente";
        const plazoEl = fila.querySelector(".pkm-tarea-plazo");
        const textoPrevio = plazoEl.textContent;

        fila.dataset.estadoNombre = nuevo;
        fila.dataset.estado = CLASE[nuevo];
        plazoEl.textContent =
          nuevo === "hecha" ? "hecha"
          : nuevo === "cancelada" ? "cancelada"
          : plazoEl.dataset.vivo || textoPrevio;

        try {
          await ciclarEstado(nLinea, previo);
          app.workspace.trigger("dataview:refresh-views");
        } catch (e) {
          fila.dataset.estadoNombre = previo;
          fila.dataset.estado = CLASE[previo];
          plazoEl.textContent = textoPrevio;
        }
      });
    }

    /* Nueva tarea: se inserta una plantilla al final de la sección y se abre
       el temario para rellenarla. Un formulario completo aquí sería más
       vistoso y bastante más frágil — esto deja el control en el editor. */
    seccion.querySelector(".pkm-btn")?.addEventListener("click", async () => {
      const archivo = app.metadataCache.getFirstLinkpathDest(TEMARIO, "");
      if (!archivo) return;
      const dentroDe = dv.luxon.DateTime.now().plus({ days: 7 }).toFormat("yyyy-MM-dd");
      const hoyISO = dv.luxon.DateTime.now().toFormat("yyyy-MM-dd");
      const PREFIJO = "- [ ] ";
      const PLACEHOLDER = "Tarea nueva";

      let lineaNueva = -1;
      await app.vault.process(archivo, (contenido) => {
        const lineas = contenido.split("\n");
        /* Última línea de tarea de la sección del plan. */
        let corte = lineas.length;
        let dentro = false;
        for (let i = 0; i < lineas.length; i++) {
          if (/^##\s+/.test(lineas[i])) dentro = lineas[i].toLowerCase().includes(SECCION_PLAN);
          else if (dentro && /^\s*[-*]\s+\[.\]/.test(lineas[i])) corte = i + 1;
        }
        lineaNueva = corte;
        lineas.splice(corte, 0,
          `${PREFIJO}${PLACEHOLDER} 🛫 ${hoyISO} 📅 ${dentroDe} [esfuerzo:: 4h]`);
        return lineas.join("\n");
      });

      /* Abrir por el ancla deja la nota en la sección; después se baja hasta
         la línea recién creada y se selecciona el placeholder, para poder
         escribir el título directamente sin buscar nada. */
      await app.workspace.openLinkText(TEMARIO + "#Plan de estudio", "", false);

      for (let intento = 0; intento < 12; intento++) {
        const editor = app.workspace.activeEditor?.editor;
        if (editor && editor.getLine(lineaNueva)?.includes(PLACEHOLDER)) {
          editor.setSelection(
            { line: lineaNueva, ch: PREFIJO.length },
            { line: lineaNueva, ch: PREFIJO.length + PLACEHOLDER.length });
          editor.scrollIntoView(
            { from: { line: lineaNueva, ch: 0 }, to: { line: lineaNueva, ch: 0 } }, true);
          editor.focus();
          break;
        }
        await new Promise((listo) => setTimeout(listo, 60));
      }
    });
  }

} catch (e) {
  dv.container.insertAdjacentHTML("beforeend", `
<div class="pkm-hero">
<div class="pkm-eyebrow">Segundo cerebro · seguridad ofensiva</div>
<h1 class="pkm-title">Todo lo que sé, a dos clics</h1>
<p class="pkm-tagline">Dataview no ha podido construir el panel: ${e.message}. Las áreas siguen accesibles desde el explorador y desde los .base.</p>
</div>`);
}
```

```dataviewjs
/* ══════════════════════════════════════════════════════════════════════════
   BLOQUE 2 · Buscador · Los 3 ejes del vault · Actividad y mantenimiento
   ══════════════════════════════════════════════════════════════════════════ */

const HOY = dv.luxon.DateTime.now();
const YO = dv.current().file.path;
const TEMARIO = "📋 Temario";

const esc = (s) => String(s).replace(/[&<>"]/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

/* Áreas raíz, para reagrupar cualquier nota por su carpeta de primer nivel. */
const RAICES = {
  "Red Team":  { nombre: "Red Team",   accent: "red",    base: "Red Team/Red-Team.base" },
  "Blue Team": { nombre: "Blue Team",  accent: "blue",   base: "Blue Team/Blue-Team.base" },
  "Redes":           { nombre: "Redes",      accent: "teal",   base: "Redes/Redes.base" },
  "Ingenieria":      { nombre: "Ingeniería", accent: "amber",  base: "Ingenieria/Ingenieria.base" },
  "02 - Recursos":   { nombre: "Recursos",   accent: "violet", base: "02 - Recursos/Recursos.base" },
};

/* Lee `Fecha de actualización` tolerando DateTime de luxon o texto suelto. */
function fechaDe(p) {
  const v = p["Fecha de actualización"];
  if (!v) return null;
  if (typeof v.diff === "function") return v;
  const d = dv.date(String(v));
  return d && d.isValid ? d : null;
}

const diasDesde = (p) => {
  const f = fechaDe(p);
  return f ? Math.round(HOY.diff(f, "days").days) : null;
};

const relativo = (d) =>
  d === null ? "sin fecha" : d <= 0 ? "hoy" : d === 1 ? "ayer" : "hace " + d + " días";

function panel(destino, { titulo, accent, nota, items, vacio, pie }) {
  const p = destino.createDiv({ cls: "pkm-panel" });
  p.dataset.accent = accent;

  const cab = p.createDiv({ cls: "pkm-panel-head" });
  cab.createSpan({ cls: "pkm-dot" });
  cab.createSpan({ text: titulo });
  if (nota) cab.createSpan({ cls: "pkm-panel-note", text: nota });

  const cuerpo = p.createDiv({ cls: "pkm-panel-body" });

  if (!items.length) {
    cuerpo.createDiv({ cls: "dataview-error-box", text: vacio || "Nada por aquí." });
    return p;
  }

  const ul = cuerpo.createEl("ul", { cls: "dataview" });
  for (const it of items) {
    const li = ul.createEl("li");
    li.createEl("a", {
      cls: "internal-link",
      text: it.texto,
      href: it.destino,
      attr: { "data-href": it.destino },
    });
    if (it.meta) li.createSpan({ cls: "pkm-panel-note", text: " · " + it.meta });
  }
  if (pie) cuerpo.createDiv({ cls: "dataview result-count", text: pie });
  return p;
}

try {
  /* ══ Buscador ═══════════════════════════════════════════════════════════
     Filtra en cliente sobre el índice ya cargado: no consulta nada al teclear. */

  const indice = dv.pages()
    .where((p) => p.file.path !== YO)
    .map((p) => ({
      n: p.file.name,
      d: String(p["Descripción"] ?? ""),
      ruta: p.file.path,
      carpeta: p.file.folder,
      k: (p.file.name + " " + (p["Descripción"] ?? "")).toLowerCase(),
    }))
    .array();

  const secB = dv.container.createDiv({ cls: "pkm-section" });
  secB.createDiv({ cls: "pkm-h", text: "Ir a una nota" });

  const caja = secB.createDiv({ cls: "pkm-search" });
  caja.insertAdjacentHTML("beforeend",
    '<span class="pkm-search-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg></span>');
  const input = caja.createEl("input", {
    attr: {
      type: "text",
      placeholder: "Buscar entre " + indice.length + " notas por nombre o descripción…",
      spellcheck: "false",
    },
  });
  const contador = caja.createSpan({ cls: "pkm-search-count" });
  const salida = secB.createDiv({ cls: "pkm-results" });

  /* Resalta el término encontrado sin permitir HTML del dato. */
  function resaltar(texto, termino) {
    const limpio = String(texto).replace(/[&<>"]/g, (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
    if (!termino) return limpio;
    const patron = termino.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return limpio.replace(new RegExp("(" + patron + ")", "gi"), "<mark>$1</mark>");
  }

  let temporizador;
  input.addEventListener("input", () => {
    clearTimeout(temporizador);
    temporizador = setTimeout(() => {
      const q = input.value.trim().toLowerCase();
      salida.empty();
      contador.setText("");
      if (q.length < 2) return;

      const hit = indice.filter((x) => x.k.includes(q));
      contador.setText(hit.length + (hit.length === 1 ? " nota" : " notas"));

      if (!hit.length) {
        salida.createDiv({ cls: "pkm-search-empty", text: "Ninguna nota coincide con «" + q + "»." });
        return;
      }
      /* Primero las que casan por nombre; dentro, el nombre más corto (más
         específico) antes que el largo. */
      hit.sort((a, b) => {
        const an = a.n.toLowerCase().includes(q), bn = b.n.toLowerCase().includes(q);
        if (an !== bn) return an ? -1 : 1;
        return a.n.length - b.n.length;
      });

      for (const x of hit.slice(0, 25)) {
        const a = salida.createEl("a", {
          cls: "internal-link pkm-result",
          href: x.ruta,
          attr: { "data-href": x.ruta },
        });
        a.insertAdjacentHTML("beforeend",
          '<span class="pkm-result-name">' + resaltar(x.n, q) + "</span>" +
          '<span class="pkm-result-desc">' + resaltar(x.d || x.carpeta, q) + "</span>");
      }
      if (hit.length > 25) {
        salida.createDiv({ cls: "pkm-search-empty", text: "…y " + (hit.length - 25) + " más. Afina la búsqueda." });
      }
    }, 90);
  });

  /* ══ Los ejes del vault ═════════════════════════════════════════════════
     Vistas transversales que atraviesan TODAS las áreas. Los tags `Tipo/*`
     NO se listan a mano: se descubren del índice de etiquetas, así que si
     mañana aparece un `Tipo/Laboratorio` sale su tarjeta sola. Lo de abajo
     solo pone título legible, color y criterio a los que ya existen; uno
     nuevo entra con su nombre crudo hasta que se le escriba la ficha. */

  const COLOR_EJE_LIBRE = ["amber", "teal", "green", "blue", "violet", "red"];
  const COLORES = ["red", "blue", "teal", "amber", "violet", "green"];

  /* Las fichas viven en la sección `## Ejes` de 📋 Temario, no aquí: así se
     configuran igual que las certificaciones, editando el temario.
     Formato por línea: `Tipo/Tag · Título · color · criterio`, con el color
     opcional. El criterio puede llevar `·`; solo se parten los dos o tres
     primeros separadores. */
  async function leerFichasEjes() {
    const fichas = {};
    const archivo = app.metadataCache.getFirstLinkpathDest(TEMARIO, "");
    if (!archivo) return fichas;

    const crudo = await app.vault.cachedRead(archivo);
    let dentro = false;
    for (const linea of crudo.split("\n")) {
      const encabezado = linea.match(/^##\s+(.+?)\s*$/);
      if (encabezado) { dentro = encabezado[1].trim().toLowerCase() === "ejes"; continue; }
      if (!dentro) continue;

      const item = linea.match(/^\s*[-*]\s+(.+)$/);
      if (!item) continue;
      const trozos = item[1].split("·").map((s) => s.trim());
      if (trozos.length < 2 || !/^tipo\//i.test(trozos[0])) continue;

      /* Si el tercer trozo es un color conocido, lo es; si no, es criterio. */
      const hayColor = trozos.length > 2 && COLORES.includes(trozos[2].toLowerCase());
      fichas[trozos[0]] = {
        titulo: trozos[1],
        accent: hayColor ? trozos[2].toLowerCase() : null,
        criterio: trozos.slice(hayColor ? 3 : 2).join(" · ").trim(),
      };
    }
    return fichas;
  }

  const FICHA_EJE = await leerFichasEjes();

  /* Todos los `Tipo/*` que existan de verdad en el vault, ordenados por
     volumen; los conocidos primero, en el orden en que están escritos. */
  const indiceTags = app.metadataCache.getTags();
  const tagsTipo = Object.keys(indiceTags)
    .map((t) => t.replace(/^#/, ""))
    /* `Tipo/Proyecto` queda fuera: no es un eje transversal del conocimiento
       (detección, arsenal…), sino el tipo de la nota-artefacto de portfolio, y
       tiene su propia sección «Proyectos ofensivos» más abajo. */
    .filter((t) => /^tipo\//i.test(t) && !/^tipo\/proyecto$/i.test(t));

  const conocidos = Object.keys(FICHA_EJE);
  tagsTipo.sort((a, b) => {
    const ia = conocidos.indexOf(a), ib = conocidos.indexOf(b);
    if (ia !== -1 && ib !== -1) return ia - ib;
    if (ia !== -1) return -1;
    if (ib !== -1) return 1;
    return a.localeCompare(b);
  });

  let colorLibre = 0;
  const EJES = tagsTipo.map((tag) => {
    const ficha = FICHA_EJE[tag];
    return {
      tag,
      titulo: ficha?.titulo || tag.split("/").pop(),
      accent: ficha?.accent || COLOR_EJE_LIBRE[colorLibre++ % COLOR_EJE_LIBRE.length],
      criterio: ficha?.criterio ||
        "Sin descripción todavía. Añade una línea en la sección «Ejes» de 📋 Temario.",
    };
  });

  /* Igual que en el plan: el enlace apunta al encabezado, así que abre
     directamente la sección donde se editan estas fichas. */
  const anclaEjes = TEMARIO + "#Ejes";
  const secE = dv.container.createDiv({ cls: "pkm-section" });
  secE.createDiv({
    cls: "pkm-h",
    text: "Los ejes del vault",
  }).insertAdjacentHTML("beforeend",
    '<span class="pkm-h-note">' + EJES.length +
    ' vistas transversales por el campo <code>Tipo/</code>, no por carpeta · edita en ' +
    '<a class="internal-link" href="' + esc(anclaEjes) + '" data-href="' + esc(anclaEjes) +
    '">las fichas</a></span>');

  const rejilla = secE.createDiv({ cls: "pkm-axes" });

  for (const eje of EJES) {
    const notas = dv.pages("#" + eje.tag);
    const porArea = {};
    for (const p of notas) {
      const raiz = p.file.folder.split("/")[0];
      porArea[raiz] = (porArea[raiz] || 0) + 1;
    }
    const filas = Object.entries(porArea)
      .filter(([k]) => RAICES[k])
      .sort((a, b) => b[1] - a[1]);
    const maximo = filas.length ? filas[0][1] : 1;

    const caja = rejilla.createDiv({ cls: "pkm-axis" });
    caja.dataset.accent = eje.accent;

    const cab = caja.createDiv({ cls: "pkm-axis-head" });
    cab.createSpan({ cls: "pkm-axis-title", text: eje.titulo });
    cab.createSpan({ cls: "pkm-axis-total", text: String(notas.length) });

    caja.createDiv({ cls: "pkm-axis-crit", text: eje.criterio });
    caja.createDiv({ cls: "pkm-axis-tag" }).insertAdjacentHTML("beforeend",
      "Etiqueta <code>#" + eje.tag + "</code>");

    const cuerpo = caja.createDiv({ cls: "pkm-axis-rows" });
    if (!filas.length) {
      cuerpo.createDiv({ cls: "pkm-search-empty", text: "Ninguna nota con esta etiqueta." });
    }
    for (const [carpeta, n] of filas) {
      const meta = RAICES[carpeta];
      const fila = cuerpo.createEl("a", {
        cls: "internal-link pkm-axis-row",
        href: meta.base,
        attr: { "data-href": meta.base, "data-accent": meta.accent },
      });
      fila.createSpan({ cls: "pkm-axis-name", text: meta.nombre });
      fila.createDiv({ cls: "pkm-axis-bar" })
        .createDiv({ cls: "pkm-axis-fill" })
        .setAttribute("style", "width:" + Math.round((n / maximo) * 100) + "%");
      fila.createSpan({ cls: "pkm-axis-n", text: String(n) });
    }
  }

  /* ══ Actividad y mantenimiento ═════════════════════════════════════════ */

  const sec2 = dv.container.createDiv({ cls: "pkm-section" });
  sec2.createDiv({ cls: "pkm-h", text: "Actividad y mantenimiento" });
  const cols2 = sec2.createDiv({ cls: "pkm-panels pkm-panels--3" });

  /* 1 · Lo último tocado */
  const recientes = dv.pages()
    .where((p) => fechaDe(p) !== null && p.file.path !== YO)
    .sort((p) => fechaDe(p).ts, "desc")
    .slice(0, 14)
    .map((p) => ({ texto: p.file.name, destino: p.file.path, meta: relativo(diasDesde(p)) }));

  panel(cols2, {
    titulo: "Lo último que toqué",
    accent: "violet",
    nota: "por Fecha de actualización",
    items: recientes,
    vacio: "Ninguna nota con Fecha de actualización.",
  });

  /* 2 · Deuda de frontmatter: viejas, sin fecha, sin Area, sin Descripción */
  const conFecha = dv.pages().where((p) => fechaDe(p) !== null);
  const viejas = conFecha.where((p) => diasDesde(p) > 180);
  const sinFecha = dv.pages().where((p) => fechaDe(p) === null && p.file.path !== YO);
  const sinArea = dv.pages().where((p) => !p.Area && p.file.path !== YO);
  const sinDesc = dv.pages().where((p) => p.Area && !p["Descripción"]);

  const deuda = [
    ...viejas.sort((p) => fechaDe(p).ts, "asc").slice(0, 8)
      .map((p) => ({ texto: p.file.name, destino: p.file.path, meta: diasDesde(p) + " días" })),
    ...sinFecha.slice(0, 8)
      .map((p) => ({ texto: p.file.name, destino: p.file.path, meta: "sin fecha" })),
  ];

  panel(cols2, {
    titulo: "Radar de deuda",
    accent: "amber",
    nota: viejas.length + " viejas · " + sinFecha.length + " sin fecha",
    items: deuda,
    vacio: "Sin deuda de frontmatter. Impecable.",
    pie: sinArea.length + " notas sin Area (fuera de todo .base) · " +
         sinDesc.length + " con Area pero sin Descripción",
  });

  /* 3 · Cadenas Zettelkasten rotas — los wikilinks rotos son silenciosos en
     Obsidian, así que nada los vigila salvo esto. */
  const rotas = [];
  for (const p of dv.pages()) {
    if (p.file.path === YO) continue;
    for (const campo of ["Nota previa", "Nota siguiente"]) {
      const v = p[campo];
      if (!v) continue;
      /* El valor puede llegar como Link de Dataview o como texto "[[X]]". */
      const crudo = typeof v === "object" && v.path ? v.path : String(v);
      const destino = crudo.replace(/^\[\[/, "").replace(/\]\]$/, "").split("|")[0].split("#")[0].trim();
      if (!destino) continue;
      if (!app.metadataCache.getFirstLinkpathDest(destino, p.file.path)) {
        rotas.push({
          texto: p.file.name,
          destino: p.file.path,
          meta: campo.replace("Nota ", "") + " → " + destino,
        });
      }
    }
  }

  panel(cols2, {
    titulo: "Cadenas rotas",
    accent: "red",
    nota: rotas.length + " enlace" + (rotas.length === 1 ? "" : "s"),
    items: rotas.slice(0, 16),
    vacio: "Ninguna cadena Zettelkasten rota. Las prev/next apuntan todas a notas reales.",
    pie: rotas.length > 16 ? "Se muestran 16 de " + rotas.length : null,
  });

} catch (e) {
  dv.container.createDiv({
    cls: "dataview-error-box",
    text: "No se han podido construir los paneles: " + e.message,
  });
}
```

```dataviewjs
/* ══════════════════════════════════════════════════════════════════════════
   BLOQUE 3 · Proyectos ofensivos · catálogo en Go, de más simple a capstone
   ---------------------------------------------------------------------------
   Lee las notas de `Red Team/Proyectos` (las que llevan `Dificultad`), las
   ordena por su número de fichero —que va de menor a mayor dificultad— y las
   pinta como filas con nivel, estado y esfuerzo. Todo sale del frontmatter; el
   mismo `.base` que las indexa es la única fuente. El color del rail y del
   badge sale del nivel (1 verde → 5 violeta).
   ══════════════════════════════════════════════════════════════════════════ */

const esc = (s) => String(s).replace(/[&<>"]/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

try {
  const YO = dv.current().file.path;
  const norm = (s) => String(s ?? "").trim().toLowerCase();

  /* Estado del frontmatter a una clave corta para el CSS. */
  const claseEstado = (e) => {
    const k = norm(e);
    if (k.includes("termin") || k.includes("hecho")) return "hecho";
    if (k.includes("curso") || k.includes("progreso")) return "curso";
    if (k.includes("descart") || k.includes("pausa")) return "descartado";
    return "idea";
  };

  const proyectos = dv.pages('"Red Team/Proyectos"')
    .where((p) => p.Dificultad != null && p.file.path !== YO)
    .sort((p) => p.file.name, "asc")
    .array();

  const sec = dv.container.createDiv({ cls: "pkm-section" });
  const baseHref = "Red Team/Proyectos/Proyectos ofensivos.base";
  sec.createDiv({ cls: "pkm-h", text: "Proyectos ofensivos" }).insertAdjacentHTML(
    "beforeend",
    `<span class="pkm-h-note">${proyectos.length} en Go, de más simple a capstone · ` +
    `<a class="internal-link" href="${esc(baseHref)}" data-href="${esc(baseHref)}">el catálogo</a></span>`);

  if (!proyectos.length) {
    sec.createDiv({ cls: "dataview-error-box", text: "Ningún proyecto indexado todavía." });
  } else {
    const cuenta = (f) => proyectos.filter(f).length;
    const kpi = (n, t, tono) =>
      `<div class="pkm-kpi" data-tono="${tono}"><span class="pkm-kpi-n">${n}</span><span class="pkm-kpi-t">${t}</span></div>`;

    const ideas = cuenta((p) => claseEstado(p.Estado) === "idea");
    const enCurso = cuenta((p) => claseEstado(p.Estado) === "curso");
    const hechos = cuenta((p) => claseEstado(p.Estado) === "hecho");

    sec.insertAdjacentHTML("beforeend", `<div class="pkm-kpis">
${kpi(proyectos.length, "proyectos", "info")}
${kpi(ideas, "en idea", "aviso")}
${kpi(enCurso, "en curso", "curso")}
${kpi(hechos, hechos === 1 ? "terminado" : "terminados", "ok")}
</div>`);

    const filas = proyectos.map((p) => {
      const m = p.file.name.match(/^(\d+)\s*-\s*(.+)$/);
      const num = m ? m[1] : "";
      const titulo = m ? m[2] : p.file.name;
      const dif = Number(p.Dificultad) || 0;
      const estado = String(p.Estado ?? "—");
      const ek = claseEstado(estado);
      const esf = p.Esfuerzo ? esc(String(p.Esfuerzo)) : "";
      const desc = p["Descripción"] ? esc(String(p["Descripción"])) : "";
      const pips = Array.from({ length: 5 }, (_, i) =>
        `<i class="pkm-pip${i < dif ? " on" : ""}"></i>`).join("");

      return `<a class="internal-link pkm-proj" data-dif="${dif}" data-estado="${ek}" href="${esc(p.file.path)}" data-href="${esc(p.file.path)}" aria-label="${esc(titulo)}">
<span class="pkm-proj-num">${esc(num)}</span>
<span class="pkm-proj-main">
<span class="pkm-proj-name">${esc(titulo)}</span>
${desc ? `<span class="pkm-proj-desc">${desc}</span>` : ""}
</span>
<span class="pkm-proj-side">
<span class="pkm-proj-pips" title="Dificultad ${dif}/5">${pips}</span>
<span class="pkm-proj-estado" data-e="${ek}">${esc(estado)}</span>
${esf ? `<span class="pkm-proj-esf">${esf}</span>` : ""}
</span>
</a>`;
    }).join("");

    sec.insertAdjacentHTML("beforeend", `<div class="pkm-projs">${filas}</div>`);
  }
} catch (e) {
  dv.container.createDiv({
    cls: "dataview-error-box",
    text: "No se ha podido construir el panel de proyectos: " + e.message,
  });
}
```

<div class="pkm-section"><div class="pkm-h">Accesos rápidos</div><div class="pkm-quick"><a class="internal-link pkm-chip" href="📋 Temario">📋 Temario</a><a class="internal-link pkm-chip" href="02 - Recursos/Templates/Template para proyectos.md">🧩 Plantilla de nota</a><a class="internal-link pkm-chip" href="02 - Recursos/Biblioteca/Librería.base">📖 Biblioteca</a><a class="internal-link pkm-chip" href="02 - Recursos/Decisiones estructurales/Decisiones estructurales.base">🏛️ Decisiones (ADR)</a><a class="internal-link pkm-chip" href="02 - Recursos/🛠️ Tools/Tools.base">🛠️ Herramientas</a><a class="internal-link pkm-chip" href="README">📄 README</a></div></div>
<div class="pkm-foot">Zettelkasten en español · términos técnicos en inglés · índices en <code>.base</code><br>Contenido propio bajo CC BY-NC-SA 4.0 · material de terceros con sus licencias</div>
