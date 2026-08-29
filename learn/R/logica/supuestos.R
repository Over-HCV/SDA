# learn/R/logica/supuestos.R
#
# Responsabilidad: evaluar sobre el dataset actual los supuestos que un método
# declara, ANTES de ajustar.
#
# `registrar_metodo(supuestos = c(...))` hasta ahora solo se imprimía en la
# ficha. Acá cada clave se convierte en una comprobación con veredicto, y el
# semáforo de la fase 2 se dibuja recorriendo el registro: añadir un supuesto a
# un método es añadir una fila, no una vista.
#
# Devuelve avisos con la MISMA forma que contratos.R
# (severidad/clave/mensaje/sugerencia), así que `lista_avisos()` los pinta sin
# una línea de UI nueva. La diferencia con validar_compatibilidad() es de
# momento y de tono: aquel dice si se PUEDE correr, este dice si CONVIENE.

#' Evalúa los supuestos declarados por un método sobre un dataset.
#'
#' @param clave    clave del método en el registro
#' @param dataset  objeto dataset de nucleo/estado.R
#' @param columnas columnas que entrarían al modelo; NULL = las numéricas
#' @return lista de avisos, vacía solo si el método no declara supuestos
evaluar_supuestos <- function(clave, dataset, columnas = NULL) {
  if (is.null(dataset)) return(list())
  m <- metodo(clave)
  if (!length(m$supuestos)) return(list())
  columnas <- intersect(columnas %||% columnas_numericas(dataset),
                        names(dataset$df))

  evaluados <- lapply(m$supuestos, function(supuesto) {
    comprobar <- .COMPROBACIONES_SUPUESTO[[supuesto]]
    if (is.null(comprobar)) return(.supuesto_sin_prueba(supuesto))
    comprobar(dataset, columnas)
  })
  Filter(Negate(is.null), evaluados)
}

#' Los supuestos de un método con su nombre legible, hayan o no comprobación.
#' Lo usa la ficha, que los lista aunque no haya dataset cargado.
nombre_supuesto <- function(supuesto) {
  legibles <- c(escalado_previo = "escalado previo",
                estructura_lineal = "estructura lineal",
                sin_atipicos = "sin atipicos influyentes",
                grupos_esfericos = "grupos esfericos",
                tamanos_similares = "tamanos de grupo similares",
                normalidad = "normalidad",
                homocedasticidad = "homocedasticidad",
                independencia = "observaciones independientes")
  legibles[[supuesto]] %||% gsub("_", " ", supuesto)
}

.supuesto_sin_prueba <- function(supuesto) {
  .aviso("aviso", supuesto,
         sprintf("%s: sin comprobacion automatica todavia.",
                 nombre_supuesto(supuesto)),
         "Se declara en el registro; la prueba entra cuando el metodo la use.")
}

# ---------------------------------------------------------------------------
# Una comprobación por supuesto. Cada una devuelve un aviso, nunca lanza.
# ---------------------------------------------------------------------------

.supuesto_escalado <- function(dataset, columnas) {
  if (.esta_escalado(dataset))
    return(.aviso("ok", "escalado_previo",
                  "Escalado previo: el dataset esta estandarizado."))
  desviaciones <- vapply(dataset$df[columnas],
                         function(x) stats::sd(x, na.rm = TRUE), numeric(1))
  desviaciones <- desviaciones[is.finite(desviaciones) & desviaciones > 0]
  if (length(desviaciones) < 2L)
    return(.aviso("aviso", "escalado_previo",
                  "Escalado previo: no hay suficientes columnas para juzgarlo."))

  razon <- max(desviaciones) / min(desviaciones)
  if (razon < 3)
    return(.aviso("ok", "escalado_previo",
                  sprintf("Escalado previo: las desviaciones son comparables (la mayor es %.1f veces la menor).",
                          razon)))
  .aviso("aviso", "escalado_previo",
         sprintf("Escalado previo: %s varia %.0f veces mas que %s, y va a dominar el resultado.",
                 names(which.max(desviaciones)), razon,
                 names(which.min(desviaciones))),
         "Descomponer la correlacion (R) equivale a estandarizar, o aplica 'escalar' en Datos - Transformacion.")
}

.supuesto_lineal <- function(dataset, columnas) {
  if (length(columnas) < 2L)
    return(.aviso("aviso", "estructura_lineal",
                  "Estructura lineal: hacen falta al menos dos variables numericas."))
  matriz <- stats::cor(dataset$df[columnas], use = "pairwise.complete.obs")
  fuera <- abs(matriz[upper.tri(matriz)])
  fuera <- fuera[is.finite(fuera)]
  if (!length(fuera))
    return(.aviso("aviso", "estructura_lineal",
                  "Estructura lineal: no se pudo calcular la correlacion."))

  maxima <- max(fuera)
  if (maxima < 0.3)
    return(.aviso("aviso", "estructura_lineal",
                  sprintf("Estructura lineal: la correlacion mas alta es %.2f. Con variables casi independientes no hay redundancia que resumir.",
                          maxima),
                  "Mira el mapa de calor en Datos - Analisis: si no hay bloques, reducir no va a ganar mucho."))
  .aviso("ok", "estructura_lineal",
         sprintf("Estructura lineal: hay correlaciones que resumir (la mayor es %.2f).",
                 maxima))
}

