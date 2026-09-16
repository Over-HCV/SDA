# learn/R/graficos/univariado.R
#
# Responsabilidad: dibujar UNA variable. Histograma, densidad, caja y Q-Q.
#
# Estas funciones reciben los datos YA muestreados: quien decide el muestreo es
# el módulo de UI, que también dibuja el badge (C8). Un gráfico que muestrea por
# su cuenta esconde la decisión.
#
# Todas devuelven un ggplot y ninguna toca `input`: se pueden correr con
# Rscript sin Shiny cargado (C3).

#' Histograma, con densidad kernel superpuesta si se pide.
#'
#' El número de clases es el hiperparámetro del gráfico: con pocas todo parece
#' una campana, con muchas es ruido dentado. Por eso va como argumento y no
#' como decisión escondida.
graficar_histograma <- function(datos, columna, clases = 30L,
                                densidad = FALSE, ancho = NULL,
                                log_x = FALSE, normal = FALSE) {
  valores <- as.numeric(datos[[columna]])
  marco <- data.frame(valor = valores[!is.na(valores)])
  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$valor)) +
    ggplot2::geom_histogram(
      ggplot2::aes(y = ggplot2::after_stat(density)), bins = clases,
      fill = paleta_cat(1), color = "white", linewidth = 0.2) +
    ggplot2::labs(x = columna, y = "densidad",
                  subtitle = sprintf("%d clases · n = %d", clases, nrow(marco))) +
    tema_ggplot()

  if (densidad) {
    curva <- estimar_densidad(marco$valor, ancho)$curva
    grafico <- grafico + ggplot2::geom_line(
      data = curva, ggplot2::aes(x = .data$x, y = .data$densidad),
      color = paleta_cat(2)[2], linewidth = 0.9)
  }
  if (normal)
    grafico <- grafico + .capa_normal(marco$valor)
  if (log_x) grafico <- grafico + ggplot2::scale_x_log10()
  grafico
}

#' Densidad kernel sola, con la banda h a la vista en el subtítulo.
#'
#' `normal = TRUE` añade la curva N(media, desvío) de los propios datos: es el
#' modelo normal "estimado", contra el que se compara la estimación kernel.
graficar_densidad <- function(datos, columna, ancho = NULL, relleno = TRUE,
                              normal = FALSE) {
  valores <- as.numeric(datos[[columna]])
  estimada <- estimar_densidad(valores, ancho)
  grafico <- ggplot2::ggplot(estimada$curva,
                             ggplot2::aes(x = .data$x, y = .data$densidad))
  if (relleno)
    grafico <- grafico + ggplot2::geom_area(fill = paleta_cat(1), alpha = 0.25)
  grafico <- grafico +
    ggplot2::geom_line(color = paleta_cat(1), linewidth = 0.9)
  # Media y desvío de los DATOS. Antes salían de estimada$curva$x, la malla
  # equiespaciada del kernel: la normal quedaba centrada en el rango y el doble
  # de ancha, y cualquier variable parecía lejos de la normal.
  if (normal)
    grafico <- grafico + .capa_normal(valores[!is.na(valores)])
  grafico +
    ggplot2::labs(x = columna, y = "densidad",
                  subtitle = sprintf("ancho de banda h = %.4g · n = %d",
                                     estimada$ancho, estimada$n)) +
    tema_ggplot()
}

#' La normal ajustada por momentos, como capa reutilizable.
#'
#' Se dibuja sobre el rango de los datos (más un colchón del 10 % a cada lado):
#' stat_function evaluaría en toda la escala x y las colas planas mienten.
.capa_normal <- function(valores) {
  media <- mean(valores)
  desviacion <- stats::sd(valores)
  colchon <- 0.1 * diff(range(valores))
  malla <- data.frame(x = seq(min(valores) - colchon, max(valores) + colchon,
                              length.out = 200))
  malla$densidad <- stats::dnorm(malla$x, media, desviacion)
  ggplot2::geom_line(
    data = malla, ggplot2::aes(x = .data$x, y = .data$densidad),
    color = paleta_cat(6)[6], linewidth = 0.8, linetype = "dashed")
}

#' Caja y bigotes de una variable. Los bigotes llegan hasta 1,5 veces el rango
#' intercuartílico: los puntos de más allá son los atípicos de Tukey.
graficar_boxplot <- function(datos, columna, mostrar_atipicos = TRUE,
                             anotar = TRUE) {
  valores <- as.numeric(datos[[columna]])
  marco <- data.frame(valor = valores[!is.na(valores)])
  ggplot2::ggplot(marco, ggplot2::aes(y = .data$valor, x = "")) +
    ggplot2::geom_boxplot(
      fill = paleta_cat(1), alpha = 0.3, width = 0.35,
      outlier.shape = if (mostrar_atipicos) 21 else NA,
      outlier.color = paleta_cat(6)[6]) +
    (if (anotar) capa_cuartiles(marco$valor) else NULL) +
    ggplot2::coord_flip() +
    ggplot2::labs(y = columna, x = NULL) +
    tema_ggplot()
}

