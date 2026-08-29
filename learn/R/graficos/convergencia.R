# learn/R/graficos/convergencia.R
#
# Responsabilidad: hacer visible lo que pasa DENTRO del optimizador.
#
# La pregunta que estas figuras contestan no es "¿cuánto dio?" sino "¿por qué
# se detuvo acá y no allá?". Sin ellas el ajuste es un botón que tarda; con
# ellas es un proceso que se puede discutir.
#
# Reciben las tablas de R/logica/traza.R. Un método con solución cerrada no
# tiene traza, y eso se dice con todas las letras en vez de dibujar un panel
# vacío.

#' Traza de convergencia: el objetivo contra la iteración.
#'
#' @param tabla salida de traza_a_tabla()
#' @param escala_log el descenso final es diminuto en escala lineal; en log se
#'   ve si de verdad se aplanó o si seguía bajando cuando se cortó
#' @param objetivo nombre de lo que desciende, para el eje
graficar_convergencia <- function(tabla, escala_log = FALSE,
                                  objetivo = "objetivo") {
  if (!nrow(tabla))
    return(.grafico_vacio("este optimizador no deja traza: resuelve en un paso"))

  tabla$paso <- seq_len(nrow(tabla))
  # En log no entra el cero: la última componente deja exactamente cero varianza
  # sin explicar, y log(0) no es un punto que falte dibujar, es un punto que no
  # existe. Se recorta antes y el subtítulo lo dice.
  recortadas <- 0L
  if (escala_log) {
    positivas <- tabla$objetivo > 0
    recortadas <- sum(!positivas)
    tabla <- tabla[positivas, , drop = FALSE]
    if (!nrow(tabla))
      return(.grafico_vacio("el objetivo llego a cero: no hay escala log que mostrar"))
  }
  tabla$componente <- factor(tabla$componente)
  n_componentes <- length(levels(tabla$componente))

  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$paso,
                                                 y = .data$objetivo,
                                                 color = .data$componente)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 1.1) +
    scale_color_cat(n_componentes, name = "componente") +
    ggplot2::labs(x = "iteracion acumulada", y = objetivo,
                  subtitle = .subtitulo_convergencia(nrow(tabla), n_componentes,
                                                     recortadas)) +
    tema_ggplot()

  if (escala_log) grafico <- grafico + ggplot2::scale_y_log10()
  grafico
}

.subtitulo_convergencia <- function(iteraciones, componentes, recortadas) {
  base <- sprintf("%d iteraciones en %d componente(s)", iteraciones, componentes)
  if (recortadas == 0L) return(base)
  sprintf("%s · %d con objetivo cero fuera de la escala log", base, recortadas)
}

#' Trayectoria: cada parámetro contra la iteración.
#'
#' Responde cuál tardó más en estabilizarse. En el ACP son las cargas del
#' autovector: se ve al vector girar hasta quedarse quieto.
#'
#' @param tabla salida de parametros_a_tabla()
#' @param componente cuál mirar; NULL = la primera disponible
graficar_trayectoria <- function(tabla, componente = NULL) {
  if (!nrow(tabla))
    return(.grafico_vacio("sin parametros registrados en la traza"))

  componente <- componente %||% min(tabla$componente)
  tabla <- tabla[tabla$componente == componente, , drop = FALSE]
  if (!nrow(tabla))
    return(.grafico_vacio(sprintf("la componente %s no tiene traza", componente)))

  # Con un ACP de 16 columnas o un k-medias de 4 grupos por 8 variables, la
  # trayectoria son decenas de lineas y no se lee ninguna. Se muestran las que
  # mas se movieron, que son las que contestan la pregunta de esta vista, y el
  # subtitulo dice cuantas quedaron fuera.
  total <- length(unique(tabla$parametro))
  tabla <- .parametros_mas_moviles(tabla, maximo = 8L)
  n_parametros <- length(unique(tabla$parametro))

  ggplot2::ggplot(tabla, ggplot2::aes(x = .data$iter, y = .data$valor,
                                      color = .data$parametro)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey80", linewidth = 0.4) +
    ggplot2::geom_line(linewidth = 0.8) +
    scale_color_cat(n_parametros, name = NULL) +
    ggplot2::labs(x = "iteracion", y = "valor del parametro",
                  subtitle = .subtitulo_trayectoria(componente, n_parametros,
                                                    total)) +
    tema_ggplot()
}

.parametros_mas_moviles <- function(tabla, maximo) {
  nombres <- unique(tabla$parametro)
  if (length(nombres) <= maximo) return(tabla)
  recorrido <- vapply(nombres, function(nombre) {
    valores <- tabla$valor[tabla$parametro == nombre]
    if (length(valores) < 2L) return(0)
    diff(range(valores, na.rm = TRUE))
  }, numeric(1))
  elegidos <- names(sort(recorrido, decreasing = TRUE))[seq_len(maximo)]
  tabla[tabla$parametro %in% elegidos, , drop = FALSE]
}

.subtitulo_trayectoria <- function(componente, mostrados, total) {
  if (mostrados == total)
    return(sprintf("componente %s · %d parametros", componente, total))
  sprintf("componente %s · los %d parametros que mas se movieron, de %d",
          componente, mostrados, total)
}

#' Cuánto cambió el vector en cada paso: el criterio de parada, dibujado.
#'
#' La línea de la tolerancia es dónde el optimizador decidió que ya estaba.
graficar_deltas <- function(tabla, tol = NULL) {
  if (!nrow(tabla)) return(.grafico_vacio("sin traza que mirar"))
  tabla <- tabla[is.finite(tabla$delta) & tabla$delta > 0, , drop = FALSE]
  if (!nrow(tabla)) return(.grafico_vacio("la traza no registro cambios"))

  tabla$paso <- seq_len(nrow(tabla))
  grafico <- ggplot2::ggplot(tabla, ggplot2::aes(x = .data$paso,
                                                 y = .data$delta)) +
    ggplot2::geom_line(color = paleta_cat(1), linewidth = 0.8) +
    ggplot2::scale_y_log10() +
    ggplot2::labs(x = "iteracion acumulada",
                  y = "cambio del vector (escala log)") +
    tema_ggplot()

  if (!is.null(tol) && is.finite(tol) && tol > 0)
    grafico <- grafico +
      ggplot2::geom_hline(yintercept = tol, linetype = "dashed",
                          color = paleta_cat(2)[2])
  grafico
}
