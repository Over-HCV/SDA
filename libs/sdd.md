<!-- Plan SDD — 3 motores de interactividad en R para el curso AED (UR)
     Specs-Driven-Development: primero especificaciones (invariantes), luego
     tareas por proyecto con checkboxes para追踪o. -->

# Especificaciones (invariantes del sistema)

## S1 — Separación lógica / UI
- [ ] Todo cómputo vive en `R/*.R` como funciones PURAS (sin `reactive`, sin `input`).
- [ ] Los ficheros de UI (`app.R`, `dashboard.qmd`) solo cablean inputs → funciones.
- [ ] Ningún fichero > 300 LOC (ideal < 150).

## S2 — Visibilidad para el agente (headless contract)
- [ ] Cada proyecto expone `R/run_headless.R` invocable vía `Rscript` sin GUI.
- [ ] Cada corrida escribe `outputs/<escenario>.{png,json,csv}`.
- [ ] Append a `outputs/run_log.csv` con schema fija (`timestamp,proyecto,escenario,params_json,metrica_principal,plot`).
- [ ] JSON de salida sigue el schema:
      `{ timestamp, proyecto, escenario, params, metricas, archivos:{plot,datos}, notas }`.
- [ ] `AGENT.md` por proyecto (inglés, máquina) con comandos exactos + schema + ubicación de salidas.

## S2b — Verificación a nivel navegador (obligatoria para todo artefacto web)
- [ ] Todo artefacto que se ejecute en un navegador (OJS, webR, Shiny) tiene un
      chequeo que lee **la consola Y el DOM de errores**, con `exit 0/1`.
- [ ] Ese chequeo incluye **aserciones positivas** (que el contenido esperado
      esté presente), no solo ausencia de errores.

**Por qué es una spec y no una recomendación.** Un render limpio y un HTTP 200
no son evidencia de nada:

| Bug | Render | HTTP | Lo delató |
|---|---|---|---|
| `conditionalPanel` namespaceado (P1) | ✅ limpio | ✅ 200 | consola del navegador |
| `pca_all.map` (P2) | ✅ limpio | ✅ 200 | DOM de errores de OJS |
| `Inputs.selection` (P2) | ✅ limpio | ✅ 200 | DOM de errores de OJS |
| `highlight.trim` (P2) | ✅ limpio | ✅ 200 | DOM de errores de OJS |

Los cuatro son **contratos de valor asumidos y nunca verificados en un borde**
(R → JS, R → UI de Shiny, código → versión de librería). No hay tipos que los
declaren, así que leer el código no los encuentra: solo aparecen en runtime.

Peor: **una celda rota deja en blanco a sus dependientes, sin error propio.**
Cuando `highlight.trim` falló, la tabla del tab Datos simplemente no se pintó.
Por eso las aserciones positivas son obligatorias.

Herramientas ya construidas:
- `libs/_comun/R/pruebas_web.R::verificar_html()` — motor reusable (chromote)
- `libs/quarto/R/test_dashboard.R` — dashboard OJS
- `libs/shiny/R/test_app.R`, `projects/*/R/test_app.R` — Shiny (shinytest2)

**Regla de oro**: si un valor cruza un borde, no podés saber su tipo leyendo.
Imprimilo o testealo. En OJS, poné el valor solo en una celda y miralo.

## S3 — Reproducibilidad
- [ ] `renv` ÚNICO en la raíz (`SDA/renv/`) compartido por los 3 proyectos.
- [ ] `.Rprofile` arranca `httpgd::hgd()` + `thematic::thematic_on()`.
- [ ] `semilla` siempre explícita en cada corrida.

## S4 — Convenciones de código
- [ ] Identificadores en español **ASCII** (sin tildes/ñ): `ajustar_modelo`, `tamano_muestra`.
- [ ] Comentarios, strings, títulos de UI, README: español completo con tildes.
- [ ] snake_case en todo R.

## S5 — Comparabilidad
- [ ] Los 3 proyectos comparten `libs/_comun/R/` (datos, métricas, tema ggplot).
- [ ] Schema JSON idéntica entre los 3 motores.

