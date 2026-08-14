# BRIEF — Proyecto 3: shinylive (ANOVA + distribuciones)

Eres un agente que va a implementar el **tercer de 3 proyectos** del curso
AED (Universidad del Rosario). Demuestra **shinylive** (Shiny corriendo en el
navegador vía WebAssembly/webR, sin servidor de R).

## Contexto (lee esto PRIMERO, en orden)

1. **Repositorio**: `/Users/oh/World/External/Study/UR/SDA/`
2. **Plan maestro**: `libs/sdd.md` (specs S1–S5).
3. **Proyecto 1 ya está hecho y es tu PATRÓN DE REFERENCIA**. Lee en orden:
   - `libs/shiny/README.md` y `libs/shiny/AGENT.md`
   - `libs/shiny/R/app.R` (estructura bslib page_navbar)
   - `libs/shiny/R/mod_ajuste.R` (patrón moduleServer + value boxes)
   - `libs/shiny/R/modelo.R` (lógica pura, separada de UI)
4. **`libs/_comun/R/datos.R`** ya tiene `gen_sintetico(tipo="anova")` y
   `cargar_charcoal()` y `pivot_paises()`.
5. **El entorno ya está**: R 4.6.1, renv activo, `shinylive` instalado.
   **NO reinstales nada**. **NO `brew`**. **NO `install.packages()`** sin
   verificar primero en `renv.lock`.
6. **Otro agente trabaja en paralelo** sobre `libs/quarto/`. **NO lo toques.**

## Hook pedagógico

El estudiante abre un URL y R corre **en el navegador** vía webR (WebAssembly).
Es el caso ideal de un **artefacto de enseñanza portable**: cero instalación.
ANOVA usa `stats::aov()` (deps mínimas → cabe bien en webR).

## Los dos datasets (alternables en la UI)

### Dataset A — `data/twins.csv` (estudio de gemelos)
- 183 pares × 16 variables. NA como `.` → leer con `na.strings = "."`.
- Variable clave: `HRWAGEL` (salario por hora del gemelo 1) y `HRWAGEH` (gemelo 2).
- **Factor de agrupación** (categorización de `EDUCL` con `cut()`):
  - `[0, 12)` → "Primaria/Secundaria"
  - `[12, 16)` → "Pregrado"
  - `[16, 24]` → "Posgrado"
- **ANOVA one-way**: `HRWAGEL ~ categoria_educ` → ¿difiere el salario por nivel educativo?
- Referencia: `workshops/twins/t00.rmd` (es exactamente este ejemplo,
  incluida la categorización con `cut(..., breaks=c(0,12,16,Inf), right=FALSE)`).
- Otros factores binarios disponibles: `WHITEL` (raza), `MALEL` (sexo),
  `DMARRIED` (estado civil), `DUNCOV` (cobertura sindical).

### Dataset B — `data/charcoal.csv` (panel geográfico)
- 145 países × producción de carbón vegetal.
- **Factor de agrupación**: continente del país. Como `_comun` no tiene esto,
  defínelo tú en `libs/shiny-live/R/datos.R` con una tabla país → región.
  Usa aproximadamente: **África, América del Norte, América del Sur,
  América Central, Caribe, Europa, Asia, Oceanía** (más granular que
  continente simple). No necesita ser exhaustivo, solo los 145 países que
  retorna `listar_paises()`.
- **ANOVA one-way**: `Quantity ~ region` para un flujo y año fijos
  → ¿difiere la producción por región?

El selector de dataset debe estar en la UI (`radioButtons` o `selectInput`)
y toda la pipeline (datos, modelo, plots) debe reaccionar.

## Reglas DURAS (no romper)

1. **Trabaja SOLO dentro de `libs/shiny-live/`.** NO toques:
   - `libs/_comun/`, `libs/shiny/`, `libs/quarto/`
   - `.Rprofile`, `renv/`, `renv.lock`, `.vscode/`
   - `data/`, `workshops/`, `projects/`, `temp/`
2. **Reutiliza `libs/_comun/R/`** vía `source()` con bootstrap auto-contenido.
3. **Ningún fichero > 300 LOC** (ideal < 150).
4. **Identificadores en español ASCII** (sin tildes/ñ).
5. **Cumple el contrato headless S2**.
6. **webR limita paquetes disponibles**. Restringe dependencias a:
   `shiny`, `bslib`, `ggplot2`, `DT`, `stats` (base). **NO uses** `broom`,
   `car`, `pwr`, `moments`, etc. — pueden no estar en el bundle shinylive.
   Si necesitas Levene/Bartlett/skewness/kurtosis/potencia, impleméntalos
   a mano (es directo con `stats::var()`, `stats::pf()`, simulación).
