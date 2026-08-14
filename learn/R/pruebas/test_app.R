# learn/R/pruebas/test_app.R
#
# Responsabilidad: probar la app en un navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app.R
#
# Por qué existe además de test_headless.R: un render limpio y un HTTP 200 no
# prueban nada. libs/sdd.md documenta cuatro bugs que pasaron los dos y solo
# aparecieron en la consola del navegador o en el DOM de errores. Un
# conditionalPanel mal namespaceado deja el servidor contento y la
# funcionalidad muerta en silencio.
#
# Por eso todas las aserciones son POSITIVAS: comprueban que el contenido
# esperado está, no solo que no hubo errores.

suppressPackageStartupMessages(library(shinytest2))

# AppDriver$new() llama a skip_on_cran() por dentro. Fuera de un contexto de
# testthat eso aborta con "Reason: On CRAN" antes de arrancar el navegador.
Sys.setenv(NOT_CRAN = "true")

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

#' Espera a que un texto aparezca en el DOM.
#'
#' Hace falta porque los outputs de una pestaña oculta están suspendidos: al
#' cambiar de sección se reanudan, pero `set_inputs()` no espera a ese segundo
#' ciclo. Sin esto las aserciones leen el DOM anterior y fallan sin motivo.
#'
#' @return el HTML del body cuando el patrón aparece (o el último leído)
esperar_html <- function(app, patron, intentos = 40, pausa = 0.25) {
  for (i in seq_len(intentos)) {
    html <- app$get_html("body")
    if (grepl(patron, html, fixed = TRUE)) return(html)
    Sys.sleep(pausa)
  }
  app$get_html("body")
}

#' Cambia de sección y espera a que su contenido esté pintado.
ir_a <- function(app, seccion, patron) {
  app$set_inputs(seccion = seccion)
  esperar_html(app, patron)
}

#' Errores de la consola del navegador. Lo único que delata un bug de cliente.
errores_de_consola <- function(app) {
  registro <- app$get_logs()
  if (is.null(registro) || !nrow(registro)) return(character(0))
  filas <- registro[registro$level %in% c("error", "SEVERE") |
                      registro$location == "shiny_console", ]
  mensajes <- as.character(filas$message)
  # Ruido conocido del entorno, no de la app.
  mensajes[!grepl("favicon|DevTools listening|Download the React",
                  mensajes, ignore.case = TRUE)]
}

cat("\n[arranque]\n")
app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab",
                     load_timeout = 60000, timeout = 20000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

html_inicio <- app$get_html("body")
probar("la app carga y pinta el navbar",
       grepl("SDA Lab", html_inicio, fixed = TRUE))
probar("el navbar tiene las 7 secciones", {
  faltan <- Filter(function(s) !grepl(s, html_inicio, fixed = TRUE),
                   c("Inicio", "Datos", "Modelado", "Ajuste", "Evaluación",
                     "Objetos", "Referencia"))
  length(faltan) == 0
})
probar("el badge de modo dice en qué entorno corre",
       grepl("servidor", html_inicio, fixed = TRUE))

cat("\n[inicio]\n")
probar("el mapa del curso pinta barras de progreso",
       grepl("progress-bar", html_inicio, fixed = TRUE))
probar("aparecen los títulos de las sesiones del curso",
       grepl("Componentes principales", html_inicio, fixed = TRUE))
probar("el panel de corridas explica que todavía no hay ninguna",
       grepl("Todavía no hay corridas", html_inicio, fixed = TRUE))

cat("\n[fase 2 · catálogo]\n")
html_catalogo <- ir_a(app, "② Modelado", "de 54 métodos")

probar("el catálogo se dibuja desde el registro",
       grepl("de 54 métodos", html_catalogo, fixed = TRUE))
probar("aparecen los seis objetivos como encabezados de grupo", {
  faltan <- Filter(function(o) !grepl(o, html_catalogo, fixed = TRUE),
                   c("Describir", "Reducir", "Agrupar", "Clasificar",
                     "Predecir", "Contrastar"))
  length(faltan) == 0
})
probar("hay una tarjeta de K-medias",
       grepl("K-medias", html_catalogo, fixed = TRUE))
