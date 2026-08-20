# learn/R/logica/modelo_geometria.R
#
# Responsabilidad: lo que se puede saber de un modelo ANTES de ajustarlo.
#
# La tesis de la fase 2: un modelo no es un resultado, es una familia de
# hipótesis. Se puede mirar el repertorio completo de lo que el método *puede*
# producir sobre estos datos sin haber estimado nada, y hacerlo primero es lo
# que evita tratar el ajuste como una caja negra.
#
# Cálculo puro: ni Shiny ni ggplot (C3).

#' El repertorio de ejes que una rotación puede elegir.
#'
#' Para el ACP la familia de hipótesis es literal: todas las direcciones de
#' norma 1 del plano de dos variables. Barriendo el ángulo se ve la varianza
#' proyectada subir y bajar; su máximo es la primera componente. El usuario
#' encuentra a mano lo que la fase 3 va a encontrar iterando.
#'
#' @param datos    data.frame
#' @param columnas exactamente dos columnas numéricas
#' @param n_angulos resolución del barrido en media vuelta (π basta: la
#'   dirección θ y la θ+π son el mismo eje)
#' @return data.frame(angulo, grados, varianza, proporcion)
familia_candidatas <- function(datos, columnas, n_angulos = 181L) {
  vacia <- data.frame(angulo = numeric(0), grados = numeric(0),
                      varianza = numeric(0), proporcion = numeric(0))
  if (length(columnas) != 2L) return(vacia)
  matriz <- as.matrix(datos[, columnas, drop = FALSE])
  matriz <- matriz[stats::complete.cases(matriz), , drop = FALSE]
  if (nrow(matriz) < 3L) return(vacia)

  centrada <- scale(matriz, center = TRUE, scale = FALSE)
  covarianzas <- stats::cov(centrada)
  total <- sum(diag(covarianzas))
  angulos <- seq(0, pi, length.out = n_angulos)

  varianzas <- vapply(angulos, function(theta) {
    direccion <- c(cos(theta), sin(theta))
    as.numeric(t(direccion) %*% covarianzas %*% direccion)
  }, numeric(1))

  data.frame(angulo = angulos, grados = angulos * 180 / pi,
             varianza = varianzas,
             proporcion = if (total > 0) varianzas / total else varianzas)
}

#' La proyección de los datos sobre una dirección elegida a mano.
#'
#' @return data.frame(x, y, proyectado_x, proyectado_y) con el pie de cada
#'   punto sobre el eje: el residuo que se ve es el error de reconstrucción.
proyectar_en_direccion <- function(datos, columnas, angulo) {
  matriz <- as.matrix(datos[, columnas, drop = FALSE])
  matriz <- matriz[stats::complete.cases(matriz), , drop = FALSE]
  if (nrow(matriz) < 1L)
    return(data.frame(x = numeric(0), y = numeric(0),
                      proyectado_x = numeric(0), proyectado_y = numeric(0)))

  centros <- colMeans(matriz)
  centrada <- scale(matriz, center = centros, scale = FALSE)
  direccion <- c(cos(angulo), sin(angulo))
  escalares <- as.numeric(centrada %*% direccion)
  data.frame(x = matriz[, 1], y = matriz[, 2],
             proyectado_x = centros[1] + escalares * direccion[1],
             proyectado_y = centros[2] + escalares * direccion[2])
}

#' Qué entra al modelo: dimensiones, rango y colinealidad de X.
#'
#' El rango es la comprobación que nadie hace y que explica la mitad de los
#' fallos: si dos columnas son combinación lineal de otras, la matriz no se
#' puede invertir y el método falla con un mensaje incomprensible. Mejor verlo
#' acá, con la palabra "colineales" escrita.
#'
#' @return data.frame(campo, valor, nota)
resumen_matriz_diseno <- function(datos, columnas) {
  columnas <- intersect(columnas, names(datos))
  fila <- function(campo, valor, nota = "") {
    data.frame(campo = campo, valor = as.character(valor), nota = nota)
  }
  if (length(columnas) < 1L)
    return(fila("columnas", 0, "elegi al menos una columna numerica"))

  matriz <- as.matrix(datos[, columnas, drop = FALSE])
  completas <- stats::complete.cases(matriz)
  matriz <- matriz[completas, , drop = FALSE]
  rango <- if (nrow(matriz)) qr(matriz)$rank else 0L

  rbind(
    fila("observaciones", nrow(matriz),
         if (sum(!completas)) sprintf("%d filas con faltantes quedaron fuera",
                                      sum(!completas)) else "todas completas"),
    fila("variables", length(columnas), paste(columnas, collapse = ", ")),
    fila("rango", rango,
         if (rango < length(columnas))
           "hay columnas colineales: sobra informacion repetida"
         else "columnas linealmente independientes"),
    fila("filas por variable",
         if (length(columnas)) sprintf("%.1f", nrow(matriz) / length(columnas)) else "-",
         "menos de 5 es poco para estimar con confianza"))
}