7. **NO `install.packages()`** salvo urgencia verificada.

## Entregables

```
libs/shiny-live/
├── app.R                  # wrapper mínimo: source("R/app.R") — necesario para shinylive::export()
├── R/
│   ├── datos.R            # cargar_twins(), categorizar_educ(), asignar_region(), datos_anova()
│   ├── modelo.R           # correr_anova(), graficar_qq(), graficar_boxplot(), graficar_hist(),
│   │                      # test_normalidad(), test_homocedasticidad(), potencia_simulada()
│   ├── mod_anova.R        # UI + server: ANOVA principal (inputs + boxplot + F/p value boxes)
│   ├── mod_distribucion.R # UI + server: QQ, hist, skewness/kurtosis
│   ├── mod_potencia.R     # UI + server: heatmap n × efecto de potencia simulada
│   ├── mod_resumen.R      # UI + server: verbatim con summary(aov) + tabla de tests
│   ├── app.R              # cableado (page_navbar, theme switcher, módulos)
│   └── run_headless.R     # correr(escenario, ...) -> escribe S2 outputs
├── docs/                  # export shinylive (NO versionar)
├── outputs/               # headless (se crea solo)
├── README.md              # esp, humano (como libs/shiny/README.md)
├── AGENT.md               # ing, agente
└── BRIEF.md               # este archivo (no borrar)
```

## API contracts obligatorios

### `R/datos.R` (~120 LOC)

```r
cargar_twins <- function(complete_cases = TRUE) { ... }

# Categorización exacta de workshops/twins/t00.rmd
# Devuelve factor con niveles: "Primaria/Secundaria" "Pregrado" "Posgrado"
categorizar_educ <- function(anios) {
  cut(anios, breaks = c(0, 12, 16, Inf),
       right = FALSE, include.lowest = FALSE,
       labels = c("Primaria/Secundaria", "Pregrado", "Posgrado"))
}

# Tabla país → región (continente / subregión). Para los ~145 países de
# listar_paises(). Si un país no está en la tabla, asígnalo a "Otros".
asignar_region <- function(pais) { ... }

# Construye el df para ANOVA: una columna `valor` (numérica) y una `grupo` (factor).
#   dataset = "twins"   : valor = HRWAGEL, grupo = categorizar_educ(EDUCL)
#   dataset = "charcoal": valor = Quantity, grupo = asignar_region(pais)
#                        para un flujo + año fijos (parámetros)
datos_anova <- function(dataset = c("twins", "charcoal"),
                         flujo = "Production", anio = 2019,
                         k_grupos = NULL,         # para modo sintético
                         n_por_grupo = 30,
                         efecto = 5, ruido = 1,
                         semilla = 42,
                         balanceado = TRUE) { ... }
```

### `R/modelo.R` (~150 LOC)

```r
# ANOVA one-way. Devuelve list con:
#   fit = aov, F, p, gl_entre, gl_intra, MSE,
#   medias_grupo = named vector, residuals = numeric,
#   shapiro_stat, shapiro_p,                    # normalidad de residuales
#   levene_stat, levene_p,                      # homocedasticidad (Levene clásico, IMPLEMENTADO A MANO)
#   bartlett_stat, bartlett_p,                  # alternativa
#   skewness, kurtosis,                         # IMPLEMENTADOS A MANO (sin moments::)
#   datos = df original, grupos = levels(grupo)
correr_anova <- function(datos, semilla = 42) { ... }

# QQ-plot ggplot con línea de referencia
graficar_qq <- function(res) { ... }

# Boxplot por grupo + jitter + media marcada
graficar_boxplot <- function(res) { ... }

# Histograma de residuales con curva normal superpuesta
graficar_hist <- function(res) { ... }

# Texto para verbatimTextOutput
formatear_resumen_anova <- function(res) { ... }

# Potencia simulada: para una grilla de n y efecto, correr correr_anova()
# N_sim veces y calcular fracción con p < 0.05.
# Devuelve data.frame(n, efecto, potencia) para heatmap ggplot.
potencia_simulada <- function(ns = c(10, 20, 30, 50, 100),
                               efectos = seq(0, 20, by = 2),
                               k_grupos = 3, ruido = 1,
                               N_sim = 50, semilla = 42) { ... }
```

### `R/mod_anova.R` (~150 LOC)

