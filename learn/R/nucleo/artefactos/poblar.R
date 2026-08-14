# learn/R/nucleo/artefactos/poblar.R
#
# Responsabilidad: poblar el registro de artefactos visuales (C9).
#
# Cada clave declara DÓNDE vivirá su gráfico, su lógica y su texto. En el
# Hito 1 la mayoría de esos archivos todavía no existe: eso es intencional.
# El mapa es una promesa verificable — `verificar_mapa.R` cuenta cuántas
# promesas están cumplidas y cuántas son deuda.
#
# Las filas se reparten en dos archivos por tamaño (C2):
#   artefactos/exploracion.R  fases 1, 2 y 3
#   artefactos/evaluacion.R   fase 4

poblar_artefactos <- function() {
  limpiar_artefactos()
  poblar_artefactos_exploracion()
  poblar_artefactos_evaluacion()
  invisible(length(claves_artefactos()))
}

#' Artefactos declarados por algún método pero nunca registrados.
#' Es un bug de catálogo: la ficha prometería un gráfico inexistente.
artefactos_huerfanos <- function() {
  declarados <- unique(unlist(lapply(metodos(), `[[`, "artefactos")))
  setdiff(declarados, claves_artefactos())
}

#' Artefactos registrados que ningún método produce. No es un error: hay
#' gráficos que pertenecen a una fase, no a un método (los de exploración).
artefactos_sin_metodo <- function() {
  declarados <- unique(unlist(lapply(metodos(), `[[`, "artefactos")))
  setdiff(claves_artefactos(), declarados)
}
