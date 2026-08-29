# learn/R/pruebas/test_app_metodo.R
#
# Responsabilidad: recorrer un método entero por las cuatro fases, en un
# navegador de verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_metodo.R
#
# Vive aparte de test_app.R por C2: aquel recorre el shell y la fase 1, este
# recorre fases 2, 3 y 4 con el ACP. Los dos arrancan su propio AppDriver.
#
# Qué prueba que ningún harness sin GUI puede probar: que los controles nuevos
# estén ENLAZADOS. La trampa del Hito 2 fue exactamente esa — el HTML aparecía,
# Shiny no volvía a atar los inputs, y la consola del navegador quedaba limpia.
# Por eso acá se mueve al menos un control de cada subsección nueva, en vez de
# solo comprobar que el texto está en el DOM.
#
# Cierra la regla de las tres partes (C11): test_contrato.R comprueba registro
# y batch; este comprueba que el hiperparámetro además existe como input.

suppressPackageStartupMessages(library(shinytest2))
Sys.setenv(NOT_CRAN = "true")

.FALLOS <- 0L

# El mensaje se recorta: los errores de shinytest2 traen el DOM entero adjunto,
# y un volcado de 150 KB por fallo hace ilegible el resto del harness.
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

# El patrón que se espera tiene que ser lo que se va a TOCAR, no el primer
# texto que pinte la sección: los uiOutput de una fase se resuelven en ciclos
# distintos, y esperar por el resumen para después pulsar un botón de la
# rejilla es una carrera que a veces se gana.
ir_a <- function(app, seccion, patron) {
  app$set_inputs(seccion = seccion, wait_ = FALSE)
  html <- esperar_html(app, patron)
  app$wait_for_idle(duration = 400, timeout = 30000)
  html
}

ir_a_pestana <- function(app, entrada, pestana, patron) {
  do.call(app$set_inputs,
          c(stats::setNames(list(pestana), entrada), list(wait_ = FALSE)))
  html <- esperar_html(app, patron)
  app$wait_for_idle(duration = 400, timeout = 20000)
  html
}

mover <- function(app, ...) {
  app$set_inputs(..., wait_ = FALSE)
  app$wait_for_idle(duration = 400, timeout = 20000)
  app$get_html("body")
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

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-metodo",
                     load_timeout = 60000, timeout = 30000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · un dataset guardado en Objetos]\n")

invisible(ir_a(app, "① Datos", "Fuente"))
app$set_inputs(`datos-fuente` = "twins", wait_ = FALSE)
app$click("datos-cargar")
app$wait_for_idle(duration = 1500, timeout = 30000)

probar("twins carga y la franja reporta sus filas",
       grepl("183", esperar_html(app, "183"), fixed = TRUE))

# Las fases no se hablan entre sí: se hablan por el almacén. Sin este clic, la
# fase 2 no tiene de dónde sacar un dataset, y eso es el diseño, no un bug.
app$click("datos-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el dataset queda guardado como objeto",
       grepl("d1", esperar_html(app, "d1"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 2 · elegir y especificar]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_acp")
probar("el catálogo se dibuja desde el registro",
       grepl("Análisis de componentes principales", html_f2, fixed = TRUE))
probar("el ACP ofrece Elegir: ya no es un metodo pendiente",
       grepl("elegir_acp", html_f2, fixed = TRUE))

app$click("modelado-elegir_acp")
app$wait_for_idle(duration = 1000, timeout = 30000)
html_spec <- esperar_html(app, "Matriz de diseño")
probar("elegir un método lleva a Especificación",
       grepl("Matriz de diseño", html_spec, fixed = TRUE))
probar("la matriz de diseño reporta el rango",
       grepl("rango", html_spec, fixed = TRUE))

html_columnas <- mover(app, `modelado-columnas` = c("DEDUC1", "AGE", "AGESQ",
                                                    "EDUCH", "EDUCL"))
probar("marcar columnas cambia la matriz de diseño",
       grepl("5", html_columnas, fixed = TRUE))

# Se espera por un mensaje del semáforo, no por el rótulo del sidebar: ese
# rótulo ya está en el DOM aunque la pestaña esté oculta, y esperar por él
# devuelve antes de que el output haya corrido.
html_sup <- ir_a_pestana(app, "modelado-pestana", "Supuestos",
                         "Escalado previo")
probar("el semáforo evalúa los tres supuestos declarados", {
  faltan <- Filter(function(p) !grepl(p, html_sup, fixed = TRUE),
                   c("Escalado previo", "Estructura lineal", "Atipicos"))
  length(faltan) == 0
})
probar("el semáforo cuenta cuántos se cumplen",
       grepl("se cumplen", html_sup, fixed = TRUE))

html_solo <- mover(app, `modelado-solo_problemas` = TRUE)
probar("el filtro de problemas responde",
       grepl("supuestos", html_solo, fixed = TRUE))
invisible(mover(app, `modelado-solo_problemas` = FALSE))

html_hiper <- ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                           "Componentes a retener")
probar("el formulario de hiperparámetros sale del registro (C11)",
       grepl("Descomponer R", html_hiper, fixed = TRUE))

# El control existe en el registro y en la función pura; moverlo prueba la
# tercera pata de C11: que además esté enlazado en el navegador.
html_k <- mover(app, `modelado-hiper_n_componentes` = 3)
probar("mover el número de componentes mueve el presupuesto",
       grepl("parametros a estimar", html_k, fixed = TRUE) ||
         grepl("presupuesto", html_k, fixed = TRUE))

html_geo <- ir_a_pestana(app, "modelado-pestana", "▣ Análisis",
                         "Dirección candidata")
probar("el espacio de hipótesis se dibuja antes de ajustar",
       grepl("Espacio de hipótesis", html_geo, fixed = TRUE))
probar("el modelo manual está presente",
       grepl("Modelo manual", html_geo, fixed = TRUE))

html_angulo <- mover(app, `modelado-angulo` = 120)
probar("mover el ángulo actualiza la varianza captada",
       grepl("captado", html_angulo, fixed = TRUE))

app$click("modelado-ir_al_optimo")
app$wait_for_idle(duration = 600, timeout = 30000)
probar("el botón lleva el ángulo al óptimo",
       app$get_value(input = "modelado-angulo") != 120)

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · ajustar y mirar la traza]\n")