UI con bslib: `page_sidebar` con inputs:
- `radioButtons("dataset", "Dataset", c("twins", "charcoal", "sintético"))`
- `conditionalPanel` que muestra inputs distintos por dataset:
  - twins: nada extra (categorización es fija)
  - charcoal: `selectInput("flujo", ...)`, `sliderInput("anio", ...)`
  - sintético: `sliderInput("k_grupos", ...)`, `sliderInput("n", ...)`,
    `sliderInput("efecto", ...)`, `sliderInput("ruido", ...)`
- `numericInput("semilla", ...)`, `actionButton("regenerar", "Regenerar")`

Outputs: value boxes (F, p, n_total), `plotOutput` (boxplot, con brush),
`verbatimTextOutput` (summary corto).

### `R/mod_distribucion.R` (~80 LOC)

QQ + hist + tabla con skewness, kurtosis, Shapiro W/p. `plotOutput` brush que
se sincroniza con `mod_anova` para excluir outliers y ver el efecto.

### `R/mod_potencia.R` (~100 LOC)

Grid `sliderInput` para `N_sim` (10–200) y `k_grupos`.
Heatmap ggplot del resultado de `potencia_simulada()`.
`withProgress` porque la simulación es pesada.

### `R/mod_resumen.R` (~60 LOC)

`verbatimTextOutput` con `summary(aov)` + tabla `DT` con los tests
(Shapiro, Levene, Bartlett) y sus p-values.

### `R/run_headless.R` (~80 LOC)

```r
correr <- function(escenario = "anova-demo",
                   dataset = "twins",
                   flujo = "Production", anio = 2019,
                   k_grupos = 4, n_por_grupo = 30, efecto = 5, ruido = 1,
                   semilla = 42, balanceado = TRUE,
                   out_dir = "libs/shiny-live/outputs") { ... }
```

Escribe `<escenario>.{png,json,csv}` con schema S2 vía `escribir_salida()`.
Las `metricas` deben incluir `F`, `p`, `shapiro_p`, `levene_p`.

### `app.R` (en `R/`)

- Bootstrap auto-contenido (copia el patrón de `libs/shiny/R/app.R`).
- `page_navbar` con tabs: ANOVA, Distribución, Potencia, Resumen.
- Theme switcher (limitado a 2-3 temas).
- `enableBookmarking = "server"` (solo funciona en R nativo, no en webR;
  documéntalo).

### `app.R` (en raíz de `libs/shiny-live/`)

```r
# Wrapper requerido por shinylive::export() — debe haber un app.R en la
# raíz del directorio exportado.
source("R/app.R")
```

## Showcase Shiny (debe cubrir los MISMOS componentes que `libs/shiny/`)

Copia la checklist de showcase de `libs/shiny/README.md` y asegúrate de
incluir: `page_navbar`, `page_sidebar`, `card`, `value_box`,
`layout_columns`, `accordion`, `conditionalPanel`, todos los inputs típicos
(slider, numeric, select, radio, checkbox, checkboxGroup, actionButton,
downloadButton), `reactive`, `eventReactive`, `observeEvent`, `reactiveVal`,
`brushedPoints`, `DT::dataTableOutput`, `verbatimTextOutput`,
`renderUI`/`uiOutput`, `showNotification`, `withProgress`, `moduleServer`.

## Showcase shinylive ESPECÍFICO (el valor único de este proyecto)

1. **`shinylive::export("libs/shiny-live", "libs/shiny-live/docs")`** produce
   bundle estático.
2. Servir con `python3 -m http.server 8000 --directory libs/shiny-live/docs`.
3. Documentar en README las **limitaciones de webR** y cómo se manifiestan:
   - Carga async inicial (webR descarga R + paquetes al navegador).
   - No hay I/O nativo; `fileInput` requiere `webr::shim_*`.
   - Paquetes limitados a los bundled.
   - Cálculos más lentos que R nativo (~2-5×).
4. Mostrar un mensaje al usuario mientras webR inicializa.

## Verificación (definition of done)

1. **Sintaxis R**:
   ```bash
   for f in libs/shiny-live/R/*.R libs/shiny-live/app.R; do
     Rscript -e "invisible(parse('$f')); cat('$f OK\n')"
   done
   ```
2. **Smoke test de app.R** (R nativo, no webR):
   ```bash
   Rscript -e 'source("libs/shiny-live/R/app.R", local=TRUE); cat("OK\n")'
   ```
