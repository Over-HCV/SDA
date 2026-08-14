# AGENT.md — libs/shiny-live/ (English, machine-targeted)

> Reference for any coding agent working on this project. Spanish prose is
> for humans in `README.md`; this file is terse English for machines.

## What

Shiny app demonstrating one-way ANOVA + distribution diagnostics, runnable
**in the browser via webR** (WebAssembly, no R server) through
`shinylive::export()`. Three switchable datasets: `twins` (wage by education
level), `charcoal` (production by region), `sintetico` (controlled demo).
Project 3 of 3 (see `libs/sdd.md`). Same modular architecture as Project 1.

## Where

- Project root: `/Users/oh/World/External/Study/UR/SDA/` (run all commands here)
- App code: `libs/shiny-live/R/*.R`
- Root wrapper (required by `shinylive::export()`): `libs/shiny-live/app.R`
- Headless entry: `libs/shiny-live/R/run_headless.R`
- Outputs: `libs/shiny-live/outputs/` (created on first run)
- Exported bundle: `libs/shiny-live/docs/` (do NOT version-control)
- Shared logic: `libs/_comun/R/{datos,metricas,temas}.R`

## Architecture invariants (do not violate)

1. **Pure logic only in `modelo.R`** — no `reactive`, no `input`, no `session`.
2. **UI files (`app.R`, `mod_*.R`) only wire inputs to modelo functions.**
3. **Max 300 LOC per file.** Split if growing past 250.
4. **Identifiers are Spanish ASCII** (no accents/ñ): `correr_anova`, not
   `correr_ánova`. Comments and string literals may have accents.
5. **webR-bundleable deps only**: `shiny`, `bslib`, `ggplot2`, `DT`, `stats`.
   Do NOT use `broom`, `car`, `pwr`, `moments` — they may not be bundled.
   Levene / skewness / kurtosis / power are implemented by hand in `modelo.R`.
6. **No Google Fonts** in `bs_theme()` (they fail/timewait in the webR bundle).

## Headless commands (your primary way to "see" results)

From the project root:

```bash
# Default scenario (twins)
Rscript -e 'source("libs/shiny-live/R/run_headless.R"); correr("demo-twins")'

# Charcoal (production by region, year 2019)
Rscript -e 'source("libs/shiny-live/R/run_headless.R");
            correr("demo-charcoal", dataset="charcoal")'

# Synthetic with a large effect
Rscript -e 'source("libs/shiny-live/R/run_headless.R");
            correr("demo-sint", dataset="sintetico", efecto=12, k_grupos=5)'
```

Outputs land in `libs/shiny-live/outputs/<scenario>.{png,json,csv}` plus
`<scenario>-qq.png` and an append to `run_log.csv`.

### JSON schema (the agent's source of truth)

```json
{
  "timestamp": "2026-08-12T23:33:55-0500",
  "proyecto":  "shiny-live",
  "escenario": "<scenario name>",
  "params":    { "dataset": "twins", "flujo": "Production", "anio": 2019,
                 "k_grupos": 4, "n_por_grupo": 30, "efecto": 5, "ruido": 1,
                 "semilla": 42, "balanceado": true },
  "metricas":  { "F": 1.2949, "p": 0.2771, "shapiro_p": 2.787e-19,
                 "levene_p": 0.6367, "n": 147, "grupos": 3 },
  "archivos":  { "plot": "<abs path to png>", "datos": "<abs path to csv>" },
  "notas":     "ANOVA one-way sobre dataset twins (147 obs, 3 grupos)"
}
```

### run_log.csv schema (append-only history)

```
timestamp, proyecto, escenario, params_json, metrica_principal, plot
```

## Verifying the app runs

```bash
# (1) Syntax check every R file
for f in libs/shiny-live/R/*.R libs/shiny-live/app.R; do
  Rscript -e "invisible(parse('$f')); cat('$f OK\n')"
done

# (2) UI builds without errors
Rscript -e 'source("libs/shiny-live/R/app.R", local=TRUE); cat("OK\n")'

# (3) Headless produces S2 artifacts
Rscript -e 'source("libs/shiny-live/R/run_headless.R"); correr("demo-twins")'
cat libs/shiny-live/outputs/demo-twins.json

# (4) Native R server returns HTTP 200
Rscript -e 'shiny::runApp("libs/shiny-live/R/app.R", port=4568,
                          launch.browser=FALSE, host="127.0.0.1")' &
sleep 12
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4568/  # expect 200
kill %1

# (5) shinylive export + static serve (slow the first time: downloads webR)
# ALWAYS via build.R — never shinylive::export() on the source dir (see below)
Rscript -e 'source("libs/shiny-live/build.R"); construir_bundle()'
python3 -m http.server 8000 --directory libs/shiny-live/docs &
sleep 3
curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8000/   # expect 200
kill %1

# (6) No file > 300 LOC
wc -l libs/shiny-live/R/*.R libs/shiny-live/app.R
```

