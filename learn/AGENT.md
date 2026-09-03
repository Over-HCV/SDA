# AGENT.md — SDA Lab (`learn/`)

Machine-facing notes. Human docs are in `README.md` (Spanish). All commands run
from the **repo root** (`SDA/`), never from `learn/`.

## Read these first, in this order

| File | What it gives you |
|---|---|
| `learn/MAPA.md` | index: artifact key → plot fn, logic fn, text file. **Start here** when asked about a result. |
| `learn/CONVENCIONES.md` | C1–C14, the enforceable rules |
| `learn/PLAN.md` | milestone checkboxes; tick `[x]` when you finish a section |
| `learn/SCHEMA.md` | full UI design, per-view |
| `libs/sdd.md` | repo-wide invariants S1–S8 this project inherits |

## Answering "why did I get this result?"

The user pastes a **context block** produced by the app. It looks like this:

```
### Contexto SDA Lab
clave    : f4.desempeno.roc
grafico  : learn/R/graficos/desempeno.R::graficar_roc
logica   : learn/R/logica/metricas_clasificacion.R::calcular_roc
texto    : learn/textos/f4/desempeno/roc.md
corrida  : c12 = dataset d3 x modelo m5 x receta r1
params   : {...}
metricas : {...}
json     : learn/outputs/c12.json
```

Procedure: read `logica` first (that is where the number comes from), then
`grafico` (how it is drawn), then `texto` (what the user was told). If a `json`
path is listed and exists, read it — it holds the full parameter set and the
seed.

If the user gives only a key, resolve it with:

```bash
Rscript -e 'source("learn/R/cargar.R"); cargar_sda(con_ui = FALSE); print(rutas_de("f4.desempeno.roc"))'
```

## Language rule (C1) — non-negotiable

Everything we write is Spanish, ASCII, `snake_case`: `graficar_roc()`,
`validar_compatibilidad()`, `semilla`. Library calls stay English. This makes
the boundary between our code and borrowed code readable at a glance.
Comments and UI strings are Spanish **with** accents; identifiers without.

Enforced by `learn/R/pruebas/verificar_idioma.R`.

## File size rule (C2)

Hard ceiling 300 LOC (comments and blank lines excluded), target 80–150.
One UI module per **subsection**, not per phase. Enforced by
`learn/R/pruebas/verificar_loc.R`.

## Loading the project

Never hand-roll a root finder. `learn/R/cargar.R` exposes:

- `sda_raiz()` — where `data/` lives
- `sda_base()` — where our `R/`, `textos/`, `fichas/`, `metodos/` live
  (differs between server and the wasm bundle)
- `ruta_app(...)`, `ruta_repo(...)`
- `cargar_sda(con_ui = TRUE)` — sources `nucleo/ → logica/ → graficos/ → ui/`
  then `metodos/`
- `cargar_librerias_ui()`

```r
source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)   # headless: no bslib, no DT
```

## Driving the lab from the console

`learn/R/lab.R` walks phase 1 without a browser. Prefer it over ad-hoc
`Rscript -e` snippets: it builds the same dataset object the app builds
(source + filter stack), so what you measure is what the app shows.

```bash
Rscript learn/R/lab.R                                   # list the commands
ORI="--fuente ori --filtro Hora=12:00"
Rscript learn/R/lab.R resumen Temperatura $ORI
Rscript learn/R/lab.R panel f1.analisis.histograma Temperatura $ORI
```

`panel` returns a PLOT AS A TABLE: it builds the registered ggplot for that
artefact key and prints `ggplot_build()` layers — bin edges and heights, box
whiskers, point coordinates — instead of drawing it. That is the read path for
anything that cannot look at an image.

## Commands

