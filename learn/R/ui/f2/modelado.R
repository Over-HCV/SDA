# learn/R/ui/f2/modelado.R
#
# Responsabilidad: cablear la fase 2. No calcula ni dibuja nada por su cuenta.
#
# Mismo contrato de cuatro funciones por subsección que f1/datos.R:
#
#   controles_<x>(ns) · actualizar_<x>(session, ds) · salida_<x>(ns) ·
#   servidor_<x>(input, output, session, ...)
#
# De dónde sale el dataset: del almacén, no de la fase 1 directamente. Las
# fases no se hablan entre sí; se hablan a través de los Objetos, que es lo que
# permite componer un dataset viejo con un modelo nuevo en la fase 4. Y para
# que llegar acá no exija saber eso, `.asegurar_dataset()` hace el primer
# "Guardar en Objetos" solo: si el almacén está vacío y la fase 1 tiene un
# dataset vivo, lo guarda y lo deja seleccionado.
#
# Lo que produce esta fase es un Modelo: método + columnas + hiperparámetros.

SUBSECCIONES_MODELADO <- c("Catálogo", "Especificación", "Supuestos",
                           "Hiperparámetros", ETIQUETA_ANALISIS)

mod_modelado_ui <- function(id) {
  ns <- shiny::NS(id)
  subsecciones <- list(
    "Catálogo"        = salida_catalogo(ns),
    "Especificación"  = salida_especificacion(ns),
    "Supuestos"       = salida_supuestos(ns),
    "Hiperparámetros" = salida_hiperparametros(ns))
  subsecciones[[ETIQUETA_ANALISIS]] <- salida_analisis_modelado(ns)

  armazon_fase(controles = .sidebar_modelado(ns),
               subsecciones = subsecciones,
               estado = shiny::uiOutput(ns("estado")),
               id_pestanas = ns("pestana"))
}

.sidebar_modelado <- function(ns) {
  visible_en <- function(pestana, contenido)
    shiny::conditionalPanel(
      sprintf("input.pestana == '%s'", pestana), ns = ns, contenido)

  shiny::tagList(
    .selectores_comunes(ns),
    visible_en("Catálogo", controles_catalogo(ns)),
    visible_en("Especificación", controles_especificacion(ns)),
    visible_en("Supuestos", controles_supuestos(ns)),
    visible_en("Hiperparámetros", controles_hiperparametros(ns)),
    visible_en(ETIQUETA_ANALISIS, controles_analisis_modelado(ns)),
    .controles_modelo(ns))
}

# El método elegido vive en un input de verdad y no en un reactiveVal para que
# conditionalPanel pueda leerlo: la condición se evalúa en el navegador y solo
# ve inputs. "Elegir" en el catálogo lo actualiza con updateSelectInput.
.selectores_comunes <- function(ns) {
  activos <- filtrar_metodos(estado = "activo")
  etiquetas <- vapply(activos, function(clave) metodo(clave)$nombre, "")
  shiny::tagList(
    shiny::selectInput(ns("dataset"), "Dataset", choices = character(0)),
    shiny::selectInput(ns("metodo"), "Método",
                       choices = stats::setNames(activos, etiquetas)),
    shiny::tags$hr())
}

.controles_modelo <- function(ns) {
  shiny::tagList(
    shiny::tags$hr(),
    shiny::actionButton(ns("guardar"), "Guardar modelo en Objetos",
                        class = "btn-outline-primary btn-sm w-100",
                        icon = shiny::icon("save")),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  "La fase 4 compone Dataset x Modelo x Receta."))
}

