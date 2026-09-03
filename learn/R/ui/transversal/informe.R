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

# La lista de claves con casilla vive en nucleo/informe_exploracion.R: es un
# contrato sobre qué se puede exportar, no una decisión de presentación, y ahí
# las pruebas headless pueden mirarla sin cargar Shiny.

#' La casilla "Añadir" del encabezado de un panel. Solo eso: el verbo y el
#' check. Que el panel entra al informe al marcarla es intuitivo; una etiqueta
#' larga le roba lugar al título y a los badges.
casilla_informe <- function(ns, clave)
  shiny::checkboxInput(ns(paste0("inf_", clave)), "Añadir", FALSE)

#' Una entrada de la selección: lo que se captura al marcar la casilla.
#'
#' Los parámetros se congelan AL MARCAR, no al exportar: el cuaderno debe
#' reflejar lo que el usuario estaba viendo cuando decidió añadirlo.
entrada_de <- function(clave, input, ds) {
  params <- params_de_artefacto(clave, input, ds)
  params <- params[!vapply(params, is.null, logical(1))]
  list(clave = clave, titulo = titulo_de(clave),
       cuando = format(Sys.time(), "%H:%M:%S"), params = params,
       tabla = tabla_de_artefacto(clave, input, ds))
}

#' Parámetros que viajan al cuaderno, por clave. Los que se pueden calcular
#' (correlación, conteo de atípicos) se calculan acá y quedan congelados.
params_de_artefacto <- function(clave, input, ds) {
  df <- ds$df
  switch(
    clave,
    "f1.fuente.vista_previa" = list(filas = ds$n, columnas = ds$p),
    "f1.diccionario.tabla" = list(columnas = ds$p),
    "f1.analisis.histograma" = list(
      variable = input$variable_uni, clases = input$clases,
      densidad = isTRUE(input$con_densidad), normal = isTRUE(input$con_normal)),
    "f1.analisis.densidad" = list(
      variable = input$variable_uni, ancho = input$ancho,
      normal = isTRUE(input$con_normal)),
    "f1.analisis.boxplot" = list(variable = input$variable_uni),
    "f1.analisis.boxplot_grupos" = list(variable = input$variable_uni,
                                        grupo = input$grupo_uni),
    "f1.analisis.qq_normal_datos" = list(variable = input$variable_uni),
    "f1.analisis.dispersion" = {
      a <- medir_asociacion(df[[input$x_bi]], df[[input$y_bi]])
      list(x = input$x_bi, y = input$y_bi, grupo = input$grupo_bi,
           marginales = isTRUE(input$marginales),
           pearson = round(a$pearson, 4), covarianza = round(a$covarianza, 4),
           spearman = round(a$spearman, 4), n = a$n)
    },
    "f1.analisis.densidad_conjunta" = list(x = input$x_bi, y = input$y_bi),
    "f1.analisis.mosaico" = {
      tabla <- tabla_contingencia(df[[input$cruce_a]], df[[input$cruce_b]],
                                  input$cruce_a, input$cruce_b)
      list(a = input$cruce_a, b = input$cruce_b, chi2 = round(tabla$chi2, 3),
           cramer = round(tabla$cramer, 4))
    },
    "f1.analisis.matriz_dispersion" = list(variables = input$variables_multi,
                                           grupo = input$grupo_multi),
    "f1.analisis.heatmap_correlacion" = list(variables = input$variables_multi,
                                             metodo = input$metodo_cor),
    "f1.analisis.coordenadas_paralelas" =
      list(variables = input$variables_multi, grupo = input$grupo_multi,
           metodo = input$normalizacion),
    "f1.analisis.elipsoide" = list(
      x = input$variables_multi[1], y = input$variables_multi[2],
      nivel = input$nivel_elipse),
    "f1.analisis.qq_mahalanobis" = list(variables = input$variables_multi),
    "f1.calidad.atipicos" = {
      metodo <- input$metodo_atipicos %||% "iqr"
      tabla <- detectar_atipicos(
        if (identical(metodo, "mahalanobis"))
          df[, columnas_numericas(ds), drop = FALSE] else df,
        input$columna_cal, metodo, input$umbral_atipicos)
      list(columna = input$columna_cal, metodo = metodo,
           umbral = input$umbral_atipicos,
           n_atipicos = attr(tabla, "n_atipicos"))
    },
    "f1.balanceo.frecuencias" = list(clase = input$clase_bal),
    list())
}

#' Tablas cuyo estado se congela tal cual: el diccionario es estado declarado
#' por el usuario y no se puede recalcular desde el código.
tabla_de_artefacto <- function(clave, input, ds) {
  switch(
    clave,
    "f1.fuente.vista_previa" = utils::head(ds$df, 10),
    "f1.diccionario.tabla" = ds$diccionario[, c("columna", "escala", "clase",
                                                "rol")],
    "f1.balanceo.frecuencias" = resumir_balance(ds$df, input$clase_bal),
    NULL)
}

#' Observadores de las casillas: marcar añade, desmarcar quita. El observer de
#' sincronización devuelve las casillas a FALSE cuando la entrada desaparece
#' por otro camino (vaciar, quitar última), para que la UI no mienta.
servidor_casillas <- function(input, session, dataset, seleccion) {
  lapply(CASILLAS_INFORME, function(clave) {
    shiny::observeEvent(input[[paste0("inf_", clave)]], {
      actual <- seleccion()
      if (!isTRUE(input[[paste0("inf_", clave)]])) {
        quedan <- actual[vapply(actual, function(e)
          !identical(e$clave, clave), logical(1))]
        seleccion(quedan)
        return(invisible(NULL))
      }
      ds <- dataset()
      shiny::req(ds)
      seleccion(c(actual, list(entrada_de(clave, input, ds))))
    }, ignoreInit = TRUE)
  })

  shiny::observe({
    marcadas <- vapply(seleccion(), function(e) e$clave, "")
    for (clave in CASILLAS_INFORME) {
      debe_estar <- clave %in% marcadas
      if (!identical(isTRUE(input[[paste0("inf_", clave)]]), debe_estar))
        shiny::updateCheckboxInput(session, paste0("inf_", clave),
                                   value = debe_estar)
    }
  })
}

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
                            "parámetros y el código R que lo redibuja.")),
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

mod_informe_server <- function(id, seleccion, dataset) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

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

    # Texto puro: renderUI acá es el uso permitido (fragmentos sin controles).
    output$lista <- shiny::renderUI({
      entradas <- seleccion()
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
        shiny::tags$div(
          class = "border rounded p-2 mb-2",
          shiny::tags$span(class = "fw-bold",
                           sprintf("%d. %s", i, entrada$titulo)),
          shiny::tags$span(class = "text-muted small ms-2",
                           sprintf("%s · %s", entrada$clave, entrada$cuando)),
          if (nzchar(resumen)) shiny::tags$p(
            class = "text-muted small mb-0 mt-1", resumen) else NULL)
      }))
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
        writeLines(armar_informe_exploracion(seleccion(), dataset()),
                   archivo, useBytes = TRUE)
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
        entradas <- lapply(seleccion(), function(e) {
          e$tabla <- NULL      # el JSON es el contrato liviano, no el snapshot
          e
        })
        exportar_json(list(proyecto = "sda-lab", tipo = "exploracion",
                           modo = modo_ejecucion(), seleccion = entradas),
                      archivo)
      })
  })
}
