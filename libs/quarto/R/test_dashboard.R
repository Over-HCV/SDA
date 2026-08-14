# libs/quarto/R/test_dashboard.R
#
# Verificacion del dashboard de Quarto+OJS a nivel navegador.
#
# Por que existe: el Proyecto 1 tiene test_app.R, que lee la consola del
# navegador y encontro el bug de conditionalPanel en su PRIMERA corrida. El
# Proyecto 2 no tenia equivalente, y por eso sus tres bugs de OJS
# (pca_all.map, Inputs.selection, highlight.trim) salieron de a uno, a mano,
# al abrir el HTML. Esto es esa red.
#
# Uso (desde la raiz del proyecto):
#   Rscript libs/quarto/R/test_dashboard.R
#
# Variables de entorno:
#   SDA_SKIP_RENDER=1   no re-renderiza; usa el dashboard.html que ya exista
#   SDA_ESPERA=8        segundos de espera a que OJS asiente (default 6)
#
# Sale 0 si todo pasa, 1 si algo falla.

suppressPackageStartupMessages({
  library(jsonlite)
})

.raiz <- (function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
    d <- p
  }
})()

source(file.path(.raiz, "libs", "_comun", "R", "pruebas.R"))
source(file.path(.raiz, "libs", "_comun", "R", "pruebas_web.R"))

QMD  <- file.path(.raiz, "libs", "quarto", "dashboard.qmd")
HTML <- file.path(.raiz, "libs", "quarto", "dashboard.html")

cat("\n=== test_dashboard.R — libs/quarto (OJS, nivel navegador) ===\n\n")
pruebas_reset()

# ---------------------------------------------------------------------------
# 1. Render
# ---------------------------------------------------------------------------
if (Sys.getenv("SDA_SKIP_RENDER", "0") == "0") {
  cat("--- quarto render\n")
  # quarto render escribe en el directorio del .qmd
  res <- suppressWarnings(system2("quarto", c("render", shQuote(QMD)),
                                  stdout = TRUE, stderr = TRUE))
  estado <- attr(res, "status")
  if (!chk(is.null(estado) || estado == 0, "quarto render sin errores")) {
    cat(paste(utils::tail(res, 25), collapse = "\n"), "\n")
    pruebas_salir("quarto dashboard")
  }
} else {
  cat("--- render omitido (SDA_SKIP_RENDER=1)\n")
}

chk(file.exists(HTML), "existe dashboard.html")
if (!file.exists(HTML)) pruebas_salir("quarto dashboard")

# ---------------------------------------------------------------------------
# 2. Carga en navegador headless
#
# Las aserciones POSITIVAS son imprescindibles: una celda de OJS que revienta
# simplemente no pinta nada, asi que "cero errores" por si solo puede ser un
# falso verde sobre una pagina vacia.
# ---------------------------------------------------------------------------
cat("\n--- carga en Chrome headless\n")

espera <- as.numeric(Sys.getenv("SDA_ESPERA", "6"))

r <- verificar_html(
  HTML,
  selectores_esperados = list(
    # 5 graficos de Plot: scree, biplot, heatmap, codo, histograma.
    "svg"                  = 5,
    # Los controles del showcase tienen que existir de verdad.
    "input[type=range]"    = 3,   # k, opacity, bins
    "select"               = 3,   # dataset, pc_x, pc_y
    "input[type=color]"    = 1,   # accent
    # La tabla de Inputs.table del tab Datos.
    "table"                = 1
  ),
  espera = espera
)

# ---------------------------------------------------------------------------
# 3. Aserciones
# ---------------------------------------------------------------------------
cat("\n--- errores de runtime\n")

if (!chk(length(r$nodos_error) == 0,
         sprintf("cero celdas de OJS en error (%d encontradas)",
                 length(r$nodos_error)))) {
  for (n in utils::head(r$nodos_error, 10)) cat("        > ", n, "\n", sep = "")
}

if (!chk(length(r$errores_js) == 0,
         sprintf("cero errores JS en consola (%d encontrados)",
                 length(r$errores_js)))) {
  for (e in utils::head(r$errores_js, 10)) cat("        > ", e, "\n", sep = "")
}

# Anti-regresion explicita: los tres bugs historicos comparten esta firma.
todo_texto <- paste(c(r$nodos_error, r$errores_js), collapse = " | ")
chk(!grepl("is not a function", todo_texto, fixed = TRUE),
    "ningun 'is not a function' (la firma de los 3 bugs de OJS)")
chk(!grepl("is not defined", todo_texto, fixed = TRUE),
    "ningun 'is not defined'")

cat("\n--- contenido renderizado (anti falso-verde)\n")
for (sel in names(r$conteos)) {
  n <- r$conteos[[sel]]
  cat(sprintf("        %-22s %d\n", sel, n))
}
if (!chk(length(r$faltantes) == 0,
         sprintf("todos los selectores esperados presentes (%d faltan)",
                 length(r$faltantes)))) {
  for (f in r$faltantes) cat("        > ", f, "\n", sep = "")
}

pruebas_salir("quarto dashboard")
