# Mapa de Temas → Patrón de App

Routing doc para construir apps por tema (`projects/NN-<slug>/`) a partir de
`data/topics-tf.csv`. Cada fila dice **qué datos**, **qué paquetes nuevos**,
**qué función `modelo.R`** y **qué módulo UI clonar** del showcase
`libs/shiny/R/`.

Convención: cada app nueva copia `projects/_template/` (Phase C del SDD) y
reemplaza solo `modelo.R` + `mod_main.R` + `datos.R`. El resto del cableado
(`app.R`, `run_headless.R`, `_comun/`) se reutiliza intacto.

---

## Leyenda

- **Datos**: `ch` = `data/charcoal.csv` (panel país×flujo×año),
  `tw` = `data/twins.csv` (183 pares × 16 vars, NA = `.`),
  `syn` = `gen_sintetico()` en `_comun/R/datos.R`,
  `piv` = `pivot_paises(charcoal)` (matriz país×año, lista para PCA/clustering),
  `ext` = requiere dataset externo.
- **Deps**: paquetes a añadir a `renv`. Base `stats`/`MASS` ya presentes.
- **UI base**: módulo a clonar de `libs/shiny/R/` como punto de partida.
  - `A` = `mod_ajuste.R` (sidebar de inputs + plot + brush + value boxes)
  - `D` = `mod_diagnostico.R` (grid dinámico de plots vía `renderUI`)
  - `T` = `mod_datos.R` (DT + cross-filter)
  - `R` = `mod_resumen.R` (verbatim + tabla de coeficientes)
- **Reactive hook**: qué input dispara el recálculo (el "hook pedagógico").

---

## 1. Herramientas estadísticas básicas (5 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 1 | Análisis de potencia | `syn` / `tw` | `pwr` | `calcular_power(n, effect, power, sig)` → lista(p, curva) | A + R | slider de `effect` → curva de potencia |
| 2 | Missing data (MCAR/MAR/MNAR) | `tw` | `naniar`, `mice` | `diagnosticar_missing(df)`, `imputar_mice(df, m)` | D + T | select de método → patrón + imputación |
| 3 | Bayes con `brms` | `tw` / `ch` | `brms`, `rstan` | `ajustar_bayes(formula, prior, iter, chains)` | A + R | numeric `iter`/`chains` + `withProgress` (MCMC lento) |
| 4 | Permutation tests | `ch` / `tw` | `coin`, `perm` | `permutar_test(x, y, n_perm)` → p + distribución | A + D | slider `n_perm` → distribución nula con observado |
| 5 | Box-Cox | `ch` (y>0) | `MASS` ✓ | `box_cox(y ~ x)` → λ óptimo + plot loglik | A | slider de rango λ → curva |

## 2. Normal Multivariada y Visualización (5 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 6 | GMM clustering | `piv` / `tw` | `mclust` | `agrupar_gmm(mat)` → Mclust + BIC | A + D | checkbox de modelos (EII/VVI/…) → BIC plot |
| 7 | LDA | `tw` (EDUCL cut) | `MASS` ✓ | `correr_lda(df, group, X)` → fit + accuracy | A + T | checkboxGroup de predictores |
| 8 | QDA | `tw` | `MASS` ✓ | `correr_qda(df, group, X)` | A + T | idem LDA |
| 9 | Cópias | `ch` (2 flujos) | `copula` | `ajustar_copula(x, y, family)` | A + D | select de familia (normal/clayton/gumbel) |
| 10 | CCA | `tw` (2 bloques) | `CCA` | `correr_cca(X, Y)` → correlaciones canónicas | A + R | multi-select de variables por bloque |

