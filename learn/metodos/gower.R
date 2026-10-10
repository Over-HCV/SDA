# learn/metodos/gower.R
#
# Responsabilidad: agrupar observaciones con variables cualitativas (o mezcladas
# con numéricas) midiendo la disimilitud de Gower, y partirlas con PAM o con
# un árbol jerárquico, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3): corre igual desde la app, desde
# run_headless.R y desde una consola de R.
#
# Lo que este método añade a k-medias y al jerárquico numérico:
#
#   · Una distancia que no exige números. Gower (1971) compara variable a
#     variable con la regla que le corresponde a su tipo —coincidir o no para
#     una categoría, diferencia relativa al rango para un número— y promedia.
#     Con solo categorías es la proporción de variables en que dos filas
#     difieren: la distancia de Hamming dividida por p.
#   · Un centro que existe. k-medias necesita promediar filas y "el promedio de
#     un pez y un ave" no es un animal. PAM elige como centro una observación
#     real, el medoide, y para eso solo hace falta poder medir disimilitudes:
#     sirve con Gower y con cualquier otra.
#
# Se delega en cluster::daisy() y cluster::pam(), como el jerárquico delega en
# hclust(). Lo que se escribe acá es lo que esas funciones no devuelven: la
# traza de PAM reconstruida y los modos de cada grupo.
#
# La teoría está en fichas/gower.md.

#' Ajusta un agrupamiento sobre la disimilitud de Gower.
#'
#' Sin `...` por la misma razón que el jerárquico: `argumentos_ajuste()` filtra
#' por la firma, y un hiperparámetro mal escrito tiene que fallar, no pasar.
#'
#' Faltantes: daisy() los resuelve par a par —cada par se compara en las
#' variables que ambos tienen y se divide por cuántas fueron—, así que una fila
#' con algún NA se queda. Solo se descarta la fila sin ningún dato. Si dos filas
#' no comparten ninguna variable observada su disimilitud no existe, y el
#' ajuste falla diciéndolo en vez de inventarla.
#'
#' @param datos                data.frame
#' @param columnas             columnas a usar; NULL = todas las cualitativas y
#'                             numéricas, salvo identificadores y constantes
#' @param k                    número de grupos
#' @param estrategia           "pam" (medoides) o "jerarquico" (árbol cortado)
#' @param enlace               enlace del árbol; solo cuenta con "jerarquico"
#' @param binarias_asimetricas TRUE no cuenta como parecido compartir la
#'                             ausencia en las variables de dos niveles
#' @param semilla              no gobierna nada (PAM y hclust son
#'                             deterministas); viaja al JSON igual que en el ACM
#' @param registrar_traza      FALSE no reconstruye la traza
#' @return list con el contrato de `ajuste_cualitativo` (ver el final)
ajustar_gower <- function(datos, columnas = NULL, k = 3L, estrategia = "pam",
                          enlace = "average", binarias_asimetricas = FALSE,
                          semilla = 42L, registrar_traza = TRUE) {
  estrategia <- .opcion_exacta(estrategia, c("pam", "jerarquico"), "estrategia")
  enlace <- .opcion_exacta(enlace, c("average", "complete", "single",
                                     "ward.D2"), "enlace")
  preparado <- .preparar_gower(datos, columnas)
  x <- preparado$x
  n <- nrow(x)
  k <- as.integer(k)
  if (k < 2L) stop("partir en menos de dos grupos no es agrupar")
  if (k >= n) stop("hacen falta mas filas que grupos: n = ", n, ", k = ", k)
  # La matriz de disimilitudes es n x n, igual que en el jerárquico.
  if (n > 5000L)
    stop("Gower guarda todas las disimilitudes entre pares: con n = ", n,
         " no entra en memoria. Muestrea antes o agrupa con k-modos")

  asimetricas <- if (isTRUE(binarias_asimetricas)) preparado$binarias else
    character(0)
  d <- .disimilitud_gower(x, asimetricas)

  ajuste <- if (estrategia == "pam") .ajustar_pam(d, k, registrar_traza) else
    .ajustar_arbol_gower(d, k, enlace, rownames(x), registrar_traza)
  orden <- .orden_por_tamano(ajuste$grupos, k)
  grupos <- match(ajuste$grupos, orden)
  medoides <- if (is.null(ajuste$medoides)) NULL else ajuste$medoides[orden]
  modos <- if (is.null(medoides)) .modos_por_grupo(x, grupos, k) else
    x[medoides, , drop = FALSE]
  rownames(modos) <- paste0("g", seq_len(k))

  structure(list(
    grupos = grupos, k = k, n = n, p = ncol(x),
    tamanos = tabulate(grupos, k),
    x = x, columnas = names(x),
    filas_descartadas = preparado$descartadas, semilla = semilla,
    disimilitud = "gower", matriz_disimilitud = d,
    estrategia = estrategia, enlace = enlace,
    binarias_asimetricas = isTRUE(binarias_asimetricas),
    medoides = medoides, modos = modos,
    arbol = ajuste$arbol,
    correlacion_cofenetica = ajuste$cofenetica %||% NA_real_,
    traza = ajuste$traza,
    # Lo que leen arbol_jerarquico() (el pie del dendrograma) y la franja de la
    # fase 3. Ninguno de los dos algoritmos tiene tolerancia ni techo: PAM
    # intercambia hasta que ningún cambio baja el costo y el árbol hace n − 1
    # fusiones, así que "convergió" es literal y tol/maxit quedan en NA.
    distancia = "gower", objetivo = ajuste$objetivo %||% NA_real_,
    asimetricas = asimetricas,
    iteraciones = ajuste$iteraciones, convergio = TRUE,
    tol = NA_real_, maxit = NA_integer_),
    class = c("ajuste_gower", "ajuste_cualitativo", "ajuste_agrupamiento",
              "ajuste_sda"))
}

