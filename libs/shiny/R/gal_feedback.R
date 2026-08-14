# libs/shiny/R/gal_feedback.R
#
# Tab "Galeria > Notificaciones": todo lo que le dice algo al usuario sin
# ser un output de datos — notificaciones, progreso, modales, alerts,
# validacion y manejo de errores.
#
# Es el tab que mas importa para depurar: aca esta el patron de req() +
# validate() + tryCatch que evita que un error mate la sesion.

gal_feedback_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(6, 6),

      card(
        card_header("showNotification() — los 4 tipos"),
        card_body(
          div(
            class = "d-flex flex-wrap gap-2",
            actionButton(ns("n_default"), "default"),
            actionButton(ns("n_message"), "message", class = "btn-info"),
            actionButton(ns("n_warning"), "warning", class = "btn-warning"),
            actionButton(ns("n_error"),   "error",   class = "btn-danger")
          ),
          hr(),
          actionButton(ns("n_persistente"), "Persistente (duration = NULL)"),
          actionButton(ns("n_cerrar"), "Cerrar la persistente",
                       class = "btn-secondary")
        )
      ),

      card(
        card_header("withProgress() y Progress$new()"),
        card_body(
          actionButton(ns("p_with"), "withProgress() — 3 s"),
          br(), br(),
          actionButton(ns("p_manual"), "Progress$new() — control manual"),
          hr(),
          "Se usa en el refit manual del tab Ajuste, y sera obligatorio en ",
          "los temas lentos del mapa (brms, t-SNE, DTW)."
        )
      )
    ),

    br(),

    layout_columns(
      col_widths = c(6, 6),

      card(
        card_header("modalDialog()"),
        card_body(
          actionButton(ns("m_simple"), "Modal simple"),
          br(), br(),
          actionButton(ns("m_confirmar"), "Modal de confirmacion",
                       class = "btn-danger"),
          br(), br(),
          verbatimTextOutput(ns("resultado_modal"))
        )
      ),

      card(
        card_header("Alerts estaticos de Bootstrap"),
        card_body(
          div(class = "alert alert-primary", "alert-primary"),
          div(class = "alert alert-success", "alert-success"),
          div(class = "alert alert-warning", "alert-warning"),
          div(class = "alert alert-danger",  "alert-danger")
        )
      )
    ),

    br(),

    card(
      card_header("Validacion y errores — el patron que evita tumbar la app"),
      layout_columns(
        col_widths = c(4, 8),
        div(
          numericInput(ns("grado"), "Grado del polinomio", value = 3,
                       min = 1, max = 30),
          numericInput(ns("n"), "Tamano de muestra", value = 40,
                       min = 5, max = 500),
          helpText("Pone grado >= n-1 para disparar la validacion.")
        ),
        div(
          strong("validate() + need() — mensaje limpio en la UI"),
          verbatimTextOutput(ns("validado")),
          br(),
          strong("tryCatch() — el error se muestra, la sesion sigue viva"),
          verbatimTextOutput(ns("capturado"))
        )
      )
    )
  )
}

gal_feedback_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # --- Notificaciones ----------------------------------------------------
    observeEvent(input$n_default, showNotification("Notificacion por defecto"))
    observeEvent(input$n_message, showNotification("Todo salio bien",
                                                   type = "message"))
    observeEvent(input$n_warning, showNotification("Cuidado con esto",
                                                   type = "warning"))
    observeEvent(input$n_error,   showNotification("Algo fallo",
                                                   type = "error"))

    # duration = NULL deja la notificacion abierta hasta cerrarla por id.
    id_persistente <- reactiveVal(NULL)
    observeEvent(input$n_persistente, {
      id_persistente(showNotification(
        "No me voy sola. Cerrame con el otro boton.",
        duration = NULL, closeButton = TRUE, type = "warning"
      ))
    })
    observeEvent(input$n_cerrar, {
      if (!is.null(id_persistente())) {
        removeNotification(id_persistente())
        id_persistente(NULL)
      }
    })

    # --- Progreso ----------------------------------------------------------
    observeEvent(input$p_with, {
      withProgress(message = "Calculando", value = 0, {
        for (i in 1:10) {
          incProgress(1 / 10, detail = sprintf("paso %d de 10", i))
          Sys.sleep(0.3)
        }
      })
      showNotification("withProgress() termino", type = "message")
    })

    observeEvent(input$p_manual, {
      # Progress$new() da control total: util cuando el trabajo esta repartido
      # entre varias funciones y no cabe en un solo bloque withProgress().
      prog <- Progress$new(session, min = 0, max = 100)
      on.exit(prog$close())
      prog$set(message = "Progreso manual", value = 0)
      for (i in seq(0, 100, by = 20)) {
        prog$set(value = i, detail = paste0(i, "%"))
        Sys.sleep(0.25)
      }
    })

    # --- Modales -----------------------------------------------------------
    decision <- reactiveVal("Sin decision todavia.")

    observeEvent(input$m_simple, {
      showModal(modalDialog(
        title = "modalDialog() simple",
        "Cualquier UI de Shiny cabe aca adentro:",
        sliderInput(session$ns("dentro_modal"), "Incluso un slider", 0, 10, 5),
        easyClose = TRUE,
        footer = modalButton("Cerrar")
      ))
    })

    observeEvent(input$m_confirmar, {
      showModal(modalDialog(
        title = "Confirmar accion",
        "Este es el patron para acciones destructivas.",
        footer = tagList(
          modalButton("Cancelar"),
          actionButton(session$ns("confirmado"), "Confirmar",
                       class = "btn-danger")
        )
      ))
    })

    observeEvent(input$confirmado, {
      removeModal()
      decision(sprintf("Confirmado a las %s", format(Sys.time(), "%H:%M:%S")))
    })

    output$resultado_modal <- renderPrint(cat(decision()))

    # --- Validacion --------------------------------------------------------
    output$validado <- renderPrint({
      # validate()/need() corta el render y pinta el mensaje en gris en la UI,
      # sin stack trace y sin tumbar nada.
      validate(
        need(input$grado >= 1, "El grado debe ser >= 1"),
        need(input$n >= 5,     "n debe ser >= 5"),
        need(input$grado < input$n - 1,
             sprintf("Grado (%d) debe ser menor que n-1 (%d)",
                     input$grado, input$n - 1))
      )
      cat(sprintf("Valido: se puede ajustar poly(x, %d) con n = %d",
                  input$grado, input$n))
    })

    output$capturado <- renderPrint({
      res <- tryCatch({
        d <- gen_sintetico(n = input$n, tipo = "regresion")
        if (input$grado >= input$n - 1)
          stop("grado >= n-1: el ajuste queda singular")
        fit <- lm(y ~ poly(x, input$grado, raw = TRUE), data = d)
        sprintf("OK — R2 = %.4f", summary(fit)$r.squared)
      }, error = function(e) paste("Error capturado:", conditionMessage(e)))
      cat(res)
    })
  })
}
