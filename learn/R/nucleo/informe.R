# learn/R/nucleo/informe.R
#
# Responsabilidad: convertir una corrida en un cuaderno .Rmd reproducible.
#
# Por qué esto no es un extra: la guía del curso (guide-eda-26A.md §15) exige
# cuaderno RMD + diapositivas PDF + video, y puntúa código R legible (30 %) y
# visualización pedagógica. Un exportador convierte cualquier exploración
# hecha en la app en la mayor parte de un entregable evaluable.
#
# Devuelve character() de líneas. Quien escribe el archivo es exportar_rmd().

.bloque <- function(...) c(..., "")

.tabla_md <- function(nombres, valores) {
  if (!length(nombres)) return(character(0))
  c("| Campo | Valor |", "|---|---|",
    sprintf("| %s | %s |", nombres, valores), "")
}

.lista_a_tabla <- function(lista) {
  if (is.null(lista) || !length(lista)) return(character(0))
  valores <- vapply(lista, function(v) paste(format(v, digits = 6), collapse = ", "), "")
  .tabla_md(names(lista), valores)
}

#' Arma el cuaderno.
#' @return character() de líneas listas para writeLines()
armar_informe <- function(corrida, dataset = NULL, modelo = NULL, receta = NULL) {
  m <- if (existe_metodo(corrida$metodo)) metodo(corrida$metodo) else NULL
  titulo <- if (is.null(m)) corrida$metodo else m$nombre

  c(
    .encabezado(titulo),
    .bloque("```{r configuracion, include=FALSE}",
            "knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)",
            "```"),
    .seccion_metodo(m),
    .seccion_datos(dataset),
    .seccion_modelo(modelo),
    .seccion_ajuste(receta),
    .seccion_resultados(corrida),
    .seccion_reproducir(corrida),
    .seccion_pie(corrida, m)
  )
}

.encabezado <- function(titulo) .bloque(
  "---",
  sprintf('title: "%s"', titulo),
  'subtitle: "Análisis Estadístico de Datos · generado con SDA Lab"',
  sprintf('date: "%s"', format(Sys.Date(), "%Y-%m-%d")),
  "output:",
  "  html_document:",
  "    toc: true",
  "    toc_float: true",
  "---"
)

.seccion_metodo <- function(m) {
  if (is.null(m)) return(character(0))
  c("# El método", "",
    sprintf("**%s** · objetivo: %s · sesión %s del curso.",
            m$nombre, m$objetivo, m$sesion), "",
    if (!is.na(m$nodo))
      sprintf("Ancla teórica: `notes/tree.md → %s`", m$nodo) else NULL, "",
    "> Completar aquí, con tus palabras, qué hace el método y por qué",
    "> es el adecuado para esta pregunta. Es el criterio R1 de la rúbrica.", "")
}

.seccion_datos <- function(dataset) {
  if (is.null(dataset)) return(character(0))
  transformaciones <- vapply(dataset$transformaciones,
                             function(t) t$tipo %||% "", "")
  c("# Los datos", "",
    .tabla_md(c("Nombre", "Fuente", "Observaciones", "Variables", "Semilla"),
              c(dataset$nombre, dataset$fuente, dataset$n, dataset$p,
                dataset$semilla)),
    if (length(transformaciones))
      c("Transformaciones aplicadas, en orden:", "",
        paste0(seq_along(transformaciones), ". `", transformaciones, "`"), "")
    else c("Sin transformaciones.", ""),
    "## Diccionario de variables", "",
    .diccionario_md(dataset$diccionario))
}

.diccionario_md <- function(diccionario) {
  if (is.null(diccionario) || !nrow(diccionario)) return(character(0))
  c("| Columna | Escala | Clase | Rol | % faltantes |",
    "|---|---|---|---|---|",
    sprintf("| `%s` | %s | %s | %s | %s |",
            diccionario$columna, diccionario$escala, diccionario$clase,
            diccionario$rol, diccionario$faltantes_pct), "")
}

.seccion_modelo <- function(modelo) {
  if (is.null(modelo)) return(character(0))
  c("# El modelo", "",
    if (!is.null(modelo$spec))
      c("Especificación:", "", "```r", paste(deparse(modelo$spec), collapse = " "),
        "```", "") else NULL,
    if (length(modelo$hiper)) c("Hiperparámetros:", "",
                                .lista_a_tabla(modelo$hiper)) else NULL)
}

.seccion_ajuste <- function(receta) {
  if (is.null(receta)) return(character(0))
  c("# El ajuste", "",
    .tabla_md(c("Optimizador", "Semilla"),
              c(ifelse(is.na(receta$optimizador), "por defecto", receta$optimizador),
                receta$semilla)),
    if (length(receta$control)) c("Control:", "", .lista_a_tabla(receta$control))
    else NULL)
}

.seccion_resultados <- function(corrida) {
  c("# Resultados", "",
    .lista_a_tabla(corrida$metricas),
    "> Interpretá aquí los números de arriba. Un resultado sin lectura no",
    "> es un resultado: es una salida de consola.", "")
}

.seccion_reproducir <- function(corrida) {
  parametros <- if (length(corrida$params))
    paste(sprintf("%s = %s", names(corrida$params),
                  vapply(corrida$params, function(v) format(v, digits = 6), "")),
          collapse = ", ") else ""
  c("# Reproducir", "",
    "Desde la raíz del repo:", "",
    "```bash",
    'Rscript -e \'source("learn/R/run_headless.R");',
    sprintf('            correr("%s"%s)\'', corrida$id,
            if (nzchar(parametros)) paste0(", ", parametros) else ""),
    "```", "")
}

.seccion_pie <- function(corrida, m) {
  c("---", "",
    sprintf("Corrida `%s` · %s · modo %s.", corrida$id, corrida$creado,
            modo_ejecucion()),
    if (!is.null(m)) sprintf("Ficha del método: `learn/%s`.", m$ficha) else NULL,
    "")
}
