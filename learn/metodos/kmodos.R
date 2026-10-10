# learn/metodos/kmodos.R
#
# Responsabilidad: partir n observaciones CUALITATIVAS en k grupos minimizando
# los desacuerdos con la moda de su grupo, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3): corre igual desde la app, desde
# run_headless.R y desde una consola de R.
#
# Es k-medias con dos piezas cambiadas, y nada más (Huang, 1998):
#
#   · la distancia euclidiana pasa a ser el emparejamiento simple: cuántas
#     variables tienen categorías distintas. Restar "ave" de "pez" no tiene
#     sentido, contar si son iguales sí;
#   · la media pasa a ser la moda, variable por variable: la categoría más
#     frecuente del grupo es la que minimiza los desacuerdos, igual que la media
#     minimiza los cuadrados.
#
# Todo lo demás —asignar, actualizar, repetir, reiniciar desde otro arranque—
# es lo mismo, y por eso la fase 3 lo muestra con las mismas vistas.
#
# Escrito a mano y sin klaR::kmodes(): klaR devuelve el resultado y se traga
# las iteraciones, que es justamente lo que la fase 3 quiere mostrar (la misma
# decisión que con stats::kmeans()).
#
# La teoría está en fichas/kmodos.md.

#' Ajusta k-modas.
#'
#' @param datos          data.frame
#' @param columnas       columnas a usar; NULL = todas las no numéricas. Una
#'   numérica pasada a propósito (`patas`) se trata como factor: si se la nombra
#'   acá es porque sus números son códigos.
#' @param k              número de grupos
#' @param inicializacion "Huang", "Cao" o "aleatoria"
#' @param reinicios      cuántas veces se reintenta desde otro arranque
#' @param maxit          techo de barridos por reinicio
#' @param semilla        gobierna el arranque (C13); el reinicio i usa semilla+i-1
#' @param registrar_traza FALSE ahorra memoria en barridos grandes
#' @return list con grupos, modos, costo, traza y los parámetros usados
ajustar_kmodos <- function(datos, columnas = NULL, k = 3L,
                           inicializacion = "Huang", reinicios = 10L,
                           maxit = 100L, semilla = 42L,
                           registrar_traza = TRUE) {
  inicializacion <- match.arg(inicializacion, c("Huang", "Cao", "aleatoria"))
  preparado <- preparar_factores_grupos(datos, columnas, "k-modas")
  x <- preparado$x
  codigos <- vapply(x, as.integer, integer(nrow(x)))
  codigos <- matrix(codigos, nrow = nrow(x), dimnames = list(NULL, names(x)))
  n <- nrow(x)
  k <- as.integer(k)
  if (k < 2L) stop("k-modas necesita al menos dos grupos")
  distintas <- sum(!duplicated(codigos))
  if (k > distintas)
    stop("hay ", distintas, " filas distintas y se pidieron ", k, " grupos: ",
         "dos modas iguales no se pueden separar")
  reinicios <- max(1L, as.integer(reinicios))
  niveles <- vapply(x, nlevels, integer(1))

  semillas <- semilla + seq_len(reinicios) - 1L
  intentos <- lapply(semillas, function(s)
    .correr_kmodos(codigos, niveles, k, inicializacion, maxit, s,
                   registrar_traza))
  mejor <- which.min(vapply(intentos, `[[`, numeric(1), "costo"))
  ganador <- .kmodos_ordenar(intentos[[mejor]], k)

  modos <- as.data.frame(lapply(seq_along(x), function(v)
    factor(levels(x[[v]])[ganador$modos[, v]], levels = levels(x[[v]]))),
    col.names = names(x))
  rownames(modos) <- paste0("g", seq_len(k))

  structure(list(
    grupos = ganador$grupos,
    k = k, n = n, p = ncol(x),
    tamanos = tabulate(ganador$grupos, nbins = k),
    x = x,
    columnas = names(x),
    filas_descartadas = preparado$descartadas,
    semilla = semilla,
    modos = modos,
    costo = ganador$costo,
    costo_por_grupo = .kmodos_costo_por_grupo(codigos, ganador$grupos,
                                              ganador$modos),
    disimilitud = "emparejamiento_simple",
    inicializacion = inicializacion, reinicios = reinicios, maxit = maxit,
    semilla_ganadora = semillas[mejor],
    iteraciones = ganador$iteraciones,
    convergio = ganador$convergio,
    traza = ganador$traza,
    trazas_reinicios = stats::setNames(lapply(intentos, `[[`, "traza"),
                                       as.character(semillas)),
    asignaciones_por_iter = ganador$asignaciones),
    class = c("ajuste_kmodos", "ajuste_cualitativo", "ajuste_agrupamiento",
              "ajuste_sda"))
}

