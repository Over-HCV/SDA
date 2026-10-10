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
#
# Los modos y el cruce con la clase real son de la familia cualitativa, pero
# caracterizan la partición igual que el centroide: viven acá por eso.

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

#' Los modos de cada grupo: la proporción de cada categoría dentro del grupo.
#'
#' Es el "perfil de los grupos" de la familia cualitativa, y la figura que
#' contesta qué es cada grupo: con factores no hay centroide que dibujar, pero
#' sí la frecuencia de cada categoría. El recuadro marca el MODO del grupo en
#' esa variable (lo que k-modos usa como representante); una celda oscura sin
#' recuadro es una categoría que el grupo comparte con otro modo casi empatado.
#'
#' Una fila por categoría, agrupadas por variable; una columna por grupo. Se
#' lee por filas: una variable que tiene el mismo modo en todos los grupos no
#' distingue a nadie, aunque su celda sea oscura.
#'
#' @param tabla salida de perfiles_grupos()
graficar_modos <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay grupos que perfilar"))

  tabla$categoria <- factor(tabla$categoria, levels = rev(unique(tabla$categoria)))
  tabla$variable <- factor(tabla$variable, levels = unique(tabla$variable))
  tabla$texto <- ifelse(tabla$proporcion >= 0.6, "white", "grey20")
  modales <- tabla[tabla$modal, , drop = FALSE]
  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$grupo, y = .data$categoria)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$proporcion), color = "white",
                       linewidth = 0.4) +
    ggplot2::geom_tile(data = modales, fill = NA, color = paleta_cat(6)[6],
                       linewidth = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = round(100 * .data$proporcion),
                                    color = .data$texto), size = 2.5) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_gradient(low = "grey97", high = paleta_cat(1),
                                 limits = c(0, 1), name = "dentro\ndel grupo",
                                 labels = function(v) paste0(round(100 * v), "%")) +
    ggplot2::facet_grid(variable ~ ., scales = "free_y", space = "free_y",
                        switch = "y") +
    ggplot2::labs(x = "grupo", y = NULL,
                  subtitle = sprintf(paste("%d grupos · %d variables ·",
                                           "recuadro = modo del grupo"),
                                     length(levels(tabla$grupo)),
                                     length(levels(tabla$variable)))) +
    tema_ggplot(base_size = 11) +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   strip.placement = "outside",
                   strip.text.y.left = ggplot2::element_text(angle = 0, hjust = 1),
                   panel.spacing.y = ggplot2::unit(1, "pt"))
}

#' Grupo contra clase real: cuántas observaciones de cada clase cayó en cada
#' grupo.
#'
#' La numeración de los grupos es arbitraria, así que no se busca una
#' diagonal: se busca que cada FILA se concentre en una sola columna. El color
#' es la proporción dentro del grupo; el número, el conteo.
#'
#' Sirve también para CONCORDANCIA entre dos métodos (el `table(K_means,
#' Jerarquico)` de la sesión 5): si la "clase" es la partición de otro método,
#' `cruce$eje_clase` y `cruce$eje_grupo` dicen cuál es cuál.
#'
#' @param cruce salida de cruce_con_clase()
graficar_cruce_clase <- function(cruce) {
  celdas <- cruce$celdas
  if (is.null(celdas) || !nrow(celdas))
    return(.grafico_vacio("todavia no hay cruce que mirar"))

  celdas$grupo <- factor(celdas$grupo, levels = rev(levels(celdas$grupo)))
  celdas$texto <- ifelse(celdas$proporcion >= 0.6, "white", "grey20")
  ggplot2::ggplot(celdas, ggplot2::aes(x = .data$clase, y = .data$grupo)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$proporcion), color = "white",
                       linewidth = 0.5) +
    ggplot2::geom_text(data = celdas[celdas$n > 0, , drop = FALSE],
                       ggplot2::aes(label = .data$n, color = .data$texto),
                       size = 3.4) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_gradient(low = "grey97", high = paleta_cat(1),
                                 limits = c(0, 1), name = "dentro\ndel grupo",
                                 labels = function(v) paste0(round(100 * v), "%")) +
    ggplot2::labs(x = cruce$eje_clase %||% "clase real",
                  y = cruce$eje_grupo %||% "grupo",
                  subtitle = sprintf("ARI = %.3f · pureza %.0f%% · n = %d",
                                     cruce$ari, 100 * cruce$pureza, cruce$n)) +
    tema_ggplot() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
}
