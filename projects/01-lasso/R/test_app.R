# projects/01-lasso/R/test_app.R
#
# Smoke + test de comportamiento de la APP LASSO.
#
# No se limita a "carga sin explotar": verifica el hook pedagogico del tema,
# que es lo unico que no puede comprobarse headless — que al subir lambda
# desde la UI los coeficientes se apaguen EN VIVO.
#
# Uso (desde la raiz del proyecto):
#   Rscript projects/01-lasso/R/test_app.R
Sys.setenv(NOT_CRAN = "true")

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

APP <- file.path(.raiz, "projects", "01-lasso", "R", "app.R")

cat("\n=== test_app.R — projects/01-lasso ===\n\n")
pruebas_reset()

app <- AppDriver$new(APP, name = "lasso", height = 950, width = 1500,
                     load_timeout = 90000, timeout = 30000)
on.exit(try(app$stop(), silent = TRUE), add = TRUE)

# Lee el value box de activos ("4 de 13") y devuelve el numerador.
activos <- function() {
  Sys.sleep(1.5)
  txt <- app$get_value(output = "main-vb_activos")
  n <- suppressWarnings(as.integer(sub(" de .*$", "", txt)))
  n
}

cat("--- tabs\n")
for (t in c("Modelo", "Acerca de")) {
  r <- tryCatch({ app$set_inputs(tab = t); Sys.sleep(1.5); TRUE },
                error = function(e) FALSE)
  chk(r, sprintf("tab %s", t))
}
app$set_inputs(tab = "Modelo"); Sys.sleep(2)

# ---------------------------------------------------------------------------
# El hook del tema: lambda arriba => menos predictores activos.
# El slider trabaja en log10(lambda), con debounce de 250 ms.
# ---------------------------------------------------------------------------
cat("\n--- hook: el slider de lambda apaga coeficientes\n")

app$set_inputs(`main-log_lambda` = -3.5); Sys.sleep(2)
n_debil <- activos()
chk(!is.na(n_debil), sprintf("lambda bajo da un conteo legible (%s)", n_debil))

app$set_inputs(`main-log_lambda` = -1.0); Sys.sleep(2)
n_medio <- activos()

app$set_inputs(`main-log_lambda` = 0.3); Sys.sleep(2)
n_fuerte <- activos()

cat(sprintf("    activos: lambda bajo = %s, medio = %s, alto = %s\n",
            n_debil, n_medio, n_fuerte))

chk(!is.na(n_fuerte) && !is.na(n_debil) && n_fuerte < n_debil,
    sprintf("subir lambda reduce los activos (%s -> %s)", n_debil, n_fuerte))
chk(!is.na(n_fuerte) && n_fuerte == 0,
    sprintf("lambda muy alto anula todo (activos = %s)", n_fuerte))

# ---------------------------------------------------------------------------
# alpha = 0 (ridge) no debe anular nada, al mismo lambda que si anulaba.
# ---------------------------------------------------------------------------
cat("\n--- ridge no anula\n")
app$set_inputs(`main-alpha` = 0); Sys.sleep(2.5)
n_ridge <- activos()
cat(sprintf("    ridge en el mismo lambda: activos = %s\n", n_ridge))
chk(!is.na(n_ridge) && n_ridge > 0,
    sprintf("con alpha = 0 sobreviven coeficientes (%s)", n_ridge))

app$set_inputs(`main-alpha` = 1); Sys.sleep(2)

# ---------------------------------------------------------------------------
# Botones que saltan al optimo del CV.
# ---------------------------------------------------------------------------
cat("\n--- botones lambda.min / lambda.1se\n")
antes <- app$get_value(input = "main-log_lambda")
app$click("main-ir_min"); Sys.sleep(2.5)
despues <- app$get_value(input = "main-log_lambda")
chk(!identical(antes, despues), "el boton lambda.min mueve el slider")

app$click("main-ir_1se"); Sys.sleep(2.5)
chk(!is.na(activos()), "tras lambda.1se el modelo sigue vivo")

# ---------------------------------------------------------------------------
# Validacion: menos de 2 predictores debe dar mensaje, no romper la sesion.
# ---------------------------------------------------------------------------
cat("\n--- validacion\n")
app$click("main-ninguno"); Sys.sleep(2)
vivo <- tryCatch({ app$get_value(input = "main-alpha"); TRUE },
                 error = function(e) FALSE)
chk(vivo, "sin predictores la app sigue respondiendo (validate, no crash)")
app$click("main-todos"); Sys.sleep(2)

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
pruebas_salir("01-lasso app")
