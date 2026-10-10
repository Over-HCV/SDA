# learn/R/nucleo/informe/codigos/cualitativos/despacho.R
#
# Responsabilidad: decidir qué generador escribe cada panel (fases 3 y 4) de
# los métodos cualitativos —k-modas, Gower, clases latentes y el ACM— y
# emitir las piezas que todos comparten: los factores que entran y el ajuste
# con nombre estable.
#
# La filosofía es la de k-medias en `fase4/agrupamiento.R`: el cuaderno no
# hace `source()` del lab, rehace el método en R legible. Acá se va un paso más
# allá porque estos métodos no tienen una función de base que el estudiante ya
# conozca: k-modas y el EM de clases latentes se escriben a mano (los mismos
# pasos que `metodos/kmodos.R` y `metodos/clases_latentes.R`, sin la
# contabilidad de la traza que el lab necesita para sus vistas), y Gower usa
# cluster::daisy() + pam()/hclust(), igual que el lab. Con la misma semilla,
# los mismos reinicios y las mismas columnas, los grupos coinciden con los del
# lab; test_informe_cualitativo.R lo comprueba ejecutando los chunks.
#
# Cada ajuste del cuaderno es una lista con un contrato mínimo que leen los
# paneles compartidos (`paneles.R`): grupos (con el nombre de la fila), k, x
# (los factores), traza y trazas (el objetivo por iteración del ganador y de
# cada reinicio), criterio (qué mide la traza) y asignaciones (la partición
# después de cada iteración, cuando el método la tiene).

# Los métodos cuyos paneles escribe esta carpeta.
METODOS_CUALITATIVOS <- c("kmodos", "gower", "clases_latentes")

# Clave del panel -> generador. Un panel que no está acá cae al despacho de
# siempre, que dice "no se dibuja para este método" o documenta los
# parámetros: nunca un chunk que no corre.
.GENERADORES_CUALITATIVOS <- list(
  "f3.analisis.convergencia" = ".cq_convergencia",
  "f3.analisis.trayectoria" = ".cq_trayectoria",
  "f3.consola.estado" = ".cq_estado",
  "f4.desempeno.grupos" = ".cq_grupos",
  "f4.desempeno.cruce_clase" = ".cq_cruce_clase",
  "f4.diagnostico.silueta" = ".cq_silueta",
  "f4.diagnostico.codo" = ".cq_codo",
  "f4.explicabilidad.modos" = ".cq_modos",
  "f4.explicabilidad.mapa_2d" = ".cq_mapa_2d",
  "f4.diagnostico.dendrograma" = ".cq_dendrograma",
  "f4.diagnostico.bic" = ".cq_bic")

# El ACM tiene dos paneles propios (el resto de sus claves sigue el camino
# del ACP, que dice que no aplica).
.GENERADORES_ACM <- list(
  "f4.diagnostico.scree" = ".acm_scree",
  "f4.explicabilidad.mapa_2d" = ".acm_mapa_2d")

#' El código de un panel de un método cualitativo, o NULL si no le toca.
#'
#' Además de la clave mira que el método DECLARE el panel: el dendrograma
#' es de Gower y solo con `estrategia = jerarquico`; pedirlo para PAM dice
#' por qué no hay árbol en vez de dibujar otra cosa.
.codigo_cualitativo <- function(clave, params) {
  clave_metodo <- params$metodo %||% ""
  if (identical(clave_metodo, "acm")) {
    generador <- .GENERADORES_ACM[[clave]]
    return(if (is.null(generador)) NULL else
      get(generador, mode = "function")(params))
  }
  if (!clave_metodo %in% METODOS_CUALITATIVOS) return(NULL)
  generador <- .GENERADORES_CUALITATIVOS[[clave]]
  if (is.null(generador) || !clave %in% metodo(clave_metodo)$artefactos)
    return(NULL)
  get(generador, mode = "function")(params)
}

#' Las fases 3 sin generador propio (k-medias, ACP) caen al genérico.
.codigo_fase3 <- function(clave, params) .codigo_cualitativo(clave, params)

