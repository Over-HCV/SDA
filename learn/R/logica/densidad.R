# learn/R/logica/densidad.R
#
# Responsabilidad: estimar densidades, en una y en dos dimensiones.
#
# El histograma cuenta; la densidad suaviza. El ancho de banda h es el mismo
# problema que el número de clases del histograma, y por eso los dos se mueven
# con un slider: es el hook pedagógico de la subsección.
#
# La densidad 2D se calcula acá a mano, con un núcleo gaussiano separable
# sobre una rejilla, para no traer MASS::kde2d al bundle.

#' Densidad kernel univariada.
#'
#' @param x vector numérico
#' @param ancho ancho de banda h; NULL usa la regla de Silverman
#' @param n_puntos resolución de la curva
#' @return list(curva = data.frame(x, densidad), ancho, n)
estimar_densidad <- function(x, ancho = NULL, n_puntos = 512L) {
  validos <- x[!is.na(x)]
  if (length(validos) < 2L)
    return(list(curva = data.frame(x = numeric(0), densidad = numeric(0)),
                ancho = NA_real_, n = length(validos)))
  h <- ancho %||% ancho_silverman(validos)
  if (!is.finite(h) || h <= 0) h <- max(diff(range(validos)) / 20, 1e-8)
  estimada <- stats::density(validos, bw = h, n = n_puntos)
  list(curva = data.frame(x = estimada$x, densidad = estimada$y),
       ancho = h, n = length(validos))
}

#' Regla de Silverman: h = 0.9 * min(s, RIC/1.34) * n^(-1/5).
#' Se expone porque el slider necesita un punto de partida honesto y un texto
#' que explique de dónde salió.
ancho_silverman <- function(x) {
  n <- length(x)
  if (n < 2L) return(NA_real_)
  dispersion <- min(stats::sd(x), stats::IQR(x) / 1.349)
  if (!is.finite(dispersion) || dispersion == 0) dispersion <- stats::sd(x)
  0.9 * dispersion * n^(-1 / 5)
}

#' Densidad conjunta sobre una rejilla, con núcleo gaussiano separable.
#'
#' @return list(rejilla = data.frame(x, y, densidad), ancho_x, ancho_y, n)
estimar_densidad_2d <- function(x, y, ancho_x = NULL, ancho_y = NULL,
                                n_celdas = 60L) {
  completos <- !is.na(x) & !is.na(y)
  x <- x[completos]; y <- y[completos]
  if (length(x) < 3L)
    return(list(rejilla = data.frame(x = numeric(0), y = numeric(0),
                                     densidad = numeric(0)),
                ancho_x = NA_real_, ancho_y = NA_real_, n = length(x)))

  hx <- ancho_x %||% ancho_silverman(x)
  hy <- ancho_y %||% ancho_silverman(y)
  if (!is.finite(hx) || hx <= 0) hx <- diff(range(x)) / 20 + 1e-8
  if (!is.finite(hy) || hy <= 0) hy <- diff(range(y)) / 20 + 1e-8

  eje_x <- seq(min(x) - 3 * hx, max(x) + 3 * hx, length.out = n_celdas)
  eje_y <- seq(min(y) - 3 * hy, max(y) + 3 * hy, length.out = n_celdas)
  peso_x <- outer(eje_x, x, function(a, b) stats::dnorm((a - b) / hx))
  peso_y <- outer(eje_y, y, function(a, b) stats::dnorm((a - b) / hy))
  matriz <- (peso_x %*% t(peso_y)) / (length(x) * hx * hy)

  list(rejilla = data.frame(x = rep(eje_x, times = n_celdas),
                            y = rep(eje_y, each = n_celdas),
                            densidad = as.numeric(matriz)),
       ancho_x = hx, ancho_y = hy, n = length(x))
}

#' Cortes del histograma para un número de clases dado. Se separa del gráfico
#' porque el conteo por intervalo también se muestra como tabla.
cortes_histograma <- function(x, clases = 30L) {
  validos <- x[!is.na(x)]
  if (length(validos) < 2L) return(numeric(0))
  seq(min(validos), max(validos), length.out = max(2L, clases + 1L))
}
