# learn/R/nucleo/sesion.R
#
# Responsabilidad: guardar y devolver el ESTADO DE TRABAJO de la fase 1, no
# solo los objetos guardados.
#
# El almacén (nucleo/almacen.R) tiene lo que uno apretó "Guardar": datasets,
# modelos, corridas. Lo que no tenía nombre hasta ahora es la otra mitad, la
# que uno arma cada vez que abre la app y pierde al cerrar la pestaña:
#
#   - qué fuente está cargada y con qué pila de filtros y transformaciones,
#   - qué declaró el diccionario (escala, clase, rol de cada columna),
#   - qué paneles quedaron marcados con "Añadir", con qué parámetros y con qué
#     lectura escrita al lado,
#   - si se balanceó o se particionó, con qué técnica y qué semilla.
#
# Balanceo y partición no se guardan como filas ni como asignación: se guarda
# la receta (técnica + semilla) y se rehace al abrir, igual que la pila.
#
# Eso es una sesión. Guardarla y volver a abrirla es entrar al lab con todo
# puesto: el filtro de mediodía aplicado, Temperatura declarada de intervalo y
# los doce paneles del taller marcados, sin repetir catorce clics.
#
# El archivo es PURO: nada de Shiny acá. La pestaña ⚙ Objetos lo descarga y lo
# sube; lab.R lo lee con `--sesion`; las pruebas lo recorren sin navegador.

VERSION_SESION <- 1L

#' La sesión lista para serializar.
#'
#' @param almacen el almacén de objetos guardados
#' @param dataset el dataset vivo de la fase 1, o NULL
#' @param seleccion los paneles marcados, o list()
#' @param texto nivel de texto elegido para el cuaderno
sesion_actual <- function(almacen = NULL, dataset = NULL, seleccion = list(),
                          texto = "completo") {
  list(
    proyecto = "sda-lab", tipo = "sesion", version = VERSION_SESION,
    exportado = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    modo = modo_ejecucion(),
    fase1 = list(
      fuente = dataset$fuente %||% NA_character_,
      nombre = dataset$nombre %||% NA_character_,
      semilla = dataset$semilla %||% 42L,
      n_crudo = dataset$n_crudo %||% NA_integer_,
      transformaciones = dataset$transformaciones %||% list(),
      balanceo = dataset$balanceo,
      particion = .receta_particion(dataset$particion),
      diccionario = dataset$diccionario,
      # Sin las tablas congeladas: se recalculan al abrirla
      # (seleccion_con_tablas). Guardarlas metía la vista previa y el
      # diccionario enteros dentro del archivo, que pasaba de 5 KB a 45.
      seleccion = lapply(seleccion %||% list(), function(entrada) {
        entrada$tabla <- NULL
        entrada
      }),
      texto = texto),
    almacen = almacen)
}

#' La partición sin su asignación: con la semilla alcanza para rehacerla, y la
#' asignación son tantas cadenas como filas.
.receta_particion <- function(particion) {
  if (is.null(particion)) return(NULL)
  particion$asignacion <- NULL
  particion
}

#' Una sesión leída de disco, venga del formato que venga.
#'
#' Los archivos viejos son el almacén pelado (no tienen `tipo`): se aceptan
#' igual y se devuelven sin fase 1, que es exactamente lo que traían.
#'
#' @return list(almacen, fase1) — `fase1` puede ser NULL
sesion_normalizada <- function(bruto) {
  if (is.null(bruto)) return(list(almacen = NULL, fase1 = NULL))
  if (!identical(bruto$tipo, "sesion"))
    return(list(almacen = bruto, fase1 = NULL))
  list(almacen = bruto$almacen, fase1 = .fase1_normalizada(bruto$fase1))
}

