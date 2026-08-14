# BRIEF — Proyecto 2: Quarto Dashboard + Observable JS (PCA + Clustering)

Eres un agente que va a implementar el **segundo de 3 proyectos** del curso
AED (Universidad del Rosario). Demuestra **Quarto + Observable JS** como
motor de interactividad.

## Contexto (lee esto PRIMERO, en orden)

1. **Repositorio**: `/Users/oh/World/External/Study/UR/SDA/`
2. **Plan maestro**: `libs/sdd.md` (specs S1–S5, invariantes del sistema).
3. **Proyecto 1 ya está hecho y es tu PATRÓN DE REFERENCIA**. Lee en orden:
   - `libs/shiny/README.md` (entrega, español)
   - `libs/shiny/AGENT.md` (entrega para agente, inglés)
   - `libs/shiny/R/modelo.R` (cómo separamos lógica pura)
   - `libs/shiny/R/run_headless.R` (cómo se usa `escribir_salida()`)
   - `libs/_comun/R/datos.R`, `metricas.R`, `temas.R` (lo que ya tienes)
4. **El entorno ya está montado**: R 4.6.1, Quarto 1.10.18, renv activo.
   **NO reinstales nada**. **NO ejecutes `brew`**. **NO `install.packages()`**
   sin verificar primero si el paquete ya está en `renv.lock`.
5. **Otro agente trabaja en paralelo** sobre `libs/shiny-live/`. **NO lo toques.**

## Hook pedagógico

PCA y k-means se **precomputan en R** sobre dos datasets reales del curso.
El navegador **solo filtra / reescala / recolorea** vía Observable JS.
Demuestra cuándo **basta un HTML estático** vs cuándo hace falta backend.

## Los dos datasets (alternables en la UI)

### Dataset A — `data/charcoal.csv` (panel geográfico)
- 145 países × 31 años (1990–2020) de producción de carbón vegetal
- Ya hay un helper en `_comun`: `pivot_paises(flujo="Production")` → matrix país×año
- **PCA**: países en el espacio de sus series temporales
- **Clustering**: agrupar países con perfiles similares

### Dataset B — `data/twins.csv` (estudio de gemelos, Ashenfelter & Krueger 1994)
- 183 pares de gemelos monocigóticos × 16 variables socioeconómicas
- Variables: `DLHRWAGE, DEDUC1, AGE, AGESQ, HRWAGEH, WHITEH, MALEH, EDUCH,
  HRWAGEL, WHITEL, MALEL, EDUCL, DEDUC2, DTEN, DMARRIED, DUNCOV`
- NA representados por `.` (lee con `read.csv(..., na.strings = ".")`)
- **PCA**: pares de gemelos en el espacio de sus variables
- **Clustering**: identificar "tipos" de pares de gemelos
- Referencia pedagógica: `workshops/twins/t00.rmd`

El dashboard debe dejar elegir entre A y B con un `viewof dataset = Inputs.select(...)`.

## Reglas DURAS (no romper)

1. **Trabaja SOLO dentro de `libs/quarto/`.** NO toques:
   - `libs/_comun/`, `libs/shiny/`, `libs/shiny-live/`
   - `.Rprofile`, `renv/`, `renv.lock`, `.vscode/`
   - `data/`, `workshops/`, `projects/`, `temp/` (propios del usuario)
2. **Reutiliza `libs/_comun/R/`** vía `source()` con bootstrap auto-contenido
   (ver `libs/shiny/R/run_headless.R` para ejemplo del root-finder).
3. **Ningún fichero > 300 LOC** (ideal < 150).
4. **Identificadores en español ASCII** (sin tildes/ñ): `calcular_pca`,
   no `calcular_p_cá`. Strings y comentarios sí pueden llevar tildes.
5. **Cumple el contrato headless S2** (ver `libs/sdd.md` y `libs/_comun/R/metricas.R`).
6. **NO uses `install.packages()`** salvo urgencia verificada. Si lo haces,
   ejecuta `renv::snapshot(prompt = FALSE)` desde la raíz al final.

## Entregables

```
libs/quarto/
├── R/
│   ├── datos.R           # wrappers sobre _comun: cargar_twins(), pivot_paises() ya está
│   ├── modelo.R          # calcular_pca(), agrupar_kmeans() genéricos sobre una matriz
│   ├── precomputo.R      # vuelca outputs/{charcoal,twins}_{pca,clusters,var,rotation}.csv
│   ├── run_headless.R    # correr(escenario, dataset, ...) -> escribe S2 outputs
│   └── _bootstrap.R      # (opcional) helper de sourceo compartido
├── dashboard.qmd         # Quarto Dashboard + OJS
├── outputs/              # se crea solo al correr
├── README.md             # esp, humano (como libs/shiny/README.md)
├── AGENT.md              # ing, agente (como libs/shiny/AGENT.md)
└── BRIEF.md              # este archivo (no borrar)
```

## API contracts obligatorios

### `R/modelo.R` (~120 LOC)

