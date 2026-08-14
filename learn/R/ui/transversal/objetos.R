# learn/R/ui/transversal/objetos.R
#
# ⚙ Objetos · el CRUD de las cuatro piezas que la fase 4 compone.
#
# Existe como sección propia porque los objetos sobreviven a la fase que los
# creó: un dataset preparado en la fase 1 se reusa en veinte corridas. Sin un
# lugar donde verlos todos, esa reutilización no se descubre.

ETIQUETA_TIPO <- c(dataset = "Datasets", modelo = "Modelos",
                   receta = "Recetas", corrida = "Corridas")

mod_objetos_ui <- function(id) {
  ns <- shiny::NS(id)
  paneles <- lapply(TIPOS_OBJETO, function(tipo) {
    bslib::nav_panel(
      ETIQUETA_TIPO[[tipo]],
      shiny::tagList(
        salida_tabla(ns, paste0("tabla_", tipo)),
        shiny::tags$div(
          class = "mt-2 d-flex gap-2",
          shiny::actionButton(ns(paste0("clonar_", tipo)), "Clonar",
                              icon = shiny::icon("copy"),
                              class = "btn-sm btn-outline-secondary"),
          shiny::actionButton(ns(paste0("eliminar_", tipo)), "Eliminar",
                              icon = shiny::icon("trash"),
                              class = "btn-sm btn-outline-danger")),
        if (tipo != "corrida") shiny::tags$p(
          class = "text-muted small mt-2 mb-0",
          "Eliminar arrastra las corridas que dependan de este objeto: una",
          " corrida huérfana no se puede reproducir ni explicar.")
      ))
  })

  bslib::layout_sidebar(
    # Mismo trato que en piezas/fase.R, y por la misma razón: el alto lo acota
    # el sidebar y nadie más, y fillable = FALSE deja que la tabla crezca en vez
    # de repartirse un alto que no le alcanza.
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 300, title = "Sesión", open = "desktop",
      shiny::div(
        style = ESTILO_CONTROLES,
        shiny::tags$p(class = "small text-muted",
                      paste("Todo vive en memoria. Exportá antes de cerrar la",
                            "pestaña si querés conservarlo.")),
        shiny::downloadButton(ns("bajar_json"), "Exportar JSON",
                              class = "btn-sm btn-outline-primary w-100 mb-2"),
        shiny::downloadButton(ns("bajar_rds"), "Exportar RDS",
                              class = "btn-sm btn-outline-primary w-100 mb-3"),
        shiny::fileInput(ns("subir"), "Importar sesión",
                         accept = c(".json", ".rds"), buttonLabel = "Elegir"),
        shiny::hr(),
        plegable("¿JSON o RDS?", shiny::tags$div(
          class = "small",
          shiny::tags$p(shiny::tags$strong("JSON"), " viaja entre máquinas y lo",
                        " puede leer un agente, pero pierde fidelidad: los",
                        " objetos de ajuste no se serializan y los datasets se",
                        " truncan a 200 filas."),
          shiny::tags$p(class = "mb-0", shiny::tags$strong("RDS"), " conserva",
                        " todo exactamente, pero solo lo abre R."))))
    ),
    do.call(bslib::navset_card_tab, paneles)
  )
}

mod_objetos_server <- function(id, almacen) {
  shiny::moduleServer(id, function(input, output, session) {

    for (tipo in TIPOS_OBJETO) {
      local({
        este_tipo <- tipo
        id_tabla <- paste0("tabla_", este_tipo)
        dibujar_tabla(output, id_tabla,
                     datos = shiny::reactive(objetos_df(almacen(), este_tipo)),
                     filtro = "none", seleccion = "single")

        shiny::observeEvent(input[[paste0("clonar_", este_tipo)]], {
          fila <- input[[paste0(id_tabla, "_rows_selected")]]
          if (!length(fila)) return(avisar_sin_seleccion())
          df <- objetos_df(almacen(), este_tipo)
          almacen(almacen_clonar(almacen(), este_tipo, df$id[fila]))
        })

        shiny::observeEvent(input[[paste0("eliminar_", este_tipo)]], {
          fila <- input[[paste0(id_tabla, "_rows_selected")]]
          if (!length(fila)) return(avisar_sin_seleccion())
          df <- objetos_df(almacen(), este_tipo)
          almacen(almacen_eliminar(almacen(), este_tipo, df$id[fila]))
        })
      })
    }

    output$bajar_json <- shiny::downloadHandler(
      filename = function() nombre_descarga("sesion", "json"),
      content = function(archivo) exportar_sesion_json(almacen(), archivo))

    output$bajar_rds <- shiny::downloadHandler(
      filename = function() nombre_descarga("sesion", "rds"),
      content = function(archivo) exportar_sesion_rds(almacen(), archivo))

    shiny::observeEvent(input$subir, {
      ruta <- input$subir$datapath
      recuperado <- tryCatch({
        if (grepl("[.]rds$", input$subir$name, ignore.case = TRUE))
          importar_sesion_rds(ruta) else importar_sesion_json(ruta)
      }, error = function(e) {
        shiny::showNotification(paste("No se pudo importar:", conditionMessage(e)),
                                type = "error", duration = 6)
        NULL
      })
      if (!is.null(recuperado)) {
        almacen(recuperado)
        shiny::showNotification("Sesión importada", type = "message")
      }
    })
  })
}

avisar_sin_seleccion <- function() {
  shiny::showNotification("Elegí una fila primero.", type = "warning",
                          duration = 3)
  invisible(NULL)
}
