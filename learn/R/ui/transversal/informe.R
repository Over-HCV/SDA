# learn/R/ui/transversal/informe.R
#
# ⤓ Informe · exportar la exploración de la fase 1 como cuaderno reproducible.
#
# El flujo: cada panel con casilla "Añadir" (fase 1) deja un snapshot en la
# selección —clave, parámetros vigentes, texto y estado del dataset— y esta
# pestaña arma con todo ello un .Rmd autónomo (nucleo/informe_exploracion.R),
# más el CSV de los datos actuales y el JSON de la selección.
#
# La selección vive en un reactiveVal creado en app.R: sobrevive a los cambios
# de pestaña (todo es una sola sesión Shiny) y el JSON lo demuestra.

# Las casillas «Añadir» (qué se captura al marcar y cómo se sincronizan)
# viven en casillas.R.

# ---------------------------------------------------------------------------
# La pestaña
# ---------------------------------------------------------------------------

mod_informe_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 300, title = "Cuaderno", open = "desktop",
      shiny::div(
        style = ESTILO_CONTROLES,
        shiny::tags$p(class = "small text-muted",
                      paste("Cada panel marcado con la casilla Añadir entra",
                            "como una sección del cuaderno: su texto, sus",
                            "parámetros y el código R que lo redibuja, en el",
                            "orden de la lista: las flechas lo cambian.")),
        shiny::radioButtons(
          ns("texto"), "Texto explicativo de cada panel",
          choices = c("completo", "breve", "ninguno"), selected = "completo"),
        shiny::tags$p(class = "small text-muted",
                      paste("El taller puntúa la concisión. `breve` deja solo",
                            "qué muestra y cuándo engaña; el texto de un panel",
                            "repetido no se copia dos veces.")),
        shiny::downloadButton(ns("bajar_rmd"), "Cuaderno .Rmd",
                              class = "btn-primary btn-sm w-100 mb-2"),
        shiny::downloadButton(ns("bajar_csv"), "Datos actuales (CSV)",
                              class = "btn-outline-primary btn-sm w-100 mb-2"),
        shiny::downloadButton(ns("bajar_json"), "Selección (JSON)",
                              class = "btn-outline-primary btn-sm w-100 mb-3"),
        shiny::actionButton(ns("quitar_ultima"), "Quitar la última",
                            icon = shiny::icon("minus"),
                            class = "btn-sm btn-outline-secondary w-100 mb-2"),
        shiny::actionButton(ns("vaciar"), "Vaciar selección",
                            icon = shiny::icon("trash"),
                            class = "btn-sm btn-outline-danger w-100"))),
    bslib::card(
      bslib::card_header(
        shiny::fluidRow(
          shiny::column(8, shiny::tags$b("Paneles añadidos"),
                        shiny::uiOutput(ns("conteo"))),
          shiny::column(4, class = "text-end",
                        shiny::uiOutput(ns("estado_datos"))))),
      bslib::card_body(shiny::uiOutput(ns("lista")))))
}

#' Flecha para subir (-1) o bajar (+1) un panel en la lista. `data-mover`
#' existe para que las pruebas la encuentren sin depender del ícono.
.flecha <- function(ns, id, direccion, apagada) {
  subir <- direccion < 0L
  shiny::tags$button(
    type = "button", class = "btn btn-outline-secondary",
    title = if (subir) "Subir" else "Bajar",
    `aria-label` = if (subir) "Subir" else "Bajar",
    `data-mover` = sprintf("%s|%d", id, direccion),
    disabled = if (apagada) NA else NULL,
    onclick = sprintf(
      "Shiny.setInputValue('%s', {id: '%s', dir: %d}, {priority: 'event'})",
      ns("mover"), id, direccion),
    shiny::icon(if (subir) "arrow-up" else "arrow-down"))
}