## S6 — Datasets disponibles (uso compartido)
- [ ] `data/charcoal.csv` — panel país×commodity×año (1990–2020, 145 países). Para series temporales, PCA geográfico, ANOVA por región.
- [ ] `data/twins.csv` — estudio Ashenfelter & Krueger (1994), 183 pares de gemelos × 16 vars. NA como `.`. Para PCA sociodemográfico, ANOVA de wage por nivel educativo. Categorización pedagógica: `cut(EDUCL, breaks=c(0,12,16,Inf), right=FALSE)` → "Primaria/Secundaria", "Pregrado", "Posgrado" (ver `workshops/twins/t00.rmd`).
- [ ] `data/topics-tf.csv` — 33 temas del curso con funciones R asociadas (referencia).
- [ ] Sintético: `gen_sintetico(tipo="anova"|"regresion")` en `_comun/R/datos.R` para demos controlables.

## S7 — Workflow con agentes
- [ ] Cada agente lee su `libs/<proyecto>/BRIEF.md` primero.
- [ ] Al terminar, marca con `[x]` todas las casillas de su sección en este archivo y agrega `> Completado por agente el <YYYY-MM-DD>` al final de su sección.
- [ ] Un agente NO toca los BRIEFs ni el código de los otros dos proyectos.

---

# Setup (una sola vez)

- [ ] `brew install --cask r`
- [ ] `brew install --cask quarto`
- [ ] `brew install python && pip install radian`
- [ ] En R: `install.packages(c("shiny","bslib","ggplot2","dplyr","tidyr","DT","jsonlite","httpgd","thematic","shinylive","patchwork","ggrepel","broom","languageserver"))`
- [ ] `renv::init()` + `renv::snapshot()` en `SDA/`
- [ ] `.vscode/settings.json`: rterm=radian, lsp=on, quarto preview=on
- [ ] `.Rprofile`: httpgd + thematic auto-arranque
- [ ] Verificar: `R --version`, `quarto --version`, `radian --version`, `hgd()` responde en navegador

---

# Proyecto 1 — `libs/shiny/` (Regresión)

**Hook pedagógico**: cada slider dispara un `lm()` real → caso donde el backend importa.

- [ ] `R/datos.R` — `cargar_charcoal()`, filtrar por país/año
- [ ] `R/modelo.R` — `ajustar_modelo(grado, variables, n, semilla)` → lista con `fit`, `r2`, `rmse`, `residuales`
- [ ] `R/modelo.R` — `graficar_ajuste(resultado)` ggplot
- [ ] `R/run_headless.R` — `correr(escenario, ...)` escribe png+json+csv+log
- [ ] `R/mod_regresion.R` — `mod_regresion_ui()` + `mod_regresion_server()` (moduleServer)
- [ ] `R/mod_diagnostico.R` — QQ-plot, residuales vs ajustados, Cook's distance
- [ ] `R/app.R` — bslib UI: `page_navbar` con tabs Regresión/Diagnósticos/Datos
- [ ] UI: `page_sidebar`, `card`, `layout_columns`, `value_box` (R²/RMSE en vivo)
- [ ] Inputs: slider, range slider, numeric, select, selectize multi, checkbox, checkboxGroup, radio, dateRange, fileInput, actionButton, downloadButton
- [ ] Reactivos: `reactive`, `eventReactive`, `observeEvent`, `reactiveVal`, `reactiveValues`, `debounce`
- [ ] Plot interactivo: brush + click + dblclick → `brushedPoints()` ↔ `DT::dataTableOutput`
- [ ] UI dinámica: `conditionalPanel`, `updateSliderInput`, `insertUI`/`removeUI`, `renderUI`
- [ ] `bs_theme()` con switcher bootswatch en vivo
- [ ] Bookmarking (`enableBookmarking="server"`)
- [ ] `withProgress` + `showNotification` + botón "Guardar para el agente"
- [ ] `README.md` (esp) + `AGENT.md` (eng)
- [ ] Verificar: `Rscript -e 'source("R/run_headless.R"); correr("demo", grado=3)'` y leer `outputs/demo.json`

---

# Proyecto 2 — `libs/quarto/` (PCA + Clustering, OJS)

**Hook pedagógico**: PCA/k-means precomputados; el navegador filtra/recolorea → caso ideal estático.

