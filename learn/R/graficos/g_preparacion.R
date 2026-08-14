# learn/R/graficos/g_preparacion.R
#
# Responsabilidad: mostrar el EFECTO de lo que se le hizo a los datos.
#
# Transformar, partir y balancear son operaciones ciegas si no se ven: el
# antes/después lado a lado es lo que convierte "apliqué log" en "la cola se
# fue y ahora la distribución es simétrica".

#' Histograma antes y contra después de una transformación, en dos facetas.
#'
#' Escalas libres a propósito: comparar la FORMA, no la magnitud. Después de un
#' log los ejes no son comparables y forzarlos a serlo haría ilegible el panel.
graficar_antes_despues <- function(antes, despues, columna, clases = 30L) {
  crudos <- as.numeric(antes[[columna]])
  tratados <- as.numeric(despues[[columna]])
  if (!length(crudos) || !length(tratados))
    return(.grafico_vacio("la columna no sobrevivio a la transformacion"))

  largo <- rbind(
    data.frame(momento = "antes", valor = crudos[!is.na(crudos)]),
    data.frame(momento = "despues", valor = tratados[!is.na(tratados)]))
  largo$momento <- factor(largo$momento, levels = c("antes", "despues"))

  ggplot2::ggplot(largo, ggplot2::aes(x = .data$valor, fill = .data$momento)) +
    ggplot2::geom_histogram(bins = clases, color = "white", linewidth = 0.2) +
    ggplot2::facet_wrap(~ momento, scales = "free", ncol = 2) +
    scale_fill_cat(2) +
    ggplot2::labs(x = columna, y = "frecuencia", fill = NULL,
                  subtitle = sprintf("g1 antes %.2f · g1 despues %.2f",
                                     .asimetria(crudos[!is.na(crudos)]),
                                     .asimetria(tratados[!is.na(tratados)]))) +
    tema_ggplot() +
    ggplot2::theme(legend.position = "none")
}

#' Perfil de verosimilitud de lambda en Box-Cox.
#'
#' Se marcan el óptimo y el redondo más cercano: cuando la curva es plana entre
#' los dos, conviene el redondo porque se interpreta (0 es log, 0.5 es raíz).
graficar_perfil_boxcox <- function(perfil) {
  curva <- perfil$curva
  if (!nrow(curva)) return(.grafico_vacio("faltan observaciones positivas"))

  ggplot2::ggplot(curva, ggplot2::aes(x = .data$lambda, y = .data$loglik)) +
    ggplot2::geom_line(color = paleta_cat(1), linewidth = 0.9) +
    ggplot2::geom_vline(xintercept = perfil$optimo, color = "#D55E00",
                        linewidth = 0.6) +
    ggplot2::geom_vline(xintercept = perfil$redondeado, color = "grey55",
                        linetype = "dashed", linewidth = 0.6) +
    ggplot2::labs(x = "lambda", y = "log-verosimilitud",
                  subtitle = sprintf("optimo %.2f · redondo sugerido %.2f",
                                     perfil$optimo, perfil$redondeado)) +
    tema_ggplot()
}

#' Barra apilada con el tamaño de cada parte de la partición.
graficar_particion <- function(resumen) {
  if (!nrow(resumen)) return(.grafico_vacio("todavia no hay particion"))
  resumen$eje <- "particion"

  ggplot2::ggplot(resumen, ggplot2::aes(x = .data$eje, y = .data$n,
                                        fill = .data$parte)) +
    ggplot2::geom_col(width = 0.4) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%s\n%d (%.0f%%)",
                                                    .data$parte, .data$n,
                                                    100 * .data$proporcion)),
                       position = ggplot2::position_stack(vjust = 0.5),
                       size = 3.2, color = "white") +
    scale_fill_cat(nrow(resumen)) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "filas", fill = NULL) +
    tema_ggplot() +
    ggplot2::theme(legend.position = "none")
}

#' Balance por parte: comprueba que la estratificación hizo lo que promete.
graficar_balance_particion <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("sin columna de estrato"))
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$parte, y = .data$proporcion,
                                      fill = .data$clase)) +
    ggplot2::geom_col(position = "dodge", width = 0.7) +
    scale_fill_cat(length(unique(tabla$clase))) +
    ggplot2::labs(x = NULL, y = "proporcion dentro de la parte", fill = NULL) +
    tema_ggplot()
}

#' Nube con las filas remuestreadas marcadas.
#'
#' Sin esta marca, un sobre-muestreo parece haber conseguido datos nuevos. Los
#' puntos repetidos se dibujan encima y con otro símbolo para que se vea que
#' son los mismos de siempre.
graficar_nube_sinteticos <- function(datos, x, y, origen, grupo = NULL) {
  marco <- data.frame(x = as.numeric(datos[[x]]), y = as.numeric(datos[[y]]),
                      origen = origen, stringsAsFactors = FALSE)
  if (!is.null(grupo)) marco$grupo <- as.character(datos[[grupo]])
  marco <- marco[stats::complete.cases(marco[, c("x", "y")]), ]
  if (!nrow(marco)) return(.grafico_vacio("hacen falta dos numericas"))

  capa <- if (is.null(grupo))
    ggplot2::geom_point(ggplot2::aes(shape = .data$origen,
                                     alpha = .data$origen),
                        size = 1.6, color = paleta_cat(1))
  else
    ggplot2::geom_point(ggplot2::aes(shape = .data$origen,
                                     alpha = .data$origen,
                                     color = .data$grupo), size = 1.6)

  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$x, y = .data$y)) +
    capa +
    ggplot2::scale_shape_manual(values = c(original = 16, remuestreada = 4)) +
    ggplot2::scale_alpha_manual(values = c(original = 0.5, remuestreada = 0.9))
  if (!is.null(grupo))
    grafico <- grafico + scale_color_cat(length(unique(marco$grupo)))

  grafico +
    ggplot2::labs(x = x, y = y, shape = NULL, alpha = NULL,
                  subtitle = sprintf("%d originales · %d remuestreadas",
                                     sum(marco$origen == "original"),
                                     sum(marco$origen == "remuestreada"))) +
    tema_ggplot()
}
