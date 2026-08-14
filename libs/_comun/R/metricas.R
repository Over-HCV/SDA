# libs/_comun/R/metricas.R
#
# Contrato headless (Spec S2 del sdd.md). Toda corrida headless usa
# escribir_salida() para volcar PNG + JSON + CSV + append a run_log.csv.
# Schema JSON fija e idéntica entre los 3 motores:
#
#   {
#     "timestamp": "...", "proyecto": "...", "escenario": "...",
#     "params":   {...},
#     "metricas": {...},
#     "archivos": {"plot": "...", "datos": "..."},
#     "notas":    "..."
#   }
#
# Solo depende de jsonlite (ya en renv).

# ---------------------------------------------------------------------------
# Validación + escritura de una corrida.
#   plot_obj   : ggplot o NULL (si solo se quiere métricas)
#   datos_df   : data.frame que el agente puede leer como CSV, o NULL
#   out_dir    : directorio relativo al proyecto (se crea si no existe)
# Devuelve la lista escrita (invisiblemente) con las rutas absolutas.
# ---------------------------------------------------------------------------
escribir_salida <- function(proyecto, escenario, params = list(),
                             metricas = list(), plot_obj = NULL,
                             datos_df = NULL, notas = "",
                             out_dir = "outputs") {
  stopifnot(is.character(proyecto), is.character(escenario),
            is.list(params), is.list(metricas))

  out_abs <- file.path(proyecto_raiz(), out_dir)
  if (!dir.exists(out_abs)) dir.create(out_abs, recursive = TRUE)

  archivos <- list()
  esc <- gsub("[^A-Za-z0-9_.-]", "_", escenario)  # safe filename

  # --- PNG ---
  if (!is.null(plot_obj)) {
    png_path <- file.path(out_abs, paste0(esc, ".png"))
    ggplot2::ggsave(png_path, plot = plot_obj,
                    width = 7, height = 5, dpi = 120, bg = "white")
    archivos$plot <- png_path
  }

  # --- CSV (los datos detrás del plot) ---
  if (!is.null(datos_df)) {
    csv_path <- file.path(out_abs, paste0(esc, ".csv"))
    utils::write.csv(datos_df, csv_path, row.names = FALSE)
    archivos$datos <- csv_path
  }

  # --- JSON de la corrida ---
  salida <- list(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    proyecto  = proyecto,
    escenario = escenario,
    params    = as.list(params),
    metricas  = as.list(metricas),
    archivos  = archivos,
    notas     = notas
  )
  json_path <- file.path(out_abs, paste0(esc, ".json"))
  jsonlite::write_json(salida, json_path, auto_unbox = TRUE, pretty = TRUE)

  # --- Append al log maestro (CSV simple, schema fija S2) ---
  log_path <- file.path(out_abs, "run_log.csv")
  log_row <- data.frame(
    timestamp        = salida$timestamp,
    proyecto         = proyecto,
    escenario        = escenario,
    # as.character(): toJSON devuelve clase "json", no character. Sin esto
    # write.table lo trata distinto y el quoting queda inconsistente.
    params_json      = as.character(jsonlite::toJSON(params, auto_unbox = TRUE)),
    metrica_principal = .extraer_metrica_principal(metricas),
    plot             = ifelse(is.null(archivos$plot), NA_character_, archivos$plot),
    stringsAsFactors = FALSE
  )
  existe <- file.exists(log_path)
  # qmethod = "double" es OBLIGATORIO: params_json lleva comillas adentro, y
  # write.table por defecto las escapa con backslash (qmethod = "escape"),
  # convencion que read.csv NO entiende. Con parametros sin comas el archivo
  # se leia de casualidad; en cuanto un parametro trae una coma (p. ej.
  # x_vars = "a,b,c") read.csv falla con "more columns than column names".
  utils::write.table(log_row, log_path, append = existe, sep = ",",
                     row.names = FALSE, col.names = !existe,
                     quote = TRUE, qmethod = "double")

  cat(sprintf("[escribir_salida] %s/%s -> %s\n",
              proyecto, escenario, basename(json_path)))

  invisible(salida)
}

# Heurística: primera métrica numérica del list, redondeada.
# Sirve para que el CSV de log tenga una columna escaneable.
.extraer_metrica_principal <- function(metricas) {
  if (!length(metricas)) return(NA_real_)
  for (nm in names(metricas)) {
    v <- metricas[[nm]]
    if (is.numeric(v) && length(v) == 1) return(round(unname(v), 6))
  }
  NA_real_
}

# ---------------------------------------------------------------------------
# Lectura del log (para que el agente lo inspeccione fácilmente).
# ---------------------------------------------------------------------------
leer_run_log <- function(out_dir = "outputs") {
  log_path <- file.path(proyecto_raiz(), out_dir, "run_log.csv")
  if (!file.exists(log_path)) {
    warning("No existe ", log_path)
    return(data.frame())
  }
  utils::read.csv(log_path, stringsAsFactors = FALSE)
}
