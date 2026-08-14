source("renv/activate.R")
# .Rprofile — arranca al abrir el proyecto SDA en VS Code / RStudio / Positron
#
# Propósito:
#   1. Auto-arrancar httpgd para que los gráficos se sirvan por HTTP
#      (el agente puede curl http://localhost:<port>/ y "verlos").
#   2. shiny.autoreload = TRUE para iterar en apps sin reiniciar.
#   3. repos CRAN canónico.
#
# NOTA: thematic NO se activa aquí. Es incompatible con el device de httpgd
# (unigd) y además necesita contexto de IDE/RStudio para resolver colores "auto".
# Cada app Shiny lo activa explícitamente con thematic_on() dentro de su UI,
# donde renderPlot() lo soporta de forma nativa.

local({
  # 1. CRAN mirror + opciones de Shiny
  options(
    repos = c(CRAN = "https://cloud.r-project.org"),
    browserNLdisabled = TRUE,
    shiny.autoreload = TRUE,
    # Grafo reactivo. No cuesta nada mientras no lo inspecciones; para verlo,
    # Ctrl+F3 con la app corriendo, o shiny::reactlogShow() despues de cerrarla.
    shiny.reactlog = TRUE
  )

  # 2. httpgd: solo si NO estamos en R CMD check / non-interactive.
  #    Lanzamos silenciosamente; si la librería no está instalada todavía,
  #    no falla (la instalamos más adelante).
  if (interactive() && Sys.getenv("R_HTTPGD_DISABLE") == "") {
    if (requireNamespace("httpgd", quietly = TRUE)) {
      try({
        hgd <- httpgd::hgd()
        hgd_url <- httpgd::hgd_url(hgd)
        options(httpgd.url = hgd_url)
        message("[.Rprofile] httpgd escuchando en: ", hgd_url)
      }, silent = TRUE)
    }
  }

  # 3. Mensaje de bienvenida breve
  if (interactive()) {
    cat("\n── Proyecto SDA (3 motores R interactivos) ──\n")
    cat("Use source('libs/_comun/R/datos.R') para cargar datos.\n\n")
  }
})
