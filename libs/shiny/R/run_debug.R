# libs/shiny/R/run_debug.R
#
# Entrada de DEPURACION. Levanta la misma app que app.R, pero con todo el
# instrumental encendido. app.R queda limpio: el modo debug es explicito.
#
# Uso (desde la raiz del proyecto):
#   Rscript -e 'source("libs/shiny/R/run_debug.R")'
#
# Que agrega sobre app.R:
#   1. Stack traces completos      -> shiny.fullstacktrace / sanitizeErrors=FALSE
#   2. Errores visibles en la UI   -> shiny.error = printea el traceback
#   3. Grafo reactivo              -> Ctrl+F3 en el navegador (reactlog)
#   4. Widget de theming en vivo   -> SDA_THEMER=1 (bs_themer)
#   5. Info del navegador/sesion   -> shinybrowser, si esta instalado
#
# Variables de entorno que respeta:
#   SDA_TEMA=retro    preset inicial
#   SDA_PORT=4568     puerto (default 4568)

.raiz_debug <- (function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
    d <- p
  }
})()

# --- 1-2. Errores sin censura -------------------------------------------
# Por defecto Shiny reemplaza el mensaje de error por "An error has occurred".
# En debug queremos el texto real y el traceback completo.
options(
  shiny.fullstacktrace  = TRUE,
  shiny.sanitizeErrors  = FALSE,
  shiny.trace           = FALSE,   # TRUE = log de cada mensaje websocket (ruidoso)
  shiny.reactlog        = TRUE,
  warn                  = 1,       # warnings al momento, no al final
  shiny.error           = function() {
    cat("\n--- TRACEBACK ------------------------------------------\n")
    print(rlang::trace_back(bottom = sys.frame(-1)))
    cat("--------------------------------------------------------\n\n")
  }
)

# --- 3-4. Instrumental opcional -----------------------------------------
if (!requireNamespace("reactlog", quietly = TRUE)) {
  message("[run_debug] reactlog no instalado: Ctrl+F3 no va a funcionar.")
}

# bs_themer() lo lee app.R desde esta variable.
Sys.setenv(SDA_THEMER = "1")

puerto <- as.integer(Sys.getenv("SDA_PORT", "4568"))

cat("\n== MODO DEBUG ==========================================\n")
cat("  Tema inicial   : ", Sys.getenv("SDA_TEMA", "flatly"), "\n", sep = "")
cat("  Theme customizer: ON (mira la consola al mover los controles)\n")
cat("  Grafo reactivo : Ctrl+F3 en el navegador\n")
cat("  Errores        : sin sanitizar, con traceback\n")
cat("  Puerto         : ", puerto, "\n", sep = "")
cat("========================================================\n\n")

shiny::runApp(
  file.path(.raiz_debug, "libs", "shiny", "R", "app.R"),
  port          = puerto,
  launch.browser = interactive(),
  host          = "127.0.0.1"
)

# Al cerrar la app, esto abre el visor del grafo reactivo de la sesion.
if (interactive() && requireNamespace("reactlog", quietly = TRUE)) {
  message("[run_debug] shiny::reactlogShow() para ver el grafo de la sesion.")
}
