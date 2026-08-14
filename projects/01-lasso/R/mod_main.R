# projects/01-lasso/R/mod_main.R
#
# Modulo principal del proyecto LASSO. Solo cablea inputs -> modelo.R.
# Cero estadistica aca dentro.
#
# El hook pedagogico del tema es el slider de lambda: al subirlo, los
# coeficientes se anulan EN VIVO y el contador de activos baja. Es el
# equivalente al slider de grado del Proyecto 1.
#
# Detalle de diseno: el slider trabaja en log10(lambda), no en lambda. La
# grilla de glmnet es logaritmica, asi que un slider lineal dejaria el 90%
# del recorrido en valores que no cambian nada.

LOG_LAMBDA_MIN <- -4
LOG_LAMBDA_MAX <- 0.5

mod_main_ui <- function(id) {
  ns <- NS(id)

  page_sidebar(
    sidebar = sidebar(
      width = 340, title = "Controles",

      selectInput(ns("y_var"), "Variable respuesta",
                  choices = etiquetas_vars(), selected = "DLHRWAGE"),

      accordion(
        open = "Regularizacion",

        accordion_panel(
          "Regularizacion", icon = bsicons::bs_icon("sliders"),

          sliderInput(ns("log_lambda"),
                      "log10(lambda) — penalizacion",
                      min = LOG_LAMBDA_MIN, max = LOG_LAMBDA_MAX,
                      value = -1.1, step = 0.02),
          div(
            class = "d-flex gap-2 mb-2",
            actionButton(ns("ir_min"), "lambda.min", class = "btn-sm btn-primary"),
            actionButton(ns("ir_1se"), "lambda.1se", class = "btn-sm btn-success")
          ),
          helpText("Subi lambda y mira como se apagan los coeficientes."),

          sliderInput(ns("alpha"), "alpha (1 = LASSO, 0 = ridge)",
                      min = 0, max = 1, value = 1, step = 0.05),
          helpText("Entre 0 y 1 es elastic net. Ridge nunca anula del todo.")
        ),

        accordion_panel(
          "Predictores", icon = bsicons::bs_icon("list-check"),
          checkboxGroupInput(ns("x_vars"), NULL,
                             choices  = etiquetas_vars(LASSO_X_DEFECTO),
                             selected = LASSO_X_DEFECTO),
          div(
            class = "d-flex gap-2",
            actionButton(ns("todos"), "Todos", class = "btn-sm"),
            actionButton(ns("ninguno"), "Ninguno", class = "btn-sm")
          )
        ),

        accordion_panel(
          "Validacion cruzada", icon = bsicons::bs_icon("shuffle"),
          sliderInput(ns("nfolds"), "Folds", min = 3, max = 20, value = 10,
                      step = 1),
          numericInput(ns("semilla"), "Semilla", value = 42, min = 1, step = 1),
          checkboxInput(ns("estandarizar"), "Estandarizar predictores", TRUE)
        )
      ),

      hr(),
      actionButton(ns("guardar"), "Guardar corrida",
                   icon = icon("floppy-disk"), class = "btn-primary"),
      helpText("Escribe outputs/*.{png,json,csv} + run_log.csv (contrato S2).")
    ),

    # --- Cuerpo -----------------------------------------------------------
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box("Predictores activos", textOutput(ns("vb_activos")),
                showcase = bsicons::bs_icon("funnel"), theme = "primary"),
      value_box("lambda", textOutput(ns("vb_lambda")),
                showcase = bsicons::bs_icon("sliders"), theme = "secondary"),
      value_box("MSE de CV", textOutput(ns("vb_cv")),
                showcase = bsicons::bs_icon("shuffle"), theme = "success"),
      value_box("n usados", textOutput(ns("vb_n")),
                showcase = bsicons::bs_icon("hash"), theme = "info")
    ),

    br(),

    navset_card_tab(
      full_screen = TRUE,

      nav_panel(
        "Camino de coeficientes",
        card_body(
          plotOutput(ns("camino"), height = "430px",
                     brush = brushOpts(ns("brush_camino"), direction = "x")),
          helpText("Arrastra en horizontal para inspeccionar un rango de lambda.")
        ),
        DT::dataTableOutput(ns("tabla_brush"))
      ),

      nav_panel("Validacion cruzada",
                plotOutput(ns("cv"), height = "460px")),

      nav_panel("Observado vs predicho",
                plotOutput(ns("ajuste"), height = "460px")),

      nav_panel("Coeficientes",
                card_body(
                  checkboxInput(ns("solo_activos"), "Mostrar solo activos", FALSE),
                  DT::dataTableOutput(ns("tabla_coefs"))
                )),

      nav_panel("Diagnostico de datos",
                card_body(verbatimTextOutput(ns("diag"))))
    )
  )
}

