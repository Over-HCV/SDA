# learn/R/ui/f1/transformacion.R
#
# Responsabilidad: subsección Transformación — la pila y su efecto.
#
# La pila se aplica siempre desde datos_base, el data.frame como se cargó. Por
# eso deshacer es exacto: se quita la última receta y se recalcula todo, en vez
# de intentar invertir una operación sobre datos ya transformados.

controles_transformacion <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("columnas_tr"), "Columnas", choices = character(0),
                       multiple = TRUE),
    shiny::selectInput(ns("tipo_tr"), "Transformacion",
                       choices = TRANSFORMACIONES, selected = "logaritmo"),
    shiny::sliderInput(ns("lambda"), "Lambda (solo Box-Cox)", -2, 2, 0,
                       step = 0.05),
    shiny::actionButton(ns("aplicar_tr"), "Aplicar", class = "btn-primary w-100"),
    shiny::actionButton(ns("deshacer_tr"), "Deshacer la ultima",
                        class = "btn-outline-secondary btn-sm w-100 mt-2"),
    shiny::tags$hr(),
    shiny::selectInput(ns("columna_perfil"), "Perfil de lambda para",
                       choices = character(0)))
}

actualizar_transformacion <- function(session, ds, previos = list()) {
  numericas <- columnas_numericas(ds)
  elegidas <- previos$columnas_tr
  if (!length(elegidas) || !all(elegidas %in% names(ds$df)))
    elegidas <- utils::head(numericas, 1)
  shiny::updateSelectInput(session, "columnas_tr", choices = names(ds$df),
                           selected = elegidas)
  .rellenar_selector(session, "columna_perfil", numericas,
                     previos$columna_perfil)
}

salida_transformacion <- function(ns) {
  shiny::tagList(
    shiny::uiOutput(ns("avisos_tr")),
    panel_resultado("f1.transformacion.antes_despues",
      shiny::tagList(
        shiny::plotOutput(ns("antes_despues"), height = "320px"),
        shiny::tags$h6(class = "mt-3", "Pila aplicada"),
        shiny::tableOutput(ns("pila"))),
      contexto = salida_contexto(ns, "contexto_tr")),
    panel_resultado("f1.transformacion.perfil_boxcox",
      shiny::plotOutput(ns("perfil"), height = "280px"),
      contexto = salida_contexto(ns, "contexto_boxcox")))
}

servidor_transformacion <- function(input, output, session, datos_base, dataset) {

  aplicar_pila <- function(ds, pila) {
    resultado <- aplicar_transformaciones(datos_base(), pila)
    ds$df <- resultado$datos
    ds$transformaciones <- pila
    ds$diccionario <- diccionario_inicial(resultado$datos)
    ds$n <- nrow(resultado$datos)
    ds$p <- ncol(resultado$datos)
    output$avisos_tr <- shiny::renderUI(lista_avisos(resultado$avisos))
    ds
  }

  shiny::observeEvent(input$aplicar_tr, {
    ds <- dataset()
    shiny::req(ds, input$columnas_tr, !is.null(datos_base()))
    # Lambda solo viaja cuando el tipo la usa: si no, ensucia la pila con un
    # parámetro que no significa nada para esa transformación.
    params <- if (identical(input$tipo_tr, "boxcox"))
      list(lambda = input$lambda %||% 0) else list()
    pila <- agregar_transformacion(ds$transformaciones, input$tipo_tr,
                                   input$columnas_tr, params)
    dataset(aplicar_pila(ds, pila))
  })

  shiny::observeEvent(input$deshacer_tr, {
    ds <- dataset()
    shiny::req(ds, length(ds$transformaciones) > 0)
    dataset(aplicar_pila(ds, quitar_transformacion(ds$transformaciones)))
  })

  output$antes_despues <- shiny::renderPlot({
    ds <- dataset()
    crudos <- datos_base()
    shiny::req(ds, crudos)
    columna <- (input$columnas_tr %||% names(ds$df))[1]
    shiny::validate(shiny::need(columna %in% names(ds$df) &&
                                  columna %in% names(crudos),
                                "Esa columna ya no existe tras la pila."))
    graficar_antes_despues(crudos, ds$df, columna)
  })

  output$pila <- shiny::renderTable({
    ds <- dataset()
    shiny::req(ds)
    if (!length(ds$transformaciones))
      return(data.frame(paso = integer(0), receta = character(0)))
    data.frame(paso = seq_along(ds$transformaciones),
               receta = vapply(ds$transformaciones, describir_transformacion, ""),
               stringsAsFactors = FALSE)
  })

  output$perfil <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$columna_perfil)
    graficar_perfil_boxcox(perfil_boxcox(as.numeric(ds$df[[input$columna_perfil]])))
  })

  dibujar_contexto(output, "f1.transformacion.antes_despues",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     list(pila = length(ds$transformaciones),
                          ultima = if (length(ds$transformaciones))
                            describir_transformacion(
                              ds$transformaciones[[length(ds$transformaciones)]])
                          else "ninguna")
                   }), sufijo = "contexto_tr")

  dibujar_contexto(output, "f1.transformacion.perfil_boxcox",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds) || is.null(input$columna_perfil)) return(NULL)
                     perfil <- perfil_boxcox(as.numeric(ds$df[[input$columna_perfil]]))
                     list(columna = input$columna_perfil, lambda = perfil$optimo,
                          redondeado = perfil$redondeado)
                   }), sufijo = "contexto_boxcox")
}