#' Disimilitud de emparejamiento simple: en cuántas variables difieren dos filas.
#'
#' d(a, b) = #{v : a_v != b_v}. Va de 0 (idénticas) a p (no comparten nada). Es
#' la distancia de Hamming sobre categorías, y la que k-modas minimiza.
#'
#' Compara por la etiqueta de la categoría y no por el código interno del
#' factor: dos factores con los niveles en otro orden siguen siendo los mismos
#' datos. Un faltante cuenta como desacuerdo (no se puede afirmar que coincide).
#'
#' @param x data.frame o matriz de categorías (filas = observaciones)
#' @param y NULL, o las filas contra las que medir (los modos de un ajuste)
#' @return con `y = NULL`, un objeto `dist` entre las filas de `x`; si no, una
#'   matriz nrow(x) x nrow(y)
disimilitud_emparejamiento <- function(x, y = NULL) {
  como_texto <- function(m) {
    m <- as.data.frame(m, stringsAsFactors = FALSE)
    matrix(vapply(m, as.character, character(nrow(m))), nrow = nrow(m),
           dimnames = list(rownames(m), names(m)))
  }
  a <- como_texto(x)
  b <- if (is.null(y)) a else como_texto(y)
  if (ncol(a) != ncol(b)) stop("x e y tienen distinto numero de variables")
  total <- matrix(0, nrow(a), nrow(b), dimnames = list(rownames(a), rownames(b)))
  for (v in seq_len(ncol(a))) {
    distinto <- outer(a[, v], b[, v], "!=")
    distinto[is.na(distinto)] <- TRUE
    total <- total + distinto
  }
  if (is.null(y)) stats::as.dist(total) else total
}

#' Las columnas cualitativas, completas y como factor, que se agrupan.
#'
#' Una columna de texto sin un solo valor repetido (`animal`, un código de país)
#' no es una variable, es un nombre: con ella cada fila sería su propia moda. Se
#' saca de las variables y pasa a ser la etiqueta de las filas. Se mira acá y no
#' en la UI porque la fase 2 ofrece todas las cualitativas del diccionario.
#'
#' Ojo con lo que NO se saca: la clase real. Si los datos traen la respuesta
#' (`tipo` en Zoo), quien llama la deja fuera de `columnas`; con `NULL` entra.
#'
#' @return list(x, descartadas, etiqueta)
preparar_factores_grupos <- function(datos, columnas,
                                     nombre = "el agrupamiento") {
  columnas <- intersect(columnas %||%
    names(datos)[!vapply(datos, is.numeric, logical(1))], names(datos))
  # La regla de lab/paneles.R para nombrar filas, aplicada a todo `datos`: la
  # primera columna de texto sin repetidos es la etiqueta.
  nombres <- names(datos)[vapply(datos, function(v)
    (is.character(v) || is.factor(v)) && nrow(datos) > 3L &&
      !anyDuplicated(stats::na.omit(as.character(v))), logical(1))]
  columnas <- setdiff(columnas, nombres)
  etiqueta <- nombres[1]
  if (!length(columnas))
    stop(nombre, " necesita al menos una columna cualitativa")

  completas <- stats::complete.cases(datos[, columnas, drop = FALSE])
  if (sum(completas) < 3L)
    stop("quedan menos de tres filas completas: imputa o quita columnas")
  x <- as.data.frame(lapply(datos[completas, columnas, drop = FALSE],
                            function(v) droplevels(factor(v))),
                     check.names = FALSE)
  filas <- if (!is.na(etiqueta)) as.character(datos[[etiqueta]][completas])
    else rownames(datos)[completas]
  rownames(x) <- make.unique(filas)
  list(x = x, descartadas = sum(!completas), etiqueta = etiqueta)
}

