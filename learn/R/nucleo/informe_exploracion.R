# learn/R/nucleo/informe_exploracion.R
#
# Responsabilidad: convertir la selección de paneles de la fase 1 en un cuaderno
# .Rmd reproducible y autónomo.
#
# A diferencia de armar_informe() (informe.R, corridas de las fases 2-4), acá lo
# que se exporta es la EXPLORACIÓN: qué gráficos se marcaron con la casilla
# "Añadir", con qué parámetros, sobre qué datos y con qué preparación. El
# cuaderno debe abrirse en cualquier R con ggplot2: no depende del código del
# lab. Cada panel entra como una sección con su texto explicativo y un chunk
# que lo redibuja.
#
# Devuelve character() de líneas. Quien escribe el archivo es quien llame.

# Los paneles que ofrecen casilla "Añadir": los de ▣ Análisis más los de las
# subsecciones que el taller necesita citar (fuente, diccionario, calidad,
# balanceo). Vive acá y no en la UI porque es el contrato de qué sabe exportar
# el cuaderno: codigo_artefacto() debe tener un generador para cada una de
# estas claves, y test_headless.R lo comprueba.
CASILLAS_INFORME <- c(
  "f1.fuente.vista_previa", "f1.diccionario.tabla", "f1.calidad.atipicos",
  "f1.balanceo.frecuencias",
  "f1.analisis.histograma", "f1.analisis.densidad", "f1.analisis.boxplot",
  "f1.analisis.boxplot_grupos", "f1.analisis.qq_normal_datos",
  "f1.analisis.dispersion", "f1.analisis.densidad_conjunta",
  "f1.analisis.mosaico", "f1.analisis.matriz_dispersion",
  "f1.analisis.heatmap_correlacion", "f1.analisis.coordenadas_paralelas",
  "f1.analisis.elipsoide", "f1.analisis.qq_mahalanobis")

#' Arma el cuaderno de exploración.
#'
#' @param seleccion lista de entradas {clave, titulo, cuando, params, tabla}
#'   en el orden en que se marcaron las casillas
#' @param dataset el dataset vivo al exportar (nombre, fuente, n, p,
#'   transformaciones), o NULL si se exportó sin datos cargados
#' @return character() de líneas listas para writeLines()
armar_informe_exploracion <- function(seleccion, dataset = NULL) {
  c(
    .encabezado_exploracion(dataset),
    .bloque("```{r configuracion, include=FALSE}",
            "knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)",
            "library(ggplot2)",
            "```"),
    .seccion_datos_exploracion(dataset),
    .seccion_preparacion(dataset),
    unlist(lapply(seleccion, .seccion_artefacto), use.names = FALSE),
    .pie_exploracion(dataset, length(seleccion))
  )
}

.encabezado_exploracion <- function(dataset) .bloque(
  "---",
  'title: "Exploración de datos · SDA Lab"',
  sprintf('subtitle: "%s"',
          if (is.null(dataset)) "sin dataset" else dataset$nombre),
  sprintf('date: "%s"', format(Sys.time(), "%Y-%m-%d %H:%M")),
  "output:",
  "  html_document:",
  "    toc: true",
  "    toc_float: true",
  "---",
  "",
  "Cuaderno generado desde SDA Lab. Cada sección corresponde a un panel marcado",
  "con la casilla **Añadir**: trae su texto explicativo, los parámetros con que",
  "se produjo y el código R que lo redibuja sobre `datos`.")

