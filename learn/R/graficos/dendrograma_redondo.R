# learn/R/graficos/dendrograma_redondo.R
#
# Responsabilidad: las dos formas redondas del dendrograma (circular y
# radial), que graficar_dendrograma() despacha con `forma`. Viven aparte para
# que diagnostico.R no pase del tope de líneas, y porque comparten lo mismo:
# coordenadas polares, la raíz al centro y los nombres alrededor.

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
    .polar_dendrograma(arbol)
  if (!etiquetas) return(grafico)
  grafico + .nombres_polares(arbol, hueco, -0.02 * techo)
}

# El árbol radial: cada enlace padre -> hijo es una curva y cada nodo un
# punto. El radio sigue siendo la altura de fusión (raíz al centro), así que se
# lee como el circular; lo que cambia es que se ve la jerarquía como ramas y
# no como escalones. Las curvas y los puntos salen de .trazos_radiales() y
# .capas_radiales(), que comparte con graficar_enlaces_radial().
.dendrograma_radial <- function(arbol, etiquetas) {
  techo <- max(arbol$nodos$y)
  hueco <- 0.04 * arbol$n
  trazos <- .trazos_radiales(arbol)
  margen <- if (etiquetas) 0.3 * techo else 0.04 * techo
  grafico <- .capas_radiales(trazos, arbol$k) +
    ggplot2::scale_x_continuous(limits = c(0.5, arbol$n + 0.5 + hueco),
                                expand = c(0, 0)) +
    ggplot2::scale_y_reverse(limits = c(techo * 1.02, -margen),
                             expand = c(0, 0)) +
    ggplot2::coord_polar(theta = "x", clip = "off") +
    .polar_dendrograma(arbol)
  if (!etiquetas) return(grafico)
  grafico + .nombres_polares(arbol, hueco, -0.03 * techo)
}

#' Varios enlaces en un solo círculo, un sector por enlace.
#'
#' Los árboles comparten el centro y se reparten la vuelta; la altura de cada
#' uno va escalada a su propio máximo (el simple funde mucho más abajo que el
#' completo y, sin escalar, quedaría aplastado en el borde), así que lo que se
#' compara es la FORMA: grupos compactos que nacen lejos del centro contra
#' ramas que se encadenan. Cada sector lleva su corte en k y su cofenética.
#'
#' @param arboles lista con nombre (el enlace) de salidas de arbol_jerarquico(),
#'   p. ej. la de arboles_por_enlace()
graficar_enlaces_radial <- function(arboles) {
  if (is.null(arboles) || !length(arboles))
    return(.grafico_vacio(paste("los enlaces se comparan solo con estrategia",
                                "jerárquica: PAM no construye árbol")))
  n <- arboles[[1]]$n
  k <- arboles[[1]]$k
  hueco <- 0.12 * n
  ancho <- n + hueco
  partes <- lapply(seq_along(arboles), function(i) {
    a <- arboles[[i]]
    techo <- max(a$nodos$y)
    tr <- .trazos_radiales(a, desplazar = (i - 1) * ancho, escala = 1 / techo,
                           prefijo = i)
    tr$corte <- data.frame(x = seq(0.5, n + 0.5, length.out = 120) +
                             (i - 1) * ancho,
                           y = a$corte / techo, id = i)
    tr$rotulo <- data.frame(
      x = (i - 1) * ancho + (n + 1) / 2, y = -0.36,
      etiqueta = sprintf("%s\ncofenética %.2f", .nombre_enlace(a$enlace),
                         a$cofenetica %||% NA_real_))
    tr
  })
  junta <- function(campo) do.call(rbind, lapply(partes, `[[`, campo))
  trazos <- list(curvas = junta("curvas"), nodos = junta("nodos"))
  .capas_radiales(trazos, k, tamanos = c(raiz = 3.6, interno = 1.3,
                                          hoja = 0.9)) +
    ggplot2::geom_path(data = junta("corte"),
                       ggplot2::aes(x = .data$x, y = .data$y, group = .data$id),
                       linetype = "dotted", color = "grey30", linewidth = 0.35) +
    ggplot2::geom_text(data = junta("rotulo"),
                       ggplot2::aes(x = .data$x, y = .data$y,
                                    label = .data$etiqueta),
                       size = 3.2, color = "grey25", lineheight = 0.9) +
    ggplot2::scale_x_continuous(limits = c(0.5, length(arboles) * ancho + 0.5),
                                expand = c(0, 0)) +
    # Los rótulos de sector quedan FUERA del panel (y = -0.36, más allá del
    # límite): oob_keep los conserva y clip = "off" los dibuja, así el árbol
    # llega casi al borde en vez de cederle un anillo entero a tres textos.
    ggplot2::scale_y_reverse(limits = c(1.02, -0.04), expand = c(0, 0),
                             oob = scales::oob_keep) +
    # coord_radial y no coord_polar: polar deja el círculo en un radio fijo del
    # 40 % del panel y la figura sale con un marco blanco enorme; radial lo
    # estira al panel. El radio interior deja las raíces en un anillo y no en
    # un punto, así cada árbol nace en su sector y no se mezcla con los otros.
    ggplot2::coord_radial(theta = "x", expand = FALSE, inner.radius = 0.14,
                          clip = "off") +
    .polar_dendrograma(arboles[[1]]) +
    # Sin leyenda: el número de grupo no significa lo mismo en cada sector
    # (cada árbol corta a su manera), y el color solo tiene que separar grupos.
    ggplot2::labs(subtitle = sprintf(
      "distancia %s · %d hojas · k = %d en cada árbol · altura escalada",
      arboles[[1]]$distancia, n, k)) +
    ggplot2::theme(legend.position = "none",
                   plot.margin = ggplot2::margin(6, 52, 30, 52))
}

