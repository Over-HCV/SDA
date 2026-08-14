# learn/R/nucleo/catalogo/agrupamiento.R
#
# Sesión 5 · Agrupamiento.
# Fuentes: notes/SDA/NB4_EST · libs/topics-map.md filas 18-22.

poblar_catalogo_agrupamiento <- function() {

  registrar_metodo(
    clave = "kmeans", nombre = "K-medias",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/020-kmeans",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 10L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)")),
    optimizador = list(
      metodos = c("Lloyd", "MacQueen", "Hartigan-Wong"),
      inicializaciones = c("k-means++", "aleatoria", "Forgy"),
      traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f3.analisis.trayectoria",
                   "f4.diagnostico.silueta", "f4.diagnostico.codo",
                   "f4.explicabilidad.mapa_2d"),
    supuestos = c("escalado_previo", "grupos_esfericos", "tamanos_similares",
                  "sin_atipicos"))

  registrar_metodo(
    clave = "jerarquico", nombre = "Agrupamiento jerárquico",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/030-jerarquico",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 5L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      enlace = list(tipo = "opcion",
                    opciones = c("ward.D2", "complete", "average", "single",
                                 "centroid"),
                    def = "ward.D2", etiqueta = "Criterio de enlace"),
      distancia = list(tipo = "opcion",
                       opciones = c("euclidean", "manhattan", "maximum"),
                       def = "euclidean", etiqueta = "Distancia"),
      k_corte = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
                     etiqueta = "Grupos al cortar el dendrograma")),
    artefactos = c("f4.diagnostico.dendrograma", "f4.diagnostico.silueta",
                   "f4.diagnostico.cofenetico"),
    supuestos = c("escalado_previo", "distancia_valida"))

  registrar_metodo(
    clave = "dbscan", nombre = "DBSCAN",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    deps = "dbscan",
    nodo = "100-agrupamiento/040-otros-enfoques/010-dbscan",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      eps = list(tipo = "real", min = 0.05, max = 5, def = 0.5, paso = 0.05,
                 etiqueta = "Radio del vecindario (ε)"),
      min_puntos = list(tipo = "entero", min = 2, max = 50, def = 5, paso = 1,
                        etiqueta = "Puntos mínimos (minPts)")),
    artefactos = c("f4.explicabilidad.mapa_2d", "f4.diagnostico.knn_distancias"),
    supuestos = c("escalado_previo", "densidad_homogenea"))

  registrar_metodo(
    clave = "espectral", nombre = "Agrupamiento espectral",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    deps = "kernlab", wasm = FALSE,
    nodo = "100-agrupamiento/040-otros-enfoques",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)")),
    artefactos = c("f4.explicabilidad.mapa_2d", "f4.diagnostico.silueta"),
    supuestos = c("escalado_previo"))

  registrar_metodo(
    clave = "dtw", nombre = "Agrupamiento de series con DTW",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    deps = "dtwclust", wasm = FALSE,
    nodo = "150-extensiones/030-series-tiempo",
    entrada = list(tipo = "series", min_p = 3L, faltantes = FALSE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)"),
      metodo_dtw = list(tipo = "opcion",
                        opciones = c("partitional", "hierarchical"),
                        def = "partitional", etiqueta = "Estrategia")),
    optimizador = list(metodos = "Lloyd sobre DTW", traza = TRUE,
                       paso_a_paso = FALSE),
    artefactos = c("f4.explicabilidad.series_por_grupo", "f4.diagnostico.silueta"),
    supuestos = c("observaciones_son_series"))

  registrar_metodo(
    clave = "comunidades", nombre = "Detección de comunidades",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    deps = "igraph", wasm = FALSE,
    nodo = "150-extensiones/090-no-estructurados",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, faltantes = FALSE),
    hiper = list(
      umbral = list(tipo = "real", min = 0, max = 1, def = 0.5, paso = 0.01,
                    etiqueta = "Umbral de correlación para crear una arista"),
      algoritmo = list(tipo = "opcion",
                       opciones = c("louvain", "walktrap", "fast_greedy"),
                       def = "louvain", etiqueta = "Algoritmo")),
    artefactos = "f4.explicabilidad.grafo",
    supuestos = c("grafo_conexo"))

  registrar_metodo(
    clave = "biclustering", nombre = "Biclustering",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    deps = "biclust", wasm = FALSE,
    nodo = "100-agrupamiento/040-otros-enfoques",
    entrada = list(tipo = "matriz_numerica", min_p = 3L, min_n = 20L,
                   faltantes = FALSE),
    hiper = list(
      metodo_bi = list(tipo = "opcion",
                       opciones = c("BCCC", "BCXmotifs", "BCPlaid"),
                       def = "BCCC", etiqueta = "Método")),
    artefactos = "f4.explicabilidad.heatmap_bicluster",
    supuestos = character(0))

  registrar_metodo(
    clave = "validacion_grupos", nombre = "Validación de grupos",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/050-validacion",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 10L,
                   faltantes = FALSE),
    hiper = list(
      k_max = list(tipo = "entero", min = 3, max = 15, def = 10, paso = 1,
                   etiqueta = "K máximo a evaluar")),
    artefactos = c("f4.diagnostico.silueta", "f4.diagnostico.codo",
                   "f4.diagnostico.indices_internos"),
    supuestos = c("escalado_previo"))

  invisible(TRUE)
}
