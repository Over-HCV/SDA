# learn/R/nucleo/catalogo/bloqueados.R
#
# Métodos que NO se pueden ejecutar aquí, y aparecen igual.
#
# Por qué no se ocultan: son el borde del mapa, y saber que hay un borde es
# parte de entender el territorio. Cada ficha lleva un PUENTE: la frase que
# conecta el método inalcanzable con algo que sí corre en el lab. Sin el
# puente, la tarjeta sería decoración; con él, es una pregunta abierta.
#
# `motivo` es obligatorio para estado = "bloqueado" (ver registro.R).

poblar_catalogo_bloqueados <- function() {

  registrar_metodo(
    clave = "mlp", nombre = "Perceptrón multicapa",
    objetivo = "clasificar", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE, deps = "torch",
    nodo = "150-extensiones/080-aprendizaje-estadistico",
    motivo = paste("torch no compila a WebAssembly y las redes neuronales",
                   "quedan fuera del temario del curso."),
    puente = paste("Un MLP sin capa oculta y con activación sigmoide ES una",
                   "regresión logística. Corré la logística en el lab, mirá",
                   "sus coeficientes, y después imaginá una capa más."))

  registrar_metodo(
    clave = "cnn", nombre = "Red convolucional",
    objetivo = "clasificar", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE, deps = "torch",
    nodo = "150-extensiones/090-no-estructurados",
    motivo = paste("Requiere torch, GPU y datos de imagen; nada de eso está",
                   "disponible en este entorno."),
    puente = paste("Una convolución es un filtro local con pesos compartidos:",
                   "el mismo promedio ponderado que hace un suavizado kernel,",
                   "pero con los pesos aprendidos en vez de fijados."))

  registrar_metodo(
    clave = "transformer", nombre = "Transformer",
    objetivo = "predecir", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE, deps = "torch",
    nodo = "150-extensiones/090-no-estructurados",
    motivo = "Escala de cómputo fuera del alcance de un curso de 24 horas.",
    puente = paste("La atención es un promedio ponderado donde los pesos",
                   "salen de similitudes entre vectores. Mirá la similitud",
                   "coseno en Distancias (sesión 3): es el mismo producto",
                   "interno normalizado."))

  registrar_metodo(
    clave = "fundacional", nombre = "Modelos fundacionales",
    objetivo = "predecir", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE,
    nodo = "150-extensiones/090-no-estructurados",
    motivo = "No son entrenables en un curso; solo se consumen preentrenados.",
    puente = paste("El borde real del mapa. Lo que sí se traslada es el",
                   "método de evaluación: matriz de confusión, validación",
                   "cruzada y sesgo-varianza valen igual para un modelo de",
                   "mil millones de parámetros."))

  registrar_metodo(
    clave = "bayes_brms", nombre = "Regresión bayesiana (MCMC)",
    objetivo = "predecir", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE, deps = c("brms", "rstan"),
    nodo = "150-extensiones/010-bayesiana",
    motivo = paste("rstan no compila a WebAssembly. En la versión de servidor",
                   "sí puede correr, pero el muestreo MCMC tarda minutos."),
    puente = paste("El teorema de Bayes de la sesión 2 es el mismo que usa",
                   "MCMC: previa × verosimilitud ∝ posterior. Lo único que",
                   "cambia es que la posterior se aproxima muestreando en vez",
                   "de resolverse en cerrado."))

  registrar_metodo(
    clave = "espacial", nombre = "Regresión espacial (SAR / SEM)",
    objetivo = "predecir", supervision = "supervisado",
    estado = "bloqueado", wasm = FALSE, deps = c("spdep", "spatialreg"),
    nodo = "100-agrupamiento/060-correlacion-espacial",
    motivo = paste("Necesita un shapefile de geometrías que el proyecto no",
                   "incluye todavía."),
    puente = paste("El supuesto que rompe es la independencia de los errores.",
                   "Corré una regresión múltiple sobre charcoal por país y",
                   "mirá el I de Moran de sus residuos: ahí se ve el problema",
                   "que este método resuelve."))

  invisible(TRUE)
}
