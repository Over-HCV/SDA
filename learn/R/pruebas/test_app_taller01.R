# learn/R/pruebas/test_app_taller01.R
#
# Responsabilidad: el recorrido completo del Taller 01 en un navegador de
# verdad — cargar ORI, quedarse con las filas del mediodía y llevarse paneles
# al cuaderno.
#
# Uso:  Rscript learn/R/pruebas/test_app_taller01.R
#
# Vive aparte de test_app.R por C2: aquel recorre el shell y la fase 1; este
# es un escenario de punta a punta. Es la única prueba que toca las tres
# piezas nuevas a la vez, que es donde estaba el riesgo: el filtro vive en
# ① Datos, la casilla en sus paneles y el cuaderno en otra sección del navbar.

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

esperar_html <- function(app, patron, intentos = 60, pausa = 0.25) {
  for (i in seq_len(intentos)) {
    html <- app$get_html("body")
    if (grepl(patron, html, fixed = TRUE)) return(html)
    Sys.sleep(pausa)
  }
  app$get_html("body")
}

ir_a <- function(app, seccion, patron) {
  app$set_inputs(seccion = seccion, wait_ = FALSE)
  html <- esperar_html(app, patron)
  app$wait_for_idle(duration = 400, timeout = 20000)
  html
}

ir_a_pestana <- function(app, entrada, pestana, patron) {
  do.call(app$set_inputs,
          c(stats::setNames(list(pestana), entrada), list(wait_ = FALSE)))
  html <- esperar_html(app, patron)
  app$wait_for_idle(duration = 400, timeout = 20000)
  html
}

errores_de_consola <- function(app) {
  registro <- app$get_logs()
  if (is.null(registro) || !nrow(registro)) return(character(0))
  filas <- registro[registro$level %in% c("error", "SEVERE") |
                      registro$location == "shiny_console", ]
  mensajes <- as.character(filas$message)
  mensajes[!grepl("favicon|DevTools listening|Download the React",
                  mensajes, ignore.case = TRUE)]
}

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-taller01",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[taller 01 · cargar ORI y filtrar el mediodía]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "ori", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-cargar")
html_ori <- esperar_html(app, "4.543", intentos = 120)
probar("la fuente del taller carga sus 4.543 filas",
       grepl("4.543", html_ori, fixed = TRUE))
probar("la vista previa trae las columnas del taller",
       grepl("Punto_de_Rocio", html_ori, fixed = TRUE) &&
         grepl("Pronostico", html_ori, fixed = TRUE))

html_filtro <- ir_a_pestana(app, "datos-pestana", "Filtro", "filas al cargar")
probar("Filtro dice cuántas filas había y cuántas quedan",
       grepl("filas al cargar", html_filtro, fixed = TRUE))
app$set_inputs(`datos-columna_filtro` = "Hora", wait_ = FALSE)
app$wait_for_idle(duration = 600, timeout = 20000)
app$set_inputs(`datos-valores_filtro` = "12:00", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-aplicar_filtro")
html_medio_dia <- esperar_html(app, "filtro Hora en [12:00]", intentos = 120)
probar("filtrar Hora = 12:00 deja las 118 filas del taller",
       grepl("118", html_medio_dia, fixed = TRUE))
probar("el filtro queda anotado en la pila, como una transformación más",
       grepl("filtro Hora en [12:00]", html_medio_dia, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[taller 01 · marcar paneles y leer el cuaderno]\n")

html_marginal <- ir_a_pestana(app, "datos-pestana", "▣ Análisis",
                              "Histogramas marginales")
probar("la dispersión ofrece los histogramas marginales (Pregunta 7)",
       grepl("Histogramas marginales", html_marginal, fixed = TRUE))
probar("cada panel trae su casilla para añadirlo al cuaderno",
       grepl("Añadir", html_marginal, fixed = TRUE))
app$set_inputs(`datos-inf_f1.analisis.boxplot` = TRUE, wait_ = FALSE)
app$wait_for_idle(duration = 600, timeout = 20000)

# Se espera por el conteo y no por el título "Paneles añadidos": ese es UI
# estática y ya está en el DOM del panel oculto, así que devolvería el HTML de
# antes de que el servidor rindiera la selección.
html_informe <- ir_a(app, "Informe", "1 panel")
# En la lista y no en todo el body: la clave también sale en el contexto de la
# card, y buscarla en cualquier lado dejó pasar una selección vacía.
probar("la pestaña Informe lista el panel marcado en ① Datos",
       grepl("f1.analisis.boxplot", app$get_html("#informe-lista"), fixed = TRUE))
probar("el conteo de paneles refleja la selección",
       grepl("1 panel", html_informe, fixed = TRUE))
probar("el cuaderno sabe sobre qué dataset se armó",
       grepl("ori · 118 x 18", html_informe, fixed = TRUE))

# La pregunta 4 del taller pide la caja de DOS variables. La casilla es por
# panel, así que sin identidad la segunda reemplazaba a la primera y el
# cuaderno salía con la mitad de la respuesta.
invisible(ir_a(app, "① Datos", "Añadir"))
marcar_caja <- function(variable) {
  app$set_inputs(`datos-variable_uni` = variable, wait_ = FALSE)
  app$wait_for_idle(duration = 800, timeout = 20000)
  marcada <- isTRUE(app$get_value(input = "datos-inf_f1.analisis.boxplot"))
  app$set_inputs(`datos-inf_f1.analisis.boxplot` = TRUE, wait_ = FALSE)
  app$wait_for_idle(duration = 800, timeout = 20000)
  marcada
}
probar("al cambiar de variable la casilla se destilda sola",
       !marcar_caja("Temperatura"))
probar("y con otra variable vuelve a destildarse, lista para sumar la segunda",
       !marcar_caja("Velocidad_del_Viento"))
html_dos <- ir_a(app, "Informe", "3 paneles")
probar("el mismo panel entra dos veces con columnas distintas (Pregunta 4)",
       grepl("variable = Temperatura", html_dos, fixed = TRUE) &&
         grepl("variable = Velocidad_del_Viento", html_dos, fixed = TRUE))
probar("hay botón para bajarse el cuaderno .Rmd",
       grepl("Cuaderno .Rmd", html_informe, fixed = TRUE))
app$click("informe-vaciar")
app$wait_for_idle(duration = 600, timeout = 20000)
probar("vaciar la selección deja la pestaña como al principio",
       grepl("Nada añadido todavía", app$get_html("body"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) for (e in utils::head(errores, 10)) cat("    ", e, "\n")
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_taller01] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
