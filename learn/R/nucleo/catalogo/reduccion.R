# learn/R/nucleo/catalogo/reduccion.R
#
# Sesión 4 · Reducción de dimensionalidad.
# Fuentes: notes/SDA/NB3 · libs/topics-map.md filas 11-17.

poblar_catalogo_reduccion <- function() {

  registrar_metodo(
    clave = "acp", nombre = "Análisis de componentes principales",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    nodo = "090-reduccion/020-acp",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 5L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      n_componentes = list(tipo = "entero", min = 1, max = 20, def = 2, paso = 1,
                           etiqueta = "Componentes a retener"),
      matriz = list(tipo = "opcion", opciones = c("correlacion", "covarianza"),
                    def = "correlacion",
                    etiqueta = "Descomponer R (escalado) o S (crudo)")),
    optimizador = list(metodos = c("SVD", "descomposicion espectral"),
                       traza = FALSE, paso_a_paso = FALSE),
    artefactos = c("f4.diagnostico.scree", "f4.explicabilidad.biplot",
                   "f4.explicabilidad.circulo_correlaciones",
                   "f4.explicabilidad.cargas"),
    supuestos = c("escalado_previo", "estructura_lineal", "sin_atipicos"))

  registrar_metodo(
    clave = "efa", nombre = "Análisis factorial exploratorio",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "psych", wasm = FALSE,
    nodo = "090-reduccion/030-emparentados/010-analisis-factorial",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 50L,
                   faltantes = FALSE),
    hiper = list(
      n_factores = list(tipo = "entero", min = 1, max = 10, def = 2, paso = 1,
                        etiqueta = "Número de factores"),
      rotacion = list(tipo = "opcion",
                      opciones = c("varimax", "oblimin", "none"),
                      def = "varimax", etiqueta = "Rotación")),
    artefactos = c("f4.explicabilidad.cargas", "f4.diagnostico.scree"),
    supuestos = c("correlaciones_suficientes"))

  registrar_metodo(
    clave = "acp_robusto", nombre = "ACP robusto",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "rrcov", wasm = FALSE,
    nodo = "090-reduccion/020-acp/050-decisiones/020-outliers",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   faltantes = FALSE),
    hiper = list(
      n_componentes = list(tipo = "entero", min = 1, max = 20, def = 2, paso = 1,
                           etiqueta = "Componentes a retener")),
    artefactos = c("f4.explicabilidad.biplot", "f4.diagnostico.scree"),
    supuestos = c("escalado_previo"))

  registrar_metodo(
    clave = "acp_faltantes", nombre = "ACP con datos faltantes",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "missMDA", wasm = FALSE,
    nodo = "090-reduccion/020-acp",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L),
    hiper = list(
      ncp = list(tipo = "entero", min = 1, max = 10, def = 2, paso = 1,
                 etiqueta = "Dimensiones para imputar")),
    optimizador = list(metodos = "EM iterativo", traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.explicabilidad.biplot"),
    supuestos = character(0))

  registrar_metodo(
    clave = "tsne", nombre = "t-SNE",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "Rtsne", wasm = FALSE,
    nodo = "090-reduccion/030-emparentados/040-no-lineal",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 30L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      perplejidad = list(tipo = "real", min = 5, max = 50, def = 30, paso = 1,
                         etiqueta = "Perplejidad"),
      dimensiones = list(tipo = "entero", min = 2, max = 3, def = 2, paso = 1,
                         etiqueta = "Dimensiones de salida")),
    optimizador = list(metodos = "descenso por gradiente", traza = TRUE,
                       paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.explicabilidad.mapa_2d"),
    supuestos = c("escalado_previo", "no_preserva_distancias_globales"))

  registrar_metodo(
    clave = "umap", nombre = "UMAP",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "umap", wasm = FALSE,
    nodo = "090-reduccion/030-emparentados/040-no-lineal",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 30L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      n_vecinos = list(tipo = "entero", min = 2, max = 100, def = 15, paso = 1,
                       etiqueta = "Número de vecinos"),
      distancia_min = list(tipo = "real", min = 0, max = 1, def = 0.1,
                           paso = 0.01, etiqueta = "Distancia mínima")),
    artefactos = "f4.explicabilidad.mapa_2d",
    supuestos = c("escalado_previo"))

  registrar_metodo(
    clave = "fpca", nombre = "ACP funcional",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "fda", wasm = FALSE,
    nodo = "150-extensiones/070-datos-funcionales",
    entrada = list(tipo = "series", min_p = 5L, faltantes = FALSE),
    hiper = list(
      n_bases = list(tipo = "entero", min = 3, max = 40, def = 10, paso = 1,
                     etiqueta = "Número de funciones base")),
    artefactos = c("f4.diagnostico.scree", "f4.explicabilidad.cargas"),
    supuestos = c("observaciones_son_curvas"))

  registrar_metodo(
    clave = "kernel_pca", nombre = "Kernel PCA",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    deps = "kernlab", wasm = FALSE,
    nodo = "090-reduccion/030-emparentados/040-no-lineal",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      nucleo = list(tipo = "opcion",
                    opciones = c("rbfdot", "polydot", "tanhdot"),
                    def = "rbfdot", etiqueta = "Kernel"),
      sigma = list(tipo = "real", min = 0.01, max = 5, def = 0.1, paso = 0.01,
                   etiqueta = "σ del kernel")),
    artefactos = "f4.explicabilidad.mapa_2d",
    supuestos = c("escalado_previo"))

  registrar_metodo(
    clave = "mds", nombre = "Escalamiento multidimensional",
    objetivo = "reducir", supervision = "no_supervisado", sesion = 4,
    nodo = "090-reduccion/030-emparentados/020-mds",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 10L,
                   faltantes = FALSE),
    hiper = list(
      tipo_mds = list(tipo = "opcion", opciones = c("clasico", "no_metrico"),
                      def = "clasico", etiqueta = "Tipo"),
      dimensiones = list(tipo = "entero", min = 2, max = 5, def = 2, paso = 1,
                         etiqueta = "Dimensiones")),
    optimizador = list(metodos = "SMACOF", traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f4.explicabilidad.mapa_2d"),
    supuestos = c("distancia_valida"))

  invisible(TRUE)
}
