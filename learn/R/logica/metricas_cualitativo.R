# learn/R/logica/metricas_cualitativo.R
#
# Responsabilidad: traducir un ajuste de agrupamiento CUALITATIVO (k-modos,
# Gower, clases latentes) a las tablas que se dibujan, y validar una partición
# contra una clase conocida.
#
# Es la tercera familia de `metricas.R`. Los métodos de `metricas_grupos.R`
# suponen una matriz numérica `z` —centroides, inercia, distancia euclidiana—
# y sobre factores ninguna de esas cosas existe: el "promedio" de pelo = si y
# pelo = no no es un animal. Lo que sí existe es la proporción de cada
# categoría dentro de cada grupo, y la categoría más frecuente (el modo), que
# es el representante natural del grupo. Todo lo de acá sale de eso.
#
# Contrato del ajuste (lo cumplen los tres métodos):
#   clase  c("ajuste_<clave>", "ajuste_cualitativo", "ajuste_agrupamiento",
#            "ajuste_sda")
#   campos grupos, k, n, p, tamanos, columnas, x (los factores usados, filas
#          completas), modos (k x p) y, según el método, `matriz_disimilitud`
#          (Gower), `probabilidades` y `seleccion` (clases latentes),
#          `costo` (k-modos)
#
# Hereda de `ajuste_agrupamiento` a propósito: el reparto de tamaños y la
# silueta siguen sirviendo, y solo se pisa lo que suponía números.
#
# La clase de referencia (`tipo` en Zoo) NO entra al ajuste. Se declara en el
# diccionario con rol "respuesta" (o `--clase` en la consola) y se adjunta a la
# corrida DESPUÉS de ajustar, con adjuntar_referencia(): así el algoritmo no la
# ve y la fase 4 sí la puede usar para medir.

# ---------------------------------------------------------------------------
# Disimilitud y perfiles
# ---------------------------------------------------------------------------

#' Emparejamiento simple: la fracción de variables en que dos filas difieren.
#'
#' Es la disimilitud de k-modos. Escrita acá y no tomada de `metodos/kmodos.R`
#' porque la silueta tiene que funcionar para cualquier ajuste cualitativo,
#' también para uno que no la exporte.
#'
#' @param x data.frame de factores (o texto), sin faltantes
#' @return matriz n x n con valores en [0, 1]
disimilitud_simple <- function(x) {
  n <- nrow(x)
  total <- matrix(0, n, n)
  for (columna in names(x)) {
    codigos <- as.integer(factor(as.character(x[[columna]])))
    total <- total + outer(codigos, codigos, "!=")
  }
  dimnames(total) <- list(rownames(x), rownames(x))
  total / ncol(x)
}

# La silueta de un ajuste cualitativo se mide con SU disimilitud: Gower si el
# método la guardó, emparejamiento simple si no. Medirla con otra sería juzgar
# una partición que el método nunca vio (la misma regla que en metricas_grupos).
distancias_de_grupos.ajuste_cualitativo <- function(ajuste, filas) {
  if (!is.null(ajuste$matriz_disimilitud))
    return(as.matrix(ajuste$matriz_disimilitud)[filas, filas, drop = FALSE])
  disimilitud_simple(ajuste$x[filas, , drop = FALSE])
}

