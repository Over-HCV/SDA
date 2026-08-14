# libs/shiny/R/test_app.R
#
# Smoke test de la APP (no del modelo). Levanta la app de verdad en un
# Chrome headless, recorre todos los tabs y falla si el navegador reporta
# algun error de JS o de servidor.
#
# Complementa a test_headless.R:
#   test_headless.R -> la logica pura y el contrato S2 de artefactos
#   test_app.R      -> que la UI cargue y los outputs rendericen sin explotar
#
# Uso (desde la raiz del proyecto):
#   Rscript libs/shiny/R/test_app.R
#
# Requiere shinytest2 + chromote (y un Chrome/Chromium instalado).
#
# Por que NOT_CRAN: shinytest2 se auto-desactiva si cree que corre en CRAN,
# y con Rscript lo cree. Sin esta variable aborta con "Reason: On CRAN".
Sys.setenv(NOT_CRAN = "true")

if (!requireNamespace("shinytest2", quietly = TRUE)) {
  cat("shinytest2 no instalado. install.packages('shinytest2')\n")
  quit(status = 1)
}
suppressPackageStartupMessages(library(shinytest2))

.raiz <- (function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
    d <- p
  }
})()

APP  <- file.path(.raiz, "libs", "shiny", "R", "app.R")
TABS <- c("Ajuste", "Diagnosticos", "Datos", "Resumen",
          "Inputs", "Cards", "Plots", "Tablas", "Notificaciones", "Tipografia")

# El preset a probar. Vale la pena correr esto tambien con SDA_TEMA=retro:
# el tema 8-bit es el que mas CSS pisa y el que mas facil rompe algo.
TEMA <- Sys.getenv("SDA_TEMA", "flatly")

fallos <- 0L

cat("\n=== test_app.R — smoke de UI (tema: ", TEMA, ") ===\n\n", sep = "")

app <- AppDriver$new(APP, name = "smoke", height = 900, width = 1400,
                     load_timeout = 90000, timeout = 30000)
on.exit(try(app$stop(), silent = TRUE), add = TRUE)

for (t in TABS) {
  r <- tryCatch({
    app$set_inputs(tab = t)
    Sys.sleep(2)
    "ok"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))

  if (identical(r, "ok")) {
    cat(sprintf("  ok    tab %s\n", t))
  } else {
    fallos <- fallos + 1L
    cat(sprintf("  FALLA tab %s -> %s\n", t, r))
  }
}

# ---------------------------------------------------------------------------
# Logs del navegador. Aca es donde aparecen los errores que NO tumban la app
# pero rompen features: el ReferenceError de un conditionalPanel mal escrito,
# por ejemplo, solo se ve por este canal.
# ---------------------------------------------------------------------------
cat("\n--- logs del navegador\n")
df  <- as.data.frame(app$get_logs())
malos <- unique(df$message[grepl("Error|error|Warning", df$message)])

if (length(malos) == 0) {
  cat("  ok    sin errores ni warnings en consola\n")
} else {
  fallos <- fallos + length(malos)
  for (m in utils::head(malos, 15)) {
    cat("  FALLA ", substr(gsub("\\s+", " ", m), 1, 200), "\n", sep = "")
  }
}

app$stop()

cat("\n========================================\n")
cat(sprintf("  %d tabs, %d fallas\n", length(TABS), fallos))
cat("========================================\n")

if (fallos > 0) {
  cat("RESULTADO: FALLA\n")
  quit(status = 1)
}
cat("RESULTADO: OK\n")
quit(status = 0)