probar("los métodos bloqueados se muestran, no se ocultan",
       grepl("Perceptrón multicapa", html_catalogo, fixed = TRUE))
probar("un método bloqueado lleva su candado",
       grepl("No ejecutable", html_catalogo, fixed = TRUE))

cat("\n[filtros]\n")
app$set_inputs(`modelado-objetivo` = "agrupar")
html_filtrado <- esperar_html(app, "8 de 54 métodos")
probar("filtrar por 'agrupar' deja k-medias",
       grepl("K-medias", html_filtrado, fixed = TRUE))
probar("filtrar por 'agrupar' saca la regresión simple",
       !grepl("Regresión lineal simple", html_filtrado, fixed = TRUE))
probar("el contador refleja el filtro",
       grepl("de 54 métodos", html_filtrado, fixed = TRUE) &&
         !grepl("54 de 54", html_filtrado, fixed = TRUE))

app$set_inputs(`modelado-objetivo` = character(0), `modelado-busqueda` = "lasso")
probar("la búsqueda encuentra LASSO",
       grepl("regularizada", esperar_html(app, "1 de 54 métodos"), fixed = TRUE))

app$click("modelado-limpiar")
probar("limpiar filtros devuelve los 54",
       grepl("54 de 54 métodos", esperar_html(app, "54 de 54 métodos"),
             fixed = TRUE))

cat("\n[ficha]\n")
app$click("modelado-ficha_mlp")
html_ficha <- esperar_html(app, "El puente")
probar("la ficha se abre en modal",
       grepl("Perceptrón multicapa", html_ficha, fixed = TRUE))
probar("la ficha de un bloqueado trae el puente",
       grepl("El puente", html_ficha, fixed = TRUE))
probar("el puente conecta con la regresión logística",
       grepl("regresión logística", html_ficha, fixed = TRUE))
probar("la ficha muestra metadatos del registro",
       grepl("notes/tree.md", html_ficha, fixed = TRUE))

cat("\n[resto de secciones]\n")
marcas <- c("① Datos" = "En construcción", "③ Ajuste" = "En construcción",
            "④ Evaluación" = "En construcción", "Objetos" = "Exportar JSON",
            "Referencia" = "Glosario")
for (seccion in names(marcas)) {
  html <- ir_a(app, seccion, marcas[[seccion]])
  probar(sprintf("'%s' navega y pinta su contenido", seccion),
         grepl(marcas[[seccion]], html, fixed = TRUE) &&
           !grepl("Error:", html, fixed = TRUE))
}

cat("\n[pestañas de fases sin construir]\n")
html_datos <- ir_a(app, "① Datos", "Diccionario")
probar("las 6 subsecciones de Datos ya existen como pestañas", {
  faltan <- Filter(function(s) !grepl(s, html_datos, fixed = TRUE),
                   c("Fuente", "Diccionario", "Calidad", "Transformación",
                     "Partición", "Balanceo"))
  length(faltan) == 0
})
probar("la pestaña de Análisis está presente en la fase 1",
       grepl("Análisis", html_datos, fixed = TRUE))
probar("una fase sin construir lo dice y apunta al hito",
       grepl("En construcción", html_datos, fixed = TRUE))

cat("\n[referencia]\n")
html_referencia <- ir_a(app, "Referencia", "Mahalanobis")
probar("el glosario define los símbolos del curso",
       grepl("Mahalanobis", html_referencia, fixed = TRUE))

cat("\n[tema]\n")
app$click("tema_darkly")
Sys.sleep(2)
probar("el cambio de tema no rompe la app",
       grepl("SDA Lab", app$get_html("body"), fixed = TRUE))

cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
probar("cero errores en la consola", length(errores) == 0)
if (length(errores)) for (e in utils::head(errores, 10)) cat("    ", e, "\n")

cat(sprintf("\n[test_app] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