```r
# PCA genérico. mat = matriz numérica (filas = observaciones, cols = variables).
# Estandariza antes (scale.=TRUE para que var=1 en cada columna).
# Devuelve list con:
#   scores    = matrix obs × PC
#   rotation  = matrix variable × PC (cargas)
#   sdev, var_pct, cum_pct
#   obs_names, var_names
calcular_pca <- function(mat, n_pcs = 4) { ... }

# k-means para un rango de k. Estandariza mat primero.
# Devuelve list con:
#   resultados = lista por k: list(cluster=integer, withinss=numeric, centers=matrix)
#   obs_names, k_range
#   tot_withinss = vector con tot.withinss por k (para codo)
agrupar_kmeans <- function(mat, k_range = 2:10, nstart = 25, semilla = 42) { ... }
```

### `R/datos.R` (~80 LOC)

```r
# Carga twins.csv eliminando filas con NA. Devuelve data.frame.
cargar_twins <- function(complete_cases = TRUE) { ... }

# Construye la matriz numérica para PCA/clustering de cada dataset.
# Para charcoal: pivot_paises() de _comun.
# Para twins: selecciona las cols numéricas y elimina NAs.
construir_matriz <- function(dataset = c("charcoal", "twins"),
                              flujo = "Production") { ... }
```

### `R/precomputo.R` (~100 LOC)

Para CADA dataset (`charcoal` y `twins`), escribe en `libs/quarto/outputs/`:

- `<ds>_pca.csv` — long format: `obs, PC, valor` (PC ∈ {PC1..PC4}).
  Alternativamente wide (`obs, PC1, PC2, PC3, PC4`) — elige una y documéntala
  en `datos.R` y `AGENT.md`.
- `<ds>_rotation.csv` — `variable, PC1, PC2, PC3, PC4` (cargas)
- `<ds>_var.csv` — `PC, var_pct, cum_pct` (varianza explicada)
- `<ds>_clusters.csv` — long: `obs, k, cluster` (k ∈ 2:10)
- `<ds>_pca.json` — schema S2 con `params = list(dataset=...)` y
  `metricas = list(n_obs=..., n_vars=..., var_pc1=..., var_pc2=...)`

Usa `escribir_salida(proyecto = "quarto", escenario = "<ds>-precomputo", ...)`.

### `R/run_headless.R` (~80 LOC)

```r
correr <- function(escenario = "default",
                   dataset = c("charcoal", "twins"),  # o "ambos"
                   flujo = "Production",              # solo charcoal
                   n_pcs = 4,
                   k_max = 10,
                   semilla = 42,
                   out_dir = "libs/quarto/outputs") { ... }
```

`correr("ambos")` regenera los 8 CSVs (4 por dataset) + 2 JSONs.

### `dashboard.qmd`

- YAML: `format: dashboard`, `orientation: rows`, `scrolling: true`,
  `theme: cosmo`, `execute: { warning: false, cache: true }`.
- Páginas (`# Título`): **Visión general**, **PCA**, **Clusters**, **Datos**.
- Chunk R inicial:
  ```r
  ```{r}
  #| include: false
  source("R/precomputo.R")
  precomputo()  # idempotente: si ya existen los CSVs, no regenera
  charcoal_pca      <- read.csv("outputs/charcoal_pca.csv")
  charcoal_clusters <- read.csv("outputs/charcoal_clusters.csv")
  charcoal_var      <- read.csv("outputs/charcoal_var.csv")
  charcoal_rot      <- read.csv("outputs/charcoal_rotation.csv")
  twins_pca         <- read.csv("outputs/twins_pca.csv")
  twins_clusters    <- read.csv("outputs/twins_clusters.csv")
  twins_var         <- read.csv("outputs/twins_var.csv")
  twins_rot         <- read.csv("outputs/twins_rotation.csv")
  ojs_define(charcoal_pca, charcoal_clusters, charcoal_var, charcoal_rot,
             twins_pca, twins_clusters, twins_var, twins_rot)
  ```
  ```

## Showcase OJS — DEBES cubrirlos TODOS

```ojs
// --- Inputs (todos los tipos comunes) ---
viewof dataset     = Inputs.select(["charcoal", "twins"], {label: "Dataset"})
viewof k           = Inputs.range([2, 10], {step: 1, value: 4, label: "k (clusters)"})
viewof pc_x        = Inputs.select(["PC1","PC2","PC3","PC4"], {value: "PC1", label: "Eje X"})
viewof pc_y        = Inputs.select(["PC1","PC2","PC3","PC4"], {value: "PC2", label: "Eje Y"})
viewof show_label  = Inputs.toggle({label: "Etiquetas", checked: true})
viewof opacity     = Inputs.range([0.2, 1], {step: 0.05, value: 0.7, label: "Opacidad"})
viewof color_by    = Inputs.radio(["cluster", "variable continua"], {label: "Color por"})
viewof highlight   = Inputs.search(/* lista de obs */)  // filtro textual
viewof bins        = Inputs.range([5, 50], {step: 1, value: 20, label: "Bins histograma"})
viewof pais_sel    = Inputs.selection(/* lista de obs */, {label: "Selección", multiple: true})
viewof accent      = Inputs.color({label: "Color de acento", value: "#0072B2"})

// --- Observable Plot ---
// 1. Scree plot: Plot.barY + Plot.lineY con cum_pct
// 2. Biplot PC_x vs PC_y: Plot.dot, coloreado por cluster[k], etiquetas toggle,
//    con Plot.arrow para las cargas (rotation) superpuestas
// 3. Heatmap obs × PC: Plot.cell
// 4. Codo (withinss vs k): Plot.line + Plot.dot
// 5. Histograma de PC1 con bins dinámico
// 6. Tabla cruzada: Inputs.table con filtros

// --- Crossfilter ---
// pais_sel debe afectar biplot, tabla y heatmap simultáneamente.
```

