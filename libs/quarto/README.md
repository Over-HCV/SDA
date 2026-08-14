# Proyecto 2 — Quarto + Observable JS · PCA + Clustering

Dashboard Quarto estático para explorar **PCA** y **k-means** sobre dos
datasets reales del curso. **Hook pedagógico**: todo el cómputo pesado
(PCA, k-means para k = 2…10) se **precomputa en R** y se vuelca a CSV;
el navegador **solo filtra / reescala / recolorea** vía Observable JS.
Demuestra cuándo **basta un HTML estático** sin backend.

Es el **Proyecto 2** de los 3 motores de interactividad del curso AED (UR).
Diseño conforme al plan SDD en `libs/sdd.md`.

---

## Datasets (alternables en la UI con `viewof dataset`)

| Dataset | Origen | Forma | PCA | Clustering |
|---|---|---|---|---|
| **charcoal** | `data/charcoal.csv` (FAO) | país × año (1990–2020) | países en el espacio de sus series temporales | perfiles de producción similares |
| **twins**    | `data/twins.csv` (Ashenfelter & Krueger 1994) | par de gemelos monocigóticos × 16 vars | pares en el espacio socioeconómico | "tipos" de pares |

> NA en twins viene como `.` → se cargan con `read.csv(..., na.strings = ".")`.

---

## Estructura

```
libs/quarto/
├── R/
│   ├── _bootstrap.R      # bootstrap: encuentra raíz, carga _comun + propios
│   ├── datos.R           # cargar_twins(), construir_matriz(dataset)
│   ├── modelo.R          # LÓGICA PURA: calcular_pca(), agrupar_kmeans()
│   ├── precomputo.R      # precomputo(): vuelca 10 CSV + 2 JSON (idempotente)
│   └── run_headless.R    # correr(escenario, dataset, ...): wrapper S2
├── dashboard.qmd         # Quarto dashboard + OJS (4 páginas)
├── outputs/              # se crea solo; no se versiona
├── README.md             # este archivo (español humano)
├── AGENT.md              # inglés máquina (para agentes LLM)
└── BRIEF.md              # especificación original (no borrar)
```

Regla S1: ningún `.R` > 300 LOC. Aquí el mayor es `precomputo.R` con ~125.
La lógica (`modelo.R`, `datos.R`) no toca `input` ni reactividad: solo
matrices y data.frames.

---

## Cómo correrlo

> ⚠️ Todo se ejecuta **desde la raíz del proyecto** (`SDA/`), donde está
> `.Rprofile` (activa `renv` + paquetes).

### Modo headless (regenera los 10 CSV + 2 JSON)

```bash
# desde la raíz SDA/
Rscript -e 'source("libs/quarto/R/run_headless.R"); correr("ambos")'
```

Esto escribe en `libs/quarto/outputs/`:

- `charcoal_{pca,rotation,var,clusters,codo}.csv`
- `twins_{pca,rotation,var,clusters,codo}.csv`
- `charcoal-precomputo.json`, `twins-precomputo.json` (schema S2)
- `run_log.csv` (append)

Ejemplos con parámetros:

```r
correr("solo-twins", dataset = "twins", k_max = 8)
correr("charcoal-k6", dataset = "charcoal", n_pcs = 3, k_max = 6)
```

### Render del dashboard

```bash
quarto render libs/quarto/dashboard.qmd --to html
```

Abre `libs/quarto/dashboard.html` en el navegador. **Es autocontenido**:
todos los datos viajan embebidos vía `ojs_define()`. Sin backend, sin
servidor: funciona con `file://`.

### Smoke test HTTP (opcional)

```bash
python3 -m http.server 8765 --directory libs/quarto
# luego: http://localhost:8765/dashboard.html
```

---

## Qué demuestra (showcase Observable JS)

### Inputs (los 11 tipos principales de `Inputs.*`)