#' Q1, mediana y Q3 escritos sobre la caja.
#'
#' Sin los números, describir la caja es leerla contra el eje a ojo y termina
#' siendo intuición; con ellos el valor que se cita en el informe está en la
#' figura. Son los cuartiles tipo 7, los mismos con los que ggplot2 la dibuja.
capa_cuartiles <- function(valores, posicion = 1.28) {
  cuartiles <- stats::quantile(valores, c(0.25, 0.5, 0.75), na.rm = TRUE)
  ggplot2::annotate("text", x = posicion, y = cuartiles,
                    label = format(round(cuartiles, 2), trim = TRUE),
                    size = 3, color = "grey25", check_overlap = TRUE)
}

#' Cajas comparadas por grupo, con violín opcional.
#'
#' El violín muestra la forma que la caja resume; con grupos bimodales la caja
#' sola miente y el violín lo delata.
graficar_boxplot_grupos <- function(datos, columna, grupo, violin = FALSE,
                                    puntos = FALSE, anotar = TRUE) {
  marco <- data.frame(valor = as.numeric(datos[[columna]]),
                      grupo = as.character(datos[[grupo]]),
                      stringsAsFactors = FALSE)
  marco <- marco[!is.na(marco$valor) & !is.na(marco$grupo), ]
  n_grupos <- length(unique(marco$grupo))

  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$grupo,
                                                 y = .data$valor,
                                                 fill = .data$grupo))
  if (violin)
    grafico <- grafico + ggplot2::geom_violin(alpha = 0.25, color = NA)
  grafico <- grafico +
    ggplot2::geom_boxplot(alpha = 0.55, width = if (violin) 0.25 else 0.5,
                          outlier.shape = 21)
  if (puntos)
    grafico <- grafico + ggplot2::geom_jitter(width = 0.12, alpha = 0.3,
                                              size = 0.8)
  # Por grupo solo se escribe la mediana: los tres cuartiles de cada caja, con
  # seis grupos, tapan el gráfico que vienen a explicar.
  if (anotar)
    grafico <- grafico + ggplot2::stat_summary(
      fun = stats::median, geom = "text", vjust = -0.6, size = 3,
      color = "grey25",
      ggplot2::aes(label = format(round(ggplot2::after_stat(.data$y), 2),
                                  trim = TRUE)))
  grafico +
    scale_fill_cat(n_grupos) +
    ggplot2::labs(x = grupo, y = columna, fill = grupo) +
    tema_ggplot() +
    ggplot2::theme(legend.position = "none")
}

#' Q-Q normal con la recta de los cuartiles.
#'
#' Se lee por las colas: una S acostada es asimetría, y los extremos que se
#' despegan hacia arriba son colas pesadas.
graficar_qq <- function(datos, columna) {
  valores <- as.numeric(datos[[columna]])
  puntos <- puntos_qq(valores)
  recta <- recta_qq(valores)
  diagnostico <- evaluar_normalidad(valores)

  ggplot2::ggplot(puntos, ggplot2::aes(x = .data$teorico, y = .data$observado)) +
    ggplot2::geom_abline(slope = recta$pendiente, intercept = recta$corte,
                         color = "grey55", linewidth = 0.6, linetype = "dashed") +
    ggplot2::geom_point(color = paleta_cat(1), alpha = 0.6, size = 1.3) +
    ggplot2::labs(x = "cuantil teorico normal", y = paste("cuantil de", columna),
                  subtitle = sprintf("%s · p = %.4g · %s",
                                     diagnostico$prueba, diagnostico$p_valor,
                                     diagnostico$veredicto)) +
    tema_ggplot()
}

#' Barras de frecuencia de una cualitativa, ordenadas por conteo.
graficar_barras <- function(datos, columna, maximo_categorias = 20L) {
  tabla <- utils::head(tabla_frecuencias(datos[[columna]]), maximo_categorias)
  tabla$categoria <- factor(tabla$categoria, levels = rev(tabla$categoria))
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$categoria, y = .data$n)) +
    ggplot2::geom_col(fill = paleta_cat(1), width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = columna, y = "frecuencia") +
    tema_ggplot()
}
