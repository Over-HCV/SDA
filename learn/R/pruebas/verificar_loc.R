# learn/R/pruebas/verificar_loc.R
#
# Responsabilidad: hacer cumplir C2 (techo de 300 LOC por archivo).
#
# Uso:  Rscript learn/R/pruebas/verificar_loc.R
# Sale con 1 si algún archivo pasa el techo. Avisa (sin fallar) a partir del
# umbral de alerta, para que la partición se planee antes de chocar.

TECHO  <- 300L
ALERTA <- 250L

.raiz_loc <- function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (dir.exists(file.path(d, "learn", "R"))) return(d)
    p <- dirname(d)
    if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
    d <- p
  }
}

#' Cuenta líneas de código: descarta vacías y comentarios puros.
#' Un archivo de 300 líneas donde 200 son comentario no viola nada.
contar_loc <- function(ruta) {
  lineas <- readLines(ruta, warn = FALSE)
  utiles <- trimws(lineas)
  sum(nzchar(utiles) & !startsWith(utiles, "#"))
}

verificar_loc <- function(base = file.path(.raiz_loc(), "learn")) {
  archivos <- list.files(base, pattern = "[.][Rr]$", recursive = TRUE,
                         full.names = TRUE)
  archivos <- archivos[!grepl("/(docs|[.]build|renv)/", archivos)]

  if (!length(archivos)) {
    cat("[loc] sin archivos .R todavía\n")
    return(invisible(TRUE))
  }

  loc <- vapply(archivos, contar_loc, integer(1))
  rel <- sub(paste0("^", base, "/"), "", archivos)
  orden <- order(loc, decreasing = TRUE)

  cat(sprintf("[loc] %d archivos · techo %d · alerta %d\n",
              length(archivos), TECHO, ALERTA))
  for (i in orden) {
    marca <- if (loc[i] > TECHO) "FALLA" else if (loc[i] >= ALERTA) "alerta" else "ok"
    if (marca != "ok" || loc[i] > 150)
      cat(sprintf("  %-6s %4d  %s\n", marca, loc[i], rel[i]))
  }

  excedidos <- rel[loc > TECHO]
  if (length(excedidos)) {
    cat(sprintf("\n[loc] %d archivo(s) por encima de %d LOC. Partir por eje\n",
                length(excedidos), TECHO))
    cat("      natural (subseccion, familia de graficos), nunca 'parte 1/2'.\n")
    return(invisible(FALSE))
  }

  cat(sprintf("\n[loc] OK · maximo %d LOC (%s)\n",
              max(loc), rel[which.max(loc)]))
  invisible(TRUE)
}

# Solo se autoejecuta si es EL script invocado por Rscript, no cuando otro
# archivo lo sourcea para reutilizar sus funciones.
.invocado_directamente <- function(nombre) {
  args <- commandArgs(trailingOnly = FALSE)
  archivo <- sub("^--file=", "", args[grepl("^--file=", args)])
  length(archivo) > 0L && basename(archivo[1]) == nombre
}

if (.invocado_directamente("verificar_loc.R")) {
  if (!isTRUE(verificar_loc())) quit(status = 1L)
}
