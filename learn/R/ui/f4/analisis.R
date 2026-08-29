# learn/R/ui/f4/analisis.R
#
# Responsabilidad: subsección ▣ Análisis de la fase 4 — el informe compuesto.
#
# Reúne las cuatro fases en un documento con narrativa: qué datos, qué modelo,
# cómo se ajustó, qué resultó. No es un extra: la guía del curso pide cuaderno
# RMD más diapositivas, y un informe exportable convierte una exploración en la
# mayor parte de un entregable.
#
# Todas las descargas pasan por downloadHandler y por los exportadores de
# nucleo/exportar.R. En wasm se escribe a tempdir() y el navegador se lo lleva
# desde ahí; nada de JavaScript propio (C10).

controles_analisis_evaluacion <- function(ns) {
  shiny::tagList(
    shiny::tags$p(class = "small text-muted mb-2", "Descargar la corrida"),
    shiny::downloadButton(ns("bajar_rmd"), "Cuaderno .Rmd",
                          class = "btn-sm btn-outline-primary w-100 mb-2"),
    shiny::downloadButton(ns("bajar_json"), "JSON del contrato",
                          class = "btn-sm btn-outline-primary w-100 mb-2"),
    shiny::downloadButton(ns("bajar_csv"), "Tabla del resultado (CSV)",
                          class = "btn-sm btn-outline-primary w-100 mb-2"),
    shiny::downloadButton(ns("bajar_rds"), "RDS sin pérdida",
                          class = "btn-sm btn-outline-primary w-100"),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  paste("El JSON lo lee un agente; el RDS conserva el objeto",
                        "de ajuste entero.")))
}

salida_analisis_evaluacion <- function(ns) {
  bslib::card(
    bslib::card_header("El informe, antes de exportarlo"),
    bslib::card_body(
      shiny::uiOutput(ns("aviso_informe")),
      shiny::verbatimTextOutput(ns("informe"))))
}

servidor_analisis_evaluacion <- function(input, output, session, piezas,
                                         corrida) {
  lineas <- shiny::reactive({
    c <- corrida()
    shiny::req(c)
    p <- piezas()
    armar_informe(c, dataset = p$dataset, modelo = p$modelo, receta = p$receta)
  })

  output$aviso_informe <- shiny::renderUI({
    if (is.null(corrida()))
      return(shiny::tags$p(class = "text-muted mb-0",
                           "Corré una composición para armar el informe."))
    shiny::tags$p(class = "text-muted small",
                  paste("Vista previa del .Rmd. Los bloques con preguntas",
                        "están para que las contestes vos: el informe no",
                        "interpreta por nadie."))
  })

  output$informe <- shiny::renderText({
    shiny::validate(shiny::need(!is.null(corrida()), "sin corrida todavia"))
    paste(lineas(), collapse = "\n")
  })

  nombre_de <- function(extension) function() {
    c <- corrida()
    nombre_descarga(paste0("corrida-", c$id %||% "sda"), extension)
  }

  output$bajar_rmd <- shiny::downloadHandler(
    filename = nombre_de("Rmd"),
    content = function(archivo) writeLines(lineas(), archivo, useBytes = TRUE))

  output$bajar_json <- shiny::downloadHandler(
    filename = nombre_de("json"),
    content = function(archivo) {
      p <- piezas()
      exportar_json(corrida(), archivo, dataset = p$dataset, modelo = p$modelo,
                    receta = p$receta)
    })

  output$bajar_csv <- shiny::downloadHandler(
    filename = nombre_de("csv"),
    content = function(archivo)
      exportar_csv(tabla_resultado(corrida()$ajuste), archivo))

  output$bajar_rds <- shiny::downloadHandler(
    filename = nombre_de("rds"),
    content = function(archivo) exportar_rds(corrida(), archivo))
  invisible(TRUE)
}
