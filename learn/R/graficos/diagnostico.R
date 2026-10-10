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
#' Una partición de factores no tiene inercia: su tabla trae el atributo
#' `criterio` (el costo de k-modas, la d de Gower) y ese es el nombre del eje.
#' La curva es la misma —costo contra k, con el k elegido marcado— para que
#' los dos codos se lean igual.
#'
#' @param tabla salida de inercia_por_k()
#' @param k     el k elegido, para marcarlo
graficar_codo <- function(tabla, k = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))
  criterio <- attr(tabla, "criterio")

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$k,
                                                 y = .data$inercia)) +
    ggplot2::geom_line(color = paleta_cat(2)[2], linewidth = 0.9) +
    ggplot2::geom_point(color = paleta_cat(2)[2], size = 2) +
    ggplot2::scale_x_continuous(breaks = tabla$k) +
    ggplot2::labs(x = "numero de grupos (k)",
                  y = criterio %||% "inercia intra-grupo",
                  subtitle = .subtitulo_codo(tabla, k, criterio)) +
    tema_ggplot()

  if (!is.null(k) && k %in% tabla$k)
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = k, linetype = "dotted", color = "grey20")
  grafico
}

.subtitulo_codo <- function(tabla, k, criterio = NULL) {
  if (is.null(k) || !k %in% tabla$k)
    return("la inercia siempre baja: el codo es un juicio, no un minimo")
  fila <- tabla[tabla$k == k, ][1, ]
  # Con factores la referencia es k = 1 (la "reducción" de la sesión 5), no
  # una inercia total que no existe.
  if (!is.null(criterio))
    return(sprintf("con k = %d: %.1f%% menos que con k = 1 (todos juntos)",
                   k, 100 * fila$proporcion))
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
#' @param forma "rectangular" (raíz arriba, hojas abajo) o "circular" (raíz al
#'   centro, hojas en el borde): con 100 hojas la circular les da a los nombres
#'   todo el perímetro en vez de un renglón, y tres árboles caben lado a lado
graficar_dendrograma <- function(arbol, etiquetas = NULL,
                                 forma = c("rectangular", "circular")) {
  forma <- match.arg(forma)
  # arbol_jerarquico() devuelve NULL cuando el ajuste no construyó árbol (Gower
  # con PAM parte por medoides): se dice por qué, en vez de un lienzo vacío.
  if (is.null(arbol))
    return(.grafico_vacio(paste("el dendrograma existe solo con estrategia",
                                "jerárquica:\nGower + PAM parte por medoides",
                                "y no construye árbol")))
  if (!nrow(arbol$segmentos))
    return(.grafico_vacio("todavia no hay arbol que mirar"))

  k <- arbol$k
  etiquetas <- etiquetas %||% (arbol$n <= 150L)
  if (forma == "circular")
    return(.dendrograma_circular(arbol, isTRUE(etiquetas)))
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

# El mismo árbol en coordenadas polares: el ángulo es la posición de la hoja y
# el radio, la altura al revés (la raíz al centro, las hojas en el borde).
#
# Dos detalles que coord_polar no resuelve solo:
#   · geom_segment no se curva en polares: un tramo horizontal (que une dos
#     ramas a la misma altura) saldría como cuerda recta y cruzaría el árbol.
#     Por eso esos tramos se parten en puntos y van con geom_path, que sí se
#     dobla siguiendo el arco.
#   · El círculo no se cierra: se deja un hueco del 4 % entre la última hoja y
#     la primera, porque si se tocan parecen vecinas y no lo son.
# Los rectángulos punteados de la versión rectangular se omiten: en polares
# serían sectores que tapan las etiquetas, y el color ya dice el grupo.
.dendrograma_circular <- function(arbol, etiquetas) {
  k <- arbol$k
  techo <- max(arbol$segmentos$yend)
  seg <- arbol$segmentos
  seg$id <- seq_len(nrow(seg))
  horizontal <- abs(seg$y - seg$yend) < 1e-12 & abs(seg$x - seg$xend) > 1e-12
  arcos <- do.call(rbind, lapply(which(horizontal), function(i) {
    puntos <- max(2L, ceiling(abs(seg$xend[i] - seg$x[i]) * 4))
    data.frame(x = seq(seg$x[i], seg$xend[i], length.out = puntos),
               y = seg$y[i], grupo = seg$grupo[i], id = seg$id[i])
  }))
  rectas <- seg[!horizontal, , drop = FALSE]
  rectas <- rbind(
    data.frame(x = rectas$x, y = rectas$y, grupo = rectas$grupo, id = rectas$id),
    data.frame(x = rectas$xend, y = rectas$yend, grupo = rectas$grupo,
               id = rectas$id))
  trazos <- rbind(arcos, rectas)
  n <- arbol$n
  hueco <- 0.04 * n
  margen <- if (etiquetas) 0.3 * techo else 0.02 * techo

  grafico <- ggplot2::ggplot(trazos, ggplot2::aes(x = .data$x, y = .data$y,
                                                   group = .data$id,
                                                   color = .data$grupo)) +
    ggplot2::geom_path(linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = arbol$corte, linetype = "dotted",
                        color = "grey20") +
    ggplot2::scale_color_manual(values = paleta_cat(k), na.value = "grey55",
                                breaks = as.character(seq_len(k)),
                                name = "grupo") +
    ggplot2::scale_x_continuous(limits = c(0.5, n + 0.5 + hueco),
                                expand = c(0, 0)) +
    # Invertida: la raíz (altura máxima) al centro. El tramo negativo es el
    # anillo exterior donde van los nombres.
    ggplot2::scale_y_reverse(limits = c(techo, -margen), expand = c(0, 0)) +
    ggplot2::coord_polar(theta = "x", clip = "off") +
    ggplot2::guides(color = ggplot2::guide_legend(nrow = 1)) +
    # El subtítulo en dos renglones: la figura es cuadrada y en uno se corta.
    ggplot2::labs(x = NULL, y = NULL,
                  subtitle = sub(" · (?=[0-9]+ hojas)", "\n",
                                 .subtitulo_dendrograma(arbol), perl = TRUE)) +
    tema_ggplot() +
    # La cuadrícula del tema se apaga elemento por elemento: tema_ggplot() fija
    # los .major.x/.y, que le ganan a `panel.grid`, y en polares dibujarían
    # anillos y radios que no significan nada.
    ggplot2::theme(axis.text = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.minor.x = ggplot2::element_blank(),
                   panel.grid.minor.y = ggplot2::element_blank(),
                   legend.position = "bottom")
  if (!etiquetas) return(grafico)

  # Cada nombre sale radial desde su hoja. En la mitad izquierda se voltea
  # 180° para que no quede de cabeza, y entonces se alinea al otro extremo.
  hojas <- arbol$hojas
  angulo <- 90 - 360 * (hojas$x - 0.5) / (n + hueco)
  izquierda <- angulo < -90
  hojas$angulo <- ifelse(izquierda, angulo + 180, angulo)
  hojas$ajuste <- ifelse(izquierda, 1, 0)
  grafico +
    ggplot2::geom_text(data = hojas,
                       ggplot2::aes(x = .data$x, y = -0.02 * techo,
                                    label = .data$etiqueta, color = .data$grupo,
                                    angle = .data$angulo, hjust = .data$ajuste),
                       inherit.aes = FALSE, size = 1.9, show.legend = FALSE)
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

#' BIC y AIC contra k: cómo un modelo de mezclas elige cuántos grupos.
#'
#' A diferencia del codo, acá hay un mínimo de verdad: la verosimilitud siempre
#' sube con k, y la penalización por parámetros la frena. El BIC penaliza con
#' log(n) por parámetro y el AIC con 2, así que el AIC tiende a pedir más
#' grupos; cuando los dos coinciden, la decisión es fácil.
#'
#' @param tabla salida de bic_mezclas(): k, bic, aic y el atributo k_elegido
graficar_bic <- function(tabla) {
  if (is.null(tabla) || !nrow(tabla))
    return(.grafico_vacio("este ajuste no compara varios k"))

  criterios <- intersect(c("bic", "aic"), names(tabla))
  largo <- do.call(rbind, lapply(criterios, function(criterio)
    data.frame(k = tabla$k, valor = tabla[[criterio]],
               criterio = toupper(criterio))))
  minimos <- do.call(rbind, lapply(split(largo, largo$criterio), function(t)
    t[which.min(t$valor), , drop = FALSE]))
  elegido <- attr(tabla, "k_elegido")

  grafico <- ggplot2::ggplot(largo, ggplot2::aes(x = .data$k, y = .data$valor,
                                                 color = .data$criterio)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_point(data = minimos, shape = 21, size = 4.2, stroke = 1.1,
                        fill = NA) +
    ggplot2::scale_x_continuous(breaks = tabla$k) +
    ggplot2::scale_color_manual(values = paleta_cat(2), name = NULL) +
    ggplot2::labs(x = "numero de grupos (k)", y = "criterio (menor es mejor)",
                  subtitle = .subtitulo_bic(minimos, elegido)) +
    tema_ggplot()
  if (!is.null(elegido) && elegido %in% tabla$k)
    grafico <- grafico +
      ggplot2::geom_vline(xintercept = elegido, linetype = "dotted",
                          color = "grey20")
  grafico
}

.subtitulo_bic <- function(minimos, elegido) {
  partes <- sprintf("%s minimo en k = %d", minimos$criterio, minimos$k)
  if (!is.null(elegido)) partes <- c(partes, sprintf("elegido k = %d", elegido))
  paste(partes, collapse = " · ")
}
