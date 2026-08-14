# libs/shiny-live/R/mod_anova.R
#
# Módulo principal del tab "ANOVA". Barra lateral con todos los inputs
# (selector de dataset + conditionalPanel por dataset) y panel principal con
# value boxes (F, p, n) + boxplot con brush para excluir outliers.
#
# Devuelve un list de reactives (el "estado") que consumen los otros módulos:
#   datos     -> reactive df (post-exclusión de outliers)
#   resultado -> reactive list (salida de correr_anova)
#   params    -> reactive list (inputs actuales, para mod_potencia)
#
# Showcase: page_sidebar, sidebar, value_box, layout_columns, accordion,
# conditionalPanel, radioButtons, selectInput, sliderInput, numericInput,
# checkboxInput, checkboxGroupInput, actionButton, downloadButton, reactive,
# reactiveVal, observeEvent, brushedPoints, showNotification.

mod_anova_ui <- function(id) {
  ns <- NS(id)
  page_sidebar(
    sidebar = sidebar(
      width = 330, title = "Parámetros",
      accordion(
        open = c("datos"), id = ns("acordeon"),
        accordion_panel(
          "Datos", value = "datos",
          radioButtons(ns("dataset"), "Dataset",
                       choices = c("Twins (salario/educación)" = "twins",
                                   "Charcoal (producción/región)" = "charcoal",
                                   "Sintético" = "sintetico"),
                       selected = "twins"),
          # OJO: con `ns = ns` la condición usa el id SIN namespace; poner
          # ns("dataset") genera `input.anova-dataset`, que JS lee como una
          # resta y rompe el panel (ReferenceError: dataset is not defined).
          conditionalPanel(
            condition = "input.dataset == 'charcoal'", ns = ns,
            # Poblado en la UI (ver flujos_charcoal en datos.R): con
            # choices = NULL + updateSelectInput el select quedaba vacío en
            # webR y datos_anova() filtraba por flujo = "" -> 0 filas.
            selectInput(ns("flujo"), "Flujo (charcoal)",
                        choices = flujos_charcoal(), selected = "Production"),
            sliderInput(ns("anio"), "Año (charcoal)",
                        min = 1990, max = 2020, value = 2019, step = 1, sep = "")
          ),
          conditionalPanel(
            condition = "input.dataset == 'sintetico'", ns = ns,
            sliderInput(ns("k_grupos"), "Número de grupos", min = 2, max = 8, value = 4, step = 1),
            sliderInput(ns("n"), "Observaciones por grupo", min = 5, max = 200, value = 30, step = 5),
            sliderInput(ns("efecto"), "Tamaño del efecto", min = 0, max = 20, value = 5, step = 1),
            sliderInput(ns("ruido"), "Ruido (sd)", min = 0.1, max = 5, value = 1, step = 0.1),
            checkboxInput(ns("balanceado"), "Balanceado", value = TRUE)
          ),
          numericInput(ns("semilla"), "Semilla", value = 42, min = 1, step = 1),
          actionButton(ns("regenerar"), "Regenerar", class = "btn-primary w-100")
        ),
        accordion_panel(
          "Boxplot", value = "box",
          checkboxGroupInput(ns("opts_box"), "Opciones",
                             choices = c("Jitter" = "jitter",
                                         "Marcar media" = "media",
                                         "Notches" = "notch"),
                             selected = c("jitter", "media"), inline = TRUE),
          actionButton(ns("limpiar"), "Limpiar selección (brush)", class = "btn-outline-secondary w-100")
        )
      ),
      tags$hr(),
      downloadButton(ns("descargar"), "Descargar datos (.csv)",
                     class = "btn-success w-100")
    ),

    layout_column_wrap(
      width = 1/3, cell_heights = "100px",
      value_box("F (estadístico)", textOutput(NS(id, "vb_F")),
                theme = "primary", showcase = bsicons::bs_icon("calculator")),
      value_box("p-value", textOutput(NS(id, "vb_p")),
                theme = "success", showcase = bsicons::bs_icon("check2-circle")),
      value_box("Observaciones", textOutput(NS(id, "vb_n")),
                theme = "info", showcase = bsicons::bs_icon("bar-chart"))
    ),
    layout_columns(
      col_widths = 12,
      card(full_screen = TRUE,
           card_header(class = "bg-dark", "Boxplot por grupo — arrastra para excluir outliers"),
           card_body(plotOutput(ns("boxplot"), height = "420px",
                                brush = brushOpts(ns("brush"), direction = "y", resetOnNew = TRUE),
                                dblclick = ns("dblclick"))))
    )
  )
}

