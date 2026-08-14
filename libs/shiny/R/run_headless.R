# libs/shiny/R/run_headless.R
#
# Entrada headless para el agente. NO usa Shiny. Llama a modelo.R
# y escribe outputs/<escenario>.{png,json,csv} + append a run_log.csv
# conforme al contrato S2 del sdd.md.
#
# Ejemplo desde la raíz del proyecto:
#   Rscript -e 'source("libs/shiny/R/run_headless.R");
#                correr("demo", pais="Colombia", grado=3)'
# ---------------------------------------------------------------------------

# Bootstrap: cargar helpers comunes + modelo.
# Auto-contenido: el root-finder vive aquí para evitar chicken-and-egg
# (proyecto_raiz() todavía no está definido cuando arrancamos).
.source_proyecto <- function() {
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
  for (f in c("datos.R", "modelo.R"))
    source(file.path(raiz, "libs", "shiny", "R", f))
}

# ---------------------------------------------------------------------------
# correr: ejecuta un escenario completo headless.
# Devuelve la lista escrita (invisiblemente) y deja huella en disco.
# ---------------------------------------------------------------------------
correr <- function(escenario, pais = "Colombia", flujo = "Production",
                    grado = 3, metodo = "lm", anio_min = 1990, anio_max = 2020,
                    log_y = FALSE, semilla = 42,
                    out_dir = "libs/shiny/outputs") {
  .source_proyecto()

  datos <- series_pais(pais = pais, flujo = flujo,
                        anio_min = anio_min, anio_max = anio_max)
  if (nrow(datos) < 5)
    stop("Muy pocos datos para ", pais, " / ", flujo,
         " en el rango [", anio_min, ", ", anio_max, "]")

  res <- ajustar_modelo(datos, grado = grado, metodo = metodo, semilla = semilla)
  p   <- graficar_ajuste(res, log_y = log_y)
  diag <- diagnosticos(res)

  # Compón un panel 2x2 con patchwork
  suppressPackageStartupMessages(library(patchwork))
  panel <- (diag$qq | diag$rvf) / (diag$cook | diag$leverage) &
    ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
  panel <- patchwork::wrap_elements(panel) +
    ggplot2::ggtitle(sprintf("Diagnósticos — %s", escenario))

  # Salida principal
  escribir_salida(
    proyecto  = "shiny",
    escenario = escenario,
    params    = list(pais = pais, flujo = flujo, grado = grado,
                     metodo = metodo, anio_min = anio_min, anio_max = anio_max,
                     log_y = log_y, semilla = semilla),
    metricas  = list(r2 = res$r2, rmse = res$rmse, n = res$n),
    plot_obj  = p,
    datos_df  = cbind(res$datos, pred = as.numeric(res$pred),
                       resid = as.numeric(res$resid)),
    notas     = sprintf("Ajuste %s grado %d sobre charcoal (%s/%s)",
                         res$metodo, res$grado, pais, flujo),
    out_dir   = out_dir
  )

  # Diagnósticos como artefacto adicional
  escribir_salida(
    proyecto  = "shiny",
    escenario = paste0(escenario, "-diagnosticos"),
    params    = list(escenario_origen = escenario),
    metricas  = list(),
    plot_obj  = panel,
    datos_df  = NULL,
    notas     = "Panel de diagnósticos del escenario principal",
    out_dir   = out_dir
  )

  cat(sprintf("[correr] %s: R²=%.3f RMSE=%.3f n=%d\n",
              escenario, res$r2, res$rmse, res$n))

  invisible(res)
}

# ---------------------------------------------------------------------------
# Si se ejecuta directamente con Rscript -e, no hace nada (solo define).
# Para invocar desde shell con args, pasar nombres completos:
#   Rscript -e 'source("..."); correr("x", pais=Sys.getenv("PAIS"))'
# ---------------------------------------------------------------------------
if (FALSE) {
  # Ejemplos útiles para inspección del agente
  correr("demo-colombia",    pais = "Colombia",      grado = 3)
  correr("demo-brasil",      pais = "Brazil",         grado = 5)
  correr("demo-loess",       pais = "Argentina",      metodo = "loess")
}
