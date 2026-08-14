# AGENT.md — libs/quarto/ (English, machine-targeted)

> Reference for any coding agent working on this project. Spanish prose is
> for humans in `README.md`; this file is terse English for machines.

## What

Quarto dashboard (static HTML) showing PCA + k-means on two datasets
(`charcoal`, `twins`). Computation precomputed in R; browser-only filter /
rescale / recolor via Observable JS. Project 2 of 3 (see `libs/sdd.md`).

## Where

- Project root: `/Users/oh/World/External/Study/UR/SDA/` (run all commands here)
- Project code: `libs/quarto/R/*.R`, `libs/quarto/dashboard.qmd`
- Headless entry: `libs/quarto/R/run_headless.R`
- Outputs dir: `libs/quarto/outputs/` (created on first run, gitignored)
- Shared logic: `libs/_comun/R/{datos,metricas,temas}.R` (DO NOT EDIT)

## Architecture invariants (do not violate)

1. **Pure logic in `modelo.R` only** — no `input`, no reactivity, no I/O.
   Functions take plain matrices/data.frames and return plain lists.
2. **`dashboard.qmd` only wires inputs to plots** via OJS. All numeric
   work happens upstream in `precomputo()`.
3. **Every interactive knob has a batch mirror.** If you add a slider for
   parameter X, also add X as an argument to `calcular_pca()` /
   `agrupar_kmeans()` AND forward it through `precomputo()` and `correr()`.
4. **Max 300 LOC per R file** (dashboard.qmd: ≤300 too). Split if growing.
5. **Identifiers are Spanish ASCII** (no accents/ñ): `calcular_pca`, not
   `calcular_pcá`. Comments and string literals may have accents.
6. **Do NOT modify `_comun/`, `shiny/`, `shiny-live/`, `data/`, `renv*`,
   `.Rprofile`.** Only touch files under `libs/quarto/` (and `libs/sdd.md`
   to mark checkboxes at the end).

## Headless commands (your primary way to "see" results)

From the project root:

```bash
# Regenerate everything (10 CSV + 2 JSON + run_log append)
Rscript -e 'source("libs/quarto/R/run_headless.R"); correr("ambos")'

# Just one dataset, custom params
Rscript -e 'source("libs/quarto/R/run_headless.R");
            correr("solo-twins", dataset="twins", n_pcs=3, k_max=8, semilla=7)'
```

**Outputs land in `libs/quarto/outputs/`:**

| File | Format | Notes |
|---|---|---|
| `<ds>_pca.csv` | WIDE: `obs, PC1..PC4` | scores per observation |
| `<ds>_rotation.csv` | `variable, PC1..PC4` | loadings (for biplot arrows) |
| `<ds>_var.csv` | `PC, var_pct, cum_pct` | for scree plot |
| `<ds>_clusters.csv` | LONG: `obs, k, cluster` | k ∈ 2:10 |
| `<ds>_codo.csv` | `k, tot_withinss` | elbow curve |
| `<ds>-precomputo.json` | schema S2 | params + metricas (no PNG) |
| `run_log.csv` | append | shared log per S2 |

### JSON schema (S2, identical across the 3 engines)

```json
{
  "timestamp": "2026-08-12T23:27:54-0500",
  "proyecto":  "quarto",
  "escenario": "twins-precomputo",
  "params":    { "dataset": "twins", "n_pcs": 4,
                 "k_range": [2,3,4,5,6,7,8,9,10], "semilla": 42 },
  "metricas":  { "n_obs": 147, "n_vars": 16,
                 "var_pc1": 17.79, "var_pc2": 14.18 },
  "archivos":  {},
  "notas":     "PCA + k-means precomputados sobre twins (147 obs × 16 vars)."
}
```

Note: `archivos.plot` is intentionally empty — the S2 PNG slot is not
used here because the project's artifacts are the per-dataset CSVs (PCA,
rotation, var, clusters, codo). The JSON exists to satisfy S2 and provide
`metricas` + `params`.

### run_log.csv schema (append-only history)

```
timestamp, proyecto, escenario, params_json, metrica_principal, plot
```

Inspect:

```bash
cat libs/quarto/outputs/run_log.csv
# or in R: source("libs/_comun/R/metricas.R"); leer_run_log("libs/quarto/outputs")
```

## Rendering the dashboard

```bash
quarto render libs/quarto/dashboard.qmd --to html
```

Self-contained HTML (data embedded via `ojs_define`). Open directly with
`file://` or:

```bash
python3 -m http.server 8765 --directory libs/quarto
curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8765/dashboard.html
```