- [x] `R/datos.R` — `pivot_paises()` → matriz país × año numérica para PCA
- [x] `R/modelo.R` — `calcular_pca(matriz)`, `agrupar_kmeans(datos, k)`
- [x] `R/precomputo.R` — vuelca todo a `outputs/pca.json` + `pca.csv` + `clusters.csv`
- [x] `R/run_headless.R` — idem schema S2
- [x] `dashboard.qmd` — `format: dashboard`, páginas: Visión general / PCA / Clusters / Datos
- [x] Layout: `layout: [[a,b],[c]]`, `orientation: rows`, `scrolling: true`, `theme: cosmo`
- [x] OJS inputs: `viewof anio`, `viewof k = Inputs.range(2,10)`, `Inputs.select`, `Inputs.checkbox`, `Inputs.color`, `Inputs.search`
- [x] Observable Plot: scree plot, biplot PC1×PC2 con `Plot.dot` + facetas, histograma distancias a centroide
- [x] Crossfilter: `viewof seleccion = Inputs.selection(paises)` compartido biplot ↔ tabla
- [x] Data flow: `ojs_define(datos = df)` (R→OJS); el `.qmd` lee `outputs/pca.json`
- [x] `quarto render dashboard.qmd --to html` → HTML autocontenido
- [x] `README.md` + `AGENT.md`
- [x] Verificar: `quarto render` sin errores y sliders OJS responden al abrir el HTML

> Completado por agente el 2026-08-12

---

# Proyecto 3 — `libs/shiny-live/` (ANOVA + distribuciones)

**Hook pedagógico**: artefacto portable; R corre en navegador vía webR, sin instalación. ANOVA usa `stats::aov()` (deps mínimas → cabe en webAssembly).

- [x] `R/datos.R` — `gen_anova_sintetico(k_grupos, n, efecto)` + filtro de charcoal por región
- [x] `R/modelo.R` — `correr_anova(datos)`, `graficar_qq()`, `graficar_boxplot()`, `test_normalidad()`
- [x] `R/run_headless.R` — idem schema S2
- [x] `R/app.R` — Shiny app reusando arquitectura de Proyecto 1 (mismo patrón modular)
- [x] UI: one-way ANOVA (región → producción), QQ-plot, Shapiro, boxplots por grupo, slider de `n` y su efecto en potencia
- [x] `shinylive::export()` vía `libs/shiny-live/build.R` (`construir_bundle()`): exporta desde un staging con `data/` + `libs/_comun/` adentro, sin lo cual el bundle no arranca en webR
- [x] Documentar quirks: carga async de webR, sin I/O nativo, paquetes limitados, `webr::shim_*` para uploads
- [x] `README.md` (incluye cómo servir) + `AGENT.md`
- [x] Verificar: `python3 -m http.server 8000 --directory libs/shiny-live/docs` y la app abre en navegador corriendo R vía webR

> Completado por agente el 2026-08-12
> Verificado en navegador (webR real, headless Chrome vía CDP) el 2026-08-13:
> los 3 datasets, los 4 tabs y el heatmap de potencia responden sin errores de
> consola. La verificación destapó 6 defectos (wrapper `app.R` sin `$value`,
> rutas de módulos, `conditionalPanel` con `ns()`, `bs_icon(size="xl")`,
> colisión `cargar_twins` con `_comun`, y el selector de flujos vacío);
> todos corregidos — ver "Bugs found by running the exported bundle" en
> `libs/shiny-live/AGENT.md`.

---

# Definición de "Done" (global)

- [ ] Los 3 proyectos corren interactivamente (`shiny::runApp`, `quarto render`, http.server sobre `docs/`)
- [ ] Los 3 proyectos tienen un `run_headless.R` funcional que produce png+json+csv+log
- [ ] `outputs/run_log.csv` acumula entradas de los 3 motores con schema idéntica
- [ ] `renv::status()` limpio
- [ ] Cada `AGENT.md` tiene al menos un comando `Rscript` copiable que funciona
- [ ] Ningún fichero > 300 LOC

---

# S8 — Apps por tema (`projects/NN-<slug>/`)

Los 3 proyectos de arriba son los **motores** (Shiny / Quarto+OJS / shinylive).
Además, cada tema de `data/topics-tf.csv` se implementa como una app propia en
`projects/NN-<slug>/`, todas clonadas de `projects/_template/`.

