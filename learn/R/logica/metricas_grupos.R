# learn/R/logica/metricas_grupos.R
#
# Responsabilidad: traducir un ajuste de agrupamiento a las tablas que se
# dibujan y se exportan, y preparar la matriz que esos ajustes miden.
#
# La hermana de `metricas_reduccion.R` para la otra familia. Sirve para
# k-medias, para el jerárquico cortado y, sin cambios, para cualquier método
# que devuelva `grupos`, `centroides` y la matriz `z` sobre la que midió:
# espectral, PAM.
#
# Todo se calcula sobre `ajuste$z`, la matriz que el método realmente usó. Si
# se escaló al ajustar, la silueta se mide en esa misma escala; medirla en las
# unidades originales daría un número que no corresponde a la partición que se
# está juzgando. Por la misma razón la silueta usa `ajuste$distancia` cuando el
# método la declara: un jerárquico con Manhattan juzgado con euclídea es otro
# jerárquico.
#
# Los métodos S3 llevan el sufijo de la FAMILIA (`.ajuste_agrupamiento`), igual
# que en reducción: k-medias y jerárquico contestan por acá, y solo escriben lo
# suyo —el gráfico principal, la frase que interpreta— los que tienen algo
# propio que decir.

# ---------------------------------------------------------------------------
# Lo que entra a las distancias (compartido por los métodos de la familia)
# ---------------------------------------------------------------------------

#' La matriz numérica, completa y (si se pide) estandarizada que se agrupa.
#'
#' Escalar no es cosmética acá: la distancia euclidiana suma cuadrados de cosas
#' con unidades distintas, así que sin escalar manda la columna con el rango
#' más grande. Se deja elegir porque a veces las unidades ya son comparables.
#'
#' @param nombre quién la pide, para que el error diga qué método falló
#' @return list(z, columnas, centro, escala, descartadas, completas)
preparar_matriz_grupos <- function(datos, columnas, escalar,
                                   nombre = "el agrupamiento") {
  numericas <- names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- intersect(columnas %||% numericas, numericas)
  if (length(columnas) < 2L)
    stop(nombre, " necesita al menos dos columnas numericas")

  bruta <- as.matrix(datos[, columnas, drop = FALSE])
  completas <- stats::complete.cases(bruta)
  if (sum(completas) < 3L)
    stop("quedan menos de tres filas completas: imputa o quita columnas")
  bruta <- bruta[completas, , drop = FALSE]

  centro <- colMeans(bruta)
  escala <- if (isTRUE(escalar)) apply(bruta, 2L, stats::sd) else
    rep(1, length(columnas))
  if (isTRUE(escalar) && any(escala == 0))
    stop("hay columnas constantes: su varianza es cero y no se pueden escalar")

  z <- scale(bruta, center = centro, scale = escala)
  attributes(z) <- list(dim = dim(z), dimnames = list(NULL, columnas))
  list(z = z, columnas = columnas, centro = centro, escala = escala,
       descartadas = sum(!completas), completas = completas)
}

#' El promedio de cada grupo, variable a variable: k x p.
centroides_de_grupos <- function(z, grupos, k) {
  centroides <- t(vapply(seq_len(k), function(j)
    colMeans(z[grupos == j, , drop = FALSE]), numeric(ncol(z))))
  dimnames(centroides) <- list(paste0("g", seq_len(k)), colnames(z))
  centroides
}

