# learn/R/nucleo/catalogo/multivariada.R
#
# Sesión 3 · Normal multivariada, distancias y visualización.
# Fuentes: notes/SDA/NB2_EST · libs/topics-map.md filas 6-10.

poblar_catalogo_multivariada <- function() {

  registrar_metodo(
    clave = "normal_multivariada", nombre = "Normal multivariada",
    objetivo = "describir", sesion = 3, deps = "mvtnorm",
    nodo = "080-normal-multivariada/020-modelo",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, faltantes = FALSE),
    artefactos = c("f1.analisis.elipsoide", "f1.analisis.densidad_conjunta"),
    supuestos = c("normalidad_multivariada"))

  registrar_metodo(
    clave = "mahalanobis", nombre = "Distancia de Mahalanobis",
    objetivo = "describir", sesion = 3,
    nodo = "070-multivariado/050-distancias/030-mahalanobis",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, faltantes = FALSE,
                   min_n = 10L),
    hiper = list(
      corte = list(tipo = "real", min = 0.90, max = 0.999, def = 0.975,
                   paso = 0.005, etiqueta = "Cuantil de corte para atípicos")),
    artefactos = c("f1.analisis.qq_mahalanobis", "f1.calidad.atipicos"),
    supuestos = c("normalidad_multivariada", "covarianza_invertible"))

  registrar_metodo(
    clave = "hotelling", nombre = "T² de Hotelling",
    objetivo = "contrastar", sesion = 3,
    nodo = "080-normal-multivariada/060-inferencia-mu/010-hotelling-una-muestra",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, faltantes = FALSE,
                   min_n = 10L),
    artefactos = c("f4.desempeno.region_confianza"),
    supuestos = c("normalidad_multivariada", "covarianza_invertible"))

  registrar_metodo(
    clave = "gmm", nombre = "Mezclas gaussianas (EM)",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 3,
    deps = "mclust", wasm = FALSE,
    nodo = "100-agrupamiento/040-otros-enfoques/020-mezclas-gaussianas",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, faltantes = FALSE,
                   escalado = TRUE),
    hiper = list(
      k = list(tipo = "entero", min = 1, max = 12, def = 3, paso = 1,
               etiqueta = "Número de componentes (k)")),
    optimizador = list(metodos = "EM", traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.diagnostico.bic"),
    supuestos = c("componentes_gaussianas"))

  registrar_metodo(
    clave = "lda", nombre = "Análisis discriminante lineal",
    objetivo = "clasificar", supervision = "supervisado", sesion = 3,
    deps = "MASS",
    nodo = "110-clasificacion/020-basados-distribucion/020-lda",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, respuesta = TRUE,
                   faltantes = FALSE, min_n = 20L),
    artefactos = c("f2.analisis.frontera_decision", "f4.desempeno.matriz_confusion"),
    supuestos = c("normalidad_multivariada", "covarianzas_iguales"))

  registrar_metodo(
    clave = "qda", nombre = "Análisis discriminante cuadrático",
    objetivo = "clasificar", supervision = "supervisado", sesion = 3,
    deps = "MASS",
    nodo = "110-clasificacion/020-basados-distribucion/030-qda",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, respuesta = TRUE,
                   faltantes = FALSE, min_n = 30L),
    artefactos = c("f2.analisis.frontera_decision", "f4.desempeno.matriz_confusion"),
    supuestos = c("normalidad_multivariada"))

  registrar_metodo(
    clave = "copula", nombre = "Cópulas",
    objetivo = "describir", sesion = 3, deps = "copula", wasm = FALSE,
    nodo = "050-bivariado/020-conjunta/010-conjunta",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, faltantes = FALSE),
    hiper = list(
      familia = list(tipo = "opcion", opciones = c("normal", "clayton", "gumbel",
                                                   "frank"),
                     def = "normal", etiqueta = "Familia de cópula")),
    artefactos = "f1.analisis.densidad_conjunta",
    supuestos = character(0))

  registrar_metodo(
    clave = "cca", nombre = "Correlación canónica",
    objetivo = "reducir", sesion = 3, deps = "CCA", wasm = FALSE,
    nodo = "090-reduccion/030-emparentados/030-correlacion-canonica",
    entrada = list(tipo = "matriz_numerica", min_p = 4L, faltantes = FALSE,
                   min_n = 30L),
    artefactos = "f4.explicabilidad.cargas",
    supuestos = c("normalidad_multivariada"))

  invisible(TRUE)
}
