# learn/R/logica/metricas_grupos.R
#
# Responsabilidad: traducir un ajuste de agrupamiento a las tablas que se
# dibujan y se exportan.
#
# La hermana de `metricas_reduccion.R` para la otra familia. Sirve para
# k-medias y, sin cambios, para cualquier método que devuelva `grupos`,
# `centroides` y la matriz `z` sobre la que midió: jerárquico cortado,
# espectral, PAM.
#
# Todo se calcula sobre `ajuste$z`, la matriz que el método realmente usó. Si
# se escaló al ajustar, la silueta se mide en esa misma escala; medirla en las
# unidades originales daría un número que no corresponde a la partición que se
# está juzgando.

#' Silueta de cada observación.
#'
#' s(i) = (b − a) / max(a, b), con `a` la distancia media a su propio grupo y
#' `b` la distancia media al grupo vecino más cercano. Cerca de 1 la
#' observación está cómoda donde está; negativa, estaría mejor en otro grupo.
#'
#' Escrita a mano y no con `cluster::silhouette()`: cero dependencias nuevas
#' (la misma decisión que MICE en el hito 2 y `factoextra` en el 3).
#'
#' Es O(n²) en memoria. Por encima de `muestra_max` se calcula sobre una
#' muestra con semilla y el atributo `muestreada` lo dice, para que el número
#' no se cite como si fuera del total (C8).
#'
#' @return data.frame(fila, grupo, vecino, s)
silueta <- function(ajuste, muestra_max = 2000L, semilla = 42L) {
  z <- ajuste$z
  grupos <- ajuste$grupos
  filas <- seq_len(nrow(z))
  muestreada <- nrow(z) > muestra_max
  if (muestreada) {
    set.seed(semilla)
    filas <- sort(sample.int(nrow(z), muestra_max))
    z <- z[filas, , drop = FALSE]
    grupos <- grupos[filas]
  }

  niveles <- sort(unique(grupos))
  distancias <- as.matrix(stats::dist(z))
  medias <- vapply(niveles, function(j) {
    columnas <- which(grupos == j)
    if (!length(columnas)) return(rep(NA_real_, nrow(z)))
    suma <- rowSums(distancias[, columnas, drop = FALSE])
    cuantos <- ifelse(grupos == j, length(columnas) - 1L, length(columnas))
    ifelse(cuantos > 0, suma / cuantos, NA_real_)
  }, numeric(nrow(z)))
  medias <- matrix(medias, nrow = nrow(z), ncol = length(niveles))

  propio <- match(grupos, niveles)
  a <- medias[cbind(seq_len(nrow(z)), propio)]
  ajenas <- medias
  ajenas[cbind(seq_len(nrow(z)), propio)] <- Inf
  vecino <- max.col(-ajenas, ties.method = "first")
  b <- ajenas[cbind(seq_len(nrow(z)), vecino)]

  s <- ifelse(is.na(a) | !is.finite(b), 0, (b - a) / pmax(a, b))
  tabla <- data.frame(fila = filas, grupo = factor(grupos, levels = niveles),
                      vecino = factor(niveles[vecino], levels = niveles),
                      s = as.numeric(s))
  attr(tabla, "muestreada") <- muestreada
  tabla
}

#' Inercia intra-grupo para cada k: la curva del codo.
#'
#' Reajusta k-medias sobre la MISMA matriz ya preparada, con la misma semilla y
#' el mismo optimizador. Es caro a propósito: el codo es un resultado del
#' método, no una extrapolación de un solo ajuste.
#'
#' @return data.frame(k, inercia, proporcion)
inercia_por_k <- function(ajuste, k_max = 10L) {
  k_max <- max(2L, min(as.integer(k_max), ajuste$n - 1L))
  marco <- as.data.frame(ajuste$z)
  filas <- lapply(2:k_max, function(k) {
    parcial <- ajustar_kmeans(marco, k = k, escalar = FALSE,
                              optimizador = ajuste$optimizador,
                              inicializacion = ajuste$inicializacion,
                              reinicios = ajuste$reinicios,
                              tol = ajuste$tol, maxit = ajuste$maxit,
                              semilla = ajuste$semilla,
                              registrar_traza = FALSE)
    data.frame(k = k, inercia = parcial$inercia,
               proporcion = 1 - parcial$inercia / ajuste$inercia_total)
  })
  do.call(rbind, filas)
}

