# learn/R/logica/traza.R
#
# Responsabilidad: registrar lo que pasa dentro de un optimizador, iteración
# por iteración.
#
# Es la pieza que hace observable la fase 3. Sin traza, "ajustar" es una caja
# negra que tarda un rato y devuelve un número; con traza se puede contestar la
# pregunta que enseña: ¿se detuvo porque convergió o porque se le acabaron las
# iteraciones?
#
# Deliberadamente genérica: no sabe nada de ACP ni de k-medias. Un optimizador
# le pasa el valor de su función objetivo y, si quiere, los parámetros de esa
# iteración. El ACP registra el error de reconstrucción; k-medias registrará la
# inercia intra-grupo. La estructura es la misma.

#' Traza vacía.
#'
#' @param objetivo nombre de lo que desciende ("error de reconstruccion",
#'   "inercia"). Viaja al eje Y del gráfico y al bloque de contexto.
#' @param sentido "desciende" o "asciende": la log-verosimilitud sube, el error
#'   baja. Sin esto no se puede juzgar si una traza es sana.
nueva_traza <- function(objetivo = "objetivo", sentido = "desciende") {
  structure(list(objetivo = objetivo, sentido = sentido, filas = list()),
            class = "traza_sda")
}

#' Añade una iteración. Devuelve una traza nueva, no muta (C3).
#'
#' @param componente para métodos que optimizan por partes (el ACP deflaciona
#'   una componente por vez). 1 cuando hay un solo problema.
#' @param parametros numeric con nombre, o NULL. Es lo que dibuja la
#'   trayectoria: qué parámetro tardó más en estabilizarse.
registrar_iteracion <- function(traza, iter, objetivo, delta = NA_real_,
                                componente = 1L, parametros = NULL) {
  fila <- list(componente = as.integer(componente), iter = as.integer(iter),
               objetivo = as.numeric(objetivo), delta = as.numeric(delta),
               parametros = parametros)
  traza$filas[[length(traza$filas) + 1L]] <- fila
  traza
}

#' La traza como tabla: una fila por iteración.
#'
#' @return data.frame(componente, iter, objetivo, delta)
traza_a_tabla <- function(traza) {
  vacia <- data.frame(componente = integer(0), iter = integer(0),
                      objetivo = numeric(0), delta = numeric(0))
  if (is.null(traza) || !length(traza$filas)) return(vacia)
  campo <- function(nombre, tipo) vapply(traza$filas, `[[`, tipo, nombre)
  data.frame(componente = campo("componente", integer(1)),
             iter = campo("iter", integer(1)),
             objetivo = campo("objetivo", numeric(1)),
             delta = campo("delta", numeric(1)))
}

#' Los parámetros de cada iteración, en formato largo.
#'
#' @return data.frame(componente, iter, parametro, valor)
parametros_a_tabla <- function(traza) {
  vacia <- data.frame(componente = integer(0), iter = integer(0),
                      parametro = character(0), valor = numeric(0))
  if (is.null(traza) || !length(traza$filas)) return(vacia)
  con_parametros <- Filter(function(f) length(f$parametros), traza$filas)
  if (!length(con_parametros)) return(vacia)

  partes <- lapply(con_parametros, function(f) {
    data.frame(componente = f$componente, iter = f$iter,
               parametro = names(f$parametros),
               valor = as.numeric(f$parametros))
  })
  do.call(rbind, partes)
}

#' Iteraciones registradas por componente.
iteraciones_traza <- function(traza) {
  tabla <- traza_a_tabla(traza)
  if (!nrow(tabla)) return(0L)
  nrow(tabla)
}

#' ¿La traza es sana? Comprueba que el objetivo se mueva en el sentido que el
#' optimizador promete. Una traza que sube cuando debería bajar es un bug del
#' método, no un mal ajuste, y conviene verlo en la prueba y no en pantalla.
traza_monotona <- function(traza, tolerancia = 1e-8) {
  tabla <- traza_a_tabla(traza)
  if (nrow(tabla) < 2L) return(TRUE)
  por_componente <- split(tabla$objetivo, tabla$componente)
  signo <- if (identical(traza$sentido, "asciende")) -1 else 1
  all(vapply(por_componente, function(valores) {
    if (length(valores) < 2L) return(TRUE)
    all(signo * diff(valores) <= tolerancia)
  }, logical(1)))
}

#' Varias trazas del mismo problema con distinta semilla, lado a lado.
#'
#' Responde "¿óptimo local o global?": si todos los reinicios llegan al mismo
#' valor, la superficie no tiene dónde esconderse.
#'
#' @param trazas lista con nombre: semilla -> traza
#' @return data.frame(reinicio, semilla, iteraciones, objetivo_final)
comparar_reinicios <- function(trazas) {
  vacia <- data.frame(reinicio = integer(0), semilla = character(0),
                      iteraciones = integer(0), objetivo_final = numeric(0))
  if (!length(trazas)) return(vacia)
  etiquetas <- names(trazas) %||% as.character(seq_along(trazas))
  partes <- lapply(seq_along(trazas), function(i) {
    tabla <- traza_a_tabla(trazas[[i]])
    if (!nrow(tabla)) return(NULL)
    data.frame(reinicio = i, semilla = etiquetas[i],
               iteraciones = nrow(tabla),
               objetivo_final = tabla$objetivo[nrow(tabla)])
  })
  partes <- Filter(Negate(is.null), partes)
  if (!length(partes)) return(vacia)
  do.call(rbind, partes)
}
