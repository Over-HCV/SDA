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
entrada_de <- function(clave, input, ds, id = "p1") {
  params <- params_de_artefacto(clave, input, ds)
  params <- params[!vapply(params, is.null, logical(1))]
  list(id = id, clave = clave, titulo = titulo_de(clave),
       cuando = format(Sys.time(), "%H:%M:%S"), params = params,
       tabla = tabla_de_artefacto(clave, input, ds))
}

#' Un id que no se reutiliza: la caja de texto de la lectura se llama por él,
#' y si un id vuelve después de quitar un panel, la lectura de uno aparece en
#' el otro.
.siguiente_id_entrada <- function(entradas) {
  usados <- suppressWarnings(as.integer(sub("^p", "", vapply(
    entradas, function(e) e$id %||% "p0", ""))))
  sprintf("p%d", max(c(0L, usados[!is.na(usados)])) + 1L)
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
    "f1.analisis.resumen" = list(variable = input$variable_uni,
                                 escala = .escala_de(ds, input$variable_uni)),
    "f1.analisis.boxplot_grupos" = list(variable = input$variable_uni,
                                        grupo = input$grupo_uni),
    "f1.analisis.qq_normal_datos" = list(variable = input$variable_uni),
    "f1.analisis.dispersion" = {
      a <- medir_asociacion(df[[input$x_bi]], df[[input$y_bi]])
      list(x = input$x_bi, y = input$y_bi, grupo = input$grupo_bi,
           marginales = isTRUE(input$marginales), alfa = input$alfa,
           jitter = isTRUE(input$jitter), celdas = isTRUE(input$celdas),
           suavizado = isTRUE(input$suavizado),
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
    "f1.analisis.resumen" = if (!is.null(input$variable_uni))
      resumir_variable(ds$df[[input$variable_uni]],
                       .escala_de(ds, input$variable_uni))[
                         , c("estadistico", "mostrado")] else NULL,
    NULL)
}

#' La identidad de un panel dentro del cuaderno: su clave más las columnas que
#' lo distinguen.
#'
#' Existe porque la casilla es por clave y el taller necesita el MISMO panel
#' dos veces con columnas distintas —la caja de Temperatura y la de
#' Velocidad_del_Viento son las dos mitades de la pregunta 4—. Con la identidad
#' en la mano, la casilla pasa a significar "lo que estoy mirando ahora está en
#' el cuaderno": al cambiar de variable se destilda sola y volver a marcarla
#' añade la segunda, en vez de reemplazar la primera.
#'
#' Los campos que identifican salen de PARAMS_REQUERIDOS, que ya declara cuáles
#' son las columnas de cada panel; acá solo hay que leerlas de los controles.
identidad_de_entrada <- function(entrada) {
  campos <- PARAMS_REQUERIDOS[[entrada$clave]] %||% character(0)
  paste(c(entrada$clave, unlist(entrada$params[campos], use.names = FALSE)),
        collapse = "|")
}

identidad_en_pantalla <- function(clave, input) {
  columnas <- switch(
    clave,
    "f1.analisis.histograma" = ,
    "f1.analisis.densidad" = ,
    "f1.analisis.boxplot" = ,
    "f1.analisis.resumen" = ,
    "f1.analisis.qq_normal_datos" = input$variable_uni,
    "f1.analisis.boxplot_grupos" = c(input$variable_uni, input$grupo_uni),
    "f1.analisis.dispersion" = ,
    "f1.analisis.densidad_conjunta" = c(input$x_bi, input$y_bi),
    "f1.analisis.elipsoide" = input$variables_multi[1:2],
    "f1.analisis.mosaico" = c(input$cruce_a, input$cruce_b),
    "f1.analisis.matriz_dispersion" = ,
    "f1.analisis.heatmap_correlacion" = ,
    "f1.analisis.coordenadas_paralelas" = ,
    "f1.analisis.qq_mahalanobis" = input$variables_multi,
    "f1.calidad.atipicos" = input$columna_cal,
    "f1.balanceo.frecuencias" = input$clase_bal,
    character(0))
  paste(c(clave, columnas), collapse = "|")
}

#' Observadores de las casillas: marcar añade lo que hay en pantalla, desmarcar
#' lo quita. El observer de sincronización devuelve la casilla a FALSE cuando
#' esa entrada ya no está —se vació la selección, se quitó la última, o se
#' cambió de columna—, para que la UI no mienta.
servidor_casillas <- function(input, session, dataset, seleccion) {
  lapply(CASILLAS_INFORME, function(clave) {
    shiny::observeEvent(input[[paste0("inf_", clave)]], {
      actual <- seleccion()
      identidad <- identidad_en_pantalla(clave, input)
      esta <- vapply(actual, function(e)
        identical(identidad_de_entrada(e), identidad), logical(1))
      if (!isTRUE(input[[paste0("inf_", clave)]])) {
        seleccion(actual[!esta])
        return(invisible(NULL))
      }
      # Restaurar una sesión vuelve a marcar las casillas, y sin esta guarda
      # cada marca programática añadía una copia: catorce paneles se volvían
      # veinticuatro al entrar a ① Datos.
      if (any(esta)) return(invisible(NULL))
      ds <- dataset()
      shiny::req(ds)
      seleccion(c(actual, list(entrada_de(clave, input, ds,
                                          .siguiente_id_entrada(actual)))))
    }, ignoreInit = TRUE)
  })

  shiny::observe({
    marcadas <- vapply(seleccion(), identidad_de_entrada, "")
    for (clave in CASILLAS_INFORME) {
      debe_estar <- identidad_en_pantalla(clave, input) %in% marcadas
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
        campo <- paste0("nota_", entrada$id %||% paste0("p", i))
        shiny::tags$div(
          class = "border rounded p-2 mb-2",
          shiny::tags$span(class = "fw-bold",
                           sprintf("%d. %s", i, entrada$titulo)),
          shiny::tags$span(class = "text-muted small ms-2",
                           sprintf("%s · %s", entrada$clave, entrada$cuando)),
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
            value = shiny::isolate(input[[campo]]) %||% (entrada$nota %||% "")))
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
