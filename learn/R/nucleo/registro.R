# learn/R/nucleo/registro.R
#
# Responsabilidad: guardar y consultar el catálogo de métodos.
#
# Una tabla declarativa gobierna toda la app: el catálogo de la fase 2 se
# dibuja recorriéndola, los filtros son consultas sobre sus columnas, los
# candados son `estado != "activo"`, la UI de hiperparámetros se genera desde
# `hiper`, y el bundle wasm filtra por `wasm`. Añadir un método es añadir una
# fila (en catalogo.R) y un archivo (en metodos/).
#
# Este archivo NO contiene ninguna fila: solo el mecanismo. Las filas viven en
# catalogo.R para que crezcan sin tocar la lógica.

OBJETIVOS <- c("describir", "reducir", "agrupar", "clasificar",
               "predecir", "contrastar")

# activo    = se puede ejecutar aquí
# pendiente = está en el temario, todavía sin implementar
# bloqueado = no se puede ejecutar nunca aquí (ver `motivo`); se muestra igual
ESTADOS <- c("activo", "pendiente", "bloqueado")

SUPERVISION <- c("supervisado", "no_supervisado", "ninguna")

.REGISTRO <- new.env(parent = emptyenv())

#' Registra un método en el catálogo.
#'
#' @param clave       identificador ASCII único, minúsculas. Ej: "kmeans"
#' @param nombre      nombre legible con tildes. Ej: "K-medias"
#' @param objetivo    uno de OBJETIVOS
#' @param supervision uno de SUPERVISION
#' @param sesion      sesión del curso 1..8 (ver guide-eda-26A.md), o NA
#' @param nodo        ancla teórica en notes/tree.md. Ej: "100-agrupamiento/020-kmeans"
#' @param estado      uno de ESTADOS
#' @param wasm        TRUE si entra al bundle del navegador
#' @param deps        paquetes CRAN que necesita
#' @param entrada     requisitos sobre los datos: list(tipo, min_p, faltantes, ...)
#' @param hiper       hiperparámetros del MODELO (no los del ajuste), ver ui_formulario.R
#' @param optimizador list(metodos, traza, paso_a_paso) o NULL si no itera
#' @param supuestos   claves de supuestos a verificar antes de ajustar
#' @param artefactos  claves de artefacto que este método produce (ver claves.R)
#' @param ajustar     función PURA de ajuste, o NULL mientras no exista
#' @param motivo      por qué está bloqueado; obligatorio si estado == "bloqueado"
#' @param puente      frase que conecta un método bloqueado con uno ejecutable
registrar_metodo <- function(clave, nombre, objetivo, supervision = "ninguna",
                             sesion = NA_integer_, nodo = NA_character_,
                             estado = "pendiente", wasm = TRUE,
                             deps = character(0), entrada = list(),
                             hiper = list(), optimizador = NULL,
                             supuestos = character(0), artefactos = character(0),
                             ajustar = NULL, motivo = NA_character_,
                             puente = NA_character_) {

  if (!grepl("^[a-z0-9_]+$", clave))
    stop("clave inválida (solo a-z, 0-9, _): ", clave)
  if (!is.null(.REGISTRO[[clave]]))
    stop("clave duplicada en el catálogo: ", clave)
  objetivo    <- match.arg(objetivo, OBJETIVOS)
  supervision <- match.arg(supervision, SUPERVISION)
  estado      <- match.arg(estado, ESTADOS)
  if (estado == "bloqueado" && is.na(motivo))
    stop("un método bloqueado necesita `motivo`: ", clave)
  if (estado == "activo" && is.null(ajustar))
    stop("un método activo necesita `ajustar`: ", clave)

  .REGISTRO[[clave]] <- list(
    clave = clave, nombre = nombre, objetivo = objetivo,
    supervision = supervision, sesion = sesion, nodo = nodo,
    estado = estado, wasm = isTRUE(wasm), deps = deps, entrada = entrada,
    hiper = hiper, optimizador = optimizador, supuestos = supuestos,
    artefactos = artefactos, ajustar = ajustar,
    motivo = motivo, puente = puente,
    ficha = file.path("fichas", paste0(clave, ".md"))
  )
  invisible(clave)
}

