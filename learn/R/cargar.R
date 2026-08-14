# learn/R/cargar.R
#
# Punto ÚNICO de arranque: resuelve rutas y sourcea el proyecto en orden.
#
# Lo sourcean tanto `R/app.R` (interactivo) como `run_headless.R` y las
# pruebas. Nadie más debería escribir un buscador de raíz a mano.
#
# Dos disposiciones posibles en disco, y hay que soportar las dos:
#
#   servidor            wasm (bundle shinylive)
#   <raiz>/data/        <bundle>/data/
#   <raiz>/libs/_comun/ <bundle>/libs/_comun/
#   <raiz>/learn/R/     <bundle>/R/
#   <raiz>/learn/textos <bundle>/textos
#
# De ahí las dos funciones: sda_raiz() apunta a donde vive `data/`, y
# sda_base() a donde vive lo nuestro (`R/`, `textos/`, `fichas/`, `metodos/`).

.sda_cache <- new.env(parent = emptyenv())

# --- Raíz del proyecto (donde cuelga data/) --------------------------------
sda_raiz <- function() {
  if (!is.null(.sda_cache$raiz)) return(.sda_cache$raiz)
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    # `sda-raiz` es el marcador que planta el bundle wasm (sin punto inicial:
    # shinylive::export() no copia archivos ocultos): ahí no hay ni renv
    # ni necesariamente data/, así que sin él el buscador subiría hasta "/".
    if (file.exists(file.path(d, "sda-raiz")) ||
        file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) {
      .sda_cache$raiz <- d
      return(d)
    }
    p <- dirname(d)
    if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
    d <- p
  }
}

# --- Base de la app (donde cuelgan R/, textos/, fichas/, metodos/) ---------
sda_base <- function() {
  if (!is.null(.sda_cache$base)) return(.sda_cache$base)
  raiz <- sda_raiz()
  candidato <- file.path(raiz, "learn")
  base <- if (dir.exists(file.path(candidato, "R", "nucleo"))) candidato else raiz
  .sda_cache$base <- base
  base
}

#' Ruta absoluta a un archivo de la app.
#' @examples ruta_app("textos", "f1.analisis.histograma.md")
ruta_app <- function(...) file.path(sda_base(), ...)

#' Ruta absoluta a un archivo compartido del repo (data/, libs/_comun/).
ruta_repo <- function(...) file.path(sda_raiz(), ...)

# --- Orden de carga --------------------------------------------------------
# nucleo -> logica -> graficos -> ui/piezas -> ui -> metodos.
#
# `ui/piezas` aparece antes que `ui` porque las piezas definen constantes que
# los módulos usan en el nivel superior de su archivo (ETIQUETA_ANALISIS, por
# ejemplo). Las rutas repetidas no se sourcean dos veces: .sourcear_arbol()
# lleva registro de lo ya cargado.
.CARPETAS_APP <- c("nucleo", "logica", "graficos", "ui/piezas", "ui")

# De libs/_comun/R/ solo lo que la app necesita. Añadir aquí, no en cada módulo.
.COMUN <- c("datos.R", "metricas.R", "temas.R", "temas_bslib.R")

#' Sourcea un directorio COMPLETO, subcarpetas incluidas.
#'
#' Las subcarpetas son la forma de partir un tema grande sin romper C2:
#' `nucleo/catalogo/` tiene una fila por macro-tema del curso, `ui/fase1/` un
#' módulo por subsección. El orden dentro del árbol no importa porque estos
#' archivos solo DEFINEN funciones; lo que se ejecuta al cargar son las
#' llamadas a poblar_* del final de cargar_sda().
#'
#' @return número de archivos sourceados en esta llamada
.sourcear_arbol <- function(dir) {
  if (!dir.exists(dir)) return(0L)
  archivos <- sort(list.files(dir, pattern = "[.][Rr]$", full.names = TRUE,
                              recursive = TRUE))
  archivos <- setdiff(normalizePath(archivos), .sda_cache$sourceados)
  for (archivo in archivos) source(archivo, local = FALSE)
  .sda_cache$sourceados <- c(.sda_cache$sourceados, archivos)
  length(archivos)
}

#' Sourcea el proyecto completo.
#'
#' @param con_ui FALSE en contexto headless: salta `ui/` y no carga bslib/DT.
#' @param silencioso TRUE para no imprimir el inventario.
cargar_sda <- function(con_ui = TRUE, silencioso = TRUE) {
  .sda_cache$sourceados <- character(0)

  for (f in .COMUN) {
    ruta <- ruta_repo("libs", "_comun", "R", f)
    if (file.exists(ruta)) source(ruta, local = FALSE)
  }

  carpetas <- if (con_ui) .CARPETAS_APP else setdiff(.CARPETAS_APP, "ui")
  # Los métodos viven fuera de R/ porque son el catálogo, no el andamiaje.
  directorios <- c(ruta_app("R", carpetas), ruta_app("metodos"))

  n <- 0L
  for (dir in directorios) n <- n + .sourcear_arbol(dir)

  # Los catálogos se pueblan DESPUÉS de sourcear todo, no al sourcearse.
  # Si `catalogo.R` llamara a `registrar_metodo()` en el momento de cargarse,
  # dependería de que `registro.R` ya estuviera cargado, y el orden dentro de
  # una carpeta es alfabético. Poblar al final rompe esa dependencia y además
  # deja los catálogos limpiables y repoblables desde las pruebas.
  if (exists("poblar_artefactos", mode = "function")) poblar_artefactos()
  if (exists("poblar_catalogo",  mode = "function")) poblar_catalogo()

  if (!silencioso) {
    message(sprintf("[cargar_sda] %d archivos · %d métodos · %d artefactos · %s",
                    n, length(claves_metodos()), length(claves_artefactos()),
                    modo_ejecucion()))
  }
  invisible(n)
}

#' Carga las librerías de UI. Separado de cargar_sda() para que el contexto
#' headless no arrastre bslib ni DT.
cargar_librerias_ui <- function() {
  suppressPackageStartupMessages({
    library(shiny); library(bslib); library(DT)
    library(ggplot2)
  })
  invisible(TRUE)
}
