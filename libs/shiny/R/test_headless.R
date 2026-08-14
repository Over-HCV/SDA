# libs/shiny/R/test_headless.R
#
# Harness de regresion del Proyecto 1. Corre varios escenarios headless y
# valida que cada artefacto cumpla el contrato S2 de libs/sdd.md.
#
# Uso (desde la raiz del proyecto):
#   Rscript libs/shiny/R/test_headless.R
#
# Sale con codigo 0 si todo pasa, 1 si algo falla. Es el check de pre-commit
# y el patron que cada projects/NN/ copia con SUS escenarios.
#
# Los asserts y el validador S2 viven en libs/_comun/R/pruebas.R, compartidos
# con todos los proyectos.

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
source(file.path(.raiz, "libs", "shiny", "R", "run_headless.R"))

OUT_DIR <- file.path(.raiz, "libs", "shiny", "outputs")

# Escenarios: grado bajo/medio/alto, loess, y rango corto (n al limite).
ESCENARIOS <- list(
  list(nombre = "test-g1",    args = list(pais = "Colombia",  grado = 1)),
  list(nombre = "test-g3",    args = list(pais = "Colombia",  grado = 3)),
  list(nombre = "test-g5",    args = list(pais = "Brazil",    grado = 5)),
  list(nombre = "test-loess", args = list(pais = "Argentina", metodo = "loess")),
  list(nombre = "test-rango", args = list(pais = "Colombia",  grado = 2,
                                          anio_min = 2005, anio_max = 2020))
)

cat("\n=== test_headless.R — Proyecto 1 (shiny) ===\n\n")
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
  validar_s2(esc$nombre, OUT_DIR, metricas_esperadas = c("r2", "rmse", "n"))
  # correr() tambien escribe el panel de diagnosticos, sin CSV.
  validar_s2(paste0(esc$nombre, "-diagnosticos"), OUT_DIR, espera_csv = FALSE)
  cat("\n")
}

# ---------------------------------------------------------------------------
# Invariantes del tema (regresion polinomial), no solo del contrato.
# ---------------------------------------------------------------------------
cat("--- invariantes del tema\n")

g1 <- resultados[["test-g1"]]
g5 <- resultados[["test-g5"]]
rango <- resultados[["test-rango"]]

if (!is.null(g1)) {
  chk(g1$grado == 1, "grado 1 se respeta")
  chk(is.finite(g1$r2) && g1$r2 >= 0 && g1$r2 <= 1, "R2 de grado 1 en [0, 1]")
}
if (!is.null(g5)) {
  chk(g5$grado == 5, "grado 5 se respeta")
  chk(g5$n > 5, "n mayor que el grado del polinomio")
}
if (!is.null(rango)) {
  # El rango corto 2005-2020 no puede devolver mas filas que anios pedidos.
  chk(rango$n <= 16, sprintf("rango 2005-2020 acota n (n = %d)", rango$n))
}
for (nm in names(resultados)) {
  r <- resultados[[nm]]
  chk(is.finite(r$rmse) && r$rmse >= 0, sprintf("RMSE finito y no negativo (%s)", nm))
}

cat("\n")
validar_run_log(OUT_DIR, vapply(ESCENARIOS, function(e) e$nombre, character(1)))

pruebas_salir("shiny")