## Key design choices (do not silently change)

- **PCA CSV is WIDE** (`obs, PC1..PC4`), not long. **`ojs_define()` serializes
  data.frames as object-of-arrays (`{obs: [...], PC1: [...]}`), NOT array-of-objects.
  Wrap with `transpose(...)` in the OJS cell to get `[{obs: "...", PC1: ...}, ...]`
  that `Plot.dot(d, {x: "PC1"})` and `arr.map(d => d.obs)` need.** This is the
  #1 gotcha — cells reference `d.PC1` only AFTER `transpose()`.
- **`correr()` is a thin wrapper over `precomputo(force=TRUE)`**. Both
  produce the same artifacts; `correr()` exists to satisfy the S2 entry
  contract and add a visible `[correr]` log line.
- **`escribir_salida` is called with `plot_obj = NULL`** — no spurious
  PNG. The CSVs *are* the artifacts.
- **`precomputo()` is idempotent** unless `force=TRUE`. The `.qmd` setup
  chunk relies on this: on cached render, it short-circuits.
- **Bootstrap is auto-contained**: `R/_bootstrap.R` defines its own
  root-finder (no reliance on `proyecto_raiz()` yet undefined). Same
  pattern as `libs/shiny/R/datos.R`.

## OJS gotchas

- **`ojs_define()` serializes data.frames as object-of-arrays, NOT array-of-objects.**
  Always wrap with `transpose(...)` in OJS before calling `.map`, `.filter`,
  `Plot.dot(...)`, etc. Static verification: inspect the rendered HTML's
  `<script type="ojs-define">` JSON — `value` will be `{"col": [...]}` (OOA),
  not `[{...}, ...]` (AOO).
- **`ojs_define()` is not cacheable**. The setup R chunk in `dashboard.qmd`
  carries `cache: false` explicitly; everything else uses `cache: true`.
- **Runtime versions are bundled by Quarto**. Check before using exotic APIs:
  ```bash
  grep -oE '@observablehq/[a-z]+@[0-9.]+' \
    libs/quarto/dashboard_files/libs/quarto-ojs/quarto-ojs-runtime.js | sort -u
  ```
  This Quarto (1.10.18) bundles **@observablehq/inputs@0.10.6**. `Inputs.selection`
  was added in 0.10.7 — NOT available here. Substitute: `Inputs.select(arr,
  {multiple: true, size: N})` (returns Array, not Set). Adjust downstream code
  accordingly (`.length`, `.includes()`, or wrap in `new Set(...)`).
- **`viewof foo = Inputs.X(...)`** exposes the value as `foo` and the DOM
  as `viewof foo`. Downstream cells reference only `foo`.
- **`Inputs.select(arr, {multiple:true})`** returns a plain Array. Empty array
  is treated as "show all" in this dashboard (see `obs_visibles` cell).
- **`Inputs.search(data)` returns the FILTERED SUBSET of `data`, not the query
  string.** This cost us `TypeError: highlight.trim is not a function` —
  `highlight` was an Array. For a text query use `Inputs.text()`. If you do
  want `Inputs.search`, consume its value as the already-filtered array.

### Value contract of every input used here

**This table is the whole point.** All three OJS bugs in this project's
history were a wrong assumption about one of these cells. Nothing in the
code declares these types; you cannot infer them by reading.

| Cell | Returns | Gotcha |
|---|---|---|
| `Inputs.select(arr)` | element of `arr` | — |
| `Inputs.select(arr, {multiple:true})` | **Array** | not a Set; `Inputs.selection` doesn't exist in 0.10.6 |
| `Inputs.search(data)` | **filtered subset of `data`** | **not the query string** |
| `Inputs.text()` | String | use this when you want the query |
| `Inputs.range([a,b])` | Number | — |
| `Inputs.toggle()` | Boolean | — |
| `Inputs.radio(arr)` | element of `arr` | — |
| `Inputs.color()` | String `"#rrggbb"` | — |
| `Inputs.table(data)` | Array of selected rows | value is the *selection*, not the data |
| `ojs_define(df)` | **object-of-arrays** | needs `transpose()` → array-of-objects |

### The habit that prevents all of this

**Before using an OJS value, put it alone in a cell and look at it.**

```js
highlight      // a cell with just this shows you it's an Array, not a String
```

That is the OJS equivalent of `str()`. It costs five seconds and it is the
only thing that catches this bug class *before* the browser. Reading the code
cannot catch it, and neither can `quarto render`.

### One broken cell silently blanks its dependents