```bash
# Structural invariants
Rscript learn/R/pruebas/verificar_loc.R
Rscript learn/R/pruebas/verificar_idioma.R
Rscript learn/R/pruebas/verificar_mapa.R

# Logic + contracts, no GUI
Rscript learn/R/pruebas/test_headless.R

# Phase 1 logic and plots, no GUI
Rscript learn/R/pruebas/test_fase1.R

# The exportable notebook and the console CLI, no GUI
Rscript learn/R/pruebas/test_informe.R

# One file per implemented method, no GUI
Rscript learn/R/pruebas/test_acp.R
Rscript learn/R/pruebas/test_kmeans.R

# S2 output contract + the three-parts rule (C11), no GUI
Rscript learn/R/pruebas/test_contrato.R

# UI + browser console (mandatory, spec S2b). One driver per file:
#   test_app.R         shell + phase 1
#   test_app_piezas.R  the chrome every card shares: seal, formulas, sidebar
#   test_app_metodo.R  ACP walked through phases 2 -> 3 -> 4
#   test_app_kmeans.R  k-means, same walk, different family
Rscript learn/R/pruebas/test_app.R
Rscript learn/R/pruebas/test_app_piezas.R
Rscript learn/R/pruebas/test_app_metodo.R
Rscript learn/R/pruebas/test_app_kmeans.R

# Run a method outside the app: same JSON the UI produces (S2)
Rscript -e 'source("learn/R/run_headless.R"); correr("acp-twins")'
Rscript -e 'source("learn/R/run_headless.R");
            correr("acp-cov", hiper = list(matriz = "covarianza"))'
Rscript -e 'source("learn/R/run_headless.R");
            correr("kmeans-twins", metodo = "kmeans", hiper = list(k = 4L),
                   reinicios = 10L)'

# Interactive
Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'

# Regenerate the artifact index
Rscript learn/R/mapa.R

# Server deploy manifest (Posit Connect Cloud). Entry point is the ROOT app.R.
Rscript -e 'source("learn/manifiesto.R"); escribir_manifiesto()'

# wasm bundle
Rscript -e 'source("learn/build.R"); construir_bundle()'
python3 -m http.server 8000 --directory learn/docs
Rscript -e 'source("libs/_comun/R/pruebas_web.R"); verificar_html("http://localhost:8000")'
```

## Environment variables

| Variable | Values | Effect |
|---|---|---|
| `SDA_TEMA` | `flatly` (default), `darkly`, `cosmo`, `minty`, `vapor`, `retro`, `retro-dark` | initial bslib preset |
| `SDA_MODO` | `wasm`, `servidor` | force the mode; auto-detected from `R.version$platform` otherwise |
| `SDA_THEMER` | `1` | mount `bslib::bs_themer()` |

## Adding a method

Two worked examples, one per family: `acp` (reduction) and `kmeans`
(clustering). Copy whichever is closer — `learn/metodos/<clave>.R`, its row in
`learn/R/nucleo/catalogo/`, and `learn/R/pruebas/test_<clave>.R`.

The phase 2/3/4 UI is method-agnostic, and since Hito 4 that is enforced rather
than asserted: what a view draws comes from `metodo(clave)$artefactos` through
`panel_si_declara()`, and what it *says* comes from the S3 generics in
`R/logica/metricas.R`. A new method in an existing family needs no UI change; a
new **family** needs a `metricas_<familia>.R` with its S3 methods, and nothing
else.

1. Add a row in `learn/R/nucleo/catalogo/<macro-tema>.R` via
   `registrar_metodo()`, with `estado = "activo"` and `ajustar = <fn>`.
   Declare only the optimisers you actually implemented.
2. Write the pure fit function in `learn/metodos/<clave>.R` — no `input`,
   no `reactive`, no `session`. It is sourced **last** by `cargar.R`, so the
   registration call must stay in `catalogo/`, never in `metodos/`.
   Iterative optimisers record their trace with `R/logica/traza.R`; that is
   what makes phase 3 show anything. Return the list with
   `class = c("ajuste_<clave>", "ajuste_sda")` — without it the phase-4 views
   fail loudly, which is the point.