# ---------------------------------------------------------------------------
# Lo que entra a la disimilitud
# ---------------------------------------------------------------------------

# Gower existe para tablas mezcladas: por defecto entran cualitativas Y
# numéricas. Lo que se deja afuera solo es lo que no es variable: una columna
# de texto con un valor distinto por fila (el nombre del animal) es la etiqueta
# de la fila, y una columna constante no separa a nadie pero sí agranda el
# denominador p, encogiendo todas las disimilitudes por igual.
.preparar_gower <- function(datos, columnas) {
  if (is.null(columnas)) {
    columnas <- Filter(function(columna) {
      v <- datos[[columna]]
      distintos <- length(unique(v[!is.na(v)]))
      identificador <- !is.numeric(v) && distintos == nrow(datos)
      (is.numeric(v) || is.factor(v) || is.character(v) || is.logical(v)) &&
        !identificador && distintos > 1L
    }, names(datos))
  }
  faltan <- setdiff(columnas, names(datos))
  if (length(faltan)) stop("no existen las columnas: ", paste(faltan, collapse = ", "))
  if (length(columnas) < 2L)
    stop("Gower necesita al menos dos columnas que comparar")

  x <- datos[, columnas, drop = FALSE]
  # Texto y lógicos pasan a factor: daisy() trata un lógico como binaria
  # asimétrica por su cuenta, y eso tiene que ser una decisión explícita
  # (`binarias_asimetricas`), no un efecto del tipo con que se leyó el CSV.
  for (columna in columnas) {
    if (is.character(x[[columna]]) || is.logical(x[[columna]]))
      x[[columna]] <- factor(x[[columna]])
  }
  con_dato <- rowSums(!is.na(x)) > 0L
  etiquetas <- .etiquetas_de_filas(datos, con_dato)
  x <- droplevels(x[con_dato, , drop = FALSE])
  rownames(x) <- make.unique(as.character(etiquetas))
  binarias <- columnas[vapply(x, function(v) is.factor(v) && nlevels(v) == 2L,
                              logical(1))]
  list(x = x, binarias = binarias, descartadas = sum(!con_dato))
}