# ---------------------------------------------------------------------------
# El optimizador de Huang
# ---------------------------------------------------------------------------

# Huang (1998), tal como lo escribe el artículo: un barrido recorre las filas
# en orden y, cada vez que una cambia de grupo, actualiza en el acto las modas
# de los dos grupos tocados (el MacQueen de las categorías). Para que eso no sea
# O(n²) se llevan las frecuencias de cada categoría por grupo: mover una fila es
# restar uno en una tabla y sumar uno en otra.
#
# El costo no puede subir: una fila se mueve solo si queda estrictamente más
# cerca de otra moda (con las modas fijas, baja), y recalcular una moda con las
# frecuencias nunca empeora (la moda es el óptimo de cada variable). Como cada
# movimiento baja el costo y las particiones son finitas, termina.
.correr_kmodos <- function(codigos, niveles, k, inicializacion, maxit,
                           semilla, registrar_traza) {
  set.seed(semilla)
  modos <- .kmodos_inicializar(codigos, niveles, k, inicializacion)
  traza <- if (registrar_traza)
    nueva_traza("disimilitud intra-grupo", sentido = "desciende") else NULL

  # El arranque es asignar y actualizar UNA vez, igual que en k-medias: sin
  # actualizar, el costo inicial se mediría contra modas que son filas sueltas.
  grupos <- .kmodos_asignar(codigos, modos)
  arreglo <- .kmodos_sin_vacios(codigos, grupos, modos, k)
  grupos <- arreglo$grupos
  frecuencias <- .kmodos_frecuencias(codigos, grupos, niveles, k)
  modos <- .kmodos_modas(frecuencias, k)
  costo <- .kmodos_costo(codigos, grupos, modos)
  asignaciones <- if (registrar_traza) matrix(grupos, ncol = 1L) else NULL
  if (!is.null(traza))
    traza <- registrar_iteracion(traza, iter = 0L, objetivo = costo,
                                 parametros = .kmodos_planos(modos))
  convergio <- FALSE
  iteraciones <- 0L

  for (iteracion in seq_len(maxit)) {
    movidas <- 0L
    tamanos <- tabulate(grupos, nbins = k)
    for (i in seq_len(nrow(codigos))) {
      fila <- codigos[i, ]
      distancias <- colSums(t(modos) != fila)
      origen <- grupos[i]
      destino <- which.min(distancias)
      # Solo se mueve si mejora ESTRICTAMENTE: con un empate se queda donde
      # está, y así dos modas equidistantes no se pasan la fila para siempre.
      # El último miembro de un grupo tampoco se va: vaciarlo dejaría una moda
      # sin nadie que la defina, a mitad del barrido.
      if (distancias[destino] >= distancias[origen] || tamanos[origen] <= 1L)
        next
      for (v in seq_along(fila)) {
        frecuencias[[v]][origen, fila[v]] <- frecuencias[[v]][origen, fila[v]] - 1L
        frecuencias[[v]][destino, fila[v]] <- frecuencias[[v]][destino, fila[v]] + 1L
      }
      tamanos[origen] <- tamanos[origen] - 1L
      tamanos[destino] <- tamanos[destino] + 1L
      grupos[i] <- destino
      modos[c(origen, destino), ] <-
        .kmodos_modas(frecuencias, k)[c(origen, destino), ]
      movidas <- movidas + 1L
    }
    nuevo <- .kmodos_costo(codigos, grupos, modos)
    delta <- costo - nuevo
    costo <- nuevo
    iteraciones <- iteracion

    if (!is.null(traza)) {
      traza <- registrar_iteracion(traza, iter = iteracion, objetivo = costo,
                                   delta = delta,
                                   parametros = .kmodos_planos(modos))
      asignaciones <- cbind(asignaciones, grupos)
    }
    if (movidas == 0L) { convergio <- TRUE; break }
  }

  list(grupos = grupos, modos = modos, costo = costo,
       iteraciones = iteraciones, convergio = convergio, traza = traza,
       asignaciones = unname(asignaciones))
}

