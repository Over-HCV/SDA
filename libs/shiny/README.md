# Proyecto 1 — Shiny · Regresión sobre charcoal

App Shiny interactiva para explorar ajustes polinomiales (y loess) sobre la
producción de carbón vegetal por país y año. **Hook pedagógico**: cada slider
dispara un `lm()` real en el servidor de R → muestra cuándo hace falta un
backend en vez de un HTML estático.

Es el **Proyecto 1** de los 3 motores de interactividad del curso AED (UR).
Diseño conforme al plan SDD en `libs/sdd.md`.

---

## Estructura

```
libs/shiny/
├── R/
│   ├── datos.R            # adaptador: bootstrap_comun(), series_pais(), leer_csv_usuario()
│   ├── modelo.R           # lógica PURA: ajustar_modelo(), graficar_ajuste(), diagnosticos()
│   ├── mod_ajuste.R       # UI + server del tab "Ajuste" (inputs + plot principal)
│   ├── mod_diagnostico.R  # tab "Diagnósticos" (4 plots en grid + tabla)
│   ├── mod_datos.R        # tab "Datos" (DT + brush)
│   ├── mod_resumen.R      # tab "Resumen" (summary + coeficientes)
│   ├── run_headless.R     # entrada para el agente (sin GUI)
│   └── app.R              # cableado: page_navbar + módulos + theme switcher
├── outputs/               # artefactos de corridas headless (no versionar)
├── README.md              # este archivo
└── AGENT.md               # instrucciones para agente LLM (inglés)
```

Regla del plan S1: ningún `.R` > 300 LOC; aquí el mayor es `mod_ajuste.R` con
~260 (UI + server del módulo más denso). La lógica de negocio (`modelo.R`)
nunca toca `input` ni `reactive`.

---

## Cómo correrlo

> ⚠️ Todo se ejecuta **desde la raíz del proyecto** (`SDA/`), donde está `.Rprofile`
> que activa `renv` y arrastra los paquetes correctos.

### Modo interactivo (vos, en VS Code o terminal)

```bash
# desde la raíz SDA/
Rscript -e 'shiny::runApp("libs/shiny/R/app.R", launch.browser = TRUE)'
```

Esto abre el navegador en `http://127.0.0.1:<puerto>` con la app. Con
`options(shiny.autoreload = TRUE)` (seteado en `.Rprofile`), editar y guardar
cualquier `.R` en `libs/shiny/R/` recarga la app automáticamente.

### Modo headless (el agente, o vos desde la terminal)

```bash
# desde la raíz SDA/
Rscript -e 'source("libs/shiny/R/run_headless.R");
            correr("demo-colombia", pais="Colombia", flujo="Production", grado=3)'
```

Esto escribe en `libs/shiny/outputs/`:
- `demo-colombia.png` (plot del ajuste)
- `demo-colombia.json` (params + métricas + paths, schema S2)
- `demo-colombia.csv` (datos con predicciones y residuales)
- `demo-colombia-diagnosticos.png` (panel 2×2 de diagnósticos)
- `run_log.csv` (append: `timestamp,proyecto,escenario,params_json,metrica_principal,plot`)

Otros ejemplos:

```r
correr("brasil-grado5", pais="Brazil", grado=5)
correr("argentina-loess", pais="Argentina", metodo="loess")
correr("rango-corto", pais="Colombia", anio_min=2005, anio_max=2020, grado=2)
```

Ver `AGENT.md` para el catálogo completo de parámetros y el contrato JSON.

---

## Qué cubre (showcase de componentes Shiny)

Esta app demuestra deliberadamente todos los componentes principales de
Shiny + bslib. Útil como referencia para el curso.

### UI (bslib)

| Componente | Dónde |
|---|---|
| `page_navbar`, `nav_panel`, `nav_spacer`, `nav_menu`, `nav_item` | `app.R` |
| `page_sidebar`, `sidebar` | `mod_ajuste.R` |
| `card`, `card_header`, `card_body`, `full_screen = TRUE` | todos los módulos |
| `layout_columns`, `layout_column_wrap` | `mod_ajuste.R`, `mod_datos.R` |
| `value_box` (R², RMSE, n) | `mod_ajuste.R` |
| `accordion`, `accordion_panel` | `mod_ajuste.R` |
| `popover`, `tooltip`, `bsicons::bs_icon` | `mod_ajuste.R`, `app.R` |
| `navset_card_tab` | `mod_diagnostico.R`, `mod_resumen.R` |
| `bs_theme` con `bootswatch` switcher en runtime | `app.R` (Flatly/Darkly/Cosmo/Minty/Vapor) |

