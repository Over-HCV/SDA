# learn/R/nucleo/almacen.R
#
# Responsabilidad: guardar los objetos de la sesión (datasets, modelos,
# recetas, corridas) y dar el CRUD transversal de la sección ⚙ Objetos.
#
# Es PURO a propósito: cada operación devuelve un almacén nuevo en vez de
# mutar el que recibe. Eso permite dos cosas a la vez:
#   - probarlo con Rscript, sin Shiny,
#   - guardarlo en un reactiveVal y que Shiny invalide solo al reemplazarlo.
#
# El precio (copiar la lista en cada escritura) es irrelevante: son decenas de
# objetos, no millones.

TIPOS_OBJETO <- c("dataset", "modelo", "receta", "corrida")

# Prefijo del id por tipo: d3, m5, r1, c12.
.PREFIJOS <- c(dataset = "d", modelo = "m", receta = "r", corrida = "c")

.plural <- function(tipo) paste0(tipo, "s")

nuevo_almacen <- function() {
  almacen <- list(contadores = stats::setNames(
    as.list(rep(0L, length(TIPOS_OBJETO))), TIPOS_OBJETO))
  for (tipo in TIPOS_OBJETO) almacen[[.plural(tipo)]] <- list()
  almacen
}

#' Siguiente id libre para un tipo. No consume el contador; eso lo hace
#' almacen_agregar(), para que pedir un id dos veces no salte números.
siguiente_id <- function(almacen, tipo) {
  tipo <- match.arg(tipo, TIPOS_OBJETO)
  sprintf("%s%d", .PREFIJOS[[tipo]], almacen$contadores[[tipo]] + 1L)
}

#' Agrega un objeto. Si su id es NULL o "", le asigna el siguiente libre.
#' @return el almacén nuevo, con attr("id_nuevo") apuntando al id usado
almacen_agregar <- function(almacen, objeto) {
  tipo <- objeto$tipo
  if (!tipo %in% TIPOS_OBJETO) stop("tipo de objeto desconocido: ", tipo)
  if (is.null(objeto$id) || !nzchar(objeto$id)) objeto$id <- siguiente_id(almacen, tipo)

  almacen$contadores[[tipo]] <- almacen$contadores[[tipo]] + 1L
  almacen[[.plural(tipo)]][[objeto$id]] <- objeto
  attr(almacen, "id_nuevo") <- objeto$id
  almacen
}

almacen_obtener <- function(almacen, tipo, id) {
  tipo <- match.arg(tipo, TIPOS_OBJETO)
  almacen[[.plural(tipo)]][[id]]
}

almacen_listar <- function(almacen, tipo) {
  tipo <- match.arg(tipo, TIPOS_OBJETO)
  almacen[[.plural(tipo)]]
}

almacen_ids <- function(almacen, tipo) names(almacen_listar(almacen, tipo))

almacen_contar <- function(almacen, tipo) length(almacen_listar(almacen, tipo))

#' Reemplaza un objeto existente. Falla si el id no está: actualizar algo que
#' no existe siempre es un bug, no un alta silenciosa.
almacen_actualizar <- function(almacen, objeto) {
  tipo <- objeto$tipo
  if (is.null(almacen_obtener(almacen, tipo, objeto$id)))
    stop("no existe ", tipo, " con id: ", objeto$id)
  almacen[[.plural(tipo)]][[objeto$id]] <- objeto
  almacen
}

#' Elimina un objeto y, en cascada, las corridas que dependían de él.
#' Una corrida huérfana no se puede reproducir ni explicar: no vale la pena.
almacen_eliminar <- function(almacen, tipo, id) {
  tipo <- match.arg(tipo, TIPOS_OBJETO)
  almacen[[.plural(tipo)]][[id]] <- NULL

  if (tipo != "corrida") {
    campo <- paste0(tipo, "_id")
    huerfanas <- Filter(function(cor) identical(cor[[campo]], id),
                        almacen$corridas)
    for (cor in huerfanas) almacen$corridas[[cor$id]] <- NULL
  }
  almacen
}

#' Clona un objeto con id nuevo. Es la acción ⧉ del CRUD: la forma natural de
#' explorar variantes sin perder la original.
almacen_clonar <- function(almacen, tipo, id, sufijo = " (copia)") {
  original <- almacen_obtener(almacen, tipo, id)
  if (is.null(original)) stop("no existe ", tipo, " con id: ", id)
  copia <- original
  copia$id <- NULL
  if (!is.null(copia$nombre)) copia$nombre <- paste0(copia$nombre, sufijo)
  almacen_agregar(almacen, copia)
}

#' Vista tabular de un tipo, para tabla_paginada() y para el CRUD.
objetos_df <- function(almacen, tipo) {
  objetos <- almacen_listar(almacen, tipo)
  if (!length(objetos)) return(data.frame(
    id = character(0), nombre = character(0), resumen = character(0),
    creado = character(0), stringsAsFactors = FALSE))
  filas <- lapply(objetos, function(o) data.frame(
    id = o$id, nombre = o$nombre %||% "-", resumen = resumen_objeto(o),
    creado = o$creado, stringsAsFactors = FALSE))
  df <- do.call(rbind, filas)
  df[order(df$creado, decreasing = TRUE), ]
}

#' Las N corridas más recientes, para el panel de Inicio.
corridas_recientes <- function(almacen, n = 5L) {
  corridas <- almacen_listar(almacen, "corrida")
  if (!length(corridas)) return(list())
  orden <- order(vapply(corridas, `[[`, "", "creado"), decreasing = TRUE)
  corridas[utils::head(orden, n)]
}