#' @param texto reactiveVal del nivel de texto (app.R): viaja con la sesión
mod_informe_server <- function(id, seleccion, dataset, texto = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # El nivel de texto es parte de la sesión: sube al reactiveVal al elegirlo
    # y baja al radio cuando una sesión abierta trae otro.
    if (!is.null(texto)) {
      shiny::observeEvent(input$texto, texto(input$texto), ignoreInit = TRUE)
      shiny::observeEvent(texto(), {
        if (!identical(input$texto, texto()))
          shiny::updateRadioButtons(session, "texto", selected = texto())
      })
    }

    # Las lecturas se escriben en la selección mientras se tipean, así una
    # sesión guardada las lleva. Antes solo se copiaban al bajar el .Rmd y
    # guardar la sesión las perdía.
    lecturas <- shiny::debounce(shiny::reactive({
      ids <- vapply(seleccion(), function(e) e$id %||% "", "")
      stats::setNames(lapply(ids, function(id) input[[paste0("nota_", id)]]),
                      ids)
    }), 500)
    shiny::observeEvent(lecturas(), {
      escritas <- lecturas()
      actual <- shiny::isolate(seleccion())
      cambio <- FALSE
      for (i in seq_along(actual)) {
        valor <- escritas[[actual[[i]]$id %||% ""]]
        if (!is.null(valor) && !identical(valor, actual[[i]]$nota %||% "")) {
          actual[[i]]$nota <- valor
          cambio <- TRUE
        }
      }
      if (cambio) seleccion(actual)
    })

    # La lista se dibuja desde la selección SIN lecturas. Si dependiera de
    # seleccion() entera, cada letra guardada la volvería a dibujar y la caja
    # perdería el foco a mitad de palabra. Un reactiveVal no invalida cuando
    # recibe un valor idéntico, y eso es justo lo que se necesita.
    estructura <- shiny::reactiveVal(list())
    shiny::observe({
      sin_lecturas <- lapply(seleccion(), function(e) { e$nota <- NULL; e })
      if (!identical(sin_lecturas, shiny::isolate(estructura())))
        estructura(sin_lecturas)
    })

    output$conteo <- shiny::renderUI({
      n <- length(seleccion())
      shiny::tags$span(class = "text-muted small",
                       if (n == 1L) "1 panel" else sprintf("%d paneles", n))
    })
    output$estado_datos <- shiny::renderUI({
      ds <- dataset()
      if (is.null(ds)) return(shiny::tags$span(
        class = "badge text-bg-warning", "sin dataset"))
      shiny::tags$span(class = "badge text-bg-secondary",
                       sprintf("%s · %d x %d", ds$nombre, ds$n, ds$p))
    })

    # Cada panel trae su caja de lectura (nota_<id>) y sus flechas. Las cajas se
    # llaman por id y no por posición, así que reordenar las redibuja con su
    # texto intacto.
    output$lista <- shiny::renderUI({
      entradas <- estructura()
      notas <- stats::setNames(
        lapply(shiny::isolate(seleccion()), function(e) e$nota %||% ""),
        vapply(shiny::isolate(seleccion()), function(e) e$id %||% "", ""))
      if (!length(entradas))
        return(shiny::tags$p(
          class = "text-muted",
          paste("Nada añadido todavía. Andá a ① Datos, marcá la casilla",
                "«Añadir» de los paneles que quieras citar, y volvé acá para",
                "descargar el cuaderno.")))
      shiny::tags$div(lapply(seq_along(entradas), function(i) {
        entrada <- entradas[[i]]
        resumen <- paste(vapply(names(entrada$params), function(nombre)
          sprintf("%s = %s", nombre, paste(format(entrada$params[[nombre]]),
                                           collapse = " ")), ""),
          collapse = " · ")
        campo <- paste0("nota_", entrada$id %||% paste0("p", i))
        shiny::tags$div(
          class = "border rounded p-2 mb-2",
          shiny::tags$div(
            class = "d-flex align-items-start gap-2",
            shiny::tags$div(
              class = "flex-grow-1",
              shiny::tags$span(class = "fw-bold",
                               sprintf("%d. %s", i, entrada$titulo)),
              shiny::tags$span(class = "text-muted small ms-2",
                               sprintf("%s · %s", entrada$clave,
                                       entrada$cuando))),
            shiny::tags$div(
              class = "btn-group btn-group-sm",
              .flecha(ns, entrada$id, -1L, i == 1L),
              .flecha(ns, entrada$id, 1L, i == length(entradas)))),
          if (nzchar(resumen)) shiny::tags$p(
            class = "text-muted small mb-0 mt-1", resumen) else NULL,
          # La lectura se escribe acá y viaja al cuaderno en el lugar del
          # recordatorio. Un gráfico sin lectura no es una respuesta, y hasta
          # ahora el cuaderno no tenía dónde guardarla.
          shiny::textAreaInput(
            ns(campo), NULL, width = "100%", rows = 2,
            placeholder = "Qué se lee en este panel (va al cuaderno).",
            # Si la entrada viene de una sesión restaurada, su lectura ya
            # estaba escrita: la caja arranca con ella y no en blanco.
            value = shiny::isolate(input[[campo]]) %||%
              (notas[[entrada$id %||% ""]] %||% "")))
      }))
    })

    # Un solo evento para todas las flechas: {id, dir} lo manda el onclick de
    # .flecha(). Un actionButton por panel pediría un observador por id.
    shiny::observeEvent(input$mover, {
      seleccion(mover_entrada(seleccion(), input$mover$id,
                              as.integer(input$mover$dir)))
    })

    shiny::observeEvent(input$quitar_ultima, {
      entradas <- seleccion()
      if (length(entradas)) seleccion(entradas[-length(entradas)])
    })
    shiny::observeEvent(input$vaciar, {
      seleccion(list())
      shiny::showNotification("Selección vaciada.", type = "message",
                              duration = 3)
    })

    output$bajar_rmd <- shiny::downloadHandler(
      filename = "sda-lab-exploracion.Rmd",
      content = function(archivo) {
        shiny::validate(shiny::need(
          length(seleccion()) > 0L, "Marcá al menos una casilla Añadir."))
        writeLines(armar_informe_exploracion(
          .con_lecturas(seleccion(), input), dataset(),
          texto = input$texto %||% "completo"), archivo, useBytes = TRUE)
      })

    # La lectura que viaja al cuaderno: la del cuadro de texto y, si ese
    # cuadro todavía no se rindió (sesión recién importada, pestaña sin
    # abrir), la que traía la entrada.
    .con_lecturas <- function(entradas, input) lapply(entradas, function(e) {
      escrita <- input[[paste0("nota_", e$id %||% "")]]
      e$nota <- escrita %||% e$nota %||% ""
      e
    })

    output$bajar_csv <- shiny::downloadHandler(
      filename = "datos-sda-lab.csv",
      content = function(archivo) {
        ds <- dataset()
        shiny::validate(shiny::need(!is.null(ds), "No hay dataset cargado."))
        exportar_csv(ds$df, archivo)
      })

    output$bajar_json <- shiny::downloadHandler(
      filename = "seleccion-sda-lab.json",
      content = function(archivo) {
        entradas <- lapply(.con_lecturas(seleccion(), input), function(e) {
          e$tabla <- NULL      # el JSON es el contrato liviano, no el snapshot
          e
        })
        exportar_json(list(proyecto = "sda-lab", tipo = "exploracion",
                           modo = modo_ejecucion(), seleccion = entradas),
                      archivo)
      })
  })
}
