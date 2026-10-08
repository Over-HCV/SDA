# learn/R/nucleo/informe/codigos/fase1/despacho.R
#
# Responsabilidad: decir qué generador de la fase 1 le toca a cada clave.

#' @return character() de líneas, o NULL si la clave no tiene generador
#'   (codigo_artefacto() cae entonces al genérico).
.codigo_fase1 <- function(clave, params, tabla = NULL) {
  switch(
    clave,
    "f1.analisis.histograma" = .codigo_histograma(params),
    "f1.analisis.densidad" = .codigo_densidad(params),
    "f1.analisis.boxplot" = .codigo_boxplot(params),
    "f1.analisis.resumen" = .codigo_resumen(params),
    "f1.analisis.boxplot_grupos" = .codigo_boxplot_grupos(params),
    "f1.analisis.qq_normal_datos" = .codigo_qq(params),
    "f1.analisis.dispersion" = .codigo_dispersion(params),
    "f1.analisis.densidad_conjunta" = .codigo_densidad_conjunta(params),
    "f1.analisis.mosaico" = .codigo_mosaico(params),
    "f1.analisis.matriz_dispersion" = .codigo_pares(params),
    "f1.analisis.heatmap_correlacion" = .codigo_heatmap(params),
    "f1.analisis.coordenadas_paralelas" = .codigo_paralelas(params),
    "f1.analisis.elipsoide" = .codigo_elipsoide(params),
    "f1.analisis.qq_mahalanobis" = .codigo_qq_mahalanobis(params),
    "f1.calidad.atipicos" = .codigo_atipicos(params),
    "f1.balanceo.frecuencias" = .codigo_frecuencias(params),
    "f1.fuente.vista_previa" = .codigo_vista_previa(params),
    "f1.filtro.filas" = .codigo_filtro(params),
    "f1.diccionario.tabla" = .codigo_diccionario(params, tabla),
    NULL)
}
