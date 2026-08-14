# learn/R/ui/f4/evaluacion.R
#
# Fase 4 · Evaluación. Donde las tres fases anteriores se componen.
#
#   DATASET x MODELO x RECETA -> CORRIDA
#
# Una corrida es el único objeto que produce resultados, y el único que se
# puede exportar como informe.

SUBSECCIONES_EVALUACION <- c("Composición", "Desempeño", "Diagnóstico",
                             "Explicabilidad", "Comparación", ETIQUETA_ANALISIS)

DETALLE_EVALUACION <- list(
  "Composición" = paste("Elegir los tres objetos, ver el panel de",
                        "compatibilidad con sus avisos accionables, correr, o",
                        "encolar un barrido de hiperparámetros."),
  "Desempeño" = paste("Métricas según el tipo de tarea, sobre train, test o",
                      "validación cruzada. ROC, precisión-exhaustividad,",
                      "calibración y matriz de confusión clicable."),
  "Diagnóstico" = paste("Lo que corresponda al método: residuos, Q-Q,",
                        "leverage y Cook, VIF, silueta, scree, dendrograma con",
                        "corte móvil."),
  "Explicabilidad" = paste("Importancia por permutación, PDP e ICE, LIME y",
                           "SHAP donde apliquen, cargas y biplot en los",
                           "métodos de reducción."),
  "Comparación" = paste("Dos o más corridas lado a lado: tabla de métricas,",
                        "coordenadas paralelas de hiperparámetros y curvas ROC",
                        "superpuestas."))
DETALLE_EVALUACION[[ETIQUETA_ANALISIS]] <- paste(
  "El informe compuesto: qué datos, qué modelo, cómo se ajustó, qué resultó y",
  "qué significa. Exportable a .Rmd, a HTML, a diapositivas y al JSON del",
  "contrato S2. La guía del curso pide cuaderno RMD más diapositivas, así que",
  "esto convierte una exploración en la mayor parte de un entregable.")

mod_evaluacion_ui <- function(id) {
  fase_pendiente(SUBSECCIONES_EVALUACION, "Hito 6", DETALLE_EVALUACION)
}

mod_evaluacion_server <- function(id, almacen = NULL) {
  servidor_pendiente(id)
}
