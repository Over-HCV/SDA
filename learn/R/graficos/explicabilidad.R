# learn/R/graficos/explicabilidad.R
#
# Responsabilidad: contar QUÉ dice un ajuste, no si es bueno.
#
# Fase 4, subsección Explicabilidad. En reducción de dimensión la pregunta es
# siempre la misma: ¿qué significa esta componente? Se contesta mirando qué
# variables la forman (cargas), cómo se correlacionan con ella (círculo) y
# dónde caen las observaciones (mapa y biplot).
#
# El biplot se dibuja a mano con ggplot2 en vez de traer factoextra: son treinta
# líneas y una dependencia menos en el bundle wasm.

#' Cargas: qué variable pesa en cada componente.
#'
#' Barras con signo, no en valor absoluto: el signo dice si la variable empuja
#' hacia el lado positivo o el negativo del eje, y eso es media interpretación.
#'
#' @param tabla salida de cargas()
graficar_cargas <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay cargas que mirar"))

  tabla$variable <- stats::reorder(tabla$variable, tabla$carga)
  tabla$signo <- ifelse(tabla$carga >= 0, "positiva", "negativa")

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$carga, y = .data$variable,
                                      fill = .data$signo)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_vline(xintercept = 0, color = "grey40", linewidth = 0.4) +
    ggplot2::facet_wrap(~ etiqueta, nrow = 1) +
    ggplot2::scale_fill_manual(values = c(positiva = paleta_cat(1),
                                          negativa = paleta_cat(2)[2]),
                               name = NULL) +
    ggplot2::labs(x = "carga", y = NULL) +
    tema_ggplot()
}

#' Círculo de correlaciones: cada variable como una flecha dentro del círculo
#' unidad.
#'
#' Una flecha larga está bien representada en este plano; una corta vive en las
#' componentes que no se están mirando. Dos flechas juntas son variables que
#' dicen lo mismo, y en ángulo recto, variables independientes.
#'
#' @param tabla salida de correlaciones_componentes()
#' @param sobre_correlacion FALSE cuando se descompuso S: el círculo de radio 1
#'   no aplica y hay que decirlo en vez de dibujar un marco que engaña
graficar_circulo <- function(tabla, ejes = c("CP1", "CP2"),
                             sobre_correlacion = TRUE) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))

  angulos <- seq(0, 2 * pi, length.out = 200)
  circulo <- data.frame(x = cos(angulos), y = sin(angulos))
  limite <- max(1, max(abs(c(tabla$x, tabla$y)), na.rm = TRUE))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey85") +
    ggplot2::geom_vline(xintercept = 0, color = "grey85") +
    ggplot2::geom_segment(x = 0, y = 0,
                          ggplot2::aes(xend = .data$x, yend = .data$y),
                          color = paleta_cat(1), linewidth = 0.7,
                          arrow = ggplot2::arrow(length = ggplot2::unit(6, "pt"),
                                                 type = "closed")) +
    ggplot2::geom_text(ggplot2::aes(label = .data$variable), size = 3.3,
                       vjust = -0.6, color = "grey20") +
    ggplot2::coord_equal(xlim = c(-limite, limite), ylim = c(-limite, limite)) +
    ggplot2::labs(x = ejes[1], y = ejes[2]) +
    tema_ggplot()

  if (sobre_correlacion) {
    grafico + ggplot2::geom_path(data = circulo, color = "grey60",
                                 linewidth = 0.5)
  } else {
    grafico + ggplot2::labs(
      subtitle = "sobre S (covarianza): las flechas no estan acotadas por 1")
  }
}

#' Mapa 2D: las observaciones en el plano de dos componentes.
#'
#' @param tabla salida de coordenadas_2d()
graficar_mapa_2d <- function(tabla, ejes = c("CP1", "CP2"), alfa = 0.7) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay puntuaciones"))

  n_grupos <- length(levels(tabla$grupo))
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$x, y = .data$y,
                                      color = .data$grupo)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey88") +
    ggplot2::geom_vline(xintercept = 0, color = "grey88") +
    ggplot2::geom_point(alpha = alfa, size = 1.4) +
    scale_color_cat(n_grupos, name = NULL,
                    guide = if (n_grupos < 2L) "none" else "legend") +
    ggplot2::labs(x = ejes[1], y = ejes[2],
                  subtitle = sprintf("%d observaciones", nrow(tabla))) +
    tema_ggplot()
}

#' Biplot: observaciones y variables en el mismo plano.
#'
#' Las flechas están reescaladas para que quepan junto a los puntos; ese factor
#' es una decisión de dibujo, no un resultado, y por eso viaja al subtítulo.
#'
#' @param coordenadas salida de coordenadas_biplot()
graficar_biplot <- function(coordenadas, ejes = c("CP1", "CP2"), alfa = 0.6) {
  puntos <- coordenadas$puntos
  flechas <- coordenadas$flechas
  if (!nrow(puntos)) return(.grafico_vacio("todavia no hay puntuaciones"))

  n_grupos <- length(levels(puntos$grupo))
  ggplot2::ggplot(puntos, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey88") +
    ggplot2::geom_vline(xintercept = 0, color = "grey88") +
    ggplot2::geom_point(ggplot2::aes(color = .data$grupo), alpha = alfa,
                        size = 1.3) +
    ggplot2::geom_segment(data = flechas, x = 0, y = 0,
                          ggplot2::aes(xend = .data$x, yend = .data$y),
                          color = "grey25", linewidth = 0.7,
                          arrow = ggplot2::arrow(length = ggplot2::unit(6, "pt"),
                                                 type = "closed")) +
    ggplot2::geom_text(data = flechas, ggplot2::aes(label = .data$variable),
                       color = "grey15", size = 3.3, vjust = -0.5) +
    scale_color_cat(n_grupos, name = NULL,
                    guide = if (n_grupos < 2L) "none" else "legend") +
    ggplot2::labs(x = ejes[1], y = ejes[2],
                  subtitle = sprintf("flechas reescaladas x%.2f para que entren con los puntos",
                                     coordenadas$escala_flechas)) +
    tema_ggplot()
}