# n x k de desacuerdos, con un bucle sobre los k grupos y no sobre las filas.
.kmodos_distancias <- function(codigos, modos) {
  vapply(seq_len(nrow(modos)), function(j)
    rowSums(codigos != rep(modos[j, ], each = nrow(codigos))),
    numeric(nrow(codigos)))
}

.kmodos_asignar <- function(codigos, modos) {
  distancias <- matrix(.kmodos_distancias(codigos, modos), nrow = nrow(codigos))
  max.col(-distancias, ties.method = "first")
}

# Un grupo vacío no tiene moda. Pasa si dos modas iniciales quedan tan cerca
# que una gana todos los empates. Se le da la fila peor explicada de un grupo
# que pueda prestarla, y esa fila pasa a ser su moda: reproducible, y la misma
# regla que k-medias usa con sus centroides.
.kmodos_sin_vacios <- function(codigos, grupos, modos, k) {
  for (j in setdiff(seq_len(k), grupos)) {
    tamanos <- tabulate(grupos, nbins = k)
    lejania <- rowSums(codigos != modos[grupos, , drop = FALSE])
    lejania[tamanos[grupos] <= 1L] <- -1
    elegida <- which.max(lejania)
    grupos[elegida] <- j
    modos[j, ] <- codigos[elegida, ]
  }
  list(grupos = grupos, modos = modos)
}

# Por variable, una tabla k x categorías con cuántos miembros de cada grupo
# tienen cada categoría.
.kmodos_frecuencias <- function(codigos, grupos, niveles, k) {
  stats::setNames(lapply(seq_along(niveles), function(v)
    unclass(table(factor(grupos, levels = seq_len(k)),
                  factor(codigos[, v], levels = seq_len(niveles[v]))))),
    colnames(codigos))
}

# La moda de cada grupo en cada variable. Un empate se rompe por el PRIMER
# nivel del factor (which.max devuelve el primero): es arbitrario pero
# determinista, y el costo no depende de cuál se elija. Por eso el cargador de
# Zoo fija "no" antes que "si" en las quince binarias.
.kmodos_modas <- function(frecuencias, k) {
  matrix(vapply(frecuencias, function(tabla)
    apply(tabla, 1L, which.max), integer(k)), nrow = k,
    dimnames = list(NULL, names(frecuencias)))
}

.kmodos_costo <- function(codigos, grupos, modos) {
  sum(codigos != modos[grupos, , drop = FALSE])
}

.kmodos_costo_por_grupo <- function(codigos, grupos, modos) {
  vapply(seq_len(nrow(modos)), function(j) {
    filas <- which(grupos == j)
    if (!length(filas)) return(0)
    sum(codigos[filas, , drop = FALSE] !=
          rep(modos[j, ], each = length(filas)))
  }, numeric(1))
}

# Las modas como vector con nombre, que es lo que la traza sabe guardar:
# "g1_pelo" = 2 es "el grupo 1 tiene moda en el segundo nivel de pelo". El
# número es un código, no una cantidad; la trayectoria muestra cuándo dejó de
# cambiar, que es lo único que se puede leer de él.
.kmodos_planos <- function(modos, nombres = colnames(modos)) {
  etiquetas <- as.vector(t(outer(paste0("g", seq_len(nrow(modos))),
                                 nombres, paste, sep = "_")))
  stats::setNames(as.numeric(t(modos)), etiquetas)
}

# Las etiquetas por tamaño, de mayor a menor (el empate, por la primera fila
# que aparece). La misma partición con los números permutados es la misma
# partición, y sin fijar el orden dos corridas pintarían otros colores.
.kmodos_ordenar <- function(resultado, k) {
  tamanos <- tabulate(resultado$grupos, nbins = k)
  primera <- match(seq_len(k), resultado$grupos)
  orden <- order(-tamanos, primera)
  resultado$grupos <- match(resultado$grupos, orden)
  resultado$modos <- resultado$modos[orden, , drop = FALSE]
  if (!is.null(resultado$asignaciones))
    resultado$asignaciones[] <- match(resultado$asignaciones, orden)
  if (!is.null(resultado$traza))
    resultado$traza$filas <- lapply(resultado$traza$filas, function(f) {
      viejo <- as.integer(sub("^g([0-9]+)_.*$", "\\1", names(f$parametros)))
      names(f$parametros) <- paste0("g", match(viejo, orden),
                                    sub("^g[0-9]+", "", names(f$parametros)))
      f$parametros <- f$parametros[order(match(viejo, orden))]
      f
    })
  resultado
}