#' Claves de todos los métodos registrados, en orden alfabético.
claves_metodos <- function() sort(ls(.REGISTRO))

#' Un método por su clave. Falla fuerte: una clave inexistente es un bug.
metodo <- function(clave) {
  registro <- .REGISTRO[[clave]]
  if (is.null(registro)) stop("método no registrado: ", clave)
  registro
}

existe_metodo <- function(clave) !is.null(.REGISTRO[[clave]])

#' Todos los métodos como lista.
metodos <- function() lapply(claves_metodos(), metodo)

#' Filtra el catálogo. Cada argumento NULL significa "no filtrar por esto".
#'
#' @param busqueda texto libre; busca en nombre y clave, sin distinguir mayúsculas
#' @return character() de claves
filtrar_metodos <- function(objetivo = NULL, sesion = NULL, estado = NULL,
                            supervision = NULL, wasm = NULL, busqueda = NULL) {
  claves <- claves_metodos()
  coincide <- function(clave) {
    m <- metodo(clave)
    if (!is.null(objetivo)    && !m$objetivo %in% objetivo)       return(FALSE)
    if (!is.null(supervision) && !m$supervision %in% supervision) return(FALSE)
    if (!is.null(estado)      && !m$estado %in% estado)           return(FALSE)
    if (!is.null(sesion)      && !(m$sesion %in% sesion))         return(FALSE)
    if (!is.null(wasm)        && !identical(m$wasm, isTRUE(wasm))) return(FALSE)
    if (!is.null(busqueda) && nzchar(busqueda)) {
      aguja <- tolower(busqueda)
      pajar <- tolower(paste(m$clave, m$nombre, m$objetivo))
      if (!grepl(aguja, pajar, fixed = TRUE)) return(FALSE)
    }
    TRUE
  }
  Filter(coincide, claves)
}

#' ¿Se puede ejecutar este método en el modo actual?
#' Un método activo pero no-wasm es ejecutable en servidor y no en navegador.
ejecutable <- function(clave) {
  m <- metodo(clave)
  m$estado == "activo" && (m$wasm || !es_wasm())
}

#' Vista tabular del catálogo, para tablas de UI y para MAPA.md.
metodos_df <- function() {
  filas <- lapply(metodos(), function(m) data.frame(
    clave = m$clave, nombre = m$nombre, objetivo = m$objetivo,
    supervision = m$supervision, sesion = m$sesion, estado = m$estado,
    wasm = m$wasm, deps = paste(m$deps, collapse = " "),
    nodo = ifelse(is.na(m$nodo), "", m$nodo),
    artefactos = length(m$artefactos),
    stringsAsFactors = FALSE))
  if (!length(filas)) return(data.frame())
  df <- do.call(rbind, filas)
  df[order(df$sesion, df$objetivo, df$nombre), ]
}

#' Conteo por estado, para la franja de progreso del Inicio.
resumen_catalogo <- function() {
  df <- metodos_df()
  if (!nrow(df)) return(setNames(integer(length(ESTADOS)), ESTADOS))
  conteo <- table(factor(df$estado, levels = ESTADOS))
  stats::setNames(as.integer(conteo), names(conteo))
}

#' Progreso por sesión del curso: cuántos activos sobre el total.
progreso_por_sesion <- function() {
  df <- metodos_df()
  if (!nrow(df)) return(data.frame())
  df <- df[!is.na(df$sesion), ]
  agregado <- lapply(split(df, df$sesion), function(g) data.frame(
    sesion = g$sesion[1], total = nrow(g),
    activos = sum(g$estado == "activo"),
    stringsAsFactors = FALSE))
  do.call(rbind, agregado)
}

#' Vacía el registro. Solo para las pruebas.
limpiar_registro <- function() {
  rm(list = ls(.REGISTRO), envir = .REGISTRO)
  invisible(TRUE)
}