#' La proporción de cada categoría dentro de cada grupo, variable a variable.
#'
#' Con clases latentes se usan las probabilidades estimadas por el modelo
#' (`probabilidades`), que son el resultado; con k-modos y Gower, las
#' frecuencias observadas en la partición. La columna `global` es la misma
#' proporción en toda la muestra: un grupo se describe por dónde se APARTA de
#' ella, no por lo que comparte con todos.
#'
#' @return data.frame(grupo, variable, categoria, proporcion, global, modal)
perfiles_grupos <- function(ajuste) {
  x <- ajuste$x
  grupos <- factor(ajuste$grupos, levels = seq_len(ajuste$k))
  partes <- lapply(names(x), function(variable) {
    valores <- factor(as.character(x[[variable]]),
                      levels = .niveles_de(x[[variable]]))
    tabla <- .proporciones_variable(ajuste, variable, grupos, valores)
    data.frame(grupo = factor(rep(seq_len(ajuste$k), ncol(tabla)),
                              levels = seq_len(ajuste$k)),
               variable = variable,
               categoria = rep(colnames(tabla), each = ajuste$k),
               proporcion = as.numeric(tabla),
               global = rep(as.numeric(prop.table(table(valores))[
                 colnames(tabla)]), each = ajuste$k))
  })
  perfiles <- do.call(rbind, partes)
  # El modo de cada grupo en cada variable; un empate se lo lleva la primera
  # categoría, igual que en k-modos.
  clave <- paste(perfiles$grupo, perfiles$variable)
  maximo <- stats::ave(perfiles$proporcion, clave, FUN = max)
  primero <- !duplicated(data.frame(clave, perfiles$proporcion == maximo)) &
    perfiles$proporcion == maximo
  perfiles$modal <- primero & maximo > 0
  perfiles
}

.niveles_de <- function(valores) {
  if (is.factor(valores)) levels(droplevels(valores))
  else sort(unique(as.character(valores)))
}

# k x R_j: filas = grupos, columnas = categorías. Un grupo vacío deja su fila
# en cero en vez de NaN.
.proporciones_variable <- function(ajuste, variable, grupos, valores) {
  estimadas <- ajuste$probabilidades[[variable]]
  if (!is.null(estimadas)) {
    tabla <- as.matrix(estimadas)
    if (is.null(colnames(tabla))) colnames(tabla) <- levels(valores)
    # En el orden de los niveles observados, para que `global` case columna a
    # columna; una categoría que el modelo no estimó no se inventa.
    return(tabla[, intersect(levels(valores), colnames(tabla)), drop = FALSE])
  }
  conteos <- table(grupos, valores)
  tabla <- conteos / pmax(rowSums(conteos), 1)
  matrix(tabla, nrow = nrow(tabla), dimnames = list(NULL, colnames(conteos)))
}

# ---------------------------------------------------------------------------
# Validación externa: la partición contra la clase conocida
# ---------------------------------------------------------------------------

#' Índice de Rand ajustado (Hubert y Arabie, 1985), escrito a mano.
#'
#' Cuenta pares de observaciones: cuántos quedan juntos en las dos
#' particiones, corregido por lo que se esperaría al azar con esos mismos
#' tamaños. 1 = las dos particiones coinciden (con cualquier numeración);
#' 0 = no más acuerdo que el azar; puede ser negativo.
#'
#'   ARI = (Σ C(n_ij,2) − E) / (½[Σ C(a_i,2) + Σ C(b_j,2)] − E)
#'   E   = Σ C(a_i,2) · Σ C(b_j,2) / C(n,2)
#'
#' @param a,b dos particiones de las mismas observaciones (se ignoran los NA)
indice_rand_ajustado <- function(a, b) {
  if (length(a) != length(b)) stop("las dos particiones tienen largos distintos")
  validas <- !is.na(a) & !is.na(b)
  tabla <- table(as.character(a[validas]), as.character(b[validas]))
  n <- sum(tabla)
  if (n < 2L) return(NA_real_)
  pares <- function(v) sum(choose(v, 2))
  conjuntos <- pares(tabla)
  filas <- pares(rowSums(tabla)); columnas <- pares(colSums(tabla))
  esperado <- filas * columnas / choose(n, 2)
  maximo <- (filas + columnas) / 2
  # Las dos particiones triviales (todo junto o todo separado) dejan el
  # denominador en cero: si coinciden el acuerdo es total, si no, nulo.
  if (isTRUE(all.equal(maximo, esperado)))
    return(if (isTRUE(all.equal(conjuntos, maximo))) 1 else 0)
  (conjuntos - esperado) / (maximo - esperado)
}