#' Los paquetes que cargan los paneles cualitativos.
.paquetes_cualitativos <- function(clave, params) {
  clave_metodo <- params$metodo %||% ""
  if (!clave_metodo %in% c(METODOS_CUALITATIVOS, "acm") ||
      is.null(.codigo_cualitativo(clave, params))) return(character(0))
  c(if (identical(clave_metodo, "gower") ||
        identical(clave, "f4.diagnostico.silueta")) "cluster" else NULL,
    if (identical(clave, "f4.diagnostico.silueta")) "factoextra" else NULL)
}

#' Los factores que entran al ajuste, rehechos en cada chunk.
#'
#' Las columnas viajan en `params$columnas` (las arma la consola con la misma
#' regla que el ajuste del lab). Sin ellas, se toman todas salvo el
#' identificador y la clase de referencia, que nunca entra al ajuste: el
#' CSV trae como números columnas que son códigos (`patas`).
#' Todo pasa a factor: `patas` llega del CSV como número y es un código; en
#' Gower las que el lab trataba como números (`params$numericas`) se quedan.
.cq_factores <- function(p) {
  columnas <- if (length(p$columnas)) .f4_vector_plegado("columnas", p$columnas, 66L)
    else sprintf('columnas <- setdiff(names(datos), c(names(id), "%s"))',
                 p$clase %||% "")
  a_factor <- if (length(p$numericas)) c(
    .f4_vector_plegado("numericas", p$numericas, 66L),
    "nominales <- setdiff(columnas, numericas)",
    "cuali[nominales] <- lapply(cuali[nominales], factor)")
    else "cuali[] <- lapply(cuali, factor)"
  c("# Los factores que se agrupan, con el nombre de cada fila (la",
    "# columna de texto sin repetidos) como rótulo.",
    "id <- Filter(function(v) is.character(v) && !anyDuplicated(v),",
    "             datos)",
    "filas <- if (length(id)) id[[1]] else rownames(datos)",
    columnas,
    "cuali <- datos[columnas]",
    "rownames(cuali) <- filas",
    "cuali <- na.omit(cuali)",
    a_factor)
}

#' El ajuste del método: la definición de la función (a mano o con cluster)
#' y la llamada, protegida para no rehacerla si ya existe sobre las mismas
#' filas. El cuaderno pliega la definición repetida (plegar_definiciones()).
#'
#' @return list(lineas, objeto): las líneas y el nombre del ajuste
.cq_ajuste <- function(p) {
  h <- p$hiper %||% list()
  k <- as.integer(h$k %||% 3L)
  semilla <- as.integer(p$semilla %||% 42L)
  reinicios <- as.integer(p$reinicios %||% 25L)
  maxit <- as.integer(p$maxit %||% 500L)
  ajuste <- switch(p$metodo,
    kmodos = .cq_ajuste_kmodos(k, reinicios, semilla, maxit),
    gower = .cq_ajuste_gower(k, h),
    clases_latentes = .cq_ajuste_latente(k, as.integer(h$k_max %||% 8L),
                                         reinicios, semilla, maxit))
  ajuste$lineas <- c(.cq_factores(p), ajuste$definicion,
    sprintf('if (!exists("%s") ||', ajuste$objeto),
    sprintf("    !identical(names(%s$grupos), rownames(cuali))) {",
            ajuste$objeto),
    paste0("  ", ajuste$llamada), "}")
  ajuste
}

# Un bloque de código escrito como texto: más fácil de leer y corregir que
# un c() de cadenas. `@nombre@` se reemplaza por el valor.
.cq_texto <- function(texto, ...) {
  valores <- list(...)
  for (nombre in names(valores))
    texto <- gsub(paste0("@", nombre, "@"), valores[[nombre]], texto,
                  fixed = TRUE)
  lineas <- strsplit(texto, "\n", fixed = TRUE)[[1]]
  lineas[cumsum(nzchar(lineas)) > 0]
}
