# learn/R/ui/f1/balanceo.R
#
# Responsabilidad: subsección Balanceo — mirar y corregir el desbalance.
#
# Las tres técnicas remuestrean filas existentes; ninguna inventa datos. Lo que
# se remuestrea queda marcado en la nube, porque un sobre-muestreo que no se ve
# parece haber conseguido información nueva.

controles_balanceo <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("clase_bal"), "Columna de clase",
                       choices = character(0)),
    shiny::radioButtons(ns("metodo_bal"), "Tecnica",
                        choices = c("Sub-muestreo" = "submuestreo",
                                    "Sobre-muestreo" = "sobremuestreo",
                                    "Bootstrap" = "bootstrap"),
                        selected = "submuestreo"),
    shiny::numericInput(ns("semilla_bal"), "Semilla", value = 42, min = 1),
    shiny::actionButton(ns("balancear"), "Balancear", class = "btn-primary w-100"),
    shiny::tags$hr(),
    shiny::selectInput(ns("x_bal"), "Eje X de la nube", choices = character(0)),
    shiny::selectInput(ns("y_bal"), "Eje Y de la nube", choices = character(0)))
}

actualizar_balanceo <- function(session, ds, previos = list()) {
  categoricas <- ds$diccionario$columna[ds$diccionario$clase != "continua"]
  numericas <- columnas_numericas(ds)
  .rellenar_selector(session, "clase_bal", categoricas, previos$clase_bal)
  .rellenar_selector(session, "x_bal", numericas, previos$x_bal)
  .rellenar_selector(session, "y_bal", numericas,
                     previos$y_bal %||% numericas[min(2L, length(numericas))])
}

salida_balanceo <- function(ns) {
  shiny::tagList(
    shiny::uiOutput(ns("avisos_bal")),
    panel_resultado("f1.balanceo.frecuencias",
      shiny::tagList(
        shiny::plotOutput(ns("frecuencias"), height = "280px"),
        shiny::tableOutput(ns("pesos"))),
      contexto = salida_contexto(ns, "contexto_bal")),
    panel_resultado("f1.balanceo.nube_sinteticos",
      shiny::plotOutput(ns("nube"), height = "320px"),
      contexto = salida_contexto(ns, "contexto_nube"),
      encabezado_extra = shiny::uiOutput(ns("badge_bal"), inline = TRUE)))
}

servidor_balanceo <- function(input, output, session, dataset, muestreo) {
  ns <- session$ns
  ultimo <- shiny::reactiveVal(NULL)

  shiny::observeEvent(input$balancear, {
    ds <- dataset()
    shiny::req(ds, input$clase_bal)
    resultado <- tryCatch(
      balancear(ds$df, input$clase_bal, input$metodo_bal %||% "submuestreo",
                input$semilla_bal %||% 42L),
      error = function(e) list(error = conditionMessage(e)))
    if (!is.null(resultado$error)) {
      output$avisos_bal <- shiny::renderUI(lista_avisos(list(list(
        severidad = "error", mensaje = resultado$error,
        sugerencia = NA_character_))))
      return(invisible(NULL))
    }
    ultimo(resultado)
    ds$df <- resultado$datos
    ds$n <- nrow(resultado$datos)
    ds$balanceo <- list(metodo = resultado$metodo, columna = input$clase_bal,
                        semilla = resultado$semilla)
    ds$particion <- NULL          # las filas cambiaron: la particion ya no vale
    dataset(ds)
    output$avisos_bal <- shiny::renderUI(lista_avisos(list(list(
      severidad = "aviso",
      mensaje = sprintf("Se rebalanceo por %s con %s: ahora hay %d filas.",
                        input$clase_bal, resultado$metodo, nrow(resultado$datos)),
      sugerencia = paste("Las probabilidades a priori cambiaron; la particion",
                         "se limpio porque las filas ya no son las mismas.")))))
  })

  output$frecuencias <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$clase_bal)
    previo <- ultimo()
    if (!is.null(previo)) graficar_balance(previo$antes, previo$despues)
    else graficar_balance(resumir_balance(ds$df, input$clase_bal))
  })

  output$pesos <- shiny::renderTable({
    ds <- dataset()
    shiny::req(ds, input$clase_bal)
    pesos <- pesos_clase(ds$df, input$clase_bal)
    data.frame(clase = names(pesos), peso = as.numeric(pesos),
               stringsAsFactors = FALSE)
  })

  output$nube <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$x_bal, input$y_bal)
    previo <- ultimo()
    origen <- if (is.null(previo)) rep("original", nrow(ds$df)) else previo$origen
    shiny::validate(shiny::need(length(origen) == nrow(ds$df),
                                "El dataset cambio despues de balancear."))
    graficar_nube_sinteticos(ds$df, input$x_bal, input$y_bal, origen,
                             grupo = input$clase_bal)
  })

  output$badge_bal <- shiny::renderUI(.badge_de_muestreo(ns, muestreo()))

  dibujar_contexto(output, "f1.balanceo.frecuencias",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds) || is.null(input$clase_bal)) return(NULL)
                     balance <- resumir_balance(ds$df, input$clase_bal)
                     list(columna = input$clase_bal,
                          clases = nrow(balance),
                          razon = round(attr(balance, "razon") %||% NA_real_, 2),
                          metodo = ds$balanceo$metodo %||% "ninguno")
                   }), sufijo = "contexto_bal")

  dibujar_contexto(output, "f1.balanceo.nube_sinteticos",
                   params = shiny::reactive({
                     previo <- ultimo()
                     if (is.null(previo)) return(NULL)
                     list(metodo = previo$metodo, semilla = previo$semilla,
                          remuestreadas = sum(previo$origen == "remuestreada"))
                   }), sufijo = "contexto_nube")
}