#' fromJSON(simplifyVector = FALSE) devuelve listas donde el RDS devuelve
#' vectores y data.frames. Acá se emparejan las dos formas, una sola vez, para
#' que nadie más tenga que preguntarse de dónde vino el archivo.
.fase1_normalizada <- function(fase1) {
  if (is.null(fase1)) return(NULL)
  fase1$fuente <- .valor_unico(fase1$fuente)
  fase1$nombre <- .valor_unico(fase1$nombre)
  fase1$texto <- .valor_unico(fase1$texto) %||% "completo"
  fase1$semilla <- as.integer(.valor_unico(fase1$semilla) %||% 42L)
  if (is.list(fase1$diccionario) && !is.data.frame(fase1$diccionario))
    fase1$diccionario <- .filas_a_df(fase1$diccionario)
  fase1$transformaciones <- lapply(fase1$transformaciones %||% list(),
                                   .transformacion_normalizada)
  fase1$balanceo <- .bloque_normalizado(fase1$balanceo)
  fase1$particion <- .bloque_normalizado(fase1$particion)
  fase1$seleccion <- lapply(fase1$seleccion %||% list(), .entrada_normalizada)
  fase1
}

# Ojo con el nombre: `.escalar` ya existe en logica/datos/transformacion.R con
# otro significado (dividir por la desviación), y como todo se sourcea en el
# mismo ambiente, el que se cargue último gana. De ahí `.valor_unico`.
.valor_unico <- function(x) {
  if (is.null(x) || !length(x)) return(NULL)
  valor <- unlist(x, use.names = FALSE)[1]
  if (is.na(valor)) NULL else valor
}

# Un bloque de escalares (balanceo, partición): cada campo a su valor, NA y
# listas vacías a NULL. Un bloque vacío es "no se hizo".
.bloque_normalizado <- function(bloque) {
  if (is.null(bloque) || !length(bloque)) return(NULL)
  limpio <- lapply(bloque, .valor_unico)
  limpio <- limpio[!vapply(limpio, is.null, logical(1))]
  if (length(limpio)) limpio else NULL
}

.filas_a_df <- function(filas) {
  if (!length(filas)) return(NULL)
  do.call(rbind, lapply(filas, function(fila)
    as.data.frame(lapply(fila, function(v) .valor_unico(v) %||% NA),
                  stringsAsFactors = FALSE)))
}

.transformacion_normalizada <- function(entrada) {
  entrada$tipo <- .valor_unico(entrada$tipo)
  entrada$columnas <- unlist(entrada$columnas, use.names = FALSE)
  entrada$params <- lapply(entrada$params %||% list(),
                           function(v) unlist(v, use.names = FALSE))
  entrada
}

.entrada_normalizada <- function(entrada) {
  entrada$id <- .valor_unico(entrada$id) %||% "p1"
  entrada$clave <- .valor_unico(entrada$clave)
  entrada$titulo <- .valor_unico(entrada$titulo) %||% titulo_de(entrada$clave)
  entrada$cuando <- .valor_unico(entrada$cuando) %||% ""
  entrada$nota <- .valor_unico(entrada$nota) %||% ""
  entrada$params <- lapply(entrada$params %||% list(),
                           function(v) unlist(v, use.names = FALSE))
  entrada
}

