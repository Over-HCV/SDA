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

# Más de doce cajas en un boxplot ya no se comparan, se cuentan. El tope es la
# regla automática, no un límite duro: el rol declarado lo salta a propósito.
TOPE_NIVELES_GRUPO <- 12L

#' Columnas que sirven de grupo.
#'
#' Dos caminos: el automático —cualitativas u ordinales con pocos niveles— y el
#' declarado —rol "grupo" en el diccionario—, este último sin tope. Si el
#' usuario dice que la columna es el grupo, es el grupo; lo que se hace es
#' avisar que 151 cajas no se leen, no esconderle el control (C5).
.grupos_de <- function(ds) {
  diccionario <- if (is.null(ds)) NULL else ds$diccionario
  if (is.null(diccionario) || !nrow(diccionario)) return(character(0))
  utiles <- diccionario$n_unicos >= 2
  automaticas <- utiles & diccionario$clase != "continua" &
    diccionario$n_unicos <= TOPE_NIVELES_GRUPO
  declaradas <- utiles & diccionario$rol == "grupo"
  unique(diccionario$columna[automaticas | declaradas])
}

#' Columnas de grupo que entran solo por rol declarado y son ilegibles.
.grupos_desbordados <- function(ds) {
  diccionario <- if (is.null(ds)) NULL else ds$diccionario
  if (is.null(diccionario) || !nrow(diccionario)) return(character(0))
  desbordadas <- diccionario$rol == "grupo" &
    diccionario$n_unicos > TOPE_NIVELES_GRUPO
  diccionario$columna[desbordadas]
}

#' Por qué no hay ninguna columna de grupo, dicho con nombres y cuentas.
#'
#' Un selector vacío sin explicación es el peor de los estados: parece roto. Se
#' nombra la mejor candidata descartada y el camino de salida (C5).
.motivo_sin_grupos <- function(ds) {
  diccionario <- if (is.null(ds)) NULL else ds$diccionario
  salida <- paste("Marca una columna con rol 'grupo' en el Diccionario si",
                  "queres forzarla.")
  if (is.null(diccionario) || !nrow(diccionario))
    return(paste("Todavia no hay diccionario: carga un dataset.", salida))

  no_continuas <- diccionario[diccionario$clase != "continua" &
                                diccionario$n_unicos >= 2, ]
  continuas <- sum(diccionario$clase == "continua")
  cola <- if (continuas)
    sprintf("; las %d continuas no agrupan", continuas) else ""

  if (!nrow(no_continuas))
    return(sprintf(paste("Ninguna columna califica como grupo: las %d columnas",
                         "son continuas y una continua no agrupa. %s"),
                   nrow(diccionario), salida))

  peor <- no_continuas[which.min(no_continuas$n_unicos), ]
  sprintf(paste("Ninguna columna califica como grupo: '%s' tiene %d niveles (el",
                "automatico admite hasta %d)%s. %s"),
          peor$columna, peor$n_unicos, TOPE_NIVELES_GRUPO, cola, salida)
}

#' Por que el cruce no se puede armar: necesita DOS cualitativas distintas.
#'
#' Con una sola candidata el motivo del grupo mentiria ("ninguna califica"),
#' asi que el cruce tiene su propio texto.
.motivo_sin_cruce <- function(ds) {
  candidatas <- .grupos_de(ds)
  if (length(candidatas) >= 2L) return(NULL)
  if (!length(candidatas)) return(.motivo_sin_grupos(ds))
  sprintf(paste("La tabla de contingencia cruza dos cualitativas y aca solo",
                "hay una: '%s'. Declara otra con rol 'grupo' en el",
                "Diccionario, o discretiza una numerica antes."),
          candidatas[1])
}

#' Nota del sidebar bajo los selectores de cruce.
.nota_cruce <- function(ds) {
  if (is.null(ds)) return(NULL)
  motivo <- .motivo_sin_cruce(ds)
  if (is.null(motivo)) return(NULL)
  shiny::tags$p(class = "text-muted small mt-2 mb-0", motivo)
}

#' Nota del sidebar bajo los selectores de grupo: o el motivo del vacio, o el
#' aviso de legibilidad de lo que entro por rol declarado.
.nota_grupos <- function(ds) {
  if (is.null(ds)) return(NULL)
  nota <- function(texto)
    shiny::tags$p(class = "text-muted small mt-2 mb-0", texto)

  if (!length(.grupos_de(ds))) return(nota(.motivo_sin_grupos(ds)))

  desbordadas <- .grupos_desbordados(ds)
  if (!length(desbordadas)) return(NULL)
  niveles <- ds$diccionario$n_unicos[
    match(desbordadas, ds$diccionario$columna)]
  nota(sprintf(paste("%s entra por rol declarado: %s cajas no se comparan,",
                     "se cuentan. Agrupa o filtra antes de leer el grafico."),
               paste(sprintf("'%s'", desbordadas), collapse = ", "),
               paste(niveles, collapse = ", ")))
}
