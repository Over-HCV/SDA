# learn/R/graficos/bivariado.R
#
# Responsabilidad: dibujar DOS variables a la vez.
#
# El enemigo de esta subsección es el sobreploteo: con 20.000 puntos la nube
# se vuelve una mancha negra y cualquier estructura desaparece. Las tres curas
# están acá y son argumentos, no magia: transparencia, jitter y conteo por
# celda (geom_bin2d, que viene con ggplot2 — hexbin sería una dependencia más).

#' Dispersión con las tres curas del sobreploteo.
#'
#' @param celdas TRUE cambia los puntos por conteo en rejilla
#' @param suavizado añade una curva loess con su banda
#' @param regresion añade la recta de mínimos cuadrados con su banda, y su
#'   ecuación al subtítulo. Con las dos a la vista se ve dónde la recta se
#'   queda corta: donde la loess se despega de ella.
graficar_dispersion <- function(datos, x, y, grupo = NULL, alfa = 0.6,
                                jitter = FALSE, celdas = FALSE,
                                suavizado = FALSE, regresion = FALSE) {
  marco <- data.frame(x = as.numeric(datos[[x]]), y = as.numeric(datos[[y]]))
  if (!is.null(grupo)) marco$grupo <- as.character(datos[[grupo]])
  marco <- marco[stats::complete.cases(marco), ]
  asociacion <- medir_asociacion(marco$x, marco$y)

  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$x, y = .data$y))
  if (celdas) {
    grafico <- grafico + ggplot2::geom_bin2d(bins = 40) + scale_fill_seq()
  } else {
    capa <- if (is.null(grupo))
      ggplot2::geom_point(alpha = alfa, color = paleta_cat(1), size = 1.4)
    else
      ggplot2::geom_point(ggplot2::aes(color = .data$grupo), alpha = alfa,
                          size = 1.4)
    grafico <- grafico + (if (jitter)
      ggplot2::geom_jitter(width = 0.02, height = 0.02, alpha = alfa,
                           color = paleta_cat(1), size = 1.4) else capa)
    if (!is.null(grupo) && !jitter)
      grafico <- grafico + scale_color_cat(length(unique(marco$grupo)))
  }
  if (suavizado)
    grafico <- grafico + ggplot2::geom_smooth(
      method = "loess", formula = y ~ x, se = TRUE, color = paleta_cat(2)[2],
      linewidth = 0.8)

  # Sin `color` en el aes: con grupo, la recta es la del total, no una por nivel.
  if (regresion)
    grafico <- grafico + ggplot2::geom_smooth(
      method = "lm", formula = y ~ x, se = TRUE, color = paleta_cat(6)[6],
      linewidth = 0.8)

  subtitulo <- sprintf("r = %.3f · rho = %.3f · n = %d · %s",
                       asociacion$pearson, asociacion$spearman,
                       asociacion$n, asociacion$comentario)
  if (regresion)
    subtitulo <- paste0(subtitulo, "\n",
                        describir_recta(ajustar_recta(marco$x, marco$y)))
  grafico +
    ggplot2::labs(x = x, y = y, subtitle = subtitulo) +
    tema_ggplot()
}

#' Dispersion con el histograma marginal de cada variable.
#'
#' Lo que aporta sobre la dispersion sola: la nube dice como se relacionan las
#' dos variables, y los marginales dicen como esta distribuida cada una por su
#' cuenta. Una correlacion debil sobre dos variables muy asimetricas se lee
#' distinto que sobre dos simetricas, y eso solo se ve con los tres a la vez.
#'
#' Se compone con `gtable`, que ggplot2 ya arrastra: `patchwork` o `ggExtra`
#' harian esto en una linea, pero serian una dependencia mas y el bundle wasm
#' es justo donde una dependencia de mas duele.
#'
#' El truco de alineacion son las dos asignaciones de geometria: copiar los
#' anchos del centro al marginal de arriba y las alturas al de la derecha hace
#' que los tres paneles empiecen y terminen en el mismo pixel. Sin eso el
#' histograma de arriba queda corrido respecto de la nube y el grafico miente.
#'
#' @return un `gtable`, que es un grob: `renderPlot()` lo dibuja igual que a un
#'   ggplot, pero no se le pueden sumar capas despues.
graficar_dispersion_marginal <- function(datos, x, y, grupo = NULL, alfa = 0.6,
                                         jitter = FALSE, celdas = FALSE,
                                         suavizado = FALSE, regresion = FALSE,
                                         clases = 30L) {
  marco <- data.frame(x = as.numeric(datos[[x]]), y = as.numeric(datos[[y]]))
  marco <- marco[stats::complete.cases(marco), ]
  asociacion <- medir_asociacion(marco$x, marco$y)

  centro <- graficar_dispersion(datos, x, y, grupo = grupo, alfa = alfa,
                                jitter = jitter, celdas = celdas,
                                suavizado = suavizado,
                                regresion = regresion) +
    ggplot2::labs(subtitle = NULL) +
    ggplot2::theme(legend.position = "none")

  # El resumen numerico sube al marginal de arriba: en el centro quedaria
  # encajonado entre el histograma y la nube.
  arriba <- .histograma_marginal(marco$x, clases) +
    ggplot2::labs(subtitle = paste0(
      sprintf("r = %.4f · cov = %.4g · n = %d", asociacion$pearson,
              asociacion$covarianza, asociacion$n),
      if (regresion) paste0("\n", describir_recta(ajustar_recta(marco$x, marco$y)))))
  derecha <- .histograma_marginal(marco$y, clases) + ggplot2::coord_flip()

  rejilla_centro <- ggplot2::ggplotGrob(centro)
  rejilla_arriba <- ggplot2::ggplotGrob(arriba)
  rejilla_derecha <- ggplot2::ggplotGrob(derecha)
  rejilla_arriba$widths <- rejilla_centro$widths
  rejilla_derecha$heights <- rejilla_centro$heights

  disposicion <- gtable::gtable(widths = grid::unit(c(4, 1), "null"),
                                heights = grid::unit(c(1, 4), "null"))
  disposicion <- gtable::gtable_add_grob(disposicion, rejilla_arriba, 1, 1,
                                         name = "arriba")
  disposicion <- gtable::gtable_add_grob(disposicion, rejilla_centro, 2, 1,
                                         name = "centro")
  disposicion <- gtable::gtable_add_grob(disposicion, rejilla_derecha, 2, 2,
                                         name = "derecha")
  disposicion
}