# ---------------------------------------------------------------------------
# Inicializaciones
# ---------------------------------------------------------------------------

# Las tres eligen k modas que son filas DISTINTAS de los datos: dos modas
# iguales empatarían en todo y una de las dos se quedaría vacía. Zoo tiene
# animales con los dieciséis atributos idénticos, así que no es hipotético.
.kmodos_inicializar <- function(codigos, niveles, k, inicializacion) {
  distintas <- codigos[!duplicated(codigos), , drop = FALSE]
  modos <- switch(inicializacion,
    Huang = .kmodos_iniciar_huang(distintas, k),
    Cao = .kmodos_iniciar_cao(codigos, distintas, k),
    aleatoria = distintas[sample.int(nrow(distintas), k), , drop = FALSE])
  dimnames(modos) <- list(NULL, colnames(codigos))
  modos
}

# Huang (1998), segundo método del artículo: cada moda candidata se arma
# variable por variable sorteando categorías según su frecuencia, y después se
# reemplaza por la fila real más parecida que no se haya usado. El sorteo es lo
# que hace que dos semillas arranquen distinto; el reemplazo, que la moda
# inicial no sea una combinación que nadie tiene.
.kmodos_iniciar_huang <- function(distintas, k) {
  candidatas <- vapply(seq_len(ncol(distintas)), function(v) {
    tabla <- table(distintas[, v])
    as.integer(names(tabla))[sample.int(length(tabla), k, replace = TRUE,
                                        prob = as.numeric(tabla))]
  }, integer(k))
  candidatas <- matrix(candidatas, nrow = k)
  libres <- seq_len(nrow(distintas))
  elegidas <- integer(k)
  for (j in seq_len(k)) {
    lejania <- rowSums(distintas[libres, , drop = FALSE] !=
                         rep(candidatas[j, ], each = length(libres)))
    cercanas <- libres[lejania == min(lejania)]
    elegidas[j] <- cercanas[sample.int(length(cercanas), 1L)]
    libres <- setdiff(libres, elegidas[j])
  }
  distintas[elegidas, , drop = FALSE]
}

# Cao, Liang y Bai (2009): la primera moda es la fila más "densa" —la que
# comparte más categorías con el resto—, y cada siguiente la que maximiza
# densidad x distancia a la moda ya elegida más cercana. Arranca en el centro
# de la masa y se abre hacia afuera, como k-means++ pero sin azar.
#
# Es determinista: todos los reinicios arrancan igual, y con ella pedir diez
# reinicios cuesta diez veces y no agrega nada. Se deja así a propósito: es la
# forma de ver en la fase 3 que la variación entre reinicios venía del arranque.
.kmodos_iniciar_cao <- function(codigos, distintas, k) {
  # Densidad = frecuencia relativa media de las categorías de la fila, medida
  # contra TODAS las filas (con repetidas): un perfil muy común pesa más.
  densidad <- rowMeans(vapply(seq_len(ncol(distintas)), function(v) {
    frecuencia <- tabulate(codigos[, v], nbins = max(codigos[, v]))
    frecuencia[distintas[, v]] / nrow(codigos)
  }, numeric(nrow(distintas))))
  densidad <- matrix(densidad, nrow = nrow(distintas))[, 1L]
  elegidas <- which.max(densidad)
  for (j in seq_len(k - 1L)) {
    cercania <- apply(matrix(.kmodos_distancias(
      distintas, distintas[elegidas, , drop = FALSE]),
      nrow = nrow(distintas)), 1L, min)
    puntaje <- cercania * densidad
    puntaje[elegidas] <- -Inf
    elegidas <- c(elegidas, which.max(puntaje))
  }
  distintas[elegidas, , drop = FALSE]
}