mod_anova_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Los flujos de charcoal se poblan en la UI (flujos_charcoal(), datos.R);
    # aquí solo se garantiza que _comun esté cargado antes del primer reactivo.
    tryCatch(bootstrap_comun(), error = function(e) NULL)

    # --- Filtro de outliers (rango de valor a conservar) -----------------
    filtro <- reactiveVal(NULL)  # NULL = sin filtro; c(lo, hi) = rango a MANTENER

    # --- Datos crudos (reaccionan a todos los inputs + botón regenerar) --
    # df vacío pero con la forma esperada: req() lo deja pasar y el flujo
    # degrada al mensaje "muy pocos datos" en vez de romper el reactivo (y
    # dejar colgado el modal de carga de webR).
    .vacio <- data.frame(valor = numeric(0), grupo = factor(), id = integer(0))

    datos_raw <- reactive({
      input$regenerar
      d <- tryCatch(
        datos_anova(dataset = input$dataset, flujo = input$flujo,
                    anio = input$anio, k_grupos = input$k_grupos,
                    n_por_grupo = input$n, efecto = input$efecto,
                    ruido = input$ruido, semilla = input$semilla,
                    balanceado = input$balanceado),
        error = function(e) {
          showNotification(paste("No se pudo cargar el dataset:",
                                 conditionMessage(e)),
                           type = "error", duration = 8)
          .vacio
        })
      if (nrow(d) == 0) return(.vacio)
      d$id <- seq_len(nrow(d)); d
    })

    # Reset del filtro cuando cambian dataset/parámetros
    observeEvent(input$dataset, filtro(NULL), ignoreInit = TRUE)
    observeEvent(input$regenerar, filtro(NULL), ignoreInit = TRUE)

    # --- Datos efectivos (post-exclusión) --------------------------------
    datos_efectivos <- reactive({
      d <- req(datos_raw())
      if (nrow(d) == 0) return(d)
      if (is.null(filtro())) return(d)
      d[d$valor >= filtro()[1] & d$valor <= filtro()[2], ]
    })

    resultado <- reactive({
      d <- req(datos_efectivos())
      if (nrow(d) < 3 || length(unique(d$grupo)) < 2)
        return(list(error = "Muy pocos datos o <2 grupos tras la exclusión."))
      tryCatch(correr_anova(d, semilla = input$semilla),
               error = function(e) list(error = conditionMessage(e)))
    })

    # --- Brush → filtro (rango a conservar) ------------------------------
    observeEvent(input$brush, {
      br <- input$brush
      if (is.null(br)) return()
      filtro(c(br$ymin, br$ymax))
      showNotification(sprintf("Manteniendo valores en [%.2f, %.2f]",
                               br$ymin, br$ymax), type = "message", duration = 2)
    })
    observeEvent(input$dblclick, { filtro(NULL); showNotification("Filtro limpiado.", type = "message", duration = 2) })
    observeEvent(input$limpiar,  filtro(NULL))

    # --- Regenerar → nueva semilla aleatoria -----------------------------
    observeEvent(input$regenerar, {
      updateNumericInput(session, "semilla", value = sample.int(1e6, 1))
    }, ignoreInit = TRUE)

    # --- Value boxes -----------------------------------------------------
    output$vb_F <- renderText({ r <- resultado(); if (!is.null(r$error)) "—" else sprintf("%.2f", r$F) })
    output$vb_p <- renderText({ r <- resultado(); if (!is.null(r$error)) "—" else sprintf("%.4g", r$p) })
    output$vb_n <- renderText({ r <- resultado(); if (!is.null(r$error)) "0" else as.character(r$n) })

    # --- Boxplot ---------------------------------------------------------
    output$boxplot <- renderPlot({
      r <- req(resultado())
      if (!is.null(r$error)) return(NULL)
      d <- r$datos
      k <- length(levels(d$grupo))
      mostrar <- input$opts_box
      p <- ggplot2::ggplot(d, ggplot2::aes(.data$grupo, .data$valor, fill = .data$grupo)) +
        ggplot2::geom_boxplot(
          outlier.shape = NA, alpha = 0.5,
          notch = "notch" %in% mostrar) +
        { if ("jitter" %in% mostrar) ggplot2::geom_jitter(width = 0.18, alpha = 0.4, size = 1.5) else NULL } +
        { if ("media" %in% mostrar)
          ggplot2::stat_summary(fun = mean, geom = "point", shape = 23, size = 3.2,
                                fill = "white", color = "black") else NULL } +
        ggplot2::labs(title = "Boxplot por grupo",
                      subtitle = sprintf("F = %.2f, p = %.4g (n = %d)", r$F, r$p, r$n),
                      x = "Grupo", y = "Valor") +
        scale_fill_cat(k) + tema_ggplot() +
        ggplot2::theme(legend.position = "none",
                       axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))
      p
    })

    # --- Descargar datos efectivos --------------------------------------
    output$descargar <- downloadHandler(
      filename = function() sprintf("anova-%s-%s.csv", input$dataset, format(Sys.Date(), "%Y%m%d")),
      content = function(file) {
        d <- req(datos_efectivos())
        utils::write.csv(d[, c("valor", "grupo")], file, row.names = FALSE)
      }
    )

    # --- Estado exportado (lo consumen los otros módulos) ----------------
    list(
      datos     = datos_efectivos,
      datos_raw = datos_raw,
      resultado = resultado,
      filtro    = filtro,
      params    = reactive(list(dataset = input$dataset, semilla = input$semilla,
                                k_grupos = input$k_grupos, ruido = input$ruido,
                                efecto = input$efecto))
    )
  })
}
