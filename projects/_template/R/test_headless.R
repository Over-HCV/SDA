# projects/__SLUG__/R/test_headless.R
#
# Harness de regresion. Corre escenarios headless y valida el contrato S2.
#
# Uso (desde la raiz del proyecto):
#   Rscript projects/__SLUG__/R/test_headless.R
#
# Sale 0 si todo pasa, 1 si algo falla. Es el check de pre-commit.

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
source(file.path(.raiz, "projects", "__SLUG__", "R", "run_headless.R"))

OUT_DIR <- file.path(.raiz, "projects", "__SLUG__", "outputs")

# Metricas que TIENEN que estar en el JSON y ser numericas finitas.
METRICAS <- c("r2", "rmse", "n")

# TODO: escenarios de TU tema. Cubri los extremos del hiperparametro
# principal y al menos un caso degenerado (pocos datos, sin variables, etc).
ESCENARIOS <- list(
  list(nombre = "test-base",  args = list(grado = 2)),
  list(nombre = "test-g1",    args = list(grado = 1)),
  list(nombre = "test-g5",    args = list(grado = 5)),
  list(nombre = "test-ruido", args = list(grado = 2, ruido = 3)),
  list(nombre = "test-n",     args = list(grado = 2, n = 40))
)

cat("\n=== test_headless.R — projects/__SLUG__ ===\n\n")
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
  validar_s2(paste0(esc$nombre, "-diagnostico"), OUT_DIR, espera_csv = FALSE)
  cat("\n")
}

# ---------------------------------------------------------------------------
# TODO — Invariantes del TEMA.
#
# Esto es lo que distingue un test util de un smoke generico: propiedades que
# TIENEN que cumplirse si el metodo esta bien implementado.
# Ejemplos reales del proyecto 01-lasso:
#   - mas penalizacion => menos coeficientes activos
#   - ridge (alpha=0) nunca anula un coeficiente
#   - lambda.1se >= lambda.min
# ---------------------------------------------------------------------------
cat("--- invariantes del tema\n")

g1 <- resultados[["test-g1"]]
g5 <- resultados[["test-g5"]]

if (!is.null(g1) && !is.null(g5)) {
  # Mas grados de libertad no pueden EMPEORAR el ajuste dentro de muestra.
  chk(g5$r2 >= g1$r2 - 1e-8,
      sprintf("mas grado no baja el R2 dentro de muestra (%.4f >= %.4f)",
              g5$r2, g1$r2))
}
for (nm in names(resultados)) {
  r <- resultados[[nm]]
  chk(is.finite(r$rmse) && r$rmse >= 0,
      sprintf("RMSE finito y no negativo (%s)", nm))
}

cat("\n")
validar_run_log(OUT_DIR, vapply(ESCENARIOS, function(e) e$nombre, character(1)))

pruebas_salir("__SLUG__")
