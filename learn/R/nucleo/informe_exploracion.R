# learn/R/nucleo/informe_exploracion.R
#
# Responsabilidad: convertir la selección de paneles de la fase 1 en un cuaderno
# .Rmd reproducible y autónomo.
#
# A diferencia de armar_informe() (informe.R, corridas de las fases 2-4), acá lo
# que se exporta es la EXPLORACIÓN: qué gráficos se marcaron con la casilla
# "Añadir", con qué parámetros, sobre qué datos y con qué preparación. Cada
# panel entra como una sección con su texto explicativo, su chunk y el renglón
# de la lectura.
#
# Devuelve character() de líneas. Quien escribe el archivo es quien llame.

# Los paneles que ofrecen casilla "Añadir": los de ▣ Análisis más los de las
# subsecciones que el taller necesita citar (fuente, diccionario, calidad,
# balanceo). Vive acá y no en la UI porque es el contrato de qué sabe exportar
# el cuaderno: codigo_artefacto() debe tener un generador para cada una de
# estas claves, y test_informe.R lo comprueba.
CASILLAS_INFORME <- c(
  "f1.fuente.vista_previa", "f1.filtro.filas", "f1.diccionario.tabla",
  "f1.calidad.atipicos",
  "f1.balanceo.frecuencias",
  "f1.analisis.histograma", "f1.analisis.densidad", "f1.analisis.boxplot",
  "f1.analisis.resumen",
  "f1.analisis.boxplot_grupos", "f1.analisis.qq_normal_datos",
  "f1.analisis.dispersion", "f1.analisis.densidad_conjunta",
  "f1.analisis.mosaico", "f1.analisis.matriz_dispersion",
  "f1.analisis.heatmap_correlacion", "f1.analisis.coordenadas_paralelas",
  "f1.analisis.elipsoide", "f1.analisis.qq_mahalanobis")

# Cuánto texto explicativo del lab viaja al cuaderno. El taller pide ser
# conciso y lo puntúa, así que esto es una decisión de quien entrega, no una
# constante: `completo` es el material de estudio, `breve` deja solo qué
# muestra y cuándo engaña, `ninguno` entrega el cuaderno pelado.
NIVELES_TEXTO <- c("completo", "breve", "ninguno")

# Las secciones del texto de un panel que sobreviven en modo `breve`.
SECCIONES_BREVES <- c("Qué muestra", "Cuándo engaña")

#' Mueve una entrada de la selección un lugar arriba (-1) o abajo (+1).
#'
#' El orden de la selección es el del cuaderno. Sin esto, un panel olvidado
#' que debía abrir el informe obligaba a vaciar y volver a marcar todo.
#' Fuera de rango o con un id que no está, la selección vuelve tal cual.
mover_entrada <- function(entradas, id, direccion) {
  ids <- vapply(entradas, function(e) e$id %||% "", "")
  i <- match(id, ids)
  j <- i + direccion
  if (is.na(i) || is.na(j) || j < 1L || j > length(entradas)) return(entradas)
  entradas[c(i, j)] <- entradas[c(j, i)]
  entradas
}

