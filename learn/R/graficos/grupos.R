# learn/R/graficos/grupos.R
#
# Responsabilidad: los gráficos que caracterizan una partición ya hecha.
#
# Fase 4, subsección Explicabilidad. Van aparte de `explicabilidad.R` porque
# aquel dibuja cargas, círculo y biplot, que son de la familia de reducción: lo
# que agrupa es la familia, no el nombre del archivo (C2).
#
# El diagnóstico de la partición (codo, silueta) no está acá: está en
# `diagnostico.R`, que es donde el registro de artefactos lo declara.

#' Perfil de cada grupo: cuánto se aparta del promedio en cada variable.
#'
#' Es la respuesta a "¿y qué son estos grupos?". Con la matriz escalada, un
#' centroide en +1.2 quiere decir "este grupo está una desviación y pico por
#' encima de la media en esta variable", que es una frase que se puede escribir
#' en el informe.
#'
#' @param tabla salida de centroides_tabla()
graficar_centroides <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay centroides"))

  n_grupos <- length(levels(tabla$grupo))
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$valor,
                                      y = stats::reorder(.data$variable,
                                                         .data$valor),
                                      fill = .data$grupo)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8),
                      width = 0.7) +
    ggplot2::geom_vline(xintercept = 0, color = "grey40") +
    scale_fill_cat(n_grupos, name = "grupo") +
    ggplot2::labs(x = "coordenada del centroide", y = NULL,
                  subtitle = sprintf("%d grupos sobre %d variables", n_grupos,
                                     length(unique(tabla$variable)))) +
    tema_ggplot()
}

#' Tamaño de cada grupo, con su inercia interna.
#'
#' k-medias parte donde hay puntos, no donde hay estructura: un grupo diminuto
#' o uno que se come la mitad de la muestra son las dos formas de que el
#' resultado no sirva, y las dos se ven acá antes que en ningún otro sitio.
#'
#' @param tabla salida de resumen_grupos()
graficar_tamanos <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay grupos"))

  n_grupos <- nrow(tabla)
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$grupo, y = .data$n,
                                      fill = .data$grupo)) +
    ggplot2::geom_col(width = 0.65) +
    ggplot2::geom_text(ggplot2::aes(label = .data$n), vjust = -0.4,
                       size = 3.4, color = "grey25") +
    scale_fill_cat(n_grupos, guide = "none") +
    ggplot2::labs(x = "grupo", y = "observaciones",
                  subtitle = sprintf("del %.0f%% al %.0f%% de la muestra",
                                     100 * min(tabla$proporcion),
                                     100 * max(tabla$proporcion))) +
    tema_ggplot()
}
