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
grafico  : learn/graficos/g_desempeno.R::graficar_roc()
logica   : learn/logica/metricas_clasificacion.R::metricas_clasificacion()
texto    : learn/textos/f4.desempeno.roc.md
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

# UI + browser console (mandatory, spec S2b)
Rscript learn/R/pruebas/test_app.R

# Interactive
Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'

# Regenerate the artifact index
Rscript learn/R/mapa.R

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

1. Add a row in `learn/R/nucleo/catalogo.R` via `registrar_metodo()`.
2. Write the pure fit function in `learn/metodos/<clave>.R` — no `input`,
   no `reactive`, no `session`.
3. Write `learn/fichas/<clave>.md`.
4. Register each plot it produces with `registrar_artefacto()` and write its
   text in `learn/textos/<fase>/<subseccion>/<artefacto>.md` — the path
   `ruta_texto_de()` derives from the key (`f1.analisis.histograma` →
   `textos/f1/analisis/histograma.md`).
5. Three-parts rule (C11): every hyperparameter exists in the pure function,
   in `correr()` of `run_headless.R` including its `params` block, **and** as a
   UI input. Miss one and app and batch diverge silently.
6. `Rscript learn/R/mapa.R` to refresh `MAPA.md`.
7. Both harnesses green.

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
- **`data/twins.csv` does not exist at the repo root**; it is at
  `workshops/twins/twins.csv`. Since Hito 2 `twins_path()` in
  `libs/_comun/R/datos.R` probes both locations, and `libs/shiny-live/build.R`
  copies it by name instead of hard-coding `data/`.
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
- **A label in the DOM is not a bound control.** `esperar_html()` returning does
  not mean `set_inputs()` will find the widget; bindings attach a cycle later.
  `ir_a_pestana()` in `test_app.R` waits for the pattern **and** for
  `wait_for_idle()`.

### Content

- **No LaTeX in `textos/` or `fichas/`.** `commonmark` does not render math and
  MathJax would need network plus hand-written JS (C10 forbids it). Use Unicode
  and code blocks, like `notes/tree.md`.
- **Clean render + HTTP 200 proves nothing.** `libs/sdd.md` S2b lists four bugs
  that passed both and only showed up in the browser console or the error DOM.
  Assertions must be positive, not just absence-of-errors.
- **No hand-written JavaScript** (C10). R cannot test it.