#' Grupo contra clase real: la tabla, el ARI y la pureza.
#'
#' Sirve para cualquier ajuste con `grupos` (también para k-medias sobre las
#' dimensiones del ACM: el tándem se juzga igual). La pureza es la fracción de
#' observaciones que caen en la clase mayoritaria de su grupo: fácil de leer,
#' pero sube sola al subir k, y por eso va al lado del ARI y no en su lugar.
#'
#' @param clase vector alineado con las filas del ajuste
#' @return list(tabla, celdas, ari, pureza, n, k)
cruce_con_clase <- function(ajuste, clase = ajuste$referencia) {
  if (is.null(clase))
    stop(paste("no hay clase de referencia: declarala con rol 'respuesta'",
               "en el Diccionario o con --clase <columna> en la consola"))
  if (length(clase) != length(ajuste$grupos))
    stop("la clase de referencia no está alineada con las filas del ajuste")
  grupos <- factor(ajuste$grupos, levels = seq_len(ajuste$k))
  # Un factor conserva su orden (Zoo: el de UCI, mamífero primero); el texto
  # va en orden alfabético.
  clase <- if (is.factor(clase)) droplevels(clase) else factor(clase)
  tabla <- table(grupo = grupos, clase = clase)
  celdas <- as.data.frame(tabla, responseName = "n", stringsAsFactors = FALSE)
  celdas$grupo <- factor(celdas$grupo, levels = seq_len(ajuste$k))
  celdas$clase <- factor(celdas$clase, levels = colnames(tabla))
  celdas$proporcion <- celdas$n / pmax(stats::ave(celdas$n, celdas$grupo,
                                                  FUN = sum), 1)
  list(tabla = tabla, celdas = celdas,
       ari = indice_rand_ajustado(ajuste$grupos, clase),
       pureza = sum(apply(tabla, 1L, max)) / sum(tabla),
       n = sum(tabla), k = ajuste$k)
}

#' La columna con rol "respuesta" del diccionario, o NULL.
columna_referencia <- function(dataset) {
  if (is.null(dataset)) return(NULL)
  candidatas <- columnas_con_rol(dataset, "respuesta")
  if (length(candidatas)) candidatas[1] else NULL
}

#' Pega a la corrida la clase de referencia, recortada a las filas que de
#' verdad entraron al ajuste (las completas en sus columnas: la misma regla del
#' color del mapa). Si no hay clase declarada, devuelve el ajuste tal cual.
adjuntar_referencia <- function(ajuste, dataset, columna = NULL) {
  columna <- columna %||% columna_referencia(dataset)
  if (is.null(columna) || is.null(ajuste$grupos) ||
      !columna %in% names(dataset$df)) return(ajuste)
  if (columna %in% ajuste$columnas)
    warning(sprintf(paste("'%s' es la clase de referencia y además entró al",
                          "ajuste: la validación queda contaminada"), columna))
  completas <- stats::complete.cases(dataset$df[, ajuste$columnas, drop = FALSE])
  ajuste$referencia <- dataset$df[[columna]][completas]
  ajuste$columna_referencia <- columna
  ajuste
}

#' El ARI como métrica de la corrida, solo si hay clase adjunta.
metricas_de_referencia <- function(ajuste) {
  if (is.null(ajuste$referencia)) return(list())
  list(ari = indice_rand_ajustado(ajuste$grupos, ajuste$referencia))
}

#' La tabla de selección de k de un modelo de mezclas: BIC y AIC por k.
#' Hoy la producen las clases latentes; un GMM con `seleccion` entra igual.
#' @return data.frame(k, log_verosimilitud, n_parametros, bic, aic)
bic_mezclas <- function(ajuste) {
  if (is.null(ajuste$seleccion) || !nrow(ajuste$seleccion))
    stop("este ajuste no trae tabla de selección por k (campo `seleccion`)")
  tabla <- as.data.frame(ajuste$seleccion)
  attr(tabla, "k_elegido") <- ajuste$k
  tabla
}

# ---------------------------------------------------------------------------
# La calidad de una partición y el codo (sesión 5)
# ---------------------------------------------------------------------------

