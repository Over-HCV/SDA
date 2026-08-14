# AGENT.md — libs/shiny/ (English, machine-targeted)

> Reference for any coding agent working on this project. Spanish prose is
> for humans in `README.md`; this file is terse English for machines.

## What

Shiny app demonstrating polynomial/loess regression on FAO charcoal panel
data (`data/charcoal.csv`). Showcase of all major Shiny + bslib components.
Project 1 of 3 (see `libs/sdd.md`).

## Where

- Project root: `/Users/oh/World/External/Study/UR/SDA/` (run all commands here)
- App code: `libs/shiny/R/*.R`
- Headless entry: `libs/shiny/R/run_headless.R`
- Outputs: `libs/shiny/outputs/` (gitignored conceptually; created on first run)
- Shared logic: `libs/_comun/R/{datos,metricas,temas}.R`

## Architecture invariants (do not violate)

1. **Pure logic only in `modelo.R`** — no `reactive`, no `input`, no `session`.
   Functions take plain values and return plain lists/data.frames.
2. **UI files (`app.R`, `mod_*.R`) only wire inputs to modelo functions.**
3. **Every interactive function has a batch mirror.** If you add a slider
   for parameter X, also add X as an argument to `ajustar_modelo()` AND to
   `correr()` in `run_headless.R`.
4. **Max 300 LOC per file.** Split if growing past 250.
5. **Identifiers are Spanish ASCII** (no accents/ñ): `ajustar_modelo`, not
   `ajustar_modeló`. Comments and string literals may have accents.

## Headless commands (your primary way to "see" results)

From the project root:

```bash
# Default: Colombia / Production / degree 3
Rscript -e 'source("libs/shiny/R/run_headless.R"); correr("demo-colombia")'

# Specific params
Rscript -e 'source("libs/shiny/R/run_headless.R");
            correr("brasil-g5", pais="Brazil", flujo="Production",
                   grado=5, metodo="lm", anio_min=1995, anio_max=2020,
                   semilla=42)'

# loess instead of polynomial
Rscript -e 'source("libs/shiny/R/run_headless.R");
            correr("arg-loess", pais="Argentina", metodo="loess")'
```

**Outputs land in `libs/shiny/outputs/<scenario>.{png,json,csv}` plus an
append to `run_log.csv`.**

### JSON schema (the agent's source of truth)

```json
{
  "timestamp": "2026-08-12T22:40:19-0500",
  "proyecto":  "shiny",
  "escenario": "<scenario name>",
  "params":    { "pais": "...", "flujo": "...", "grado": 3,
                 "metodo": "lm"|"loess", "anio_min": 1990, "anio_max": 2020,
                 "log_y": false, "semilla": 42 },
  "metricas":  { "r2": 0.8197, "rmse": 95.6064, "n": 30 },
  "archivos":  { "plot": "<abs path to png>", "datos": "<abs path to csv>" },
  "notas":     "Ajuste <metodo> grado <g> sobre charcoal (<pais>/<flujo>)"
}
```

### run_log.csv schema (append-only history)

```
timestamp, proyecto, escenario, params_json, metrica_principal, plot
```

Inspect with:

```bash
cat libs/shiny/outputs/run_log.csv
# or in R: source("libs/_comun/R/metricas.R"); leer_run_log("libs/shiny/outputs")
```

## The four canonical commands

All from the project root. These are the whole loop — prefer them over ad-hoc invocations.

```bash
# 1. INTERACTIVE — the real app
Rscript -e 'shiny::runApp("libs/shiny/R/app.R", launch.browser=TRUE)'

# 2. HEADLESS — one scenario, writes artifacts you can read
Rscript -e 'source("libs/shiny/R/run_headless.R"); correr("demo-colombia")'

# 3. DEBUG — same app, full stack traces + reactlog + bs_themer widget
Rscript -e 'source("libs/shiny/R/run_debug.R")'

# 4. TEST — regression gate, exits non-zero on failure
Rscript libs/shiny/R/test_headless.R   # pure logic + S2 artifact contract
Rscript libs/shiny/R/test_app.R        # UI smoke: every tab, browser console
```

