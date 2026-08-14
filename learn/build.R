# learn/build.R
#
# Construye el bundle shinylive (docs/) desde un directorio de staging.
#
# Uso, desde la raíz del repo:
#   Rscript -e 'source("learn/build.R"); construir_bundle()'
#   python3 -m http.server 8000 --directory learn/docs
#
# Por qué staging y no exportar learn/ tal cual: el bundle SOLO contiene lo
# que hay dentro del directorio fuente, y la app necesita tres cosas que viven
# fuera de learn/ — libs/_comun/R/, data/ y el marcador de raíz. Sin ellas el
# buscador de raíz sube hasta "/" y la app muere en webR sin error legible.
#
#   <tempdir>/sda-lab-staging/
#   ├── sda-raiz            marcador para sda_raiz()
#   ├── app.R               wrapper con $value y las librerías declaradas
#   ├── R/                  todo el árbol, sin pruebas/ ni mapa.R
#   ├── textos/ fichas/ metodos/
#   ├── libs/_comun/R/
#   └── data/

source("learn/R/cargar.R")

# De libs/_comun/ solo lo que la app llega a usar. temas_bslib.R viaja porque
# listar_temas() se usa en el navbar, pero tema_seguro() evita font_google()
# en wasm (ver learn/R/nucleo/tema_app.R).
.COMUN_BUNDLE <- c("datos.R", "metricas.R", "temas.R", "temas_bslib.R")

# No se exportan: pruebas/ (no corren en el navegador) ni mapa.R (herramienta
# de desarrollo). MAPA.md tampoco: es para agentes, no para la app.
.EXCLUIR_R <- c("pruebas", "mapa.R")

#' Datasets a incluir, resueltos desde donde de verdad están.
#'
#' OJO: twins.csv NO está en data/ del repo, está en workshops/twins/. Desde el
#' Hito 2 `twins_path()` de libs/_comun/ prueba los dos sitios, así que el
#' build de libs/shiny-live ya no falla por esto.
rutas_datos <- function() {
  candidatas <- c(ruta_repo("data", "charcoal.csv"),
                  ruta_repo("data", "twins.csv"),
                  ruta_repo("workshops", "twins", "twins.csv"))
  existentes <- candidatas[file.exists(candidatas)]
  # Si twins aparece en los dos sitios, quedarse con uno solo.
  existentes[!duplicated(basename(existentes))]
}

.copiar_arbol <- function(origen, destino_base, relativa) {
  if (!dir.exists(origen)) return(0L)
  archivos <- list.files(origen, recursive = TRUE, all.files = FALSE)
  for (archivo in archivos) {
    destino <- file.path(destino_base, relativa, archivo)
    dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
    file.copy(file.path(origen, archivo), destino, overwrite = TRUE)
  }
  length(archivos)
}

#' Arma el directorio de staging y devuelve su ruta.
preparar_staging <- function(stage) {
  unlink(stage, recursive = TRUE)
  dir.create(stage, recursive = TRUE, showWarnings = FALSE)

  file.create(file.path(stage, "sda-raiz"))
  file.copy(ruta_app("app.R"), file.path(stage, "app.R"))

  .copiar_arbol(ruta_app("R"), stage, "R")
  for (excluido in .EXCLUIR_R)
    unlink(file.path(stage, "R", excluido), recursive = TRUE)

  for (carpeta in c("textos", "fichas", "metodos"))
    .copiar_arbol(ruta_app(carpeta), stage, carpeta)

  dir.create(file.path(stage, "libs", "_comun", "R"), recursive = TRUE,
             showWarnings = FALSE)
  file.copy(ruta_repo("libs", "_comun", "R", .COMUN_BUNDLE),
            file.path(stage, "libs", "_comun", "R"), overwrite = TRUE)
  .copiar_arbol(ruta_repo("libs", "_comun", "scss"), stage,
                file.path("libs", "_comun", "scss"))

  dir.create(file.path(stage, "data"), showWarnings = FALSE)
  file.copy(rutas_datos(), file.path(stage, "data"), overwrite = TRUE)

  stage
}

