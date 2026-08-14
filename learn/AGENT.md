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
4. Register each plot it produces with `registrar_artefacto()` and write
   `learn/textos/<clave-artefacto>.md`.
5. Three-parts rule (C11): every hyperparameter exists in the pure function,
   in `correr()` of `run_headless.R` including its `params` block, **and** as a
   UI input. Miss one and app and batch diverge silently.
6. `Rscript learn/R/mapa.R` to refresh `MAPA.md`.
7. Both harnesses green.

## Known traps

- **`data/twins.csv` does not exist at the repo root.** The file is at
  `workshops/twins/twins.csv`. `libs/shiny-live/build.R` still lists it in
  `.DATOS` and will fail. `learn/build.R` must resolve twins from the
  workshops path or the bundle staging breaks.
- **shinylive wrapper needs `$value`**: `source("R/app.R")$value`. Without it
  the bundle dies with "app.R did not return a shiny.appobj".
- **The exported bundle only contains what is inside the staged directory.**
  `data/` and `libs/_comun/` must be copied into the staging root or the root
  finder walks to `/` and the app dies in webR.
- **Clean render + HTTP 200 proves nothing.** `libs/sdd.md` S2b lists four bugs
  that passed both and only showed up in the browser console or the error DOM.
  Assertions must be positive (expected content present), not just
  absence-of-errors.
- **No hand-written JavaScript** (C10). R cannot test it.