3. **Headless**:
   ```bash
   Rscript -e 'source("libs/shiny-live/R/run_headless.R"); correr("demo-twins", dataset="twins")'
   Rscript -e 'source("libs/shiny-live/R/run_headless.R"); correr("demo-charcoal", dataset="charcoal")'
   ls libs/shiny-live/outputs/
   cat libs/shiny-live/outputs/demo-twins.json   # schema S2
   ```
4. **App arranca en R nativo**:
   ```bash
   Rscript -e 'shiny::runApp("libs/shiny-live/R/app.R", port=4568,
                             launch.browser=FALSE, host="127.0.0.1")' &
   sleep 12
   curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4568/  # 200
   kill %1
   ```
5. **Export shinylive** (puede tardar varios minutos la primera vez):
   ```bash
   Rscript -e 'shinylive::export("libs/shiny-live", "libs/shiny-live/docs")'
   python3 -m http.server 8000 --directory libs/shiny-live/docs &
   sleep 3
   curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8000/
   kill %1
   ```
   Verificar manualmente en el navegador que la app carga y responde
   (webR inicializa en ~10-30s la primera vez).
6. **Ningún archivo > 300 LOC** (`wc -l libs/shiny-live/R/*.R libs/shiny-live/app.R`).

## Definition of done global

- [ ] Todos los archivos entregados con sintaxis OK.
- [ ] `correr("demo-twins")` y `correr("demo-charcoal")` generan outputs S2.
- [ ] `shiny::runApp("libs/shiny-live/R/app.R")` arranca en R nativo (HTTP 200).
- [ ] `shinylive::export()` produce `docs/` servible con `python3 -m http.server`.
- [ ] La app exportada carga en navegador (webR inicializa).
- [ ] Selector de dataset (twins / charcoal / sintético) funciona.
- [ ] Heatmap de potencia se renderiza con `withProgress`.
- [ ] Ningún archivo > 300 LOC.
- [ ] `README.md` (esp) + `AGENT.md` (eng) escritos, incluyen sección webR.
- [ ] **Al terminar, actualiza `libs/sdd.md`** marcando con `[x]` todas las
      casillas de "Proyecto 3" y agrega al final de esa sección:
      `> Completado por agente el <YYYY-MM-DD>`.
- [ ] No tocaste archivos fuera de `libs/shiny-live/` (salvo sdd.md).

## Gotchas específicos de shinylive + webR

- **NO `library(broom)`**: puede no estar bundled. Tidy a mano:
  `tidy_aov <- function(fit) as.data.frame(broom:::tidy_aov(fit))` → mejor
  usa `unclass(anova(fit))` y construye el df tú mismo.
- **NO `pwr::pwr.anova.test`**: implementa potencia por simulación en
  `mod_potencia.R` (N_sim iteraciones, cuenta fracción con p<0.05).
- **NO `car::leveneTest`**: Levene a mano = calcula mediana por grupo,
  luego ANOVA de las desviaciones absolutas a la mediana de cada grupo.
- **NO `moments::skewness`/`kurtosis`**: impleméntalos a mano
  (definiciones estándar de Fisher/Pearson, una línea cada una).
- **`shinylive::export()`** busca un `app.R` en la raíz del directorio
  exportado. Por eso hay `libs/shiny-live/app.R` (wrapper).
- **El render inicial en webR tarda 10–30s**: muestra un mensaje tipo
  "Inicializando webR..." usando `showModal()` o un `withProgress` en
  `session$onContentLoaded(() => ...)`.
- **ggplot2 en webR**: soportado pero más lento. Mantén plots simples.
- **bslib en webR**: funciona. **Evita Google Fonts externas** (tardan o
  fallan en bundle); usa `bs_theme(bootswatch = "flatly")` sin `base_font`.
- **Bookmarking NO funciona** en el artefacto estático exportado (no hay
  servidor). Si lo activas, solo funcionará en `runApp()` tradicional.
  Documenta esto en README.

## Cuando te atasques

1. Re-lee este archivo completo.
2. Mira `libs/shiny/R/app.R` y `libs/shiny/R/mod_ajuste.R` (mismo patrón).
3. Lee `libs/_comun/R/datos.R` (`gen_sintetico(tipo="anova")` ya existe).
4. Lee `workshops/twins/t00.rmd` para entender el dataset twins.
5. Si webR falla por un paquete, replanifica con menos dependencias.
6. Si `shinylive::export()` falla, revisa que `libs/shiny-live/app.R` exista
   y sea un entry-point válido.
7. **NO agregues helpers a `_comun/`**. Si lo necesitas, detente y reporta.
