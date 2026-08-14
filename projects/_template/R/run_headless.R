# projects/__SLUG__/R/run_headless.R
#
# Entrada headless. No usa Shiny. Escribe outputs/<escenario>.{png,json,csv}
# + append a run_log.csv, conforme al contrato S2 de libs/sdd.md.
#
# Uso desde la raiz del proyecto:
#   Rscript -e 'source("projects/__SLUG__/R/run_headless.R");
#               correr("demo", grado=3)'

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
    source(file.path(raiz, "projects", "__SLUG__", "R", f))
  suppressPackageStartupMessages(library(ggplot2))
  raiz
}

# ---------------------------------------------------------------------------
# REGLA DE LAS 3 PARTES: todo hiperparametro que exista como input en
# mod_main.R tiene que existir tambien como argumento aca y viajar al bloque
# `params` de escribir_salida(). Si no, la app y el batch divergen en silencio.
#
# TODO: agrega tus parametros en los tres lugares a la vez.
# ---------------------------------------------------------------------------
correr <- function(escenario,
                    n      = 120,
                    ruido  = 1,
                    grado  = 2,
                    semilla = 42,
                    out_dir = "projects/__SLUG__/outputs") {
  .source_proyecto()

  df  <- datos_proyecto(n = n, ruido = ruido, semilla = semilla)
  res <- ajustar(df, grado = grado, semilla = semilla)

  p_principal  <- graficar_principal(res)
  p_secundario <- graficar_secundario(res)

  # --- Salida principal (contrato S2) ---
  escribir_salida(
    proyecto  = "__SLUG__",
    escenario = escenario,
    params    = list(n = n, ruido = ruido, grado = grado, semilla = semilla),
    metricas  = list(r2 = res$r2, rmse = res$rmse, n = res$n),
    plot_obj  = p_principal,
    datos_df  = tabla_resultados(res),
    notas     = sprintf("Ajuste grado %d sobre datos sinteticos (n = %d)",
                         res$grado, res$n),
    out_dir   = out_dir
  )

  # --- Artefacto secundario (sin CSV) ---
  escribir_salida(
    proyecto  = "__SLUG__",
    escenario = paste0(escenario, "-diagnostico"),
    params    = list(escenario_origen = escenario),
    metricas  = list(),
    plot_obj  = p_secundario,
    datos_df  = NULL,
    notas     = "Grafico secundario del escenario principal",
    out_dir   = out_dir
  )

  cat(sprintf("[correr] %s: R2=%.3f RMSE=%.3f n=%d\n",
              escenario, res$r2, res$rmse, res$n))

  invisible(res)
}

if (FALSE) {
  correr("demo",      grado = 2)
  correr("demo-g5",   grado = 5)
  correr("demo-ruido", ruido = 3)
}
