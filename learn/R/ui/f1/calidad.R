# learn/R/ui/f1/calidad.R
#
# Responsabilidad: subsección Calidad — faltantes, atípicos y duplicados.
#
# Tres paneles y ninguna acción automática: la app marca, el usuario decide.
# Imputar y quitar duplicados cambian el dataset y quedan anotados en su pila
# de transformaciones, que es lo que después permite reconstruir qué pasó.

controles_calidad <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("columna_cal"), "Columna", choices = character(0)),
    shiny::radioButtons(ns("metodo_atipicos"), "Criterio de atipico",
                        choices = c("IQR (1.5 x RIC)" = "iqr",
                                    "z (desvios)" = "z",
                                    "Mahalanobis (multivariado)" = "mahalanobis"),
                        selected = "iqr"),
    shiny::sliderInput(ns("umbral_atipicos"), "Umbral", 1, 5, 1.5, step = 0.1),
    shiny::tags$hr(),
    shiny::selectInput(ns("metodo_imputar"), "Imputar faltantes con",
                       choices = c("mediana", "media", "moda")),
    shiny::actionButton(ns("imputar"), "Imputar esta columna",
                        class = "btn-outline-primary btn-sm w-100"),
    shiny::actionButton(ns("quitar_duplicados"), "Quitar filas duplicadas",
                        class = "btn-outline-secondary btn-sm w-100 mt-2"))
}

#' Las columnas candidatas salen del diccionario, no del tipo en memoria.
actualizar_calidad <- function(session, ds, previos = list()) {
  numericas <- columnas_numericas(ds)
  if (!length(numericas)) numericas <- names(ds$df)
  .rellenar_selector(session, "columna_cal", numericas, previos$columna_cal)
}

salida_calidad <- function(ns) {
  shiny::tagList(
    shiny::uiOutput(ns("avisos_cal")),
    panel_resultado("f1.calidad.matriz_nulidad",
      shiny::tagList(
        shiny::plotOutput(ns("nulidad"), height = "300px"),
        shiny::plotOutput(ns("faltantes_columna"), height = "200px")),
      contexto = salida_contexto(ns, "contexto_nulidad")),
    panel_resultado("f1.calidad.atipicos",
      shiny::plotOutput(ns("atipicos"), height = "300px"),
      contexto = salida_contexto(ns, "contexto_atipicos"),
      encabezado_extra = shiny::uiOutput(ns("badge_cal"), inline = TRUE)),
    panel_resultado("f1.calidad.duplicados",
      salida_tabla(ns, "duplicados"),
      contexto = salida_contexto(ns, "contexto_duplicados")))
}

servidor_calidad <- function(input, output, session, dataset, muestreo) {
  ns <- session$ns

  faltantes <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    patron_faltantes(ds$df)
  })

  atipicos <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds, input$columna_cal)
    metodo <- input$metodo_atipicos %||% "iqr"
    umbral <- if (identical(metodo, "mahalanobis")) 0.975
              else input$umbral_atipicos %||% 1.5
    entrada <- if (identical(metodo, "mahalanobis"))
      ds$df[, columnas_numericas(ds), drop = FALSE] else ds$df
    tryCatch(detectar_atipicos(entrada, input$columna_cal, metodo, umbral),
             error = function(e) NULL)
  })

  output$nulidad <- shiny::renderPlot(graficar_nulidad(faltantes()))
  output$faltantes_columna <- shiny::renderPlot(
    graficar_faltantes_columna(faltantes()))
  output$atipicos <- shiny::renderPlot({
    tabla <- atipicos()
    shiny::validate(shiny::need(!is.null(tabla),
                                "No se pudo calcular con ese criterio."))
    graficar_atipicos(tabla, input$columna_cal)
  })
  output$badge_cal <- shiny::renderUI(.badge_de_muestreo(ns, muestreo()))

  dibujar_tabla(output, "duplicados", shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    tabla <- marcar_duplicados(ds$df)
    tabla[tabla$repeticiones > 1L, , drop = FALSE]
  }), filtro = "none")

  shiny::observeEvent(input$imputar, {
    ds <- dataset()
    shiny::req(ds, input$columna_cal)
    resultado <- tryCatch(imputar(ds$df, input$columna_cal,
                                  input$metodo_imputar %||% "mediana"),
                          error = function(e) list(error = conditionMessage(e)))
    if (!is.null(resultado$error)) {
      .avisar_calidad(output, "error", resultado$error)
      return(invisible(NULL))
    }
    ds$df <- resultado$datos
    ds$diccionario <- diccionario_inicial(resultado$datos)
    ds$transformaciones <- c(ds$transformaciones, list(list(
      tipo = "imputar", columnas = input$columna_cal,
      params = list(metodo = resultado$metodo, imputados = resultado$imputados))))
    dataset(ds)
    .avisar_calidad(output, "aviso",
      sprintf("Se imputaron %d valores de '%s' con la %s (%s).",
              resultado$imputados, input$columna_cal, resultado$metodo,
              format(resultado$relleno)),
      "Imputar achica la varianza: la incertidumbre real es mayor.")
  })

  shiny::observeEvent(input$quitar_duplicados, {
    ds <- dataset()
    shiny::req(ds)
    marcas <- marcar_duplicados(ds$df)
    quitadas <- sum(marcas$duplicada)
    ds$df <- ds$df[!marcas$duplicada, , drop = FALSE]
    ds$n <- nrow(ds$df)
    ds$transformaciones <- c(ds$transformaciones, list(list(
      tipo = "quitar_duplicados", columnas = "todas",
      params = list(filas = quitadas))))
    dataset(ds)
    .avisar_calidad(output, "aviso",
                    sprintf("Se quitaron %d filas duplicadas.", quitadas))
  })

  dibujar_contexto(output, "f1.calidad.matriz_nulidad",
                   params = shiny::reactive(list(
                     total_pct = faltantes()$total_pct,
                     filas_completas = faltantes()$completas)),
                   sufijo = "contexto_nulidad")
  dibujar_contexto(output, "f1.calidad.atipicos",
                   params = shiny::reactive(list(
                     columna = input$columna_cal,
                     metodo = input$metodo_atipicos,
                     umbral = input$umbral_atipicos,
                     atipicos = attr(atipicos(), "n_atipicos"))),
                   sufijo = "contexto_atipicos")
  dibujar_contexto(output, "f1.calidad.duplicados",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     list(duplicadas = sum(marcar_duplicados(ds$df)$duplicada))
                   }), sufijo = "contexto_duplicados")
}

.avisar_calidad <- function(output, severidad, mensaje, sugerencia = NA_character_) {
  output$avisos_cal <- shiny::renderUI(lista_avisos(list(list(
    severidad = severidad, mensaje = mensaje, sugerencia = sugerencia))))
}