### Inputs

`selectizeInput` (país, server-side), `selectInput` (flujo),
`sliderInput` (grado), `sliderInput` range (años, con `debounce` 200ms),
`numericInput` (semilla), `radioButtons` (método lm/loess),
`checkboxInput` (log_y, auto-recalc), `checkboxGroupInput` (qué diagnósticos
mostrar), `fileInput` (CSV propio), `actionButton` (refit manual, guardar),
`downloadButton` (exportar datos), `actionLink` (cambio de tema).

### Reactivos

`reactive` (datos, ajuste), `eventReactive` (refit manual), `observeEvent`
(guardar, theme switch, file upload), `reactiveVal` (CSV subido),
`debounce` (rango de años), `reactiveValuesToList` (bookmarking).

### Outputs interactivos

`plotOutput` con `brush` + `click` + `hover`, `brushedPoints` (del paquete
shiny), `DT::dataTableOutput` (filtrable, ordenable), `verbatimTextOutput`
(summary del modelo), `textOutput` (value boxes), `renderUI`/`uiOutput`
(grid dinámico de diagnósticos, hover tooltip).

### UI dinámica

`conditionalPanel` (grado solo en modo lm), `updateSelectizeInput`,
`updateSelectInput`, `updateSliderInput` (grado máximo según n),
`renderUI`/`uiOutput` (grid de diagnósticos según checkboxes).

### Extras

- **Bookmarking** (`enableBookmarking = "server"`): el estado se guarda al
  cambiar de tab y se restaura vía URL.
- **`showNotification`**: feedback al guardar, subir CSV, cambiar tema.
- **`withProgress`**: spinner en el refit manual.
- **Módulos** (`moduleServer`): cada tab es un módulo desacoplado que
  consume un `reactiveValues` compartido (`estado`).

---

## Galería de componentes (menú "Galería")

Además de los 4 tabs de análisis, la app trae un menú **Galería** con 6 tabs
que no hacen estadística: son el catálogo visual de Shiny + bslib bajo el tema
activo. Es la referencia para armar proyectos nuevos.

| Tab | Qué muestra | Archivo |
|---|---|---|
| Inputs | un ejemplar de cada input + sus valores enlazados en vivo | `gal_inputs.R` |
| Cards | `value_box`, `card`, `layout_columns`, `accordion`, `sidebar` | `gal_layout.R` |
| Plots | `plotOutput` con brush/click/hover y qué devuelve cada uno | `gal_plots.R` |
| Tablas | DT (filtro, selección, `formatRound`, `formatStyle`) + cross-filter | `gal_tablas.R` |
| Notificaciones | notificaciones, progreso, modales, `validate()`, `tryCatch()` | `gal_feedback.R` |
| Tipografía | escala de texto, roles de color, y las variables Sass del tema activo | `gal_tipografia.R` |

---

## Temas y personalización (bslib)

Los presets viven en `libs/_comun/R/temas_bslib.R`. `listar_temas()` devuelve:

`flatly`, `darkly`, `cosmo`, `minty`, `vapor`, **`retro`**, **`retro-dark`**