mod_main_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    df <- datos_lasso()

    # El slider de lambda se mueve mucho; sin debounce se dispara un
    # cv.glmnet por cada paso intermedio.
    log_lambda_d <- debounce(reactive(input$log_lambda), 250)

    # --- Ajuste -----------------------------------------------------------
    ajuste <- reactive({
      req(input$x_vars, input$y_var)
      validate(
        need(length(input$x_vars) >= 2,
             "Selecciona al menos 2 predictores."),
        need(!(input$y_var %in% input$x_vars),
             "La respuesta no puede estar tambien entre los predictores."),
        need(n_completos(df, input$y_var, input$x_vars) >= 20,
             "Muy pocos casos completos con esa combinacion de columnas.")
      )

      tryCatch(
        correr_lasso(df,
                      y_var  = input$y_var,
                      x_vars = input$x_vars,
                      alpha  = input$alpha,
                      lambda = 10^log_lambda_d(),
                      nfolds = input$nfolds,
                      semilla = input$semilla,
                      estandarizar = isTRUE(input$estandarizar)),
        error = function(e) list(error = conditionMessage(e))
      )
    })

    ok <- reactive({
      a <- ajuste()
      !is.null(a) && is.null(a$error)
    })

    # --- Value boxes ------------------------------------------------------
    output$vb_activos <- renderText({
      if (!ok()) return("—")
      sprintf("%d de %d", ajuste()$no_cero, ajuste()$p)
    })
    output$vb_lambda <- renderText({
      if (!ok()) return("—"); sprintf("%.4f", ajuste()$lambda)
    })
    output$vb_cv <- renderText({
      if (!ok()) return("—"); sprintf("%.4f", ajuste()$cv_error)
    })
    output$vb_n <- renderText({
      if (!ok()) return("—"); as.character(ajuste()$n)
    })

    # --- Botones que saltan al lambda optimo del CV -----------------------
    observeEvent(input$ir_min, {
      if (ok()) updateSliderInput(session, "log_lambda",
                                  value = log10(ajuste()$lambda_min))
    })
    observeEvent(input$ir_1se, {
      if (ok()) updateSliderInput(session, "log_lambda",
                                  value = log10(ajuste()$lambda_1se))
    })

    observeEvent(input$todos,
                 updateCheckboxGroupInput(session, "x_vars",
                                          selected = LASSO_X_DEFECTO))
    observeEvent(input$ninguno,
                 updateCheckboxGroupInput(session, "x_vars", selected = character(0)))

    # --- Plots ------------------------------------------------------------
    output$camino <- renderPlot({
      validate(need(ok(), ajuste()$error %||% "Sin ajuste."))
      graficar_camino(ajuste())
    })

    output$cv <- renderPlot({
      validate(need(ok(), ajuste()$error %||% "Sin ajuste."))
      graficar_cv(ajuste())
    })

    output$ajuste <- renderPlot({
      validate(need(ok(), ajuste()$error %||% "Sin ajuste."))
      graficar_ajuste(ajuste())
    })

    # --- Tablas -----------------------------------------------------------
    output$tabla_coefs <- DT::renderDataTable({
      req(ok())
      d <- tabla_coefs(ajuste(), incluir_ceros = !isTRUE(input$solo_activos))
      tab <- DT::datatable(d, options = list(pageLength = 15, dom = "tp"),
                           rownames = FALSE)
      DT::formatRound(tab, "coef", 5)
    })

    # Que variables siguen vivas en el rango de lambda que marcaste con brush.
    output$tabla_brush <- DT::renderDataTable({
      req(ok())
      br <- input$brush_camino
      if (is.null(br)) return(NULL)

      a <- ajuste()
      beta <- as.matrix(a$fit$beta)
      lam  <- a$fit$lambda
      dentro <- which(log(lam) >= br$xmin & log(lam) <= br$xmax)
      if (!length(dentro)) return(NULL)

      sub <- beta[, dentro, drop = FALSE]
      d <- data.frame(
        variable   = rownames(sub),
        coef_max   = apply(sub, 1, function(v) v[which.max(abs(v))]),
        veces_no_cero = rowSums(sub != 0),
        de_lambdas = ncol(sub),
        stringsAsFactors = FALSE
      )
      d <- d[order(-abs(d$coef_max)), ]
      DT::datatable(d, options = list(pageLength = 8, dom = "tp"),
                    rownames = FALSE,
                    caption = sprintf("Rango log(lambda) [%.2f, %.2f]",
                                      br$xmin, br$xmax)) |>
        DT::formatRound("coef_max", 5)
    })

    output$diag <- renderPrint({
      cols <- c(input$y_var, input$x_vars)
      cat("Filas totales en twins.csv :", nrow(df), "\n")
      cat("Columnas seleccionadas     :", length(cols), "\n")
      cat("Casos completos usables    :", n_completos(df, input$y_var, input$x_vars), "\n\n")
      cat("NA por columna seleccionada:\n")
      print(colSums(is.na(df[, intersect(cols, names(df)), drop = FALSE])))
      if (ok() && length(ajuste()$descartados)) {
        cat("\nDescartadas por varianza cero: ",
            paste(ajuste()$descartados, collapse = ", "), "\n")
      }
    })

    # --- Guardar (contrato S2) --------------------------------------------
    observeEvent(input$guardar, {
      req(ok())
      withProgress(message = "Escribiendo artefactos", value = 0.4, {
        esc <- sprintf("app-a%02d-l%s",
                       round(input$alpha * 100),
                       gsub("[.-]", "", sprintf("%.2f", log_lambda_d())))
        correr(esc,
               y_var  = input$y_var,
               x_vars = input$x_vars,
               alpha  = input$alpha,
               lambda = 10^log_lambda_d(),
               nfolds = input$nfolds,
               semilla = input$semilla,
               estandarizar = isTRUE(input$estandarizar))
        incProgress(0.6)
      })
      showNotification("Corrida guardada en outputs/", type = "message")
    })
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a
