# learn/R/logica/normalidad.R
#
# Responsabilidad: contrastar una variable contra la normal y preparar el Q-Q.
#
# El Q-Q es el gráfico honesto y la prueba es el resumen. Van juntos a
# propósito: con n grande cualquier desvío ínfimo da p < 0.05 y la prueba dice
# "no normal" mientras el Q-Q muestra una recta. Con n chico pasa al revés.

#' Puntos del Q-Q normal: cuantil teórico contra cuantil observado.
#'
#' @return data.frame(teorico, observado) ordenado por teórico
puntos_qq <- function(x) {
  validos <- sort(x[!is.na(x)])
  n <- length(validos)
  if (n < 2L) return(data.frame(teorico = numeric(0), observado = numeric(0)))
  data.frame(teorico = stats::qnorm(stats::ppoints(n)), observado = validos)
}

#' Recta de referencia del Q-Q, por los cuartiles (como qqline()).
recta_qq <- function(x) {
  validos <- x[!is.na(x)]
  if (length(validos) < 2L) return(list(pendiente = NA_real_, corte = NA_real_))
  observados <- stats::quantile(validos, c(0.25, 0.75), names = FALSE)
  teoricos <- stats::qnorm(c(0.25, 0.75))
  pendiente <- diff(observados) / diff(teoricos)
  list(pendiente = pendiente, corte = observados[1] - pendiente * teoricos[1])
}

#' Diagnóstico de normalidad en una tabla que se puede leer entera.
#'
#' Shapiro-Wilk exige 3 <= n <= 5000; por encima se usa Kolmogorov-Smirnov
#' contra la normal estimada, y se dice cuál se usó en vez de esconderlo.
#'
#' @return list(n, asimetria, curtosis, prueba, estadistico, p_valor, veredicto)
evaluar_normalidad <- function(x) {
  validos <- x[!is.na(x)]
  n <- length(validos)
  base <- list(n = n, asimetria = .asimetria(validos),
               curtosis = .curtosis(validos), prueba = NA_character_,
               estadistico = NA_real_, p_valor = NA_real_,
               veredicto = "sin datos suficientes")
  if (n < 3L) return(base)

  resultado <- tryCatch({
    if (n <= 5000L) {
      prueba <- stats::shapiro.test(validos)
      list(nombre = "Shapiro-Wilk", estadistico = unname(prueba$statistic),
           p_valor = prueba$p.value)
    } else {
      prueba <- suppressWarnings(stats::ks.test(
        validos, "pnorm", mean(validos), stats::sd(validos)))
      list(nombre = "Kolmogorov-Smirnov", estadistico = unname(prueba$statistic),
           p_valor = prueba$p.value)
    }
  }, error = function(e) NULL)
  if (is.null(resultado)) return(base)

  base$prueba <- resultado$nombre
  base$estadistico <- resultado$estadistico
  base$p_valor <- resultado$p_valor
  base$veredicto <- if (is.na(resultado$p_valor)) "no concluyente"
    else if (resultado$p_valor < 0.05) "se rechaza la normalidad"
    else "compatible con normal"
  base
}
