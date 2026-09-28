# learn/R/graficos/explicabilidad.R
#
# Responsabilidad: contar QUÉ dice un ajuste, no si es bueno.
#
# Fase 4, subsección Explicabilidad. En reducción de dimensión la pregunta es
# siempre la misma: ¿qué significa esta componente? Se contesta mirando qué
# variables la forman (cargas), cómo se correlacionan con ella (círculo) y
# dónde caen las observaciones (mapa y biplot).
#
# El biplot se dibuja a mano con ggplot2 en vez de traer factoextra: son treinta
# líneas y una dependencia menos en el bundle wasm.

#' Cargas: qué variable pesa en cada componente.
#'
#' Barras con signo, no en valor absoluto: el signo dice si la variable empuja
#' hacia el lado positivo o el negativo del eje, y eso es media interpretación.
#'
#' @param tabla salida de cargas()
graficar_cargas <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay cargas que mirar"))

  tabla$variable <- stats::reorder(tabla$variable, tabla$carga)
  tabla$signo <- ifelse(tabla$carga >= 0, "positiva", "negativa")

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$carga, y = .data$variable,
                                      fill = .data$signo)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_vline(xintercept = 0, color = "grey40", linewidth = 0.4) +
    ggplot2::facet_wrap(~ etiqueta, nrow = 1) +
    ggplot2::scale_fill_manual(values = c(positiva = paleta_cat(1),
                                          negativa = paleta_cat(2)[2]),
                               name = NULL) +
    ggplot2::labs(x = "carga", y = NULL) +
    tema_ggplot()
}

#' Círculo de correlaciones: cada variable como una flecha dentro del círculo
#' unidad.
#'
#' Una flecha larga está bien representada en este plano; una corta vive en las
#' componentes que no se están mirando. Dos flechas juntas son variables que
#' dicen lo mismo, y en ángulo recto, variables independientes.
#'
#' @param tabla salida de correlaciones_componentes()
#' @param sobre_correlacion FALSE cuando se descompuso S: el círculo de radio 1
#'   no aplica y hay que decirlo en vez de dibujar un marco que engaña
#' @param suplementarias salida de proyectar_variable(), o NULL. Punteadas y en
#'   otro color: no construyeron los ejes y confundirlas con las activas sería
#'   atribuirles un papel que no tuvieron.
graficar_circulo <- function(tabla, ejes = c("CP1", "CP2"),
                             sobre_correlacion = TRUE,
                             suplementarias = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))

  angulos <- seq(0, 2 * pi, length.out = 200)
  circulo <- data.frame(x = cos(angulos), y = sin(angulos))
  limite <- max(1, max(abs(c(tabla$x, tabla$y, suplementarias$x,
                             suplementarias$y)), na.rm = TRUE))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey85") +
    ggplot2::geom_vline(xintercept = 0, color = "grey85") +
    ggplot2::geom_segment(x = 0, y = 0,
                          ggplot2::aes(xend = .data$x, yend = .data$y),
                          color = paleta_cat(1), linewidth = 0.7,
                          arrow = ggplot2::arrow(length = ggplot2::unit(6, "pt"),
                                                 type = "closed")) +
    ggplot2::geom_text(ggplot2::aes(label = .data$variable), size = 3.3,
                       vjust = -0.6, color = "grey20") +
    ggplot2::coord_equal(xlim = c(-limite, limite), ylim = c(-limite, limite)) +
    ggplot2::labs(x = ejes[1], y = ejes[2]) +
    tema_ggplot()

  if (sobre_correlacion) {
    grafico <- grafico + ggplot2::geom_path(data = circulo, color = "grey60",
                                            linewidth = 0.5)
  } else {
    grafico <- grafico + ggplot2::labs(
      subtitle = "sobre S (covarianza): las flechas no estan acotadas por 1")
  }
  .capa_variable_suplementaria(grafico, suplementarias)
}

.capa_variable_suplementaria <- function(grafico, suplementarias) {
  if (is.null(suplementarias) || !nrow(suplementarias)) return(grafico)
  grafico +
    ggplot2::geom_segment(data = suplementarias, x = 0, y = 0,
                          ggplot2::aes(xend = .data$x, yend = .data$y),
                          color = paleta_cat(4)[4], linewidth = 0.7,
                          linetype = "dashed",
                          arrow = ggplot2::arrow(length = ggplot2::unit(6, "pt"),
                                                 type = "open")) +
    ggplot2::geom_text(data = suplementarias,
                       ggplot2::aes(label = .data$variable), size = 3.3,
                       vjust = 1.4, color = paleta_cat(4)[4])
}

#' Mapa 2D: las observaciones en el plano de dos componentes.
#'
#' @param tabla salida de coordenadas_2d()
#' @param color_nombre qué dice la leyenda del color, o NULL
#' @param suplementarios salida de proyectar_individuos(), o NULL
graficar_mapa_2d <- function(tabla, ejes = c("CP1", "CP2"), alfa = 0.7,
                             color_nombre = NULL, suplementarios = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay puntuaciones"))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$x, y = .data$y,
                                                 color = .data$grupo)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey88") +
    ggplot2::geom_vline(xintercept = 0, color = "grey88") +
    ggplot2::geom_point(alpha = alfa, size = 1.4) +
    .escala_color_puntos(tabla$grupo, color_nombre) +
    ggplot2::labs(x = ejes[1], y = ejes[2],
                  subtitle = sprintf("%d observaciones", nrow(tabla))) +
    tema_ggplot()
  .capa_individuos_suplementarios(grafico, suplementarios)
}

