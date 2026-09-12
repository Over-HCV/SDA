# learn/R/lab.R
#
# Responsabilidad: hacer el laboratorio DESDE LA CONSOLA, sin navegador.
#
# La app es la forma de mirar; esta es la forma de preguntar por escrito. Sirve
# para responder un taller sin abrir Shiny, para comprobar en dos segundos lo
# que un panel dice, y para que un agente o un script puedan recorrer la fase 1
# igual que una persona recorre las pestañas.
#
# La regla que la hace útil: **un gráfico se devuelve como su TABLA**. `panel`
# construye el mismo ggplot que pinta la app y en vez de dibujarlo imprime las
# capas ya calculadas — los bordes y las alturas del histograma, los bigotes de
# la caja, los puntos de la nube. Es la misma información que uno lee del
# dibujo, en un formato que se puede leer sin ojos.
#
# Uso, desde la raíz del repo:
#
#   Rscript learn/R/lab.R fuentes
#   Rscript learn/R/lab.R datos --fuente ori          # --fuente es obligatorio
#   Rscript learn/R/lab.R resumen Temperatura --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R atipicos Presion --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R asociacion Temperatura Velocidad_del_Viento \
#     --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R panel f1.analisis.histograma Temperatura \
#     --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R cuaderno \
#     f1.analisis.boxplot:Temperatura,\
#     f1.analisis.dispersion:Temperatura+Velocidad_del_Viento+marginales=TRUE \
#     --fuente ori --filtro Hora=12:00 --salida taller.Rmd
#   Rscript learn/R/lab.R sesion f1.analisis.boxplot:Temperatura \
#     --fuente ori --filtro Hora=12:00 --salida sesion.json
#   Rscript learn/R/lab.R cuaderno --sesion sesion.json --salida taller.Rmd
#
# Una SESIÓN (nucleo/sesion.R) es fuente + pila + diccionario + paneles
# marcados. `--sesion archivo.json` arma el dataset desde ella, así que la
# misma configuración sirve por consola y abriendo la app con
# `?sesion=...`: se guarda una vez y se reusa.
#
# `--texto completo|breve|ninguno` gradúa cuánto texto explicativo entra al
# cuaderno. El taller puntúa la concisión, así que es una decisión de quien
# entrega y no una constante.
#
# En `cuaderno`, lo que va tras los dos puntos son los parámetros del panel:
# columnas separadas por `+`, y opciones con nombre como `normal=TRUE`. Son los
# mismos que en la app fijan los controles del sidebar.
#
# Las opciones `--fuente` y `--filtro` arman el dataset ANTES de cada comando y
# se pueden repetir: `--filtro Hora=12:00 --filtro Region=ORI` encadena dos, en
# orden, igual que la pila de la subsección Filtro.

local({
  candidatos <- c("learn/R/cargar.R", "R/cargar.R")
  ruta <- candidatos[file.exists(candidatos)]
  if (!length(ruta)) stop("corre esto desde la raiz del repo (ver AGENT.md)")
  source(ruta[1])
})

# --- Opciones ---------------------------------------------------------------

#' Parte los argumentos en posicionales y opciones `--clave valor`.
#'
#' `--filtro` y `--escala` se acumulan en un vector porque repetirlas es lo
#' normal (dos filtros encadenados, tres columnas declaradas); las demás se
#' quedan con la última, que es lo que uno espera al repetir una por error.
partir_argumentos <- function(argumentos) {
  posicionales <- character(0)
  opciones <- list()
  i <- 1L
  while (i <= length(argumentos)) {
    actual <- argumentos[i]
    if (startsWith(actual, "--")) {
      clave <- sub("^--", "", actual)
      valor <- if (i < length(argumentos)) argumentos[i + 1L] else ""
      opciones[[clave]] <- if (clave %in% c("filtro", "escala"))
        c(opciones[[clave]], valor) else valor
      i <- i + 2L
    } else {
      posicionales <- c(posicionales, actual)
      i <- i + 1L
    }
  }
  list(posicionales = posicionales, opciones = opciones)
}

