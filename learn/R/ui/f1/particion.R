# learn/R/ui/f1/particion.R
#
# Responsabilidad: subsección Partición — repartir las filas con semilla.
#
# La partición no copia datos: se guarda el vector de asignación y la semilla
# dentro del Dataset. Con eso, la misma partición se reconstruye desde el JSON
# de la corrida o desde Rscript, sin la app.

controles_particion <- function(ns) {
  shiny::tagList(
    shiny::radioButtons(ns("tipo_part"), "Tipo",
                        choices = c("Holdout (train/test)" = "holdout",
                                    "Validacion cruzada k-fold" = "kfold"),
                        selected = "holdout"),
    shiny::conditionalPanel(
      "input.tipo_part == 'holdout'", ns = ns,
      shiny::sliderInput(ns("proporcion"), "Proporcion de entrenamiento",
                         0.5, 0.9, 0.7, step = 0.05)),
    shiny::conditionalPanel(
      "input.tipo_part == 'kfold'", ns = ns,
      shiny::sliderInput(ns("k_pliegues"), "Pliegues (k-fold)", 2, 10, 5)),
    shiny::selectInput(ns("estrato"), "Estratificar por",
                       choices = c("ninguna" = "")),
    shiny::numericInput(ns("semilla_part"), "Semilla", value = 42, min = 1),
    shiny::actionButton(ns("partir"), "Partir", class = "btn-primary w-100"),
    shiny::actionButton(ns("quitar_particion"), "Quitar particion",
                        class = "btn-outline-secondary btn-sm w-100 mt-2"))
}

#' Solo se puede estratificar por algo que tenga niveles, no por una continua.
actualizar_particion <- function(session, ds, previos = list()) {
  categoricas <- ds$diccionario$columna[ds$diccionario$clase != "continua"]
  previo <- previos$estrato
  shiny::updateSelectInput(
    session, "estrato", choices = c("ninguna" = "", categoricas),
    selected = if (!is.null(previo) && previo %in% categoricas) previo else "")
}

salida_particion <- function(ns) {
  shiny::tagList(
    panel_resultado("f1.particion.tamanos",
      shiny::tagList(
        shiny::plotOutput(ns("tamanos"), height = "160px"),
        shiny::uiOutput(ns("resumen_part"))),
      contexto = salida_contexto(ns, "contexto_part")),
    panel_resultado("f1.particion.balance",
      shiny::plotOutput(ns("balance_part"), height = "280px"),
      contexto = salida_contexto(ns, "contexto_balance_part")))
}

servidor_particion <- function(input, output, session, dataset) {

  shiny::observeEvent(input$partir, {
    ds <- dataset()
    shiny::req(ds)
    estrato <- if (nzchar(input$estrato %||% "")) input$estrato else NULL
    ds$particion <- particionar(ds$df, tipo = input$tipo_part %||% "holdout",
                                proporcion = input$proporcion %||% 0.7,
                                k = input$k_pliegues %||% 5L,
                                estratificar = estrato,
                                semilla = input$semilla_part %||% 42L)
    dataset(ds)
  })

  shiny::observeEvent(input$quitar_particion, {
    ds <- dataset()
    shiny::req(ds)
    ds$particion <- NULL
    dataset(ds)
  })

  output$tamanos <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds)
    shiny::validate(shiny::need(!is.null(ds$particion),
                                "Todavia no hay particion: elegi el tipo y parti."))
    graficar_particion(resumir_particion(ds$particion))
  })

  output$resumen_part <- shiny::renderUI({
    ds <- dataset()
    shiny::req(ds, ds$particion)
    particion <- ds$particion
    shiny::tags$p(class = "small text-muted mb-0", sprintf(
      "%s · semilla %s · estratificada por %s", particion$tipo,
      particion$semilla,
      if (is.na(particion$estratificar)) "nada" else particion$estratificar))
  })

  output$balance_part <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds)
    shiny::validate(shiny::need(!is.null(ds$particion), "Falta particionar."))
    columna <- if (!is.na(ds$particion$estratificar)) ds$particion$estratificar
               else .primera_categorica(ds)
    shiny::validate(shiny::need(!is.null(columna),
                                "No hay ninguna columna categorica que comparar."))
    graficar_balance_particion(balance_por_particion(ds$df, ds$particion, columna))
  })

  dibujar_contexto(output, "f1.particion.tamanos",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds) || is.null(ds$particion)) return(NULL)
                     tamanos <- resumir_particion(ds$particion)
                     c(list(tipo = ds$particion$tipo,
                            semilla = ds$particion$semilla),
                       stats::setNames(as.list(tamanos$n), tamanos$parte))
                   }), sufijo = "contexto_part")

  dibujar_contexto(output, "f1.particion.balance",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds) || is.null(ds$particion)) return(NULL)
                     list(estratificada = ds$particion$estratificar)
                   }), sufijo = "contexto_balance_part")
}

.primera_categorica <- function(ds) {
  candidatas <- ds$diccionario$columna[ds$diccionario$clase == "cualitativa"]
  if (!length(candidatas)) return(NULL)
  candidatas[1]
}