#' La d de una partición: la disimilitud media dentro de cada grupo, sumada.
#'
#'   d = Σ_k (1/n_k) Σ_{i<j ∈ G_k} d(i, j)
#'
#' Es la medida con que la sesión 5 compara dos agrupamientos ("entre más
#' pequeña, mayor homogeneidad promedio dentro de los K grupos"). Con la
#' euclídea al cuadrado reproduce `calcular_d2` del cuaderno del curso
#' —`sum(dist(vals)^2) / length(vals)` por grupo, cada par una vez— y coincide
#' con la suma de `withinss` de k-medias: Σ_{i<j} ‖x_i − x_j‖² / n_k es la suma
#' de cuadrados contra el centroide. Por eso sirve de puente: la misma cuenta
#' juzga una partición numérica y una de factores, cambiando solo d(i, j).
#'
#' @param x data.frame (o matriz) de las filas agrupadas, o un objeto `dist`
#'   ya calculado (la matriz de Gower que guardó el ajuste). Con `euclidea2`
#'   un `dist` se eleva al cuadrado; con las otras dos se usa tal cual.
#' @param grupos partición alineada con las filas, sin NA
#' @param distancia "emparejamiento" (variables en que difieren, la de
#'   k-modas), "gower" (en [0, 1]) o "euclidea2" (euclídea al cuadrado, sin
#'   escalar: escalar es decisión de quien llama)
#' @return el total, con los atributos `por_grupo` y `distancia`
disimilitud_particion <- function(x, grupos,
                                  distancia = c("emparejamiento", "gower",
                                                "euclidea2")) {
  distancia <- match.arg(distancia)
  d <- .disimilitudes_para_particion(x, distancia)
  if (length(grupos) != nrow(d))
    stop("la partición no está alineada con las filas: ", length(grupos),
         " grupos para ", nrow(d), " filas")
  if (anyNA(grupos)) stop("la partición tiene filas sin grupo (NA)")
  por_grupo <- vapply(split(seq_along(grupos), factor(grupos)), function(filas) {
    bloque <- d[filas, filas, drop = FALSE]
    sum(bloque[upper.tri(bloque)]) / length(filas)
  }, numeric(1))
  structure(sum(por_grupo), por_grupo = por_grupo, distancia = distancia)
}

.disimilitudes_para_particion <- function(x, distancia) {
  if (inherits(x, "dist")) {
    d <- as.matrix(x)
    return(if (distancia == "euclidea2") d^2 else d)
  }
  marco <- as.data.frame(x)
  switch(distancia,
    # disimilitud_simple() da la FRACCIÓN de variables; acá va el conteo, que
    # es la unidad del costo de k-modas.
    emparejamiento = disimilitud_simple(marco) * ncol(marco),
    gower = as.matrix(cluster::daisy(as.data.frame(lapply(marco, function(v)
      if (is.character(v)) factor(v) else v)), metric = "gower")),
    euclidea2 = as.matrix(stats::dist(as.matrix(marco)))^2)
}

# La d de la corrida, en la disimilitud con que el método agrupó.
.d_de_la_particion <- function(ajuste) {
  if (!is.null(ajuste$matriz_disimilitud))
    return(as.numeric(disimilitud_particion(ajuste$matriz_disimilitud,
                                            ajuste$grupos, "gower")))
  as.numeric(disimilitud_particion(ajuste$x, ajuste$grupos, "emparejamiento"))
}

#' El codo de una partición de factores: el costo para cada k de 1 a k_max.
#'
#' Igual que el codo numérico, cada punto es un ajuste completo con el mismo
#' método, los mismos hiperparámetros y la misma semilla; lo que cambia es qué
#' se mide, porque "inercia" no existe sin centroides:
#'   - k-modas: su propio costo, el total de desacuerdos con el modo del grupo
#'     (lo que el algoritmo minimiza);
#'   - Gower (PAM o jerárquico): la d de la partición sobre la matriz de Gower
#'     del ajuste, la medida de la sesión 5.
#' Empieza en k = 1 —todos juntos, con un solo modo o un solo grupo— porque esa
#' es la referencia de la "reducción" del curso: `proporcion` es cuánto bajó
#' el costo respecto de k = 1, y `reduccion` la misma resta sin dividir.
#'
#' @return data.frame(k, inercia, proporcion, reduccion) con el atributo
#'   `criterio` (el nombre del eje y)
inercia_por_k.ajuste_cualitativo <- function(ajuste, k_max = 10L) {
  medir <- .medida_codo(ajuste)
  distintas <- sum(!duplicated(ajuste$x))
  k_max <- max(2L, min(as.integer(k_max), ajuste$n - 1L, distintas))
  costos <- vapply(seq_len(k_max), medir, numeric(1))
  tabla <- data.frame(k = seq_len(k_max), inercia = costos,
                      proporcion = 1 - costos / costos[1],
                      reduccion = costos[1] - costos)
  attr(tabla, "criterio") <- attr(medir, "criterio")
  tabla
}

