# learn/metodos/jerarquico.R
#
# Responsabilidad: agrupar n observaciones por fusiones sucesivas y cortar el
# árbol en k grupos, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3): corre igual desde la app, desde
# run_headless.R y desde una consola de R.
#
# Lo que el jerárquico añade al marco y k-medias no podía dar:
#
#   · Un resultado que no depende de la semilla. Arranca con cada observación
#     sola y en cada paso junta los dos grupos más cercanos; no hay arranque
#     que sortear. La pregunta deja de ser "¿otra semilla da lo mismo?" y pasa a
#     ser "¿otro enlace da lo mismo?".
#   · Todas las particiones a la vez. El árbol guarda de n grupos a uno; k_corte
#     solo elige a qué altura se lee. Por eso cambiar k no reajusta nada.
#
# Acá SÍ se delega en stats::hclust(), al revés que k-medias. No se pierde la
# traza: `$merge` y `$height` son el historial completo de fusiones, en orden,
# y se registra después leyéndolo. Escribir Lance-Williams a mano no enseñaría
# nada que ese historial no muestre.
#
# La teoría está en fichas/jerarquico.md.

#' Ajusta un agrupamiento jerárquico aglomerativo.
#'
#' No acepta `...`: `argumentos_ajuste()` filtra por la firma, y con `...` el
#' filtro se apaga y un hiperparámetro mal escrito pasaría sin avisar. Los
#' mandos que este método no tiene (inicialización, reinicios, tolerancia,
#' techo de iteraciones) no llegan.
#'
#' @param datos           data.frame
#' @param columnas        columnas a usar; NULL = todas las numéricas
#' @param enlace          criterio para medir la distancia entre dos grupos
#' @param distancia       métrica entre observaciones
#' @param k_corte         grupos al cortar el árbol
#' @param escalar         TRUE estandariza cada columna antes de medir
#' @param optimizador     "aglomerativo", el único: se declara para que la
#'                        receta lo guarde como a los demás
#' @param semilla         no gobierna nada (hclust es determinista); viaja al
#'                        JSON igual que en el ACM
#' @param registrar_traza FALSE no guarda el historial de fusiones
#' @return list con grupos, centroides, arbol, cofenética, traza y parámetros
ajustar_jerarquico <- function(datos, columnas = NULL, enlace = "ward.D2",
                               distancia = "euclidean", k_corte = 3L,
                               escalar = TRUE, optimizador = "aglomerativo",
                               semilla = 42L, registrar_traza = TRUE) {
  enlace <- .opcion_exacta(enlace, c("ward.D2", "complete", "average",
                                     "single", "centroid"), "enlace")
  distancia <- .opcion_exacta(distancia, c("euclidean", "manhattan", "maximum"),
                              "distancia")
  optimizador <- .opcion_exacta(optimizador, "aglomerativo", "optimizador")

  preparado <- preparar_matriz_grupos(datos, columnas, escalar,
                                      "el agrupamiento jerarquico")
  z <- preparado$z
  n <- nrow(z)
  k <- as.integer(k_corte)
  if (k < 2L) stop("cortar el arbol en menos de dos grupos no es agrupar")
  if (k >= n) stop("hacen falta mas filas completas que grupos: n = ", n,
                   ", k = ", k)
  # La matriz de distancias es n x n: con 5000 filas son 100 MB solo para ella.
  if (n > 5000L)
    stop("el jerarquico guarda todas las distancias entre pares: con n = ", n,
         " no entra en memoria. Agrupa con k-medias o muestrea antes")

  distancias <- stats::dist(z, method = distancia)
  arbol <- .construir_arbol(distancias, enlace)
  arbol$labels <- .etiquetas_de_filas(datos, preparado$completas)

  grupos <- as.integer(stats::cutree(arbol, k = k))
  centroides <- centroides_de_grupos(z, grupos, k)
  inercia_por_grupo <- inercia_de_grupos(z, grupos, centroides)
  inercia_total <- sum((scale(z, center = TRUE, scale = FALSE))^2)

  structure(list(
    grupos = grupos,
    centroides = centroides,
    inercia = sum(inercia_por_grupo),
    inercia_por_grupo = inercia_por_grupo,
    inercia_total = inercia_total,
    proporcion_explicada = 1 - sum(inercia_por_grupo) / inercia_total,
    tamanos = as.integer(table(factor(grupos, levels = seq_len(k)))),
    arbol = arbol,
    correlacion_cofenetica = stats::cor(as.numeric(distancias),
                                        as.numeric(stats::cophenetic(arbol))),
    z = z,
    centro = preparado$centro, escala = preparado$escala,
    columnas = preparado$columnas,
    n = n, p = ncol(z), k = k,
    filas_descartadas = preparado$descartadas,
    enlace = enlace, distancia = distancia, escalar = escalar,
    optimizador = optimizador, semilla = semilla,
    # Lo que la franja de la fase 3 lee de cualquier ajuste. El algoritmo no
    # tiene tolerancia ni techo: hace exactamente n − 1 fusiones y termina, así
    # que "convergió" es literal y la tolerancia queda en NA, no en un número
    # inventado.
    iteraciones = n - 1L, convergio = TRUE,
    tol = NA_real_, maxit = n - 1L,
    traza = if (isTRUE(registrar_traza)) .traza_fusiones(arbol, z) else NULL),
    class = c("ajuste_jerarquico", "ajuste_agrupamiento", "ajuste_sda"))
}

# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

# match.arg() completa por prefijo: "ward" se volvería "ward.D2" sin avisar, y
# hclust() tiene un "ward.D" que es OTRO criterio. Un enlace se nombra entero.
.opcion_exacta <- function(valor, opciones, nombre) {
  if (length(valor) == 1L && valor %in% opciones) return(valor)
  stop(sprintf("%s '%s' no existe; las opciones son: %s", nombre,
               paste(valor, collapse = ","), paste(opciones, collapse = ", ")))
}

# El enlace del centroide está definido sobre distancias euclídeas AL CUADRADO
# (es lo que dice ?hclust, y lo que hace válida la fórmula de Lance-Williams
# para ese criterio). Se le pasa d² y las alturas vuelven a la escala de d, para
# que el dendrograma y la cofenética se lean en las mismas unidades que los
# demás enlaces. Ward.D2 eleva al cuadrado por su cuenta.
.construir_arbol <- function(distancias, enlace) {
  if (enlace != "centroid") return(stats::hclust(distancias, method = enlace))
  arbol <- stats::hclust(distancias^2, method = "centroid")
  arbol[["height"]] <- sqrt(arbol$height)
  arbol
}

# Un dendrograma de 107 hojas numeradas no se lee: se lee con los nombres de
# los países. Se usan los rownames si alguien los puso, y si no la primera
# columna no numérica que identifique cada fila sin repetir. Unos rownames que
# son todos números no los puso nadie: son los de read.csv, quizá con huecos
# porque se filtraron filas.
.etiquetas_de_filas <- function(datos, completas) {
  nombres <- rownames(datos)
  if (!is.null(nombres) && !all(grepl("^[0-9]+$", nombres)))
    return(nombres[completas])
  for (columna in names(datos)[!vapply(datos, is.numeric, logical(1))]) {
    valores <- as.character(datos[[columna]])[completas]
    if (!anyNA(valores) && !anyDuplicated(valores)) return(valores)
  }
  as.character(which(completas))
}

# La traza del jerárquico es su historial: una iteración por fusión. El
# objetivo es la altura a la que se juntan los dos grupos —sube, salvo las
# inversiones del enlace del centroide, que son reales y la traza no esconde—,
# y el parámetro que se sigue es la inercia intra-grupo de la partición que
# queda después de cada fusión: la misma W que minimiza k-medias, leída al
# revés. Se acumula sin recalcular: juntar A y B sube W en
# |A||B| / (|A| + |B|) · ‖c_A − c_B‖², que es la cuenta de Ward.
.traza_fusiones <- function(arbol, z) {
  n <- nrow(z)
  traza <- nueva_traza("altura de fusion", sentido = "asciende")
  tamanos <- integer(n - 1L)
  centros <- matrix(0, nrow = n - 1L, ncol = ncol(z))
  inercia <- 0
  nodo <- function(j) if (j < 0) list(n = 1L, c = z[-j, ]) else
    list(n = tamanos[j], c = centros[j, ])
  for (i in seq_len(n - 1L)) {
    a <- nodo(arbol$merge[i, 1L]); b <- nodo(arbol$merge[i, 2L])
    inercia <- inercia + a$n * b$n / (a$n + b$n) * sum((a$c - b$c)^2)
    tamanos[i] <- a$n + b$n
    centros[i, ] <- (a$n * a$c + b$n * b$c) / tamanos[i]
    traza <- registrar_iteracion(
      traza, iter = i, objetivo = arbol$height[i],
      delta = if (i == 1L) NA_real_ else arbol$height[i] - arbol$height[i - 1L],
      componente = 1L, parametros = c(inercia_intra = inercia))
  }
  traza
}