| Input | Controla |
|---|---|
| `viewof dataset` (`Inputs.select`) | dataset activo: charcoal ↔ twins |
| `viewof k` (`Inputs.range`)        | nº de clústeres k ∈ 2:10 |
| `viewof pc_x`, `pc_y` (`Inputs.select`) | PCs en los ejes del biplot |
| `viewof show_label` (`Inputs.toggle`)   | etiquetas de texto en biplot |
| `viewof opacity` (`Inputs.range`)       | opacidad de los puntos |
| `viewof color_by` (`Inputs.radio`)      | colorear por clúster o por acento |
| `viewof highlight` (`Inputs.search`)    | filtro textual por nombre de obs |
| `viewof bins` (`Inputs.range`)          | nº de bins del histograma |
| `viewof pais_sel` (`Inputs.selection`)  | selección múltiple (crossfilter) |
| `viewof accent` (`Inputs.color`)        | color de acento |

### Plots (Observable Plot)

1. **Scree plot** — `Plot.barY` (var %) + `Plot.lineY` (acumulada).
2. **Biplot PCx × PCy** — `Plot.dot` (scores) + `Plot.arrow` (cargas de
   rotación), con etiquetas toggle y opacidad/cromática dinámicas.
3. **Heatmap obs × PC** — `Plot.cell`, divergente RdBu.
4. **Curva del codo** — `Plot.line` + `Plot.dot` con `tot.withinss` por k.
5. **Histograma de PC1** — `Plot.rectY` + `Plot.binX` con bins dinámico.
6. **Tabla cruzada** — `Inputs.table` con clúster a k actual.

### Crossfilter

`pais_sel` (`Inputs.selection`, devuelve un `Set`) **afecta a la vez** al
biplot, a la tabla y al heatmap. Combinado con `highlight` (búsqueda
textual) permite filtrar de las dos formas. Si `pais_sel` está vacío se
muestran todas las observaciones.

---

## Data flow

```
   R (precomputo)                          Navegador (OJS)
   ──────────────                          ──────────────
   cargar_charcoal()/cargar_twins()
            │
            ▼
   construir_matriz(dataset)  ───► matriz obs × vars
            │
            ▼
   calcular_pca(mat)  +  agrupar_kmeans(mat)
            │
            ▼
   10 CSV + 2 JSON (escribir_salida S2)
            │
            ▼ (read.csv + ojs_define)
   charcoal_pca, charcoal_clusters, …  ──►  viewof dataset
                                              │
                                              ▼
                                   pca_all, clusters_all, …
                                              │
                                              ▼
                                   viewof k, pc_x, pc_y, …  +  crossfilter
                                              │
                                              ▼
                                   6 plots reactivos (Plot.*)
```

---

## Dependencias

- **R**: `stats::prcomp`, `stats::kmeans`, `utils::read.csv`. Nada más.
- **Quarto** + **Observable Plot** + **Observable Inputs** (vienen con
  Quarto; sin `import` adicional).

`renv::status()` desde la raíz debe estar limpio.

---

## Convenciones

- Identificadores R en español **ASCII** (sin tildes/ñ): `calcular_pca`,
  no `calcular_pcá`. Strings y comentarios sí llevan tilde.
- PCA CSV en formato **WIDE** (`obs, PC1, PC2, PC3, PC4`). `ojs_define()`
  serializa data.frames como **object-of-arrays**; hay que envolver con
  `transpose(...)` en OJS para obtener array-of-objects y poder usar `d.PC1`,
  `arr.map(...)`, etc. Documentado en `AGENT.md`.
- `precomputo()` es **idempotente**: si los 10 CSV ya existen, no
  recomputa salvo `force = TRUE`. `correr()` siempre hace `force = TRUE`.

---

## Problemas conocidos

- **`ojs_define()` serializa data.frames como object-of-arrays, NO como
  array-of-objects.** Sin `transpose()` en OJS, `pca_all.map(d => ...)` falla
  con `TypeError: pca_all.map is not a function`. El BRIEF decía que la
  conversión era automática — no lo es. Todos los datasets derivados del
  `.qmd` pasan por `transpose()`.
- **Este Quarto (1.10.18) trae `@observablehq/inputs@0.10.6`.** `Inputs.selection`
  se agregó en 0.10.7 y NO está disponible. Se usa `Inputs.select(arr,
  {multiple: true, size: 7})` en su lugar (devuelve Array, no Set). Para
  verificar versiones:
  ```bash
  grep -oE '@observablehq/[a-z]+@[0-9.]+' \
    libs/quarto/dashboard_files/libs/quarto-ojs/quarto-ojs-runtime.js | sort -u
  ```
