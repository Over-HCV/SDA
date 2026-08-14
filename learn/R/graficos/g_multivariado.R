# learn/R/graficos/g_multivariado.R
#
# Responsabilidad: mirar p variables a la vez.
#
# La matriz de dispersión se arma a mano con facetas en vez de traer GGally:
# son cuatro líneas de reshape y una dependencia menos en el bundle wasm.

#' Matriz de dispersión: todos los pares, en una rejilla de facetas.
graficar_pares <- function(datos, columnas = NULL, grupo = NULL, alfa = 0.5,
                           maximo_variables = 6L) {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- utils::head(intersect(columnas, names(datos)), maximo_variables)
  if (length(columnas) < 2L)
    return(.grafico_vacio("hacen falta al menos dos variables numericas"))

  pares <- expand.grid(fila = columnas, columna = columnas,
                       stringsAsFactors = FALSE)
  largo <- do.call(rbind, lapply(seq_len(nrow(pares)), function(i) {
    marco <- data.frame(
      fila = pares$fila[i], columna = pares$columna[i],
      x = as.numeric(datos[[pares$columna[i]]]),
      y = as.numeric(datos[[pares$fila[i]]]), stringsAsFactors = FALSE)
    if (!is.null(grupo)) marco$grupo <- as.character(datos[[grupo]])
    marco
  }))
  largo <- largo[stats::complete.cases(largo[, c("x", "y")]), ]

  capa <- if (is.null(grupo))
    ggplot2::geom_point(alpha = alfa, size = 0.7, color = paleta_cat(1))
  else ggplot2::geom_point(ggplot2::aes(color = .data$grupo), alpha = alfa,
                           size = 0.7)

  grafico <- ggplot2::ggplot(largo, ggplot2::aes(x = .data$x, y = .data$y)) +
    capa +
    ggplot2::facet_grid(fila ~ columna, scales = "free") +
    ggplot2::labs(x = NULL, y = NULL,
                  subtitle = sprintf("%d variables · n = %d", length(columnas),
                                     nrow(datos))) +
    tema_ggplot()
  if (!is.null(grupo))
    grafico <- grafico + scale_color_cat(length(unique(largo$grupo)))
  grafico
}

#' Mapa de calor de la matriz de correlación.
#'
#' Con reordenamiento las variables parecidas quedan juntas y los bloques
#' saltan a la vista; sin él, el orden alfabético esconde la estructura.
graficar_heatmap_correlacion <- function(matriz, mostrar_valores = TRUE) {
  largo <- correlacion_larga(matriz)
  if (!nrow(largo)) return(.grafico_vacio("sin correlaciones que dibujar"))

  niveles <- rownames(matriz)
  largo$fila <- factor(largo$fila, levels = rev(niveles))
  largo$columna <- factor(largo$columna, levels = niveles)

  grafico <- ggplot2::ggplot(largo, ggplot2::aes(x = .data$columna,
                                                 y = .data$fila,
                                                 fill = .data$correlacion)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4) +
    ggplot2::scale_fill_gradient2(low = "#D55E00", mid = "grey95",
                                  high = "#0072B2", midpoint = 0,
                                  limits = c(-1, 1))
  if (mostrar_valores && nrow(matriz) <= 12L)
    grafico <- grafico + ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.2f", .data$correlacion)),
      size = 3, color = "grey20")

  grafico +
    ggplot2::labs(x = NULL, y = NULL, fill = "r") +
    tema_ggplot() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   panel.grid = ggplot2::element_blank())
}

