# learn/R/pruebas/verificar_mapa.R
#
# Responsabilidad: hacer cumplir C9 (trazabilidad).
#
# Uso:  Rscript learn/R/pruebas/verificar_mapa.R
#
# Falla (exit 1) por dos cosas, las dos son bugs:
#   1. Un método declara un artefacto que nadie registró. La ficha prometería
#      un gráfico inexistente.
#   2. MAPA.md quedó viejo. Un índice desactualizado es peor que no tenerlo:
#      manda a leer archivos equivocados.
#
# NO falla por archivos de gráfico o lógica todavía inexistentes: eso es
# deuda planificada, no error. Se cuenta y se informa.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/mapa.R")

.archivo_de <- function(referencia) {
  if (is.na(referencia) || !nzchar(referencia)) return(NA_character_)
  sub("::.*$", "", referencia)
}

.contar_deuda <- function() {
  df <- artefactos_df()
  referencias <- unique(stats::na.omit(c(vapply(df$grafico, .archivo_de, ""),
                                         vapply(df$logica, .archivo_de, ""))))
  referencias <- referencias[nzchar(referencias)]
  existen <- vapply(referencias, function(r) file.exists(ruta_app(r)), logical(1))
  list(archivos_totales = length(referencias),
       archivos_escritos = sum(existen),
       faltantes = referencias[!existen])
}

verificar_mapa <- function() {
  ok <- TRUE

  # --- 1. Artefactos huérfanos -------------------------------------------
  huerfanos <- artefactos_huerfanos()
  if (length(huerfanos)) {
    cat("[mapa] artefactos declarados por un método y NO registrados:\n")
    for (h in huerfanos) cat("  ", h, "\n")
    cat("       registralos en learn/R/nucleo/artefactos/\n")
    ok <- FALSE
  }

  # --- 2. MAPA.md al día --------------------------------------------------
  ruta <- ruta_app("MAPA.md")
  if (!file.exists(ruta)) {
    cat("[mapa] falta MAPA.md · generalo con: Rscript learn/R/mapa.R\n")
    ok <- FALSE
  } else {
    en_disco <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
    if (!identical(en_disco, generar_mapa())) {
      cat("[mapa] MAPA.md está desactualizado · Rscript learn/R/mapa.R\n")
      ok <- FALSE
    }
  }

  # --- 3. Deuda (informativa) ---------------------------------------------
  deuda <- .contar_deuda()
  cobertura <- cobertura_textos()
  cat(sprintf("[mapa] %d métodos · %d artefactos\n",
              length(claves_metodos()), length(claves_artefactos())))
  cat(sprintf("[mapa] deuda · código %d/%d · textos %d/%d · fichas %d/%d\n",
              deuda$archivos_escritos, deuda$archivos_totales,
              cobertura$textos_escritos, cobertura$textos_esperados,
              cobertura$fichas_escritas, cobertura$fichas_esperadas))

  if (ok) cat("[mapa] OK\n")
  invisible(ok)
}

if (any(grepl("verificar_mapa[.]R$", commandArgs(trailingOnly = FALSE)))) {
  if (!isTRUE(verificar_mapa())) quit(status = 1L)
}
