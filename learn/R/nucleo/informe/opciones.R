# learn/R/nucleo/informe/opciones.R
#
# Responsabilidad: decir qué piezas lleva el cuaderno de exploración.
#
# El cuaderno se arma para dos públicos distintos. Uno estudia con él y quiere
# el texto del panel, sus parámetros y de dónde salió cada cosa; el otro lo
# entrega como taller y necesita justo lo contrario, porque la procedencia y
# las tablas de estado son ruido que hay que borrar a mano. En vez de elegir
# por él con tres presets, cada pieza se prende o se apaga por separado y los
# valores por defecto son los del entregable.
#
# Una selección de piezas es un character() de claves de PIEZAS_CUADERNO.

# Clave -> etiqueta que se ve en la pestaña Informe.
PIEZAS_CUADERNO <- c(
  texto_esencial   = "Texto del panel: Qué muestra y Cuándo engaña",
  texto_ampliado   = "Texto del panel: Para qué sirve y Qué buscar",
  procedencia      = "Clave del panel y hora en que se marcó",
  estado           = "Tabla del estado al marcarlo",
  parametros       = "Tabla de parámetros",
  ficha_datos      = "Ficha del dataset (fuente, filas, columnas)",
  notas            = "Mis lecturas",
  marco            = "Encabezado y pie del cuaderno",
  plantilla_taller = "YAML de la plantilla del taller (LaTeX) y salida .qmd")

# Lo que sale marcado: el cuaderno que se entrega como taller.
PIEZAS_POR_DEFECTO <- c("ficha_datos", "notas", "plantilla_taller")

# Los presets viejos (`--texto completo|breve|ninguno`) traducidos a piezas.
# Se conservan porque las sesiones guardadas antes de las casillas traen el
# nivel y no la lista, y porque es la forma corta de pedir "el de estudio".
PIEZAS_DE_TEXTO <- list(
  completo = c("texto_esencial", "texto_ampliado"),
  breve    = "texto_esencial",
  ninguno  = character(0))

#' La selección de piezas, normalizada.
#'
#' @param piezas claves marcadas; NULL deja las de PIEZAS_POR_DEFECTO
#' @param texto preset viejo (completo|breve|ninguno) que suma sus piezas de
#'   texto a `piezas`; NULL lo ignora
#' @return character() de claves válidas, en el orden de PIEZAS_CUADERNO
opciones_cuaderno <- function(piezas = NULL, texto = NULL) {
  elegidas <- if (is.null(piezas)) PIEZAS_POR_DEFECTO else
    as.character(unlist(piezas, use.names = FALSE))
  if (!is.null(texto)) {
    nivel <- match.arg(texto, names(PIEZAS_DE_TEXTO))
    elegidas <- c(setdiff(elegidas, unlist(PIEZAS_DE_TEXTO, use.names = FALSE)),
                  PIEZAS_DE_TEXTO[[nivel]])
  }
  desconocidas <- setdiff(elegidas, names(PIEZAS_CUADERNO))
  if (length(desconocidas))
    stop("pieza de cuaderno desconocida: ",
         paste(desconocidas, collapse = ", "), call. = FALSE)
  names(PIEZAS_CUADERNO)[names(PIEZAS_CUADERNO) %in% elegidas]
}

#' ¿Va esta pieza en el cuaderno?
incluye <- function(opciones, pieza) pieza %in% opciones

#' El nivel de texto que corresponde a las piezas marcadas.
#'
#' El recorte de secciones (SECCIONES_BREVES) sigue razonando en niveles, así
#' que acá se traduce de vuelta una sola vez.
nivel_de_texto <- function(opciones) {
  if (incluye(opciones, "texto_ampliado")) return("completo")
  if (incluye(opciones, "texto_esencial")) return("breve")
  "ninguno"
}
