# libs/shiny/R/mod_ajuste.R
#
# Módulo principal del tab "Ajuste". Contiene la barra lateral con todos
# los inputs y el plot principal con brush. Devuelve un reactiveValues
# con: datos(), ajuste(), brush() para que los otros módulos consuman.
#
# Showcase UI/reactividad:
#   - page_sidebar, sidebarPanel, layout_columns, layout_column_wrap
#   - value_box (R², RMSE, n)
#   - selectizeInput, selectInput, sliderInput, sliderInput(range),
#     numericInput, radioButtons, checkboxInput, checkboxGroupInput,
#     fileInput, actionButton, downloadButton
#   - reactive, eventReactive, observeEvent, reactiveVal, debounce
#   - plotOutput con brush + hover + click
#   - conditionalPanel, updateSliderInput, renderUI/uiOutput
#   - showNotification, withProgress

mod_ajuste_ui <- function(id) {
  ns <- NS(id)
  page_sidebar(
    sidebar = sidebar(
      width = 320,
      title = "Parámetros",

      accordion(
        open = c("datos", "modelo"),
        id = ns("acordeon"),
        accordion_panel(
          "Datos", value = "datos",
          selectizeInput(ns("pais"), "País",
                         choices = NULL, selected = "Colombia",
                         options = list(maxItems = 1)),
          selectInput(ns("flujo"), "Flujo", choices = NULL),
          sliderInput(ns("anios"), "Rango de años",
                      min = 1990, max = 2020, value = c(1995, 2020), step = 1),
          fileInput(ns("csv"), "Subir CSV propio (opcional)",
                    accept = ".csv", placeholder = "x,y numéricas"),
          helpText("Sobreescribe la selección de país/flujo.")
        ),
        accordion_panel(
          "Modelo", value = "modelo",
          radioButtons(ns("metodo"), "Método de ajuste",
                       choices = c("lm" = "lm", "loess" = "loess"),
                       selected = "lm", inline = TRUE),
          conditionalPanel(
            # OJO: la condicion va con el id DESNUDO ("metodo"), no con
            # ns("metodo"). Al pasar ns =, conditionalPanel la reescribe solo a
            # input['ajuste-metodo']. Si escribis input.ajuste-metodo, JS lo lee
            # como una RESTA (ajuste - metodo) y tira "metodo is not defined".
            condition = "input.metodo == 'lm'",
            ns = ns,
            sliderInput(ns("grado"), "Grado del polinomio",
                        min = 1, max = 10, value = 3, step = 1)
          ),
          numericInput(ns("semilla"), "Semilla", value = 42, min = 1, step = 1),
          checkboxInput(ns("log_y"), "Escala log en Y", value = FALSE),
          checkboxInput(ns("auto"), "Recálculo automático", value = TRUE)
        )
      ),

      tags$hr(),
      actionButton(ns("refit"), "Refit ahora",
                   class = "btn-primary w-100"),
      tags$span(style = "display:block; height: 6px;"),
      downloadButton(ns("descargar"), "Descargar datos (.csv)",
                     class = "btn-success w-100"),
      tags$span(style = "display:block; height: 6px;"),
      actionButton(ns("guardar"), "Guardar corrida (headless)",
                   class = "btn-outline-secondary w-100")
    ),

    # Main panel: value boxes + plot
    layout_column_wrap(
      width = 1/3, fixed_cell_size = FALSE,
      cell_heights = "100px",
      value_box(
        title = "R²",
        value = textOutput(NS(id, "r2")),
        showcase = bsicons::bs_icon("graph-up"),
        theme = "primary"
      ),
      value_box(
        title = "RMSE",
        value = textOutput(NS(id, "rmse")),
        showcase = bsicons::bs_icon("rulers"),
        theme = "success"
      ),
      value_box(
        title = "Observaciones",
        value = textOutput(NS(id, "nobs")),
        showcase = bsicons::bs_icon("bar-chart"),
        theme = "info"
      )
    ),

    layout_columns(
      col_widths = 12,
      card(
        full_screen = TRUE,
        card_header(class = "bg-dark", "Ajuste interactivo"),
        popover(
          trigger = bsicons::bs_icon("info-circle"),
          "Arrastra sobre el gráfico para seleccionar puntos.",
          placement = "right"
        ),
        card_body(
          plotOutput(ns("plot"), height = "420px",
                     brush = brushOpts(ns("brush"), direction = "x",
                                       resetOnNew = TRUE),
                     click = ns("click"),
                     hover = hoverOpts(ns("hover"), delay = 100)),
          uiOutput(ns("hover_info"))
        )
      )
    )
  )
}

