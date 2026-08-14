# learn/R/nucleo/contratos.R
#
# Responsabilidad: decir si un Dataset, un Modelo y una Receta se pueden
# componer, y por qué no cuando la respuesta es no.
#
# Es el panel de "Compatibilidad" de la fase 4. Su valor pedagógico está en
# los mensajes: un método no falla por capricho, falla porque sus supuestos de
# ENTRADA no se cumplen, y ese es justo el momento de explicarlo.
#
# Devuelve siempre una lista de avisos, nunca lanza. Un error de composición
# es información para el usuario, no una excepción.

SEVERIDADES <- c("ok", "aviso", "error")

.aviso <- function(severidad, clave, mensaje, sugerencia = NA_character_) {
  list(severidad = severidad, clave = clave, mensaje = mensaje,
       sugerencia = sugerencia)
}

#' Valida la composición de los tres objetos.
#'
#' @param dataset objeto dataset, o NULL si todavía no se eligió
#' @param modelo  objeto modelo, o NULL
#' @param receta  objeto receta, o NULL
#' @return lista de avisos; usar severidad_maxima() para el veredicto
validar_compatibilidad <- function(dataset = NULL, modelo = NULL, receta = NULL) {
  avisos <- list()
  agregar <- function(...) avisos[[length(avisos) + 1L]] <<- .aviso(...)

  # --- Piezas presentes -------------------------------------------------
  if (is.null(dataset)) agregar("error", "sin_dataset", "Falta elegir un dataset.")
  if (is.null(modelo))  agregar("error", "sin_modelo",  "Falta elegir un modelo.")
  if (is.null(receta))  agregar("aviso", "sin_receta",
    "Sin receta: se usará el control por defecto del método.")
  if (is.null(dataset) || is.null(modelo)) return(avisos)

  m <- metodo(modelo$metodo)

  # --- ¿Se puede ejecutar aquí? ----------------------------------------
  if (m$estado == "bloqueado") {
    agregar("error", "bloqueado", m$motivo,
            if (!is.na(m$puente)) m$puente else NA_character_)
  } else if (m$estado == "pendiente") {
    agregar("error", "pendiente",
            sprintf("%s todavía no está implementado.", m$nombre))
  } else if (!m$wasm && es_wasm()) {
    agregar("error", "no_wasm", motivo_no_ejecutable(m$nombre),
            "Corré la app sobre R completo.")
  }

  # --- Dependencias -----------------------------------------------------
  faltantes <- Filter(function(p) !requireNamespace(p, quietly = TRUE), m$deps)
  if (length(faltantes)) {
    agregar("error", "deps",
            sprintf("Faltan paquetes: %s.", paste(faltantes, collapse = ", ")),
            sprintf('install.packages(c("%s")); renv::snapshot()',
                    paste(faltantes, collapse = '","')))
  }

  avisos <- c(avisos, .validar_entrada(dataset, m))
  avisos <- c(avisos, .validar_receta(receta, m))
  if (!length(avisos)) avisos <- list(.aviso("ok", "todo", "Composición válida."))
  avisos
}

# ---------------------------------------------------------------------------
# Requisitos del método sobre los datos
# ---------------------------------------------------------------------------
.validar_entrada <- function(dataset, m) {
  avisos <- list()
  agregar <- function(...) avisos[[length(avisos) + 1L]] <<- .aviso(...)
  requisitos <- m$entrada

  numericas <- columnas_numericas(dataset)
  min_p <- requisitos$min_p %||% 0L
  if (length(numericas) < min_p) {
    agregar("error", "min_p",
            sprintf("%s necesita al menos %d variables numéricas; el dataset tiene %d.",
                    m$nombre, min_p, length(numericas)),
            "Revisá la clase de cada columna en el Diccionario de la fase 1.")
  }

  min_n <- requisitos$min_n %||% 0L
  if (dataset$n < min_n) {
    agregar("error", "min_n",
            sprintf("%s necesita al menos %d observaciones; hay %d.",
                    m$nombre, min_n, dataset$n))
  }

  if (identical(requisitos$faltantes, FALSE)) {
    columnas <- if (length(numericas)) numericas else names(dataset$df)
    con_na <- vapply(dataset$df[columnas], function(x) any(is.na(x)), logical(1))
    if (any(con_na)) {
      agregar("error", "faltantes",
              sprintf("%s no admite faltantes y hay NA en: %s.", m$nombre,
                      paste(names(con_na)[con_na], collapse = ", ")),
              "Imputá o descartá en Datos → Calidad.")
    }
  }

  if (isTRUE(requisitos$respuesta) && !length(columnas_con_rol(dataset, "respuesta"))) {
    agregar("error", "sin_respuesta",
            sprintf("%s es un método supervisado y ninguna columna tiene rol de respuesta.",
                    m$nombre),
            "Asigná el rol en Datos → Diccionario.")
  }

  if (isTRUE(requisitos$grupo) && !length(columnas_con_rol(dataset, "grupo"))) {
    agregar("error", "sin_grupo",
            sprintf("%s compara grupos y ninguna columna tiene rol de grupo.", m$nombre),
            "Asigná el rol en Datos → Diccionario.")
  }

  if (isTRUE(requisitos$escalado) && !.esta_escalado(dataset)) {
    agregar("aviso", "escalado",
            sprintf("%s es sensible a la escala y el dataset no está estandarizado.",
                    m$nombre),
            "Aplicá 'escalar' en Datos → Transformación, o entendé que la variable de mayor varianza dominará.")
  }

  if (m$supervision == "supervisado" && is.null(dataset$particion)) {
    agregar("aviso", "sin_particion",
            "Sin partición: el desempeño se medirá sobre los mismos datos del ajuste.",
            "Definí train/test en Datos → Partición para tener una medida honesta.")
  }

  avisos
}

.esta_escalado <- function(dataset) {
  transformaciones <- vapply(dataset$transformaciones,
                             function(t) t$tipo %||% "", "")
  any(transformaciones %in% c("escalar", "z"))
}

# ---------------------------------------------------------------------------
# Coherencia entre la receta y el optimizador del método
# ---------------------------------------------------------------------------
.validar_receta <- function(receta, m) {
  if (is.null(receta) || is.null(m$optimizador)) return(list())
  disponibles <- m$optimizador$metodos %||% character(0)
  if (!is.na(receta$optimizador) && length(disponibles) &&
      !receta$optimizador %in% disponibles) {
    return(list(.aviso("error", "optimizador",
      sprintf("%s no admite el optimizador '%s'.", m$nombre, receta$optimizador),
      sprintf("Disponibles: %s.", paste(disponibles, collapse = ", ")))))
  }
  list()
}

# ---------------------------------------------------------------------------
# Veredicto
# ---------------------------------------------------------------------------

#' La severidad más grave de una lista de avisos.
severidad_maxima <- function(avisos) {
  if (!length(avisos)) return("ok")
  niveles <- vapply(avisos, `[[`, "", "severidad")
  SEVERIDADES[max(match(niveles, SEVERIDADES))]
}

#' ¿Se puede correr esta composición?
componible <- function(avisos) severidad_maxima(avisos) != "error"

#' Resumen de una línea para la franja de estado de la fase 4.
resumen_compatibilidad <- function(avisos) {
  niveles <- vapply(avisos, `[[`, "", "severidad")
  sprintf("%d error(es) · %d aviso(s)",
          sum(niveles == "error"), sum(niveles == "aviso"))
}