#' Comprueba que el staging tiene lo mínimo ANTES de exportar.
#'
#' Exportar tarda minutos; descubrir que falta un archivo al abrir el bundle
#' en el navegador cuesta mucho más que comprobarlo acá.
verificar_staging <- function(stage) {
  obligatorios <- c("sda-raiz", "app.R", "R/app.R", "R/cargar.R",
                    "R/nucleo/registro.R", "R/nucleo/catalogo/poblar.R",
                    "R/nucleo/artefactos/poblar.R", "R/ui/piezas/panel.R",
                    "R/ui/f2/catalogo.R", "libs/_comun/R/temas_bslib.R")
  faltan <- obligatorios[!file.exists(file.path(stage, obligatorios))]
  if (length(faltan))
    stop("Staging incompleto, faltan: ", paste(faltan, collapse = ", "))

  prohibidos <- c("R/pruebas", "R/mapa.R")
  colados <- prohibidos[file.exists(file.path(stage, prohibidos))]
  if (length(colados))
    stop("Staging con archivos de desarrollo: ", paste(colados, collapse = ", "))

  invisible(TRUE)
}

# El staging va FUERA del repo, y no es una preferencia estética.
#
# shinylive::export() averigua qué paquetes meter en el bundle llamando a
# `renv::dependencies(appdir)`, y renv respeta `.gitignore`. Con el staging en
# `learn/.build/` — que la raíz ignora con `.build/` — el escaneo devolvía
# CERO paquetes, el bundle salía sin ninguno, y webR moría en el navegador con
# una lluvia de "preload error: Downloading webR package: ...".
#
# Fuera del repo no hay .gitignore que interfiera.
stage_por_defecto <- function() file.path(tempdir(), "sda-lab-staging")

#' Construye el bundle.
#'
#' @param limpiar_stage TRUE borra el staging al terminar. Dejarlo ayuda a
#'   depurar: es exactamente el árbol que vio shinylive.
construir_bundle <- function(destino = ruta_app("docs"),
                             stage = stage_por_defecto(),
                             limpiar_stage = FALSE) {
  stage <- preparar_staging(stage)
  verificar_staging(stage)

  message("Exportando ", stage, " -> ", destino, " (lento la primera vez)")
  verificar_dependencias(stage)
  unlink(file.path(destino, "app.json"))
  shinylive::export(stage, destino)

  inventario_bundle(destino)
  if (limpiar_stage) unlink(stage, recursive = TRUE)
  invisible(destino)
}

#' Comprueba que shinylive va a encontrar los paquetes.
#'
#' Es la misma llamada que hace export() por dentro. Verla acá convierte un
#' fallo silencioso (bundle sin paquetes) en un error con nombre.
verificar_dependencias <- function(stage) {
  paquetes <- unique(renv::dependencies(stage, quiet = TRUE)$Package)
  esperados <- c("shiny", "bslib", "DT", "ggplot2", "bsicons", "commonmark",
                 "jsonlite")
  faltan <- setdiff(esperados, paquetes)
  if (length(faltan))
    stop("renv::dependencies() no ve estos paquetes en el staging: ",
         paste(faltan, collapse = ", "),
         ". Sin ellos el bundle sale vacío y webR falla al arrancar. ",
         "Revisá que el staging no caiga bajo una regla de .gitignore.")
  message("[deps] ", length(paquetes), " paquetes detectados: ",
          paste(utils::head(sort(paquetes), 12), collapse = ", "))
  invisible(paquetes)
}

#' Inventario de lo que quedó dentro. El bug que motivó este script (archivos
#' que nunca viajaron) solo se ve mirando app.json, no el directorio fuente.
inventario_bundle <- function(destino = ruta_app("docs")) {
  app_json <- file.path(destino, "app.json")
  archivos <- jsonlite::fromJSON(app_json, simplifyDataFrame = FALSE)
  nombres <- vapply(archivos, `[[`, "", "name")

  cat(sprintf("\n[bundle] %d archivos · app.json %.1f MB\n", length(archivos),
              file.size(app_json) / 1024^2))
  por_carpeta <- table(ifelse(grepl("/", nombres),
                              sub("/.*$", "/", nombres), "(raíz)"))
  for (carpeta in names(por_carpeta))
    cat(sprintf("  %-18s %3d\n", carpeta, por_carpeta[[carpeta]]))

  esperados <- c("app.R", "R/app.R", "R/cargar.R", "sda-raiz")
  faltan <- setdiff(esperados, nombres)
  if (length(faltan))
    stop("Bundle incompleto, faltan: ", paste(faltan, collapse = ", "))
  invisible(nombres)
}
