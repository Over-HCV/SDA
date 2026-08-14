# learn/R/logica/distancias.R
#
# Responsabilidad: medir qué tan lejos está un punto de la nube.
#
# La distancia euclídea trata todas las direcciones por igual; la de
# Mahalanobis divide por la forma de la nube, así que un punto puede estar
# cerca del centro en cada variable por separado y lejísimos en conjunto. Ese
# es exactamente el atípico multivariado que un boxplot por columna no ve.
#
#   d²(x) = (x − x̄)ᵀ S⁻¹ (x − x̄)

#' Distancia de Mahalanobis al cuadrado de cada fila.
#'
#' @return numeric con una entrada por fila (NA en filas incompletas)
mahalanobis_cuadrado <- function(datos, columnas = NULL) {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  matriz <- as.matrix(datos[, intersect(columnas, names(datos)), drop = FALSE])
  if (ncol(matriz) < 2L) return(rep(NA_real_, nrow(matriz)))

  completos <- stats::complete.cases(matriz)
  if (sum(completos) <= ncol(matriz)) return(rep(NA_real_, nrow(matriz)))

  centro <- colMeans(matriz[completos, , drop = FALSE])
  covarianza <- stats::cov(matriz[completos, , drop = FALSE])
  inversa <- tryCatch(solve(covarianza), error = function(e) NULL)
  if (is.null(inversa)) {
    # Covarianza singular: hay colinealidad exacta. Se avisa devolviendo NA en
    # vez de inventar una pseudoinversa que el usuario no pidió.
    return(rep(NA_real_, nrow(matriz)))
  }
  distancias <- rep(NA_real_, nrow(matriz))
  distancias[completos] <- stats::mahalanobis(
    matriz[completos, , drop = FALSE], centro, inversa, inverted = TRUE)
  distancias
}

#' Cuantiles teóricos ji-cuadrado para el Q-Q de Mahalanobis.
#' Si los datos son normales multivariados, d² ~ χ²(p).
puntos_qq_mahalanobis <- function(distancias, p) {
  validas <- sort(distancias[!is.na(distancias)])
  n <- length(validas)
  if (n < 2L || p < 1L)
    return(data.frame(teorico = numeric(0), observado = numeric(0)))
  data.frame(teorico = stats::qchisq(stats::ppoints(n), df = p),
             observado = validas)
}

#' Elipsoide de concentración de dos variables: el contorno que encierra el
#' `nivel` de la masa bajo normalidad bivariada. Se deforma con la correlación,
#' que es justo lo que hay que ver.
#'
#' @return data.frame(x, y) con el contorno cerrado
elipsoide_concentracion <- function(x, y, nivel = 0.95, n_puntos = 200L) {
  completos <- !is.na(x) & !is.na(y)
  matriz <- cbind(x[completos], y[completos])
  vacio <- data.frame(x = numeric(0), y = numeric(0))
  if (nrow(matriz) < 3L) return(vacio)

  covarianza <- stats::cov(matriz)
  descomposicion <- tryCatch(chol(covarianza), error = function(e) NULL)
  if (is.null(descomposicion)) return(vacio)

  radio <- sqrt(stats::qchisq(nivel, df = 2))
  angulos <- seq(0, 2 * pi, length.out = n_puntos)
  circulo <- cbind(cos(angulos), sin(angulos)) * radio
  contorno <- circulo %*% descomposicion
  data.frame(x = contorno[, 1] + mean(matriz[, 1]),
             y = contorno[, 2] + mean(matriz[, 2]))
}