## 3. Análisis de componentes principales (7 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 11 | EFA | `tw` | `psych` | `correr_efa(mat, n_factors, rotation)` | A + D + R | slider `n_factors` + select `rotation` |
| 12 | PCA robusto | `piv` | `rrcov` | `pca_robusto(mat)` → PcaCov + biplot | A + D | checkbox robust vs clásico (comparación) |
| 13 | PCA con missing | `ch` (NA) | `missMDA` | `pca_imputar(mat, ncp)` | A + D | slider `ncp` (dims imputación) |
| 14 | t-SNE | `piv` / `tw` | `Rtsne` | `correr_tsne(mat, perplexity, dims=2)` | A + D | **slider `perplexity`** (muy sensible) + color por grupo |
| 15 | UMAP | `piv` / `tw` | `umap` | `correr_umap(mat, n_neighbors, min_dist)` | A + D | sliders `n_neighbors` + `min_dist` |
| 16 | FPCA | `ch` (curvas) | `fda` | `correr_fpca(series, nbasis)` | A + D | slider `nbasis` |
| 17 | Kernel PCA | `tw` | `kernlab` | `correr_kpca(mat, kernel, sigma)` | A + D | select `kernel` + slider `sigma` |

## 4. Agrupamiento / Clustering (5 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 18 | DBSCAN | `piv` / `tw` | `dbscan` | `correr_dbscan(mat, eps, minPts)` | A + D | **sliders `eps` + `minPts`** (ruido = NA, color vivo) |
| 19 | Spectral clustering | `piv` | `kernlab` | `agrupar_espectral(mat, k)` | A + D | slider `k` |
| 20 | DTW time series | `ch` (por país) | `dtwclust` | `agrupar_dtw(series, k, method)` | A + D + R | slider `k` + select `method` |
| 21 | Community detection | `ch` (correl) | `igraph` | `construir_grafo(mat, thr)`, `detectar_comunidades(g, algo)` | A + D | slider `thr` + select `algo` (louvain/walktrap) |
| 22 | Biclustering | `piv` | `biclust` | `correr_biclust(mat, method)` | A + D + T | select `method` |

## 5. Regresión lineal en múltiples variables (5 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 23 | **LASSO** ⭐ | `tw` (wage ~ …) | `glmnet` | `correr_lasso(X, y, alpha, lambda)` + `cv.glmnet` | A + D + R | **slider log `lambda`** + radio `alpha` (lasso/ridge/elastic) |
| 24 | Regresión cuantílica | `tw` | `quantreg` | `correr_rq(y ~ x, tau)` | A + D | slider `tau` (0.01–0.99) + bandas superpuestas |
| 25 | Step AIC/BIC | `ch` / `tw` | `MASS` ✓ | `seleccionar_step(fit, direction, k)` | A + R | select `direction` + radio AIC/BIC |
| 26 | Bayes regresión | `tw` | `brms`, `rstanarm` | `ajustar_bayes_lm(formula, prior)` | A + R | textInput `formula` + select `prior` |
| 27 | Espacial (SAR/SEM) | `ch` + mapa | `spdep`, `spatialreg`, `ext`(shapefile) | `construir_pesos(mapa, k)`, `ajustar_sarlm(formula, listw, type)` | A + D | slider `k` vecinos + select `type` |

## 6. Análisis de varianza a una vía (5 temas)

| # | Tema | Datos | Deps | `modelo.R` | UI | Reactive hook |
|---|---|---|---|---|---|---|
| 28 | MANOVA | `ch` (región → flujos) / `tw` | `stats` ✓ | `correr_manova(cbind(y*) ~ group)` | A + R | checkboxGroup de outcomes |
| 29 | RM-ANOVA | `ch` (país × año) | `ez`, `afex` | `correr_rm_anova(df, id, within, between)` | A + R | select `id` / `within` / `between` |
| 30 | Welch / Brown-Forsythe | `ch` / `syn` | `stats` ✓ | `correr_welch(y ~ g)` + `car::leveneTest` | A + R | igual que ANOVA base |
| 31 | Mixed models (lmer) | `ch` (RE por país) | `lme4`, `nlme` ✓ | `correr_lmer(formula, re)` | A + R | textInput `random effect` |
| 32 | Effect size (η²/ω²) | cualquiera | `effectsize` | `calcular_efecto(aov)` → tabla | R (complemento) | depende del módulo ANOVA padre |

