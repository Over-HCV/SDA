# learn/R/pruebas/verificar_idioma.R
#
# Responsabilidad: hacer cumplir C1 (nuestro código en español ASCII).
#
# Uso:  Rscript learn/R/pruebas/verificar_idioma.R
#
# Revisa SOLO los identificadores que definimos nosotros (lado izquierdo de
# `<-` y nombres de argumentos), nunca los que vienen de una librería. Tres
# reglas, todas duras:
#
#   1. Sin tildes ni ñ:  tamano_muestra, no tamaño_muestra.
#   2. snake_case:       graficar_roc, no graficarRoc.
#   3. Sin raíces inglesas del glosario de abajo.
#
# La lista de raíces es curada a propósito: cazar inglés en general daría
# falsos positivos sin fin. Cazar las veinte palabras que de verdad se cuelan
# alcanza. Si una raíz nueva se cuela dos veces, se añade aquí.

# Raíz inglesa -> lo que debería decir en su lugar.
RAICES_INGLESAS <- c(
  data = "datos", plot = "grafico", chart = "grafico", run = "correr",
  load = "cargar", save = "guardar", build = "construir", check = "verificar",
  get = "obtener", set = "fijar", fit = "ajustar", train = "entrenar",
  score = "puntaje", label = "etiqueta", name = "nombre", value = "valor",
  file = "archivo", path = "ruta", row = "fila", col = "columna",
  width = "ancho", height = "alto", sample = "muestra", seed = "semilla",
  count = "conteo", size = "tamano", split = "particion", model = "modelo",
  output = "salida", input = "entrada", update = "actualizar",
  render = "dibujar", helper = "auxiliar", utils = "utilidades"
)

# Nombres heredados de convenciones del repo o exigidos por una librería.
PERMITIDOS <- c(
  "test_headless", "test_app", "run_headless", "ui", "server", "app",
  "id", "ns", "input", "output", "session"
)

.raiz_idioma <- function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (dir.exists(file.path(d, "learn", "R"))) return(d)
    p <- dirname(d)
    if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
    d <- p
  }
}

#' Identificadores que el archivo DEFINE: asignaciones y nombres de argumento.
identificadores_definidos <- function(ruta) {
  pd <- utils::getParseData(parse(ruta, keep.source = TRUE))
  if (is.null(pd) || !nrow(pd)) return(character(0))

  # Lado izquierdo de una asignacion: el SYMBOL inmediatamente anterior.
  asignaciones <- character(0)
  simbolos <- pd[pd$token %in% c("SYMBOL", "LEFT_ASSIGN", "EQ_ASSIGN"), ]
  simbolos <- simbolos[order(simbolos$line1, simbolos$col1), ]
  if (nrow(simbolos) > 1) {
    izq <- which(simbolos$token %in% c("LEFT_ASSIGN", "EQ_ASSIGN"))
    izq <- izq[izq > 1]
    previos <- simbolos[izq - 1, ]
    asignaciones <- previos$text[previos$token == "SYMBOL"]
  }

  argumentos <- pd$text[pd$token == "SYMBOL_FORMALS"]
  unique(c(asignaciones, argumentos))
}

#' @return data.frame de infracciones (vacío si todo bien)
revisar_archivo <- function(ruta) {
  ids <- identificadores_definidos(ruta)
  ids <- setdiff(ids, PERMITIDOS)
  ids <- ids[!startsWith(ids, ".")]          # internos, no forman API
  ids <- ids[nchar(ids) > 2]                 # i, j, df, pd...
  ids <- ids[ids != toupper(ids)]            # CONSTANTES en mayúsculas

  infracciones <- list()
  agregar <- function(id, regla, sugerencia) {
    infracciones[[length(infracciones) + 1L]] <<-
      data.frame(archivo = ruta, identificador = id, regla = regla,
                 sugerencia = sugerencia, stringsAsFactors = FALSE)
  }

  for (id in ids) {
    if (grepl("[^ -~]", id)) {
      agregar(id, "no-ascii", "quitar tildes y ñ del identificador")
      next
    }
    if (grepl("[a-z][A-Z]", id)) {
      agregar(id, "camelCase", "usar snake_case")
      next
    }
    partes <- strsplit(id, "_", fixed = TRUE)[[1]]
    inglesas <- intersect(partes, names(RAICES_INGLESAS))
    if (length(inglesas)) {
      agregar(id, paste0("ingles: ", paste(inglesas, collapse = ", ")),
              paste(RAICES_INGLESAS[inglesas], collapse = ", "))
    }
  }

  if (!length(infracciones)) return(NULL)
  do.call(rbind, infracciones)
}

verificar_idioma <- function(base = file.path(.raiz_idioma(), "learn")) {
  archivos <- list.files(base, pattern = "[.][Rr]$", recursive = TRUE,
                         full.names = TRUE)
  archivos <- archivos[!grepl("/(docs|[.]build|renv)/", archivos)]
  # Este mismo archivo contiene el glosario inglés; revisarse a sí mismo sería
  # un falso positivo garantizado.
  archivos <- archivos[!endsWith(archivos, "verificar_idioma.R")]

  if (!length(archivos)) {
    cat("[idioma] sin archivos .R todavía\n")
    return(invisible(TRUE))
  }

  resultados <- lapply(archivos, function(a)
    tryCatch(revisar_archivo(a), error = function(e) {
      cat(sprintf("[idioma] no se pudo parsear %s: %s\n", a, conditionMessage(e)))
      NULL
    }))
  malos <- do.call(rbind, Filter(Negate(is.null), resultados))

  cat(sprintf("[idioma] %d archivos revisados\n", length(archivos)))
  if (is.null(malos)) {
    cat("[idioma] OK\n")
    return(invisible(TRUE))
  }

  malos$archivo <- sub(paste0("^", base, "/"), "", malos$archivo)
  for (i in seq_len(nrow(malos)))
    cat(sprintf("  %-34s %-22s %-24s -> %s\n", malos$archivo[i],
                malos$identificador[i], malos$regla[i], malos$sugerencia[i]))
  cat(sprintf("\n[idioma] %d infracción(es). Ver C1 en learn/CONVENCIONES.md\n",
              nrow(malos)))
  invisible(FALSE)
}

# Solo se autoejecuta si es EL script invocado por Rscript, no cuando otro
# archivo lo sourcea para reutilizar sus funciones.
.invocado_directamente <- function(nombre) {
  args <- commandArgs(trailingOnly = FALSE)
  archivo <- sub("^--file=", "", args[grepl("^--file=", args)])
  length(archivo) > 0L && basename(archivo[1]) == nombre
}

if (.invocado_directamente("verificar_idioma.R")) {
  if (!isTRUE(verificar_idioma())) quit(status = 1L)
}
