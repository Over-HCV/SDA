# libs/shiny/R/datos.R
#
# Adaptador de _comun/R/datos.R para el proyecto Shiny de regresión.
# Funciones:
#   bootstrap_comun()     -> carga silenciosamente los helpers compartidos
#   series_pais(pais, flujo, anio_min, anio_max)
#                          -> data.frame(x=Year, y=Quantity, listo para lm)
#   leer_csv_usuario(file) -> data.frame normalizado (x,y) desde un CSV subido

# ---------------------------------------------------------------------------
# Bootstrap del módulo común. Busca la raíz del proyecto (definida en
# _comun) y carga los 3 ficheros. Idempotente.
# Auto-contenido: define su propio root-finder para no caer en el
# chicken-and-egg (proyecto_raiz() se define DENTRO de _comun/R/datos.R).
# ---------------------------------------------------------------------------
.bootstrap_comun_hecho <- FALSE
bootstrap_comun <- function(force = FALSE) {
  if (.bootstrap_comun_hecho && !force) return(invisible(TRUE))

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

  .bootstrap_comun_hecho <<- TRUE
  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Serie temporal de un país/flujo en formato (x, y) para regresión.
# ---------------------------------------------------------------------------
series_pais <- function(pais, flujo = "Production",
                         anio_min = 1990, anio_max = 2020,
                        .df = NULL) {
  if (is.null(.df)) {
    bootstrap_comun()
    .df <- cargar_charcoal()
  }
  d <- filtrar_charcoal(.df, paises = pais, flujos = flujo,
                        anios = seq(anio_min, anio_max))
  if (nrow(d) == 0) return(data.frame(x = numeric(), y = numeric()))
  # Agregar duplicados (pais, año) por media
  agg <- aggregate(Quantity ~ Year, data = d, FUN = mean, na.rm = TRUE)
  names(agg) <- c("x", "y")
  agg[order(agg$x), ]
}

# ---------------------------------------------------------------------------
# CSV subido por el usuario: acepta cualquier CSV, intenta adivinar columnas
# numéricas (x, y). Si no, toma las dos primeras numéricas.
# ---------------------------------------------------------------------------
leer_csv_usuario <- function(path) {
  df <- tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
  if (is.null(df) || ncol(df) < 2) {
    return(list(ok = FALSE, msg = "CSV inválido o con menos de 2 columnas."))
  }
  nums <- names(df)[vapply(df, is.numeric, logical(1))]
  if (length(nums) < 2) {
    return(list(ok = FALSE, msg = "Se requieren al menos 2 columnas numéricas."))
  }
  out <- data.frame(x = df[[nums[1]]], y = df[[nums[2]]])
  out <- out[complete.cases(out), ]
  list(ok = TRUE, msg = sprintf("Cargadas %d filas (%s vs %s).",
                                 nrow(out), nums[1], nums[2]),
       datos = out, nombres = nums)
}
