# learn/R/nucleo/catalogo/agrupamiento.R
#
# Sesión 5 · Agrupamiento.
# Fuentes: notes/SDA/NB4_EST · libs/topics-map.md filas 18-22.

poblar_catalogo_agrupamiento <- function() {

  registrar_metodo(
    clave = "kmeans", nombre = "K-medias",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/020-kmeans",
    estado = "activo", ajustar = ajustar_kmeans,
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 10L,
                   faltantes = FALSE, escalado = TRUE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)"),
      escalar = list(tipo = "logico", def = TRUE,
                     etiqueta = "Estandarizar antes de medir distancias")),
    # Hartigan-Wong no está: implementarlo a mano es otro hito y despacharlo a
    # stats::kmeans() devolvería un resultado sin traza, que es justo lo que la
    # fase 3 muestra. El catálogo promete lo que puede correr.
    optimizador = list(
      metodos = c("Lloyd", "MacQueen"),
      inicializaciones = c("k-means++", "aleatoria", "Forgy"),
      traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.consola.estado", "f3.analisis.convergencia",
                   "f3.analisis.trayectoria",
                   "f4.desempeno.grupos", "f4.desempeno.cruce_clase",
                   "f4.diagnostico.silueta",
                   "f4.diagnostico.codo", "f4.explicabilidad.mapa_2d",
                   "f4.explicabilidad.centroides"),
    supuestos = c("escalado_previo", "grupos_esfericos", "tamanos_similares",
                  "sin_atipicos"))

  registrar_metodo(
    clave = "jerarquico", nombre = "Agrupamiento jerárquico",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/030-jerarquico",
    estado = "activo", ajustar = ajustar_jerarquico,
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
                     etiqueta = "Grupos al cortar el dendrograma"),
      # El mismo interruptor que k-medias y por la misma razón: las distancias
      # suman unidades distintas. Sin él, comparar las dos particiones sobre
      # los mismos datos sería comparar matrices distintas.
      escalar = list(tipo = "logico", def = TRUE,
                     etiqueta = "Estandarizar antes de medir distancias")),
    # Un solo algoritmo, el aglomerativo de hclust(). Se declara igual: su
    # historial de fusiones es una traza de verdad, y la fase 3 la reproduce.
    optimizador = list(metodos = "aglomerativo", traza = TRUE,
                       paso_a_paso = TRUE),
    artefactos = c("f3.analisis.convergencia", "f3.analisis.trayectoria",
                   "f4.desempeno.grupos", "f4.desempeno.cruce_clase",
                   "f4.diagnostico.dendrograma",
                   "f4.diagnostico.silueta", "f4.diagnostico.cofenetico",
                   "f4.explicabilidad.mapa_2d", "f4.explicabilidad.centroides"),
    supuestos = c("escalado_previo", "distancia_valida"))

  # Proyecto final: agrupamiento de variables cualitativas. Los tres métodos
  # que siguen cambian una pieza de k-medias cada uno: el centro (kmodos), la
  # distancia (gower) o el modelo (clases_latentes).
  #
  # `inicializacion` y `reinicios` NO van en hiper: ajustar_por_registro() ya
  # los pasa como argumentos de control, y declararlos otra vez los duplica.
  registrar_metodo(
    clave = "kmodos", nombre = "K-modas",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/020-kmeans",
    estado = "activo", ajustar = ajustar_kmodos,
    entrada = list(tipo = "matriz_cualitativa", min_p = 2L, min_n = 10L,
                   faltantes = FALSE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)")),
    optimizador = list(
      metodos = "Huang",
      inicializaciones = c("Huang", "Cao", "aleatoria"),
      traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.consola.estado", "f3.analisis.convergencia",
                   "f3.analisis.trayectoria",
                   "f4.desempeno.grupos", "f4.desempeno.cruce_clase",
                   "f4.diagnostico.silueta", "f4.diagnostico.codo",
                   "f4.explicabilidad.modos", "f4.explicabilidad.mapa_2d"),
    supuestos = character(0))

  # `faltantes = FALSE` aunque daisy tolera NA por pares: agregar_grupos()
  # alinea la columna de grupos con complete.cases y una fila incompleta
  # quedaría con el grupo de otra.
  registrar_metodo(
    clave = "gower", nombre = "Gower + PAM / jerárquico",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/040-otros-enfoques",
    estado = "activo", ajustar = ajustar_gower,
    entrada = list(tipo = "matriz_cualitativa", min_p = 2L, min_n = 5L,
                   faltantes = FALSE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de grupos (k)"),
      estrategia = list(tipo = "opcion", opciones = c("pam", "jerarquico"),
                        def = "pam", etiqueta = "Estrategia"),
      enlace = list(tipo = "opcion",
                    opciones = c("average", "complete", "single", "ward.D2"),
                    def = "average", etiqueta = "Enlace (solo jerárquico)"),
      binarias_asimetricas = list(tipo = "logico", def = FALSE,
                                  etiqueta = "Binarias asimétricas (no/no no cuenta)")),
    optimizador = list(metodos = "PAM / aglomerativo", traza = TRUE,
                       paso_a_paso = FALSE),
    artefactos = c("f3.analisis.convergencia", "f3.analisis.trayectoria",
                   "f4.desempeno.grupos", "f4.desempeno.cruce_clase",
                   "f4.diagnostico.dendrograma", "f4.diagnostico.silueta",
                   "f4.diagnostico.codo",
                   "f4.explicabilidad.modos", "f4.explicabilidad.mapa_2d"),
    supuestos = character(0))

  # El análogo categórico de la mezcla gaussiana: EM a mano, BIC para k.
  # `k_max` solo arma la tabla de BIC; el ajuste que se lee es el de `k`.
  registrar_metodo(
    clave = "clases_latentes", nombre = "Clases latentes",
    objetivo = "agrupar", supervision = "no_supervisado", sesion = 5,
    nodo = "100-agrupamiento/040-otros-enfoques",
    estado = "activo", ajustar = ajustar_clases_latentes,
    entrada = list(tipo = "matriz_cualitativa", min_p = 2L, min_n = 10L,
                   faltantes = FALSE),
    hiper = list(
      k = list(tipo = "entero", min = 2, max = 12, def = 3, paso = 1,
               etiqueta = "Número de clases (k)"),
      k_max = list(tipo = "entero", min = 2, max = 12, def = 8, paso = 1,
                   etiqueta = "K máximo en la tabla de BIC")),
    optimizador = list(metodos = "EM", traza = TRUE, paso_a_paso = TRUE),
    artefactos = c("f3.consola.estado", "f3.analisis.convergencia",
                   "f3.analisis.trayectoria",
                   "f4.desempeno.grupos", "f4.desempeno.cruce_clase",
                   "f4.diagnostico.bic", "f4.diagnostico.silueta",
                   "f4.explicabilidad.modos", "f4.explicabilidad.mapa_2d"),
    supuestos = "categorias_suficientes")

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