**Librerías OJS disponibles en Quarto sin `import`**: `Plot` (Observable Plot),
`Inputs`, `Generators`, `transpose` (de `observablehq:stdlib`), `html`, `md`.

## Gotchas específicos de Quarto + OJS

- **`ojs_define(name = value)`** en chunk R; en celda OJS accedes como `name`.
- **data.frame → array-of-objects** es automático. NO necesitas `transpose()`
  salvo para acceso por columna en un bucle.
- **`viewof foo = Inputs.range(...)`** expone el valor como `foo` y el DOM
  como `viewof foo`. Celdas downstream referencian solo `foo`.
- **OJS Plot** = `Plot.plot({...})`. Docs: observablehq.com/plot.
- **No mezclar R y OJS** dentro de una misma celda.
- **Dependencias cíclicas**: si un slider no responde, suele ser un ciclo.
  Las celdas OJS reaccionan por nombre, no por orden de declaración.
- **`Inputs.selection()`** devuelve un Set; úsalo con `.has(x)`.
- **Cache de Quarto**: si cambias `R/precomputo.R` y no se refleja, borra
  `.quarto_cache_dir/` o pon `cache: false` en el chunk temporalmente.
- **Google Fonts** en `theme:` son lentas al render local; espera.
- **`transpose()`** en OJS convierte array-of-objects → object-of-arrays,
  útil para `Plot.plot({x: d => transpose(data).obs, ...})`.
- **Charcoal tiene 145 obs, twins tiene ~120 obs** tras drop-NA: tamaños
  cómodos para Plot.

## Verificación (definition of done)

1. **Sintaxis R**:
   ```bash
   for f in libs/quarto/R/*.R; do Rscript -e "invisible(parse('$f')); cat('$f OK\n')"; done
   ```
2. **Headless**:
   ```bash
   Rscript -e 'source("libs/quarto/R/run_headless.R"); correr("ambos")'
   ls libs/quarto/outputs/
   # debe listar: charcoal_{pca,clusters,var,rotation}.csv
   #              twins_{pca,clusters,var,rotation}.csv
   #              charcoal-precomputo.json  twins-precomputo.json
   #              run_log.csv
   cat libs/quarto/outputs/twins-precomputo.json  # debe seguir schema S2
   ```
3. **Render del dashboard**:
   ```bash
   quarto render libs/quarto/dashboard.qmd --to html
   ```
   Sin errores. Abre el HTML en el navegador y verifica que TODOS los
   sliders OJS (k, pc_x, pc_y, dataset, etc.) actualizan los plots al moverlos.
4. **HTTP smoke test** (opcional):
   ```bash
   python3 -m http.server 8765 --directory libs/quarto &
   sleep 2
   curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8765/dashboard.html
   kill %1
   ```
5. **Ningún archivo > 300 LOC** (`wc -l libs/quarto/R/*.R`).

## Definition of done global

- [ ] Todos los archivos entregados con sintaxis OK.
- [ ] `correr("ambos")` genera los 8 CSVs + 2 JSONs + append a run_log.csv.
- [ ] `quarto render` produce HTML sin errores.
- [ ] TODOS los sliders OJS responden.
- [ ] Selector `viewof dataset` cambia entre charcoal y twins correctamente.
- [ ] Crossfilter (pais_sel) afecta biplot + tabla + heatmap.
- [ ] Ningún archivo > 300 LOC.
- [ ] `README.md` (esp) + `AGENT.md` (eng) escritos.
- [ ] **Al terminar, actualiza `libs/sdd.md`** marcando con `[x]` todas las
      casillas de la sección "Proyecto 2" y agrega una línea al final de
      esa sección: `> Completado por agente el <YYYY-MM-DD>`.
- [ ] No tocaste archivos fuera de `libs/quarto/` (salvo sdd.md).

## Cuando te atasques

1. Re-lee este archivo completo.
2. Mira cómo `libs/shiny/` resolvió el problema análogo
   (`run_headless.R`, `modelo.R`, `AGENT.md`).
3. Lee `libs/_comun/R/datos.R` (qué helpers ya existen).
4. Consulta `libs/sdd.md` para specs globales.
5. **NO agregues helpers a `_comun/`**. Si lo necesitas, detente y reporta.
6. Para OJS: https://observablehq.com/plot/ y https://quarto.org/docs/interactive/ojs/
