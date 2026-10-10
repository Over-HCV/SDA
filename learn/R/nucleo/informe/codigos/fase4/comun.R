# learn/R/nucleo/informe/codigos/fase4/comun.R
#
# Responsabilidad: despachar los paneles de la fase 4 a su generador y
# emitir las piezas que todos comparten (la matriz numérica, el ajuste del
# método con nombre estable, los grupos adjuntos a `datos`).
#
# Contrato de `params` de una entrada f4 (lo arma la CLI y la pestaña
# Informe):
#
#   list(metodo = "acp" | "kmeans" | "jerarquico",
#        hiper  = list(...),          # nombres del registro
#        ejes   = c(1L, 2L),          # opcional
#        top    = 30L,                # opcional
#        grupos = list(metodo =, hiper =),  # opcional
#        reduccion = list(metodo = "acm", hiper, columnas, dimensiones),
#        clase  = "tipo")             # opcional: la clase de referencia
#
# El código emitido es R base + stats + factoextra, nada del lab: el
# cuaderno tiene que correr en la máquina de quien entrega el taller.

# Qué familias de método sabe dibujar cada clave y con qué función. Las
# funciones van como texto y se buscan al llamar: así esta constante no
# depende de que `agrupamiento.R` o `reduccion.R` estén ya cargados.
.GENERADORES_F4 <- list(
  "f4.diagnostico.scree" = list("acp", ".f4_scree"),
  "f4.diagnostico.reglas_k" = list("acp", ".f4_reglas_k"),
  "f4.explicabilidad.contribuciones" = list("acp", ".f4_contribuciones"),
  "f4.explicabilidad.circulo_correlaciones" = list("acp", ".f4_circulo"),
  "f4.explicabilidad.cargas" = list("acp", ".f4_cargas"),
  "f4.explicabilidad.calidad" = list("acp", ".f4_calidad"),
  "f4.explicabilidad.mapa_2d" = list(c("acp", "grupos"), ".f4_mapa_2d"),
  "f4.diagnostico.codo" = list("grupos", ".f4_codo"),
  "f4.diagnostico.silueta" = list("grupos", ".f4_silueta"),
  "f4.explicabilidad.centroides" = list("grupos", ".f4_centroides"),
  "f4.desempeno.grupos" = list("grupos", ".f4_grupos"),
  "f4.diagnostico.dendrograma" = list("jerarquico", ".f4_dendrograma"),
  "f4.desempeno.cruce_clase" = list("grupos", ".f4_cruce_clase"))

# Las claves que dibujan con factoextra (fviz_*); la silueta además
# calcula con cluster::silhouette().
.CLAVES_FACTOEXTRA <- c(
  "f4.diagnostico.scree", "f4.explicabilidad.contribuciones",
  "f4.explicabilidad.circulo_correlaciones", "f4.explicabilidad.calidad",
  "f4.explicabilidad.mapa_2d", "f4.diagnostico.silueta")

#' @return character() de líneas, o NULL si la clave no tiene generador.
.codigo_fase4 <- function(clave, params) {
  # k-modas, Gower, clases latentes y el ACM tienen su carpeta propia.
  cualitativo <- .codigo_cualitativo(clave, params)
  if (!is.null(cualitativo)) return(cualitativo)
  generador <- .GENERADORES_F4[[clave]]
  if (is.null(generador)) return(NULL)
  if (!.f4_aplica(generador[[1]], params$metodo))
    return(c(sprintf("# (Este panel no se dibuja para el método \"%s\".)",
                     params$metodo %||% ""),
             "# Volvé al lab y marcalo desde una corrida que lo declare."))
  adjunto <- .f4_adjuntar_grupos(params$grupos)
  cuerpo <- get(generador[[2]], mode = "function")(params)
  c(.f4_matriz(), .f4_reduccion(params$reduccion), adjunto,
    .f4_sin_repetir(cuerpo, adjunto))
}

#' Saca del cuerpo los bloques `if (!exists(...)) { ... }` que los grupos
#' adjuntos ya emitieron. Con `--grupos kmeans` y un panel de k-medias el
#' chunk ajustaba `km3` dos veces seguidas: corría igual (el segundo bloque
#' no hace nada), pero el lector veía el mismo ajuste repetido.
.f4_sin_repetir <- function(cuerpo, adjunto) {
  for (i in grep("^if \\(!exists\\(", adjunto)) {
    bloque <- adjunto[i:(i + match("}", adjunto[i:length(adjunto)]) - 1L)]
    n <- length(bloque)
    for (j in seq_len(max(0L, length(cuerpo) - n + 1L))) {
      if (identical(cuerpo[j:(j + n - 1L)], bloque)) {
        cuerpo <- cuerpo[-(j:(j + n - 1L))]
        break
      }
    }
  }
  cuerpo
}

.paquetes_fase4 <- function(clave, params) {
  if (!is.null(.codigo_cualitativo(clave, params)))
    return(.paquetes_cualitativos(clave, params))
  generador <- .GENERADORES_F4[[clave]]
  if (is.null(generador) || !.f4_aplica(generador[[1]], params$metodo))
    return(character(0))
  c(if (clave %in% .CLAVES_FACTOEXTRA) "factoextra" else NULL,
    if (identical(clave, "f4.diagnostico.silueta")) "cluster" else NULL)
}