#' Un marginal: histograma pelado, sin ejes ni rejilla.
#'
#' No fija limites a proposito. Las dos capas miran la MISMA columna, asi que
#' la escala por defecto y su expansion del 5 % dan el mismo rango en las dos:
#' fijarlos a mano solo abriria la puerta a recortar barras del borde.
.histograma_marginal <- function(valores, clases = 30L) {
  ggplot2::ggplot(data.frame(valor = valores),
                  ggplot2::aes(x = .data$valor)) +
    ggplot2::geom_histogram(bins = clases, fill = paleta_cat(1),
                            color = "white", linewidth = 0.2) +
    tema_ggplot() +
    ggplot2::theme(axis.title = ggplot2::element_blank(),
                   axis.text = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank())
}

#' Densidad conjunta con curvas de nivel sobre los puntos.
#'
#' Donde el sobreploteo esconde la estructura, las curvas la devuelven: cada
#' anillo encierra una fracción de la masa.
graficar_densidad_conjunta <- function(datos, x, y, ancho_x = NULL,
                                       ancho_y = NULL, puntos = TRUE) {
  marco <- data.frame(x = as.numeric(datos[[x]]), y = as.numeric(datos[[y]]))
  marco <- marco[stats::complete.cases(marco), ]
  estimada <- estimar_densidad_2d(marco$x, marco$y, ancho_x, ancho_y)

  grafico <- ggplot2::ggplot()
  if (nrow(estimada$rejilla))
    grafico <- grafico +
      ggplot2::geom_raster(data = estimada$rejilla,
                           ggplot2::aes(x = .data$x, y = .data$y,
                                        fill = .data$densidad)) +
      ggplot2::geom_contour(data = estimada$rejilla,
                            ggplot2::aes(x = .data$x, y = .data$y,
                                         z = .data$densidad),
                            color = "white", linewidth = 0.3, bins = 8) +
      scale_fill_seq()
  if (puntos)
    grafico <- grafico + ggplot2::geom_point(
      data = marco, ggplot2::aes(x = .data$x, y = .data$y),
      color = "white", alpha = 0.25, size = 0.7)

  grafico +
    ggplot2::labs(x = x, y = y, fill = "densidad",
                  subtitle = sprintf("h_x = %.4g · h_y = %.4g · n = %d",
                                     estimada$ancho_x, estimada$ancho_y,
                                     estimada$n)) +
    tema_ggplot()
}

#' Mosaico de dos cualitativas: el área de cada bloque es su frecuencia y el
#' color es el residuo estandarizado.
#'
#' Un bloque grande no dice nada por sí solo — puede serlo porque su fila es
#' grande. Lo que se lee es el color: azul es más de lo esperado bajo
#' independencia, rojo es menos.
graficar_mosaico <- function(cruce) {
  largo <- contingencia_larga(cruce)
  if (!nrow(largo))
    return(ggplot2::ggplot() + ggplot2::labs(subtitle = "sin datos para cruzar") +
             tema_ggplot())

  anchos <- tapply(largo$n, largo$fila, sum)
  anchos <- anchos / sum(anchos)
  bordes <- cumsum(c(0, anchos))
  largo$x_min <- bordes[match(largo$fila, names(anchos))]
  largo$x_max <- largo$x_min + anchos[match(largo$fila, names(anchos))]

  largo <- largo[order(largo$fila, largo$columna), ]
  partes <- split(largo, largo$fila)
  largo <- do.call(rbind, lapply(partes, function(parte) {
    alturas <- parte$n / sum(parte$n)
    parte$y_min <- cumsum(c(0, utils::head(alturas, -1)))
    parte$y_max <- cumsum(alturas)
    parte
  }))

  ggplot2::ggplot(largo) +
    ggplot2::geom_rect(ggplot2::aes(xmin = .data$x_min, xmax = .data$x_max,
                                    ymin = .data$y_min, ymax = .data$y_max,
                                    fill = .data$residuo),
                       color = "white", linewidth = 0.4) +
    ggplot2::scale_fill_gradient2(low = "#D55E00", mid = "grey92",
                                  high = "#0072B2", midpoint = 0) +
    ggplot2::labs(x = names(dimnames(cruce$tabla))[1],
                  y = names(dimnames(cruce$tabla))[2],
                  fill = "residuo",
                  subtitle = sprintf("chi2 = %.2f · gl = %s · p = %.4g · V = %.3f",
                                     cruce$chi2, cruce$gl, cruce$p_valor,
                                     cruce$cramer)) +
    tema_ggplot()
}
