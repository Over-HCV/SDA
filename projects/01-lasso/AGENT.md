# AGENT.md — projects/01-lasso/ (English, machine-targeted)

> Terse English for machines. Spanish prose for humans is in `README.md`.

## What

Shiny app for LASSO / ridge / elastic-net variable selection (`glmnet`) on
`data/twins.csv`. Row 23 of `libs/topics-map.md`. Reference instance of
`projects/_template/`.

## Where

- Project root: `/Users/oh/World/External/Study/UR/SDA/` (run all commands here)
- App code: `projects/01-lasso/R/*.R`
- Outputs: `projects/01-lasso/outputs/`
- Shared: `libs/_comun/R/{datos,metricas,temas,temas_bslib,pruebas}.R`

## Architecture invariants (do not violate)

1. **Pure logic only in `modelo.R`** — no `reactive`, no `input`, no `session`.
2. **UI files (`app.R`, `mod_main.R`) only wire inputs to modelo functions.**
3. **3-place rule.** A new hyperparameter X must be added in all three:
   `correr_lasso()` in `modelo.R`, `correr()` in `run_headless.R` (including
   its `params` list), and an input in `mod_main.R`. Otherwise app and batch
   diverge silently.
4. **Max 300 LOC per file.**
5. **Identifiers are Spanish ASCII** (no accents/ñ). Comments may have accents.

## The four canonical commands

```bash
# 1. INTERACTIVE
Rscript -e 'shiny::runApp("projects/01-lasso/R/app.R", launch.browser=TRUE)'

# 2. HEADLESS
Rscript -e 'source("projects/01-lasso/R/run_headless.R"); correr("lasso-base", alpha=1)'

# 3. DEBUG  (reuses Project 1's debug entrypoint pattern)
SDA_THEMER=1 Rscript -e 'shiny::runApp("projects/01-lasso/R/app.R", launch.browser=TRUE)'

# 4. TEST
Rscript projects/01-lasso/R/test_headless.R   # logic + S2 contract
Rscript projects/01-lasso/R/test_app.R        # UI + slider behavior
```

## `correr()` parameters

| arg | default | notes |
|---|---|---|
| `y_var` | `"DLHRWAGE"` | response |
| `x_vars` | `LASSO_X_DEFECTO` (13) | `NULL` → default set |
| `alpha` | `1` | 1 = LASSO, 0 = ridge, in between = elastic net |
| `lambda` | `NULL` | `NULL` → use `cv.glmnet`'s `lambda.1se` |
| `nfolds` | `10` | CV folds |
| `semilla` | `42` | CV folds are random; without it, not reproducible |
| `estandarizar` | `TRUE` | passed to `glmnet(standardize=)` |

## JSON schema (S2)

```json
{
  "timestamp": "2026-08-13T00:27:09-0500",
  "proyecto":  "01-lasso",
  "escenario": "<name>",
  "params":    { "y_var": "DLHRWAGE", "x_vars": "DEDUC1,DEDUC2,...",
                 "alpha": 1, "lambda": "cv.1se"|<number>,
                 "nfolds": 10, "semilla": 42, "estandarizar": true },
  "metricas":  { "r2": 0.2314, "rmse": 0.5094, "cv_error": 0.2856,
                 "no_cero": 4, "lambda_usado": 0.08125,
                 "lambda_min": 0.00871, "lambda_1se": 0.08125,
                 "n": 147, "p": 13 },
  "archivos":  { "plot": "<abs png>", "datos": "<abs csv>" },
  "notas":     "..."
}
```

`correr()` writes a **second** artifact `<esc>-regularizacion` (coefficient
path + CV curve panel, no CSV).

## Topic invariants the tests assert

These are the checks a generic smoke test cannot produce. Keep them green:

- Higher `lambda` ⇒ strictly fewer non-zero coefficients.
- `lambda = 0.5` ⇒ `no_cero == 0` (intercept only).
- `alpha = 0` (ridge) ⇒ `no_cero == p` (ridge shrinks, never zeroes).
- `lambda_1se >= lambda_min`.
- Default predictors ⇒ `n == 147`, `p == 13`.

## Data gotchas

- `twins.csv` codes missing as `"."` and carries a UTF-8 BOM. Always load via
  `cargar_twins()` in `libs/_comun/R/datos.R`, never `read.csv` directly.
- `DLHRWAGE` has 34 NAs. `correr_lasso()` drops incomplete cases **on the
  columns actually used**, not on the whole frame — so `n` changes with
  `x_vars`. `n_completos()` in `datos.R` predicts it for the UI.
- Never add `HRWAGEH` / `HRWAGEL` to `x_vars` in examples: they construct the
  response (leakage).
- Zero-variance predictors are dropped automatically and reported in
  `res$descartados`.

## Common gotchas

- `glmnet` needs a numeric **matrix**, no NAs, ≥2 columns with variance.
- The lambda slider is `log10(lambda)`; `mod_main.R` converts with `10^`.
  glmnet's grid is logarithmic — a linear slider wastes most of its travel.
- The slider is `debounce`d 250 ms; without it every intermediate pixel
  triggers a `cv.glmnet`.
- `R2` under regularization is descriptive only. Report `cv_error`.
- See `libs/shiny/AGENT.md` for the project-wide gotchas (partial application,
  `conditionalPanel` namespacing, ionRangeSlider CSS, `NOT_CRAN`).

## What to read first when iterating

1. `libs/topics-map.md` — row 23, and the routing convention.
2. `libs/sdd.md` — global spec + per-project definition of done.
3. `projects/01-lasso/R/modelo.R` — pure logic.
4. `projects/01-lasso/R/mod_main.R` — reactivity.
