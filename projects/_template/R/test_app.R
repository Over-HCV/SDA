# projects/__SLUG__/R/test_app.R
#
# Smoke + test de comportamiento de la APP.
#
# Existe porque test_headless.R NO puede ver lo que se rompe del lado del
# cliente: un conditionalPanel mal escrito deja el servidor contento, la app
# responde 200, y la feature queda muerta en silencio. Solo app$get_logs()
# lo delata.
#
# Uso (desde la raiz del proyecto):
#   Rscript projects/__SLUG__/R/test_app.R
Sys.setenv(NOT_CRAN = "true")   # sin esto shinytest2 aborta bajo Rscript

if (!requireNamespace("shinytest2", quietly = TRUE)) {
  cat("shinytest2 no instalado.\n"); quit(status = 1)
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

source(file.path(.raiz, "libs", "_comun", "R", "pruebas.R"))
APP <- file.path(.raiz, "projects", "__SLUG__", "R", "app.R")

cat("\n=== test_app.R — projects/__SLUG__ ===\n\n")
pruebas_reset()

app <- AppDriver$new(APP, name = "__SLUG__", height = 950, width = 1500,
                     load_timeout = 90000, timeout = 30000)
on.exit(try(app$stop(), silent = TRUE), add = TRUE)

cat("--- tabs\n")
for (t in c("Modelo", "Acerca de")) {
  r <- tryCatch({ app$set_inputs(tab = t); Sys.sleep(1.5); TRUE },
                error = function(e) FALSE)
  chk(r, sprintf("tab %s", t))
}
app$set_inputs(tab = "Modelo"); Sys.sleep(2)

# ---------------------------------------------------------------------------
# TODO — El hook del tema.
#
# Movelo de punta a punta y verifica que la metrica reaccione en la direccion
# correcta. Este es el test que realmente prueba que tu tema esta bien
# cableado. Patron (del proyecto 01-lasso):
#
#   app$set_inputs(`main-log_lambda` = -3.5); Sys.sleep(2)
#   n_debil <- as.integer(sub(" de .*$", "", app$get_value(output="main-vb_activos")))
#   app$set_inputs(`main-log_lambda` = 0.3);  Sys.sleep(2)
#   n_fuerte <- as.integer(sub(" de .*$", "", app$get_value(output="main-vb_activos")))
#   chk(n_fuerte < n_debil, "subir lambda reduce los activos")
# ---------------------------------------------------------------------------
cat("\n--- hook del tema\n")

app$set_inputs(`main-grado` = 1); Sys.sleep(2)
r2_bajo <- suppressWarnings(as.numeric(app$get_value(output = "main-vb_r2")))

app$set_inputs(`main-grado` = 6); Sys.sleep(2)
r2_alto <- suppressWarnings(as.numeric(app$get_value(output = "main-vb_r2")))

cat(sprintf("    R2: grado 1 = %s, grado 6 = %s\n", r2_bajo, r2_alto))
chk(!is.na(r2_bajo) && !is.na(r2_alto) && r2_alto >= r2_bajo - 1e-8,
    "subir el grado no baja el R2 dentro de muestra")

# ---------------------------------------------------------------------------
# Validacion: un caso invalido debe mostrar mensaje, no matar la sesion.
# ---------------------------------------------------------------------------
cat("\n--- validacion\n")
app$set_inputs(`main-n` = 20); Sys.sleep(1.5)
app$set_inputs(`main-grado` = 10); Sys.sleep(2)
vivo <- tryCatch({ app$get_value(input = "main-n"); TRUE },
                 error = function(e) FALSE)
chk(vivo, "caso invalido no tumba la sesion (validate, no crash)")

# ---------------------------------------------------------------------------
# Consola del navegador
# ---------------------------------------------------------------------------
cat("\n--- logs del navegador\n")
df <- as.data.frame(app$get_logs())
malos <- unique(df$message[grepl("Error|error|Warning", df$message)])
if (length(malos) == 0) {
  chk(TRUE, "sin errores ni warnings en consola")
} else {
  for (m in utils::head(malos, 10))
    chk(FALSE, substr(gsub("\\s+", " ", m), 1, 180))
}

app$stop()
pruebas_salir("__SLUG__ app")
