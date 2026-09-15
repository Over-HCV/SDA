# learn/R/ui/f1/filtro.R
#
# Responsabilidad: subsección Filtro — quedarse con las filas que interesan.
#
# El caso del curso es el Taller 01: "para los registros recolectados a medio
# día" son las filas con Hora = "12:00". Sin un filtro, esa pregunta no se
# puede responder dentro de la app.
#
# El filtro entra en la MISMA pila que las transformaciones de columna (tipo
# "filtro"), así que hereda gratis deshacer, el aviso de qué se aplicó y el
# cuaderno exportado. La pila se reaplica siempre desde los datos crudos: el
# orden entre filtro y transformaciones es el orden en que se añadieron.

# Un selector de valores con miles de niveles no se elige, se sufre: arriba de
# este tope la columna no se ofrece y el motivo se dice en el sidebar (C5).
TOPE_NIVELES_FILTRO <- 60L

controles_filtro <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("columna_filtro"), "Filtrar por columna",
                       choices = character(0)),
    shiny::selectInput(ns("valores_filtro"), "Valores a conservar",
                       choices = character(0), multiple = TRUE),
    shiny::actionButton(ns("aplicar_filtro"), "Aplicar filtro",
                        class = "btn-primary w-100"),
    shiny::actionButton(ns("deshacer_filtro"), "Deshacer la última",
                        class = "btn-outline-secondary btn-sm w-100 mt-2"),
    shiny::tags$hr(),
    shiny::uiOutput(ns("nota_columnas_filtro")))
}

actualizar_filtro <- function(session, ds, previos = list()) {
  candidatas <- .columnas_filtrables(ds)
  .rellenar_selector(session, "columna_filtro", candidatas,
                     previos$columna_filtro)
}

#' Columnas con pocos niveles distintos: las que un filtro puede elegir sin
#' volver el selector ilegible.
.columnas_filtrables <- function(ds) {
  if (is.null(ds) || !nrow(ds$diccionario)) return(character(0))
  con_niveles <- ds$diccionario$n_unicos >= 1L &
    ds$diccionario$n_unicos <= TOPE_NIVELES_FILTRO
  ds$diccionario$columna[con_niveles]
}

salida_filtro <- function(ns) {
  panel_resultado(
    "f1.filtro.filas",
    shiny::tagList(
      shiny::uiOutput(ns("avisos_filtro")),
      shiny::tableOutput(ns("resumen_filtro")),
      shiny::tags$h6(class = "mt-3", "Pila aplicada, en orden"),
      salida_tabla(ns, "pila_filtro")),
    contexto = salida_contexto(ns, "contexto_filtro"),
    encabezado_extra = casilla_informe(ns, "f1.filtro.filas"))
}

