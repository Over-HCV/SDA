# AGENT.md — projects/__SLUG__/ (English, machine-targeted)

> Terse English for machines. Spanish prose for humans is in `README.md`.
> **TODO**: fill every TODO before considering this project done.

## What

TODO — one sentence: method, package, dataset. Row __FILA__ of
`libs/topics-map.md`.

## Where

- Project root: `/Users/oh/World/External/Study/UR/SDA/` (run all commands here)
- App code: `projects/__SLUG__/R/*.R`
- Outputs: `projects/__SLUG__/outputs/`
- Shared: `libs/_comun/R/{datos,metricas,temas,temas_bslib,pruebas}.R`

## Architecture invariants (do not violate)

1. **Pure logic only in `modelo.R`** — no `reactive`, no `input`, no `session`.
2. **UI files (`app.R`, `mod_main.R`) only wire inputs to modelo functions.**
3. **3-place rule.** A new hyperparameter X must be added in all three:
   the fit function in `modelo.R`, `correr()` in `run_headless.R` (including
   its `params` list), and an input in `mod_main.R`. Otherwise app and batch
   diverge silently.
4. **Max 300 LOC per file.**
5. **Identifiers are Spanish ASCII** (no accents/ñ). Comments may have accents.

## The four canonical commands

```bash
# 1. INTERACTIVE
Rscript -e 'shiny::runApp("projects/__SLUG__/R/app.R", launch.browser=TRUE)'

# 2. HEADLESS
Rscript -e 'source("projects/__SLUG__/R/run_headless.R"); correr("demo")'

# 3. DEBUG
SDA_THEMER=1 Rscript -e 'shiny::runApp("projects/__SLUG__/R/app.R", launch.browser=TRUE)'

# 4. TEST
Rscript projects/__SLUG__/R/test_headless.R
Rscript projects/__SLUG__/R/test_app.R
```

## `correr()` parameters

TODO — table of every argument, its default, and what it does.

| arg | default | notes |
|---|---|---|
| `grado` | `2` | TODO replace |
| `n` | `120` | TODO replace |
| `semilla` | `42` | fix any randomness, or results aren't reproducible |

## JSON schema (S2)

```json
{
  "timestamp": "...", "proyecto": "__SLUG__", "escenario": "<name>",
  "params":   { "...": "..." },
  "metricas": { "r2": 0.0, "rmse": 0.0, "n": 0 },
  "archivos": { "plot": "<abs png>", "datos": "<abs csv>" },
  "notas":    "..."
}
```

`correr()` also writes a second artifact `<esc>-diagnostico` (secondary plot,
no CSV).

## Topic invariants the tests assert

TODO — the properties that MUST hold if the method is implemented correctly.
This is what separates a useful test from a generic smoke test.

Examples from `projects/01-lasso`:
- Higher `lambda` ⇒ strictly fewer non-zero coefficients.
- `alpha = 0` (ridge) ⇒ shrinks but never zeroes.
- `lambda_1se >= lambda_min`.

## Data gotchas

TODO — anything about the dataset that will bite: missing-value coding,
encoding, leakage risks, degenerate columns.

## Common gotchas

See `libs/shiny/AGENT.md` for the project-wide list. The ones that bite most:

- **R has no partial application.** `x |> (if (c) f("a", 1) else identity)()`
  evaluates `f("a", 1)` first. Use a temp variable and explicit `if/else`.
- **`conditionalPanel` takes the BARE id when you pass `ns =`.** Writing
  `sprintf("input.%s", ns("x"))` yields `input.main-x`, which JS parses as
  subtraction → `ReferenceError`, and the panel silently never shows.
- **ionRangeSlider CSS loads after the bslib theme** — slider rules in custom
  SCSS need `!important`.
- **`shinytest2` needs `NOT_CRAN=true`** under `Rscript` (test files set it).
- **Never put `.shiny-text-output` in theme SCSS** — it also matches
  `textOutput` inside `value_box()`, and a background rule there makes the
  value invisible.

## What to read first when iterating

1. `libs/topics-map.md` — your row, and the routing convention.
2. `libs/sdd.md` — global spec + per-project definition of done.
3. `projects/01-lasso/` — the reference instance of this template.
4. `projects/__SLUG__/R/modelo.R` — pure logic.