---

## Distribución de dependencias a añadir

```
Macro 1 (básicos):       pwr, naniar, mice, brms, rstan, coin, perm
Macro 2 (normal multiv): mclust, copula, CCA             (MASS ya)
Macro 3 (PCA):           psych, rrcov, missMDA, Rtsne, umap, fda, kernlab
Macro 4 (clustering):    dbscan, kernlab, dtwclust, igraph, biclust
Macro 5 (regresión):     glmnet, quantreg, brms, rstanarm, spdep, spatialreg
Macro 6 (ANOVA):         ez, afex, effectsize, lme4      (nlme ya, stats ya)
```

Total: **33 paquetes nuevos** a añadir a `renv` a medida que se aborden los
temas (no instalar todo de una; sigue el principio "1 app = N deps mínimas"
para que `shiny-live` queira en webR).

---

## Orden recomendado (por fricción creciente)

1. **#23 LASSO** — 1 dep, slider λ muy expresivo, twins limpio. **Valida el template.**
2. **#18 DBSCAN** — 1 dep, 2 sliders muy interactivos, `piv` listo.
3. **#14 t-SNE** — 1 dep, slider `perplexity` dramático, gran visual.
4. **#25 Step AIC/BIC** — 0 deps nuevas, reusa `MASS` ya instalado.
5. **#11 EFA** — 1 dep, hermano conceptual del PCA (Project 2 Quarto).
6. **#30 Welch/Brown-Forsythe** — 0 deps, transición natural al ANOVA module.
7. …luego los bayesianos (#3, #26) que son los más lentos (MCMC).

Temas pesados al final: #27 espacial (shapefile), #16 FPCA, #20 DTW (curvas).

---

## Cómo usar este mapa

> **Motor: Shiny.** Todos los temas de este mapa se construyen sobre
> `projects/_template/`, no sobre Quarto+OJS. Razón corta: en OJS la
> estadística queda *precomputada*, así que el hook de la columna "Reactive
> hook" haría un lookup en vez de re-ajustar el modelo — justo lo contrario
> de lo que el tema tiene que mostrar. Justificación completa en
> `libs/sdd.md` S8 y `libs/quarto/README.md`.

Para cada tema `N`:

1. `./projects/nuevo-tema.sh NN <slug> "<Título>" <fila>`
   (o `cp -r projects/_template projects/NN-<slug>` y sustituir marcadores).
2. Editar `R/modelo.R` con la función listada en la columna `modelo.R`.
3. Editar `R/mod_main.R` clonando el módulo UI indicado en columna `UI`.
4. `install.packages(c(<deps>)); renv::snapshot()` — solo los de la fila.
5. Cablear inputs → reactive → `modelo()` → outputs (patrón S1 de `sdd.md`).
6. Implementar `correr()` en `run_headless.R` conforme al contrato S2.
7. Verificar: `Rscript -e 'source("R/run_headless.R"); correr("demo")'`
   debe producir `<esc>.{png,json,csv}` + append a `run_log.csv`.
8. **Los dos harness en verde** (spec S2b de `sdd.md` — no es opcional):
   ```bash
   Rscript projects/NN-<slug>/R/test_headless.R   # lógica + contrato S2
   Rscript projects/NN-<slug>/R/test_app.R        # UI + consola del navegador
   ```
   En `test_headless.R` escribí al menos una **invariante del tema**, no solo
   validación del contrato (ej. LASSO: "más λ ⇒ menos coeficientes activos";
   "ridge nunca anula"). En `test_app.R` ejercitá el hook de la columna
   "Reactive hook" de punta a punta y comprobá que la métrica se mueve en la
   dirección correcta.