# Binaria asimétrica: en el zoológico, que dos animales NO tengan plumas no los
# hace parecidos —la mayoría de los animales no las tiene—; que las tengan los
# dos, sí. Con la regla simétrica cada "no" compartido suma parecido, y los
# animales con muchas ausencias (gusanos, medusas) quedan cerca entre sí solo
# por lo que les falta. La regla asimétrica saca esos pares 0–0 del numerador
# Y del denominador: es el coeficiente de Jaccard sobre esas columnas.
#
# daisy() decide qué es "ausencia" por el código del valor, así que se le pasa
# 0/1 explícito. Ausencia es el nivel que se llama así (no, 0, false, ausente);
# si ninguno se llama así, el primer nivel, que es el orden alfabético salvo
# que alguien lo haya fijado.
.disimilitud_gower <- function(x, asimetricas) {
  if (!length(asimetricas)) return(.sin_huecos(cluster::daisy(x, metric = "gower")))
  codificada <- x
  for (columna in asimetricas) {
    niveles <- levels(x[[columna]])
    ausencia <- grep("^(no|0|false|ausente|n)$", niveles, ignore.case = TRUE,
                     value = TRUE)[1]
    if (is.na(ausencia)) ausencia <- niveles[1]
    codificada[[columna]] <- as.integer(x[[columna]] != ausencia)
  }
  .sin_huecos(cluster::daisy(codificada, metric = "gower",
                             type = list(asymm = asimetricas)))
}

.sin_huecos <- function(d) {
  if (anyNA(d))
    stop("hay pares de filas sin ninguna variable comparable (todo ausencias ",
         "compartidas o faltantes): su disimilitud no existe")
  d
}

# ---------------------------------------------------------------------------
# Las dos estrategias
# ---------------------------------------------------------------------------

# PAM no devuelve su recorrido, solo dos números: el costo al terminar BUILD y
# al terminar SWAP. Con `trace.lev = 2` sí lo imprime —qué fila entra en cada
# paso de BUILD, qué par se intercambia en cada SWAP—, y de ese texto se toman
# SOLO los índices; el costo de cada estado se recalcula acá con la matriz. Si
# el formato de esos mensajes cambiara con otra versión de cluster, el conjunto
# final no cuadraría con `id.med` y se cae a la traza honesta de dos puntos.
.ajustar_pam <- function(d, k, registrar_traza) {
  impreso <- utils::capture.output(
    pam <- cluster::pam(d, k = k, diss = TRUE,
                        trace.lev = if (isTRUE(registrar_traza)) 2L else 0L))
  traza <- if (isTRUE(registrar_traza))
    .traza_pam(impreso, as.matrix(d), pam) else NULL
  list(grupos = as.integer(pam$clustering), medoides = as.integer(pam$id.med),
       objetivo = unname(pam$objective["swap"]), traza = traza,
       iteraciones = if (is.null(traza)) NA_integer_ else
         nrow(traza_a_tabla(traza)))
}

# El objetivo de PAM es la disimilitud media de cada fila a su medoide más
# cercano. En BUILD los medoides entran de a uno, así que el costo baja con
# cada entrada; en SWAP cada intercambio lo baja otra vez. El parámetro que se
# sigue es el tamaño del grupo mayor: muestra si un medoide se queda con todo.
.traza_pam <- function(impreso, distancias, pam) {
  construidos <- as.integer(sub(".*new repr\\.\\s+(\\d+).*", "\\1",
                                grep("new repr\\.", impreso, value = TRUE)))
  cambios <- regmatches(impreso, regexec("swp new\\s+(\\d+)\\s+<->\\s+(\\d+)",
                                         impreso))
  cambios <- Filter(length, cambios)
  estados <- lapply(seq_along(construidos), function(j) construidos[seq_len(j)])
  actual <- construidos
  for (cambio in cambios) {
    actual[actual == as.integer(cambio[3])] <- as.integer(cambio[2])
    estados[[length(estados) + 1L]] <- actual
  }
  traza <- nueva_traza("disimilitud media al medoide", sentido = "desciende")
  costo <- function(m) mean(apply(distancias[, m, drop = FALSE], 1L, min))
  mayor <- function(m) max(tabulate(max.col(-distancias[, m, drop = FALSE],
                                            ties.method = "first"), length(m)))
  if (!length(estados) || !setequal(estados[[length(estados)]], pam$id.med)) {
    # Plan B: los dos números que pam() sí devuelve, sin inventar los de en medio.
    estados <- list(NULL, pam$id.med)
    valores <- unname(pam$objective[c("build", "swap")])
  } else {
    valores <- vapply(estados, costo, numeric(1))
  }
  # Con filas repetidas (en el zoológico hay animales idénticos en las 16
  # columnas) una fila puede quedar a la misma distancia de dos medoides; en
  # el último estado manda el reparto que pam() devolvió, no el desempate local.
  final <- max(tabulate(pam$clustering, length(pam$id.med)))
  for (i in seq_along(valores)) {
    m <- estados[[i]]
    tamano <- if (i == length(valores)) final else if (!is.null(m)) mayor(m)
    traza <- registrar_iteracion(
      traza, iter = i, objetivo = valores[i],
      delta = if (i == 1L) NA_real_ else valores[i] - valores[i - 1L],
      parametros = if (is.null(tamano)) NULL else c(tamano_mayor = tamano))
  }
  traza
}