#' @param almacen    reactiveVal del almacén de la sesión
#' @param dataset_f1 reactiveVal del dataset vivo de la fase 1 (puede ser NULL)
#' @param entrar     reactivo TRUE mientras la sección activa es ② Modelado
#' @param al_explorar función(claves de artefacto) que lleva a ① Datos, al
#'                   panel donde un pendiente con `explora` ya corre
mod_modelado_server <- function(id, almacen = NULL, dataset_f1 = NULL,
                                entrar = NULL, al_explorar = NULL) {
  shiny::moduleServer(id, function(input, output, session) {

    # El traspaso ① → ② sin fricción. Hace una sola vez lo que antes pedíamos
    # descubrir a mano: si no hay NINGÚN dataset guardado y la fase 1 tiene
    # uno vivo, ejecuta el mismo "Guardar en Objetos" del botón de ① (incluida
    # la actualización del reactiveVal de la fase 1 a la copia con id). El
    # selector de abajo sigue ahí para elegir ENTRE versiones guardadas.
    .asegurar_dataset <- function() {
      if (is.null(almacen) || is.null(dataset_f1)) return(invisible(NULL))
      if (length(almacen_ids(almacen(), "dataset"))) return(invisible(NULL))
      ds <- tryCatch(dataset_f1(), error = function(e) NULL)
      if (is.null(ds)) return(invisible(NULL))
      guardado <- almacen_agregar(almacen(), ds)
      almacen(guardado)
      dataset_f1(almacen_obtener(guardado, "dataset",
                                 attr(guardado, "id_nuevo")))
      shiny::showNotification(
        sprintf("Dataset de ① Datos guardado como %s",
                attr(guardado, "id_nuevo")),
        type = "message", duration = 5)
      invisible(NULL)
    }

    dataset <- shiny::reactive({
      shiny::req(!is.null(almacen), nzchar(input$dataset %||% ""))
      almacen_obtener(almacen(), "dataset", input$dataset)
    })
    clave_metodo <- shiny::reactive(input$metodo)
    columnas <- shiny::reactive(input$columnas %||% character(0))
    hiper <- shiny::reactive({
      shiny::req(clave_metodo())
      valores_hiper(input, clave_metodo())
    })

    # La muestra de dibujo es compartida, igual que en la fase 1 (C8): los
    # gráficos usan muestreo()$datos, las cuentas usan dataset()$df.
    muestreo <- shiny::reactive({
      ds <- dataset()
      shiny::req(ds)
      muestrear_para_grafico(ds$df, semilla = ds$semilla)
    })

    # Los datasets guardados cambian mientras la app corre; el selector se
    # rellena cada vez que el almacén se mueve, sin perder lo ya elegido.
    shiny::observeEvent(almacen(), {
      ids <- almacen_ids(almacen(), "dataset")
      etiquetas <- vapply(ids, function(id)
        sprintf("%s · %s", id, almacen_obtener(almacen(), "dataset", id)$nombre),
        "")
      .rellenar_selector(session, "dataset",
                         stats::setNames(ids, etiquetas), input$dataset)
    }, ignoreNULL = FALSE)

    # El tipo de entrada del método decide qué columnas se ofrecen, así que el
    # selector se rellena también al CAMBIAR de método: con un ACM elegido, las
    # numéricas ya no son candidatas y seguir mostrándolas invita al error.
    tipo_entrada <- shiny::reactive({
      clave <- clave_metodo()
      if (is.null(clave) || !nzchar(clave)) return("matriz_numerica")
      metodo(clave)$entrada$tipo %||% "matriz_numerica"
    })

    shiny::observeEvent(list(dataset(), tipo_entrada()), {
      ds <- dataset()
      shiny::req(ds)
      previos <- shiny::isolate(shiny::reactiveValuesToList(input))
      actualizar_especificacion(session, ds, previos, tipo_entrada())
      actualizar_analisis_modelado(session, ds, previos)
    })

    output$estado <- shiny::renderUI(.franja_modelo(dataset_o_nulo(dataset),
                                                    clave_metodo(), columnas(),
                                                    hiper()))

    # Dos caminos llegan al mismo requisito: "Elegir" en el catálogo y entrar
    # a la sección por el navbar. El observador de `entrar` se dispara también
    # al IRSE de ② (el reactivo pasa a FALSE), por eso el guardia.
    if (!is.null(entrar))
      shiny::observeEvent(entrar(), {
        if (isTRUE(entrar())) .asegurar_dataset()
      }, ignoreInit = TRUE)

    servidor_catalogo(input, output, session, al_elegir = function(clave) {
      .asegurar_dataset()
      shiny::updateSelectInput(session, "metodo", selected = clave)
      shiny::updateTabsetPanel(session, "pestana", selected = "Especificación")
    }, al_explorar = al_explorar)
    servidor_especificacion(input, output, session, dataset, columnas,
                            tipo = tipo_entrada)
    servidor_supuestos(input, output, session, dataset, clave_metodo, columnas)
    servidor_hiperparametros(input, output, session, dataset, clave_metodo,
                             columnas, hiper)
    servidor_analisis_modelado(input, output, session, dataset, muestreo)

    shiny::observeEvent(input$guardar, {
      shiny::req(!is.null(almacen), clave_metodo())
      modelo <- nuevo_modelo(
        NULL, sprintf("%s · %d vars", metodo(clave_metodo())$nombre,
                      length(columnas())),
        clave_metodo(), spec = columnas(), hiper = hiper())
      guardado <- almacen_agregar(almacen(), modelo)
      almacen(guardado)
      shiny::showNotification(
        sprintf("Modelo guardado como %s", attr(guardado, "id_nuevo")),
        type = "message", duration = 3)
    })
  })
}

#' `dataset()` usa req() y aborta el reactivo cuando no hay nada elegido; la
#' franja de estado tiene que pintarse igual, diciendo que falta.
dataset_o_nulo <- function(dataset) {
  tryCatch(dataset(), error = function(e) NULL)
}

.franja_modelo <- function(ds, clave, columnas, hiper) {
  if (is.null(ds))
    return(franja_estado(list(
      "dataset" = "sin elegir",
      "que hacer" = "cargá uno en ① Datos y volvé")))
  m <- metodo(clave)
  franja_estado(c(
    list("dataset" = ds$id, "n" = ds$n, "variables X" = length(columnas),
         "metodo" = m$nombre),
    lapply(hiper, function(v) paste(v, collapse = ", "))))
}
