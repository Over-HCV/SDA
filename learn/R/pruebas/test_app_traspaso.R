# learn/R/pruebas/test_app_traspaso.R
#
# Responsabilidad: probar el traspaso automatico de dataset ① → ②.
#
# Uso:  Rscript learn/R/pruebas/test_app_traspaso.R
#
# Vive aparte de test_app_metodo.R por C2: aquel recorre el metodo entero y ya
# roza el techo. Este arranca la app igual (C14, navegador de verdad) pero solo
# mira una cosa: llegar a ② sin haber pulsado "Guardar en Objetos" tiene que
# dejar el dataset de ① disponible igual, porque modelado.R lo guarda solo la
# primera vez. Y volver a ② despues de cambiar la fuente en ① NO tiene que
# guardar otro: el auto-guardado es una vez, no un versionado silencioso.

suppressPackageStartupMessages(library(shinytest2))
Sys.setenv(NOT_CRAN = "true")

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", substr(conditionMessage(e), 1, 300), "\n"); FALSE })
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
  app$wait_for_idle(duration = 400, timeout = 30000)
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

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-traspaso",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[① Datos · cargar SIN guardar en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "twins", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)
probar("twins carga en ①", grepl("183", esperar_html(app, "183"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[② Modelado · entrar sin haber guardado]\n")

# Ni un clic en datos-guardar: entrar a la sección tiene que bastar.
html_f2 <- ir_a(app, "② Modelado", "guardado como d1")
probar("entrar a ② auto-guarda el dataset de ① y lo avisa",
       grepl("guardado como d1", html_f2, fixed = TRUE))
probar("el selector queda apuntando al dataset nuevo",
       identical(app$get_value(input = "modelado-dataset"), "d1"))

app$click("modelado-elegir_acp")
app$wait_for_idle(duration = 1000, timeout = 30000)
html_spec <- esperar_html(app, "Matriz de diseño")
probar("elegir el ACP lleva a Especificación sin guardar a mano",
       grepl("Matriz de diseño", html_spec, fixed = TRUE))
probar("no queda el aviso de dataset faltante",
       !grepl("Elegí un dataset", html_spec, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[idempotencia · cambiar la fuente en ① no guarda otro]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "sintetico_regresion", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)

html_f2b <- ir_a(app, "② Modelado", "d1 ·")
probar("volver a ② conserva el único dataset guardado",
       !grepl("d2 ·", html_f2b, fixed = TRUE))
probar("y sigue seleccionado d1",
       identical(app$get_value(input = "modelado-dataset"), "d1"))

# ---------------------------------------------------------------------------
cat("\n[catálogo · el salto a ① Datos]\n")

app$set_inputs(`modelado-pestana` = "Catálogo", wait_ = FALSE)
html_cat <- esperar_html(app, "Ver en ① Datos")
probar("los pendientes con lógica en ① ofrecen el salto",
       grepl("ver_normalidad", html_cat, fixed = TRUE))
probar("los pendientes sin lógica siguen diciendo la verdad",
       grepl("Sin implementar", html_cat, fixed = TRUE))

app$click("modelado-ver_normalidad")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("el salto aterriza en ① Datos · Análisis",
       identical(app$get_value(input = "seccion"), "① Datos") &&
         identical(app$get_value(input = "datos-pestana"), "▣ Análisis"))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_traspaso] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
