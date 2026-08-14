# libs/shiny-live/build.R
#
# Construye el bundle shinylive (docs/) desde un directorio de staging.
#
# Por qué staging y no `shinylive::export("libs/shiny-live", ...)` directo:
# el bundle exportado SOLO contiene lo que hay dentro del directorio fuente.
# La app arranca con un root-finder que busca `data/charcoal.csv` hacia arriba
# y luego sourcea `libs/_comun/R/*.R` (ver R/app.R). Exportando el directorio
# tal cual, ni `data/` ni `libs/_comun/` viajan al bundle: en webR el
# root-finder llega a "/" y la app muere al sourcearse.
#
# El staging replica una mini-raíz de proyecto dentro del bundle:
#
#   .build/
#   ├── app.R                # wrapper requerido por shinylive::export()
#   ├── R/*.R                # sin run_headless.R (la app no lo sourcea)
#   ├── libs/_comun/R/*.R
#   └── data/{charcoal,twins}.csv   <- marca la raíz para el root-finder
#
# Uso (desde la raíz del proyecto):
#   Rscript -e 'source("libs/shiny-live/build.R"); construir_bundle()'

source(file.path(
  (function() {
    d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
    repeat {
      if (file.exists(file.path(d, "data", "charcoal.csv")) ||
          file.exists(file.path(d, "renv", "activate.R"))) return(d)
      p <- dirname(d); if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
      d <- p
    }
  })(),
  "libs", "_comun", "R", "datos.R"))  # trae proyecto_raiz()

# Archivos de R/ que la app sourcea (R/app.R los lista explícitamente).
.APP_R <- c("app.R", "datos.R", "modelo.R", "mod_anova.R",
            "mod_distribucion.R", "mod_potencia.R", "mod_resumen.R")
.COMUN_R <- c("datos.R", "metricas.R", "temas.R")
.DATOS   <- c("charcoal.csv", "twins.csv")

construir_bundle <- function(destino = "libs/shiny-live/docs",
                             stage   = "libs/shiny-live/.build",
                             limpiar_stage = FALSE) {
  raiz    <- proyecto_raiz()
  origen  <- file.path(raiz, "libs", "shiny-live")
  stage   <- file.path(raiz, stage)
  destino <- file.path(raiz, destino)

  # --- Staging limpio ---------------------------------------------------
  unlink(stage, recursive = TRUE)
  for (d in c("R", "libs/_comun/R", "data"))
    dir.create(file.path(stage, d), recursive = TRUE, showWarnings = FALSE)

  file.copy(file.path(origen, "app.R"), file.path(stage, "app.R"))
  file.copy(file.path(origen, "R", .APP_R), file.path(stage, "R"))
  file.copy(file.path(raiz, "libs", "_comun", "R", .COMUN_R),
            file.path(stage, "libs", "_comun", "R"))
  # twins.csv no está en data/ sino en workshops/twins/: se resuelve por
  # nombre en vez de fijar la ruta, que es lo que tenía roto este build.
  for (nombre in .DATOS) {
    origen_dato <- if (identical(nombre, "twins.csv")) twins_path()
                   else file.path(raiz, "data", nombre)
    file.copy(origen_dato, file.path(stage, "data", nombre))
  }

  faltan <- Filter(Negate(file.exists), file.path(
    stage, c("app.R", file.path("R", .APP_R),
             file.path("libs/_comun/R", .COMUN_R), file.path("data", .DATOS))))
  if (length(faltan)) stop("Staging incompleto: ", paste(faltan, collapse = ", "))

  # --- Export -----------------------------------------------------------
  message("Exportando ", stage, " -> ", destino, " (lento la primera vez)")
  unlink(file.path(destino, "app.json"))
  shinylive::export(stage, destino)

  # --- Inventario (el bug que motivó este script se ve aquí) ------------
  app_json <- file.path(destino, "app.json")
  files <- jsonlite::fromJSON(app_json, simplifyDataFrame = FALSE)
  cat("\nArchivos en el bundle (", length(files), "):\n", sep = "")
  for (f in files) cat(sprintf("  %-34s %8d B\n", f$name, nchar(f$content)))
  cat(sprintf("\napp.json: %.1f MB\n", file.size(app_json) / 1024^2))

  nombres <- vapply(files, `[[`, "", "name")
  esperados <- c("app.R", file.path("R", .APP_R),
                 file.path("libs/_comun/R", .COMUN_R), file.path("data", .DATOS))
  if (length(setdiff(esperados, nombres)))
    stop("Bundle incompleto, faltan: ",
         paste(setdiff(esperados, nombres), collapse = ", "))

  if (limpiar_stage) unlink(stage, recursive = TRUE)
  invisible(destino)
}