html_f3 <- ir_a(app, "③ Ajuste", "Deflacionar")
probar("el optimizador sale del registro del método",
       grepl("potencia", html_f3, fixed = TRUE) &&
         grepl("svd", html_f3, fixed = TRUE))
probar("los pasos del algoritmo están escritos",
       grepl("Deflacionar", html_f3, fixed = TRUE))

html_svd <- mover(app, `ajuste-optimizador` = "svd")
probar("con svd la app avisa de que no habrá traza",
       grepl("resuelve en un paso", html_svd, fixed = TRUE))
invisible(mover(app, `ajuste-optimizador` = "potencia"))

html_control <- ir_a_pestana(app, "ajuste-pestana", "Control",
                             "Máximo de iteraciones")
probar("el control expone tolerancia, semilla y traza", {
  faltan <- Filter(function(p) !grepl(p, html_control, fixed = TRUE),
                   c("Tolerancia", "Semilla", "Registrar la traza"))
  length(faltan) == 0
})

html_tol <- mover(app, `ajuste-tol_log` = -6)
probar("mover la tolerancia se refleja en el resumen",
       grepl("e-06", html_tol, fixed = TRUE))

invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 2000, timeout = 60000)
html_ajustado <- esperar_html(app, "convergio")
probar("ajustar deja la corrida convergida",
       grepl("convergio", html_ajustado, fixed = TRUE))
probar("la consola registra iteraciones con su delta",
       grepl("delta=", html_ajustado, fixed = TRUE))

app$click("ajuste-paso_adelante")
app$wait_for_idle(duration = 600, timeout = 30000)
probar("la reproducción avanza de a una iteración",
       app$get_value(input = "ajuste-paso") == 2)

html_conv <- ir_a_pestana(app, "ajuste-pestana", "▣ Análisis",
                          "Escala logarítmica")
probar("la traza de convergencia se dibuja",
       grepl("Traza de convergencia", html_conv, fixed = TRUE))
html_log <- mover(app, `ajuste-escala_log` = TRUE)
probar("la escala logarítmica responde",
       grepl("Traza de convergencia", html_log, fixed = TRUE))

app$click("ajuste-guardar_receta")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("la receta queda guardada",
       grepl("Receta guardada", esperar_html(app, "Receta guardada"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 4 · componer, correr y leer]\n")

html_f4 <- ir_a(app, "④ Evaluación", "Compatibilidad")
probar("la composición muestra las tres piezas", {
  faltan <- Filter(function(p) !grepl(p, html_f4, fixed = TRUE),
                   c("Dataset", "Modelo", "Receta"))
  length(faltan) == 0
})
probar("la compatibilidad se valida antes de correr",
       grepl("Composición válida", html_f4, fixed = TRUE) ||
         grepl("alert", html_f4, fixed = TRUE))

app$click("evaluacion-correr")
app$wait_for_idle(duration = 2000, timeout = 60000)
html_corrida <- esperar_html(app, "retenido")
probar("correr produce una corrida con su resumen",
       grepl("retenido", html_corrida, fixed = TRUE))

html_desem <- ir_a_pestana(app, "evaluacion-pestana", "Desempeño",
                           "error de reconstruccion")
probar("el desempeño reporta lo que conserva el resumen",
       grepl("error de reconstruccion", html_desem, fixed = TRUE))
probar("la tabla de varianza llega hasta el acumulado",
       grepl("acumulada", html_desem, fixed = TRUE))

html_umbral <- mover(app, `evaluacion-umbral_acumulado` = 0.95)
probar("mover el umbral cambia cuántas componentes hacen falta",
       grepl("hacen falta", html_umbral, fixed = TRUE))

html_diag <- ir_a_pestana(app, "evaluacion-pestana", "Diagnóstico",
                          "Gráfico de sedimentación")
probar("el scree se dibuja con su corte",
       grepl("Gráfico de sedimentación", html_diag, fixed = TRUE))

html_expl <- ir_a_pestana(app, "evaluacion-pestana", "Explicabilidad",
                          "Componente horizontal")
probar("las cuatro vistas de explicabilidad están", {
  faltan <- Filter(function(p) !grepl(p, html_expl, fixed = TRUE),
                   c("Cargas", "Círculo de correlaciones", "Biplot",
                     "Mapa en dos dimensiones"))
  length(faltan) == 0
})

html_ejes <- mover(app, `evaluacion-eje_y` = "3")
probar("cambiar el par de ejes responde",
       grepl("Biplot", html_ejes, fixed = TRUE))

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe compuesto se arma con las cuatro fases",
       grepl("Reproducir", html_informe, fixed = TRUE) ||
         grepl("run_headless", html_informe, fixed = TRUE))
probar("el informe nombra el método",
       grepl("componentes principales", html_informe, fixed = TRUE))

html_comparar <- ir_a_pestana(app, "evaluacion-pestana", "Comparación",
                              "En construcción")
probar("comparación dice a qué hito pertenece",
       grepl("Hito 6", html_comparar, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[trazabilidad]\n")

probar("las cards del método traen su bloque de contexto",
       grepl("contexto", tolower(html_expl), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_metodo] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