#' La carga de datos. Dos caminos: la fuente `ori` se recarga desde el CSV
#' original (reproducible de punta a punta); cualquier otra fuente se trae del
#' CSV que el usuario baja de la misma pestaña Informe, con la preparación ya
#' aplicada.
.seccion_datos_exploracion <- function(dataset) {
  if (is.null(dataset)) return(c("# Los datos", "",
    "El cuaderno se exportó sin dataset cargado.", ""))
  meta <- .tabla_md(
    c("Nombre", "Fuente", "Filas", "Columnas"),
    c(dataset$nombre, dataset$fuente, dataset$n, dataset$p))
  if (identical(dataset$fuente, "ori")) return(c("# Los datos", "", meta, "",
    "```{r cargar-datos}",
    '# ORI.csv es la base del Taller 01 (IDEAM). Ponerlo al lado del cuaderno.',
    '# La copia que reparte el curso viene en ISO-8859-1; si la tuya ya está en',
    '# UTF-8 (la de data/ del repo lo está), quitá el fileEncoding.',
    'datos <- read.csv("ORI.csv", sep = ";", dec = ".",',
    '                  fileEncoding = "latin1", stringsAsFactors = FALSE)',
    'names(datos) <- trimws(names(datos))',
    "```", ""))
  c("# Los datos", "", meta, "",
    "```{r cargar-datos}",
    '# Bajá "Datos actuales (CSV)" de la pestaña Informe y ponelo al lado de',
    '# este cuaderno: trae la preparación ya aplicada.',
    'datos <- read.csv("datos-sda-lab.csv", stringsAsFactors = FALSE)',
    "```", "")
}

#' La pila (filtros y transformaciones) traducida a R.
#'
#' Con fuente `ori` los chunks corren de verdad: los datos del cuaderno pasan
#' por exactamente lo mismo que los del lab. Con la otra vía ya viene aplicada
#' en el CSV, así que se muestran `eval = FALSE`: documentan, no re-aplican.
.seccion_preparacion <- function(dataset) {
  if (is.null(dataset) || !length(dataset$transformaciones))
    return(c("# Preparación", "", "Sin filtros ni transformaciones aplicados.", ""))
  evaluar <- identical(dataset$fuente, "ori")
  encabezado <- if (evaluar) "```{r preparacion}" else "```{r preparacion, eval=FALSE}"
  lineas <- unlist(lapply(dataset$transformaciones, codigo_de_transformacion),
                   use.names = FALSE)
  c("# Preparación", "",
    if (!evaluar) paste("Ya aplicadas en el CSV de arriba; se listan para",
                        "documentación:", "") else NULL,
    encabezado, lineas, "```", "")
}

#' Una entrada de la pila, en R autónomo.
codigo_de_transformacion <- function(entrada) {
  if (identical(entrada$tipo, "filtro"))
    return(sprintf("datos <- datos[datos$%s %%in%% c(%s), ]",
                   entrada$columnas[1], .valores_r(entrada$params$valores)))
  lineas <- character(0)
  for (columna in entrada$columnas) {
    lineas <- c(lineas, switch(
      entrada$tipo,
      centrar = sprintf("datos$%s <- datos$%s - mean(datos$%s, na.rm = TRUE)",
                        columna, columna, columna),
      escalar = sprintf("datos$%s <- datos$%s / sd(datos$%s, na.rm = TRUE)",
                        columna, columna, columna),
      estandarizar = c(
        sprintf("datos$%s <- datos$%s - mean(datos$%s, na.rm = TRUE)",
                columna, columna, columna),
        sprintf("datos$%s <- datos$%s / sd(datos$%s, na.rm = TRUE)",
                columna, columna, columna)),
      logaritmo = c(.linea_desplazamiento(columna),
                    sprintf("datos$%s <- log(datos$%s)", columna, columna)),
      raiz = c(.linea_desplazamiento(columna),
               sprintf("datos$%s <- sqrt(datos$%s)", columna, columna)),
      boxcox = c(.linea_desplazamiento(columna),
                 sprintf("lambda <- %s", entrada$params$lambda %||% 0),
                 sprintf("datos$%s <- ifelse(abs(lambda) < 1e-8, log(datos$%s),",
                         columna, columna),
                 sprintf("                          (datos$%s^lambda - 1) / lambda)",
                         columna)),
      dummies = c(sprintf("# (dummies de %s: expandida dentro de SDA Lab; el",
                          columna),
                  "# CSV exportado ya trae las columnas indicadoras)"),
      sprintf("# (tipo desconocido: %s)", entrada$tipo)))
  }
  lineas
}

