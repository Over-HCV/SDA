# learn/R/pruebas/test_app_gower.R
#
# Responsabilidad: recorrer el agrupamiento de Gower por las cuatro fases, en
# un navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_gower.R
#
# Es el primer agrupamiento que entra por columnas CUALITATIVAS, y lo que
# prueba es eso: que la fase 2 ofrezca los atributos del zoológico en vez de
# las numéricas, que los cuatro hiperparámetros propios (k, estrategia,
# enlace, binarias asimétricas) estén enlazados —la tercera pata de C11—, que
# la fase 3 reproduzca las fusiones del árbol sobre Gower y que la fase 4
# dibuje el dendrograma con la misma pieza que el jerárquico numérico.

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

ir_a_pestana <- function(app, entrada, pestana, patron, intentos = 60) {
  do.call(app$set_inputs,
          c(stats::setNames(list(pestana), entrada), list(wait_ = FALSE)))
  html <- esperar_html(app, patron, intentos = intentos)
  app$wait_for_idle(duration = 400, timeout = 20000)
  html
}

mover <- function(app, ...) {
  app$set_inputs(..., wait_ = FALSE)
  app$wait_for_idle(duration = 400, timeout = 20000)
  app$get_html("body")
}

bandera <- function(app, modulo, clave)
  isTRUE(app$get_value(output = paste0(modulo, "-", bandera_artefacto(clave))))

errores_de_consola <- function(app) {
  registro <- app$get_logs()
  if (is.null(registro) || !nrow(registro)) return(character(0))
  filas <- registro[registro$level %in% c("error", "SEVERE") |
                      registro$location == "shiny_console", ]
  mensajes <- as.character(filas$message)
  mensajes[!grepl("favicon|DevTools listening|Download the React",
                  mensajes, ignore.case = TRUE)]
}

# Un renderPlot que falla no deja rastro en la consola del navegador: deja un
# div de error donde iba la imagen. Se asevera que la imagen está.
dibujada <- function(app, id) {
  for (i in seq_len(80)) {
    html <- app$get_html(paste0("#", id))
    if (grepl("<img", html, fixed = TRUE)) return(TRUE)
    if (grepl("shiny-output-error", html, fixed = TRUE)) return(FALSE)
    Sys.sleep(0.25)
  }
  FALSE
}

# Las 16 variables del zoológico: ni `animal` (la etiqueta de cada fila) ni
# `tipo` (la clase real, que solo sirve para validar).
VARIABLES_ZOO <- c("pelo", "plumas", "huevos", "leche", "vuela", "acuatico",
                   "depredador", "dientes", "vertebrado", "respira",
                   "venenoso", "aletas", "patas", "cola", "domestico",
                   "tamano_gato")

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-gower",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · el zoológico guardado en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "zoo", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)
app$click("datos-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el dataset queda guardado como objeto",
       grepl("d1", esperar_html(app, "d1"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 2 · Gower entra por las columnas cualitativas]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_gower")
probar("Gower ofrece Elegir en el catálogo",
       grepl("elegir_gower", html_f2, fixed = TRUE))

app$click("modelado-elegir_gower")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("elegirlo lleva a Especificación",
       grepl("Matriz de diseño", esperar_html(app, "Matriz de diseño"),
             fixed = TRUE))

invisible(mover(app, `modelado-columnas` = VARIABLES_ZOO))
probar("las columnas elegidas son los atributos, sin la clase real",
       setequal(app$get_value(input = "modelado-columnas"), VARIABLES_ZOO))

invisible(ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                       "hiper_gower_estrategia"))
invisible(mover(app, `modelado-hiper_gower_estrategia` = "jerarquico"))
probar("la estrategia está enlazada",
       app$get_value(input = "modelado-hiper_gower_estrategia") == "jerarquico")
invisible(mover(app, `modelado-hiper_gower_enlace` = "average"))
probar("el enlace está enlazado",
       app$get_value(input = "modelado-hiper_gower_enlace") == "average")
invisible(mover(app, `modelado-hiper_gower_k` = 7))
probar("k está enlazado", app$get_value(input = "modelado-hiper_gower_k") == 7)
invisible(mover(app, `modelado-hiper_gower_binarias_asimetricas` = TRUE))
probar("el interruptor de binarias asimétricas está enlazado",
       isTRUE(app$get_value(input = "modelado-hiper_gower_binarias_asimetricas")))

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · las fusiones del árbol sobre Gower]\n")

invisible(ir_a(app, "③ Ajuste", "Consola"))
invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 3000, timeout = 90000)
probar("la consola registra las alturas de fusión",
       grepl("altura de fusion=", esperar_html(app, "altura de fusion="),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 4 · el registro decide qué se dibuja]\n")

invisible(ir_a(app, "④ Evaluación", "Compatibilidad"))
app$click("evaluacion-correr")
app$wait_for_idle(duration = 4000, timeout = 120000)
html_corrida <- esperar_html(app, "d1 x m1", intentos = 200)
probar("correr produce una corrida", grepl("d1 x m1", html_corrida, fixed = TRUE))

probar("enciende el dendrograma y el tamaño de los grupos",
       bandera(app, "evaluacion", "f4.diagnostico.dendrograma") &&
         bandera(app, "evaluacion", "f4.desempeno.grupos"))
# El codo sí se enciende: el cualitativo dibuja la d de la partición por k.
probar("enciende el codo de Gower y deja apagado el scree del ACP",
       bandera(app, "evaluacion", "f4.diagnostico.codo") &&
         !bandera(app, "evaluacion", "f4.diagnostico.scree"))

invisible(ir_a_pestana(app, "evaluacion-pestana", "Diagnóstico",
                       "Dendrograma", intentos = 160))
probar("el dendrograma se dibuja", dibujada(app, "evaluacion-dendrograma"))

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe nombra el método", grepl("Gower", html_informe, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_gower] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