servidor_filtro <- function(input, output, session, datos_base, dataset) {
  ns <- session$ns

  # La nota explica por qué no están TODAS las columnas: sin ella, el selector
  # corto parece un bug (C5).
  output$nota_columnas_filtro <- shiny::renderUI({
    ds <- dataset()
    if (is.null(ds)) return(NULL)
    excluidas <- setdiff(ds$diccionario$columna, .columnas_filtrables(ds))
    if (!length(excluidas)) return(NULL)
    sobran <- sprintf("%d columnas con más de %d valores distintos no se ofrecen",
                      length(excluidas), TOPE_NIVELES_FILTRO)
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  paste(sobran, "como filtro: el selector de valores sería",
                        "ilegible. Transformá o discretizá antes si las necesitás."))
  })
  shiny::outputOptions(output, "nota_columnas_filtro",
                       suspendWhenHidden = FALSE)

  # Al cambiar de columna, los valores a conservar son los niveles que esa
  # columna tiene HOY, tras la pila vigente: es el estado que se va a filtrar.
  shiny::observeEvent(input$columna_filtro, {
    ds <- dataset()
    columna <- input$columna_filtro
    if (is.null(ds) || is.null(columna) || !columna %in% names(ds$df))
      return(invisible(NULL))
    niveles <- sort(unique(as.character(ds$df[[columna]])))
    niveles <- niveles[!is.na(niveles)]
    shiny::updateSelectInput(session, "valores_filtro", choices = niveles)
  })

  aplicar_pila <- function(ds, pila) {
    resultado <- aplicar_transformaciones(datos_base(), pila)
    if (!nrow(resultado$datos)) {
      output$avisos_filtro <- shiny::renderUI(lista_avisos(list(list(
        severidad = "error", mensaje = "la pila dejaría el dataset vacío",
        sugerencia = "No se aplicó nada: revisá los valores del filtro."))))
      return(invisible(NULL))
    }
    ds$df <- resultado$datos
    ds$transformaciones <- pila
    ds$diccionario <- rehacer_diccionario(ds$diccionario, resultado$datos)
    ds$n <- nrow(resultado$datos)
    ds$p <- ncol(resultado$datos)
    ds$particion <- NULL      # las filas cambiaron: la partición ya no vale
    dataset(ds)
    output$avisos_filtro <- shiny::renderUI(lista_avisos(resultado$avisos))
  }

  shiny::observeEvent(input$aplicar_filtro, {
    ds <- dataset()
    shiny::req(ds, input$columna_filtro, !is.null(datos_base()))
    if (!length(input$valores_filtro)) {
      output$avisos_filtro <- shiny::renderUI(lista_avisos(list(list(
        severidad = "error", mensaje = "elegí al menos un valor a conservar",
        sugerencia = NA_character_))))
      return(invisible(NULL))
    }
    pila <- agregar_transformacion(
      ds$transformaciones, "filtro", input$columna_filtro,
      list(valores = input$valores_filtro))
    aplicar_pila(ds, pila)
  })

  # Deshace la última entrada de la pila, sea filtro o transformación: es la
  # misma pila y el mismo "deshacer" que en Transformación.
  shiny::observeEvent(input$deshacer_filtro, {
    ds <- dataset()
    shiny::req(ds, length(ds$transformaciones) > 0)
    aplicar_pila(ds, quitar_transformacion(ds$transformaciones))
  })

  output$resumen_filtro <- shiny::renderTable({
    ds <- dataset()
    crudos <- datos_base()
    shiny::req(ds, crudos)
    tabla_filtro(nrow(crudos), ds$n)
  })

  dibujar_tabla(output, "pila_filtro", shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    if (!length(ds$transformaciones))
      return(data.frame(paso = integer(0), receta = character(0)))
    data.frame(paso = seq_along(ds$transformaciones),
               receta = vapply(ds$transformaciones, describir_transformacion, ""))
  }), filtro = "none")

  dibujar_contexto(output, "f1.filtro.filas",
                   params = shiny::reactive({
                     ds <- dataset()
                     crudos <- datos_base()
                     if (is.null(ds) || is.null(crudos)) return(NULL)
                     list(antes = nrow(crudos), ahora = ds$n,
                          filtros = .describir_filtros(ds))
                   }), sufijo = "contexto_filtro")
}

#' Los filtros de la pila, en una línea cada uno: "Hora en [12:00]".
#' Lo usan el contexto del panel y lo que viaja al cuaderno.
.describir_filtros <- function(ds) {
  pila <- ds$transformaciones
  filtros <- vapply(pila[is_tipos_pila(pila, "filtro")], function(entrada)
    sprintf("%s en [%s]", entrada$columnas[1],
            paste(entrada$params$valores, collapse = ", ")), "")
  if (length(filtros)) filtros else "ninguno"
}

#' La tabla del panel: cuántas filas trajo el archivo y cuántas quedan.
tabla_filtro <- function(al_cargar, ahora)
  data.frame(estado = c("filas al cargar", "filas ahora", "filas fuera"),
             cantidad = c(al_cargar, ahora, al_cargar - ahora),
             stringsAsFactors = FALSE)

#' ¿Cuáles entradas de la pila son de un tipo dado? Para el contexto del
#' panel: qué filtros exactos dejó aplicados el usuario.
is_tipos_pila <- function(pila, tipo) {
  vapply(pila, function(entrada) identical(entrada$tipo, tipo), logical(1))
}