#' La función objetivo evaluada en una dirección elegida a mano.
#'
#' Es el puente pedagógico de la fase 2: acá el usuario ES el optimizador. Mueve
#' el ángulo, ve subir la varianza proyectada y bajar el error de
#' reconstrucción, y descubre que son el mismo movimiento visto de dos lados.
#' La fase 3 después le muestra cómo la máquina hace lo mismo, más rápido.
#'
#' @return list(varianza_proyectada, error_reconstruccion, proporcion, optimo)
evaluar_objetivo <- function(datos, columnas, angulo) {
  familia <- familia_candidatas(datos, columnas)
  if (!nrow(familia))
    return(list(varianza_proyectada = NA_real_, error_reconstruccion = NA_real_,
                proporcion = NA_real_, optimo = NA_real_, total = NA_real_))

  matriz <- as.matrix(datos[, columnas, drop = FALSE])
  matriz <- matriz[stats::complete.cases(matriz), , drop = FALSE]
  total <- sum(diag(stats::cov(matriz)))
  direccion <- c(cos(angulo), sin(angulo))
  proyectada <- as.numeric(t(direccion) %*% stats::cov(matriz) %*% direccion)

  list(varianza_proyectada = proyectada,
       error_reconstruccion = total - proyectada,
       proporcion = if (total > 0) proyectada / total else NA_real_,
       optimo = familia$angulo[which.max(familia$varianza)],
       total = total)
}

#' Cuántos parámetros se van a estimar y con cuántas observaciones.
#'
#' La pregunta que responde: ¿alcanzan los datos para lo que estoy pidiendo?
#' Un ACP con k componentes estima p·k cargas, menos k(k−1)/2 por la
#' ortogonalidad que ya no es libre, más las p medias del centrado.
#'
#' @return list(parametros, observaciones, razon, veredicto, detalle)
contar_parametros <- function(clave, p, n, k = NULL) {
  p <- as.integer(p); n <- as.integer(n)
  k <- as.integer(k %||% p)
  parametros <- switch(
    clave,
    # Los paréntesis no son decorativos: %/% liga más fuerte que *, y sin
    # ellos k*(k-1)%/%2 se lee k*((k-1)%/%2), que da cero para k = 2.
    acp = p * k - (k * (k - 1L)) %/% 2L + p,
    kmeans = p * k,
    p * k)

  razon <- if (parametros > 0) n / parametros else NA_real_
  veredicto <- if (is.na(razon)) "sin datos"
    else if (razon < 1) "mas parametros que observaciones"
    else if (razon < 5) "justo: cada parametro se apoya en pocas filas"
    else "holgado"

  list(parametros = parametros, observaciones = n, razon = razon,
       veredicto = veredicto,
       detalle = sprintf("%d parametros con %d observaciones (%.1f filas por parametro)",
                         parametros, n, razon))
}

#' El presupuesto como tabla, para dibujarlo barriendo k.
#'
#' @return data.frame(k, parametros, observaciones, razon, veredicto)
presupuesto_por_k <- function(clave, p, n, k_maximo = NULL) {
  k_maximo <- as.integer(k_maximo %||% p)
  ks <- seq_len(max(1L, k_maximo))
  partes <- lapply(ks, function(k) {
    cuenta <- contar_parametros(clave, p, n, k)
    data.frame(k = k, parametros = cuenta$parametros,
               observaciones = cuenta$observaciones, razon = cuenta$razon,
               veredicto = cuenta$veredicto)
  })
  do.call(rbind, partes)
}
