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
