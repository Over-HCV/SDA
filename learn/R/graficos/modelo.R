# learn/R/graficos/modelo.R
#
# Responsabilidad: dibujar el modelo ANTES de ajustarlo.
#
# Ninguna de estas figuras necesita un ajuste hecho: todas salen de la
# geometría del método más los datos. Es lo que convierte a la fase 2 en algo
# más que un formulario.
#
# Reciben tablas ya calculadas por R/logica/modelo_geometria.R y devuelven un
# ggplot, sin tocar input (C3).

#' El espacio de hipótesis: qué gana cada dirección candidata.
#'
#' Cada punto de la curva es un modelo posible. El máximo es la primera
#' componente principal: no hay que ajustar nada para verlo, solo mirar la
#' familia entera de una vez.
#'
#' @param familia salida de familia_candidatas()
#' @param angulo  la dirección elegida ahora mismo, en radianes, o NULL
graficar_espacio_hipotesis <- function(familia, angulo = NULL) {
  if (!nrow(familia))
    return(.grafico_vacio("elegi dos variables numericas para ver la familia"))

  optimo <- familia[which.max(familia$varianza), ]
  grafico <- ggplot2::ggplot(familia, ggplot2::aes(x = .data$grados,
                                                   y = .data$proporcion)) +
    ggplot2::geom_line(color = paleta_cat(1), linewidth = 0.9) +
    ggplot2::geom_point(data = optimo, size = 3, color = paleta_cat(2)[2]) +
    ggplot2::scale_x_continuous(breaks = seq(0, 180, by = 30)) +
    ggplot2::labs(
      x = "direccion candidata (grados)", y = "proporcion de varianza captada",
      subtitle = sprintf("el maximo esta en %.0f grados y capta %.1f%%",
                         optimo$grados, 100 * optimo$proporcion)) +
    tema_ggplot()

  if (!is.null(angulo)) {
    grados <- (angulo * 180 / pi) %% 180
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = grados, linetype = "dashed",
                          color = "grey40")
  }
  grafico
}

#' Modelo manual: el usuario mueve el eje y ve el residuo.
#'
#' Cada segmento gris es lo que se pierde al proyectar ese punto sobre el eje.
#' La suma de sus cuadrados es el error de reconstrucción, y se minimiza
#' exactamente donde la varianza proyectada se maximiza.
#'
#' @param proyeccion salida de proyectar_en_direccion()
#' @param objetivo   salida de evaluar_objetivo(), o NULL
graficar_modelo_manual <- function(proyeccion, columnas, objetivo = NULL,
                                   alfa = 0.6) {
  if (!nrow(proyeccion))
    return(.grafico_vacio("sin filas completas en esas dos variables"))

  subtitulo <- if (is.null(objetivo) || is.na(objetivo$proporcion)) NULL else
    sprintf("capta %.1f%% de la varianza · queda fuera %.3f",
            100 * objetivo$proporcion, objetivo$error_reconstruccion)

  ggplot2::ggplot(proyeccion, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = .data$proyectado_x, yend = .data$proyectado_y),
      color = "grey65", linewidth = 0.3) +
    ggplot2::geom_point(alpha = alfa, size = 1.2, color = paleta_cat(1)) +
    ggplot2::geom_line(ggplot2::aes(x = .data$proyectado_x,
                                    y = .data$proyectado_y),
                       color = paleta_cat(2)[2], linewidth = 0.9) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = columnas[1], y = columnas[2], subtitle = subtitulo) +
    tema_ggplot()
}

#' Presupuesto de parámetros: cuántos se estiman contra cuántas filas hay.
#'
#' Se pone en rojo cuando cada parámetro se apoya en menos de cinco
#' observaciones. No es una regla sagrada, es un umbral que obliga a mirar.
#'
#' @param tabla salida de presupuesto_por_k()
#' @param k     el valor elegido ahora, para marcarlo
graficar_presupuesto <- function(tabla, k = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("sin dimensiones que contar"))

  tabla$holgura <- ifelse(tabla$razon < 1, "insuficiente",
                   ifelse(tabla$razon < 5, "justo", "holgado"))
  colores <- c(insuficiente = "#c0392b", justo = "#e0a800", holgado = "#2d8a5f")

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$k,
                                                 y = .data$parametros,
                                                 fill = .data$holgura)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_hline(yintercept = tabla$observaciones[1], linetype = "dashed",
                        color = "grey35") +
    ggplot2::annotate("text", x = min(tabla$k), y = tabla$observaciones[1],
                      label = sprintf("n = %d", tabla$observaciones[1]),
                      vjust = -0.5, hjust = 0, size = 3.2, color = "grey35") +
    ggplot2::scale_fill_manual(values = colores, name = NULL) +
    ggplot2::scale_x_continuous(breaks = tabla$k) +
    ggplot2::labs(x = "componentes retenidas (k)", y = "parametros a estimar") +
    tema_ggplot()

  if (!is.null(k) && k %in% tabla$k)
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = k, linetype = "dotted", color = "grey20")
  grafico
}
