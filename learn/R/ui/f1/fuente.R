# learn/R/ui/f1/fuente.R
#
# Responsabilidad: subsección Fuente — elegir de dónde salen los datos.
#
# Nada se lee al arrancar la app: solo al pulsar Cargar. Con el panel crudo de
# charcoal eso importa de verdad, porque dentro del navegador son 35.115 filas
# que hay que descomprimir antes de ver una sola celda.

controles_fuente <- function(ns) {
  catalogo <- fuentes_disponibles()
  opciones <- c(stats::setNames(as.list(catalogo$clave), catalogo$nombre),
                list("subir archivo (CSV)" = "subido"))
  visible_si <- function(condicion, contenido)
    shiny::conditionalPanel(condicion, ns = ns, contenido)

  shiny::tagList(
    shiny::radioButtons(ns("fuente"), "Fuente", choices = opciones,
                        selected = "sintetico_anova"),
    visible_si("input.fuente == 'sintetico_anova'", shiny::tagList(
      shiny::sliderInput(ns("k_grupos"), "Grupos", 2, 8, 4),
      shiny::sliderInput(ns("efecto"), "Separacion entre medias", 0, 10, 5,
                         step = 0.5))),
    visible_si("input.fuente.indexOf('sintetico') == 0", shiny::tagList(
      shiny::sliderInput(ns("n"), "Observaciones", 30, 1000, 200, step = 10),
      shiny::numericInput(ns("semilla"), "Semilla", value = 42, min = 1))),
    visible_si("input.fuente == 'charcoal_pivot'",
      shiny::selectInput(ns("flujo"), "Flujo", choices = FLUJOS_SUGERIDOS)),
    visible_si("input.fuente == 'subido'", shiny::tagList(
      shiny::fileInput(ns("archivo"), "Archivo CSV", accept = ".csv",
                       buttonLabel = "Examinar", placeholder = "sin archivo"),
      shiny::selectInput(ns("separador"), "Separador",
                         c("coma ," = ",", "punto y coma ;" = ";",
                           "tabulador" = "\t")),
      shiny::selectInput(ns("decimal"), "Decimal",
                         c("punto ." = ".", "coma ," = ",")))),
    shiny::uiOutput(ns("peso_fuente")),
    shiny::actionButton(ns("cargar"), "Cargar", class = "btn-primary w-100",
                        icon = shiny::icon("download")))
}

salida_fuente <- function(ns) {
  panel_resultado(
    "f1.fuente.vista_previa",
    shiny::tagList(
      shiny::uiOutput(ns("avisos_fuente")),
      salida_tabla(ns, "vista_previa")),
    contexto = salida_contexto(ns, "contexto_fuente"))
}

servidor_fuente <- function(input, output, session, datos_base, dataset) {
  ns <- session$ns

  # Solo texto: acá renderUI es seguro porque no hay ningún control que
  # Shiny tenga que enlazar.
  output$peso_fuente <- shiny::renderUI({
    peso <- aviso_de_peso(input$fuente %||% "sintetico_anova")
    if (is.null(peso)) return(NULL)
    shiny::tags$p(class = "text-warning small mt-2", peso)
  })

  shiny::observeEvent(input$cargar, {
    clave <- input$fuente %||% "sintetico_anova"
    resultado <- tryCatch({
      if (identical(clave, "subido")) {
        shiny::validate(shiny::need(!is.null(input$archivo),
                                    "Elegí un archivo primero."))
        leido <- leer_archivo_subido(input$archivo$datapath,
                                     separador = input$separador %||% ",",
                                     decimal = input$decimal %||% ".")
        list(datos = leido$datos, fuente = "subido", avisos = leido$avisos)
      } else {
        cargar_fuente(clave, semilla = input$semilla %||% 42L,
                      n = input$n %||% 200L, k_grupos = input$k_grupos %||% 4L,
                      efecto = input$efecto %||% 5,
                      flujo = input$flujo %||% "Production")
      }
    }, error = function(e) list(error = conditionMessage(e)))

    if (!is.null(resultado$error)) {
      output$avisos_fuente <- shiny::renderUI(lista_avisos(list(list(
        severidad = "error", mensaje = resultado$error,
        sugerencia = "Revisá los parámetros de lectura."))))
      return(invisible(NULL))
    }

    datos_base(resultado$datos)
    dataset(nuevo_dataset(NULL, .nombre_de_fuente(clave, input$archivo),
                          resultado$datos, fuente = clave,
                          semilla = input$semilla %||% 42L))
    output$avisos_fuente <- shiny::renderUI(lista_avisos(resultado$avisos))
  })

  # dibujar_tabla ya recorta para wasm y escribe el pie "mostrando X de N" (C7).
  dibujar_tabla(output, "vista_previa", shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    ds$df
  }))

  dibujar_contexto(output, "f1.fuente.vista_previa",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     list(fuente = ds$fuente, n = ds$n, p = ds$p,
                          semilla = ds$semilla)
                   }), sufijo = "contexto_fuente")
}

.nombre_de_fuente <- function(clave, archivo = NULL) {
  if (identical(clave, "subido") && !is.null(archivo))
    return(tools::file_path_sans_ext(archivo$name))
  clave
}
