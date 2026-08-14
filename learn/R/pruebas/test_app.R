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

#' Cambia de pestaña dentro de una fase y espera a que el sidebar exista Y esté
#' enlazado. Que el HTML aparezca no alcanza: Shiny ata los bindings un ciclo
#' después, y hasta entonces set_inputs() no encuentra el control.
ir_a_pestana <- function(app, entrada, pestana, patron) {
  do.call(app$set_inputs,
          c(stats::setNames(list(pestana), entrada), list(wait_ = FALSE)))
  html <- esperar_html(app, patron)
  app$wait_for_idle(duration = 400, timeout = 20000)
  html
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
marcas <- c("① Datos" = "Vista previa del dataset", "③ Ajuste" = "En construcción",
            "④ Evaluación" = "En construcción", "Objetos" = "Exportar JSON",
            "Referencia" = "Glosario")
for (seccion in names(marcas)) {
  html <- ir_a(app, seccion, marcas[[seccion]])
  probar(sprintf("'%s' navega y pinta su contenido", seccion),
         grepl(marcas[[seccion]], html, fixed = TRUE) &&
           !grepl("Error:", html, fixed = TRUE))
}

cat("\n[fase 1 · estructura]\n")
# Se espera por la franja de estado y no por un título: los títulos son UI
# estática y ya están en el DOM antes de que el servidor rinda el sidebar.
html_datos <- ir_a(app, "① Datos", "sin cargar")
probar("las 6 subsecciones de Datos ya existen como pestañas", {
  faltan <- Filter(function(s) !grepl(s, html_datos, fixed = TRUE),
                   c("Fuente", "Diccionario", "Calidad", "Transformación",
                     "Partición", "Balanceo"))
  length(faltan) == 0
})
probar("la pestaña de Análisis está presente en la fase 1",
       grepl("Análisis", html_datos, fixed = TRUE))
probar("la fase 1 ya no es un andamio del Hito 2",
       !grepl("En construcción · Hito 2", html_datos, fixed = TRUE))
probar("la franja de estado arranca sin dataset",
       grepl("sin cargar", html_datos, fixed = TRUE))
probar("el sidebar ofrece las fuentes del curso",
       grepl("charcoal", html_datos, fixed = TRUE))

cat("\n[fase 1 · cargar y mirar]\n")
app$set_inputs(`datos-fuente` = "sintetico_anova", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-cargar")
html_cargado <- esperar_html(app, "sintetico_anova")
probar("cargar el sintético llena la franja de estado",
       grepl("faltantes", html_cargado, fixed = TRUE))
probar("la vista previa trae su pie de conteo",
       grepl("filas", html_cargado, fixed = TRUE))
probar("el badge de muestreo no aparece por debajo del umbral",
       !grepl("graficando", html_cargado, fixed = TRUE))

html_analisis <- ir_a_pestana(app, "datos-pestana", "▣ Análisis",
                              "Clases del histograma")
probar("▣ Análisis pinta el histograma con su sello",
       grepl("Histograma", html_analisis, fixed = TRUE))
probar("el hook de las clases del histograma está a la vista",
       grepl("Clases del histograma", html_analisis, fixed = TRUE))
probar("el ancho de banda h también es un control",
       grepl("Ancho de banda h", html_analisis, fixed = TRUE))

app$set_inputs(`datos-clases` = 12, wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
probar("mover las clases no rompe el panel",
       grepl("Histograma", app$get_html("body"), fixed = TRUE))

cat("\n[fase 1 · la escala manda]\n")
# Se espera por un encabezado de la tabla: los rótulos del sidebar ya están en
# el DOM aunque su pestaña esté oculta, así que no sirven de señal.
html_diccionario <- ir_a_pestana(app, "datos-pestana", "Diccionario",
                                 "faltantes_pct")
probar("el diccionario se dibuja con una fila por columna",
       grepl("faltantes_pct", html_diccionario, fixed = TRUE))
probar("se explica qué habilita la escala elegida",
       grepl("se habilitan", html_diccionario, fixed = TRUE))

app$set_inputs(`datos-columna_dic` = "valor", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$set_inputs(`datos-escala` = "nominal", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-aplicar_dic")
invisible(ir_a_pestana(app, "datos-pestana", "▣ Análisis",
                       "Clases del histograma"))
app$set_inputs(`datos-variable_uni` = "valor", wait_ = FALSE)
html_bloqueado <- esperar_html(app, "no aplica a una escala nominal")
probar("marcar la variable como nominal bloquea el histograma",
       grepl("no aplica a una escala nominal", html_bloqueado, fixed = TRUE))
probar("el bloqueo viene con su razón escrita",
       grepl("Promediarlas no significa nada", html_bloqueado, fixed = TRUE))

cat("\n[fase 1 · preparar de verdad]\n")
html_calidad <- ir_a_pestana(app, "datos-pestana", "Calidad",
                             "Matriz de nulidad")
probar("Calidad ofrece los tres criterios de atípico",
       grepl("Mahalanobis (multivariado)", html_calidad, fixed = TRUE))
app$set_inputs(`datos-metodo_atipicos` = "z", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
probar("cambiar el criterio no rompe el panel",
       !grepl("Error:", app$get_html("body"), fixed = TRUE))

invisible(ir_a_pestana(app, "datos-pestana", "Transformación", "Pila aplicada"))
app$set_inputs(`datos-columnas_tr` = "valor", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$set_inputs(`datos-tipo_tr` = "logaritmo", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-aplicar_tr")
html_transformada <- esperar_html(app, "logaritmo sobre")
probar("aplicar una transformación la deja anotada en la pila",
       grepl("logaritmo sobre", html_transformada, fixed = TRUE))
probar("la franja de estado cuenta la transformación aplicada",
       grepl("transformaciones", html_transformada, fixed = TRUE))
app$click("datos-deshacer_tr")
app$wait_for_idle(duration = 600, timeout = 20000)
probar("deshacer vacía la pila",
       !grepl("logaritmo sobre", app$get_html("body"), fixed = TRUE))

invisible(ir_a_pestana(app, "datos-pestana", "Partición", "Tamaño de cada parte"))
app$set_inputs(`datos-estrato` = "grupo", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-partir")
html_particion <- esperar_html(app, "estratificada por grupo")
probar("partir deja constancia de tipo, semilla y estrato",
       grepl("holdout · semilla 42 · estratificada por grupo", html_particion,
             fixed = TRUE))
probar("la franja de estado registra la partición",
       grepl("holdout", html_particion, fixed = TRUE))

invisible(ir_a_pestana(app, "datos-pestana", "Balanceo", "Frecuencias por clase"))
app$click("datos-balancear")
html_balanceo <- esperar_html(app, "Se rebalanceo por")
probar("balancear avisa de lo que hizo y por qué importa",
       grepl("Las probabilidades a priori cambiaron", html_balanceo,
             fixed = TRUE))
probar("rebalancear invalida la partición anterior",
       grepl("balanceo", html_balanceo, fixed = TRUE))

cat("\n[fase 1 · muestreo visible (C8)]\n")
invisible(ir_a_pestana(app, "datos-pestana", "Fuente", "Vista previa"))
app$set_inputs(`datos-fuente` = "charcoal_crudo", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-cargar")
invisible(esperar_html(app, "charcoal_crudo", intentos = 120))
# El badge vive en el encabezado de los paneles con gráfico, y los outputs de
# una pestaña oculta están suspendidos: hay que ir a mirarlo.
html_charcoal <- ir_a_pestana(app, "datos-pestana", "▣ Análisis", "graficando")
probar("con 35.113 filas aparece el badge de muestreo",
       grepl("graficando", html_charcoal, fixed = TRUE))
probar("el badge dice cuántas filas se dibujan y con qué semilla",
       grepl("de 35.113 · semilla 42", html_charcoal, fixed = TRUE))
probar("la franja sigue reportando el total, no la muestra",
       grepl("35.113", html_charcoal, fixed = TRUE))

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