# Un color continuo no se puede pintar con una paleta categórica: con 32 valores
# distintos scale_color_manual pide 32 colores y ninguno significa nada. El
# degradado, en cambio, deja ver que el eje 1 ES esa variable.
.escala_color_puntos <- function(valores, nombre = NULL) {
  if (is.numeric(valores)) return(scale_color_seq(name = nombre))
  niveles <- length(levels(valores))
  scale_color_cat(niveles, name = nombre,
                  guide = if (niveles < 2L) "none" else "legend")
}

# Los suplementarios van en otra forma y con etiqueta: están dibujados en un
# plano que no ayudaron a elegir, y el gráfico tiene que decirlo solo.
.capa_individuos_suplementarios <- function(grafico, suplementarios) {
  if (is.null(suplementarios) || !nrow(suplementarios)) return(grafico)
  grafico +
    ggplot2::geom_point(data = suplementarios,
                        ggplot2::aes(x = .data$x, y = .data$y),
                        inherit.aes = FALSE, shape = 17, size = 2.6,
                        color = paleta_cat(4)[4]) +
    ggplot2::geom_text(data = suplementarios,
                       ggplot2::aes(x = .data$x, y = .data$y,
                                    label = .data$etiqueta),
                       inherit.aes = FALSE, size = 3.1, vjust = -0.8,
                       color = paleta_cat(4)[4]) +
    ggplot2::labs(caption = sprintf("%d suplementarios: proyectados, no ajustados",
                                    nrow(suplementarios)))
}

#' Biplot: observaciones y variables en el mismo plano.
#'
#' Las flechas están reescaladas para que quepan junto a los puntos; ese factor
#' es una decisión de dibujo, no un resultado, y por eso viaja al subtítulo.
#'
#' @param coordenadas salida de coordenadas_biplot()
#' @param color_nombre qué dice la leyenda del color, o NULL
#' @param suplementarios salida de proyectar_individuos(), o NULL
graficar_biplot <- function(coordenadas, ejes = c("CP1", "CP2"), alfa = 0.6,
                            color_nombre = NULL, suplementarios = NULL) {
  puntos <- coordenadas$puntos
  flechas <- coordenadas$flechas
  if (!nrow(puntos)) return(.grafico_vacio("todavia no hay puntuaciones"))

  grafico <- ggplot2::ggplot(puntos, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey88") +
    ggplot2::geom_vline(xintercept = 0, color = "grey88") +
    ggplot2::geom_point(ggplot2::aes(color = .data$grupo), alpha = alfa,
                        size = 1.3) +
    ggplot2::geom_segment(data = flechas, x = 0, y = 0,
                          ggplot2::aes(xend = .data$x, yend = .data$y),
                          color = "grey25", linewidth = 0.7,
                          arrow = ggplot2::arrow(length = ggplot2::unit(6, "pt"),
                                                 type = "closed")) +
    ggplot2::geom_text(data = flechas, ggplot2::aes(label = .data$variable),
                       color = "grey15", size = 3.3, vjust = -0.5) +
    .escala_color_puntos(puntos$grupo, color_nombre) +
    ggplot2::labs(x = ejes[1], y = ejes[2],
                  subtitle = sprintf("flechas reescaladas x%.2f para que entren con los puntos",
                                     coordenadas$escala_flechas)) +
    tema_ggplot()
  .capa_individuos_suplementarios(grafico, suplementarios)
}

#' Contribución de cada variable al eje: quién puso la varianza.
#'
#' La línea de referencia es 100/p, lo que aportaría cada variable si todas
#' aportaran igual. Por encima de esa línea la variable está definiendo el eje;
#' por debajo, viene arrastrada.
#'
#' @param tabla salida de contribuciones()
graficar_contribuciones <- function(tabla) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay cargas que mirar"))
  referencia <- 100 / length(unique(tabla$variable))
  tabla$variable <- stats::reorder(tabla$variable, tabla$contribucion)

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$contribucion,
                                      y = .data$variable)) +
    ggplot2::geom_col(width = 0.7, fill = paleta_cat(1)) +
    ggplot2::geom_vline(xintercept = referencia, linetype = "dashed",
                        color = "grey40") +
    ggplot2::facet_wrap(~ etiqueta, nrow = 1) +
    ggplot2::labs(x = "contribucion (%)", y = NULL,
                  subtitle = sprintf("reparto de 100 por componente · reparto parejo = %.1f %%",
                                     referencia)) +
    tema_ggplot()
}

#' Calidad de representación: cuánto de cada variable muestra este plano.
#'
#' Apilado por eje, porque lo que importa es la suma: una barra corta no es una
#' variable sin importancia, es una variable que vive en las componentes que no
#' se están mirando, y la decisión que sigue es mirar otro plano.
#'
#' @param tabla salida de calidad_variables()
#' @param sobre_correlacion FALSE cuando se descompuso S: el cos² puede pasarse
#'   de 1 y hay que avisarlo en vez de recortarlo
graficar_calidad <- function(tabla, sobre_correlacion = TRUE) {
  if (!nrow(tabla)) return(.grafico_vacio("todavia no hay ajuste que mirar"))
  tabla$variable <- stats::reorder(tabla$variable, tabla$cos2_plano)

  aviso <- if (sobre_correlacion)
    "1 = la variable esta enteramente en este plano"
  else "sobre S las coordenadas no son correlaciones: el cos2 puede pasar de 1"

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$cos2, y = .data$variable,
                                      fill = .data$etiqueta)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(values = paleta_cat(length(unique(tabla$etiqueta))),
                               name = NULL) +
    ggplot2::labs(x = "cos2 acumulado en el plano", y = NULL, subtitle = aviso) +
    tema_ggplot()
}