#' Un grupo por fila: cuántos, qué tan apretados, qué tan lejos del centro.
#' @return data.frame(grupo, n, inercia, radio_medio, proporcion)
resumen_grupos <- function(ajuste) {
  tamanos <- ajuste$tamanos
  data.frame(grupo = factor(seq_len(ajuste$k)),
             n = tamanos,
             inercia = ajuste$inercia_por_grupo,
             radio_medio = ifelse(tamanos > 0,
                                  sqrt(ajuste$inercia_por_grupo / pmax(tamanos, 1)),
                                  0),
             proporcion = tamanos / sum(tamanos))
}

#' Los centroides en formato largo: el perfil de cada grupo variable a variable.
#' @return data.frame(grupo, variable, valor)
centroides_tabla <- function(ajuste) {
  matriz <- ajuste$centroides
  partes <- lapply(seq_len(nrow(matriz)), function(j)
    data.frame(grupo = factor(j, levels = seq_len(nrow(matriz))),
               variable = colnames(matriz),
               valor = as.numeric(matriz[j, ])))
  do.call(rbind, partes)
}

# ---------------------------------------------------------------------------
# La cara de la familia hacia la UI (genéricas de metricas.R)
# ---------------------------------------------------------------------------

metricas_de_corrida.ajuste_kmeans <- function(ajuste) {
  siluetas <- silueta(ajuste)
  list(n = ajuste$n, p = ajuste$p, k = ajuste$k,
       inercia = ajuste$inercia,
       proporcion_explicada = ajuste$proporcion_explicada,
       silueta_media = mean(siluetas$s),
       silueta_muestreada = isTRUE(attr(siluetas, "muestreada")),
       grupo_menor = min(ajuste$tamanos),
       grupo_mayor = max(ajuste$tamanos),
       iteraciones = ajuste$iteraciones,
       convergio = isTRUE(ajuste$convergio))
}

#' El mapa 2D de una partición no tiene ejes propios: se proyecta sobre las dos
#' primeras direcciones principales de la misma matriz que se agrupó. Es un
#' dibujo, no un resultado — la partición vive en las p dimensiones.
#'
#' @param grupo asignaciones a pintar; NULL = las del ajuste. El paso a paso de
#'   la fase 3 pasa acá la columna de `asignaciones_por_iter`.
coordenadas_2d.ajuste_kmeans <- function(ajuste, ejes = c(1L, 2L), grupo = NULL,
                                         ...) {
  descomposicion <- svd(scale(ajuste$z, center = TRUE, scale = FALSE),
                        nu = 2L, nv = 2L)
  proyeccion <- descomposicion$u %*% diag(descomposicion$d[1:2], 2L, 2L)
  etiquetas <- grupo %||% ajuste$grupos
  data.frame(fila = seq_len(nrow(proyeccion)),
             x = proyeccion[, 1], y = proyeccion[, 2],
             grupo = factor(etiquetas, levels = seq_len(ajuste$k)))
}

tabla_resultado.ajuste_kmeans <- function(ajuste) resumen_grupos(ajuste)

grafico_resultado.ajuste_kmeans <- function(ajuste, ...) {
  graficar_codo(inercia_por_k(ajuste), k = ajuste$k, ...)
}

resumen_ajuste.ajuste_kmeans <- function(ajuste) {
  list("grupos" = ajuste$k,
       "inercia" = sprintf("%.3f", ajuste$inercia),
       "explicado" = sprintf("%.1f %%", 100 * ajuste$proporcion_explicada),
       "grupo menor" = min(ajuste$tamanos))
}

lectura_resultado.ajuste_kmeans <- function(ajuste, ...) {
  tamanos <- ajuste$tamanos
  sprintf(paste("Los %d grupos van de %d a %d observaciones y dejan explicada",
                "el %.1f %% de la inercia. Un grupo diminuto no es un hallazgo:",
                "mira si sobrevive a otra semilla."),
          ajuste$k, min(tamanos), max(tamanos),
          100 * ajuste$proporcion_explicada)
}

# Dos y solo dos: el plano de la proyección. Pedir un tercer eje sobre una
# partición sería ofrecer una opción que no significa nada.
etiquetas_ejes.ajuste_kmeans <- function(ajuste) c("eje 1", "eje 2")
