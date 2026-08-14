# learn/manifiesto.R
#
# Genera el manifest.json de la raíz, que es lo que Posit Connect Cloud exige
# para publicar contenido de R desde GitHub.
#
# Uso, desde la raíz del repo:
#   Rscript -e 'source("learn/manifiesto.R"); escribir_manifiesto()'
#
# Por qué no se llama `rsconnect::writeManifest(".")` y ya:
#
# rsconnect, si encuentra un `renv.lock` en el directorio, lo usa tal cual. El
# nuestro es único para TODO el repo (S3 de libs/sdd.md) y trae 111 paquetes:
# tidyverse, plotly y GGally de los cuadernos de `notes/`, más chromote,
# shinytest2 y httpgd, que son herramientas de desarrollo. El servidor
# intentaría instalar los 111 y tardaría una eternidad para correr una app que
# usa 14.
#
# La salida es la misma que produciría desplegar el repo entero, pero pidiendo
# solo lo que la app toca: se arma un ESPEJO en tempdir() con el mismo layout
# relativo (app.R, learn/, libs/_comun/, data/), se genera ahí el manifiesto —
# sin renv.lock, así rsconnect deduce las dependencias leyendo el código — y se
# copia el resultado a la raíz. Las rutas y los checksums coinciden porque los
# archivos del espejo son copias exactas.

source("learn/R/cargar.R")

# Lo que la app necesita en tiempo de ejecución. Nada más entra al espejo.
.SUBCARPETAS_ESPEJO <- c("R", "textos", "fichas", "metodos")

# Generados o de desarrollo: se reconstruyen, no se despliegan.
.FUERA_DEL_ESPEJO <- c("R/pruebas", "R/mapa.R")

# Copia un archivo o un árbol entero. file.copy(recursive = TRUE) copia la
# carpeta DENTRO del destino y exige que exista; acá el destino es la ruta
# final, que es lo que hace legible el resto del archivo.
.copiar <- function(origen, destino) {
  if (!file.exists(origen)) return(invisible(FALSE))
  if (dir.exists(origen)) {
    for (archivo in list.files(origen, recursive = TRUE)) {
      final <- file.path(destino, archivo)
      dir.create(dirname(final), recursive = TRUE, showWarnings = FALSE)
      file.copy(file.path(origen, archivo), final, overwrite = TRUE)
    }
    return(invisible(TRUE))
  }
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  file.copy(origen, destino, overwrite = TRUE)
}

#' Arma el espejo y devuelve su ruta.
#'
#' Conserva el layout RELATIVO A LA RAÍZ del repo, no el del bundle wasm: el
#' servidor clona el repositorio entero, así que `app.R` de la raíz encuentra
#' `learn/`, `libs/_comun/` y `data/` donde siempre.
preparar_espejo <- function(espejo = file.path(tempdir(), "sda-manifiesto")) {
  unlink(espejo, recursive = TRUE)
  dir.create(espejo, recursive = TRUE, showWarnings = FALSE)

  .copiar(ruta_repo("app.R"), file.path(espejo, "app.R"))
  for (carpeta in .SUBCARPETAS_ESPEJO)
    .copiar(ruta_app(carpeta), file.path(espejo, "learn", carpeta))
  for (excluido in .FUERA_DEL_ESPEJO)
    unlink(file.path(espejo, "learn", excluido), recursive = TRUE)

  .copiar(ruta_repo("libs", "_comun"), file.path(espejo, "libs", "_comun"))
  dir.create(file.path(espejo, "data"), showWarnings = FALSE)
  for (dato in c("charcoal.csv", "twins.csv"))
    .copiar(ruta_repo("data", dato), file.path(espejo, "data", dato))

  faltan <- c("app.R", "learn/R/app.R", "learn/R/cargar.R",
              "libs/_comun/R/datos.R", "data/charcoal.csv", "data/twins.csv")
  faltan <- faltan[!file.exists(file.path(espejo, faltan))]
  if (length(faltan))
    stop("Espejo incompleto, faltan: ", paste(faltan, collapse = ", "))
  espejo
}

#' Escribe `manifest.json` en la raíz del repo.
#'
#' @return la lista de paquetes que el servidor va a instalar
escribir_manifiesto <- function(destino = ruta_repo("manifest.json")) {
  if (!requireNamespace("rsconnect", quietly = TRUE))
    stop("Falta rsconnect: renv::install('rsconnect')")

  espejo <- preparar_espejo()
  rsconnect::writeManifest(appDir = espejo, appPrimaryDoc = "app.R")
  file.copy(file.path(espejo, "manifest.json"), destino, overwrite = TRUE)

  manifiesto <- jsonlite::fromJSON(destino)
  paquetes <- names(manifiesto$packages)
  message(sprintf("[manifiesto] %s · %d paquetes · %d archivos · R %s",
                  destino, length(paquetes), length(manifiesto$files),
                  manifiesto$platform))

  # Aviso, no error: que la app arranque en el servidor no lo prueba esto.
  esenciales <- c("shiny", "bslib", "DT", "ggplot2", "commonmark", "jsonlite")
  ausentes <- setdiff(esenciales, paquetes)
  if (length(ausentes))
    warning("El manifiesto no declara: ", paste(ausentes, collapse = ", "),
            ". Revisá las llamadas library() de app.R.")
  invisible(paquetes)
}
