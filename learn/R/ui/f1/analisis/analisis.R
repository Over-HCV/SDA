# learn/R/ui/f1/analisis/analisis.R
#
# Responsabilidad: armazón de ▣ Análisis y reparto entre las tres dimensiones.
#
# Es el lugar donde la fase deja de configurarse y empieza a mirarse. Tres
# pestañas internas —univariado, bivariado, multivariado— cada una con su
# propio juego de controles, que el sidebar de la fase pide por su cuenta.
#
# Los gráficos reciben la MUESTRA y las tablas de estadísticos, el TOTAL (C8).

DIMENSIONES_ANALISIS <- c("Univariado", "Bivariado", "Multivariado")

salida_analisis <- function(ns) {
  bslib::navset_card_tab(
    id = ns("analisis"),
    bslib::nav_panel("Univariado", salida_univariado(ns)),
    bslib::nav_panel("Bivariado", salida_bivariado(ns)),
    bslib::nav_panel("Multivariado", salida_multivariado(ns)))
}

#' Los tres juegos de controles existen desde el arranque; se muestra el de la
#' dimensión abierta. La condición mira el id del navset interno.
controles_analisis <- function(ns) {
  visible_en <- function(dimension, contenido)
    shiny::conditionalPanel(
      sprintf("input.analisis == '%s'", dimension), ns = ns, contenido)
  shiny::tagList(
    visible_en("Univariado", controles_univariado(ns)),
    visible_en("Bivariado", controles_bivariado(ns)),
    visible_en("Multivariado", controles_multivariado(ns)))
}

actualizar_analisis <- function(session, ds, previos = list()) {
  actualizar_univariado(session, ds, previos)
  actualizar_bivariado(session, ds, previos)
  actualizar_multivariado(session, ds, previos)
}

servidor_analisis <- function(input, output, session, dataset, muestreo) {
  servidor_univariado(input, output, session, dataset, muestreo)
  servidor_bivariado(input, output, session, dataset, muestreo)
  servidor_multivariado(input, output, session, dataset, muestreo)
}

# --------------------------------------------------------------------------
# Auxiliares compartidos por las tres dimensiones
# --------------------------------------------------------------------------

#' Escala declarada de una columna. Es lo que decide qué se habilita.
.escala_de <- function(ds, columna) {
  if (is.null(ds) || is.null(columna)) return("razon")
  fila <- ds$diccionario[ds$diccionario$columna == columna, ]
  if (!nrow(fila)) "razon" else fila$escala
}

#' Corta el render con el motivo escrito cuando la escala no admite el gráfico.
#'
#' No se esconde el panel: se explica. Un control que desaparece sin decir por
#' qué enseña menos que uno bloqueado con su razón al lado (C5).
.exigir_operacion <- function(ds, columna, operacion) {
  escala <- .escala_de(ds, columna)
  shiny::validate(shiny::need(permite_operacion(escala, operacion),
                              razon_de_bloqueo(escala, operacion)))
  invisible(TRUE)
}

#' Nota del sidebar: qué habilita la escala de la variable elegida.
.nota_escala_variable <- function(ds, columna) {
  escala <- .escala_de(ds, columna)
  shiny::tags$p(class = "text-muted small mt-2 mb-0",
                sprintf("'%s' es de escala %s. %s", columna, escala,
                        operaciones_permitidas(escala)$razon))
}

#' Columnas que se pueden poner en un eje numérico, según el diccionario.
.numericas_de <- function(ds) {
  numericas <- columnas_numericas(ds)
  if (length(numericas)) numericas else names(ds$df)
}

#' Columnas que sirven de grupo: cualitativas u ordinales, con pocos niveles.
.grupos_de <- function(ds) {
  diccionario <- ds$diccionario
  candidatas <- diccionario$columna[diccionario$clase != "continua" &
                                      diccionario$n_unicos <= 12]
  candidatas
}