#' La suma de cuadrados de cada grupo contra su centroide. Sumadas dan W.
inercia_de_grupos <- function(z, grupos, centroides) {
  vapply(seq_len(nrow(centroides)), function(j) {
    filas <- which(grupos == j)
    if (!length(filas)) return(0)
    sum((z[filas, , drop = FALSE] -
           rep(centroides[j, ], each = length(filas)))^2)
  }, numeric(1))
}

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
#' Las distancias las pone `distancias_de_grupos()`, que despacha por familia:
#' una partición numérica se mide sobre `z`, una cualitativa con su
#' disimilitud (metricas_cualitativo.R). La cuenta de la silueta es la misma.
#'
#' @return data.frame(fila, grupo, vecino, s)
silueta <- function(ajuste, muestra_max = 2000L, semilla = 42L) {
  n <- length(ajuste$grupos)
  filas <- seq_len(n)
  muestreada <- n > muestra_max
  if (muestreada) {
    set.seed(semilla)
    filas <- sort(sample.int(n, muestra_max))
  }
  grupos <- ajuste$grupos[filas]
  distancias <- distancias_de_grupos(ajuste, filas)
  m <- nrow(distancias)

  niveles <- sort(unique(grupos))
  medias <- vapply(niveles, function(j) {
    columnas <- which(grupos == j)
    if (!length(columnas)) return(rep(NA_real_, m))
    suma <- rowSums(distancias[, columnas, drop = FALSE])
    cuantos <- ifelse(grupos == j, length(columnas) - 1L, length(columnas))
    ifelse(cuantos > 0, suma / cuantos, NA_real_)
  }, numeric(m))
  medias <- matrix(medias, nrow = m, ncol = length(niveles))

  propio <- match(grupos, niveles)
  a <- medias[cbind(seq_len(m), propio)]
  ajenas <- medias
  ajenas[cbind(seq_len(m), propio)] <- Inf
  vecino <- max.col(-ajenas, ties.method = "first")
  b <- ajenas[cbind(seq_len(m), vecino)]

  # Con a = b = 0 (dos filas idénticas en grupos distintos) el cociente es 0/0:
  # la observación está exactamente en la frontera, y eso vale 0.
  s <- ifelse(is.na(a) | !is.finite(b) | pmax(a, b) == 0, 0,
              (b - a) / pmax(a, b))
  tabla <- data.frame(fila = filas, grupo = factor(grupos, levels = niveles),
                      vecino = factor(niveles[vecino], levels = niveles),
                      s = as.numeric(s))
  attr(tabla, "muestreada") <- muestreada
  tabla
}

#' Las distancias entre las filas pedidas, en la métrica con que se agrupó.
#' @return matriz cuadrada length(filas) x length(filas)
distancias_de_grupos <- function(ajuste, filas) UseMethod("distancias_de_grupos")

distancias_de_grupos.default <- function(ajuste, filas) {
  as.matrix(stats::dist(ajuste$z[filas, , drop = FALSE],
                        method = ajuste$distancia %||% "euclidean"))
}

#' Inercia intra-grupo para cada k: la curva del codo.
#'
#' Reajusta k-medias sobre la MISMA matriz ya preparada, con la misma semilla y
#' el mismo optimizador. Es caro a propósito: el codo es un resultado del
#' método, no una extrapolación de un solo ajuste.
#'
#' Es genérica porque "inercia" solo existe sobre números: una partición de
#' factores mide su codo con su propio costo (metricas_cualitativo.R), y la
#' card del codo no tiene que saber cuál de los dos le tocó.
#'
#' @return data.frame(k, inercia, proporcion)
inercia_por_k <- function(ajuste, k_max = 10L) UseMethod("inercia_por_k")