#' El dataset sobre el que corre el comando: fuente + filtros, en orden.
#'
#' Devuelve el mismo objeto que la app (`nuevo_dataset()`), así que todo lo que
#' sabe hacer la fase 1 con un dataset sirve acá sin traducción.
armar_dataset <- function(opciones) {
  # Una sesión ya trae fuente, pila y diccionario declarado: si la pasaron,
  # manda ella. Los --filtro de la línea se apilan encima, que es lo que uno
  # espera al pedir una vuelta de tuerca sobre algo guardado.
  if (!is.null(opciones$sesion)) {
    fase1 <- leer_sesion_cli(opciones$sesion)$fase1
    reconstruido <- dataset_de_sesion(fase1)
    for (aviso in reconstruido$avisos) message("[aviso] ", aviso$mensaje)
    if (is.null(reconstruido$dataset))
      stop("la sesión no trae una fuente que se pueda recargar",
           call. = FALSE)
    ds <- reconstruido$dataset
    for (filtro in opciones$filtro %||% character(0))
      ds <- aplicar_filtro_cli(ds, filtro)
    return(declarar_escalas_cli(ds, opciones$escala))
  }
  # Sin default a propósito. Un default acá no ahorra tecleo: produce en
  # silencio un análisis sobre el dataset equivocado, y el cuaderno exportado
  # sale citando un CSV que no es el de la pregunta. Mejor negarse.
  clave <- opciones$fuente
  if (is.null(clave) || !nzchar(clave))
    stop("falta --fuente. Elegí una de: ",
         paste(fuentes_disponibles()$clave, collapse = ", "),
         call. = FALSE)
  resultado <- cargar_fuente(clave)
  for (aviso in resultado$avisos)
    message("[aviso] ", aviso$mensaje)
  ds <- nuevo_dataset(NULL, clave, resultado$datos, fuente = clave)
  for (filtro in opciones$filtro %||% character(0))
    ds <- aplicar_filtro_cli(ds, filtro)
  declarar_escalas_cli(ds, opciones$escala)
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

#' Un `--filtro Columna=valor[,valor]` aplicado sobre el dataset.
aplicar_filtro_cli <- function(ds, expresion) {
  if (!grepl("=", expresion, fixed = TRUE))
    stop("un filtro se escribe Columna=valor, no: ", expresion)
  columna <- sub("=.*$", "", expresion)
  valores <- strsplit(sub("^[^=]*=", "", expresion), ",", fixed = TRUE)[[1]]
  pila <- agregar_transformacion(ds$transformaciones, "filtro", columna,
                                 list(valores = valores))
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

# --- Comandos ---------------------------------------------------------------

#' Cada comando recibe (ds, posicionales) y devuelve algo imprimible.
COMANDOS <- list(

  fuentes = function(ds, args) fuentes_disponibles()[, c("clave", "nombre",
                                                         "filas_aprox")],

  datos = function(ds, args) {
    cat(sprintf("%s · %d filas × %d columnas\n", ds$nombre, ds$n, ds$p))
    for (entrada in ds$transformaciones)
      cat("  pila:", describir_transformacion(entrada), "\n")
    utils::head(ds$df, as.integer(args[1] %||% "10"))
  },

  diccionario = function(ds, args)
    ds$diccionario[, c("columna", "escala", "clase", "n_unicos",
                       "faltantes_pct")],

  resumen = function(ds, args) {
    columna <- .exigir(args[1], "resumen <columna>")
    resumir_variable(ds$df[[columna]], .escala_cli(ds, columna))
  },

  frecuencias = function(ds, args)
    resumir_balance(ds$df, .exigir(args[1], "frecuencias <columna>")),

  atipicos = function(ds, args) {
    columna <- .exigir(args[1], "atipicos <columna> [metodo] [umbral]")
    metodo <- .arg(args, 2L, "iqr")
    tabla <- detectar_atipicos(ds$df, columna, metodo,
                              as.numeric(.arg(args, 3L, "1.5")))
    corte <- attr(tabla, "corte")
    cat(sprintf("%s · %d atipicos de %d por %s · corte %s\n", columna,
                attr(tabla, "n_atipicos"), nrow(tabla), metodo,
                paste(round(corte, 4), collapse = " a ")))
    # La tabla del panel trae una fila por observación; acá interesa el
    # subconjunto marcado, que es lo que uno lee del diagrama de caja.
    marcadas <- tabla[tabla$atipico, c("fila", "valor", "distancia")]
    marcadas[order(marcadas$valor), ]
  },

  asociacion = function(ds, args) {
    x <- .exigir(args[1], "asociacion <x> <y>")
    y <- .exigir(args[2], "asociacion <x> <y>")
    medida <- medir_asociacion(ds$df[[x]], ds$df[[y]])
    data.frame(medida = c("n", "covarianza", "pearson", "spearman", "p_valor"),
               valor = c(medida$n, medida$covarianza, medida$pearson,
                         medida$spearman, medida$p_valor),
               unidades = c("filas", paste(x, "x", y), "ninguna", "ninguna",
                            "ninguna"))
  },

  normalidad = function(ds, args) {
    columna <- .exigir(args[1], "normalidad <columna>")
    valores <- as.numeric(ds$df[[columna]])
    juicio <- evaluar_normalidad(valores)
    estimada <- estimar_densidad(valores)
    cat(sprintf("%s · %s · %s\n", columna, juicio$prueba, juicio$veredicto))
    data.frame(medida = c("n", "media", "desviacion", "asimetria", "curtosis",
                          "ancho_banda_h", "estadistico", "p_valor"),
               valor = c(juicio$n, mean(valores, na.rm = TRUE),
                         stats::sd(valores, na.rm = TRUE), juicio$asimetria,
                         juicio$curtosis, estimada$ancho, juicio$estadistico,
                         juicio$p_valor))
  },

  contingencia = function(ds, args) {
    a <- .exigir(args[1], "contingencia <a> <b>")
    b <- .exigir(args[2], "contingencia <a> <b>")
    cruce <- tabla_contingencia(ds$df[[a]], ds$df[[b]], a, b)
    cat(sprintf("chi2 = %.3f · V de Cramer = %.4f\n", cruce$chi2, cruce$cramer))
    cruce$observado
  },

  casillas = function(ds, args)
    data.frame(clave = CASILLAS_INFORME,
               titulo = vapply(CASILLAS_INFORME, titulo_de, "")),

  panel = function(ds, args) tabla_de_panel(ds, .exigir(
    args[1], "panel <clave> [columnas...]"), args[-1]),

  cuaderno = function(ds, args, opciones = list()) {
    seleccion <- seleccion_de_args(ds, args, opciones)
    armar_informe_exploracion(seleccion, ds,
                              texto = opciones$texto %||% .texto_de_sesion(opciones))
  },

  #' La sesión guardada: lo mismo que descarga ⚙ Objetos, desde la consola.
  #' Sirve para dejar preparada la configuración de un taller y abrirla
  #' después con `--sesion` o con `?sesion=` en la app.
  sesion = function(ds, args, opciones = list()) {
    seleccion <- seleccion_de_args(ds, args, opciones)
    sesion_actual(NULL, ds, seleccion, opciones$texto %||% "completo")
  }
)

#' Los paneles pedidos: los de la línea de comandos o, si no hay, los que
#' venían marcados en la sesión.
seleccion_de_args <- function(ds, args, opciones) {
  pedidos <- if (!is.na(args[1]) && nzchar(args[1] %||% ""))
    strsplit(args[1], ",", fixed = TRUE)[[1]] else character(0)
  if (length(pedidos))
    return(lapply(seq_along(pedidos), function(i)
      entrada_de_pedido(pedidos[i], ds, sprintf("p%d", i))))
  if (is.null(opciones$sesion))
    stop("faltan argumentos · uso: cuaderno <clave>[:col+col][,...] ",
         "(o --sesion archivo.json)", call. = FALSE)
  guardada <- seleccion_de_sesion(leer_sesion_cli(opciones$sesion)$fase1)
  seleccion_con_tablas(guardada, ds)
}

.texto_de_sesion <- function(opciones) {
  if (is.null(opciones$sesion)) return("completo")
  leer_sesion_cli(opciones$sesion)$fase1$texto %||% "completo"
}

#' Un `clave:token+token` a la entrada de selección que espera el cuaderno.
#'
#' Los tokens sin `=` son columnas y se reparten en el orden que el generador
#' de esa clave declara (`PARAMS_REQUERIDOS`); los que traen `=` son opciones
#' con nombre, como `marginales=TRUE`. En la app esos parámetros salen de los
#' controles; acá salen de la línea de comandos, y son los mismos.
entrada_de_pedido <- function(pedido, ds, id = "p1") {
  partes <- strsplit(pedido, ":", fixed = TRUE)[[1]]
  clave <- partes[1]
  if (!existe_artefacto(clave))
    stop("clave desconocida: ", clave, ". Ver: Rscript learn/R/lab.R casillas",
         call. = FALSE)
  tokens <- if (length(partes) > 1L)
    strsplit(partes[2], "+", fixed = TRUE)[[1]] else character(0)
  params <- .completar_params(clave, params_de_pedido(clave, tokens), ds)
  if (!params_completos(clave, params))
    message("[aviso] ", clave, " necesita ",
            paste(PARAMS_REQUERIDOS[[clave]], collapse = " + "),
            ": escribilo como ", clave, ":columna")
  list(id = id, clave = clave, titulo = titulo_de(clave),
       cuando = format(Sys.time(), "%H:%M:%S"), params = params,
       tabla = tabla_de_seleccion(clave, params, ds))
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

#' El gráfico de un panel, como tabla.
#'
#' La función que dibuja cada artefacto está declarada en el registro (C9), así
#' que no hace falta un mapa clave -> función acá: se lee de ahí y se llama con
#' las columnas que pase el usuario. `ggplot_build()` es lo que convierte el
#' dibujo en números: devuelve una fila por elemento pintado.
tabla_de_panel <- function(ds, clave, columnas) {
  if (!existe_artefacto(clave))
    stop("clave desconocida: ", clave, ". Ver: Rscript learn/R/lab.R casillas")
  referencia <- artefacto(clave)$grafico
  if (is.na(referencia))
    stop("el artefacto ", clave, " todavia no tiene grafico registrado")
  nombre <- sub("^.*::", "", referencia)
  if (!exists(nombre, mode = "function"))
    stop("la funcion ", nombre, " no esta cargada")
  argumentos <- c(list(ds$df), as.list(columnas))
  grafico <- tryCatch(do.call(nombre, argumentos), error = function(e)
    stop(sprintf("%s(datos, %s) falló: %s\n  Probá con otras columnas.",
                 nombre, paste(columnas, collapse = ", "),
                 conditionMessage(e)), call. = FALSE))
  capas <- ggplot2::ggplot_build(grafico)$data
  cat(sprintf("%s · %s · %d capa(s)\n", clave, nombre, length(capas)))
  # Las columnas de estilo (color, alpha, linetype) no son el resultado: son
  # como se pintó. Se van para que quede la tabla que uno leería del dibujo.
  estilo <- c("colour", "fill", "alpha", "linewidth", "linetype", "shape",
              "size", "weight", "flipped_aes", "PANEL", "group")
  lapply(capas, function(capa) capa[, setdiff(names(capa), estilo),
                                    drop = FALSE])
}

.exigir <- function(valor, uso) {
  if (is.na(valor) || is.null(valor) || !nzchar(valor))
    stop("faltan argumentos · uso: ", uso, call. = FALSE)
  valor
}

.escala_cli <- function(ds, columna) {
  fila <- ds$diccionario$columna == columna
  if (!any(fila)) stop("no existe la columna: ", columna, call. = FALSE)
  ds$diccionario$escala[fila][1]
}

#' Un posicional opcional. `args[i]` da NA cuando no está, y `%||%` solo
#' atrapa NULL: sin esto un `--metodo` omitido llega como NA a la lógica.
.arg <- function(args, i, alterno) {
  if (i > length(args) || is.na(args[i]) || !nzchar(args[i])) alterno else args[i]
}

#' Punto de entrada del CLI.
correr_lab <- function(argumentos = commandArgs(trailingOnly = TRUE)) {
  cargar_sda(con_ui = FALSE)
  partido <- partir_argumentos(argumentos)
  comando <- partido$posicionales[1]
  if (is.na(comando) || !comando %in% names(COMANDOS)) {
    cat("comandos:", paste(names(COMANDOS), collapse = " · "), "\n")
    cat("opciones: --fuente <clave> · --filtro Columna=valor (repetible)",
        "· --sesion archivo.json · --texto completo|breve|ninguno",
        "· --salida archivo\n")
    return(invisible(FALSE))
  }
  # `fuentes` y `casillas` son catálogos: preguntan qué hay, no miran datos.
  # Exigirles --fuente era pedir el dataset para poder preguntar cuál elegir.
  ds <- if (comando %in% c("fuentes", "casillas")) NULL
        else armar_dataset(partido$opciones)
  resultado <- if (comando %in% c("cuaderno", "sesion"))
    COMANDOS[[comando]](ds, partido$posicionales[-1], partido$opciones)
  else COMANDOS[[comando]](ds, partido$posicionales[-1])
  salida <- partido$opciones$salida
  if (identical(comando, "cuaderno") && !is.null(salida)) {
    writeLines(resultado, salida, useBytes = TRUE)
    cat("cuaderno escrito en", salida, "\n")
    return(invisible(TRUE))
  }
  if (identical(comando, "sesion") && !is.null(salida)) {
    exportar_sesion_json(resultado, salida)
    cat("sesión escrita en", salida, "\n")
    return(invisible(TRUE))
  }
  print(resultado)
  invisible(TRUE)
}

if (any(grepl("lab[.]R$", commandArgs(trailingOnly = FALSE)))) correr_lab()
