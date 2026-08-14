# learn/R/ui/f1/diccionario.R
#
# Responsabilidad: subsección Diccionario — declarar qué es cada columna.
#
# Se edita una fila por vez desde el sidebar en vez de con una tabla editable:
# DT::datatable(editable=) devuelve eventos que hay que interpretar del lado
# del cliente, y eso es superficie que R no puede testear (C10). Con selector
# más botón, el mismo cambio es una acción verificable desde test_app.R.
#
# Lo que se declara acá gobierna el resto de la app: la escala decide qué
# estadístico y qué gráfico se habilitan en ▣ Análisis.

controles_diccionario <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("columna_dic"), "Columna", choices = character(0)),
    shiny::textInput(ns("etiqueta"), "Etiqueta", value = ""),
    shiny::selectInput(ns("escala"), "Escala de medicion", choices = ESCALAS),
    shiny::selectInput(ns("clase"), "Clase", choices = CLASES),
    shiny::selectInput(ns("rol"), "Rol", choices = ROLES),
    shiny::textInput(ns("unidad"), "Unidad", value = ""),
    shiny::actionButton(ns("aplicar_dic"), "Aplicar a la columna",
                        class = "btn-primary w-100"),
    shiny::uiOutput(ns("razon_escala")))
}

#' Rellena el selector de columnas cuando entra o cambia el dataset.
actualizar_diccionario_ui <- function(session, ds, previos = list()) {
  .rellenar_selector(session, "columna_dic", ds$diccionario$columna,
                     previos$columna_dic)
}

salida_diccionario <- function(ns) {
  panel_resultado(
    "f1.diccionario.tabla",
    shiny::tagList(
      shiny::uiOutput(ns("avisos_dic")),
      salida_tabla(ns, "tabla_dic"),
      shiny::uiOutput(ns("operaciones_dic"))),
    contexto = salida_contexto(ns, "contexto_dic"))
}

servidor_diccionario <- function(input, output, session, dataset) {

  # Al elegir otra columna, los campos muestran lo que esa columna tiene hoy.
  shiny::observeEvent(input$columna_dic, {
    ds <- dataset()
    shiny::req(ds, input$columna_dic)
    fila <- ds$diccionario[ds$diccionario$columna == input$columna_dic, ]
    shiny::req(nrow(fila) == 1L)
    shiny::updateTextInput(session, "etiqueta", value = fila$etiqueta)
    shiny::updateTextInput(session, "unidad", value = fila$unidad)
    shiny::updateSelectInput(session, "escala", selected = fila$escala)
    shiny::updateSelectInput(session, "clase", selected = fila$clase)
    shiny::updateSelectInput(session, "rol", selected = fila$rol)
  })

  output$razon_escala <- shiny::renderUI({
    escala <- input$escala %||% "razon"
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  operaciones_permitidas(escala)$razon)
  })

  shiny::observeEvent(input$aplicar_dic, {
    ds <- dataset()
    shiny::req(ds, input$columna_dic)
    diccionario <- ds$diccionario
    for (campo in c("etiqueta", "escala", "clase", "rol", "unidad")) {
      valor <- input[[campo]]
      if (!is.null(valor))
        diccionario <- actualizar_diccionario(diccionario, input$columna_dic,
                                              campo, valor)
    }
    ds$diccionario <- diccionario
    dataset(ds)
  })

  dibujar_tabla(output, "tabla_dic", shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    ds$diccionario
  }), filtro = "none")

  output$avisos_dic <- shiny::renderUI({
    ds <- dataset()
    if (is.null(ds)) return(NULL)
    lista_avisos(avisos_diccionario(ds$diccionario))
  })

  # Lo que la escala habilita o prohíbe, escrito, no solo aplicado.
  output$operaciones_dic <- shiny::renderUI({
    ds <- dataset()
    shiny::req(ds, input$columna_dic)
    fila <- ds$diccionario[ds$diccionario$columna == input$columna_dic, ]
    if (!nrow(fila)) return(NULL)
    permitidas <- operaciones_permitidas(fila$escala)
    shiny::tags$div(
      class = "small mt-3",
      shiny::tags$strong(sprintf("Con escala %s se habilitan: ", fila$escala)),
      paste(permitidas$estadisticos, collapse = ", "),
      shiny::tags$br(),
      shiny::tags$span(class = "text-muted",
                       sprintf("Graficos: %s",
                               paste(permitidas$graficos, collapse = ", "))))
  })

  dibujar_contexto(output, "f1.diccionario.tabla",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     list(columnas = ds$p,
                          respuestas = paste(columnas_con_rol(ds, "respuesta"),
                                             collapse = ", "),
                          numericas = length(columnas_numericas(ds)))
                   }), sufijo = "contexto_dic")
}