El routing (qué datos, qué paquete, qué módulo clonar, cuál es el hook
interactivo) está en **`libs/topics-map.md`**, una fila por tema.

## Decisión: los temas nuevos van sobre Shiny, no sobre OJS

**Los 3 motores se quedan como están** (cada uno enseña algo distinto), pero
**todo tema nuevo se construye sobre `projects/_template/` (Shiny)**. Razones,
en orden de peso:

1. **Techo de reactividad.** En el dashboard de OJS la estadística está
   *congelada* por `precomputo()`: el slider de `k` hace un lookup de una
   columna precomputada, no corre `kmeans`. No hay control para las variables
   del PCA, el escalado ni la semilla, porque cambiarlos exige re-ajustar en R.
   En Shiny el slider de λ corre `glmnet` de verdad. **El método es lo que
   tiene que ser reactivo, y en OJS no puede serlo.**
2. **Cero peso en la rúbrica.** La guía (`guide-eda-26A.md` §15) pide cuaderno
   RMD + diapositivas PDF + video, y puntúa código R legible (R2, 30%) y
   visualización pedagógica (R1/R3). Interactividad, JS y despliegue web: 0%.
3. **Costo de bugs.** OJS es un segundo lenguaje con contratos de valor
   invisibles y no testeable desde R. Ver S2b.

Escapar del punto 1 exigiría reimplementar `prcomp`/`kmeans` en JS: duplica la
superficie de bugs y sacrifica R2, que es el 30% de la nota.

**Quarto como motor de documentos sí conserva valor alto**: un solo `.qmd`
produce el cuaderno y, con `format: revealjs`, las diapositivas → PDF; además
renderiza `.rmd` nativamente. Lo que se encoge es **OJS**, no Quarto.

## Cómo arrancar un tema nuevo

```bash
./projects/nuevo-tema.sh 02 dbscan "DBSCAN sobre charcoal" 18
grep -rn TODO projects/02-dbscan
```

El template arranca **funcionando** (placeholder de regresión polinomial), así
que podés correr sus tests antes de tocar nada y confirmar que el cableado está
bien. Después reemplazás `modelo.R` con tu tema.

Instancia de referencia: **`projects/01-lasso/`**.

## Definición de "Done" por tema

- [ ] `modelo.R` no menciona `input`, `reactive` ni `session`
- [ ] Ningún `.R` supera 300 LOC
- [ ] **Regla de las 3 partes**: cada hiperparámetro existe en `modelo.R`,
      en `correr()` de `run_headless.R` (incluido su bloque `params`), y como
      input en `mod_main.R`. Si falta uno, la app y el batch divergen en silencio.
- [ ] `test_headless.R` verde, con al menos una **invariante del tema** (no solo
      validación del contrato S2). Ej. en LASSO: "más penalización ⇒ menos
      coeficientes activos"; "ridge nunca anula".
- [ ] `test_app.R` verde, ejercitando el hook interactivo de punta a punta
- [ ] Toda aleatoriedad tiene semilla, y la semilla viaja al JSON
- [ ] README.md (español) y AGENT.md (inglés) sin `TODO` sueltos
- [ ] `renv::snapshot()` corrido si se añadió algún paquete

## Por qué dos harness de test

`test_headless.R` no puede ver lo que se rompe del lado del cliente. Un
`conditionalPanel` mal escrito deja el servidor contento, la app responde
HTTP 200, y la feature queda **muerta en silencio**. Solo `app$get_logs()`
de `test_app.R` lo delata. Los dos son obligatorios.

## Temas compartidos (bslib)

Los presets viven en `libs/_comun/R/temas_bslib.R` (`listar_temas()`), y el
SCSS del look 8-bit en `libs/_comun/scss/retro.scss`. Toda app del curso los
hereda con `theme = tema(TEMA_INICIAL)` y el switcher del navbar.

- `SDA_TEMA=retro` — arranca con el preset 8-bit
- `SDA_THEMER=1` — monta el widget `bs_themer()` de theming en vivo, que
  imprime en consola el `bs_theme()` equivalente a lo que ajustes

Vale la pena correr `SDA_TEMA=retro Rscript .../test_app.R`: es el preset que
más CSS pisa y el primero en romperse.
