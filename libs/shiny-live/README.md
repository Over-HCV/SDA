# Proyecto 3 — shinylive · ANOVA + distribuciones (R corriendo en el navegador)

App Shiny que demuestra **shinylive**: la misma app de Shiny corre en el
navegador vía **webR** (R compilado a WebAssembly), **sin servidor de R**.
El hook pedagógico es un artefacto de enseñanza **portable**: un URL y R
corre en cualquier máquina, cero instalación.

Es el **Proyecto 3** de los 3 motores de interactividad del curso AED (UR).
Diseño conforme al plan SDD en `libs/sdd.md`. Reutiliza la arquitectura
modular del Proyecto 1 (`libs/shiny/`).

---

## Qué hace

ANOVA one-way sobre **3 datasets alternables** desde la UI:

| Dataset | Variable respuesta | Factor de agrupación | Pregunta |
|---|---|---|---|
| **Twins** | `HRWAGEL` (salario/hora) | Nivel educativo (`EDUCL` categorizado) | ¿Difiere el salario por nivel educativo? |
| **Charcoal** | `Quantity` (producción) | Región del país (8 regiones) | ¿Difiere la producción por región? |
| **Sintético** | valor generado | `k_grupos` | Demo controlable para enseñar potencia |

Además:
- QQ-plot + histograma de residuales con métricas de forma (asimetría,
  curtosis) y **Shapiro** (normalidad) y **Levene/Bartlett** (homocedasticidad),
  ambos **Levene y skewness/kurtosis implementados a mano** (sin `car` ni
  `moments`, que pueden no estar bundled en webR).
- **Heatmap de potencia simulada** (sustituye a `pwr::pwr.anova.test`): para
  una grilla de (n, efecto) corre N_sim ANOVAs y cuenta la fracción con p<0.05.
- Exclusión interactiva de outliers arrastrando sobre el boxplot.

---

## Estructura

```
libs/shiny-live/
├── app.R                  # wrapper: source("R/app.R") — requerido por shinylive::export()
├── R/
│   ├── datos.R            # cargar_twins, categorizar_educ, asignar_region (8 regiones), datos_anova
│   ├── modelo.R           # correr_anova, graficar_{qq,boxplot,hist}, potencia_simulada (TODO a mano)
│   ├── mod_anova.R        # tab ANOVA: inputs + value boxes + boxplot con brush
│   ├── mod_distribucion.R # tab Distribución: QQ + hist + tabla métricas
│   ├── mod_potencia.R     # tab Potencia: heatmap simulado con withProgress
│   ├── mod_resumen.R      # tab Resumen: summary(aov) + DT tests
│   ├── app.R              # cableado: page_navbar + theme switcher + modal webR
│   └── run_headless.R     # correr(escenario, ...) -> outputs S2 (sin GUI)
├── build.R                # staging + shinylive::export() -> docs/ (ver §2)
├── docs/                  # bundle shinylive exportado (NO versionar)
├── .build/                # staging del export (NO versionar, lo crea build.R)
├── outputs/               # artefactos de corridas headless (se crea solo)
├── README.md              # este archivo
├── AGENT.md               # instrucciones para agente LLM (inglés)
└── BRIEF.md               # especificación original
```

Regla S1: ningún `.R` > 300 LOC; aquí el mayor es `mod_anova.R` (~190). La
lógica de negocio (`modelo.R`) nunca toca `input` ni `reactive`.

---

## Cómo correrlo

> Todo se ejecuta desde la **raíz del proyecto** (`SDA/`), donde está `.Rprofile`
> que activa `renv`.

### 1. Modo interactivo en R nativo (desarrollo)

```bash
Rscript -e 'shiny::runApp("libs/shiny-live/R/app.R", launch.browser = TRUE)'
```

### 2. Modo artefacto portable (el valor único de este proyecto)

Exportar a un bundle estático y servirlo con cualquier servidor HTTP:

```bash
# (1) Exportar — la primera vez descarga webR y puede tardar varios minutos
Rscript -e 'source("libs/shiny-live/build.R"); construir_bundle()'

# (2) Servir
python3 -m http.server 8000 --directory libs/shiny-live/docs
```

> **No uses `shinylive::export("libs/shiny-live", ...)` directo.** El bundle
> solo incluye lo que hay dentro del directorio exportado, y la app arranca
> buscando `data/charcoal.csv` hacia arriba para luego sourcear
> `libs/_comun/R/*.R`. Exportando el directorio tal cual, ni `data/` ni
> `_comun/` viajan: en webR el root-finder llega a `/` y la app muere al
> sourcearse. `build.R` arma un staging (`.build/`) con `data/` +
> `libs/_comun/` adentro y exporta desde ahí; además deja fuera del bundle
> `run_headless.R`, `outputs/` y los `.md`.

Abrir `http://localhost:8000/` en el navegador. webR inicializa en
**~10–30s la primera vez** (descarga R + paquetes); luego queda cacheado.
Mientras tanto, la app muestra un modal "Inicializando webR…".

> También podés publicar `docs/` en GitHub Pages, Netlify, o cualquier
> hosting estático. Es solo HTML + JS + WASM.

### 3. Modo headless (el agente, o vos desde la terminal)

```bash
Rscript -e 'source("libs/shiny-live/R/run_headless.R");
            correr("demo-twins", dataset = "twins")'
Rscript -e 'source("libs/shiny-live/R/run_headless.R");
            correr("demo-charcoal", dataset = "charcoal")'
```

