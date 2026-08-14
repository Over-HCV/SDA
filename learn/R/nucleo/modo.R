# learn/R/nucleo/modo.R
#
# Responsabilidad: saber si la app corre en el navegador (webR/WebAssembly) o
# en un R completo, y exponerlo a quien lo necesite.
#
# Por qué existe: el catálogo filtra métodos por `wasm`, y varias piezas de UI
# cambian de comportamiento (DT con server=TRUE solo tiene sentido en
# servidor; saveRDS a disco no existe en wasm). Que esa decisión viva en un
# solo lugar evita que cada módulo invente su propia detección.

#' Modo de ejecución: "wasm" o "servidor".
#'
#' Precedencia: la variable de entorno SDA_MODO gana sobre la detección
#' automática. Sirve para probar el camino de wasm sin exportar el bundle.
modo_ejecucion <- function() {
  forzado <- Sys.getenv("SDA_MODO", "")
  if (nzchar(forzado)) {
    if (!forzado %in% c("wasm", "servidor"))
      stop("SDA_MODO debe ser 'wasm' o 'servidor', no: ", forzado)
    return(forzado)
  }
  if (grepl("emscripten", R.version$platform, fixed = TRUE)) "wasm" else "servidor"
}

es_wasm <- function() modo_ejecucion() == "wasm"

#' Etiqueta corta para el navbar.
etiqueta_modo <- function() {
  if (es_wasm()) "navegador" else "servidor"
}

#' Frase para el usuario cuando un método no puede correr aquí.
#' @param nombre nombre legible del método
motivo_no_ejecutable <- function(nombre = "Este método") {
  if (es_wasm()) {
    sprintf(paste("%s necesita R completo y esta versión corre dentro del",
                  "navegador. Abrilo en la versión de servidor o corrélo con",
                  "Rscript learn/R/run_headless.R"), nombre)
  } else {
    sprintf("%s no está implementado todavía.", nombre)
  }
}
