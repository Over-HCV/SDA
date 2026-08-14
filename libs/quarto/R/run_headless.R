# libs/quarto/R/run_headless.R
#
# Entrada headless para el agente. NO usa UI. Llama a precomputo() y escribe
# los 8 CSVs + 2 JSONs + append a run_log.csv conforme al contrato S2 del
# sdd.md. Wrapper delgado sobre precomputo() (DRY).
#
# Ejemplo desde la raíz del proyecto:
#   Rscript -e 'source("libs/quarto/R/run_headless.R"); correr("ambos")'
# ---------------------------------------------------------------------------

# Bootstrap: cargar helpers comunes + modelo + precomputo. Auto-contenido.
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
  for (f in c("datos.R", "modelo.R", "precomputo.R"))
    source(file.path(raiz, "libs", "quarto", "R", f))
}

# ---------------------------------------------------------------------------
# correr: regenera outputs para el/los dataset(s) pedidos.
#   escenario = etiqueta para el run_log (no afecta los nombres de archivo)
#   dataset   = "charcoal" | "twins" | "ambos"
# Devuelve invisiblemente el listado de paths escritos.
# ---------------------------------------------------------------------------
correr <- function(escenario = "default",
                   dataset = c("ambos", "charcoal", "twins"),
                   flujo = "Production",
                   n_pcs = 4,
                   k_max = 10,
                   semilla = 42,
                   out_dir = "libs/quarto/outputs") {
  .source_proyecto()

  dataset <- match.arg(dataset)
  ds_vec <- if (dataset == "ambos") c("charcoal", "twins") else dataset

  cat(sprintf("[correr] escenario='%s' dataset=%s k_max=%d semilla=%d\n",
              escenario, paste(ds_vec, collapse="+"), k_max, semilla))

  # Forzamos regeneración (correr es la entrada "fresca" del agente).
  res <- precomputo(force = TRUE, out_dir = out_dir,
                    n_pcs = n_pcs, k_range = 2:k_max, semilla = semilla)

  # Resumen legible para el log del agente.
  for (ds in ds_vec) {
    pca_path <- file.path(proyecto_raiz(), out_dir, paste0(ds, "_pca.csv"))
    if (file.exists(pca_path)) {
      n <- length(unique(utils::read.csv(pca_path)$obs))
      cat(sprintf("  %s: %d obs escritas en %s\n", ds, n, basename(pca_path)))
    }
  }

  invisible(res)
}

# ---------------------------------------------------------------------------
# Si se ejecuta con Rscript -e, solo define correr(). Ejemplos:
if (FALSE) {
  correr("ambos")
  correr("solo-twins", dataset = "twins", k_max = 8)
}
