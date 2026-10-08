# learn/R/pruebas/test_app_jerarquico.R
#
# Responsabilidad: recorrer el agrupamiento jerárquico por las cuatro fases, en
# un navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_jerarquico.R
#
# Es el segundo método de la familia de grupos, y lo que prueba es justamente
# eso: que entró SIN vistas nuevas salvo las suyas. Lo que añade a
# test_app_kmeans.R:
#
#   · que los hiperparámetros propios (enlace, corte) estén enlazados — la
#     tercera pata de C11;
#   · que la fase 3 reproduzca el historial de fusiones como traza;
#   · que la fase 4 encienda dendrograma y cofenética y deje apagado el codo,
#     que es de k-medias.

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

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-jerarquico",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · un dataset guardado en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "twins", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)
app$click("datos-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el dataset queda guardado como objeto",
       grepl("d1", esperar_html(app, "d1"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 2 · el jerárquico ya no es un pendiente]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_jerarquico")
probar("el jerárquico ofrece Elegir en el catálogo",
       grepl("elegir_jerarquico", html_f2, fixed = TRUE))

app$click("modelado-elegir_jerarquico")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("elegirlo lleva a Especificación",
       grepl("Matriz de diseño", esperar_html(app, "Matriz de diseño"),
             fixed = TRUE))

# Las mismas columnas sin faltantes que test_app_kmeans.R: `faltantes = FALSE`.
invisible(mover(app, `modelado-columnas` = c("DEDUC1", "AGE", "AGESQ",
                                             "EDUCH", "EDUCL")))

html_sup <- ir_a_pestana(app, "modelado-pestana", "Supuestos", "Distancia: ", intentos = 120)
probar("el semáforo evalúa la distancia, sin 'sin comprobacion'",
       grepl("Distancia:", html_sup, fixed = TRUE) &&
         !grepl("sin comprobacion automatica", html_sup, fixed = TRUE))

html_hiper <- ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                           "Criterio de enlace")
probar("el formulario sale del registro del jerárquico (C11)",
       grepl("Grupos al cortar el dendrograma", html_hiper, fixed = TRUE))

invisible(mover(app, `modelado-hiper_jerarquico_enlace` = "average"))
probar("el enlace está enlazado",
       app$get_value(input = "modelado-hiper_jerarquico_enlace") == "average")
invisible(mover(app, `modelado-hiper_jerarquico_k_corte` = 4))
probar("el corte está enlazado",
       app$get_value(input = "modelado-hiper_jerarquico_k_corte") == 4)

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · el historial de fusiones como traza]\n")

html_f3 <- ir_a(app, "③ Ajuste", "Fusionar los dos mas cercanos")
probar("el optimizador es el aglomerativo, con sus pasos escritos",
       grepl("aglomerativo", html_f3, fixed = TRUE) &&
         grepl("Fusionar los dos mas cercanos", html_f3, fixed = TRUE))

invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 3000, timeout = 90000)
html_ajustado <- esperar_html(app, "altura de fusion=")
probar("la consola registra las alturas de fusión",
       grepl("altura de fusion=", html_ajustado, fixed = TRUE))
probar("sin asignaciones por iteración, la card de estado no se enciende",
       !isTRUE(app$get_value(output = "ajuste-hay_estado_paso")))

app$click("ajuste-paso_adelante")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la reproducción avanza de a una fusión",
       app$get_value(input = "ajuste-paso") == 2)

app$click("ajuste-guardar_receta")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la receta se guarda",
       grepl("Receta guardada", esperar_html(app, "Receta guardada"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 4 · el registro decide qué se dibuja]\n")

invisible(ir_a(app, "④ Evaluación", "Compatibilidad"))
app$click("evaluacion-correr")
app$wait_for_idle(duration = 4000, timeout = 120000)
html_corrida <- esperar_html(app, "d1 x m1", intentos = 200)
probar("correr produce una corrida con el resumen del jerárquico",
       grepl("d1 x m1", html_corrida, fixed = TRUE) &&
         grepl("cofenética", html_corrida, fixed = TRUE))

probar("enciende dendrograma, cofenética y las vistas de grupos", {
  encendidas <- vapply(c("f4.diagnostico.dendrograma",
                         "f4.diagnostico.cofenetico", "f4.diagnostico.silueta",
                         "f4.desempeno.grupos", "f4.explicabilidad.mapa_2d",
                         "f4.explicabilidad.centroides"),
                       function(clave) bandera(app, "evaluacion", clave),
                       logical(1))
  all(encendidas)
})

probar("y deja apagados el codo de k-medias y el scree del ACP",
       !bandera(app, "evaluacion", "f4.diagnostico.codo") &&
         !bandera(app, "evaluacion", "f4.diagnostico.scree"))

html_desem <- ir_a_pestana(app, "evaluacion-pestana", "Desempeño",
                           "sobrevive a otro enlace", intentos = 160)
probar("el desempeño trae la correlación cofenética",
       grepl("correlacion cofenetica", html_desem, fixed = TRUE) &&
         grepl("grupo mas chico", html_desem, fixed = TRUE))
probar("la lectura habla del enlace, no de la semilla",
       grepl("sobrevive a otro enlace", html_desem, fixed = TRUE))

html_diag <- ir_a_pestana(app, "evaluacion-pestana", "Diagnóstico",
                          "Índices internos", intentos = 160)
# Un renderPlot que falla no deja rastro en la consola del navegador: deja un
# div de error donde iba la imagen. Se asevera que la imagen está.
dibujada <- function(id) {
  for (i in seq_len(80)) {
    html <- app$get_html(paste0("#", id))
    if (grepl("<img", html, fixed = TRUE)) return(TRUE)
    if (grepl("shiny-output-error", html, fixed = TRUE)) return(FALSE)
    Sys.sleep(0.25)
  }
  FALSE
}
probar("el dendrograma se dibuja", dibujada("evaluacion-dendrograma"))
probar("la cofenética se dibuja", dibujada("evaluacion-cofenetico"))
probar("el dendrograma ya no figura entre lo que falta",
       !grepl("Dendrograma e índices internos", html_diag, fixed = TRUE))

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe nombra el método",
       grepl("Agrupamiento jerárquico", html_informe, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_jerarquico] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
