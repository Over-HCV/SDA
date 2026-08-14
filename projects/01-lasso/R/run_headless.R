# projects/01-lasso/R/run_headless.R
#
# Entrada headless del proyecto LASSO. No usa Shiny. Escribe
# outputs/<escenario>.{png,json,csv} + append a run_log.csv, conforme al
# contrato S2 de libs/sdd.md.
#
# Uso desde la raiz del proyecto:
#   Rscript -e 'source("projects/01-lasso/R/run_headless.R");
#               correr("lasso-base", alpha=1)'

.source_proyecto <- function() {
  raiz <- (function() {
    d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
    repeat {
      if (file.exists(file.path(d, "data", "charcoal.csv")) ||
          file.exists(file.path(d, "renv", "activate.R"))) return(d)
      p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
      d <- p
    }
  })()

  for (f in c("datos.R", "metricas.R", "temas.R"))
    source(file.path(raiz, "libs", "_comun", "R", f))
  for (f in c("datos.R", "modelo.R"))
    source(file.path(raiz, "projects", "01-lasso", "R", f))
  suppressPackageStartupMessages(library(ggplot2))
  raiz
}

# ---------------------------------------------------------------------------
# correr: un escenario completo.
#
# REGLA DE LAS 3 PARTES (ver AGENT.md): todo hiperparametro que exista como
# input en mod_main.R tiene que existir tambien como argumento aca y viajar
# al bloque `params` de escribir_salida(). Si no, la app y el batch divergen.
# ---------------------------------------------------------------------------
correr <- function(escenario,
                    y_var  = "DLHRWAGE",
                    x_vars = NULL,
                    alpha  = 1,
                    lambda = NULL,
                    nfolds = 10,
                    semilla = 42,
                    estandarizar = TRUE,
                    out_dir = "projects/01-lasso/outputs") {
  .source_proyecto()

  if (is.null(x_vars)) x_vars <- LASSO_X_DEFECTO

  df <- datos_lasso()

  res <- correr_lasso(df, y_var = y_var, x_vars = x_vars,
                       alpha = alpha, lambda = lambda,
                       nfolds = nfolds, semilla = semilla,
                       estandarizar = estandarizar)

  p_ajuste <- graficar_ajuste(res)
  p_camino <- graficar_camino(res)
  p_cv     <- graficar_cv(res)

  # Panel secundario: camino + CV, que es como se lee el tema.
  suppressPackageStartupMessages(library(patchwork))
  panel <- (p_camino / p_cv) &
    ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
  panel <- patchwork::wrap_elements(panel) +
    ggplot2::ggtitle(sprintf("Regularizacion — %s", escenario))

  # --- Salida principal (contrato S2) ---
  escribir_salida(
    proyecto  = "01-lasso",
    escenario = escenario,
    params    = list(y_var = y_var, x_vars = paste(x_vars, collapse = ","),
                     alpha = alpha,
                     lambda = if (is.null(lambda)) "cv.1se" else lambda,
                     nfolds = nfolds, semilla = semilla,
                     estandarizar = estandarizar),
    metricas  = list(r2 = res$r2, rmse = res$rmse, cv_error = res$cv_error,
                     no_cero = res$no_cero, lambda_usado = res$lambda,
                     lambda_min = res$lambda_min, lambda_1se = res$lambda_1se,
                     n = res$n, p = res$p),
    plot_obj  = p_ajuste,
    datos_df  = tabla_coefs(res),
    notas     = sprintf(
      "LASSO/elastic-net (alpha=%.2f) sobre twins: %d de %d predictores activos en lambda=%.5f",
      alpha, res$no_cero, res$p, res$lambda),
    out_dir   = out_dir
  )

  # --- Artefacto adicional: camino + CV ---
  escribir_salida(
    proyecto  = "01-lasso",
    escenario = paste0(escenario, "-regularizacion"),
    params    = list(escenario_origen = escenario),
    metricas  = list(),
    plot_obj  = panel,
    datos_df  = NULL,
    notas     = "Camino de coeficientes y curva de validacion cruzada",
    out_dir   = out_dir
  )

  cat(sprintf("[correr] %s: alpha=%.2f lambda=%.5f activos=%d/%d R2=%.3f cvMSE=%.4f n=%d\n",
              escenario, alpha, res$lambda, res$no_cero, res$p,
              res$r2, res$cv_error, res$n))

  invisible(res)
}

if (FALSE) {
  correr("lasso-base",  alpha = 1)
  correr("ridge",       alpha = 0,   lambda = 0.05)
  correr("enet",        alpha = 0.5)
  correr("lasso-fuerte", alpha = 1,  lambda = 0.3)
}
