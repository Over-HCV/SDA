# learn/R/pruebas/test_app_piezas.R
#
# Responsabilidad: probar en un navegador de verdad la ENVOLTURA que comparten
# todas las cards — el sello ⓘ, las fórmulas y el sidebar.
#
# Uso:  Rscript learn/R/pruebas/test_app_piezas.R
#
# Vive aparte de test_app.R porque prueba otra cosa: aquel recorre el flujo de
# la fase 1, este mira las piezas de R/ui/piezas/ y R/nucleo/formulas.R, que son
# transversales a todas las fases. Partir por ese eje —y no por "parte 1 /
# parte 2"— es lo que pide C2.
#
# Las tres cosas que comprueba solo se rompen del lado del cliente:
#
#   - el sello ⓘ falla al clic si el foco cae sobre un <svg> aria-hidden. El
#     servidor no se entera: responde 200 y el popover queda muerto.
#   - las fórmulas las pinta KaTeX en el navegador. Si el asset no llega, el
#     HTML es correcto y el usuario ve TeX crudo.
#   - el sidebar pegado es CSS. R no puede verlo de ninguna otra forma.

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

#' Espera a que un texto aparezca en el DOM. Ver test_app.R para el porqué.
esperar_html <- function(app, patron, intentos = 40, pausa = 0.25) {
  for (i in seq_len(intentos)) {
    html <- app$get_html("body")
    if (grepl(patron, html, fixed = TRUE)) return(html)
    Sys.sleep(pausa)
  }
  app$get_html("body")
}

#' Cuántas veces aparece un texto en el DOM. La no-duplicación es una
#' aserción de conteo: que esté no alcanza, tiene que estar UNA vez.
veces_en <- function(patron, html) {
  length(gregexpr(patron, html, fixed = TRUE)[[1]][
    gregexpr(patron, html, fixed = TRUE)[[1]] > 0])
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

cat("\n[arranque]\n")
app <- AppDriver$new(app_dir = "learn/R", name = "sda-piezas",
                     load_timeout = 60000, timeout = 20000,
                     seed = 42, options = list(shiny.autoreload = FALSE))
on.exit(app$stop(), add = TRUE)
probar("la app carga", grepl("SDA Lab", app$get_html("body"), fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[sidebar con scroll propio]\n")
html_datos <- esperar_html(app, "sin cargar")
app$set_inputs(seccion = "① Datos")
html_datos <- esperar_html(app, "sin cargar")

probar("los controles se quedan pegados al desplazar",
       grepl("position: sticky", html_datos, fixed = TRUE))
probar("los controles tienen su propio scroll, no el del documento",
       grepl("overflow-y: auto", html_datos, fixed = TRUE))
probar("el alto de los controles está acotado al viewport",
       grepl("max-height: calc(100vh", html_datos, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[sello ⓘ: para qué sirve]\n")
probar("el disparador del sello es accesible, no un svg aria-hidden",
       grepl("aria-label=\"¿Para qué sirve?\"", html_datos, fixed = TRUE))
probar("ya no queda el rótulo viejo, que repetía el bloque Contexto",
       !grepl("De dónde sale este gráfico", html_datos, fixed = TRUE))
probar("el sello trae la utilidad de la card",
       grepl("Atrapar el desastre", html_datos, fixed = TRUE))
probar("la utilidad aparece UNA vez: el pie ya no la repite",
       veces_en("Atrapar el desastre", html_datos) == 1L)
probar("el pie conserva sus tres bloques",
       grepl("¿Cómo se lee?", html_datos, fixed = TRUE) &&
         grepl("Contexto", html_datos, fixed = TRUE))

# Sacar la traza del sello solo es aceptable si el bloque Contexto la ofrece,
# y ese bloque es opcional en la firma de panel_resultado(). Que el hueco esté
# es lo comprobable desde acá: el CONTENIDO no se puede leer sin abrir el
# acordeón, porque Bootstrap le pone display:none al panel plegado y Shiny
# suspende los outputs ocultos. Lo que sale por ese hueco lo aseveran
# test_headless.R (`contexto_de`) y la cuenta de abajo.
probar("toda card ofrece el hueco de Contexto, que es donde vive la traza",
       veces_en("Este bloque sirve para orientarse", html_datos) ==
         veces_en("aria-label=\"¿Para qué sirve?\"", html_datos))

app$set_inputs(`datos-fuente` = "sintetico_anova", wait_ = FALSE)
app$wait_for_idle(duration = 400, timeout = 20000)
app$click("datos-cargar")
invisible(esperar_html(app, "sintetico_anova"))

# ---------------------------------------------------------------------------
cat("\n[fórmulas: KaTeX de verdad]\n")
# Calidad tiene la fórmula más exigente que hay: tres filas alineadas con
# fracción, valor absoluto y chi cuadrado.
app$set_inputs(`datos-pestana` = "Calidad", wait_ = FALSE)
html_calidad <- esperar_html(app, "Matriz de nulidad")
app$wait_for_idle(duration = 400, timeout = 20000)
html_calidad <- esperar_html(app, "katex")

probar("KaTeX se cargó y pintó algo",
       grepl("class=\"katex", html_calidad, fixed = TRUE))
probar("la fórmula de bloque quedó marcada como renderizada",
       grepl("data-formula-lista", html_calidad, fixed = TRUE))
probar("el TeX original viaja en la anotación MathML",
       grepl("application/x-tex", html_calidad, fixed = TRUE))
probar("el alineador multi-fila sobrevivió hasta el navegador",
       grepl("begin{aligned}", html_calidad, fixed = TRUE))
probar("no queda ninguna fórmula sin pintar",
       !grepl("<div class=\"formula-bloque\">\\", html_calidad, fixed = TRUE))

# ---------------------------------------------------------------------------
cat("\n[consola del navegador]\n")
# Acá tiene que morir el aviso de aria-hidden que daba el sello viejo.
errores <- errores_de_consola(app)
probar("cero errores en la consola", length(errores) == 0)
if (length(errores)) for (e in utils::head(errores, 10)) cat("    ", e, "\n")

cat(sprintf("\n[test_app_piezas] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
