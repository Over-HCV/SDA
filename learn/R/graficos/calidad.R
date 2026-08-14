# learn/R/graficos/calidad.R
#
# Responsabilidad: dibujar lo que está roto — faltantes, atípicos, desbalance.
#
# Son los gráficos que nadie quiere mirar y que deciden el resto del análisis:
# una imputación mal elegida en la fase 1 se cobra en la fase 4, cuando ya no
# se puede rastrear.

#' Matriz de nulidad: una fila por observación, una columna por variable.
#'
#' Lo que importa no son las celdas sueltas sino las BANDAS: si las mismas
#' filas fallan en las mismas columnas, la ausencia tiene mecanismo y no es
#' azar (MCAR).
graficar_nulidad <- function(patron, maximo_filas = 500L) {
  matriz <- patron$matriz
  if (!length(matriz)) return(.grafico_vacio("sin columnas que revisar"))
  filas <- seq_len(min(nrow(matriz), maximo_filas))

  largo <- data.frame(
    fila = rep(filas, times = ncol(matriz)),
    columna = rep(colnames(matriz), each = length(filas)),
    falta = as.logical(matriz[filas, , drop = FALSE]),
    stringsAsFactors = FALSE)
  orden <- patron$por_columna$columna
  largo$columna <- factor(largo$columna, levels = orden)

  ggplot2::ggplot(largo, ggplot2::aes(x = .data$columna, y = .data$fila,
                                      fill = .data$falta)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_manual(values = c(`FALSE` = "grey88",
                                          `TRUE` = "#D55E00"),
                               labels = c("presente", "faltante")) +
    ggplot2::scale_y_reverse() +
    ggplot2::labs(x = NULL, y = "fila", fill = NULL,
                  subtitle = sprintf("%.2f%% de celdas faltantes · %d filas completas · %s",
                                     patron$total_pct, patron$completas,
                                     if (nrow(matriz) > maximo_filas)
                                       sprintf("primeras %d filas", maximo_filas)
                                     else "todas las filas")) +
    tema_ggplot() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   panel.grid = ggplot2::element_blank())
}

#' Barras de faltantes por columna. El resumen del gráfico anterior.
graficar_faltantes_columna <- function(patron) {
  tabla <- patron$por_columna
  if (!nrow(tabla)) return(.grafico_vacio("sin columnas que revisar"))
  tabla$columna <- factor(tabla$columna, levels = rev(tabla$columna))

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$columna, y = .data$porcentaje)) +
    ggplot2::geom_col(fill = paleta_cat(1), width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "% faltante") +
    tema_ggplot()
}

#' Atípicos de una columna, con el corte dibujado.
#'
#' Los puntos se muestran contra su posición en el archivo a propósito: si los
#' atípicos se agrupan al final, no son ruido, es un cambio de régimen.
graficar_atipicos <- function(tabla, columna = "valor") {
  if (!nrow(tabla)) return(.grafico_vacio("sin datos para evaluar"))
  metodo <- attr(tabla, "metodo") %||% "iqr"
  corte <- attr(tabla, "corte")
  eje_y <- if (identical(metodo, "mahalanobis")) "distancia" else "valor"
  marco <- tabla[!is.na(tabla[[eje_y]]), ]

  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$fila,
                                                 y = .data[[eje_y]],
                                                 color = .data$atipico)) +
    ggplot2::geom_point(alpha = 0.65, size = 1.2) +
    ggplot2::scale_color_manual(values = c(`FALSE` = paleta_cat(1),
                                           `TRUE` = "#D55E00"),
                                labels = c("dentro", "atipico"))
  if (identical(metodo, "iqr") && length(corte) == 2L)
    grafico <- grafico + ggplot2::geom_hline(yintercept = corte, linetype = "dashed",
                                             color = "grey50", linewidth = 0.5)
  if (identical(metodo, "mahalanobis") && length(corte) == 1L)
    grafico <- grafico + ggplot2::geom_hline(yintercept = corte, linetype = "dashed",
                                             color = "grey50", linewidth = 0.5)

  grafico +
    ggplot2::labs(x = "fila", y = paste(eje_y, "de", columna), color = NULL,
                  subtitle = sprintf("metodo %s · %d atipicos de %d", metodo,
                                     attr(tabla, "n_atipicos") %||% 0L,
                                     nrow(tabla))) +
    tema_ggplot()
}

#' Frecuencias por clase, antes y después de balancear.
#'
#' @param despues data.frame de resumir_balance() posterior; NULL dibuja solo el
#'   estado actual
graficar_balance <- function(antes, despues = NULL) {
  if (!nrow(antes)) return(.grafico_vacio("sin clases que contar"))
  antes$momento <- "antes"
  largo <- if (is.null(despues)) antes else {
    despues$momento <- "despues"
    rbind(antes, despues)
  }
  largo$momento <- factor(largo$momento, levels = c("antes", "despues"))

  ggplot2::ggplot(largo, ggplot2::aes(x = .data$clase, y = .data$n,
                                      fill = .data$momento)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(preserve = "single"),
                      width = 0.7) +
    scale_fill_cat(2) +
    ggplot2::labs(x = NULL, y = "frecuencia", fill = NULL,
                  subtitle = sprintf("razon de desbalance %.2f a 1",
                                     attr(antes, "razon") %||% NA_real_)) +
    tema_ggplot()
}