# Ward minimiza la inercia, y la inercia es una suma de cuadrados euclídeos:
# Gower no es euclídea, así que con ward.D2 el árbol corre pero ya no minimiza
# nada con nombre. Se permite porque la comparación es instructiva y se avisa
# en la ficha (para coincidencia simple, sqrt(d) sí es euclídea —Gower y
# Legendre, 1986—, pero acá no se transforma).
.ajustar_arbol_gower <- function(d, k, enlace, etiquetas, registrar_traza) {
  distancias <- stats::as.dist(d)
  arbol <- .construir_arbol(distancias, enlace)
  arbol$labels <- etiquetas
  list(grupos = as.integer(stats::cutree(arbol, k = k)), medoides = NULL,
       arbol = arbol,
       cofenetica = stats::cor(as.numeric(distancias),
                               as.numeric(stats::cophenetic(arbol))),
       traza = if (isTRUE(registrar_traza)) .traza_arbol_gower(arbol) else NULL,
       iteraciones = length(arbol$height))
}

# Una iteración por fusión, como en el jerárquico numérico. Sin centroides no
# hay inercia que acumular; lo que se sigue es el tamaño del grupo mayor, que
# delata el encadenamiento del enlace simple (un grupo que se come a los demás
# de a uno).
.traza_arbol_gower <- function(arbol) {
  traza <- nueva_traza("altura de fusion", sentido = "asciende")
  tamanos <- integer(nrow(arbol$merge))
  tamano <- function(j) if (j < 0) 1L else tamanos[j]
  mayor <- 1L
  for (i in seq_len(nrow(arbol$merge))) {
    tamanos[i] <- tamano(arbol$merge[i, 1L]) + tamano(arbol$merge[i, 2L])
    mayor <- max(mayor, tamanos[i])
    traza <- registrar_iteracion(
      traza, iter = i, objetivo = arbol$height[i],
      delta = if (i == 1L) NA_real_ else arbol$height[i] - arbol$height[i - 1L],
      parametros = c(tamano_mayor = mayor))
  }
  traza
}

# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

# g1 es el grupo más grande. PAM y cutree numeran en el orden en que
# encuentran los grupos, que no significa nada; por tamaño, dos ajustes de la
# misma tabla se pueden leer lado a lado. Empates: queda el número original.
.orden_por_tamano <- function(grupos, k) {
  order(-tabulate(grupos, k), seq_len(k))
}

# El "centro" de un grupo cualitativo es su modo, columna a columna: la
# categoría más frecuente. En empate gana el primer nivel, que es una
# convención y no un hallazgo. Para numéricas la mediana, que es el centro que
# minimiza la suma de diferencias absolutas, la misma que suma Gower.
.modos_por_grupo <- function(x, grupos, k) {
  columnas <- lapply(x, function(v) {
    valores <- lapply(seq_len(k), function(g) {
      w <- v[grupos == g]
      if (is.numeric(w)) return(stats::median(w, na.rm = TRUE))
      conteo <- table(w)
      if (!sum(conteo)) return(NA_character_)
      names(conteo)[which.max(conteo)]
    })
    if (is.numeric(v)) return(unlist(valores))
    factor(unlist(valores), levels = levels(v), ordered = is.ordered(v))
  })
  as.data.frame(columnas, stringsAsFactors = FALSE, optional = TRUE)
}