#' El desplazamiento que hace el lab antes de log/raíz/boxcox cuando hay
#' valores <= 0: reproducirlo acá es lo que hace el chunk equivalente al panel.
.linea_desplazamiento <- function(columna)
  c(sprintf("if (min(datos$%s, na.rm = TRUE) <= 0)", columna),
    sprintf("  datos$%s <- datos$%s - min(datos$%s, na.rm = TRUE) + 1",
            columna, columna, columna))

#' Una sección por panel marcado: título, texto, parámetros y chunk.
.seccion_artefacto <- function(entrada) {
  c(sprintf("## %s", .titulo_con_variables(entrada)),
    sprintf("Panel `%s` · marcado a las %s", entrada$clave, entrada$cuando),
    "",
    .texto_de_artefacto(entrada$clave),
    if (!is.null(entrada$tabla)) c("", "Estado al marcarlo:", "",
                                   .tabla_df_md(entrada$tabla)) else NULL,
    if (length(entrada$params %||% list())) c("", "Parámetros:", "",
                                              .lista_a_tabla(entrada$params)) else NULL,
    "", "```{r}", codigo_artefacto(entrada$clave, entrada$params), "```", "",
    "> Interpretá acá qué muestra el gráfico y qué conclusión sacás. Una",
    "> figura sin lectura no es un resultado: es un adorno.", "")
}

#' El título de la sección, con las variables que la distinguen.
#'
#' Un cuaderno del Taller 01 trae tres "Densidad kernel" y dos "Diagrama de
#' caja": sin la variable en el título, el índice no sirve para navegar y las
#' secciones se confunden entre sí.
.titulo_con_variables <- function(entrada) {
  campos <- c("variable", "columna", "clase", "x", "y", "a", "b", "variables")
  valores <- unlist(entrada$params[intersect(campos, names(entrada$params))],
                    use.names = FALSE)
  if (!length(valores)) return(entrada$titulo)
  sprintf("%s · %s", entrada$titulo, paste(valores, collapse = " vs. "))
}

#' El texto explicativo del panel (textos/…): markdown ya, pero un nivel más
#' abajo.
#'
#' Los textos del lab abren en `##` ("Para qué sirve", "Qué muestra"…) porque
#' allá son el bloque entero. Acá cuelgan del `##` del panel, así que sin
#' rebajarlos el índice del cuaderno los pondría como hermanos del panel y no
#' como sus partes.
.texto_de_artefacto <- function(clave) {
  ruta <- if (existe_artefacto(clave)) artefacto(clave)$texto else NA_character_
  if (is.na(ruta) || !file.exists(ruta_app(ruta)))
    return(paste("(Sin texto explicativo para este panel en el lab.)"))
  .rebajar_titulos(readLines(ruta_app(ruta), warn = FALSE, encoding = "UTF-8"))
}

#' Baja un nivel todos los títulos markdown, salteando los bloques de código:
#' ahí un `#` es un comentario de R y rebajarlo lo rompería.
.rebajar_titulos <- function(lineas) {
  en_codigo <- cumsum(grepl("^\\s*```", lineas)) %% 2L == 1L
  titulo <- grepl("^#{1,5} ", lineas) & !en_codigo
  lineas[titulo] <- paste0("#", lineas[titulo])
  lineas
}

#' data.frame a tabla markdown: para las casillas que guardan una tabla
#' (diccionario, frecuencias) y no un gráfico.
.tabla_df_md <- function(tabla, maximo = 12L) {
  if (is.null(tabla) || !nrow(tabla)) return(character(0))
  tabla <- utils::head(tabla, maximo)
  filas <- vapply(seq_len(nrow(tabla)), function(i)
    paste0("| ", paste(vapply(tabla[i, , drop = FALSE], function(v)
      paste(format(v), collapse = " "), ""), collapse = " | "), " |"), "")
  c(paste0("| ", paste(names(tabla), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(tabla)), collapse = "|"), "|"),
    filas, "")
}

.pie_exploracion <- function(dataset, n_artefactos) {
  c("---", "",
    sprintf("%d paneles · dataset %s · generado en modo %s.",
            n_artefactos, if (is.null(dataset)) "ninguno" else dataset$nombre,
            modo_ejecucion()), "")
}
