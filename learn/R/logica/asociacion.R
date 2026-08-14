# learn/R/logica/asociacion.R
#
# Responsabilidad: medir cómo se mueven juntas dos o más columnas.
#
# Pearson mide relación LINEAL; Spearman mide monotonía. Cuando las dos
# difieren mucho, la relación existe y no es una recta: por eso las funciones
# devuelven las dos y la UI muestra ambas, en vez de elegir por el usuario.

#' Asociación entre dos vectores numéricos.
#'
#' @return list(n, pearson, spearman, p_valor, comentario)
medir_asociacion <- function(x, y, metodo = "pearson") {
  completos <- !is.na(x) & !is.na(y)
  x <- x[completos]; y <- y[completos]
  n <- length(x)
  if (n < 3L)
    return(list(n = n, pearson = NA_real_, spearman = NA_real_,
                p_valor = NA_real_, comentario = "faltan observaciones"))

  pearson <- suppressWarnings(stats::cor(x, y, method = "pearson"))
  spearman <- suppressWarnings(stats::cor(x, y, method = "spearman"))
  prueba <- tryCatch(stats::cor.test(x, y, method = metodo),
                     error = function(e) NULL)
  brecha <- abs(spearman) - abs(pearson)
  comentario <- if (is.na(brecha)) "no calculable"
    else if (brecha > 0.15) "monotona pero no lineal: mira Spearman"
    else if (abs(pearson) < 0.1) "sin relacion lineal apreciable"
    else "relacion aproximadamente lineal"

  list(n = n, pearson = pearson, spearman = spearman,
       p_valor = if (is.null(prueba)) NA_real_ else prueba$p.value,
       comentario = comentario)
}

#' Matriz de correlación de las columnas numéricas.
#'
#' @param reordenar TRUE agrupa las variables parecidas con un dendrograma;
#'   es lo que convierte un mapa de calor en algo legible.
#' @return matrix con dimnames
matriz_correlacion <- function(datos, columnas = NULL, metodo = "pearson",
                               reordenar = FALSE) {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- intersect(columnas, names(datos))
  if (length(columnas) < 2L) return(matrix(numeric(0), 0, 0))

  matriz <- suppressWarnings(stats::cor(
    datos[, columnas, drop = FALSE], use = "pairwise.complete.obs",
    method = metodo))
  matriz[!is.finite(matriz)] <- 0
  if (!reordenar || nrow(matriz) < 3L) return(matriz)

  orden <- tryCatch(
    stats::hclust(stats::as.dist(1 - abs(matriz)))$order,
    error = function(e) seq_len(nrow(matriz)))
  matriz[orden, orden, drop = FALSE]
}

#' Pasa la matriz de correlación a formato largo, que es lo que consume ggplot.
correlacion_larga <- function(matriz) {
  if (!length(matriz)) return(data.frame())
  nombres <- rownames(matriz)
  data.frame(fila = rep(nombres, times = ncol(matriz)),
             columna = rep(colnames(matriz), each = nrow(matriz)),
             correlacion = as.numeric(matriz), stringsAsFactors = FALSE)
}

#' Normaliza columnas a una escala común. Las coordenadas paralelas no se
#' pueden leer sin esto: la variable de mayor rango se come el gráfico.
#'
#' @param metodo "minmax" (0..1) o "z" (centrada y escalada)
normalizar_columnas <- function(datos, columnas = NULL, metodo = "minmax") {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  copia <- datos
  for (columna in intersect(columnas, names(datos))) {
    valores <- as.numeric(datos[[columna]])
    copia[[columna]] <- if (identical(metodo, "z")) {
      desviacion <- stats::sd(valores, na.rm = TRUE)
      if (!is.finite(desviacion) || desviacion == 0) valores * 0
      else (valores - mean(valores, na.rm = TRUE)) / desviacion
    } else {
      rango <- range(valores, na.rm = TRUE)
      if (diff(rango) == 0) valores * 0 else (valores - rango[1]) / diff(rango)
    }
  }
  copia
}