3. Answer the generics of `R/logica/metricas.R` for the family, in
   `R/logica/metricas_<familia>.R`. If the family already exists, this step is
   free.
4. Write `learn/fichas/<clave>.md`.
5. Register each plot it produces with `registrar_artefacto()` and write its
   text in `learn/textos/<fase>/<subseccion>/<artefacto>.md` — the path
   `ruta_texto_de()` derives from the key (`f1.analisis.histograma` →
   `textos/f1/analisis/histograma.md`).
6. Three-parts rule (C11): every hyperparameter exists in the pure function,
   in `correr()` of `run_headless.R` including its `params` block, **and** as a
   UI input. Miss one and app and batch diverge silently. Controls that only
   some families have (`inicializacion`, `reinicios`, `matriz`) are filtered by
   `argumentos_ajuste()`, so `do.call` never sees an argument the method does
   not take.
7. `Rscript learn/R/mapa.R` to refresh `MAPA.md`.
8. Both harnesses green, including a new `test_app_<clave>.R`.

## Known traps

Every one of these was hit while building Hito 1. They cost real time.

### Bundle / shinylive

- **Staging must live OUTSIDE the repo.** `shinylive::export()` resolves the
  package list with `renv::dependencies(appdir)`, and renv honours
  `.gitignore`. With the staging in `learn/.build/` — matched by the root
  `.gitignore` rule `.build/` — the scan returned **zero** packages, the bundle
  shipped with none, and webR died with a wall of
  `preload error: Downloading webR package: ...`. Export stayed green
  throughout. `stage_por_defecto()` now points at `tempdir()`, and
  `verificar_dependencias()` fails loudly if the scan comes up short.
- **The scan only sees the app-dir root.** A one-line `app.R` wrapper hides
  every `library()` call in `R/`. `learn/app.R` therefore declares the runtime
  packages explicitly — those calls are load-bearing, not decoration.
- **`shinylive::export()` skips dotfiles.** The root marker is `sda-raiz`, no
  leading dot; `.sda-raiz` silently never travelled.
- **shinylive renders the app inside an `<iframe>`.** `document.querySelectorAll`
  on the top document always returns 0. `verificar_bundle.R` walks
  `iframe.contentDocument` (same-origin, so it is reachable).
- **`Page.loadEventFired` times out on webR.** Tens of MB download before
  `load` fires, past chromote's 60 s cap in `verificar_html()`. Poll the DOM
  instead — "the app painted" is the honest signal anyway.
- **The wrapper needs `$value`**: `source("R/app.R")$value`, or the bundle dies
  with "app.R did not return a shiny.appobj".
- **The bundle only contains the staged directory.** `data/`, `libs/_comun/`
  and the root marker must be copied in, or the root finder walks to `/`.
- **`twins.csv` used to live only in `workshops/twins/`.** It is now also in
  `data/` (the deploy mirror needs it there), and `twins_path()` probes both.
  Keep them in sync or drop the workshop copy.
- **`rsconnect::writeManifest(".")` reads `renv.lock` and ships all 111
  packages.** The lockfile is repo-wide (S3). `learn/manifiesto.R` builds a
  mirror without a lockfile so dependencies are inferred from the code that the
  app actually loads — 60 with transitive deps instead of 111.
- **Connect Cloud needs `manifest.json` at the repo root**, and its `Primary
  file` is the root `app.R`, not `learn/R/app.R`. Regenerate the manifest
  whenever the app's `library()` calls change.
- **`font_google()` hangs in webR** (needs network and a disk cache). Use
  `tema_seguro()` from `R/nucleo/tema_app.R`, never `tema()` directly.

### Shiny

- **Outputs on a hidden tab are suspended.** After `set_inputs(seccion = ...)`
  the panel's outputs render on a later cycle that `set_inputs()` does not wait
  for. `test_app.R` polls with `esperar_html()`.
