# learn/R/ui/f4/explicabilidad.R
#
# Responsabilidad: subsección Explicabilidad — dónde cayeron las observaciones.
#
# El mapa 2D, el biplot y el perfil de los grupos: las vistas que hablan de
# individuos. Lo que habla de variables (cargas, círculo, contribución, calidad)
# vive en f4/aportes.R y se dibuja en esta misma subsección: son cards de la
# misma pestaña, partidas por lo que cuentan y no por el techo de líneas.
#
# Los controles de acá los leen las dos mitades: el par de ejes es compartido a
# propósito, porque mirar las cargas de un plano y los puntos de otro sería
# comparar cosas que no se comparan.

controles_explicabilidad <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("eje_x"), "Componente horizontal",
                       choices = c("CP1" = "1")),
    shiny::selectInput(ns("eje_y"), "Componente vertical",
                       choices = c("CP2" = "2")),
    shiny::selectInput(ns("color"), "Colorear por",
                       choices = c("sin color" = "")),
    shiny::sliderInput(ns("alfa"), "Transparencia de los puntos",
                       min = 0.1, max = 1, value = 0.7, step = 0.05),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("El color no participó del ajuste: si los grupos se",
                        "separan, es un hallazgo.")),
    bslib::accordion(
      open = FALSE,
      bslib::accordion_panel(
        "Suplementarios",
        shiny::selectInput(ns("suplementario"), "Individuos de otro dataset",
                           choices = c("ninguno" = "")),
        shiny::selectInput(ns("variable_sup"), "Variable que no entró",
                           choices = c("ninguna" = "")),
        shiny::tags$p(class = "text-muted small mb-0",
                      paste("Se proyectan con las cargas del ajuste y no lo",
                            "movieron: dicen dónde caerían, no qué eje hay.")))))
}

#' Los ejes disponibles los declara la familia del ajuste: las componentes
#' RETENIDAS en el ACP —pedir la quinta cuando se guardaron dos no es un error
#' del usuario, es una opción que no debería existir— y los dos del plano en
#' una partición.
actualizar_explicabilidad <- function(session, corrida, dataset,
                                      previos = list(), almacen = NULL) {
  if (is.null(corrida)) return(invisible(FALSE))
  ajuste <- corrida$ajuste
  nombres <- etiquetas_ejes(ajuste)
  opciones <- stats::setNames(as.character(seq_along(nombres)), nombres)
  .rellenar_selector(session, "eje_x", opciones, previos$eje_x %||% "1")
  .rellenar_selector(session, "eje_y", opciones,
                     previos$eje_y %||% as.character(min(2L, length(nombres))))

  shiny::updateSelectInput(session, "color",
                           choices = .opciones_color(dataset),
                           selected = previos$color %||% "")
  shiny::updateSelectInput(session, "suplementario",
                           choices = .opciones_suplementarias(ajuste, almacen,
                                                              dataset),
                           selected = previos$suplementario %||% "")
  shiny::updateSelectInput(session, "variable_sup",
                           choices = .opciones_variable_sup(ajuste, dataset),
                           selected = previos$variable_sup %||% "")
  invisible(TRUE)
}

# Una cualitativa colorea por grupo; una cuantitativa, en degradado. Las dos
# sirven y dicen cosas distintas, así que se ofrecen las dos, separadas para que
# se vea que la elección tiene consecuencias.
.opciones_color <- function(dataset) {
  if (is.null(dataset)) return(c("sin color" = ""))
  cualitativas <- unique(c(columnas_con_rol(dataset, "grupo"),
                           columnas_cualitativas(dataset)))
  cuantitativas <- columnas_numericas(dataset)
  opciones <- list("sin color" = "")
  if (length(cualitativas)) opciones[["por grupo"]] <- cualitativas
  if (length(cuantitativas)) opciones[["en degradado"]] <- cuantitativas
  opciones
}

