# learn/R/lab/pedidos.R
#
# Responsabilidad: traducir los paneles pedidos por consola
# (`clave:token+token,...`) a las entradas de selección que arma el cuaderno.
#
# En la app esos parámetros salen de los controles del sidebar y de la casilla
# "Añadir"; acá salen de la línea de comandos, y tienen que quedar idénticos
# para que `cuaderno` y `sesion` den lo mismo que la pestaña Informe.

#' Los paneles pedidos: los de la línea de comandos o, si no hay, los que
#' venían marcados en la sesión.
seleccion_de_args <- function(ds, args, opciones) {
  pedidos <- if (!is.na(args[1]) && nzchar(args[1] %||% ""))
    strsplit(args[1], ",", fixed = TRUE)[[1]] else character(0)
  if (length(pedidos))
    return(lapply(seq_along(pedidos), function(i)
      entrada_de_pedido(pedidos[i], ds, sprintf("p%d", i), opciones)))
  if (is.null(opciones$sesion))
    stop("faltan argumentos · uso: cuaderno <clave>[:col+col][,...] ",
         "(o --sesion archivo.json)", call. = FALSE)
  guardada <- seleccion_de_sesion(leer_sesion_cli(opciones$sesion)$fase1)
  seleccion_con_tablas(guardada, ds)
}

#' Las piezas del cuaderno pedidas en la línea de comandos.
#'
#' Se parte de las de la sesión (si se pasó una) o de las de fábrica, y encima
#' se aplican `--incluir` y `--excluir`, que son listas separadas por comas.
.piezas_pedidas <- function(opciones) {
  base <- if (is.null(opciones$sesion)) opciones_cuaderno() else
    opciones_cuaderno(leer_sesion_cli(opciones$sesion)$fase1$cuaderno)
  piezas <- union(base, .lista_de_opcion(opciones$incluir))
  opciones_cuaderno(setdiff(piezas, .lista_de_opcion(opciones$excluir)))
}

.lista_de_opcion <- function(valor) {
  if (is.null(valor) || !nzchar(valor)) return(character(0))
  trimws(strsplit(valor, ",", fixed = TRUE)[[1]])
}

#' Un `clave:token+token` a la entrada de selección que espera el cuaderno.
#'
#' Fase 1: los tokens sin `=` son columnas y se reparten en el orden que el
#' generador de esa clave declara (`PARAMS_REQUERIDOS`); los que traen `=` son
#' opciones con nombre, como `marginales=TRUE`. Fase 4: ver params_f4().
entrada_de_pedido <- function(pedido, ds, id = "p1", opciones = list()) {
  partes <- strsplit(pedido, ":", fixed = TRUE)[[1]]
  clave <- partes[1]
  if (!existe_artefacto(clave))
    stop("clave desconocida: ", clave, ". Ver: Rscript learn/R/lab.R casillas",
         call. = FALSE)
  tokens <- if (length(partes) > 1L)
    strsplit(partes[2], "+", fixed = TRUE)[[1]] else character(0)
  params <- if (grepl("^f[34][.]", clave))
    params_f4(clave, tokens, opciones, ds)
            else .completar_params(clave, params_de_pedido(clave, tokens), ds)
  if (!params_completos(clave, params))
    message("[aviso] ", clave, " necesita ",
            paste(PARAMS_REQUERIDOS[[clave]], collapse = " + "),
            ": escribilo como ", clave, ":columna")
  list(id = id, clave = clave, titulo = titulo_de(clave),
       cuando = format(Sys.time(), "%H:%M:%S"), params = params,
       tabla = tabla_de_seleccion(clave, params, ds))
}