.supuesto_atipicos <- function(dataset, columnas) {
  if (length(columnas) < 2L)
    return(.aviso("aviso", "sin_atipicos",
                  "Atipicos: hacen falta al menos dos variables numericas."))
  distancias <- mahalanobis_cuadrado(dataset$df, columnas)
  validas <- distancias[!is.na(distancias)]
  if (!length(validas))
    return(.aviso("aviso", "sin_atipicos",
                  "Atipicos: la covarianza es singular, hay colinealidad exacta.",
                  "Quita una de las columnas repetidas en Datos - Diccionario."))

  corte <- stats::qchisq(0.975, df = length(columnas))
  cuantos <- sum(validas > corte)
  proporcion <- cuantos / length(validas)
  if (proporcion <= 0.05)
    return(.aviso("ok", "sin_atipicos",
                  sprintf("Atipicos: %d de %d filas superan el corte chi-cuadrado (%.1f%%), dentro de lo esperable.",
                          cuantos, length(validas), 100 * proporcion)))
  .aviso("aviso", "sin_atipicos",
         sprintf("Atipicos: %d de %d filas (%.1f%%) quedan lejos del centro. La varianza es una media de cuadrados: un punto lejano puede torcer la primera componente el solo.",
                 cuantos, length(validas), 100 * proporcion),
         "Miralos en Datos - Calidad con el criterio de Mahalanobis antes de ajustar.")
}


# k-medias corta el espacio con esferas del mismo tamaño: asigna cada punto al
# centroide más cercano en distancia euclidiana. Si la nube es un cigarro, la
# frontera correcta no es una esfera y la partición sale cortando el cigarro a
# lo ancho. La razón entre el mayor y el menor valor propio de la correlación
# mide justamente eso.
.supuesto_esfericos <- function(dataset, columnas) {
  if (length(columnas) < 2L)
    return(.aviso("aviso", "grupos_esfericos",
                  "Grupos esfericos: hacen falta al menos dos variables numericas."))
  matriz <- stats::cor(dataset$df[columnas], use = "pairwise.complete.obs")
  valores <- tryCatch(eigen(matriz, symmetric = TRUE, only.values = TRUE)$values,
                      error = function(e) NULL)
  valores <- valores[is.finite(valores) & valores > 1e-10]
  if (length(valores) < 2L)
    return(.aviso("aviso", "grupos_esfericos",
                  "Grupos esfericos: la correlacion es singular, hay colinealidad exacta.",
                  "Quita una de las columnas repetidas en Datos - Diccionario."))

  razon <- max(valores) / min(valores)
  if (razon < 20)
    return(.aviso("ok", "grupos_esfericos",
                  sprintf("Grupos esfericos: la nube no esta muy alargada (razon de valores propios %.1f).",
                          razon)))
  .aviso("aviso", "grupos_esfericos",
         sprintf("Grupos esfericos: la nube es %.0f veces mas larga en una direccion que en otra. Las esferas de k-medias van a cortarla a lo ancho.",
                 razon),
         "Mira el elipsoide en Datos - Analisis - Multivariado, o reduce con ACP antes de agrupar.")
}

# Antes de ajustar no hay grupos cuyos tamaños comparar. Lo que sí se puede
# mirar es si el dataset da para los grupos que se van a pedir: con n < 2k, el
# tamaño medio de grupo es menor que dos y la partición no significa nada.
.supuesto_tamanos <- function(dataset, columnas) {
  n <- nrow(dataset$df)
  techo <- n %/% 2L
  if (techo < 2L)
    return(.aviso("error", "tamanos_similares",
                  sprintf("Tamanos de grupo similares: con %d filas no alcanza para dos grupos.",
                          n)))
  .aviso("ok", "tamanos_similares",
         sprintf("Tamanos de grupo similares: %d filas dan para k hasta %d sin que un grupo quede con menos de dos observaciones.",
                 n, techo),
         "k-medias parte antes un grupo grande que dejar uno pequeno: revisa los tamanos en Evaluacion - Desempeno.")
}

.COMPROBACIONES_SUPUESTO <- list(
  escalado_previo = .supuesto_escalado,
  estructura_lineal = .supuesto_lineal,
  sin_atipicos = .supuesto_atipicos,
  grupos_esfericos = .supuesto_esfericos,
  tamanos_similares = .supuesto_tamanos)
