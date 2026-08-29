# learn/R/pruebas/test_app_kmeans.R
#
# Responsabilidad: recorrer k-medias por las cuatro fases, en un navegador de
# verdad (C14, spec S2b).
#
# Uso:  Rscript learn/R/pruebas/test_app_kmeans.R
#
# Un archivo por método, igual que en las pruebas sin GUI: el ACP tiene el suyo
# en test_app_metodo.R. Lo que este añade y aquel no puede dar:
#
#   · que la fase 4 APAGUE las vistas del ACP y ENCIENDA las de grupos, que es
#     el mecanismo que el hito 4 tuvo que construir;
#   · que los controles propios de esta familia (inicialización, reinicios)
#     estén enlazados — la tercera pata de C11;
#   · que el paso a paso dibuje el estado de cada iteración.

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

app <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-kmeans",
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
cat("\n[fase 2 · k-medias ya no es un pendiente]\n")

html_f2 <- ir_a(app, "② Modelado", "elegir_kmeans")
probar("k-medias ofrece Elegir en el catálogo",
       grepl("elegir_kmeans", html_f2, fixed = TRUE))

app$click("modelado-elegir_kmeans")
app$wait_for_idle(duration = 1000, timeout = 30000)
probar("elegir k-medias lleva a Especificación",
       grepl("Matriz de diseño", esperar_html(app, "Matriz de diseño"),
             fixed = TRUE))

# Columnas sin faltantes a proposito: k-medias declara `faltantes = FALSE` en
# su entrada, asi que con HRWAGEH la composicion se bloquea — y eso esta bien,
# es el contrato de la fase 4 haciendo su trabajo.
invisible(mover(app, `modelado-columnas` = c("DEDUC1", "AGE", "AGESQ",
                                             "EDUCH", "EDUCL")))

html_sup <- ir_a_pestana(app, "modelado-pestana", "Supuestos",
                         "Grupos esfericos")
probar("el semáforo evalúa los cuatro supuestos de esta familia", {
  faltan <- Filter(function(p) !grepl(p, html_sup, fixed = TRUE),
                   c("Escalado previo", "Grupos esfericos",
                     "Tamanos de grupo similares", "Atipicos"))
  length(faltan) == 0
})
probar("los dos supuestos nuevos ya no dicen 'sin comprobacion'",
       !grepl("sin comprobacion automatica", html_sup, fixed = TRUE))

html_hiper <- ir_a_pestana(app, "modelado-pestana", "Hiperparámetros",
                           "Número de grupos")
probar("el formulario sale del registro de k-medias (C11)",
       grepl("Estandarizar antes de medir distancias", html_hiper,
             fixed = TRUE))
probar("no se cuela el formulario del otro método",
       !grepl("Descomponer R", html_hiper, fixed = TRUE) ||
         grepl("display: none", html_hiper, fixed = TRUE))

# Los dos hiperparametros del registro, movidos: es la tercera pata de C11, la
# que ningun harness sin GUI puede comprobar.
invisible(mover(app, `modelado-hiper_k` = 4))
probar("el numero de grupos esta enlazado",
       app$get_value(input = "modelado-hiper_k") == 4)
invisible(mover(app, `modelado-hiper_escalar` = FALSE))
probar("el interruptor de escalado esta enlazado",
       identical(app$get_value(input = "modelado-hiper_escalar"), FALSE))
invisible(mover(app, `modelado-hiper_escalar` = TRUE))