#' Coordenadas paralelas: cada fila es una línea que cruza todos los ejes.
#'
#' Sin normalizar no se lee: la variable de mayor rango aplasta al resto. Por
#' eso el eje vertical es la escala normalizada y el subtítulo lo dice.
graficar_coordenadas_paralelas <- function(datos, columnas = NULL, grupo = NULL,
                                           metodo = "minmax", alfa = 0.35) {
  columnas <- columnas %||% names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- intersect(columnas, names(datos))
  if (length(columnas) < 2L)
    return(.grafico_vacio("hacen falta al menos dos variables numericas"))

  normalizados <- normalizar_columnas(datos, columnas, metodo)
  largo <- do.call(rbind, lapply(columnas, function(columna) {
    marco <- data.frame(observacion = seq_len(nrow(datos)), eje = columna,
                        valor = as.numeric(normalizados[[columna]]),
                        stringsAsFactors = FALSE)
    if (!is.null(grupo)) marco$grupo <- as.character(datos[[grupo]])
    marco
  }))
  largo$eje <- factor(largo$eje, levels = columnas)
  largo <- largo[!is.na(largo$valor), ]

  capa <- if (is.null(grupo))
    ggplot2::geom_line(ggplot2::aes(group = .data$observacion), alpha = alfa,
                       color = paleta_cat(1), linewidth = 0.4)
  else ggplot2::geom_line(ggplot2::aes(group = .data$observacion,
                                       color = .data$grupo),
                          alpha = alfa, linewidth = 0.4)

  grafico <- ggplot2::ggplot(largo, ggplot2::aes(x = .data$eje, y = .data$valor)) +
    capa +
    ggplot2::labs(x = NULL, y = paste("escala", metodo),
                  subtitle = sprintf("%d variables · %d observaciones",
                                     length(columnas), nrow(datos))) +
    tema_ggplot() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
  if (!is.null(grupo))
    grafico <- grafico + scale_color_cat(length(unique(largo$grupo)))
  grafico
}

#' Nube con elipsoides de concentración a dos niveles.
#'
#' La elipse se deforma con la correlación: eso que se ve inclinarse es
#' exactamente la covarianza.
graficar_elipsoide <- function(datos, x, y, niveles = c(0.5, 0.95)) {
  marco <- data.frame(x = as.numeric(datos[[x]]), y = as.numeric(datos[[y]]))
  marco <- marco[stats::complete.cases(marco), ]
  if (nrow(marco) < 3L) return(.grafico_vacio("faltan observaciones completas"))

  contornos <- do.call(rbind, lapply(niveles, function(nivel) {
    borde <- elipsoide_concentracion(marco$x, marco$y, nivel)
    if (!nrow(borde)) return(NULL)
    borde$nivel <- sprintf("%.0f%%", 100 * nivel)
    borde
  }))

  grafico <- ggplot2::ggplot(marco, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point(alpha = 0.45, size = 1.2, color = paleta_cat(1))
  if (!is.null(contornos))
    grafico <- grafico + ggplot2::geom_path(
      data = contornos, ggplot2::aes(x = .data$x, y = .data$y,
                                     color = .data$nivel),
      linewidth = 0.8) + scale_color_cat(length(niveles))

  grafico +
    ggplot2::annotate("point", x = mean(marco$x), y = mean(marco$y),
                      shape = 4, size = 3, color = "grey25") +
    ggplot2::labs(x = x, y = y, color = "concentracion",
                  subtitle = sprintf("r = %.3f · el centro es la media conjunta",
                                     stats::cor(marco$x, marco$y))) +
    tema_ggplot()
}

#' Q-Q de distancias de Mahalanobis contra chi-cuadrado.
#'
#' Es el Q-Q normal, pero multivariado: si la nube es normal de p dimensiones,
#' los puntos caen sobre la recta. Los de arriba a la derecha son los atípicos
#' que ninguna variable por separado delata.
graficar_qq_mahalanobis <- function(distancias, p, nivel = 0.975) {
  puntos <- puntos_qq_mahalanobis(distancias, p)
  if (!nrow(puntos)) return(.grafico_vacio("no se pudo calcular la distancia"))
  corte <- stats::qchisq(nivel, df = p)
  puntos$atipico <- puntos$observado > corte

  ggplot2::ggplot(puntos, ggplot2::aes(x = .data$teorico, y = .data$observado)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, color = "grey55",
                         linetype = "dashed", linewidth = 0.6) +
    ggplot2::geom_point(ggplot2::aes(color = .data$atipico), alpha = 0.7,
                        size = 1.3) +
    ggplot2::scale_color_manual(values = c(`FALSE` = paleta_cat(1),
                                           `TRUE` = "#D55E00"),
                                labels = c("dentro", "atipico")) +
    ggplot2::labs(x = sprintf("cuantil chi2 con %d gl", p),
                  y = "distancia de Mahalanobis al cuadrado", color = NULL,
                  subtitle = sprintf("corte al %.1f%% = %.2f · %d por encima",
                                     100 * nivel, corte, sum(puntos$atipico))) +
    tema_ggplot()
}

.grafico_vacio <- function(mensaje) {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = 0, label = mensaje, color = "grey45") +
    ggplot2::theme_void()
}
