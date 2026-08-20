# learn/R/ui/f2/analisis.R
#
# Responsabilidad: subsección ▣ Análisis de la fase 2 — la geometría del modelo
# ANTES de ajustarlo.
#
# La tesis: se puede entender un modelo sin haberlo estimado, y hacerlo primero
# es lo que evita tratar el ajuste como una caja negra. Acá el optimizador es el
# usuario: mueve el ángulo y ve el error subir y bajar. La fase 3 después le
# muestra cómo lo hace la máquina.
#
# Superficie de pérdida, frontera de decisión y curva de potencia siguen
# pendientes: son vistas de k-medias, de los clasificadores y de las pruebas de
# hipótesis, no del ACP. Entran con su método.

DETALLE_ANALISIS_MODELADO <- list(
  "Superficie de pérdida" = paste(
    "Mapa de calor de la función objetivo sobre dos parámetros, con el mínimo",
    "marcado. Necesita un método con dos parámetros libres comparables:",
    "entra con k-medias."),
  "Frontera de decisión" = paste(
    "Dónde el clasificador cambia de opinión. Entra con LDA y la regresión",
    "logística."),
  "Curva de potencia" = paste(
    "Potencia frente a n y al tamaño del efecto. Entra con las pruebas de",
    "hipótesis de la sesión 8."))

controles_analisis_modelado <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("par_x"), "Variable horizontal",
                       choices = character(0)),
    shiny::selectInput(ns("par_y"), "Variable vertical", choices = character(0)),
    shiny::sliderInput(ns("angulo"), "Dirección candidata (grados)",
                       min = 0, max = 180, value = 45, step = 1),
    shiny::actionButton(ns("ir_al_optimo"), "Llevame al óptimo",
                        class = "btn-sm btn-outline-primary w-100"),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  paste("Dos variables por vez: el espacio de hipótesis de p",
                        "variables no cabe en una curva.")))
}

actualizar_analisis_modelado <- function(session, ds, previos = list()) {
  numericas <- columnas_numericas(ds)
  .rellenar_selector(session, "par_x", numericas,
                     previos$par_x %||% numericas[1])
  .rellenar_selector(session, "par_y", numericas,
                     previos$par_y %||% numericas[min(2L, length(numericas))])
}

salida_analisis_modelado <- function(ns) {
  pendientes <- lapply(names(DETALLE_ANALISIS_MODELADO), function(titulo)
    panel_pendiente(titulo, "Hitos 4-6", DETALLE_ANALISIS_MODELADO[[titulo]]))

  shiny::tagList(
    panel_resultado(
      "f2.analisis.espacio_hipotesis",
      shiny::plotOutput(ns("espacio_hipotesis"), height = "300px"),
      contexto = salida_contexto(ns, "contexto_espacio")),
    panel_resultado(
      "f2.analisis.modelo_manual",
      shiny::tagList(
        shiny::plotOutput(ns("modelo_manual"), height = "340px"),
        shiny::uiOutput(ns("marcador_objetivo"))),
      contexto = salida_contexto(ns, "contexto_manual")),
    plegable("Lo que falta en esta subsección", shiny::tagList(pendientes)))
}

servidor_analisis_modelado <- function(input, output, session, dataset,
                                       muestreo) {
  par_elegido <- shiny::reactive({
    c(input$par_x, input$par_y)
  })

  objetivo <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds, input$par_x, input$par_y)
    evaluar_objetivo(ds$df, par_elegido(), .radianes(input$angulo))
  })

  # Llevar el slider al máximo es el atajo que cierra el bucle: el usuario
  # busca a mano, no encuentra el punto exacto, pulsa el botón y ve que era el
  # mismo ángulo que marca la curva.
  shiny::observeEvent(input$ir_al_optimo, {
    optimo <- objetivo()$optimo
    shiny::req(is.finite(optimo))
    shiny::updateSliderInput(session, "angulo",
                             value = round(optimo * 180 / pi))
  })

  output$espacio_hipotesis <- shiny::renderPlot({
    ds <- dataset()
    shiny::validate(shiny::need(!is.null(ds),
                                "Elegí un dataset guardado en Objetos."))
    .exigir_par(par_elegido())
    graficar_espacio_hipotesis(
      familia_candidatas(muestreo()$datos, par_elegido()),
      angulo = .radianes(input$angulo))
  })

  output$modelo_manual <- shiny::renderPlot({
    ds <- dataset()
    shiny::validate(shiny::need(!is.null(ds),
                                "Elegí un dataset guardado en Objetos."))
    .exigir_par(par_elegido())
    graficar_modelo_manual(
      proyectar_en_direccion(muestreo()$datos, par_elegido(),
                             .radianes(input$angulo)),
      par_elegido(), objetivo())
  })

  # Las cuentas van sobre el dataset completo, nunca sobre la muestra de
  # dibujo (C8).
  output$marcador_objetivo <- shiny::renderUI({
    valores <- objetivo()
    shiny::req(is.finite(valores$proporcion))
    franja_estado(list(
      "captado" = sprintf("%.1f %%", 100 * valores$proporcion),
      "fuera" = sprintf("%.3f", valores$error_reconstruccion),
      "optimo en" = sprintf("%.0f grados", valores$optimo * 180 / pi)))
  })

  parametros <- shiny::reactive({
    if (is.null(dataset()) || is.null(input$par_x)) return(NULL)
    list(variables = paste(par_elegido(), collapse = " x "),
         angulo_grados = input$angulo,
         varianza_captada = round(objetivo()$proporcion, 4),
         muestreo = descripcion_muestreo(muestreo()) %||% "sin muestreo")
  })
  for (par in list(c("f2.analisis.espacio_hipotesis", "contexto_espacio"),
                   c("f2.analisis.modelo_manual", "contexto_manual")))
    dibujar_contexto(output, par[1], params = parametros, sufijo = par[2])
  invisible(TRUE)
}

.radianes <- function(grados) (grados %||% 0) * pi / 180

# Dos variables distintas o no hay plano que mirar. Se dice, no se esconde (C5).
.exigir_par <- function(par) {
  shiny::validate(
    shiny::need(length(par) == 2L && all(nzchar(par)),
                "Elegí dos variables numéricas en el sidebar."),
    shiny::need(par[1] != par[2],
                "Las dos variables tienen que ser distintas: una contra sí misma no define un plano."))
  invisible(TRUE)
}