- **`quarto render` exitoso ≠ runtime OK.** El HTML se produce aunque todas
  las celdas OJS tiren error. Por eso existe el guard:

  ```bash
  Rscript libs/quarto/R/test_dashboard.R
  ```

  Renderiza, sirve por HTTP, carga en Chrome headless y falla si hay celdas en
  error, excepciones JS, o si **falta contenido esperado**. Ver AGENT.md.
- **Una celda rota deja en blanco a sus dependientes, sin error propio.**
  Cuando `highlight.trim` falló, la tabla del tab Datos simplemente no se
  pintó. Por eso el guard verifica presencia de contenido, no solo ausencia
  de errores.
- **`Inputs.search(data)` devuelve el subconjunto filtrado de `data`, no el
  texto buscado.** Para un string, `Inputs.text()`. Tabla completa de
  contratos de valor de cada `Inputs.*` en AGENT.md.
- **`ojs_define` no es cacheable**: el chunk de setup lleva `cache: false`
  explícito. El resto del documento sí usa `cache: true`.
- **Quarto cache**: si modificas `R/precomputo.R` y no se refleja en el
  render, borra `.quarto_cache_dir/` o pon `cache: false` global temporal.
- **Cambio de dataset**: al cambiar `viewof dataset`, todas las celdas
  downstream se recomputan en el navegador; los `pais_sel` y `highlight`
  se reevalúan sobre la nueva lista de obs.
- **Charcoal**: 151 obs tras `pivot_paises(min_obs=10)` (BRIEF estimaba
  145, depende del filtro). Twins: 147 obs tras drop-NA.

---

## Alcance de este motor (evaluación contra la guía del curso)

Escrito para no volver a discutirlo.

### El techo de reactividad

Este dashboard **no puede** ser tan reactivo como Shiny o shinylive, y no es un
defecto: es el diseño. `precomputo()` congela la estadística en CSVs antes de
renderizar.

| Control | Qué hace en realidad |
|---|---|
| `k` (2–10) | busca una columna precomputada — **no corre `kmeans`** |
| `pc_x` / `pc_y` | elige entre los PC1–PC4 exportados — **no corre `prcomp`** |
| variables del PCA | **no existe el control** (exigiría re-ajustar en R) |
| escalado, distancia, semilla | **no existen** (ídem) |

Mover un control hace un *lookup*, nunca un reajuste. Comparado:

- **LASSO (Shiny)**: el slider de λ corre `glmnet` de verdad; los coeficientes
  se anulan de verdad. *El método es lo reactivo.*
- **ANOVA (shinylive)**: el slider de `n` corre `aov()` de verdad; F y p se mueven.
- **PCA (acá)**: la estadística está congelada; solo se mueve la vista.

### Contra la rúbrica

`guide-eda-26A.md` §15 pide **cuaderno RMD + diapositivas PDF + video**.
Rúbrica: R1 30% (conceptos y visualización pedagógica), R2 30% (código R
legible, método correcto), R3 20% (exposición), R4 20% (video).
**Peso sobre interactividad, JS o despliegue web: 0%.**

### Conclusión

- **Quarto como motor de documentos: alto valor.** Un solo `.qmd` produce el
  cuaderno y, con `format: revealjs`, las diapositivas → PDF. Además renderiza
  `.rmd` nativamente. Pega directo en R2 y R3.
- **OJS en particular: bajo valor para este curso.** Segundo lenguaje,
  contratos de valor invisibles, no testeable desde R, cero puntos de rúbrica,
  y con el techo de reactividad de arriba. Su valor real es la lección *meta*
  de "cuándo alcanza un artefacto estático" — legítima, pero es una lección de
  arquitectura, no de estadística.
- **Decisión** (ver `libs/sdd.md` S8): este proyecto se queda como está, pero
  **los temas nuevos se construyen sobre `projects/_template/` (Shiny)**.

Reimplementar `prcomp`/`kmeans` en JS para lograr reactividad real es un
callejón sin salida: duplica la superficie de bugs y sacrifica R2 (30%).

---

## Siguiente

- `libs/shiny/` — Proyecto 1 (regresión, caso donde el backend sí importa).
- `libs/shiny-live/` — Proyecto 3 (ANOVA en webR).
- `projects/_template/` — plantilla para temas nuevos (Shiny).
