# learn/R/pruebas/test_app_clases_latentes.R
#
# Responsabilidad: recorrer clases latentes por las cuatro fases, en un
# navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_clases_latentes.R
#
# Calcado de test_app_kmeans.R. Lo que este añade y aquel no puede dar:
#
#   · un dataset cualitativo de punta a punta (Zoo): la fase 2 tiene que
#     ofrecer factores, no números, y el identificador `animal` no puede
#     romper el ajuste aunque quede seleccionado;
#   · una traza que SUBE: la consola registra la log-verosimilitud;
#   · la fase 4 encendiendo las vistas cualitativas (modos, cruce con la clase
#     real, BIC) y apagando las que solo tienen sentido con centroides.

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

# Las quince binarias y `patas`. Fuera quedan `animal` (un nombre) y `tipo`
# (la respuesta: meterla es agrupar con la solución en la mano).
VARIABLES_ZOO <- c("pelo", "plumas", "huevos", "leche", "vuela", "acuatico",
                   "depredador", "dientes", "vertebrado", "respira",
                   "venenoso", "aletas", "patas", "cola", "domestico",
                   "tamano_gato")

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-clases-latentes",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · Zoo guardado en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "zoo", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)
app$click("datos-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el dataset queda guardado como objeto",
       grepl("d1", esperar_html(app, "d1"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 2 · clases latentes con columnas cualitativas]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_clases_latentes")
probar("clases latentes ofrece Elegir en el catálogo",
       grepl("elegir_clases_latentes", html_f2, fixed = TRUE))

app$click("modelado-elegir_clases_latentes")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("elegir clases latentes lleva a Especificación",
       grepl("Matriz de diseño", esperar_html(app, "Matriz de diseño"),
             fixed = TRUE))

# La fase 2 preselecciona todas las cualitativas, `tipo` incluida: la
# respuesta hay que sacarla a mano, y eso es lo que hace un usuario honesto.
probar("la fase ofrece las cualitativas de Zoo, no números",
       all(c("pelo", "patas") %in%
             app$get_value(input = "modelado-columnas")))
invisible(mover(app, `modelado-columnas` = VARIABLES_ZOO))
probar("las dieciséis variables quedan elegidas",
       setequal(app$get_value(input = "modelado-columnas"), VARIABLES_ZOO))

html_hiper <- ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                           "Número de clases")
probar("el formulario sale del registro de clases latentes (C11)",
       grepl("Número de clases", html_hiper, fixed = TRUE))

invisible(mover(app, `modelado-hiper_clases_latentes_k` = 4))
probar("el número de clases está enlazado",
       app$get_value(input = "modelado-hiper_clases_latentes_k") == 4)
invisible(mover(app, `modelado-hiper_clases_latentes_k_max` = 6))
probar("el K máximo de la tabla de BIC está enlazado",
       app$get_value(input = "modelado-hiper_clases_latentes_k_max") == 6)

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · EM, reinicios y la verosimilitud subiendo]\n")

invisible(ir_a(app, "③ Ajuste", "El algoritmo, paso a paso"))
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el optimizador que ofrece es el EM del registro",
       identical(app$get_value(input = "ajuste-optimizador"), "EM"))

html_control <- ir_a_pestana(app, "ajuste-pestana", "Control", "Reinicios")
invisible(mover(app, `ajuste-reinicios` = 5))
probar("el control expone reinicios y está enlazado",
       grepl("Reinicios", html_control, fixed = TRUE) &&
         app$get_value(input = "ajuste-reinicios") == 5)

invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 3000, timeout = 90000)
html_ajustado <- esperar_html(app, "log-verosimilitud=", intentos = 120)
probar("la consola registra la log-verosimilitud, no una inercia",
       grepl("log-verosimilitud=", html_ajustado, fixed = TRUE) &&
         !grepl("inercia intra-grupo=", html_ajustado, fixed = TRUE))
probar("ajustar deja la corrida convergida",
       grepl("convergio", html_ajustado, fixed = TRUE))
probar("la card se enciende porque el ajuste registró su estado",
       isTRUE(app$get_value(output = "ajuste-hay_estado_paso")))

app$click("ajuste-paso_adelante")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la reproducción avanza de a una iteración",
       app$get_value(input = "ajuste-paso") == 2)

app$click("ajuste-guardar_receta")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la receta queda guardada",
       grepl("Receta guardada", esperar_html(app, "Receta guardada"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 4 · las vistas cualitativas]\n")

invisible(ir_a(app, "④ Evaluación", "Compatibilidad"))
app$click("evaluacion-correr")
app$wait_for_idle(duration = 4000, timeout = 120000)
html_corrida <- esperar_html(app, "d1 x m1", intentos = 200)
probar("correr produce una corrida",
       grepl("d1 x m1", html_corrida, fixed = TRUE))

probar("la fase 4 enciende las vistas de clases latentes", {
  encendidas <- vapply(c("f4.diagnostico.bic", "f4.explicabilidad.modos",
                         "f4.desempeno.cruce_clase",
                         "f4.explicabilidad.mapa_2d"),
                       function(clave) bandera(app, "evaluacion", clave),
                       logical(1))
  if (!all(encendidas)) print(encendidas)
  all(encendidas)
})

probar("y apaga las del ACP y las de centroides", {
  apagadas <- vapply(c("f4.diagnostico.scree", "f4.explicabilidad.cargas",
                       "f4.explicabilidad.centroides", "f4.diagnostico.codo"),
                     function(clave) bandera(app, "evaluacion", clave),
                     logical(1))
  !any(apagadas)
})

html_desem <- ir_a_pestana(app, "evaluacion-pestana", "Desempeño", "BIC",
                           intentos = 160)
probar("el desempeño reporta el BIC del ajuste",
       grepl("BIC", html_desem, fixed = TRUE))

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe nombra el método",
       grepl("Clases latentes", html_informe, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_clases_latentes] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
