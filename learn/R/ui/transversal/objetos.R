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
                      paste("Todo vive en memoria. Guardá antes de cerrar la",
                            "pestaña si querés conservarlo. La sesión lleva",
                            "además el estado de ① Datos: fuente, pila,",
                            "diccionario, paneles marcados y lecturas.")),
        controles_sesion(ns))
    ),
    do.call(bslib::navset_card_tab, paneles)
  )
}

#' @param dataset reactiveVal del dataset vivo de la fase 1 (puede ser NULL)
#' @param seleccion reactiveVal de los paneles marcados (puede ser NULL)
#' @param cuaderno,guardado reactiveVal de las piezas del cuaderno y del
#'   estado de guardado
mod_objetos_server <- function(id, almacen, dataset = NULL, seleccion = NULL,
                               cuaderno = NULL, guardado = NULL) {
  shiny::moduleServer(id, function(input, output, session) {

    # Guardar y abrir: el mismo componente que Inicio (transversal/sesion.R).
    servidor_sesion(input, output, session, almacen, dataset, seleccion,
                    cuaderno, guardado)

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

  })
}

#' Devolver la fase 1 a como estaba: el dataset se RECONSTRUYE desde la fuente
#' y la pila (nucleo/sesion.R) y los paneles marcados vuelven a la lista del
#' cuaderno. Las casillas de ① Datos se re-marcan solas: su observador de
#' sincronización mira esta misma selección.
#'
#' Vive fuera del módulo porque lo usan dos caminos: importar un archivo desde
#' ⚙ Objetos y abrir la app con una sesión ya puesta (`?sesion=`).
#'
#' @param dataset,seleccion los reactiveVal de app.R
#' @param cuaderno reactiveVal de las piezas del cuaderno, o NULL
#' @return el mensaje que se le muestra a quien importó
restaurar_fase1_en <- function(fase1, dataset, seleccion, cuaderno = NULL) {
  if (is.null(fase1)) return("Sesión importada (sin estado de ① Datos).")
  if (is.null(dataset) || is.null(seleccion))
    return("Sesión importada; los objetos, sí; el estado de ① Datos no.")
  reconstruido <- dataset_de_sesion(fase1)
  for (aviso in reconstruido$avisos) message("[sesion] ", aviso$mensaje)
  if (is.null(reconstruido$dataset))
    return(paste("Sesión importada, pero el dataset no se pudo recrear:",
                 reconstruido$avisos[[1]]$mensaje))
  dataset(reconstruido$dataset)
  if (!is.null(cuaderno) && !is.null(fase1$cuaderno))
    cuaderno(opciones_cuaderno(fase1$cuaderno))
  marcados <- seleccion_con_tablas(seleccion_de_sesion(fase1),
                                   reconstruido$dataset)
  seleccion(marcados)
  sprintf("Sesión restaurada · %s · %d x %d · %d paneles marcados",
          reconstruido$dataset$nombre, reconstruido$dataset$n,
          reconstruido$dataset$p, length(marcados))
}

avisar_sin_seleccion <- function() {
  shiny::showNotification("Elegí una fila primero.", type = "warning",
                          duration = 3)
  invisible(NULL)
}