.nombre_enlace <- function(enlace)
  c(complete = "Completo", average = "Promedio", single = "Simple",
    ward.D2 = "Ward", centroid = "Centroide")[[enlace]] %||% enlace

# Curvas y nodos de un árbol, listos para polares. La curva se arma en
# (ángulo, altura) antes de pasar a polares: la altura avanza lineal del padre
# al hijo y el ángulo con una suavizada (3t² − 2t³), que sale y llega tangente
# a la dirección radial, como los enlaces radiales de d3. `desplazar` y
# `escala` ubican el árbol en su sector cuando van varios en un círculo.
.trazos_radiales <- function(arbol, desplazar = 0, escala = 1, prefijo = "") {
  t <- seq(0, 1, length.out = 24)
  suave <- 3 * t^2 - 2 * t^3
  e <- arbol$enlaces
  curvas <- do.call(rbind, lapply(seq_len(nrow(e)), function(i)
    data.frame(x = desplazar + e$x[i] + (e$xend[i] - e$x[i]) * suave,
               y = escala * (e$y[i] + (e$yend[i] - e$y[i]) * t),
               id = paste(prefijo, i))))
  nodos <- arbol$nodos
  nodos$x <- nodos$x + desplazar
  nodos$y <- nodos$y * escala
  nodos$clase <- ifelse(nodos$raiz_grupo, "raiz",
                        ifelse(nodos$tipo == "hoja", "hoja", "interno"))
  list(curvas = curvas, nodos = nodos)
}

# Tres tamaños de punto: grande donde nace cada grupo (bajo el corte), mediano
# en los nodos internos, chico en las hojas. Los enlaces van en gris claro
# para que el color quede en los puntos.
.capas_radiales <- function(trazos, k,
                            tamanos = c(raiz = 4.2, interno = 1.8, hoja = 1.6)) {
  nodos <- trazos$nodos
  ggplot2::ggplot() +
    ggplot2::geom_path(data = trazos$curvas,
                       ggplot2::aes(x = .data$x, y = .data$y, group = .data$id),
                       color = "grey72", linewidth = 0.35) +
    ggplot2::geom_point(data = nodos[is.na(nodos$grupo), ],
                        ggplot2::aes(x = .data$x, y = .data$y),
                        color = "grey60", size = 1.2) +
    ggplot2::geom_point(data = nodos[!is.na(nodos$grupo), ],
                        ggplot2::aes(x = .data$x, y = .data$y,
                                     color = .data$grupo, size = .data$clase)) +
    ggplot2::scale_size_manual(values = tamanos, guide = "none") +
    ggplot2::scale_color_manual(values = paleta_cat(k),
                                breaks = as.character(seq_len(k)),
                                name = "grupo")
}

# Lo común a las dos formas: leyenda en una fila, subtítulo en dos renglones
# (la figura es cuadrada y en uno se corta) y la cuadrícula apagada elemento
# por elemento: tema_ggplot() fija los .major.x/.y, que le ganan a
# `panel.grid`, y en polares dibujarían anillos y radios que no significan
# nada.
.polar_dendrograma <- function(arbol) {
  list(
    ggplot2::guides(color = ggplot2::guide_legend(nrow = 1)),
    ggplot2::labs(x = NULL, y = NULL,
                  subtitle = sub(" · (?=[0-9]+ hojas)", "\n",
                                 .subtitulo_dendrograma(arbol), perl = TRUE)),
    tema_ggplot(),
    ggplot2::theme(axis.text = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.minor.x = ggplot2::element_blank(),
                   panel.grid.minor.y = ggplot2::element_blank(),
                   legend.position = "bottom"))
}

# Cada nombre sale radial desde su hoja. En la mitad izquierda se voltea 180°
# para que no quede de cabeza, y entonces se alinea al otro extremo.
.nombres_polares <- function(arbol, hueco, radio) {
  hojas <- arbol$hojas
  angulo <- 90 - 360 * (hojas$x - 0.5) / (arbol$n + hueco)
  izquierda <- angulo < -90
  hojas$angulo <- ifelse(izquierda, angulo + 180, angulo)
  hojas$ajuste <- ifelse(izquierda, 1, 0)
  ggplot2::geom_text(data = hojas,
                     ggplot2::aes(x = .data$x, y = radio,
                                  label = .data$etiqueta, color = .data$grupo,
                                  angle = .data$angulo, hjust = .data$ajuste),
                     inherit.aes = FALSE, size = 1.9, show.legend = FALSE)
}
