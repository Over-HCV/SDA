# learn/R/nucleo/exportar.R
#
# Responsabilidad: sacar cosas de la app hacia archivos.
#
# Seis formatos, cada uno con un motivo distinto:
#   json  canónico. Contrato S2 de libs/sdd.md. Es lo que lee un agente.
#   csv   tablas de resultados y de métricas, para abrirlas en otra parte.
#   png   el gráfico tal como se ve.
#   rds   la sesión con los objetos R vivos, sin pérdida.
#   rmd   informe reproducible — el 60 % del entregable del curso.
#   md    el bloque de contexto para pegar en un chat.
#
# El informe .Rmd se arma en informe.R; aquí solo se escribe el archivo.
#
# En wasm no hay disco persistente: estas funciones escriben en tempdir() y
# quien las llama entrega el archivo con downloadHandler().

.asegurar_dir <- function(ruta) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  ruta
}

#' Estructura serializable de una corrida, conforme al contrato S2.
#' Los campos extra (dataset/modelo/receta, artefactos) son nuestros y son
#' justamente los que hacen rastreable el resultado.
corrida_a_lista <- function(corrida, dataset = NULL, modelo = NULL,
                            receta = NULL, notas = "") {
  m <- if (existe_metodo(corrida$metodo)) metodo(corrida$metodo) else NULL
  list(
    timestamp = corrida$creado,
    proyecto  = "sda-lab",
    escenario = corrida$id,
    metodo    = corrida$metodo,
    composicion = list(dataset = corrida$dataset_id, modelo = corrida$modelo_id,
                       receta = corrida$receta_id),
    datos = if (is.null(dataset)) NULL else list(
      nombre = dataset$nombre, fuente = dataset$fuente,
      n = dataset$n, p = dataset$p, semilla = dataset$semilla,
      transformaciones = vapply(dataset$transformaciones,
                                function(t) t$tipo %||% "", "")),
    params    = corrida$params,
    metricas  = corrida$metricas,
    artefactos = if (is.null(m)) character(0) else m$artefactos,
    archivos  = list(plot = paste0(corrida$id, ".png"),
                     datos = paste0(corrida$id, ".csv")),
    duracion_s = corrida$duracion,
    estado    = corrida$estado,
    modo      = modo_ejecucion(),
    notas     = notas
  )
}

#' @param objeto lista o corrida. Si es una corrida, se normaliza antes.
exportar_json <- function(objeto, ruta, ...) {
  if (identical(objeto$tipo, "corrida")) objeto <- corrida_a_lista(objeto, ...)
  jsonlite::write_json(objeto, .asegurar_dir(ruta), auto_unbox = TRUE,
                       pretty = TRUE, digits = 8, null = "null", na = "null")
  invisible(ruta)
}

exportar_csv <- function(df, ruta) {
  stopifnot(is.data.frame(df))
  utils::write.csv(df, .asegurar_dir(ruta), row.names = FALSE,
                   fileEncoding = "UTF-8")
  invisible(ruta)
}

#' @param grafico objeto ggplot
exportar_png <- function(grafico, ruta, ancho = 9, alto = 5.5, dpi = 144) {
  ggplot2::ggsave(.asegurar_dir(ruta), plot = grafico, width = ancho,
                  height = alto, dpi = dpi, bg = "white")
  invisible(ruta)
}

exportar_rds <- function(objeto, ruta) {
  saveRDS(objeto, .asegurar_dir(ruta))
  invisible(ruta)
}

#' Bloque de contexto de un artefacto, como archivo .md.
exportar_contexto <- function(clave, ruta, ...) {
  writeLines(contexto_de(clave, ...), .asegurar_dir(ruta), useBytes = TRUE)
  invisible(ruta)
}

#' Informe reproducible. El contenido lo arma armar_informe() en informe.R.
exportar_rmd <- function(corrida, ruta, dataset = NULL, modelo = NULL,
                         receta = NULL) {
  writeLines(armar_informe(corrida, dataset, modelo, receta),
             .asegurar_dir(ruta), useBytes = TRUE)
  invisible(ruta)
}

# ---------------------------------------------------------------------------
# Sesión completa
#
# Dos formatos por una razón concreta: JSON viaja entre máquinas y lo puede
# leer un agente, pero pierde fidelidad (factores, atributos, objetos de
# ajuste). RDS conserva todo pero solo lo abre R. Se ofrecen los dos y se
# explica la diferencia en la UI.
# ---------------------------------------------------------------------------

exportar_sesion_rds <- function(almacen, ruta) exportar_rds(almacen, ruta)

importar_sesion_rds <- function(ruta) {
  if (!file.exists(ruta)) stop("no existe el archivo: ", ruta)
  readRDS(ruta)
}

#' Sesión a JSON. Los objetos de ajuste (`ajuste`) no se serializan: son
#' punteros a estructuras de R que no sobreviven el viaje. Se guarda todo lo
#' necesario para RE-correr la corrida, que es lo que importa.
exportar_sesion_json <- function(almacen, ruta) {
  liviano <- almacen
  liviano$corridas <- lapply(almacen$corridas, function(cor) {
    cor$ajuste <- NULL
    cor
  })
  liviano$datasets <- lapply(almacen$datasets, function(ds) {
    ds$df <- utils::head(ds$df, 200)     # muestra, no el dataset entero
    ds$truncado <- TRUE
    ds
  })
  liviano$exportado <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  liviano$modo <- modo_ejecucion()
  jsonlite::write_json(liviano, .asegurar_dir(ruta), auto_unbox = TRUE,
                       pretty = TRUE, digits = 8, na = "null")
  invisible(ruta)
}

importar_sesion_json <- function(ruta) {
  if (!file.exists(ruta)) stop("no existe el archivo: ", ruta)
  jsonlite::fromJSON(ruta, simplifyVector = FALSE)
}

#' Nombre de archivo sugerido, con marca de tiempo para no pisar descargas.
nombre_descarga <- function(base, extension) {
  sprintf("sda-%s-%s.%s", base, format(Sys.time(), "%Y%m%d-%H%M%S"), extension)
}
