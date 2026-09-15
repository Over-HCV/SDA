# learn/R/pruebas/test_app_sesion.R
#
# Responsabilidad: probar en un navegador de verdad que una sesión se abre, se
# modifica, se guarda y vuelve a abrirse en una app nueva sin perder nada.
#
# Uso:  Rscript learn/R/pruebas/test_app_sesion.R
#
# Vive aparte de test_app.R por C2: aquel recorre la fase 1; este, lo que pasa
# entre dos arranques de la app. La mitad sin navegador está en test_sesion.R.

suppressPackageStartupMessages(library(shinytest2))

Sys.setenv(NOT_CRAN = "true")

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

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

# ---------------------------------------------------------------------------
cat("\n[sesión guardada · arrancar con todo puesto]\n")
# La app abierta con SDA_SESION: el caso de uso es entrar al lab y encontrar el
# filtro aplicado, el diccionario declarado y los paneles del taller marcados,
# en vez de rehacer los clics cada vez.
app2 <- local({
  Sys.setenv(SDA_SESION = "sesiones/taller-01.json")
  on.exit(Sys.unsetenv("SDA_SESION"), add = TRUE)
  AppDriver$new(app_dir = "learn/R", name = "sda-lab-sesion",
                load_timeout = 60000, timeout = 20000, seed = 42,
                options = list(shiny.autoreload = FALSE))
})
on.exit(app2$stop(), add = TRUE)

probar("al abrir con una sesión, el dataset ya está cargado y filtrado",
       grepl("ori · 118 x 18", esperar_html(app2, "ori · 118 x 18"),
             fixed = TRUE))
# Se espera por el texto de la caja de lectura y no por el conteo: el
# encabezado se pinta un ciclo antes que la lista de paneles.
html_sesion <- ir_a(app2, "Informe", "va al cuaderno")
probar("y los paneles del taller ya están en el cuaderno, sin duplicarse", {
  # Restaurar re-marca las casillas de ① Datos, y cada marca dispara el
  # observador que añade: sin la guarda de identidad, los 14 se volvían 24.
  grepl("14 paneles", html_sesion, fixed = TRUE) &&
    grepl("Resumen numérico", html_sesion, fixed = TRUE)
})
probar("la lectura de cada panel tiene dónde escribirse",
       grepl("va al cuaderno", html_sesion, fixed = TRUE))
html_inicio <- ir_a(app2, "Inicio", "paneles marcados")
probar("Inicio muestra la sesión abierta: dataset, filtro y paneles", {
  grepl("118 de 4.543 filas", html_inicio, fixed = TRUE) &&
    grepl("filtro Hora en [12:00]", html_inicio, fixed = TRUE) &&
    grepl("14 paneles marcados", html_inicio, fixed = TRUE)
})
probar("Inicio ofrece guardar y abrir la sesión, con la de ejemplo",
       grepl("Guardar JSON", html_inicio, fixed = TRUE) &&
         grepl("taller-01", html_inicio, fixed = TRUE))
probar("recién abierta, la sesión no cuenta como cambios sin guardar",
       !grepl("Cambios sin guardar", html_inicio, fixed = TRUE))

# Guardar, cerrar y volver a abrir: lo que antes se perdía al recargar.
invisible(ir_a(app2, "Informe", "va al cuaderno"))
app2$set_inputs(`informe-nota_p1` = "Lectura escrita antes de guardar.",
                wait_ = FALSE)
app2$wait_for_idle(duration = 1200, timeout = 20000)
html_pendiente <- ir_a(app2, "Inicio", "Cambios sin guardar")
probar("escribir una lectura marca cambios sin guardar",
       grepl("Cambios sin guardar", html_pendiente, fixed = TRUE))
archivo_guardado <- app2$get_download("inicio-bajar_json")
probar("la sesión guardada lleva la lectura escrita", {
  leida <- jsonlite::fromJSON(archivo_guardado, simplifyVector = FALSE)
  any(vapply(leida$fase1$seleccion, function(e)
    identical(e$nota, "Lectura escrita antes de guardar."), logical(1)))
})
probar("después de guardar ya no hay cambios pendientes",
       !grepl("Cambios sin guardar",
              esperar_html(app2, "Guardada o abierta"), fixed = TRUE))
probar("cero errores de consola al restaurar",
       length(errores_de_consola(app2)) == 0)

app3 <- AppDriver$new(app_dir = "learn/R", name = "sda-lab-reabrir",
                      load_timeout = 60000, timeout = 20000, seed = 42,
                      options = list(shiny.autoreload = FALSE))
on.exit(app3$stop(), add = TRUE)
# Subir apenas arranca la app se perdía a veces: se espera a que Inicio pinte.
invisible(esperar_html(app3, "Dataset"))
app3$upload_file(`inicio-subir` = archivo_guardado)
html_reabierta <- esperar_html(app3, "14 paneles marcados", intentos = 160)
probar("una app nueva abre el archivo guardado con todo puesto",
       grepl("118 de 4.543 filas", html_reabierta, fixed = TRUE) &&
         grepl("1 con lectura", html_reabierta, fixed = TRUE))
html_lectura <- ir_a(app3, "Informe", "Lectura escrita antes de guardar.")
probar("y la lectura vuelve a su caja",
       grepl("Lectura escrita antes de guardar.", html_lectura, fixed = TRUE))

cat(sprintf("\n[test_app_sesion] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