# Una función k -> costo, con el reajuste del método de la corrida.
.medida_codo <- function(ajuste) {
  x <- ajuste$x
  if (inherits(ajuste, "ajuste_kmodos"))
    return(structure(function(k) {
      if (k == 1L) return(sum(vapply(x, function(v)
        length(v) - max(table(v)), numeric(1))))
      ajustar_kmodos(x, columnas = names(x), k = k,
                     inicializacion = ajuste$inicializacion,
                     reinicios = ajuste$reinicios, maxit = ajuste$maxit,
                     semilla = ajuste$semilla, registrar_traza = FALSE)$costo
    }, criterio = "costo (desacuerdos con el modo)"))
  if (inherits(ajuste, "ajuste_gower"))
    return(structure(function(k) {
      grupos <- if (k == 1L) rep(1L, ajuste$n) else
        ajustar_gower(x, columnas = names(x), k = k,
                      estrategia = ajuste$estrategia, enlace = ajuste$enlace,
                      binarias_asimetricas = ajuste$binarias_asimetricas,
                      semilla = ajuste$semilla, registrar_traza = FALSE)$grupos
      as.numeric(disimilitud_particion(ajuste$matriz_disimilitud, grupos,
                                       "gower"))
    }, criterio = "d de la partición (Gower)"))
  stop(paste("el codo no está definido para", class(ajuste)[1], "· las",
             "clases latentes eligen k con el BIC (f4.diagnostico.bic)"),
       call. = FALSE)
}

# ---------------------------------------------------------------------------
# El plano: un ACM de los mismos factores
# ---------------------------------------------------------------------------

# El ACM de `x`, con las dimensiones que pida el par de ejes. Se rehace cada
# vez (101 x 16 son milisegundos) en vez de guardarlo en el ajuste: así el
# método no tiene que saber que la fase 4 lo dibuja así.
.acm_del_ajuste <- function(ajuste, dimensiones = 2L) {
  ajustar_acm(ajuste$x, columnas = names(ajuste$x),
              n_componentes = max(2L, as.integer(dimensiones)))
}

# ---------------------------------------------------------------------------
# La cara de la familia hacia la UI (genéricas de metricas.R)
# ---------------------------------------------------------------------------

metricas_de_corrida.ajuste_cualitativo <- function(ajuste) {
  siluetas <- silueta(ajuste)
  base <- list(n = ajuste$n, p = ajuste$p, k = ajuste$k,
               silueta_media = mean(siluetas$s),
               silueta_muestreada = isTRUE(attr(siluetas, "muestreada")),
               grupo_menor = min(ajuste$tamanos),
               grupo_mayor = max(ajuste$tamanos),
               costo = ajuste$costo,
               d_particion = .d_de_la_particion(ajuste),
               log_verosimilitud = ajuste$log_verosimilitud,
               bic = ajuste$bic,
               iteraciones = ajuste$iteraciones,
               convergio = if (!is.null(ajuste$convergio))
                 isTRUE(ajuste$convergio))
  c(Filter(Negate(is.null), base), metricas_de_referencia(ajuste))
}

