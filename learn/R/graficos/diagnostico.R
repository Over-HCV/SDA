# learn/R/graficos/diagnostico.R
#
# Responsabilidad: los gráficos que juzgan un ajuste ya hecho.
#
# Fase 4, subsección Diagnóstico. Van entrando por método: el scree del ACP, el
# codo y la silueta de k-medias, el dendrograma y la cofenética del jerárquico;
# residuos y compañía llegan con sus métodos, en su hito.

#' Gráfico de sedimentación: cuánta varianza aporta cada componente.
#'
#' Las barras son el aporte individual; la línea, el acumulado. El "codo" es
#' donde el aporte deja de valer lo que cuesta, y es un juicio, no un cálculo:
#' por eso el corte se dibuja donde el usuario lo puso.
#'
#' @param tabla salida de varianza_explicada()
#' @param k     componentes retenidas, para marcar el corte
#' @param umbral línea de referencia del acumulado (0.8 por convención)
#' @param reglas salida de reglas_k(), o NULL. Las tres heurísticas dibujadas
#'   juntas: cuando coinciden, la decisión es fácil y se ve de una; cuando no
#'   coinciden, la discrepancia es el resultado y esconderla no la resuelve.
graficar_scree <- function(tabla, k = NULL, umbral = 0.8, reglas = NULL) {
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
  .capa_reglas(grafico, reglas)
}

# Las reglas se escalonan en vertical a propósito: casi siempre dan el mismo k y
# sus rótulos quedarían uno encima del otro justo en el caso más común.
.capa_reglas <- function(grafico, reglas) {
  if (is.null(reglas) || !nrow(reglas)) return(grafico)
  reglas$corta <- sub(" .*", "", reglas$regla)
  reglas$altura <- seq(0.96, 0.60, length.out = nrow(reglas))

  grafico +
    ggplot2::geom_vline(data = reglas, ggplot2::aes(xintercept = .data$k),
                        color = "grey55", linewidth = 0.4) +
    ggplot2::geom_label(data = reglas,
                        ggplot2::aes(x = .data$k, y = .data$altura,
                                     label = sprintf("%s: %d", .data$corta,
                                                     .data$k)),
                        size = 2.9, color = "grey30", fill = "white",
                        linewidth = 0, hjust = -0.05)
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

#' Dendrograma con el corte en k grupos.
#'
#' La altura de cada unión es la distancia (según el enlace) a la que se
#' juntaron esas dos ramas. Las ramas debajo del corte van del color de su
#' grupo; las de arriba, en gris, juntan grupos distintos y son las que el
#' corte decidió no hacer. Una rama larga justo encima del corte dice que ese
#' k separa grupos que estaban lejos; ramas cortas, que el corte es arbitrario.
#'
#' @param arbol salida de arbol_jerarquico()
#' @param etiquetas TRUE pone el nombre de cada hoja; NULL decide por n (más
#'   de 150 hojas no se leen y solo ensucian)
graficar_dendrograma <- function(arbol, etiquetas = NULL) {
  if (is.null(arbol) || !nrow(arbol$segmentos))
    return(.grafico_vacio("todavia no hay arbol que mirar"))

  k <- arbol$k
  etiquetas <- etiquetas %||% (arbol$n <= 150L)
  techo <- max(arbol$segmentos$yend)
  grafico <- ggplot2::ggplot(arbol$segmentos,
                             ggplot2::aes(x = .data$x, y = .data$y,
                                          xend = .data$xend, yend = .data$yend,
                                          color = .data$grupo)) +
    ggplot2::geom_rect(data = arbol$rectangulos,
                       ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax,
                                    ymin = .data$ymin, ymax = .data$ymax,
                                    color = .data$grupo),
                       inherit.aes = FALSE, fill = NA, linetype = "dashed",
                       linewidth = 0.3) +
    ggplot2::geom_segment(linewidth = 0.45) +
    ggplot2::geom_hline(yintercept = arbol$corte, linetype = "dotted",
                        color = "grey20") +
    ggplot2::scale_color_manual(values = paleta_cat(k), na.value = "grey55",
                                breaks = as.character(seq_len(k)),
                                name = "grupo") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(add = 1)) +
    # Sin alturas negativas en el eje: el tramo bajo el cero es de las etiquetas.
    ggplot2::scale_y_continuous(breaks = function(limites) {
      marcas <- pretty(c(0, limites[2])); marcas[marcas >= 0] }) +
    ggplot2::labs(x = NULL, y = "altura de fusion",
                  subtitle = .subtitulo_dendrograma(arbol)) +
    tema_ggplot() +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.minor.x = ggplot2::element_blank())

  if (!isTRUE(etiquetas)) return(grafico)
  # Las hojas cuelgan debajo del cero, giradas: el espacio se le saca al eje y
  # con un límite negativo, que es más estable que pelear con los márgenes.
  grafico +
    ggplot2::geom_text(data = arbol$hojas,
                       ggplot2::aes(x = .data$x, y = -0.01 * techo,
                                    label = .data$etiqueta, color = .data$grupo),
                       inherit.aes = FALSE, angle = 90, hjust = 1,
                       size = 2.1, show.legend = FALSE) +
    ggplot2::expand_limits(y = -0.32 * techo)
}

.subtitulo_dendrograma <- function(arbol) {
  sprintf("enlace %s · distancia %s · %d hojas cortadas en k = %d · cofenetica %.3f",
          arbol$enlace, arbol$distancia, arbol$n, arbol$k,
          arbol$cofenetica %||% NA_real_)
}

#' Distancia original contra distancia en el árbol.
#'
#' Cada punto es un par de observaciones. Si el dendrograma respetara las
#' distancias, los puntos subirían en línea; la nube ancha y los escalones
#' horizontales son la distorsión: pares a distancias muy distintas que el
#' árbol junta a la misma altura.
#'
#' @param tabla salida de cofenetico()
graficar_cofenetico <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay arbol que comparar"))

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$original,
                                      y = .data$cofenetica)) +
    ggplot2::geom_point(alpha = 0.25, size = 0.9, color = paleta_cat(1)) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                         color = paleta_cat(2)[2], linewidth = 0.8) +
    ggplot2::labs(x = "distancia original", y = "distancia cofenetica",
                  subtitle = .subtitulo_cofenetico(tabla)) +
    tema_ggplot()
}

.subtitulo_cofenetico <- function(tabla) {
  base <- sprintf("correlacion cofenetica %.3f sobre %d pares",
                  attr(tabla, "correlacion") %||% NA_real_,
                  attr(tabla, "pares") %||% nrow(tabla))
  if (!isTRUE(attr(tabla, "muestreada"))) return(base)
  sprintf("%s · se dibujan %d", base, nrow(tabla))
}
