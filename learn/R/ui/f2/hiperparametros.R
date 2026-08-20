# learn/R/ui/f2/hiperparametros.R
#
# Responsabilidad: subsección Hiperparámetros — los del MODELO, no los del
# ajuste. Los del ajuste (tolerancia, iteraciones, semilla) son de la fase 3.
#
# El formulario se genera desde `metodo(clave)$hiper` con formulario_hiper(),
# así que no puede desincronizarse de la función de ajuste: esa es la primera
# pata de la regla de las tres partes (C11).
#
# Por qué NO se rinde con renderUI aunque dependa del método elegido: un
# `uiOutput` que reemplaza controles deja inputs sin binding y la consola queda
# limpia (la trampa está documentada en AGENT.md y costó el Hito 2). En su
# lugar se construyen de una vez los formularios de TODOS los métodos activos y
# se muestra el que toca con conditionalPanel. Hoy es uno; el catálogo crece de
# a un método por hito, así que el coste está acotado.

controles_hiperparametros <- function(ns) {
  activos <- filtrar_metodos(estado = "activo")
  if (!length(activos))
    return(shiny::tags$p(class = "text-muted small",
                         "Todavía no hay ningún método implementado."))
  shiny::tagList(lapply(activos, function(clave) {
    shiny::conditionalPanel(
      sprintf("input.metodo == '%s'", clave), ns = ns,
      formulario_hiper(ns, clave))
  }))
}

salida_hiperparametros <- function(ns) {
  panel_resultado(
    "f2.analisis.presupuesto_parametros",
    shiny::tagList(
      shiny::uiOutput(ns("resumen_hiper")),
      shiny::plotOutput(ns("presupuesto"), height = "300px")),
    contexto = salida_contexto(ns, "contexto_presupuesto"))
}

servidor_hiperparametros <- function(input, output, session, dataset,
                                     clave_metodo, columnas, hiper) {
  output$resumen_hiper <- shiny::renderUI({
    valores <- hiper()
    shiny::validate(shiny::need(length(valores),
                                "Este método no tiene hiperparámetros."))
    franja_estado(lapply(valores, function(v) paste(v, collapse = ", ")))
  })

  output$presupuesto <- shiny::renderPlot({
    ds <- dataset()
    shiny::validate(shiny::need(!is.null(ds),
                                "Elegí un dataset guardado en Objetos."))
    shiny::validate(shiny::need(length(columnas()) >= 2L,
                                "Marcá al menos dos columnas en Especificación."))
    graficar_presupuesto(
      presupuesto_por_k(clave_metodo(), p = length(columnas()), n = ds$n),
      k = hiper()$n_componentes)
  })

  dibujar_contexto(output, "f2.analisis.presupuesto_parametros",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     c(hiper(), list(metodo = clave_metodo(),
                                     p = length(columnas()), n = ds$n))
                   }),
                   sufijo = "contexto_presupuesto")
  invisible(TRUE)
}