OJS paints the error inside the failing cell and keeps going. Every downstream
cell then renders **nothing** — no error of its own. When `highlight.trim`
broke, `Inputs.table` in the Datos tab simply never appeared (the guard caught
it as `table: 0`). So "the page loads and mostly looks fine" is not evidence.
Always assert that expected content is *present*, not just that errors are
absent.
- **Cells react by name, not declaration order.** If a slider doesn't
  respond, suspect a cyclic dependency on the derived cell.
- **`Plot.arrow()`** needs `x1,y1,x2,y2` channels; for biplot loadings
  we anchor at origin `(0,0)` and end at the rotation value.

## Verification (runtime-aware, not just static)

`quarto render` succeeding is **NOT** proof that OJS works — it produces
HTML even when every cell throws.

**Just run the guard:**

```bash
Rscript libs/quarto/R/test_dashboard.R          # render + headless browser
SDA_SKIP_RENDER=1 Rscript libs/quarto/R/test_dashboard.R   # reuse existing HTML
SDA_ESPERA=10 Rscript libs/quarto/R/test_dashboard.R       # slower machines
```

It renders, serves the HTML over HTTP (OJS module imports are CORS-blocked
under `file://`), loads it in headless Chrome via `chromote`, waits for the
reactive graph to settle, and fails on:

- any `.observablehq--error` / `.quarto-ojs-error` node in the DOM
- any JS exception, unhandled rejection, or `console.error`
- the literal strings `is not a function` / `is not defined`
  (the signature of all three historical bugs)
- **missing expected content** — ≥5 `svg`, ≥3 sliders, ≥3 selects, ≥1 color
  input, ≥1 table. This catches the silent-blank cascade; without it a page
  that renders nothing passes cleanly.

Exit 0/1, so it works as a pre-commit gate. The reusable engine is
`libs/_comun/R/pruebas_web.R::verificar_html()` — point it at any static
HTML artifact (shiny-live's bundle next).

**This guard is validated by falsification**: deleting the `transpose()` on
`pca_all` makes it fail with 17 error cells naming `pca_all.map is not a
function`. If you change it, re-run that check — a guard nobody has tried to
fool is not a guard.

Manual pass (still worth doing once after big changes): open the HTML,
exercise every slider/selector, confirm the biplot, heatmap and table filter
together.

## Adding a new parameter (3-place rule)

If you add e.g. a `peso` hyperparameter to k-means:

1. **`modelo.R::agrupar_kmeans()`** — add `peso = ...` argument.
2. **`precomputo.R::precomputo()`** — add `peso = ...`, forward it.
3. **`run_headless.R::correr()`** — add `peso = ...`, forward it; include
   in `params` of `escribir_salida()`.
4. **`dashboard.qmd`** — only if you want it user-tunable: add a
   `viewof peso = Inputs.range(...)` and propagate.

Otherwise logic and UI desync.

## Common gotchas

- `prcomp(scale.=TRUE)` standardizes columns. K-means here does its own
  `scale()` first to be consistent. Don't remove either.
- `agrupar_kmeans()` filters `k_range` to feasible values
  (`2 ≤ k ≤ nrow-1`); if you ask for k=11 on a 10-row matrix, it silently
  drops.
- `pivot_paises(min_obs=10)` keeps countries with ≥10 non-NA years and
  imputes the rest to 0. That's why charcoal ends with 151 obs (BRIEF
  estimated 145 — same data, slight param diff).
- `renv` activation depends on `.Rprofile` at project root — don't move.

## Verifying changes (CI-like)

```bash
# 1. R syntax
for f in libs/quarto/R/*.R; do Rscript -e "invisible(parse('$f')); cat('$f OK\n')"; done

# 2. Headless regen
Rscript -e 'source("libs/quarto/R/run_headless.R"); correr("ambos")'
ls libs/quarto/outputs/   # expect 10 CSV + 2 JSON + run_log.csv

# 3. Render
quarto render libs/quarto/dashboard.qmd --to html

# 4. LOC
wc -l libs/quarto/R/*.R libs/quarto/dashboard.qmd   # all < 300
```

## What to read first when iterating

1. `libs/sdd.md` — global spec (S1–S7).
2. `libs/quarto/README.md` — component showcase + data flow.
3. `libs/quarto/R/modelo.R` — pure logic, ~90 LOC.
4. `libs/quarto/dashboard.qmd` — OJS showcase, ~220 LOC.
5. `libs/quarto/R/precomputo.R` — file schemas + idempotency, ~125 LOC.