#' Las filas en el plano del ACM de los mismos factores que se agruparon.
#' Como en la familia numérica, es un dibujo: la partición vive en las p
#' variables, y el plano solo muestra la parte de la asociación que cabe en
#' dos dimensiones.
#'
#' @param grupo color: NULL = la partición del ajuste; un vector de enteros
#'   1..k (el paso a paso de la fase 3) o cualquier columna (la clase real).
coordenadas_2d.ajuste_cualitativo <- function(ajuste, ejes = c(1L, 2L),
                                              grupo = NULL, ...) {
  ejes <- as.integer(ejes)
  acm <- .acm_del_ajuste(ajuste, max(ejes))
  if (any(ejes > ncol(acm$puntuaciones)))
    stop(sprintf("el ACM de estos factores tiene %d dimensiones",
                 ncol(acm$puntuaciones)))
  color <- grupo %||% ajuste$grupos
  es_particion <- is.numeric(color) && all(color %in% seq_len(ajuste$k))
  data.frame(fila = seq_len(nrow(acm$puntuaciones)),
             x = acm$puntuaciones[, ejes[1]], y = acm$puntuaciones[, ejes[2]],
             grupo = if (es_particion) factor(color, levels = seq_len(ajuste$k))
                     else factor(color), row.names = NULL)
}

# Las dimensiones con su inercia, como en el ACM: "Dim1 (14.2 %)". Hasta cinco,
# para poder mirar otros planos sin ofrecer veinte ejes que nadie lee.
etiquetas_ejes.ajuste_cualitativo <- function(ajuste) {
  acm <- .acm_del_ajuste(ajuste, 5L)
  usar <- seq_len(min(5L, length(acm$valores_propios)))
  sprintf("Dim%d (%.1f %%)", usar, 100 * acm$varianza_explicada[usar])
}

#' Un grupo por fila: tamaño y los rasgos que más lo apartan de la muestra.
#' @return data.frame(grupo, n, proporcion, rasgos)
tabla_resultado.ajuste_cualitativo <- function(ajuste) {
  perfiles <- perfiles_grupos(ajuste)
  modales <- perfiles[perfiles$modal, ]
  modales$realce <- modales$proporcion - modales$global
  rasgos <- vapply(seq_len(ajuste$k), function(j) {
    propios <- modales[modales$grupo == j, ]
    propios <- utils::head(propios[order(-propios$realce), ], 4L)
    paste(sprintf("%s=%s (%.0f%%)", propios$variable, propios$categoria,
                  100 * propios$proporcion), collapse = ", ")
  }, character(1))
  data.frame(grupo = factor(seq_len(ajuste$k)), n = ajuste$tamanos,
             proporcion = ajuste$tamanos / sum(ajuste$tamanos),
             rasgos = rasgos)
}

grafico_resultado.ajuste_cualitativo <- function(ajuste, ...) {
  graficar_modos(perfiles_grupos(ajuste), ...)
}

resumen_ajuste.ajuste_cualitativo <- function(ajuste) {
  criterio <- if (!is.null(ajuste$bic)) list("BIC" = sprintf("%.1f", ajuste$bic))
              else if (!is.null(ajuste$costo))
                list("costo" = sprintf("%.3f", ajuste$costo))
  c(list("grupos" = ajuste$k,
         "disimilitud" = ajuste$disimilitud %||% "verosimilitud"),
    criterio,
    list("grupo menor" = min(ajuste$tamanos)),
    if (!is.null(ajuste$referencia))
      list("ARI" = sprintf("%.3f", metricas_de_referencia(ajuste)$ari)))
}

lectura_resultado.ajuste_cualitativo <- function(ajuste, ...) {
  tamanos <- ajuste$tamanos
  base <- sprintf(paste("Los %d grupos van de %d a %d observaciones. Cada uno",
                        "se describe por su categoría más frecuente en cada",
                        "variable: mirá dónde se aparta de la muestra, no",
                        "dónde coincide con todos."),
                  ajuste$k, min(tamanos), max(tamanos))
  if (is.null(ajuste$referencia)) return(base)
  sprintf("%s Contra '%s' el ARI es %.3f: 1 sería la clase real, 0 el azar.",
          base, ajuste$columna_referencia %||% "la clase",
          metricas_de_referencia(ajuste)$ari)
}
