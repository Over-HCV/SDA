# libs/quarto/R/_bootstrap.R
#
# Helper de sourceo compartido para el proyecto Quarto. Auto-contenido:
# define su propio root-finder (no depende de proyecto_raiz() todavía no
# definido) y carga silenciosamente los helpers de _comun + los propios
# del proyecto. Idempotente.
#
# Uso:
#   source("libs/quarto/R/_bootstrap.R")
#   # _comun y R/{datos,modelo,precomputo}.R ya están cargados.

.bootstrap_hecho <- FALSE

bootstrap_quarto <- function(force = FALSE) {
  if (.bootstrap_hecho && !force) return(invisible(TRUE))

  raiz <- (function() {
    d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
    repeat {
      if (file.exists(file.path(d, "data", "charcoal.csv")) ||
          file.exists(file.path(d, "renv", "activate.R"))) return(d)
      p <- dirname(d); if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
      d <- p
    }
  })()

  for (f in c("datos.R", "metricas.R", "temas.R"))
    source(file.path(raiz, "libs", "_comun", "R", f))

  for (f in c("datos.R", "modelo.R", "precomputo.R"))
    source(file.path(raiz, "libs", "quarto", "R", f))

  .bootstrap_hecho <<- TRUE
  invisible(TRUE)
}