#' El dataset vivo reconstruido desde la sesión.
#'
#' Se RECARGA de la fuente y se le reaplica la pila, en vez de guardar el
#' data.frame: así la sesión pesa kilobytes, viaja entre máquinas y no queda
#' desactualizada si el CSV cambió. La contrapartida es que una fuente subida
#' a mano no se puede recrear sola, y eso se dice en vez de fingir.
#'
#' @return list(dataset, avisos)
dataset_de_sesion <- function(fase1) {
  avisos <- list()
  fuente <- fase1$fuente %||% NA_character_
  if (is.na(fuente) || !nzchar(fuente))
    return(list(dataset = NULL, avisos = list(list(
      severidad = "aviso", mensaje = "la sesión no traía dataset cargado",
      sugerencia = "Cargá una fuente en ① Datos."))))
  if (!fuente %in% fuentes_disponibles()$clave)
    return(list(dataset = NULL, avisos = list(list(
      severidad = "aviso",
      mensaje = sprintf("la fuente '%s' no está en el catálogo", fuente),
      sugerencia = "Volvé a subir el archivo; la pila se puede reaplicar después."))))

  cargada <- cargar_fuente(fuente, semilla = fase1$semilla %||% 42L)
  ds <- nuevo_dataset(NULL, fase1$nombre %||% fuente, cargada$datos,
                      fuente = fuente, semilla = fase1$semilla %||% 42L)
  if (length(fase1$transformaciones)) {
    resultado <- aplicar_transformaciones(ds$df, fase1$transformaciones)
    avisos <- c(avisos, resultado$avisos)
    ds$df <- resultado$datos
    ds$transformaciones <- fase1$transformaciones
    ds$n <- nrow(resultado$datos)
    ds$p <- ncol(resultado$datos)
  }
  # Primero balanceo y después partición: balancear cambia las filas y la
  # app limpia la partición, así que en el orden inverso no pudo haber pasado.
  receta_bal <- fase1$balanceo
  if (!is.null(receta_bal$columna) && receta_bal$columna %in% names(ds$df)) {
    balanceado <- tryCatch(
      balancear(ds$df, receta_bal$columna, receta_bal$metodo %||% "submuestreo",
                as.integer(receta_bal$semilla %||% 42L)),
      error = function(e) NULL)
    if (is.null(balanceado)) {
      avisos <- c(avisos, list(list(
        severidad = "aviso", mensaje = "no se pudo rehacer el balanceo",
        sugerencia = "Volvé a balancear en ① Datos.")))
    } else {
      ds$df <- balanceado$datos
      ds$n <- nrow(balanceado$datos)
      ds$balanceo <- list(metodo = balanceado$metodo,
                          columna = receta_bal$columna,
                          semilla = balanceado$semilla)
    }
  }
  receta_part <- fase1$particion
  if (!is.null(receta_part$tipo)) {
    estrato <- receta_part$estratificar
    if (!is.null(estrato) && !estrato %in% names(ds$df)) estrato <- NULL
    ds$particion <- tryCatch(
      particionar(ds$df, tipo = receta_part$tipo,
                  proporcion = as.numeric(receta_part$proporcion %||% 0.7),
                  k = as.integer(receta_part$k %||% 5L),
                  estratificar = estrato,
                  semilla = as.integer(receta_part$semilla %||% 42L)),
      error = function(e) NULL)
  }
  # El diccionario declarado manda sobre la autodetección: es la mitad de lo
  # que se guarda una sesión.
  ds$diccionario <- rehacer_diccionario(fase1$diccionario, ds$df)
  list(dataset = ds, avisos = c(cargada$avisos, avisos))
}

#' Los paneles marcados, listos para el cuaderno. Se descartan los que apuntan
#' a claves que ya no existen: una sesión vieja no debe romper el arranque.
seleccion_de_sesion <- function(fase1) {
  entradas <- fase1$seleccion %||% list()
  Filter(function(e) !is.null(e$clave) && e$clave %in% CASILLAS_INFORME,
         entradas)
}

#' Las tablas que cada panel congela (diccionario, frecuencias, resumen) no se
#' guardan en el archivo: se recalculan sobre el dataset reconstruido. Así una
#' sesión no arrastra copias de los datos.
seleccion_con_tablas <- function(seleccion, ds) {
  lapply(seleccion, function(entrada) {
    entrada$tabla <- tabla_de_seleccion(entrada$clave, entrada$params, ds)
    entrada
  })
}

#' La tabla congelada de un panel, a partir de sus parámetros. Es la versión
#' sin Shiny de tabla_de_artefacto() (ui/transversal/informe.R), y la que usan
#' lab.R y la restauración de sesiones.
tabla_de_seleccion <- function(clave, params, ds) {
  if (is.null(ds)) return(NULL)
  switch(clave,
    "f1.fuente.vista_previa" = utils::head(ds$df, 10),
    "f1.diccionario.tabla" =
      ds$diccionario[, c("columna", "escala", "clase", "rol")],
    "f1.balanceo.frecuencias" = if (!is.null(params$clase))
      resumir_balance(ds$df, params$clase) else NULL,
    "f1.analisis.resumen" = if (!is.null(params$variable))
      resumir_variable(ds$df[[params$variable]],
                       params$escala %||% "razon")[, c("estadistico", "mostrado")]
      else NULL,
    NULL)
}