Esto escribe en `libs/shiny-live/outputs/`:
- `<escenario>.png` (boxplot), `<escenario>-qq.png` (QQ de residuales)
- `<escenario>.json` (params + métricas + paths, schema S2)
- `<escenario>.csv` (datos)
- `run_log.csv` (append con schema fija)

---

## Limitaciones de webR (y cómo se manifiestan)

webR corre R en el navegador vía WebAssembly. Implicaciones:

1. **Carga asíncrona inicial**: la primera visita descarga R + paquetes
   (~10–30s). Se muestra un modal `showModal()` que se quita cuando el primer
   resultado está listo.
2. **Paquetes limitados a los bundled**. Por eso **solo** dependemos de
   `shiny`, `bslib`, `ggplot2`, `DT`, `stats`. **No usamos** `broom`, `car`,
   `pwr`, `moments`:
   - Levene → implementado a mano (ANOVA de desviaciones absolutas a la mediana).
   - Skewness/kurtosis → fórmulas directas de Fisher/Pearson.
   - Potencia → simulación (N_sim ANOVAs, cuenta p<0.05).
3. **Sin I/O nativo**: `fileInput` requiere `webr::shim_*`. Esta app no usa
   uploads (los datasets vienen embebidos en el bundle).
4. **Cálculos ~2–5× más lentos** que R nativo. La simulación de potencia lo
   nota: por eso N_sim por defecto es bajo (30) y hay un `withProgress`.
5. **bslib sin Google Fonts**: las fuentes externas tardan o fallan en el
   bundle. Usamos `bs_theme(bootswatch = "flatly")` sin `base_font`.
6. **Bookmarking no funciona** en el artefacto exportado (no hay servidor
   que persista el estado). `enableBookmarking = "server"` queda activado y
   solo es operativo bajo `shiny::runApp()` tradicional.

---

## Showcase de componentes (cubre lo mismo que `libs/shiny/`)

**UI (bslib)**: `page_navbar`, `nav_panel`, `nav_spacer`, `nav_menu`,
`nav_item`, `page_sidebar`, `sidebar`, `card`, `card_header`, `card_body`,
`full_screen`, `value_box`, `layout_columns`, `layout_column_wrap`,
`accordion`, `accordion_panel`, `navset_card_tab`, `bs_theme` con switcher
`bootswatch` en runtime (Flatly / Darkly / Cosmo).

**Inputs**: `radioButtons` (dataset), `selectInput` (flujo), `sliderInput`
(año, k, n, efecto, ruido), `numericInput` (semilla, N_sim, ruido),
`checkboxInput` (balanceado), `checkboxGroupInput` (opciones de boxplot),
`actionButton` (regenerar, calcular potencia, limpiar),
`downloadButton` (exportar datos).

**Reactivos**: `reactive` (datos, resultado), `eventReactive` (potencia),
`observeEvent` (brush, regenerar, theme, limpiar), `reactiveVal` (filtro de
outliers), `brushedPoints` (QQ → DT).

**Outputs**: `plotOutput` con `brush`/`dblclick`, `verbatimTextOutput`
(summary + métricas), `DT::dataTableOutput` (tests, medias, selección),
`textOutput` (value boxes), `showModal`/`removeModal` (carga webR),
`showNotification`, `withProgress`, `moduleServer`.

---

## Dependencias

Solo paquetes bundled-ables en webR: `shiny`, `bslib`, `bsicons`, `ggplot2`,
`DT`. Más `shinylive` (para exportar, no para correr) y `jsonlite` (headless).
Gestionadas por `renv` desde la raíz del proyecto.

---

## Verificado en navegador

Bundle ejecutado con webR (R 4.6.0 wasm32) el 2026-08-13:

| Comprobación | Resultado |
|---|---|
| webR inicializa y el modal se cierra | sí |
| Twins | F = 1.29, p = 0.2771, n = 147 (igual que `outputs/demo-twins.json`) |
| Charcoal (Production, 2019) | F = 2.72, n = 148, 31 flujos en el selector |
| Sintético | F = 1151.09, n = 120, sliders k/n/efecto/ruido activos |
| Distribución | QQ + histograma + métricas (asimetría 4.99, curtosis 31.75) |
| Resumen | `summary(aov)` + tabla DT con los 3 tests |
| Potencia | heatmap 55 celdas × 10 reps con `withProgress` |
| Errores en consola | ninguno (solo el aviso de canal `PostMessage`) |

## Problemas conocidos

- **`shinylive::export()` tarda la primera vez**: descarga webR. Paciencia.
- **`cargar_twins_sl()` lleva sufijo a propósito**: `_comun/R/datos.R` define
  otro `cargar_twins()` con firma distinta y puede re-sourcearse después.
- **El heatmap de potencia satura en 1.00** con el ruido por defecto (sd = 1):
  para que se vea la transición hay que subir *Ruido (sd)* a 4–5.
- **América del Norte queda con 1 país** (United States) en charcoal 2019:
  Canada/Mexico no están en el dataset FAO. Es un buen ejemplo de grupo
  pequeño en ANOVA desbalanceado.
- **Bookmarking**: ver limitación 6 arriba.

## Siguiente

- `libs/shiny/` — Proyecto 1 (regresión, Shiny clásico con servidor)
- `libs/quarto/` — Proyecto 2 (PCA + clustering, dashboard OJS estático)
