# learn/R/nucleo/claves.R
#
# Responsabilidad: dar a cada artefacto visual una clave estable y saber
# qué archivos lo producen (C9, trazabilidad).
#
# El caso de uso que justifica todo esto: el usuario ve un resultado que no
# entiende, abre un chat y pregunta "¿por qué la ROC me dio esto?". Para que
# un agente pueda responder sin adivinar, necesita llegar del gráfico al
# código. La clave es ese puente.
#
# Formato de clave: fase.subseccion.artefacto  ->  "f4.desempeno.roc"
#
# Las filas viven en artefactos.R; aquí solo está el mecanismo.

.ARTEFACTOS <- new.env(parent = emptyenv())

.PATRON_CLAVE <- "^f[0-9]\\.[a-z0-9_]+\\.[a-z0-9_]+$"

#' Registra un artefacto visual.
#'
#' @param clave       "fase.subseccion.artefacto", ASCII minúsculas
#' @param titulo      nombre legible con tildes. Ej: "Curva ROC"
#' @param grafico     "graficos/g_desempeno.R::graficar_roc" o NA
#' @param logica      "logica/metricas_clasificacion.R::metricas_clasificacion" o NA
#' @param texto       ruta al .md; por defecto textos/<clave>.md
#' @param descripcion una frase: qué es este artefacto
registrar_artefacto <- function(clave, titulo, grafico = NA_character_,
                                logica = NA_character_, texto = NULL,
                                descripcion = "") {
  if (!grepl(.PATRON_CLAVE, clave))
    stop("clave de artefacto inválida (fase.subseccion.artefacto): ", clave)
  if (!is.null(.ARTEFACTOS[[clave]]))
    stop("clave de artefacto duplicada: ", clave)

  .ARTEFACTOS[[clave]] <- list(
    clave = clave, titulo = titulo,
    fase = substr(clave, 1, 2),
    subseccion = strsplit(clave, ".", fixed = TRUE)[[1]][2],
    grafico = grafico, logica = logica,
    texto = texto %||% ruta_texto_de(clave),
    descripcion = descripcion
  )
  invisible(clave)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Ruta por defecto del texto de una clave.
#'
#' Una carpeta por fase y por subsección, igual que `R/ui/`: la clave
#' `f1.analisis.histograma` se escribe en `textos/f1/analisis/histograma.md`.
#' Con 79 artefactos, una carpeta plana deja de ser navegable.
ruta_texto_de <- function(clave) {
  partes <- strsplit(clave, ".", fixed = TRUE)[[1]]
  if (length(partes) != 3L) return(file.path("textos", paste0(clave, ".md")))
  file.path("textos", partes[1], partes[2], paste0(partes[3], ".md"))
}

claves_artefactos <- function() sort(ls(.ARTEFACTOS))

existe_artefacto <- function(clave) !is.null(.ARTEFACTOS[[clave]])

artefacto <- function(clave) {
  registro <- .ARTEFACTOS[[clave]]
  if (is.null(registro)) stop("artefacto no registrado: ", clave)
  registro
}

titulo_de <- function(clave) {
  if (!existe_artefacto(clave)) return(clave)
  artefacto(clave)$titulo
}

#' Rutas de un artefacto, relativas a learn/, más si el texto existe en disco.
rutas_de <- function(clave) {
  a <- artefacto(clave)
  list(
    clave   = clave,
    titulo  = a$titulo,
    grafico = a$grafico,
    logica  = a$logica,
    texto   = a$texto,
    hay_texto = file.exists(ruta_app(a$texto))
  )
}

#' Vista tabular, para MAPA.md y para tablas de UI.
artefactos_df <- function() {
  filas <- lapply(claves_artefactos(), function(k) {
    a <- artefacto(k)
    data.frame(clave = a$clave, titulo = a$titulo, fase = a$fase,
               subseccion = a$subseccion,
               grafico = ifelse(is.na(a$grafico), "", a$grafico),
               logica  = ifelse(is.na(a$logica), "", a$logica),
               texto   = a$texto,
               hay_texto = file.exists(ruta_app(a$texto)),
               descripcion = a$descripcion,
               stringsAsFactors = FALSE)
  })
  if (!length(filas)) return(data.frame())
  do.call(rbind, filas)
}

# ---------------------------------------------------------------------------
# El bloque de contexto
#
# Lo que el usuario copia y pega en un chat. Todo lo que hace falta para
# reconstruir la derivación de un resultado: dónde está el código, con qué
# datos, con qué parámetros y qué salió.
# ---------------------------------------------------------------------------

.linea_json <- function(x) {
  if (is.null(x) || !length(x)) return("-")
  if (is.character(x) && length(x) == 1 && !is.null(names(x))) return(x)
  tryCatch(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 6),
           error = function(e) paste(utils::capture.output(str(x)), collapse = " "))
}

.linea <- function(etiqueta, valor) {
  if (is.null(valor) || identical(valor, "") || (length(valor) == 1 && is.na(valor)))
    return(NULL)
  sprintf("%-9s: %s", etiqueta, valor)
}

#' Construye el bloque de contexto de un artefacto.
#'
#' @param clave     clave del artefacto
#' @param corrida   objeto corrida (ver estado.R) o NULL
#' @param params    lista de parámetros vigentes
#' @param metricas  lista de métricas resultantes
#' @param muestreo  texto describiendo el muestreo aplicado, o NULL
#' @return un character(1) multilínea, listo para pegar en un chat
contexto_de <- function(clave, corrida = NULL, params = NULL,
                        metricas = NULL, muestreo = NULL) {
  a <- if (existe_artefacto(clave)) artefacto(clave) else
    list(clave = clave, titulo = clave, grafico = NA, logica = NA,
         texto = NA, descripcion = "")

  con_prefijo <- function(x) if (is.na(x)) NA_character_ else file.path("learn", x)

  lineas <- c(
    "### Contexto SDA Lab",
    .linea("clave",   a$clave),
    .linea("titulo",  a$titulo),
    .linea("grafico", con_prefijo(a$grafico)),
    .linea("logica",  con_prefijo(a$logica)),
    .linea("texto",   con_prefijo(a$texto))
  )

  if (!is.null(corrida)) {
    lineas <- c(lineas,
      .linea("corrida", sprintf("%s = dataset %s x modelo %s x receta %s",
                                corrida$id, corrida$dataset_id,
                                corrida$modelo_id, corrida$receta_id)))
    if (!is.null(corrida$metodo) && existe_metodo(corrida$metodo)) {
      lineas <- c(lineas, .linea("metodo", sprintf(
        "%s  (ficha: learn/%s)", corrida$metodo, metodo(corrida$metodo)$ficha)))
    }
    lineas <- c(lineas, .linea("json", file.path("learn", "outputs",
                                                 paste0(corrida$id, ".json"))))
  }

  lineas <- c(lineas,
    .linea("params",   .linea_json(params %||% corrida$params)),
    .linea("metricas", .linea_json(metricas %||% corrida$metricas)),
    .linea("muestreo", muestreo),
    .linea("modo",     modo_ejecucion())
  )

  paste(Filter(Negate(is.null), lineas), collapse = "\n")
}

#' Vacía el registro de artefactos. Solo para las pruebas.
limpiar_artefactos <- function() {
  rm(list = ls(.ARTEFACTOS), envir = .ARTEFACTOS)
  invisible(TRUE)
}
