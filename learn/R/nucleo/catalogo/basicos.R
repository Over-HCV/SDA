# learn/R/nucleo/catalogo/basicos.R
#
# Sesiones 1-2 · Herramientas estadísticas básicas.
# Fuentes: notes/SDA/NB1_1_EST, NB1_2_EST · libs/topics-map.md filas 1-5.

poblar_catalogo_basicos <- function() {

  registrar_metodo(
    clave = "resumen_univariado", nombre = "Resumen univariado",
    objetivo = "describir", sesion = 1,
    nodo = "020-descriptiva/050-numerico",
    entrada = list(min_p = 1L),
    artefactos = c("f1.analisis.histograma", "f1.analisis.boxplot"),
    supuestos = character(0))

  registrar_metodo(
    clave = "densidad_kernel", nombre = "Estimación de densidad kernel",
    objetivo = "describir", sesion = 1,
    nodo = "040-variables-aleatorias/060-estimacion-densidad/020-kernel",
    entrada = list(tipo = "vector_numerico", min_p = 1L, faltantes = FALSE),
    hiper = list(
      ancho = list(tipo = "real", min = 0.05, max = 5, def = 0.5, paso = 0.05,
                   etiqueta = "Ancho de banda (h)"),
      nucleo = list(tipo = "opcion", opciones = c("gaussian", "epanechnikov",
                                                  "rectangular"),
                    def = "gaussian", etiqueta = "Función núcleo")),
    artefactos = "f1.analisis.densidad",
    supuestos = c("sin_faltantes"))

  registrar_metodo(
    clave = "normalidad", nombre = "Verificación de normalidad",
    objetivo = "contrastar", sesion = 2,
    nodo = "040-variables-aleatorias/050-normal-detalle/030-verificacion-normalidad",
    entrada = list(tipo = "vector_numerico", min_p = 1L, min_n = 3L,
                   faltantes = FALSE),
    hiper = list(
      prueba = list(tipo = "opcion",
                    opciones = c("shapiro", "anderson-darling", "ks"),
                    def = "shapiro", etiqueta = "Prueba")),
    artefactos = c("f4.diagnostico.qq_normal"),
    supuestos = c("muestra_aleatoria"))

  registrar_metodo(
    clave = "box_cox", nombre = "Transformación de Box-Cox",
    objetivo = "describir", sesion = 2, deps = "MASS",
    nodo = "120-regresion/040-multiple/090-transformaciones",
    entrada = list(tipo = "vector_numerico", min_p = 1L, positivo = TRUE,
                   faltantes = FALSE),
    hiper = list(
      lambda_min = list(tipo = "real", min = -3, max = 0, def = -2, paso = 0.5,
                        etiqueta = "λ mínimo"),
      lambda_max = list(tipo = "real", min = 0, max = 3, def = 2, paso = 0.5,
                        etiqueta = "λ máximo")),
    optimizador = list(metodos = "perfil de verosimilitud", traza = TRUE,
                       paso_a_paso = FALSE),
    artefactos = "f3.analisis.perfil_verosimilitud",
    supuestos = c("respuesta_positiva"))

  registrar_metodo(
    clave = "potencia", nombre = "Análisis de potencia",
    objetivo = "contrastar", sesion = 2, deps = "pwr",
    nodo = "060-inferencia/050-pruebas-hipotesis/040-potencia",
    entrada = list(min_p = 0L),
    hiper = list(
      efecto = list(tipo = "real", min = 0.05, max = 2, def = 0.5, paso = 0.05,
                    etiqueta = "Tamaño del efecto (d de Cohen)"),
      alfa = list(tipo = "real", min = 0.001, max = 0.2, def = 0.05, paso = 0.005,
                  etiqueta = "Nivel de significancia (α)")),
    artefactos = "f2.analisis.curva_potencia",
    supuestos = character(0))

  registrar_metodo(
    clave = "faltantes", nombre = "Diagnóstico de datos faltantes",
    objetivo = "describir", sesion = 1, deps = c("naniar", "mice"),
    nodo = "020-descriptiva/030-estructura-datos/010-faltantes",
    entrada = list(min_p = 1L),
    hiper = list(
      metodo = list(tipo = "opcion",
                    opciones = c("media", "mediana", "knn", "mice"),
                    def = "mediana", etiqueta = "Método de imputación")),
    artefactos = "f1.calidad.matriz_nulidad",
    supuestos = character(0))

  registrar_metodo(
    clave = "permutacion", nombre = "Prueba de permutación",
    objetivo = "contrastar", sesion = 2, deps = "coin",
    nodo = "060-inferencia/060-remuestreo/020-permutacion",
    entrada = list(min_p = 1L, grupo = TRUE, faltantes = FALSE),
    hiper = list(
      n_permutaciones = list(tipo = "entero", min = 100, max = 20000,
                             def = 2000, paso = 100,
                             etiqueta = "Número de permutaciones")),
    optimizador = list(metodos = "remuestreo", traza = TRUE, paso_a_paso = FALSE),
    artefactos = "f4.desempeno.distribucion_nula",
    supuestos = c("intercambiabilidad"))

  registrar_metodo(
    clave = "bootstrap", nombre = "Bootstrap",
    objetivo = "contrastar", sesion = 2,
    nodo = "060-inferencia/060-remuestreo/010-bootstrap",
    entrada = list(tipo = "vector_numerico", min_p = 1L, faltantes = FALSE),
    hiper = list(
      n_replicas = list(tipo = "entero", min = 100, max = 20000, def = 2000,
                        paso = 100, etiqueta = "Número de réplicas")),
    optimizador = list(metodos = "remuestreo", traza = TRUE, paso_a_paso = FALSE),
    artefactos = "f4.desempeno.distribucion_bootstrap",
    supuestos = c("muestra_aleatoria"))

  invisible(TRUE)
}