# `grupos` reúne a las dos familias que parten la muestra; `jerarquico`
# deja pasar solo al que tiene árbol (el dendrograma).
.f4_aplica <- function(familias, metodo) {
  metodo <- metodo %||% ""
  metodo %in% familias ||
    ("grupos" %in% familias && metodo %in% c("kmeans", "jerarquico"))
}

#' La matriz que analizan todos los paneles, rehecha en cada chunk.
#'
#' Se rehace siempre (son milisegundos) para que el chunk corra solo. La
#' columna identificadora se detecta en el cuaderno y no acá, porque el
#' generador no ve los datos: es la primera de texto sin repetidos.
.f4_matriz <- function()
  c("# Las numéricas, con la columna de texto que identifica cada fila",
    "# como nombre: así los gráficos rotulan países y no números.",
    "num <- datos[vapply(datos, is.numeric, logical(1))]",
    "id <- Filter(function(v) is.character(v) && !anyDuplicated(v),",
    "             datos)",
    "filas <- if (length(id)) id[[1]] else rownames(datos)",
    "rownames(num) <- filas",
    "num <- na.omit(num)",
    "# Una columna constante no tiene varianza que repartir ni escalar.",
    "num <- num[vapply(num, sd, numeric(1)) > 0]")

#' El objeto ajustado, con nombre derivado de los hiperparámetros.
#'
#' Se reutiliza si ya existe, pero solo si se ajustó sobre las MISMAS filas:
#' el Taller 02 rehace el ACP sin cuatro países, y un `acp_normado` viejo
#' reciclado en silencio daría el plano de la base completa.
#'
#' @return list(lineas, objeto, grupos, z): las líneas que ajustan, el
#'   nombre del objeto, la expresión R de los grupos y la de la matriz.
.f4_ajuste <- function(metodo, hiper = list(), semilla = 42L) {
  h <- hiper %||% list()
  escalar <- !isFALSE(h$escalar)
  sufijo <- if (escalar) "" else "_crudo"
  z <- if (escalar) "scale(num)" else "as.matrix(num)"
  if (identical(metodo, "acp")) {
    normado <- !identical(h$matriz, "covarianza")
    objeto <- if (normado) "acp_normado" else "acp_crudo"
    return(list(objeto = objeto, z = z, grupos = NULL, lineas = c(
      .f4_guarda(objeto, sprintf("rownames(%s$x)", objeto)),
      sprintf("  %s <- prcomp(num, scale. = %s)", objeto, normado), "}")))
  }
  if (identical(metodo, "kmeans")) {
    k <- as.integer(h$k %||% 3L)
    # 100 arranques y no 25: con 25, stats::kmeans() sobre EIA (taller 02)
    # cae en particiones distintas según la semilla; con 100 coincide con el
    # óptimo que el lab encuentra con k-means++ y 25 reinicios.
    objeto <- sprintf("km%d%s", k, sufijo)
    return(list(objeto = objeto, z = z,
                grupos = sprintf("%s$cluster", objeto), lineas = c(
      .f4_guarda(objeto, sprintf("names(%s$cluster)", objeto)),
      sprintf("  set.seed(%d)", as.integer(semilla)),
      sprintf("  %s <- kmeans(%s, centers = %d, nstart = %d)", objeto, z, k,
              as.integer(h$reinicios %||% 100L)), "}")))
  }
  enlace <- h$enlace %||% "ward.D2"
  distancia <- h$distancia %||% "euclidean"
  corta <- c(euclidean = "", manhattan = "_man", maximum = "_max")
  marca <- if (distancia %in% names(corta)) corta[[distancia]]
    else paste0("_", gsub("[^a-z0-9]+", "_", tolower(distancia)))
  objeto <- paste0("hc_", gsub("[^a-z0-9]+", "_", tolower(enlace)),
                   marca, sufijo)
  list(objeto = objeto, z = z,
       grupos = sprintf("cutree(%s, k = %d)", objeto,
                        as.integer(h$k_corte %||% 3L)), lineas = c(
    .f4_guarda(objeto, sprintf("%s$labels", objeto)),
    sprintf('  distancias <- dist(%s, method = "%s")', z, distancia),
    sprintf('  %s <- hclust(distancias, method = "%s")', objeto, enlace),
    "}"))
}

.f4_guarda <- function(objeto, filas_del_objeto)
  c(sprintf('if (!exists("%s") ||', objeto),
    sprintf("    !identical(%s, rownames(num))) {", filas_del_objeto))

#' Los grupos de otra corrida como columna `grupo` de `datos`: es lo que
#' deja que f1.analisis.boxplot_grupos con grupo = "grupo" funcione en el
#' mismo cuaderno (pregunta 11 del Taller 02). Las filas que se cayeron por
#' faltantes quedan en NA, no corridas un lugar.
.f4_adjuntar_grupos <- function(grupos) {
  if (is.null(grupos) || !(grupos$metodo %||% "") %in%
      c("kmeans", "jerarquico")) return(NULL)
  ajuste <- .f4_ajuste(grupos$metodo, grupos$hiper, grupos$semilla %||% 42L)
  c(ajuste$lineas,
    "# Los grupos, como columna de `datos` (para las cajas por grupo).",
    sprintf("datos$grupo <- factor(%s[filas])", ajuste$grupos))
}

# Un vector de enteros como lo escribiría una persona: c(1, 2).
.vector_r <- function(x) sprintf("c(%s)", paste(as.integer(x), collapse = ", "))

.f4_ejes <- function(p) .vector_r(p$ejes %||% c(1L, 2L))
