# learn/R/ui/transversal/referencia.R
#
# ⓘ Referencia · glosario, árbol de temas, catálogo tabular y entorno.
#
# Todo lo estático de consulta vive acá y no dentro de las fases (C5): es
# contenido que no cambia con ningún input, así que no puede ocupar píxeles de
# una vista donde hay resultados moviéndose.

GLOSARIO <- list(
  list("Σ", "Matriz de covarianzas poblacional", "070-multivariado/030-estadisticas/020-matriz-covarianzas"),
  list("S", "Matriz de covarianzas muestral", "070-multivariado/030-estadisticas/020-matriz-covarianzas"),
  list("R", "Matriz de correlación", "070-multivariado/030-estadisticas/030-matriz-correlacion"),
  list("λᵢ", "Autovalor i-ésimo: la varianza de la componente i", "010-fundamentos/050-autovalores"),
  list("vᵢ", "Autovector i-ésimo: la dirección de la componente i", "010-fundamentos/050-autovalores"),
  list("H", "Matriz de centrado, H = I − (1/n)11ᵀ", "010-fundamentos/030-matrices/070-matriz-centrado"),
  list("d²(x,μ)", "Distancia de Mahalanobis al cuadrado", "070-multivariado/050-distancias/030-mahalanobis"),
  list("T²", "Estadístico de Hotelling", "080-normal-multivariada/060-inferencia-mu/010-hotelling-una-muestra"),
  list("Λ", "Lambda de Wilks", "130-anova/070-manova/030-estadisticos"),
  list("W", "Inercia intra-grupo en k-medias", "100-agrupamiento/020-kmeans/020-calidad-particion"),
  list("s(i)", "Silueta de la observación i", "100-agrupamiento/020-kmeans/060-seleccion-k/040-silueta"),
  list("hᵢᵢ", "Apalancamiento de la observación i", "120-regresion/050-diagnostico/050-influyentes"),
  list("VIF", "Factor de inflación de la varianza", "120-regresion/050-diagnostico/060-multicolinealidad/010-vif"),
  list("η², ω²", "Tamaño del efecto en ANOVA", "130-anova/030-una-via/060-tamano-efecto")
)

mod_referencia_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::navset_card_tab(
    bslib::nav_panel("Glosario", shiny::uiOutput(ns("glosario"))),
    bslib::nav_panel("Catálogo", salida_tabla(ns, "tabla_metodos")),
    bslib::nav_panel("Artefactos", salida_tabla(ns, "tabla_artefactos")),
    bslib::nav_panel("Entorno", shiny::uiOutput(ns("entorno")))
  )
}

mod_referencia_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {

    output$glosario <- shiny::renderUI({
      shiny::tags$table(
        class = "table table-sm",
        shiny::tags$thead(shiny::tags$tr(
          shiny::tags$th("Símbolo"), shiny::tags$th("Qué es"),
          shiny::tags$th("Dónde se define"))),
        shiny::tags$tbody(lapply(GLOSARIO, function(fila) shiny::tags$tr(
          shiny::tags$td(shiny::tags$strong(fila[[1]])),
          shiny::tags$td(fila[[2]]),
          shiny::tags$td(shiny::tags$code(fila[[3]]))))))
    })

    dibujar_tabla(output, "tabla_metodos",
                 datos = shiny::reactive(metodos_df()))

    dibujar_tabla(output, "tabla_artefactos",
                 datos = shiny::reactive({
                   df <- artefactos_df()
                   df[, c("clave", "titulo", "fase", "grafico", "logica",
                          "hay_texto")]
                 }))

    output$entorno <- shiny::renderUI({
      cobertura <- cobertura_textos()
      shiny::tagList(
        franja_estado(list(
          "modo" = etiqueta_modo(),
          "R" = paste(R.version$major, R.version$minor, sep = "."),
          "métodos" = length(claves_metodos()),
          "artefactos" = length(claves_artefactos()),
          "fichas" = sprintf("%d/%d", cobertura$fichas_escritas,
                             cobertura$fichas_esperadas),
          "textos" = sprintf("%d/%d", cobertura$textos_escritos,
                             cobertura$textos_esperados))),
        shiny::tags$h6(class = "mt-4", "Comandos"),
        shiny::tags$pre(class = "small", paste(
          'Rscript -e \'shiny::runApp("learn/R/app.R", launch.browser = TRUE)\'',
          "Rscript learn/R/pruebas/test_headless.R",
          "Rscript learn/R/pruebas/test_app.R",
          "Rscript learn/R/mapa.R",
          'Rscript -e \'source("learn/build.R"); construir_bundle()\'',
          sep = "\n")),
        shiny::tags$h6(class = "mt-4", "Documentos"),
        shiny::tags$ul(
          shiny::tags$li(shiny::tags$code("learn/SCHEMA.md"),
                         " — el diseño de cada pantalla"),
          shiny::tags$li(shiny::tags$code("learn/CONVENCIONES.md"),
                         " — las reglas C1 a C14"),
          shiny::tags$li(shiny::tags$code("learn/PLAN.md"),
                         " — hitos y avance"),
          shiny::tags$li(shiny::tags$code("learn/MAPA.md"),
                         " — clave de artefacto → archivos"),
          shiny::tags$li(shiny::tags$code("notes/tree.md"),
                         " — el árbol completo de temas del curso"))
      )
    })
  })
}
