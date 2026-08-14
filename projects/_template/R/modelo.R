# projects/__SLUG__/R/modelo.R
#
# Logica PURA del tema. INVARIANTE: aqui no hay `input`, ni `reactive`, ni
# `session`. Todo entra como valores planos y sale como listas/data.frames.
#
# Ese es el punto: run_headless.R ejecuta EXACTAMENTE lo mismo que la app,
# asi que cualquier resultado de la UI es reproducible desde la terminal.
#
# TODO(1): reemplaza ajustar() por la funcion de tu tema.
#          Mira la columna "modelo.R" de tu fila en libs/topics-map.md.
# TODO(2): reemplaza los graficar_*() por los de tu tema.
# TODO(3): si tu tema necesita un paquete nuevo, cargalo aca arriba y
#          corre renv::snapshot() al terminar.

# suppressPackageStartupMessages(library(TU_PAQUETE))   # TODO(3)

# Parametros por defecto del tema. Los usa tanto la UI como el headless,
# para que no se puedan desincronizar.
PAR_DEFECTO <- list(
  n       = 120,
  ruido   = 1,
  grado   = 2
)

# ---------------------------------------------------------------------------
# TODO(1) — Ajuste principal.
#
# Contrato de retorno: una lista que SIEMPRE traiga
#   $datos   data.frame usado (para el CSV del contrato S2)
#   $n       tamano efectivo
#   + las metricas de tu tema (numericos de largo 1, para el JSON)
#
# El ejemplo de abajo es un placeholder funcional: regresion polinomial sobre
# datos sinteticos. Sirve para que el template CORRA desde el minuto cero;
# borralo cuando metas tu tema.
# ---------------------------------------------------------------------------
ajustar <- function(df,
                     grado = PAR_DEFECTO$grado,
                     semilla = 42) {

  stopifnot(is.data.frame(df))
  d <- df[stats::complete.cases(df[, c("x", "y")]), , drop = FALSE]

  if (nrow(d) < grado + 2)
    stop("Muy pocos datos (", nrow(d), ") para grado ", grado)

  set.seed(semilla)
  fit <- stats::lm(y ~ poly(x, grado, raw = TRUE), data = d)

  pred  <- as.numeric(stats::predict(fit))
  resid <- d$y - pred

  list(
    fit   = fit,
    datos = d,
    grado = grado,
    semilla = semilla,
    pred = pred, resid = resid,
    r2   = summary(fit)$r.squared,
    rmse = sqrt(mean(resid^2)),
    n    = nrow(d)
  )
}

# ---------------------------------------------------------------------------
# TODO(2) — Grafico principal. Es el que va al PNG del contrato S2.
#
# Convencion del proyecto: el subtitulo lleva los parametros y las metricas,
# para que el PNG se entienda solo cuando el agente lo mira sin el JSON.
# ---------------------------------------------------------------------------
graficar_principal <- function(res) {
  d <- res$datos
  d$pred <- res$pred

  p <- ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point(alpha = 0.6, size = 2) +
    ggplot2::geom_line(ggplot2::aes(y = pred), linewidth = 1,
                       color = "#c0392b") +
    ggplot2::labs(
      title = sprintf("Ajuste (grado = %d)", res$grado),
      subtitle = sprintf("R2 = %.3f | RMSE = %.3f | n = %d",
                          res$r2, res$rmse, res$n),
      x = "x", y = "y"
    )

  # tema_ggplot() viene de libs/_comun/R/temas.R. El exists() permite que
  # modelo.R se pueda sourcear solo, sin el resto del proyecto.
  if (exists("tema_ggplot", mode = "function")) p <- p + tema_ggplot()
  p
}

# ---------------------------------------------------------------------------
# TODO(2) — Grafico secundario (diagnosticos, camino, curva, lo que aplique).
# ---------------------------------------------------------------------------
graficar_secundario <- function(res) {
  d <- data.frame(pred = res$pred, resid = res$resid)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = pred, y = resid)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::geom_point(alpha = 0.6, size = 2) +
    ggplot2::labs(title = "Residuales vs ajustados",
                  x = "ajustado", y = "residual")

  if (exists("tema_ggplot", mode = "function")) p <- p + tema_ggplot()
  p
}

# ---------------------------------------------------------------------------
# Tabla que se exporta como CSV en el contrato S2.
# ---------------------------------------------------------------------------
tabla_resultados <- function(res) {
  co <- stats::coef(res$fit)
  data.frame(
    termino  = names(co),
    estimado = as.numeric(co),
    stringsAsFactors = FALSE
  )
}
