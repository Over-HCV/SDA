# learn/R/logica/momentos.R
#
# Responsabilidad: el vector de medias y la matriz de varianzas-covarianzas de
# un grupo de columnas, sobre las mismas filas.
#
# Es la primera pregunta de casi todo taller multivariado (x̄ y S), y la base
# de todo lo que viene después: el ACP no normado descompone S, el normado
# descompone R. Las dos piezas se calculan sobre las filas COMPLETAS a la vez:
# una media sobre 111 filas al lado de una covarianza sobre 107 no describen la
# misma nube, y la diferencia no se ve en la tabla.

#' x̄ y S de las columnas pedidas.
#'
#' @param columnas NULL = todas las numéricas
#' @return list(medias, covarianzas, n, descartadas)
momentos_muestrales <- function(datos, columnas = NULL) {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  faltan <- setdiff(columnas, names(datos))
  if (length(faltan))
    stop("no existen las columnas: ", paste(faltan, collapse = ", "),
         call. = FALSE)
  no_numericas <- columnas[!vapply(datos[columnas], is.numeric, logical(1))]
  if (length(no_numericas))
    stop("no son numéricas: ", paste(no_numericas, collapse = ", "),
         call. = FALSE)
  matriz <- as.matrix(datos[, columnas, drop = FALSE])
  completas <- stats::complete.cases(matriz)
  matriz <- matriz[completas, , drop = FALSE]
  list(medias = colMeans(matriz), covarianzas = stats::cov(matriz),
       n = nrow(matriz), descartadas = sum(!completas))
}