inercia_por_k.default <- function(ajuste, k_max = 10L) {
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
  # Un ajuste cualitativo no tiene inercia (no hay centroide que promediar):
  # el reparto se dibuja igual y esas dos columnas quedan en NA.
  inercia <- ajuste$inercia_por_grupo %||% rep(NA_real_, ajuste$k)
  data.frame(grupo = factor(seq_len(ajuste$k)),
             n = tamanos,
             inercia = inercia,
             radio_medio = ifelse(tamanos > 0,
                                  sqrt(inercia / pmax(tamanos, 1)), 0),
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
# El árbol de un jerárquico
# ---------------------------------------------------------------------------

#' El mismo ajuste con otros enlaces, un árbol por enlace.
#'
#' No se reajusta nada: las distancias son las mismas (la de Gower guardada, o
#' la de `z` con la métrica del ajuste) y solo cambia cómo se mide la
#' distancia entre grupos. Por eso los árboles se pueden comparar de a uno: la
#' diferencia es el enlace y nada más.
#'
#' @param enlaces p. ej. c("complete", "average", "single")
#' @return lista con nombre (el enlace) de salidas de arbol_jerarquico()
arboles_por_enlace <- function(ajuste, enlaces, k = ajuste$k) {
  if (is.null(ajuste$arbol)) return(NULL)
  distancias <- ajuste$matriz_disimilitud %||%
    stats::dist(ajuste$z, method = ajuste$distancia %||% "euclidean")
  etiquetas <- ajuste$arbol$labels
  stats::setNames(lapply(enlaces, function(enlace) {
    otro <- ajuste
    otro$arbol <- .construir_arbol(distancias, enlace)
    otro$arbol$labels <- etiquetas
    otro$enlace <- enlace
    otro$correlacion_cofenetica <- stats::cor(
      as.numeric(distancias), as.numeric(stats::cophenetic(otro$arbol)))
    arbol_jerarquico(otro, k)
  }), enlaces)
}

#' El dendrograma como tablas: segmentos, hojas, rectángulos del corte.
#'
#' Se calcula a mano desde `$merge`, `$height` y `$order` en vez de pasar por
#' `as.dendrogram()`: así cada segmento sabe a qué grupo del corte pertenece, y
#' el gráfico solo tiene que pintar. Una fusión entre dos ramas del mismo grupo
#' lleva su color; una por encima del corte junta grupos distintos y va en gris.
#'
#' La hoja i está en la posición que le da `$order`, que es la que garantiza
#' que ninguna rama se cruce con otra. Cada nodo se dibuja en el punto medio de
#' sus dos hijos.
#'
#' @param k grupos del corte; por defecto, los del ajuste
#' @return list(segmentos, hojas, rectangulos, corte, k, n, enlace, distancia)
arbol_jerarquico <- function(ajuste, k = ajuste$k) {
  # Gower con PAM no construye árbol: NULL y el gráfico lo dice, en vez de un
  # error de cutree() sobre algo que no es un hclust.
  if (is.null(ajuste$arbol)) return(NULL)
  arbol <- ajuste$arbol
  n <- length(arbol$order)
  altura <- arbol$height
  fusiones <- arbol$merge
  posicion <- integer(n)
  posicion[arbol$order] <- seq_len(n)
  grupos <- as.integer(stats::cutree(arbol, k = k))

  x_nodo <- numeric(n - 1L)
  grupo_nodo <- rep(NA_integer_, n - 1L)
  hijo <- function(j) if (j < 0) c(posicion[-j], 0, grupos[-j]) else
    c(x_nodo[j], altura[j], grupo_nodo[j])
  partes <- vector("list", n - 1L)
  for (i in seq_len(n - 1L)) {
    a <- hijo(fusiones[i, 1L]); b <- hijo(fusiones[i, 2L])
    x_nodo[i] <- (a[1] + b[1]) / 2
    if (!is.na(a[3]) && !is.na(b[3]) && a[3] == b[3]) grupo_nodo[i] <- a[3]
    partes[[i]] <- c(a[1], a[2], a[1], altura[i], a[3],
                     b[1], b[2], b[1], altura[i], b[3],
                     a[1], altura[i], b[1], altura[i], grupo_nodo[i])
  }
  plano <- matrix(unlist(partes), ncol = 5L, byrow = TRUE)
  segmentos <- data.frame(x = plano[, 1], y = plano[, 2], xend = plano[, 3],
                          yend = plano[, 4],
                          grupo = factor(plano[, 5], levels = seq_len(k)))

  # cutree(k) corta después de la fusión n − k, así que la línea va a mitad de
  # camino entre esa fusión y la siguiente.
  corte <- mean(altura[c(n - k, n - k + 1L)])
  etiquetas <- arbol$labels %||% as.character(seq_len(n))
  hojas <- data.frame(x = seq_len(n), etiqueta = etiquetas[arbol$order],
                      grupo = factor(grupos[arbol$order], levels = seq_len(k)))
  rectangulos <- do.call(rbind, lapply(seq_len(k), function(g) {
    lugares <- posicion[grupos == g]
    data.frame(xmin = min(lugares) - 0.45, xmax = max(lugares) + 0.45,
               ymin = 0, ymax = corte, grupo = factor(g, levels = seq_len(k)))
  }))

  # Nodos y enlaces padre -> hijo, para la forma radial (curvas en vez de
  # escalones). Un nodo es «raíz de grupo» si pertenece a un grupo y su padre
  # no: es el punto donde nace ese grupo, justo bajo el corte. Una hoja que
  # queda sola en su grupo también lo es.
  nodo_hoja <- data.frame(x = posicion, y = 0, grupo = grupos,
                          tipo = "hoja", padre_grupo = NA_integer_)
  nodo_int <- data.frame(x = x_nodo, y = altura, grupo = grupo_nodo,
                         tipo = "interno", padre_grupo = NA_integer_)
  enlaces <- vector("list", 2L * (n - 1L))
  for (i in seq_len(n - 1L)) for (lado in 1:2) {
    j <- fusiones[i, lado]
    hijo_nodo <- if (j < 0) nodo_hoja[-j, ] else nodo_int[j, ]
    enlaces[[2L * (i - 1L) + lado]] <- data.frame(
      x = x_nodo[i], y = altura[i], xend = hijo_nodo$x, yend = hijo_nodo$y,
      grupo = hijo_nodo$grupo)
    if (j < 0) nodo_hoja$padre_grupo[-j] <- grupo_nodo[i]
    else nodo_int$padre_grupo[j] <- grupo_nodo[i]
  }
  nodos <- rbind(nodo_hoja, nodo_int)
  nodos$raiz_grupo <- !is.na(nodos$grupo) & is.na(nodos$padre_grupo)
  nodos$grupo <- factor(nodos$grupo, levels = seq_len(k))
  nodos$padre_grupo <- NULL
  enlaces <- do.call(rbind, enlaces)
  enlaces$grupo <- factor(enlaces$grupo, levels = seq_len(k))

  list(segmentos = segmentos, hojas = hojas, rectangulos = rectangulos,
       nodos = nodos, enlaces = enlaces,
       corte = corte, k = as.integer(k), n = n, enlace = ajuste$enlace,
       distancia = ajuste$distancia,
       cofenetica = ajuste$correlacion_cofenetica)
}

#' Distancia original contra distancia cofenética, par por par.
#'
#' La cofenética de dos observaciones es la altura a la que el árbol las junta
#' por primera vez. Si el árbol respeta las distancias, las dos columnas se
#' mueven juntas; la correlación entre ellas mide cuánto distorsionó el enlace.
#'
#' La correlación se calcula sobre TODOS los pares (es la del ajuste); lo que
#' se muestrea por encima de `muestra_max` son los puntos a dibujar, y el
#' atributo `muestreada` lo dice (C8).
#'
#' @return data.frame(original, cofenetica) con atributos correlacion, pares
cofenetico <- function(ajuste, muestra_max = 20000L, semilla = 42L) {
  original <- as.numeric(stats::dist(ajuste$z, method = ajuste$distancia))
  cofenetica <- as.numeric(stats::cophenetic(ajuste$arbol))
  tabla <- data.frame(original = original, cofenetica = cofenetica)
  pares <- nrow(tabla)
  muestreada <- pares > muestra_max
  if (muestreada) {
    set.seed(semilla)
    tabla <- tabla[sort(sample.int(pares, muestra_max)), , drop = FALSE]
  }
  attr(tabla, "correlacion") <- stats::cor(original, cofenetica)
  attr(tabla, "pares") <- pares
  attr(tabla, "muestreada") <- muestreada
  tabla
}

# ---------------------------------------------------------------------------
# La cara de la familia hacia la UI (genéricas de metricas.R)
# ---------------------------------------------------------------------------

metricas_de_corrida.ajuste_agrupamiento <- function(ajuste) {
  siluetas <- silueta(ajuste)
  c(list(n = ajuste$n, p = ajuste$p, k = ajuste$k,
         inercia = ajuste$inercia,
         proporcion_explicada = ajuste$proporcion_explicada,
         silueta_media = mean(siluetas$s),
         silueta_muestreada = isTRUE(attr(siluetas, "muestreada")),
         grupo_menor = min(ajuste$tamanos),
         grupo_mayor = max(ajuste$tamanos),
         iteraciones = ajuste$iteraciones,
         convergio = isTRUE(ajuste$convergio)),
    metricas_de_referencia(ajuste))
}

metricas_de_corrida.ajuste_jerarquico <- function(ajuste) {
  c(NextMethod(), list(correlacion_cofenetica = ajuste$correlacion_cofenetica))
}

#' El mapa 2D de una partición no tiene ejes propios: se proyecta sobre las dos
#' primeras direcciones principales de la misma matriz que se agrupó. Es un
#' dibujo, no un resultado — la partición vive en las p dimensiones.
#'
#' @param grupo asignaciones a pintar; NULL = las del ajuste. El paso a paso de
#'   la fase 3 pasa acá la columna de `asignaciones_por_iter`.
coordenadas_2d.ajuste_agrupamiento <- function(ajuste, ejes = c(1L, 2L),
                                               grupo = NULL, ...) {
  descomposicion <- svd(scale(ajuste$z, center = TRUE, scale = FALSE),
                        nu = 2L, nv = 2L)
  proyeccion <- descomposicion$u %*% diag(descomposicion$d[1:2], 2L, 2L)
  etiquetas <- grupo %||% ajuste$grupos
  data.frame(fila = seq_len(nrow(proyeccion)),
             x = proyeccion[, 1], y = proyeccion[, 2],
             grupo = factor(etiquetas, levels = seq_len(ajuste$k)))
}

tabla_resultado.ajuste_agrupamiento <- function(ajuste) resumen_grupos(ajuste)

grafico_resultado.ajuste_kmeans <- function(ajuste, ...) {
  graficar_codo(inercia_por_k(ajuste), k = ajuste$k, ...)
}

grafico_resultado.ajuste_jerarquico <- function(ajuste, ...) {
  graficar_dendrograma(arbol_jerarquico(ajuste), ...)
}

resumen_ajuste.ajuste_agrupamiento <- function(ajuste) {
  list("grupos" = ajuste$k,
       "inercia" = sprintf("%.3f", ajuste$inercia),
       "explicado" = sprintf("%.1f %%", 100 * ajuste$proporcion_explicada),
       "grupo menor" = min(ajuste$tamanos))
}

resumen_ajuste.ajuste_jerarquico <- function(ajuste) {
  c(list("enlace" = ajuste$enlace,
         "cofenética" = sprintf("%.3f", ajuste$correlacion_cofenetica)),
    NextMethod())
}

lectura_resultado.ajuste_kmeans <- function(ajuste, ...) {
  tamanos <- ajuste$tamanos
  sprintf(paste("Los %d grupos van de %d a %d observaciones y dejan explicada",
                "el %.1f %% de la inercia. Un grupo diminuto no es un hallazgo:",
                "mira si sobrevive a otra semilla."),
          ajuste$k, min(tamanos), max(tamanos),
          100 * ajuste$proporcion_explicada)
}

# El jerárquico no tiene semilla que cambiar: lo que se pone a prueba es el
# enlace. Un grupo de una sola observación suele ser un atípico que el árbol
# dejó para el final, y con enlace promedio o simple pasa seguido.
lectura_resultado.ajuste_jerarquico <- function(ajuste, ...) {
  tamanos <- ajuste$tamanos
  sprintf(paste("Cortado en %d grupos con enlace %s, van de %d a %d",
                "observaciones y dejan explicada el %.1f %% de la inercia. La",
                "correlación cofenética es %.2f. Un grupo de una sola",
                "observación suele ser un atípico: mira si sobrevive a otro",
                "enlace."),
          ajuste$k, ajuste$enlace, min(tamanos), max(tamanos),
          100 * ajuste$proporcion_explicada, ajuste$correlacion_cofenetica)
}

# Dos y solo dos: el plano de la proyección. Pedir un tercer eje sobre una
# partición sería ofrecer una opción que no significa nada.
etiquetas_ejes.ajuste_agrupamiento <- function(ajuste) c("eje 1", "eje 2")