Env vars honored by `app.R` / `run_debug.R`:

| var | default | effect |
|---|---|---|
| `SDA_TEMA` | `flatly` | initial preset; see `listar_temas()` in `_comun/R/temas_bslib.R` |
| `SDA_THEMER` | `0` (`1` in debug) | mount the `bs_themer()` live theming widget |
| `SDA_PORT` | `4568` | port for `run_debug.R` |

Run the UI smoke against the retro preset too — it overrides the most CSS
and breaks first:

```bash
SDA_TEMA=retro Rscript libs/shiny/R/test_app.R
```

### Why `test_app.R` exists

`test_headless.R` cannot see client-side breakage. A malformed
`conditionalPanel` condition throws a JS `ReferenceError` that leaves the
server happy, HTTP 200, and the feature silently dead. Only
`app$get_logs()` surfaces it. Any bug in the "feature quietly stopped
working" class needs command 4b, not 4a.

## Verifying the app runs (manual, lower level)

```bash
# Quick: source-based smoke test (UI builds without errors)
Rscript -e 'source("libs/shiny/R/app.R", local=TRUE); cat("OK\n")'

# Full: start the server and check HTTP
Rscript -e 'shiny::runApp("libs/shiny/R/app.R", port=4567,
                          launch.browser=FALSE, host="127.0.0.1")' &
sleep 12
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4567/  # expect 200
kill %1
```

Note: HTTP 200 only proves the UI **built**. It says nothing about whether
outputs render. Use `test_app.R` for that.

## Adding a new parameter (3-place rule)

If you add e.g. a `peso` hyperparameter:

1. **`libs/shiny/R/modelo.R`** — add `peso = ...` argument to `ajustar_modelo()`.
2. **`libs/shiny/R/run_headless.R`** — add `peso = ...` argument to `correr()`,
   forward it to `ajustar_modelo()`, and include it in the `params` list of
   `escribir_salida()`.
3. **`libs/shiny/R/mod_ajuste.R`** — add an input (`sliderInput`, etc.) and
   pass it to `ajustar_modelo()` inside the reactive.

Otherwise logic and UI desync.

## Common gotchas

- `bs_icon()` → use `bsicons::bs_icon()` (moved out of bslib in 0.9).
- `page_navbar(bg=...)` → use `navbar_options = navbar_options(bg=...)`.
- patchwork operators (`|`, `/`, `&`) require `library(patchwork)`, not
  just installation.
- `renv` activation depends on `.Rprofile` at project root — don't move it.
- `DT::datatable(...) |> DT::formatRound(...)` works on R ≥ 4.1.
- `confint()` on loess fits throws → guarded with `tryCatch`.
- **R has no partial application.** `x |> (if (c) DT::formatRound("col", 3) else identity)()`
  does NOT curry: `formatRound("col", 3)` evaluates first with `table="col"`
  and dies with `Invalid table argument`. Use a temp variable and an explicit
  `if/else` returning the table.
- **`conditionalPanel` conditions take the BARE id when you pass `ns =`.**
  `sprintf("input.%s == 'lm'", ns("metodo"))` produces `input.ajuste-metodo`,
  which JS parses as *subtraction* → `ReferenceError: metodo is not defined`,
  and the panel never shows. Write `condition = "input.metodo == 'lm'", ns = ns`
  and let `conditionalPanel` rewrite it to `input['ajuste-metodo']`.
- **ionRangeSlider CSS loads after the bslib theme.** Slider rules in a custom
  `.scss` need `!important` or the default blue wins. Only that block needs it;
  Bootstrap classes compile with the theme normally.
- `shinytest2` aborts under `Rscript` with `Reason: On CRAN` unless
  `NOT_CRAN=true` is set (`test_app.R` sets it itself).

## What to read first when iterating

1. `libs/sdd.md` — global spec.
2. `libs/shiny/README.md` — component showcase table.
3. `libs/shiny/R/modelo.R` — pure logic, ~170 LOC.
4. `libs/shiny/R/mod_ajuste.R` — main UI module, ~260 LOC.
