# learn/R/nucleo/informe/codigos/comun.R
#
# Responsabilidad: elegir, por clave, el generador de código R autónomo de un
# panel para el cuaderno exportado, y decidir cuándo no se puede generar.
#
# Cada generador devuelve character() de líneas que usan `datos` como nombre
# del data.frame: el cuaderno lo define una vez en "Los datos" y todos los
# chunks miran el mismo objeto. Los de la fase 1 viven en `fase1/` (base +
# ggplot2); los de la fase 4 en `fase4/` (base + stats + factoextra).
#
# Esta carpeta se sourcea en orden alfabético y `comun.R` va primero, pero
# nada de acá se EJECUTA al cargar salvo constantes literales: las funciones
# de `fase1/` y `fase4/` recién se buscan cuando alguien llama a
# codigo_artefacto(), y para entonces ya está todo cargado.

# Entrecomilla valores de filtro: Hora = 12:00 es texto, no número.
.valores_r <- function(valores)
  paste(sprintf('"%s"', as.character(valores)), collapse = ", ")

# Qué parámetros necesita cada generador para producir código que CORRA.
#
# Sin esta tabla, un parámetro ausente no daba error: `sprintf()` con NULL
# devuelve character(0), así que la línea del `ggplot(...)` desaparecía y el
# chunk quedaba con un `+` huérfano — R roto, dentro de un cuaderno con cara de
# estar bien. Faltando algo se cae al genérico, que documenta en vez de mentir.
#
# Las de la fase 4 solo exigen `metodo`: el resto (hiper, ejes, top) tiene un
# valor por defecto razonable, el mismo que tiene el registro.
PARAMS_REQUERIDOS <- c(list(
  "f1.analisis.histograma" = "variable",
  "f1.analisis.densidad" = "variable",
  "f1.analisis.boxplot" = "variable",
  "f1.analisis.resumen" = "variable",
  "f1.analisis.boxplot_grupos" = c("variable", "grupo"),
  "f1.analisis.qq_normal_datos" = "variable",
  "f1.analisis.dispersion" = c("x", "y"),
  "f1.analisis.densidad_conjunta" = c("x", "y"),
  "f1.analisis.mosaico" = c("a", "b"),
  "f1.analisis.matriz_dispersion" = "variables",
  "f1.analisis.heatmap_correlacion" = "variables",
  "f1.analisis.coordenadas_paralelas" = "variables",
  "f1.analisis.elipsoide" = c("x", "y"),
  "f1.analisis.qq_mahalanobis" = "variables",
  "f1.calidad.atipicos" = "columna",
  "f1.balanceo.frecuencias" = "clase"),
  stats::setNames(rep(list("metodo"), 12L), c(
    "f4.diagnostico.scree", "f4.diagnostico.reglas_k",
    "f4.explicabilidad.contribuciones",
    "f4.explicabilidad.circulo_correlaciones",
    "f4.explicabilidad.mapa_2d", "f4.explicabilidad.cargas",
    "f4.explicabilidad.calidad", "f4.diagnostico.codo",
    "f4.diagnostico.silueta", "f4.explicabilidad.centroides",
    "f4.desempeno.grupos", "f4.diagnostico.dendrograma")))

#' ¿Están los parámetros que el generador de esta clave necesita?
params_completos <- function(clave, params) {
  campos <- PARAMS_REQUERIDOS[[clave]]
  if (is.null(campos)) return(TRUE)
  todos <- vapply(campos, function(campo) {
    valor <- params[[campo]]
    !is.null(valor) && length(valor) > 0L && all(nzchar(as.character(valor)))
  }, logical(1))
  all(todos)
}

#' El código de un artefacto, elegido por su clave.
#'
#' @param params lista con los parámetros vigentes al marcar la casilla
#' @param tabla la tabla congelada del panel, cuando la clave guarda una
#'   (diccionario, frecuencias): hay código que la necesita para ser autónomo.
#' @return character() de líneas R; nunca character(0): el fallback documenta.
codigo_artefacto <- function(clave, params, tabla = NULL) {
  if (!params_completos(clave, params))
    return(c(sprintf("# %s", clave),
             .codigo_incompleto(clave, params)))
  lineas <- if (startsWith(clave, "f4.")) .codigo_fase4(clave, params)
    else .codigo_fase1(clave, params, tabla)
  # La clave viaja como comentario: es el puente entre el cuaderno y el lab.
  c(sprintf("# %s", clave), lineas %||% .codigo_generico(clave, params))
}

#' Los paquetes que el código de esta entrada carga con library().
#'
#' Lo pregunta `.paquetes_de()` al armar el chunk de configuración: el que
#' sabe qué funciones emite un generador es el generador, no el cuaderno.
paquetes_de_codigo <- function(clave, params) {
  if (startsWith(clave, "f4.")) return(.paquetes_fase4(clave, params))
  if (identical(clave, "f1.analisis.dispersion") &&
      isTRUE(params$marginales)) return("ggExtra")
  character(0)
}

#' Cuando faltan los parámetros, el cuaderno dice QUÉ falta en vez de emitir
#' un chunk que no corre. El que lo lea puede completarlo a mano.
.codigo_incompleto <- function(clave, params) {
  campos <- PARAMS_REQUERIDOS[[clave]]
  faltan <- campos[!vapply(campos, function(campo)
    !is.null(params[[campo]]) && length(params[[campo]]) > 0L, logical(1))]
  c("# (Este panel se exportó sin los parámetros que su código necesita.)",
    sprintf("# Falta indicar: %s", paste(faltan, collapse = ", ")),
    "# Volvé al lab, elegí las columnas y marcá la casilla de nuevo.")
}

#' Cuando no hay generador dedicado, el cuaderno no miente: documenta qué se
#' vio y con qué parámetros, y apunta a la clave para reproducirlo en el lab.
.codigo_generico <- function(clave, params) {
  c("# (Sin generador autónomo para este panel.)",
    sprintf("# Parámetros con que se produjo: %s",
            jsonlite::toJSON(params %||% list(), auto_unbox = TRUE)))
}
