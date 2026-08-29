# learn/R/run_headless.R
#
# Responsabilidad: correr un método completo sin Shiny y dejar el resultado en
# disco con el contrato S2 de libs/sdd.md (JSON + CSV + PNG + run_log.csv).
#
# Por qué existe, y no es un extra: la regla de las tres partes (C11) dice que
# todo hiperparámetro vive a la vez en la función pura, en `correr()` y en la
# UI. Sin este archivo la regla no se puede comprobar, y app y batch divergen
# en silencio — que es exactamente el bug que nadie ve hasta que un resultado
# no se puede reproducir.
#
# Uso desde la raíz del repo:
#
#   Rscript -e 'source("learn/R/run_headless.R"); correr("acp-twins")'
#   Rscript -e 'source("learn/R/run_headless.R");
#               correr("acp-cov", hiper = list(matriz = "covarianza"))'
#
# No sabe nada del ACP en particular: recorre el registro. Cuando entre
# k-medias, este archivo no se toca.

# Como todo en este repo, se invoca desde la raíz (ver AGENT.md). El segundo
# candidato cubre el caso de sourcearlo estando dentro de learn/.
local({
  candidatos <- c("learn/R/cargar.R", "R/cargar.R")
  ruta <- candidatos[file.exists(candidatos)]
  if (!length(ruta)) stop("corre esto desde la raiz del repo (ver AGENT.md)")
  source(ruta[1])
})

#' Ajusta un método y escribe su corrida.
#'
#' @param escenario nombre del archivo de salida
#' @param metodo    clave del catálogo; debe estar `activo`
#' @param fuente    clave de fuentes_disponibles(), o un data.frame
#' @param columnas  columnas que entran al modelo; NULL = las numéricas
#' @param hiper     lista con nombre que pisa `hiper_por_defecto(metodo)`. Los
#'   nombres son los del registro: así el batch no puede inventar un parámetro
#'   que la UI no ofrece, ni al revés
#' @param optimizador nombre del optimizador; NULL = el primero que declare
#' @param out_dir   relativo a la raíz del repo
#' @return la corrida (invisible)
correr <- function(escenario, metodo = "acp", fuente = "twins", columnas = NULL,
                   hiper = list(), optimizador = NULL, tol = 1e-8,
                   maxit = 500L, semilla = 42L, registrar_traza = TRUE,
                   out_dir = "learn/outputs") {
  cargar_sda(con_ui = FALSE)

  m <- metodo(metodo)
  if (m$estado != "activo")
    stop(sprintf("'%s' esta '%s': todavia no se puede ajustar", metodo, m$estado))

  dataset <- .dataset_para_correr(fuente, semilla)
  parametros <- utils::modifyList(hiper_por_defecto(metodo), as.list(hiper))
  optimizador <- optimizador %||% (m$optimizador$metodos %||% NA_character_)[1]

  modelo <- nuevo_modelo("m1", sprintf("%s (headless)", m$nombre), metodo,
                         spec = columnas, hiper = parametros)
  receta <- nueva_receta("r1", "headless", optimizador = optimizador,
                         control = list(tol = tol, maxit = maxit),
                         semilla = semilla)
  avisos <- validar_compatibilidad(dataset, modelo, receta)

  inicio <- Sys.time()
  ajuste <- do.call(m$ajustar, c(
    list(datos = dataset$df, columnas = columnas),
    parametros,
    list(optimizador = optimizador, tol = tol, maxit = maxit,
         semilla = semilla, registrar_traza = registrar_traza)))
  duracion <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))

  corrida <- nueva_corrida("c1", dataset$id, modelo$id, receta$id, metodo,
                           ajuste = ajuste, traza = ajuste$traza,
                           metricas = metricas_de_corrida(ajuste),
                           params = .params_de_corrida(parametros, optimizador,
                                                       tol, maxit, semilla,
                                                       dataset, columnas),
                           duracion = duracion, estado = "listo")

  escribir_salida(
    proyecto = "sda-lab", escenario = escenario,
    params = corrida$params, metricas = corrida$metricas,
    plot_obj = graficar_scree(varianza_explicada(ajuste), k = ajuste$k),
    datos_df = varianza_explicada(ajuste),
    notas = .notas_de_corrida(m, dataset, avisos),
    out_dir = out_dir)

  cat(sprintf("[correr] %s · %s · %d de %d componentes · %.1f%% explicado · %.2fs\n",
              escenario, metodo, ajuste$k, ajuste$p,
              100 * sum(ajuste$varianza_explicada[seq_len(ajuste$k)]), duracion))
  invisible(corrida)
}

# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

.dataset_para_correr <- function(fuente, semilla) {
  if (is.data.frame(fuente))
    return(nuevo_dataset("d1", "datos dados", fuente, fuente = "memoria",
                         semilla = semilla))
  cargada <- cargar_fuente(fuente, semilla = semilla)
  nuevo_dataset("d1", fuente, cargada$datos, fuente = fuente, semilla = semilla)
}

# Todo lo que hace falta para repetir la corrida exactamente: los hiper del
# registro, el control del optimizador, la semilla (C13) y qué datos entraron.
.params_de_corrida <- function(parametros, optimizador, tol, maxit, semilla,
                               dataset, columnas) {
  c(parametros,
    list(optimizador = optimizador, tol = tol, maxit = maxit, semilla = semilla,
         fuente = dataset$fuente,
         columnas = paste(columnas %||% columnas_numericas(dataset),
                          collapse = ",")))
}

.notas_de_corrida <- function(m, dataset, avisos) {
  graves <- Filter(function(a) a$severidad != "ok", avisos)
  resumen <- if (!length(graves)) "composicion sin avisos"
             else paste(vapply(graves, `[[`, "", "mensaje"), collapse = " | ")
  sprintf("%s sobre %s (n = %d) · %s", m$nombre, dataset$nombre, dataset$n,
          resumen)
}

if (identical(environment(), globalenv()) &&
    any(grepl("run_headless[.]R$", commandArgs(trailingOnly = FALSE)))) {
  correr("acp-twins")
}
