# learn/R/lab/dataset.R
#
# Responsabilidad: de la línea de comandos al dataset sobre el que corre cada
# comando de lab.R — opciones, fuente, sesión, filtros, escalas y grupos.
#
# Vive aparte de lab.R por C2: con los comandos de las fases 2-4 el ejecutable
# pasaba el techo. Lo sourcea lab.R, no cargar_sda(): la consola no viaja al
# bundle del navegador.

# Las opciones que se acumulan en vez de pisarse: repetirlas es lo normal (dos
# filtros encadenados, tres columnas declaradas, varios hiperparámetros).
OPCIONES_REPETIBLES <- c("filtro", "escala", "hiper")

#' Parte los argumentos en posicionales y opciones `--clave valor`.
#'
#' Las repetibles se acumulan en un vector; las demás se quedan con la última,
#' que es lo que uno espera al repetir una por error.
partir_argumentos <- function(argumentos) {
  posicionales <- character(0)
  opciones <- list()
  i <- 1L
  while (i <= length(argumentos)) {
    actual <- argumentos[i]
    if (startsWith(actual, "--")) {
      clave <- sub("^--", "", actual)
      valor <- if (i < length(argumentos)) argumentos[i + 1L] else ""
      opciones[[clave]] <- if (clave %in% OPCIONES_REPETIBLES)
        c(opciones[[clave]], valor) else valor
      i <- i + 2L
    } else {
      posicionales <- c(posicionales, actual)
      i <- i + 1L
    }
  }
  list(posicionales = posicionales, opciones = opciones)
}

#' El dataset sobre el que corre el comando: fuente + filtros, en orden, y al
#' final los grupos de `--grupos` si se pidieron.
#'
#' Devuelve el mismo objeto que la app (`nuevo_dataset()`), así que todo lo que
#' sabe hacer la fase 1 con un dataset sirve acá sin traducción.
armar_dataset <- function(opciones) {
  ds <- if (!is.null(opciones$sesion)) .dataset_de_sesion_cli(opciones)
        else .dataset_de_fuente_cli(opciones)
  for (filtro in opciones$filtro %||% character(0))
    ds <- aplicar_filtro_cli(ds, filtro)
  ds <- declarar_escalas_cli(ds, opciones$escala)
  agregar_grupos_cli(ds, opciones)
}

# Una sesión ya trae fuente, pila y diccionario declarado: si la pasaron, manda
# ella. Los --filtro de la línea se apilan encima, que es lo que uno espera al
# pedir una vuelta de tuerca sobre algo guardado.
.dataset_de_sesion_cli <- function(opciones) {
  reconstruido <- dataset_de_sesion(leer_sesion_cli(opciones$sesion)$fase1)
  for (aviso in reconstruido$avisos) message("[aviso] ", aviso$mensaje)
  if (is.null(reconstruido$dataset))
    stop("la sesión no trae una fuente que se pueda recargar", call. = FALSE)
  reconstruido$dataset
}

# Sin default a propósito. Un default acá no ahorra tecleo: produce en silencio
# un análisis sobre el dataset equivocado, y el cuaderno exportado sale citando
# un CSV que no es el de la pregunta. Mejor negarse.
.dataset_de_fuente_cli <- function(opciones) {
  clave <- opciones$fuente
  if (is.null(clave) || !nzchar(clave))
    stop("falta --fuente. Elegí una de: ",
         paste(fuentes_disponibles()$clave, collapse = ", "), call. = FALSE)
  resultado <- cargar_fuente(clave)
  for (aviso in resultado$avisos) message("[aviso] ", aviso$mensaje)
  nuevo_dataset(NULL, clave, resultado$datos, fuente = clave)
}

#' `--escala Columna=intervalo`, repetible: lo que en la app se corrige a mano
#' en el Diccionario.
#'
#' No es un detalle de tecleo. La autodetección ve números y propone razón; que
#' Temperatura sea de INTERVALO —el 0 °C es convencional, así que 30 °C no es
#' el doble de calor que 15 °C— es información del dominio, y sin esta opción
#' la consola no tenía forma de declararla.
declarar_escalas_cli <- function(ds, expresiones) {
  for (expresion in expresiones %||% character(0)) {
    if (!grepl("=", expresion, fixed = TRUE))
      stop("una escala se escribe Columna=escala, no: ", expresion,
           call. = FALSE)
    columna <- sub("=.*$", "", expresion)
    valor <- sub("^[^=]*=", "", expresion)
    if (!valor %in% ESCALAS)
      stop("escala desconocida: ", valor, " · válidas: ",
           paste(ESCALAS, collapse = ", "), call. = FALSE)
    if (!columna %in% ds$diccionario$columna)
      stop("no existe la columna: ", columna, call. = FALSE)
    ds$diccionario <- actualizar_diccionario(ds$diccionario, columna,
                                             "escala", valor)
  }
  ds
}

#' Una sesión de disco, en cualquiera de los dos formatos.
leer_sesion_cli <- function(ruta) {
  if (!file.exists(ruta)) stop("no existe la sesión: ", ruta, call. = FALSE)
  if (grepl("[.]rds$", ruta, ignore.case = TRUE)) importar_sesion_rds(ruta)
  else importar_sesion_json(ruta)
}

#' Un `--filtro Columna=valor[,valor]` (conservar) o `Columna!=valor[,valor]`
#' (sacar) aplicado sobre el dataset, como una entrada más de la pila.
aplicar_filtro_cli <- function(ds, expresion) {
  if (!grepl("=", expresion, fixed = TRUE))
    stop("un filtro se escribe Columna=valor o Columna!=valor, no: ",
         expresion)
  excluir <- grepl("^[^=]*!=", expresion)
  columna <- sub("!?=.*$", "", expresion)
  valores <- strsplit(sub("^[^=]*=", "", expresion), ",", fixed = TRUE)[[1]]
  pila <- agregar_transformacion(ds$transformaciones, "filtro", columna,
                                 list(valores = valores, excluir = excluir))
  resultado <- aplicar_transformaciones(ds$df, list(pila[[length(pila)]]))
  for (aviso in resultado$avisos)
    message("[", aviso$severidad, "] ", aviso$mensaje)
  ds$df <- resultado$datos
  ds$transformaciones <- pila
  ds$diccionario <- rehacer_diccionario(ds$diccionario, resultado$datos)
  ds$n <- nrow(resultado$datos)
  ds$p <- ncol(resultado$datos)
  ds
}

#' `--grupos <metodo>` (con su `--hiper`): ajusta ese método sobre el dataset
#' ya filtrado y le agrega la columna `grupo`. Es el traspaso ② → ①: los grupos
#' de k-medias vuelven como una cualitativa más, y de ahí las cajas por grupo.
agregar_grupos_cli <- function(ds, opciones) {
  metodo <- opciones$grupos
  if (is.null(metodo) || !nzchar(metodo)) return(ds)
  if ("grupo" %in% names(ds$df))
    message("[aviso] la columna 'grupo' ya existía: se reemplaza")
  ds$df$grupo <- NULL
  ds <- agregar_grupos(ds, metodo, hiper_cli(metodo, opciones),
                       columnas = columnas_cli(opciones),
                       reinicios = as.integer(opciones$reinicios %||% 25L),
                       semilla = as.integer(opciones$semilla %||% 42L))
  tamanos <- table(ds$df$grupo)
  message(sprintf("[grupos] %s · %s", metodo, paste(sprintf(
    "grupo %s: %d", names(tamanos), as.integer(tamanos)), collapse = " · ")))
  ds
}
