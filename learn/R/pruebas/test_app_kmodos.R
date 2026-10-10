# learn/R/pruebas/test_app_kmodos.R
#
# Responsabilidad: recorrer k-modas por las cuatro fases sobre Zoo, en un
# navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_kmodos.R
#
# El molde es test_app_kmeans.R. Lo que este añade y aquel no puede dar:
#
#   · que una fuente cualitativa llegue entera a la fase 2 y que el método
#     ofrezca sus columnas (entrada `matriz_cualitativa`), no las numéricas;
#   · que la fase 3 hable de disimilitud y no de inercia, y que el paso a paso
#     funcione con modas en vez de centroides;
#   · que la fase 4 encienda las vistas de la familia cualitativa y apague las
#     que suponen una matriz numérica (centroides, cargas).

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

# Las dieciséis variables de entrada: todo menos el nombre y la respuesta.
ENTRADA_ZOO <- setdiff(names(cargar_zoo()), c("animal", "tipo"))

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-kmodos",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · Zoo guardado en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "zoo", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)
probar("zoo carga sus 101 animales",
       grepl("101", esperar_html(app, "101"), fixed = TRUE))
app$click("datos-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el dataset queda guardado como objeto",
       grepl("d1", esperar_html(app, "d1"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 2 · k-modas en el catálogo]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_kmodos")
probar("k-modas ofrece Elegir en el catálogo",
       grepl("elegir_kmodos", html_f2, fixed = TRUE))

app$click("modelado-elegir_kmodos")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("elegir k-modas lleva a Especificación",
       grepl("Matriz de diseño", esperar_html(app, "Matriz de diseño"),
             fixed = TRUE))

# `tipo` se deja afuera a proposito: es la clase real, y agrupar con ella
# adentro es agrupar con la respuesta en la mano.
invisible(mover(app, `modelado-columnas` = ENTRADA_ZOO))
probar("las columnas cualitativas quedan elegidas, sin la clase real", {
  elegidas <- app$get_value(input = "modelado-columnas")
  setequal(elegidas, ENTRADA_ZOO) && !"tipo" %in% elegidas
})

html_hiper <- ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                           "Número de grupos")
probar("el formulario sale del registro de k-modas (C11)",
       grepl("Número de grupos", html_hiper, fixed = TRUE))
invisible(mover(app, `modelado-hiper_kmodos_k` = 7))
probar("el numero de grupos esta enlazado",
       app$get_value(input = "modelado-hiper_kmodos_k") == 7)

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · Huang, arranques y las modas caminando]\n")

html_f3 <- ir_a(app, "③ Ajuste", "Huang")
probar("el optimizador sale del registro del método",
       grepl("Huang", html_f3, fixed = TRUE))
probar("no se cuela el arranque de k-medias",
       !grepl("k-means++", html_f3, fixed = TRUE) ||
         grepl("display: none", html_f3, fixed = TRUE))

invisible(mover(app, `ajuste-inicializacion` = "Cao"))
probar("la inicialización está enlazada y ofrece Cao",
       app$get_value(input = "ajuste-inicializacion") == "Cao")
invisible(mover(app, `ajuste-inicializacion` = "Huang"))

invisible(ir_a_pestana(app, "ajuste-pestana", "Control", "Reinicios"))
invisible(mover(app, `ajuste-reinicios` = 5))
probar("los reinicios están enlazados",
       app$get_value(input = "ajuste-reinicios") == 5)

invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 3000, timeout = 90000)
html_ajustado <- esperar_html(app, "disimilitud intra-grupo=")
probar("ajustar deja la corrida convergida",
       grepl("convergio", html_ajustado, fixed = TRUE))
probar("la consola registra la disimilitud, no la inercia",
       grepl("disimilitud intra-grupo=", html_ajustado, fixed = TRUE))
probar("la card se enciende porque el ajuste registro su estado",
       isTRUE(app$get_value(output = "ajuste-hay_estado_paso")))

app$click("ajuste-paso_adelante")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la reproducción avanza de a una iteración",
       app$get_value(input = "ajuste-paso") == 2)

app$click("ajuste-guardar_receta")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la receta guarda los mandos de esta familia",
       grepl("Receta guardada", esperar_html(app, "Receta guardada"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 4 · las vistas de la familia cualitativa]\n")

invisible(ir_a(app, "④ Evaluación", "Compatibilidad"))
app$click("evaluacion-correr")
app$wait_for_idle(duration = 4000, timeout = 120000)
html_corrida <- esperar_html(app, "d1 x m1", intentos = 200)
probar("correr produce una corrida",
       grepl("d1 x m1", html_corrida, fixed = TRUE))

probar("la fase 4 enciende las vistas de k-modas", {
  encendidas <- vapply(c("f4.desempeno.grupos", "f4.explicabilidad.modos",
                         "f4.desempeno.cruce_clase",
                         "f4.explicabilidad.mapa_2d"),
                       function(clave) bandera(app, "evaluacion", clave),
                       logical(1))
  if (!all(encendidas))
    cat("    apagadas:", names(encendidas)[!encendidas], "\n")
  all(encendidas)
})

probar("y apaga las que suponen una matriz numérica", {
  # El codo ya no está acá: k-modas lo dibuja con los desacuerdos por k.
  apagadas <- vapply(c("f4.explicabilidad.centroides",
                       "f4.diagnostico.scree", "f4.explicabilidad.cargas"),
                     function(clave) bandera(app, "evaluacion", clave),
                     logical(1))
  !any(apagadas)
})

html_desem <- ir_a_pestana(app, "evaluacion-pestana", "Desempeño",
                           "grupo mas grande", intentos = 160)
probar("el desempeño reporta los tamaños de los grupos",
       grepl("grupo mas chico", html_desem, fixed = TRUE) &&
         grepl("grupo mas grande", html_desem, fixed = TRUE))
probar("y no las métricas de la reducción",
       !grepl("error de reconstruccion", html_desem, fixed = TRUE))

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe nombra el método",
       grepl("K-modas", html_informe, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_kmodos] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