Los dos últimos son el look 8-bit tipo NES: `font_google("Press Start 2P")`,
bordes de 4px sin redondeo, sombras duras, sliders cuadrados. Se construyen
combinando variables Sass con reglas propias, igual que el ejemplo de la
[viñeta de theming de bslib](https://rstudio.github.io/bslib/articles/theming/index.html):

```r
bs_theme(
  bg = "#e5e5e5", fg = "#0d0c0c", primary = "#dd2020",
  base_font = font_google("Press Start 2P"),
  code_font = font_google("Press Start 2P"),
  "font-size-base" = "0.75rem", "enable-rounded" = FALSE
) |>
  bs_add_rules(list(
    sass::sass_file("libs/_comun/scss/retro.scss"),
    sass::sass_file("libs/_comun/scss/custom.scss")
  ))
```

Arrancar con un preset:

```bash
SDA_TEMA=retro Rscript -e 'shiny::runApp("libs/shiny/R/app.R", launch.browser = TRUE)'
```

### Diseñar un tema propio

```bash
SDA_THEMER=1 Rscript -e 'shiny::runApp("libs/shiny/R/app.R", launch.browser = TRUE)'
```

Eso monta el widget **Theme customizer** (`bs_themer()`). Movés colores,
fuentes y espaciado en vivo, y el widget **imprime en la consola de R** el
`bs_theme()` equivalente. El flujo es:

1. Ajustás en el widget (mirá el tab **Galería > Tipografía** para ver el
   efecto sobre todos los componentes a la vez).
2. Copiás el código que imprime la consola.
3. Lo pegás como preset nuevo en `libs/_comun/R/temas_bslib.R`.
4. El CSS fino que Sass no cubre va en `libs/_comun/scss/custom.scss`.

Un preset nuevo aparece solo en el menú **Tema** de todas las apps: el
switcher se genera recorriendo `listar_temas()`.

> `cambiar_tema()` reconstruye el preset **completo**, no usa
> `bs_theme_update()`. Si no, las fuentes y reglas Sass del preset anterior
> quedan pegadas al cambiar de tema.

---

## Depuración y tests

```bash
# Modo debug: stack traces completos, reactlog (Ctrl+F3), bs_themer
Rscript -e 'source("libs/shiny/R/run_debug.R")'

# Regresión de la lógica pura + contrato S2
Rscript libs/shiny/R/test_headless.R

# Regresión de la UI: recorre todos los tabs, falla si hay error de JS
Rscript libs/shiny/R/test_app.R
SDA_TEMA=retro Rscript libs/shiny/R/test_app.R   # el preset que más CSS pisa
```

Los dos harness son necesarios: `test_headless.R` no puede ver errores del
lado del cliente. Un `conditionalPanel` mal escrito deja el servidor contento
y la app en HTTP 200, con la feature muerta en silencio; solo los logs del
navegador lo delatan.

---

## Flujo del módulo principal

```
   inputs (pais, flujo, años, grado, método, semilla)
                │
                ▼
        datos() reactive  ──── si hay CSV subido, lo usa en vez de charcoal
                │
                ▼
        ajuste() reactive  ──►  ajustar_modelo() en modelo.R (función PURA)
                │                  │
                │                  ├─► graficar_ajuste() → renderPlot
                │                  ├─► diagnosticos()    → mod_diagnostico
                │                  ├─► formatear_resumen → mod_resumen
                │                  └─► value boxes (R², RMSE, n)
                │
                └─► estado$ajuste exportado a los otros 3 módulos

        input$guardar  ──►  escribir_salida() en libs/_comun/R/metricas.R
                              → outputs/*.png, *.json, *.csv, run_log.csv
```

---

## Dependencias

Las maneja `renv` desde la raíz del proyecto. Principales:

- `shiny` (1.14), `bslib` (0.12), `bsicons` (0.1)
- `ggplot2` (4.0), `patchwork` (1.3) para paneles de diagnósticos
- `DT` (0.34) para tablas interactivas
- `dplyr` (1.2) para filtrado (vía `_comun`)

`renv::status()` desde la raíz del proyecto debe estar limpio. Si no,
`renv::restore()` sincroniza.

---

## Problemas conocidos

- **`bs_icon()` no está en bslib**: se mudó a `bsicons` en bslib 0.9. Usamos
  `bsicons::bs_icon("nombre")` explícitamente.
- **`page_navbar(bg=...)` deprecado**: usar `navbar_options = navbar_options(bg=..., type=...)`.
- **thematic + httpgd son incompatibles**: thematic no soporta el device
  `unigd` que usa httpgd. Por eso `thematic_on()` NO va en `.Rprofile`; cada
  app lo activaría dentro de `renderPlot()` si lo necesita (esta no).
- **`shiny.autoreload` legacy warning**: instalar `watcher` (`install.packages("watcher")`)
  elimina el warning sobre file watcher. Opcional.

---

## Siguiente

- `libs/quarto/` — Proyecto 2 (PCA + clustering, dashboard OJS estático)
- `libs/shiny-live/` — Proyecto 3 (ANOVA, Shiny corriendo en webR)