#' Los parámetros de un panel de la fase 4: con qué método se ajusta y cómo
#' se mira. Es el contrato con los generadores del cuaderno:
#'
#'   list(metodo = "acp",
#'        hiper  = <todos los de hiper_por_defecto(metodo), pisados>,
#'        ejes   = c(1L, 2L),          # si se pidió `ejes=1-2`
#'        top    = 30L,                # si se pidió `top=30`
#'        grupos = list(metodo, hiper) # si la línea trae --grupos
#'        reduccion = list(metodo, hiper, columnas, dimensiones),  # tándem
#'        clase  = "tipo",             # si hay clase de referencia
#'        semilla = 42L, reinicios = 25L,  # el control del ajuste
#'        columnas = c(...), numericas = c(...))  # métodos cualitativos
#'
#' Los paneles de la fase 3 (`f3.`) usan el mismo contrato: son del método.
#'
#' `--metodo` y `--hiper` de la línea valen de default para el panel que no
#' traiga `metodo=`; lo que traiga el token pisa. Otros `nombre=valor` (como
#' `umbral=0.9`) pasan tal cual.
params_f4 <- function(clave, tokens, opciones = list(), ds = NULL) {
  pares <- .lab_pares(tokens[grepl("=", tokens, fixed = TRUE)])
  sueltos <- tokens[!grepl("=", tokens, fixed = TRUE)]
  if (length(sueltos))
    message("[aviso] ", clave, " no toma columnas sueltas: se ignoran ",
            paste(sueltos, collapse = ", "))
  metodo <- metodo_para_clave(clave, pares$metodo %||% opciones$metodo)
  defecto <- hiper_por_defecto(metodo)
  heredados <- if (identical(metodo, opciones$metodo %||% metodo))
    hiper_cli(metodo, opciones) else list()
  propios <- pares[names(pares) %in% names(defecto)]
  hiper <- utils::modifyList(
    utils::modifyList(defecto, heredados),
    stats::setNames(lapply(names(propios), function(nombre)
      convertir_hiper(metodo, nombre, propios[[nombre]])), names(propios)))
  sobrantes <- pares[setdiff(names(pares),
                             c("metodo", "ejes", "top", names(defecto)))]
  params <- c(list(metodo = metodo, hiper = hiper),
              if (!is.null(pares$ejes))
                list(ejes = as.integer(strsplit(pares$ejes, "[-,]")[[1]])),
              if (!is.null(pares$top)) list(top = as.integer(pares$top)),
              lapply(sobrantes, .convertir))
  if (!is.null(opciones$grupos) && nzchar(opciones$grupos))
    params$grupos <- list(metodo = opciones$grupos,
                          hiper = hiper_cli(opciones$grupos, opciones))
  # El tándem viaja como receta, igual que los grupos: el cuaderno rehace el
  # ACM y agrupa sobre sus dimensiones, en vez de leerlas de un CSV.
  if (!is.null(ds$reduccion)) params$reduccion <- ds$reduccion
  clase <- opciones$clase %||% columna_referencia(ds)
  if (!is.null(clase) && nzchar(clase)) params$clase <- clase
  # El control del ajuste, con los defaults de ajustar_cli(): sin ellos el
  # cuaderno ajusta con otros reinicios y su partición no es la del lab.
  params$semilla <- as.integer(opciones$semilla %||% 42L)
  params$reinicios <- as.integer(opciones$reinicios %||% 25L)
  c(params, .columnas_cualitativas(metodo, opciones, ds))
}

#' Las columnas con que el lab ajusta un método cualitativo, para que el
#' cuaderno agrupe exactamente esas (y sepa cuáles eran números: Gower las
#' trata distinto). Los métodos numéricos rehacen su matriz en el chunk.
.columnas_cualitativas <- function(clave_metodo, opciones, ds) {
  if (is.null(ds) || !identical(metodo(clave_metodo)$entrada$tipo,
                                "matriz_cualitativa")) return(list())
  columnas <- columnas_para(ds, clave_metodo, opciones) %||%
    columnas_de_entrada(ds, clave_metodo)
  numericas <- columnas[vapply(ds$df[columnas], is.numeric, logical(1))]
  c(list(columnas = columnas),
    if (length(numericas)) list(numericas = numericas))
}

#' Lo que la app saca de sus controles y la consola tiene que sacar del
#' diccionario: la escala decide qué resumen se emite.
.completar_params <- function(clave, params, ds) {
  if (identical(clave, "f1.analisis.resumen") && !is.null(params$variable) &&
      is.null(params$escala))
    params$escala <- .escala_cli(ds, params$variable)
  params
}

params_de_pedido <- function(clave, tokens) {
  con_nombre <- grepl("=", tokens, fixed = TRUE)
  nombrados <- lapply(sub("^[^=]*=", "", tokens[con_nombre]), .convertir)
  names(nombrados) <- sub("=.*$", "", tokens[con_nombre])
  c(.columnas_a_params(clave, tokens[!con_nombre]), nombrados)
}

#' Las columnas sueltas, puestas en los campos que la clave declara. Un campo
#' llamado `variables` es plural de verdad: se lleva todas las columnas.
.columnas_a_params <- function(clave, columnas) {
  campos <- PARAMS_REQUERIDOS[[clave]]
  if (is.null(campos) || !length(columnas)) return(list())
  if (identical(campos, "variables")) return(list(variables = columnas))
  stats::setNames(as.list(columnas[seq_along(campos)]),
                  campos[seq_along(columnas)])
}

.convertir <- function(x) {
  if (x %in% c("TRUE", "FALSE")) return(as.logical(x))
  numero <- suppressWarnings(as.numeric(x))
  if (!is.na(numero)) numero else x
}
