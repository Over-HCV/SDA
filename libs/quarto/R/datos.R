# libs/quarto/R/datos.R
#
# Adaptador de _comun/R/datos.R para el proyecto Quarto (PCA + clustering).
# Funciones:
#   cargar_twins(complete_cases = TRUE)  -> data.frame (gemelos, NA como ".")
#   construir_matriz(dataset, flujo)     -> matriz numérica obs × vars
#
# Convenio: charcoal = país × año (vía pivot_paises), twins = par × variable.
# Para el PCA WIDE generado en precomputo.R: obs = rownames, PC1..PC4 columnas.

TWINS_VARS <- c("DLHRWAGE","DEDUC1","AGE","AGESQ","HRWAGEH","WHITEH","MALEH",
                "EDUCH","HRWAGEL","WHITEL","MALEL","EDUCL","DEDUC2","DTEN",
                "DMARRIED","DUNCOV")

# ---------------------------------------------------------------------------
# Carga twins.csv. NA representados por "." (Ashenfelter & Krueger 1994).
# complete_cases = TRUE elimina filas con NA (necesario para prcomp/kmeans).
# ---------------------------------------------------------------------------
cargar_twins <- function(complete_cases = TRUE) {
  ruta <- file.path(proyecto_raiz(), "data", "twins.csv")
  df <- utils::read.csv(ruta, stringsAsFactors = FALSE,
                        check.names = FALSE, na.strings = ".")
  if (!all(TWINS_VARS %in% names(df))) {
    faltan <- setdiff(TWINS_VARS, names(df))
    stop("twins.csv no tiene las columnas esperadas. Faltan: ",
         paste(faltan, collapse = ", "))
  }
  df <- df[, TWINS_VARS]
  if (complete_cases) df <- df[complete.cases(df), ]
  df
}

# ---------------------------------------------------------------------------
# Matriz numérica lista para PCA / k-means.
#   dataset = "charcoal": país × año vía pivot_paises() de _comun.
#   dataset = "twins":    par de gemelos × 16 variables socioeconómicas.
# Devuelve matrix con nombres en filas y columnas (sin NAs).
# ---------------------------------------------------------------------------
construir_matriz <- function(dataset = c("charcoal", "twins"),
                             flujo = "Production") {
  dataset <- match.arg(dataset)

  if (dataset == "charcoal") {
    mat <- pivot_paises(flujo = flujo)
  } else {
    df <- cargar_twins(complete_cases = TRUE)
    mat <- as.matrix(df)
    rownames(mat) <- paste0("par_", seq_len(nrow(mat)))
  }

  # Sólamente numérico, sin NA (defensivo: pivot_paises ya imputa).
  mode(mat) <- "numeric"
  mat[!is.finite(mat)] <- 0
  stopifnot(is.matrix(mat), nrow(mat) >= 3, ncol(mat) >= 2)
  mat
}