#' Arma el cuaderno de exploración.
#'
#' @param seleccion lista de entradas {clave, titulo, cuando, params, tabla,
#'   nota} en el orden de la pestaña Informe (se marcan en orden y ahí se
#'   reordenan)
#' @param dataset el dataset vivo al exportar (nombre, fuente, n, p, n_crudo,
#'   transformaciones), o NULL si se exportó sin datos cargados
#' @param texto uno de NIVELES_TEXTO
#' @return character() de líneas listas para writeLines()
armar_informe_exploracion <- function(seleccion, dataset = NULL,
                                      texto = "completo") {
  texto <- match.arg(texto, NIVELES_TEXTO)
  # El texto de un panel se escribe UNA vez: un cuaderno del Taller 01 trae
  # tres densidades kernel, y repetir sus cuarenta renglones tres veces es
  # justo lo que el enunciado castiga.
  explicadas <- character(0)
  secciones <- unlist(lapply(seleccion, function(entrada) {
    repetida <- entrada$clave %in% explicadas
    explicadas <<- c(explicadas, entrada$clave)
    .seccion_artefacto(entrada, if (repetida) "repetido" else texto)
  }), use.names = FALSE)

  c(
    .encabezado_exploracion(dataset),
    .seccion_configuracion(seleccion),
    .seccion_datos_exploracion(dataset),
    .seccion_preparacion(dataset),
    if (length(seleccion)) c("# Análisis", "") else NULL,
    secciones,
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
  "    number_sections: true",
  "---",
  "",
  "Cuaderno generado desde SDA Lab. Cada sección corresponde a un panel marcado",
  "con la casilla **Añadir**: trae su texto explicativo, los parámetros con que",
  "se produjo y el código R que lo redibuja sobre `datos`.")

#' El chunk de arranque, con las librerías que el cuaderno de verdad usa.
#'
#' No se declaran todas las del taller por si acaso: un `library()` de un
#' paquete que no está instalado detiene el knit en la primera línea.
.seccion_configuracion <- function(seleccion) {
  paquetes <- .paquetes_de(seleccion)
  .bloque("```{r configuracion, include=FALSE}",
          "knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)",
          sprintf("# install.packages(c(%s))",
                  paste(sprintf('"%s"', paquetes), collapse = ", ")),
          sprintf("library(%s)", paquetes),
          "```")
}

#' Qué paquetes necesitan los paneles marcados.
.paquetes_de <- function(seleccion) {
  hay <- function(condicion)
    length(seleccion) > 0L && any(vapply(seleccion, condicion, logical(1)))
  c("ggplot2",
    if (hay(function(e) identical(e$clave, "f1.analisis.dispersion") &&
            isTRUE(e$params$marginales))) "ggExtra" else NULL)
}

#' La carga de datos. Dos caminos: la fuente `ori` se recarga desde el CSV
#' original (reproducible de punta a punta); cualquier otra fuente se trae del
#' CSV que el usuario baja de la misma pestaña Informe, con la preparación ya
#' aplicada.
.seccion_datos_exploracion <- function(dataset) {
  if (is.null(dataset)) return(c("# Los datos", "",
    "El cuaderno se exportó sin dataset cargado.", ""))
  meta <- .meta_dataset(dataset)
  if (identical(dataset$fuente, "ori")) return(c("# Los datos", "", meta, "",
    '```{r cargar-datos}',
    '# ORI.csv es la base del Taller 01 (IDEAM), publicada en Kaggle como',
    '# overhcv/ori-dataset. Se baja de ahí; sin internet se busca una copia',
    '# local en los lugares habituales, en orden.',
    'url_ori <- "https://www.kaggle.com/api/v1/datasets/download/overhcv/ori-dataset"',
    'zip_ori <- file.path(tempdir(), "ori-dataset.zip")',
    'ruta <- tryCatch({',
    '  download.file(url_ori, zip_ori, mode = "wb", quiet = TRUE)',
    '  unzip(zip_ori, files = "ORI.csv", exdir = tempdir())',
    '}, error = function(e) {',
    '  message("Sin acceso a Kaggle, se usa la copia local: ", conditionMessage(e))',
    '  Filter(file.exists, c("ORI.csv", "data/ORI.csv",',
    '                        "../../../data/ORI.csv"))[1]',
    '})',
    '# La copia que reparte el curso viene en ISO-8859-1 y la de data/ del repo',
    '# en UTF-8. Se detecta en vez de suponer: suponer es lo que rompe las',
    '# tildes de los municipios (ACACÍAS -> ACACÃAS).',
    'codificacion <- if (all(validUTF8(readLines(ruta, warn = FALSE,',
    '                                            encoding = "bytes"))))',
    '  "UTF-8" else "latin1"',
    'datos <- read.csv(ruta, sep = ";", dec = ".", fileEncoding = codificacion,',
    '                  stringsAsFactors = FALSE)',
    'names(datos) <- trimws(names(datos))   # el encabezado trae "Pronostico "',
    'filas_al_cargar <- nrow(datos)         # antes de filtrar: lo usa el panel del filtro',
    'cat("Al cargar:", nrow(datos), "filas x", ncol(datos), "columnas\\n")',
    "```", ""))
  c("# Los datos", "", meta, "",
    "```{r cargar-datos}",
    '# Bajá "Datos actuales (CSV)" de la pestaña Informe y ponelo al lado de',
    '# este cuaderno: trae la preparación ya aplicada.',
    'datos <- read.csv("datos-sda-lab.csv", stringsAsFactors = FALSE)',
    '# Este CSV ya viene filtrado: las filas del archivo original se anotan',
    '# tal como estaban al exportar.',
    sprintf('filas_al_cargar <- %dL', as.integer(dataset$n_crudo %||% dataset$n)),
    'cat("Al cargar:", nrow(datos), "filas x", ncol(datos), "columnas\\n")',
    "```", "")
}

#' La ficha del dataset. Las filas de "al cargar" solo aparecen si la
#' preparación cambió el tamaño: si no, serían la misma cifra dos veces.
.meta_dataset <- function(dataset) {
  n_crudo <- dataset$n_crudo %||% dataset$n
  p_crudo <- dataset$p_crudo %||% dataset$p
  campos <- c("Nombre", "Fuente")
  valores <- c(dataset$nombre, dataset$fuente)
  if (!identical(as.integer(n_crudo), as.integer(dataset$n)) ||
      !identical(as.integer(p_crudo), as.integer(dataset$p))) {
    campos <- c(campos, "Filas al cargar", "Columnas al cargar")
    valores <- c(valores, n_crudo, p_crudo)
  }
  .tabla_md(c(campos, "Filas ahora", "Columnas ahora"),
            c(valores, dataset$n, dataset$p))
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
    encabezado, lineas,
    if (evaluar)
      'cat("Después de la preparación:", nrow(datos), "filas\\n")' else NULL,
    "```", "")
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
.seccion_artefacto <- function(entrada, texto = "completo") {
  c(sprintf("## %s", .titulo_con_variables(entrada)),
    sprintf("Panel `%s` · marcado a las %s", entrada$clave, entrada$cuando),
    "",
    .texto_de_artefacto(entrada$clave, texto, entrada$titulo),
    if (.lleva_tabla(entrada)) c("", "Estado al marcarlo:", "",
                                 .tabla_df_md(entrada$tabla)) else NULL,
    if (length(entrada$params %||% list())) c("", "Parámetros:", "",
                                              .lista_a_tabla(entrada$params)) else NULL,
    "", "```{r}",
    codigo_artefacto(entrada$clave, entrada$params, entrada$tabla), "```", "",
    .lectura(entrada))
}

#' El diccionario viaja DENTRO del chunk (lo imprime el código, que lo declara
#' como data.frame): repetirlo además como tabla markdown son dieciocho filas
#' dos veces. Las demás tablas son estado que el código no reconstruye.
.lleva_tabla <- function(entrada)
  !is.null(entrada$tabla) && !identical(entrada$clave, "f1.diccionario.tabla")

#' La lectura del panel. Si quien exporta la escribió en la pestaña Informe,
#' esa es la que va; si no, queda el recordatorio de que falta.
.lectura <- function(entrada) {
  nota <- trimws(entrada$nota %||% "")
  if (!nzchar(nota))
    return(c("> Interpretá acá qué muestra el gráfico y qué conclusión sacás. Una",
             "> figura sin lectura no es un resultado: es un adorno.", ""))
  c("**Lectura.**", "", strsplit(nota, "\n", fixed = TRUE)[[1]], "")
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
.texto_de_artefacto <- function(clave, nivel = "completo", titulo = clave) {
  if (identical(nivel, "ninguno")) return(character(0))
  if (identical(nivel, "repetido"))
    return(sprintf("El texto de este panel está en la primera sección «%s».",
                   titulo))
  ruta <- if (existe_artefacto(clave)) artefacto(clave)$texto else NA_character_
  if (is.na(ruta) || !file.exists(ruta_app(ruta)))
    return(paste("(Sin texto explicativo para este panel en el lab.)"))
  lineas <- readLines(ruta_app(ruta), warn = FALSE, encoding = "UTF-8")
  if (identical(nivel, "breve")) lineas <- .recortar_texto(lineas)
  .rebajar_titulos(lineas)
}

#' Se queda con las secciones de SECCIONES_BREVES y tira el resto.
#'
#' Los `#` dentro de un bloque de código son comentarios de R, no títulos: si
#' se los toma por títulos, el recorte parte el bloque a la mitad.
.recortar_texto <- function(lineas) {
  en_codigo <- cumsum(grepl("^\\s*```", lineas)) %% 2L == 1L
  es_titulo <- grepl("^#{1,5} ", lineas) & !en_codigo
  if (!any(es_titulo)) return(lineas)
  titulo_actual <- cumsum(es_titulo)
  nombres <- trimws(sub("^#+ ", "", lineas[es_titulo]))
  se_queda <- c(TRUE, nombres %in% SECCIONES_BREVES)   # 0 = antes del primero
  lineas[se_queda[titulo_actual + 1L]]
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
#'
#' Sin tope por defecto. Truncar en silencio a doce filas dejaba fuera seis
#' columnas del diccionario justo en la pregunta que las pide todas; cuando se
#' trunca, ahora se dice.
.tabla_df_md <- function(tabla, maximo = NULL) {
  if (is.null(tabla) || !nrow(tabla)) return(character(0))
  sobrantes <- if (!is.null(maximo) && nrow(tabla) > maximo)
    nrow(tabla) - maximo else 0L
  if (sobrantes) tabla <- utils::head(tabla, maximo)
  filas <- vapply(seq_len(nrow(tabla)), function(i)
    paste0("| ", paste(vapply(tabla[i, , drop = FALSE], function(v)
      paste(format(v), collapse = " "), ""), collapse = " | "), " |"), "")
  c(paste0("| ", paste(names(tabla), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(tabla)), collapse = "|"), "|"),
    filas,
    if (sobrantes) "" else NULL,
    if (sobrantes) sprintf("… y %d filas más.", sobrantes) else NULL,
    "")
}

.pie_exploracion <- function(dataset, n_artefactos) {
  c("---", "",
    sprintf("%d paneles · dataset %s · generado en modo %s.",
            n_artefactos, if (is.null(dataset)) "ninguno" else dataset$nombre,
            modo_ejecucion()), "")
}
