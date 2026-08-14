# learn/R/ui/f3/ajuste.R
#
# Fase 3 · Ajuste. Cómo se estima, no qué se estima.
#
# No se llama "entrenamiento" porque en prcomp, lm y aov no hay épocas. Lo que
# sí hay, y es lo que esta fase muestra, es un optimizador iterando: Lloyd en
# k-medias, EM en mezclas, descenso por coordenadas en LASSO, IRLS en
# logística. Todos tienen traza, barra de progreso honesta y modo paso a paso.

SUBSECCIONES_AJUSTE <- c("Optimizador", "Control", "Consola", ETIQUETA_ANALISIS)

DETALLE_AJUSTE <- list(
  "Optimizador" = paste("Algoritmo, inicialización y número de reinicios. La",
                        "descripción del algoritmo resalta el paso que se está",
                        "ejecutando mientras corre."),
  "Control" = paste("Máximo de iteraciones, tolerancia, criterio de parada y",
                    "semilla. Sin semilla explícita un resultado no es",
                    "reproducible, así que no es opcional (C13)."),
  "Consola" = paste("Barra de progreso real, log por iteración y modo paso a",
                    "paso: una iteración por clic. En k-medias se ven los",
                    "centroides caminar; en LASSO, los coeficientes tocar cero",
                    "de a uno."))
DETALLE_AJUSTE[[ETIQUETA_ANALISIS]] <- paste(
  "Convergencia, trayectoria de parámetros, camino sobre la superficie de",
  "pérdida, sensibilidad a la semilla, ruta de regularización y curva de",
  "aprendizaje. La pregunta que responden todos: ¿se detuvo por converger o",
  "por agotar iteraciones?")

mod_ajuste_ui <- function(id) {
  fase_pendiente(SUBSECCIONES_AJUSTE, "Hito 4", DETALLE_AJUSTE)
}

mod_ajuste_server <- function(id, almacen = NULL) {
  servidor_pendiente(id)
}