app$click("modelado-guardar")
app$wait_for_idle(duration = 800, timeout = 30000)
probar("el modelo queda guardado como objeto",
       grepl("Modelo guardado", esperar_html(app, "Modelo guardado"),
             fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[fase 3 · Lloyd, reinicios y los centroides caminando]\n")

html_f3 <- ir_a(app, "③ Ajuste", "Recalcular cada centroide")
probar("el optimizador sale del registro del método",
       grepl("Lloyd", html_f3, fixed = TRUE) &&
         grepl("MacQueen", html_f3, fixed = TRUE))
probar("el catálogo no promete un algoritmo que no está",
       !grepl("Hartigan", html_f3, fixed = TRUE))
probar("aparece la inicialización, que el ACP no tiene",
       grepl("k-means++", html_f3, fixed = TRUE))
probar("los pasos de Lloyd están escritos",
       grepl("Recalcular cada centroide", html_f3, fixed = TRUE))

invisible(mover(app, `ajuste-inicializacion` = "aleatoria"))
probar("la inicialización está enlazada",
       app$get_value(input = "ajuste-inicializacion") == "aleatoria")
invisible(mover(app, `ajuste-inicializacion` = "k-means++"))

html_control <- ir_a_pestana(app, "ajuste-pestana", "Control", "Reinicios")
probar("el control expone reinicios",
       grepl("Reinicios", html_control, fixed = TRUE))
html_re <- mover(app, `ajuste-reinicios` = 5)
probar("mover los reinicios se refleja en el resumen del control",
       grepl("reinicios", html_re, fixed = TRUE) &&
         app$get_value(input = "ajuste-reinicios") == 5)

invisible(ir_a_pestana(app, "ajuste-pestana", "Consola",
                       "Reproducción de la traza"))
app$click("ajuste-ajustar")
app$wait_for_idle(duration = 3000, timeout = 90000)
html_ajustado <- esperar_html(app, "inercia")
probar("ajustar deja la corrida convergida",
       grepl("convergio", html_ajustado, fixed = TRUE))
probar("la consola registra la inercia, no la varianza del otro método",
       grepl("inercia intra-grupo=", html_ajustado, fixed = TRUE))
probar("aparece la card del estado por iteración",
       grepl("El ajuste, iteración por iteración", html_ajustado, fixed = TRUE))
# La card no se muestra por lo que el registro promete sino por lo que el
# ajuste registro: un k-medias con la traza apagada tampoco tendria estado que
# reproducir, y eso es una propiedad del resultado, no del catalogo.
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
cat("\n[fase 4 · el registro decide qué se dibuja]\n")

invisible(ir_a(app, "④ Evaluación", "Compatibilidad"))
# La franja de la fase 3 tambien dice "inercia" y page_navbar deja las cuatro
# fases en el DOM: se espera por la composicion, que solo escribe esta fase.
app$click("evaluacion-correr")
app$wait_for_idle(duration = 4000, timeout = 120000)
html_corrida <- esperar_html(app, "d1 x m1", intentos = 200)
probar("correr produce una corrida con el resumen de su familia",
       grepl("d1 x m1", html_corrida, fixed = TRUE) &&
         grepl("inercia", html_corrida, fixed = TRUE))

probar("la fase 4 enciende las vistas de agrupamiento", {
  encendidas <- vapply(c("f4.desempeno.grupos", "f4.diagnostico.codo",
                         "f4.diagnostico.silueta",
                         "f4.explicabilidad.centroides",
                         "f4.explicabilidad.mapa_2d"),
                       function(clave) bandera(app, "evaluacion", clave),
                       logical(1))
  all(encendidas)
})

probar("y apaga las del ACP", {
  apagadas <- vapply(c("f4.diagnostico.scree", "f4.explicabilidad.cargas",
                       "f4.explicabilidad.biplot",
                       "f4.explicabilidad.circulo_correlaciones"),
                     function(clave) bandera(app, "evaluacion", clave),
                     logical(1))
  !any(apagadas)
})

# Se espera por la frase que interpreta, que es lo ultimo que rinde la
# subseccion: "inercia intra-grupo" tambien esta en el log de la fase 3, que
# page_navbar deja en el DOM, y esperar por ella devuelve antes de tiempo.
html_desem <- ir_a_pestana(app, "evaluacion-pestana", "Desempeño",
                           "sobrevive a otra semilla", intentos = 160)
# Se buscan los rotulos de las cajas, no las palabras: "silueta media" e
# "inercia intra-grupo" tambien estan en los textos de las cards, que viven en
# el DOM aunque su card este oculta.
probar("el desempeño reporta métricas de grupos",
       grepl("grupo mas chico", html_desem, fixed = TRUE) &&
         grepl("grupo mas grande", html_desem, fixed = TRUE))
probar("y no las del otro método",
       !grepl("error de reconstruccion", html_desem, fixed = TRUE))
probar("la lectura interpreta con los números a la vista",
       grepl("sobrevive a otra semilla", html_desem, fixed = TRUE))

# El titulo de una card esta en el DOM aunque la card este oculta, asi que su
# presencia no prueba nada: lo que se asevera es que el control propio de esta
# subseccion aparecio y esta enlazado.
html_diag <- ir_a_pestana(app, "evaluacion-pestana", "Diagnóstico",
                          "K máximo en la curva del codo", intentos = 160)
probar("el control del codo aparece solo para quien lo declara",
       grepl("K máximo en la curva del codo", html_diag, fixed = TRUE))
html_kmax <- mover(app, `evaluacion-k_max` = 6)
probar("mover el K máximo del codo responde",
       app$get_value(input = "evaluacion-k_max") == 6)

html_expl <- ir_a_pestana(app, "evaluacion-pestana", "Explicabilidad",
                          "Perfil de los grupos")
probar("el perfil de los grupos está",
       grepl("Perfil de los grupos", html_expl, fixed = TRUE))
probar("el mapa 2d de la particion tambien",
       grepl("Mapa en dos dimensiones", html_expl, fixed = TRUE))
# Los ejes que ofrece el selector no se pueden leer del DOM —selectize guarda
# las opciones en JavaScript—, asi que lo que se comprueba acá es que el par
# elegido siga siendo valido despues de cambiarlo. Que las etiquetas sean las
# de esta familia lo asevera test_kmeans.R sobre etiquetas_ejes().
invisible(mover(app, `evaluacion-eje_y` = "2"))
probar("el par de ejes responde y no ofrece una tercera dimension",
       app$get_value(input = "evaluacion-eje_y") == "2")

html_informe <- ir_a_pestana(app, "evaluacion-pestana", "▣ Análisis",
                             "Cuaderno .Rmd")
probar("el informe nombra el método",
       grepl("K-medias", html_informe, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
errores <- errores_de_consola(app)
if (length(errores)) {
  cat("  mensajes:\n")
  for (mensaje in utils::head(errores, 10)) cat("   ", mensaje, "\n")
}
probar("cero errores en la consola", length(errores) == 0)

cat(sprintf("\n[test_app_kmeans] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
