# learn/R/graficos/diagnostico.R
#
# Responsabilidad: los gráficos que juzgan un ajuste ya hecho.
#
# Fase 4, subsección Diagnóstico. Van entrando por método: acá está lo que el
# ACP necesita; residuos, silueta, dendrograma y compañía llegan con sus
# métodos, en su hito.

#' Gráfico de sedimentación: cuánta varianza aporta cada componente.
#'
#' Las barras son el aporte individual; la línea, el acumulado. El "codo" es
#' donde el aporte deja de valer lo que cuesta, y es un juicio, no un cálculo:
#' por eso el corte se dibuja donde el usuario lo puso.
#'
#' @param tabla salida de varianza_explicada()
#' @param k     componentes retenidas, para marcar el corte
#' @param umbral línea de referencia del acumulado (0.8 por convención)
graficar_scree <- function(tabla, k = NULL, umbral = 0.8) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$componente)) +
    ggplot2::geom_col(ggplot2::aes(y = .data$proporcion), width = 0.65,
                      fill = paleta_cat(1)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$acumulada), color = paleta_cat(2)[2],
                       linewidth = 0.9) +
    ggplot2::geom_point(ggplot2::aes(y = .data$acumulada),
                        color = paleta_cat(2)[2], size = 1.8) +
    ggplot2::geom_hline(yintercept = umbral, linetype = "dashed",
                        color = "grey45") +
    ggplot2::scale_x_continuous(breaks = tabla$componente) +
    ggplot2::scale_y_continuous(labels = function(v) paste0(round(100 * v), "%")) +
    ggplot2::labs(x = "componente", y = "varianza explicada",
                  subtitle = .subtitulo_scree(tabla, k, umbral)) +
    tema_ggplot()

  if (!is.null(k) && k %in% tabla$componente)
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = k + 0.5, linetype = "dotted",
                          color = "grey20")
  grafico
}

.subtitulo_scree <- function(tabla, k, umbral) {
  alcanza <- which(tabla$acumulada >= umbral)
  parte_umbral <- if (length(alcanza))
    sprintf("con %d componentes se pasa el %.0f%%", alcanza[1], 100 * umbral)
    else sprintf("ninguna cantidad de componentes llega al %.0f%%", 100 * umbral)
  if (is.null(k) || !k %in% tabla$componente) return(parte_umbral)
  sprintf("retenidas %d · acumulan %.1f%% · %s", k,
          100 * tabla$acumulada[k], parte_umbral)
}

#' Codo de la inercia: cuánto baja W al añadir un grupo más.
#'
#' El codo no es un cálculo, es un juicio, igual que en el scree. La curva
#' siempre baja —con k = n la inercia es cero y la partición no dice nada—, así
#' que lo que se mira es dónde deja de bajar rápido.
#'
#' @param tabla salida de inercia_por_k()
#' @param k     el k elegido, para marcarlo
graficar_codo <- function(tabla, k = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$k,
                                                 y = .data$inercia)) +
    ggplot2::geom_line(color = paleta_cat(2)[2], linewidth = 0.9) +
    ggplot2::geom_point(color = paleta_cat(2)[2], size = 2) +
    ggplot2::scale_x_continuous(breaks = tabla$k) +
    ggplot2::labs(x = "numero de grupos (k)", y = "inercia intra-grupo",
                  subtitle = .subtitulo_codo(tabla, k)) +
    tema_ggplot()

  if (!is.null(k) && k %in% tabla$k)
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = k, linetype = "dotted", color = "grey20")
  grafico
}

.subtitulo_codo <- function(tabla, k) {
  if (is.null(k) || !k %in% tabla$k)
    return("la inercia siempre baja: el codo es un juicio, no un minimo")
  fila <- tabla[tabla$k == k, ][1, ]
  sprintf("con k = %d queda %.1f%% de la inercia explicada entre grupos",
          k, 100 * fila$proporcion)
}

#' Silueta por observación, ordenada dentro de cada grupo.
#'
#' Las barras negativas son el mensaje: esas observaciones están más cerca del
#' grupo vecino que del propio. Un grupo entero por debajo de la media delata
#' una partición que la inercia sola no delata.
#'
#' @param tabla salida de silueta()
graficar_silueta <- function(tabla, ...) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay grupos que juzgar"))

  muestreada <- isTRUE(attr(tabla, "muestreada"))
  ordenada <- tabla[order(tabla$grupo, -tabla$s), ]
  ordenada$orden <- seq_len(nrow(ordenada))
  media <- mean(ordenada$s)
  n_grupos <- length(levels(ordenada$grupo))

  ggplot2::ggplot(ordenada, ggplot2::aes(x = .data$orden, y = .data$s,
                                         fill = .data$grupo)) +
    ggplot2::geom_col(width = 1) +
    ggplot2::geom_hline(yintercept = media, linetype = "dashed",
                        color = "grey30") +
    ggplot2::coord_flip() +
    scale_fill_cat(n_grupos, name = "grupo") +
    ggplot2::labs(x = NULL, y = "s(i)",
                  subtitle = .subtitulo_silueta(ordenada, media, muestreada)) +
    tema_ggplot() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank())
}

.subtitulo_silueta <- function(tabla, media, muestreada = FALSE) {
  negativas <- sum(tabla$s < 0)
  parte <- if (isTRUE(muestreada))
    sprintf(" · sobre una muestra de %d", nrow(tabla)) else ""
  sprintf("silueta media %.3f · %d observaciones mal ubicadas%s",
          media, negativas, parte)
}