mod_ajuste_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ---- Poblado de selectores ------------------------------------------
    .df_cache <- cargar_charcoal()
    updateSelectizeInput(session, "pais",
                         choices = listar_paises(.df_cache),
                         selected = "Colombia", server = TRUE)
    updateSelectInput(session, "flujo",
                      choices = listar_flujos(.df_cache),
                      selected = "Production")

    # ---- Estado: CSV subido ---------------------------------------------
    csv_usuario <- reactiveVal(NULL)  # NULL = usar charcoal

    observeEvent(input$csv, {
      req(input$csv)
      info <- leer_csv_usuario(input$csv$datapath)
      if (info$ok) {
        csv_usuario(info$datos)
        showNotification(info$msg, type = "message")
      } else {
        csv_usuario(NULL)
        showNotification(info$msg, type = "error")
      }
    })

    # ---- Datos reactivos (con debounce en rango de años) ----------------
    anios_d <- debounce(reactive(input$anios), 200)

    datos <- reactive({
      if (!is.null(csv_usuario())) return(csv_usuario())
      series_pais(pais = input$pais, flujo = input$flujo,
                  anio_min = anios_d()[1], anio_max = anios_d()[2])
    })

    # ---- Constrain grado máximo según n --------------------------------
    observe({
      req(datos())
      n <- nrow(datos())
      max_grado <- max(1, min(10, n - 2))
      updateSliderInput(session, "grado", max = max_grado)
    })

    # ---- Ajuste (reactive o eventReactive según modo) ------------------
    ajuste_auto <- reactive({
      req(datos())
      tryCatch(
        ajustar_modelo(datos(), grado = if (is.null(input$grado)) 3 else input$grado,
                       metodo = input$metodo, semilla = input$semilla),
        error = function(e) list(error = conditionMessage(e))
      )
    })

    ajuste_manual <- eventReactive(input$refit, {
      req(datos())
      withProgress(message = "Refiteando...", value = 1, {
        tryCatch(
          ajustar_modelo(datos(), grado = if (is.null(input$grado)) 3 else input$grado,
                         metodo = input$metodo, semilla = input$semilla),
          error = function(e) list(error = conditionMessage(e))
        )
      })
    })

    ajuste <- reactive({
      if (isTRUE(input$auto)) ajuste_auto() else ajuste_manual()
    })

    # ---- Value boxes ----------------------------------------------------
    output$r2 <- renderText({
      a <- ajuste(); if (!is.null(a$error)) return("—")
      sprintf("%.3f", a$r2)
    })
    output$rmse <- renderText({
      a <- ajuste(); if (!is.null(a$error)) return("—")
      sprintf("%.2f", a$rmse)
    })
    output$nobs <- renderText({
      a <- ajuste(); if (!is.null(a$error)) return("0")
      as.character(a$n)
    })

    # ---- Plot principal -------------------------------------------------
    output$plot <- renderPlot({
      a <- ajuste()
      if (!is.null(a$error)) return(NULL)
      graficar_ajuste(a, log_y = isTRUE(input$log_y))
    })

    # Hover info dinámico
    output$hover_info <- renderUI({
      req(input$hover)
      a <- req(ajuste()); if (!is.null(a$error)) return(NULL)
      d <- a$datos
      idx <- which.min(abs(d$x - input$hover$x))
      if (length(idx) == 0) return(NULL)
      row <- d[idx, ]
      wellPanel(
        style = "background: rgba(255,255,255,0.95); font-size: 12px;",
        tags$b("Año: "), row$x, tags$br(),
        tags$b("Observado: "), sprintf("%.2f", row$y), tags$br(),
        tags$b("Ajustado: "), sprintf("%.2f", a$pred[idx])
      )
    })

    # ---- Descargar datos ajustados -------------------------------------
    output$descargar <- downloadHandler(
      filename = function() sprintf("ajuste-%s.csv", format(Sys.Date(), "%Y%m%d")),
      content = function(file) {
        a <- req(ajuste())
        utils::write.csv(cbind(a$datos, pred = as.numeric(a$pred),
                                resid = as.numeric(a$resid)),
                         file, row.names = FALSE)
      }
    )

    # ---- Guardar corrida headless --------------------------------------
    observeEvent(input$guardar, {
      a <- req(ajuste())
      if (!is.null(a$error)) {
        showNotification("El ajuste actual tiene error.", type = "error"); return()
      }
      esc <- sprintf("ui-%s-%s", input$pais %||% "csv", input$metodo)
      p <- graficar_ajuste(a, log_y = isTRUE(input$log_y))
      escribir_salida(
        proyecto  = "shiny",
        escenario = gsub("[^A-Za-z0-9_.-]", "_", esc),
        params    = list(pais = input$pais, flujo = input$flujo,
                         grado = input$grado, metodo = input$metodo,
                         semilla = input$semilla),
        metricas  = list(r2 = a$r2, rmse = a$rmse, n = a$n),
        plot_obj  = p,
        datos_df  = cbind(a$datos, pred = as.numeric(a$pred)),
        notas     = "Corrida guardada desde la UI"
      )
      showNotification("Guardado en libs/shiny/outputs/", type = "message")
    })

    # ---- Estado exportado (lo consumen los otros módulos) --------------
    list(
      datos    = datos,
      ajuste   = ajuste,
      brush    = reactive(input$brush),
      csv_info = reactive(list(usando_csv = !is.null(csv_usuario())))
    )
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a
