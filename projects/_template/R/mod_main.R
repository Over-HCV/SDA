# projects/__SLUG__/R/mod_main.R
#
# Modulo principal. Solo cablea inputs -> modelo.R. Cero estadistica aca.
#
# TODO: el input mas importante es el "hook" de tu tema — el control que hace
# que el metodo se entienda al moverlo (ver la columna "Reactive hook" de tu
# fila en libs/topics-map.md). Ejemplos:
#   LASSO   -> slider log(lambda)      DBSCAN -> sliders eps + minPts
#   t-SNE   -> slider perplexity       PCA    -> slider n componentes
#   k-means -> slider k                quantreg -> slider tau

mod_main_ui <- function(id) {
  ns <- NS(id)

  page_sidebar(
    sidebar = sidebar(
      width = 320, title = "Controles",

      # --- El hook del tema ---------------------------------------------
      sliderInput(ns("grado"), "Grado del polinomio",
                  min = 1, max = 10, value = 2, step = 1),
      helpText("TODO: reemplazar por el hook de tu tema."),

      accordion(
        open = FALSE,
        accordion_panel(
          "Datos", icon = bsicons::bs_icon("database"),
          sliderInput(ns("n"), "Tamano de muestra",
                      min = 20, max = 400, value = 120, step = 20),
          sliderInput(ns("ruido"), "Ruido (sd)",
                      min = 0, max = 5, value = 1, step = 0.1),
          numericInput(ns("semilla"), "Semilla", value = 42, min = 1, step = 1)
        )
      ),

      hr(),
      actionButton(ns("guardar"), "Guardar corrida",
                   icon = icon("floppy-disk"), class = "btn-primary"),
      helpText("Escribe outputs/*.{png,json,csv} + run_log.csv (contrato S2).")
    ),

    # --- Cuerpo ----------------------------------------------------------
    layout_columns(
      col_widths = c(4, 4, 4),
      value_box("R cuadrado", textOutput(ns("vb_r2")),
                showcase = bsicons::bs_icon("graph-up"), theme = "primary"),
      value_box("RMSE", textOutput(ns("vb_rmse")),
                showcase = bsicons::bs_icon("rulers"), theme = "success"),
      value_box("n", textOutput(ns("vb_n")),
                showcase = bsicons::bs_icon("hash"), theme = "info")
    ),

    br(),

    navset_card_tab(
      full_screen = TRUE,
      nav_panel("Principal",
                plotOutput(ns("principal"), height = "440px",
                           brush = brushOpts(ns("brush")))),
      nav_panel("Secundario",
                plotOutput(ns("secundario"), height = "440px")),
      nav_panel("Resultados",
                DT::dataTableOutput(ns("tabla"))),
      nav_panel("Datos",
                DT::dataTableOutput(ns("tabla_datos")))
    )
  )
}

mod_main_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    datos <- reactive({
      datos_proyecto(n = input$n, ruido = input$ruido,
                     semilla = input$semilla)
    })

    # tryCatch + validate: un error del modelo se MUESTRA, no tumba la sesion.
    ajuste <- reactive({
      req(datos())
      validate(need(input$grado < nrow(datos()) - 1,
                    "El grado debe ser menor que n - 1."))
      tryCatch(
        ajustar(datos(), grado = input$grado, semilla = input$semilla),
        error = function(e) list(error = conditionMessage(e))
      )
    })

    ok <- reactive({
      a <- ajuste()
      !is.null(a) && is.null(a$error)
    })

    output$vb_r2   <- renderText(if (ok()) sprintf("%.4f", ajuste()$r2) else "—")
    output$vb_rmse <- renderText(if (ok()) sprintf("%.3f", ajuste()$rmse) else "—")
    output$vb_n    <- renderText(if (ok()) as.character(ajuste()$n) else "—")

    output$principal <- renderPlot({
      validate(need(ok(), ajuste()$error %||% "Sin ajuste."))
      graficar_principal(ajuste())
    })

    output$secundario <- renderPlot({
      validate(need(ok(), ajuste()$error %||% "Sin ajuste."))
      graficar_secundario(ajuste())
    })

    output$tabla <- DT::renderDataTable({
      req(ok())
      tab <- DT::datatable(tabla_resultados(ajuste()),
                           options = list(dom = "t"), rownames = FALSE)
      # OJO: R no hace aplicacion parcial. formatRound necesita la tabla como
      # PRIMER argumento; no se puede pipear un `if` que devuelva la funcion.
      DT::formatRound(tab, "estimado", 5)
    })

    output$tabla_datos <- DT::renderDataTable({
      d <- req(datos())
      br <- input$brush
      if (!is.null(br)) d <- brushedPoints(d, br, xvar = "x", yvar = "y")
      DT::datatable(d, options = list(pageLength = 12), filter = "top",
                    rownames = FALSE)
    })

    observeEvent(input$guardar, {
      req(ok())
      withProgress(message = "Escribiendo artefactos", value = 0.4, {
        correr(sprintf("app-g%d-n%d", input$grado, input$n),
               n = input$n, ruido = input$ruido,
               grado = input$grado, semilla = input$semilla)
        incProgress(0.6)
      })
      showNotification("Corrida guardada en outputs/", type = "message")
    })
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a