## Adding a new parameter (3-place rule)

If you add e.g. a `peso` hyperparameter:

1. **`modelo.R`** — add `peso = ...` to `correr_anova()` (or the relevant fn).
2. **`run_headless.R`** — add `peso = ...` to `correr()`, forward it, include
   it in the `params` of `escribir_salida()`.
3. **`mod_anova.R`** — add an input and pass it through the `datos_anova()`
   call (or the reactive that builds the result).

Otherwise logic and UI desync.

## Country → region mapping

`asignar_region()` in `datos.R` maps the ~190 countries of charcoal.csv into
8 regions (África, América del Norte, América del Sur, América Central,
Caribe, Europa, Asia, Oceanía). Variants like "(former)" map to their
historical region; anything unrecognized falls back to `"Otros"`. To extend,
edit the `.paises_region` list at the top of `datos.R`.

## Common gotchas

- **`shinylive::export()`** requires an `app.R` at the **root** of the
  exported dir — that's why `libs/shiny-live/app.R` is a 1-line wrapper that
  sources `R/app.R`.
- **Never export the source dir directly.** The bundle only carries files
  inside the exported dir, and the bootstrap in `R/app.R` walks up for
  `data/charcoal.csv` then sources `libs/_comun/R/*.R`. Exporting
  `libs/shiny-live` leaves both out → in webR the walk reaches `/` and the app
  dies at source time (this bug shipped once). `build.R` stages
  `.build/{app.R, R/, libs/_comun/R/, data/}` — a mini project root — and
  exports that, excluding `run_headless.R`, `outputs/` and the `.md` files.
- **Bundle inventory**: `construir_bundle()` prints every file in `app.json`
  and hard-fails if `data/` or `libs/_comun/` are missing. Trust that list, not
  the fact that `docs/` exists.
- **`font_google()` in `bs_theme()` breaks the webR bundle** — omit it; rely
  on `bootswatch` defaults.
- **`broom::tidy()` on `aov`** may not be bundled — `modelo.R` extracts F/p/df
  via `summary(fit)[[1]][["Pr(>F)"]][1]` instead.
- **Levene by hand**: ANOVA of `abs(valor - median_grupo)` ~ grupo.
- **Power by simulation**: `potencia_simulada()` runs `N_sim` ANOVAs per grid
  cell — keep `N_sim` modest in webR (it's ~2-5× slower than native R).
- **Bookmarking** (`enableBookmarking = "server"`) only works under
  `shiny::runApp()`; the exported static bundle has no server to persist state.
  `R/app.R` disables it when `R.version$os == "emscripten"` (`.es_webr`).

## Bugs found by running the exported bundle (do not reintroduce)

All five were invisible until the bundle was actually driven in a browser;
four of them also affected the native app.

1. **Root wrapper must return the appobj**: `app.R` ends in
   `source("R/app.R")$value`. Without `$value`, shiny reports
   *"app.R did not return a shiny.appobj object"*.
2. **Module dir is layout-dependent**: `R/app.R` resolves `.dir_app` by
   probing (`<raiz>/libs/shiny-live/R` in the dev tree, `<raiz>/R` in the
   bundle). Hardcoding either path breaks the other.
3. **`conditionalPanel(condition=, ns=)` takes the UNNAMESPACED id**:
   `"input.dataset == 'charcoal'"`. Using `ns("dataset")` emits
   `input.anova-dataset`, which JS parses as a subtraction →
   *"ReferenceError: dataset is not defined"* and the panel never shows.
4. **`bs_icon(size=)` needs a CSS unit** (`"3rem"`); `"xl"` throws in
   `validateCssUnit()` and kills the render.
5. **`cargar_twins` collides with `_comun`**: `_comun/R/datos.R` now defines
   `cargar_twins(completos, vars)`. Ours is `cargar_twins_sl()` because
   `bootstrap_comun()` may re-source `_comun` *after* this file and would
   otherwise shadow it (*"unused argument (complete_cases = TRUE)"*).
   Check for name collisions with `_comun` before adding a function.
6. **Don't populate inputs with `updateSelectInput` at server init in webR** —
   the flujo select stayed empty. `mod_anova_ui` calls `flujos_charcoal()`
   (memoized, in `datos.R`) so the choices exist in the initial UI.
   Related: `<<-` inside `tryCatch({...})` assigns in the *parent* env, not
   the module frame — that was how `.flujos` silently stayed `NULL`.

## What to read first when iterating

1. `libs/sdd.md` — global spec.
2. `libs/shiny-live/BRIEF.md` — original spec for this project.
3. `libs/shiny-live/R/modelo.R` — pure ANOVA logic + hand-rolled tests (~205 LOC).
4. `libs/shiny-live/R/mod_anova.R` — main UI module (~190 LOC).
5. `libs/shiny/R/` — Project 1, the reference pattern this mirrors.
