# projects/01-lasso/R/test_headless.R
#
# Harness de regresion del proyecto LASSO.
#
# Uso (desde la raiz del proyecto):
#   Rscript projects/01-lasso/R/test_headless.R
#
# Sale 0 si todo pasa, 1 si algo falla.

suppressPackageStartupMessages(library(jsonlite))

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
source(file.path(.raiz, "projects", "01-lasso", "R", "run_headless.R"))

OUT_DIR <- file.path(.raiz, "projects", "01-lasso", "outputs")

METRICAS <- c("r2", "rmse", "cv_error", "no_cero",
              "lambda_usado", "lambda_min", "lambda_1se", "n", "p")

# Escenarios: cubren los tres regimenes de alpha y los dos extremos de lambda.
ESCENARIOS <- list(
  list(nombre = "test-lasso",   args = list(alpha = 1)),
  list(nombre = "test-ridge",   args = list(alpha = 0,   lambda = 0.05)),
  list(nombre = "test-enet",    args = list(alpha = 0.5)),
  list(nombre = "test-fuerte",  args = list(alpha = 1,   lambda = 0.5)),
  list(nombre = "test-debil",   args = list(alpha = 1,   lambda = 0.0005)),
  list(nombre = "test-subset",  args = list(alpha = 1,
                                            x_vars = c("DEDUC1", "DEDUC2",
                                                       "AGE", "DTEN")))
)

cat("\n=== test_headless.R — projects/01-lasso ===\n\n")
pruebas_reset()

resultados <- list()

for (esc in ESCENARIOS) {
  cat("--- corriendo: ", esc$nombre, "\n", sep = "")
  r <- tryCatch(do.call(correr, c(list(escenario = esc$nombre), esc$args)),
                error = function(e) {
                  cat("  ERROR: ", conditionMessage(e), "\n", sep = "")
                  NULL
                })
  if (!chk(!is.null(r), "correr() no lanzo error")) { cat("\n"); next }

  resultados[[esc$nombre]] <- r
  validar_s2(esc$nombre, OUT_DIR, metricas_esperadas = METRICAS)
  validar_s2(paste0(esc$nombre, "-regularizacion"), OUT_DIR, espera_csv = FALSE)
  cat("\n")
}

# ---------------------------------------------------------------------------
# Invariantes propias del TEMA. Esto es lo que un smoke genérico no atrapa:
# que el modelo se comporte como LASSO y no como cualquier otra cosa.
# ---------------------------------------------------------------------------
cat("--- invariantes del tema\n")

fuerte <- resultados[["test-fuerte"]]
debil  <- resultados[["test-debil"]]
ridge  <- resultados[["test-ridge"]]
lasso  <- resultados[["test-lasso"]]

if (!is.null(fuerte) && !is.null(debil)) {
  chk(fuerte$no_cero < debil$no_cero,
      sprintf("mas penalizacion => menos activos (%d < %d)",
              fuerte$no_cero, debil$no_cero))
  chk(fuerte$no_cero == 0,
      sprintf("lambda = 0.5 anula todos los coeficientes (activos = %d)",
              fuerte$no_cero))
}

if (!is.null(ridge)) {
  # La propiedad que distingue ridge de LASSO: encoge pero no anula.
  chk(ridge$no_cero == ridge$p,
      sprintf("ridge (alpha=0) no anula ningun coeficiente (%d de %d)",
              ridge$no_cero, ridge$p))
}

if (!is.null(lasso)) {
  chk(lasso$lambda_1se >= lasso$lambda_min,
      "lambda.1se >= lambda.min (el 1se es mas parsimonioso)")
  chk(lasso$n == 147,
      sprintf("casos completos esperados con predictores por defecto (n = %d)",
              lasso$n))
  chk(lasso$p == 13, sprintf("13 predictores por defecto (p = %d)", lasso$p))
  chk(is.finite(lasso$cv_error) && lasso$cv_error > 0,
      "el MSE de CV es finito y positivo")
}

sub <- resultados[["test-subset"]]
if (!is.null(sub)) {
  chk(sub$p == 4, sprintf("x_vars a medida se respeta (p = %d)", sub$p))
}

cat("\n")
validar_run_log(OUT_DIR, vapply(ESCENARIOS, function(e) e$nombre, character(1)))

pruebas_salir("01-lasso")