# Solo los datasets que de verdad se pueden proyectar: uno al que le falta una
# columna del ajuste no entra al selector, en vez de entrar y fallar al dibujar.
.opciones_suplementarias <- function(ajuste, almacen, dataset) {
  if (is.null(almacen) || is.null(ajuste$centro)) return(c("ninguno" = ""))
  lista <- almacen()
  ids <- setdiff(almacen_ids(lista, "dataset"), dataset$id %||% "")
  sirven <- Filter(function(id) {
    ds <- almacen_obtener(lista, "dataset", id)
    isTRUE(sirve_como_suplementario(ajuste, ds$df))
  }, ids)
  if (!length(sirven)) return(c("ninguno" = ""))
  etiquetas <- vapply(sirven, function(id)
    sprintf("%s · %s", id, almacen_obtener(lista, "dataset", id)$nombre), "")
  c(stats::setNames("", "ninguno"), stats::setNames(sirven, etiquetas))
}

# Una variable suplementaria es, por definición, una que NO entró al ajuste.
.opciones_variable_sup <- function(ajuste, dataset) {
  if (is.null(dataset)) return(c("ninguna" = ""))
  fuera <- setdiff(columnas_numericas(dataset), ajuste$columnas)
  if (!length(fuera)) return(c("ninguna" = ""))
  c(stats::setNames("", "ninguna"), stats::setNames(fuera, fuera))
}

salida_explicabilidad <- function(ns) {
  shiny::tagList(
    panel_si_declara(ns, "f4.explicabilidad.mapa_2d",
                     shiny::plotOutput(ns("mapa"), height = "380px"),
                     contexto = salida_contexto(ns, "contexto_mapa")),
    panel_si_declara(ns, "f4.explicabilidad.centroides",
                     shiny::plotOutput(ns("centroides"), height = "400px"),
                     contexto = salida_contexto(ns, "contexto_centroides")),
    panel_si_declara(ns, "f4.explicabilidad.biplot",
                     shiny::plotOutput(ns("biplot"), height = "420px"),
                     contexto = salida_contexto(ns, "contexto_biplot")),
    salida_aportes(ns))
}

servidor_explicabilidad <- function(input, output, session, corrida, dataset,
                                    almacen = NULL) {
  contexto <- contexto_plano(input, output, session, corrida, dataset)
  ajuste <- contexto$ajuste
  ejes <- contexto$ejes
  etiquetas <- contexto$etiquetas

  suplementarios <- shiny::reactive({
    id <- input$suplementario %||% ""
    if (!nzchar(id) || is.null(almacen)) return(NULL)
    ds <- almacen_obtener(almacen(), "dataset", id)
    .o_aviso(proyectar_individuos(ajuste(), ds$df, ejes()))
  })

  output$mapa <- shiny::renderPlot({
    contexto$exigir_ejes()
    graficar_mapa_2d(coordenadas_2d(ajuste(), ejes(), contexto$grupo()),
                     etiquetas(), alfa = input$alfa %||% 0.7,
                     color_nombre = contexto$nombre_color(),
                     suplementarios = suplementarios())
  })

  output$centroides <- shiny::renderPlot(
    graficar_centroides(centroides_tabla(ajuste())))

  output$biplot <- shiny::renderPlot({
    contexto$exigir_ejes()
    graficar_biplot(coordenadas_biplot(ajuste(), ejes(), contexto$grupo()),
                    etiquetas(), alfa = input$alfa %||% 0.6,
                    color_nombre = contexto$nombre_color(),
                    suplementarios = suplementarios())
  })

  servidor_aportes(input, output, session, contexto)

  for (par in list(c("f4.explicabilidad.mapa_2d", "contexto_mapa"),
                   c("f4.explicabilidad.centroides", "contexto_centroides"),
                   c("f4.explicabilidad.biplot", "contexto_biplot")))
    dibujar_contexto(output, par[1], params = contexto$parametros,
                     metricas = contexto$metricas, corrida = contexto$corrida,
                     sufijo = par[2])
  invisible(TRUE)
}
