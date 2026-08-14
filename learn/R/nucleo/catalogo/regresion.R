# learn/R/nucleo/catalogo/regresion.R
#
# Sesiones 6-7 · Regresión lineal y sus extensiones.
# Fuentes: notes/SDA/NB5_EST · libs/topics-map.md filas 23-27.

poblar_catalogo_regresion <- function() {

  registrar_metodo(
    clave = "regresion_simple", nombre = "Regresión lineal simple",
    objetivo = "predecir", supervision = "supervisado", sesion = 6,
    nodo = "120-regresion/030-simple",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 10L,
                   respuesta = TRUE, faltantes = FALSE),
    optimizador = list(metodos = "mínimos cuadrados (solución cerrada)",
                       traza = FALSE, paso_a_paso = FALSE),
    artefactos = c("f2.analisis.espacio_hipotesis", "f2.analisis.modelo_manual",
                   "f4.desempeno.ajuste", "f4.diagnostico.residuos",
                   "f4.diagnostico.qq_normal"),
    supuestos = c("linealidad", "independencia", "homocedasticidad",
                  "normalidad_errores"))

  registrar_metodo(
    clave = "regresion_multiple", nombre = "Regresión lineal múltiple",
    objetivo = "predecir", supervision = "supervisado", sesion = 6,
    nodo = "120-regresion/040-multiple",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 20L,
                   respuesta = TRUE, faltantes = FALSE),
    optimizador = list(metodos = "mínimos cuadrados (solución cerrada)",
                       traza = FALSE, paso_a_paso = FALSE),
    artefactos = c("f2.analisis.presupuesto_parametros",
                   "f4.desempeno.ajuste", "f4.diagnostico.residuos",
                   "f4.diagnostico.influyentes", "f4.diagnostico.vif",
                   "f4.explicabilidad.coeficientes"),
    supuestos = c("linealidad", "independencia", "homocedasticidad",
                  "normalidad_errores", "sin_multicolinealidad"))

  registrar_metodo(
    clave = "lasso", nombre = "Regresión regularizada (LASSO / Ridge)",
    objetivo = "predecir", supervision = "supervisado", sesion = 7,
    deps = "glmnet",
    nodo = "120-regresion/070-extensiones/010-regularizacion",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 20L,
                   respuesta = TRUE, faltantes = FALSE, escalado = TRUE),
    hiper = list(
      alfa = list(tipo = "real", min = 0, max = 1, def = 1, paso = 0.05,
                  etiqueta = "α — 0 es ridge, 1 es lasso, en medio elastic net"),
      lambda = list(tipo = "real", min = -6, max = 2, def = -3, paso = 0.05,
                    escala = "log10", etiqueta = "log₁₀ λ — penalización")),
    optimizador = list(metodos = "descenso por coordenadas", traza = TRUE,
                       paso_a_paso = FALSE),
    artefactos = c("f3.analisis.ruta_regularizacion", "f3.analisis.convergencia",
                   "f4.explicabilidad.coeficientes", "f4.desempeno.ajuste"),
    supuestos = c("escalado_previo", "linealidad"))

  registrar_metodo(
    clave = "cuantilica", nombre = "Regresión cuantílica",
    objetivo = "predecir", supervision = "supervisado", sesion = 7,
    deps = "quantreg", wasm = FALSE,
    nodo = "120-regresion/070-extensiones/040-robusta",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   respuesta = TRUE, faltantes = FALSE),
    hiper = list(
      tau = list(tipo = "real", min = 0.05, max = 0.95, def = 0.5, paso = 0.05,
                 etiqueta = "Cuantil (τ)")),
    optimizador = list(metodos = "programación lineal", traza = FALSE,
                       paso_a_paso = FALSE),
    artefactos = c("f4.desempeno.ajuste", "f4.explicabilidad.coeficientes"),
    supuestos = c("linealidad"))

  registrar_metodo(
    clave = "step_aic", nombre = "Selección paso a paso (AIC / BIC)",
    objetivo = "predecir", supervision = "supervisado", sesion = 7,
    deps = "MASS",
    nodo = "120-regresion/060-seleccion/020-stepwise",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 30L,
                   respuesta = TRUE, faltantes = FALSE),
    hiper = list(
      direccion = list(tipo = "opcion",
                       opciones = c("both", "backward", "forward"),
                       def = "both", etiqueta = "Dirección"),
      criterio = list(tipo = "opcion", opciones = c("AIC", "BIC"),
                      def = "AIC", etiqueta = "Criterio")),
    optimizador = list(metodos = "búsqueda voraz", traza = TRUE,
                       paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.explicabilidad.coeficientes"),
    supuestos = c("linealidad", "riesgo_dragado_datos"))

  registrar_metodo(
    clave = "logistica", nombre = "Regresión logística",
    objetivo = "clasificar", supervision = "supervisado", sesion = 7,
    nodo = "110-clasificacion/030-basados-regresion/010-logistica",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 30L,
                   respuesta = TRUE, faltantes = FALSE),
    optimizador = list(metodos = c("IRLS", "Newton-Raphson"), traza = TRUE,
                       paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.desempeno.roc",
                   "f4.desempeno.matriz_confusion",
                   "f4.explicabilidad.coeficientes"),
    supuestos = c("linealidad_logit", "independencia", "sin_separacion_completa"))

  registrar_metodo(
    clave = "knn", nombre = "K vecinos más cercanos",
    objetivo = "clasificar", supervision = "supervisado", sesion = 7,
    nodo = "110-clasificacion/040-no-parametricos/010-knn",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   respuesta = TRUE, faltantes = FALSE, escalado = TRUE),
    hiper = list(
      k_vecinos = list(tipo = "entero", min = 1, max = 30, def = 5, paso = 1,
                       etiqueta = "Vecinos (k)")),
    artefactos = c("f2.analisis.frontera_decision",
                   "f4.desempeno.matriz_confusion"),
    supuestos = c("escalado_previo"))

  invisible(TRUE)
}