- **`AppDriver$new()` calls `skip_on_cran()`.** Outside testthat that aborts
  with "Reason: On CRAN". Set `NOT_CRAN=true`.
- **Load order matters for top-level constants.** `ui/piezas` is sourced before
  the rest of `ui/` because modules reference `ETIQUETA_ANALISIS` at file
  scope. `.sourcear_arbol()` de-duplicates, so listing a path twice is safe.
- **Do not build a whole sidebar with `renderUI`.** Hito 2 started with the
  phase-1 sidebar re-rendered per subsection. The HTML appeared in the DOM but
  Shiny never re-bound it: `input$clases` stayed NULL forever, `set_inputs()`
  answered *"Unable to find input binding"*, and **the browser console was
  clean** — the exact silent client-side failure S2b is about. The fix is the
  boring one: build every control once, show them with `conditionalPanel(ns =
  ns)`, and fill their choices with `update*Input()` when the dataset changes.
  `renderUI` is fine for text-only fragments (notices, badges, legends).
- **`layout_sidebar(height = ...)` squashes every plot in the tab.** A fixed
  height turns the body into a *fill* container: `navset_card_tab` and its
  cards then SHARE those pixels instead of growing. With three
  `panel_resultado()` in one tab each `plotOutput` got a few dozen pixels and
  R's device aborted with `figure margins too large` — worse in tabs with more
  cards, which is why it looked random. Bound the **sidebar** instead
  (`ESTILO_CONTROLES` in `ui/piezas/fase.R`: sticky + `max-height` +
  `overflow-y`) and pass `fillable = FALSE`.
- **Duplicate input ids fail quietly.** `modelado-estado` existed twice: the
  catalogue's state filter and the phase's status bar. Shiny prints
  "HTML id values are not unique" and keeps going at half speed, with
  `input$estado` returning whatever. Grep the module's `ns(...)` calls before
  adding an output named like a common input.
- **`names(list())` is NULL, not `character(0)`.** `almacen_ids()` returned it
  straight, and a selector filled with `setNames(NULL, ...)` threw "attempt to
  set an attribute on NULL" inside an observer — on startup, with an empty
  store, before anything was visible.
- **Wait for what you are about to touch.** `esperar_html()` on a sidebar label
  returns immediately: sidebar controls are in the DOM even when their tab is
  hidden. Wait for a string produced by the *output* you are asserting on, or
  the assertion reads a half-rendered page.
- **A label in the DOM is not a bound control.** `esperar_html()` returning does
  not mean `set_inputs()` will find the widget; bindings attach a cycle later.
  `ir_a_pestana()` in `test_app.R` waits for the pattern **and** for
  `wait_for_idle()`.

### Content

- **LaTeX in `textos/` and `fichas/` is written as LaTeX.** `$...$` and
  `$$...$$`. `R/nucleo/formulas.R` pulls the formulas out before commonmark
  —which eats the `\\` of a matrix row and reads `_` as emphasis— and vendored
  KaTeX paints them client-side. A formula inside a ``` fence is a formatting
  error. See C6 and the C10 exception.
- **A card title in the DOM proves nothing.** `page_navbar` keeps all four
  phases in the DOM, and `conditionalPanel` hides rather than removes. Two
  consequences for browser tests: wait for a string that only the view you are
  about to touch produces (waiting for "inercia" matches the phase-3 log), and
  assert visibility through the flag output (`bandera_artefacto()`), never
  through the presence of the text.
- **A `selectInput`'s choices are not in the DOM.** selectize keeps them in
  JavaScript and leaves only the selected `<option>`. Assert on
  `get_value(input = ...)`, or headless on the function that produces the
  labels.
- **Clean render + HTTP 200 proves nothing.** `libs/sdd.md` S2b lists four bugs
  that passed both and only showed up in the browser console or the error DOM.
  Assertions must be positive, not just absence-of-errors.
- **No hand-written JavaScript** (C10). R cannot test it.
