# learn/R/ui/f4/aportes.R
#
# Responsabilidad: las cards que hablan de VARIABLES en un plano factorial.
#
# Cargas (cuánto pesa cada variable en el eje), círculo de correlaciones (cómo
# se correlaciona con él), contribución (quién puso la varianza, en porcentaje)
# y calidad de representación (cuánto de esa variable muestra este plano de
# verdad). Se dibujan en la subsección Explicabilidad, junto a las cards de
# individuos de f4/explicabilidad.R, y comparten su contexto: mismo par de ejes.
#
# La distinción que justifica las dos últimas: una variable con contribución
# baja no aporta al eje; una con calidad baja SÍ podría aportar, pero a otro eje.
# Confundirlas es leer el círculo al revés.

salida_aportes <- function(ns) {
  shiny::tagList(
    panel_si_declara(ns, "f4.explicabilidad.cargas",
                     shiny::plotOutput(ns("cargas"), height = "300px"),
                     contexto = salida_contexto(ns, "contexto_cargas")),
    panel_si_declara(ns, "f4.explicabilidad.circulo_correlaciones",
                     shiny::plotOutput(ns("circulo"), height = "380px"),
                     contexto = salida_contexto(ns, "contexto_circulo")),
    panel_si_declara(ns, "f4.explicabilidad.contribuciones",
                     shiny::plotOutput(ns("contribuciones"), height = "300px"),
                     contexto = salida_contexto(ns, "contexto_contribuciones")),
    panel_si_declara(ns, "f4.explicabilidad.calidad",
                     shiny::plotOutput(ns("calidad"), height = "300px"),
                     contexto = salida_contexto(ns, "contexto_calidad")))
}

#' @param contexto salida de contexto_plano()
servidor_aportes <- function(input, output, session, contexto) {
  ajuste <- contexto$ajuste
  ejes <- contexto$ejes

  sobre_correlacion <- shiny::reactive(
    identical(ajuste()$matriz, "correlacion"))

  output$cargas <- shiny::renderPlot({
    graficar_cargas(cargas(ajuste(), componentes = unique(ejes())))
  })

  output$circulo <- shiny::renderPlot({
    contexto$exigir_ejes()
    graficar_circulo(correlaciones_componentes(ajuste(), ejes()),
                     contexto$etiquetas(),
                     sobre_correlacion = sobre_correlacion(),
                     suplementarias = contexto$suplementaria())
  })

  output$contribuciones <- shiny::renderPlot({
    graficar_contribuciones(contribuciones(ajuste(),
                                           componentes = unique(ejes())))
  })

  output$calidad <- shiny::renderPlot({
    contexto$exigir_ejes()
    graficar_calidad(calidad_variables(ajuste(), ejes()),
                     sobre_correlacion = sobre_correlacion())
  })

  for (par in list(c("f4.explicabilidad.cargas", "contexto_cargas"),
                   c("f4.explicabilidad.circulo_correlaciones", "contexto_circulo"),
                   c("f4.explicabilidad.contribuciones", "contexto_contribuciones"),
                   c("f4.explicabilidad.calidad", "contexto_calidad")))
    dibujar_contexto(output, par[1], params = contexto$parametros,
                     metricas = contexto$metricas, corrida = contexto$corrida,
                     sufijo = par[2])
  invisible(TRUE)
}
