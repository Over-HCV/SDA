# learn/R/nucleo/catalogo/anova.R
#
# Sesión 8 · Análisis de varianza.
# Fuentes: notes/SDA/NB6_EST · libs/topics-map.md filas 28-32.

poblar_catalogo_anova <- function() {

  registrar_metodo(
    clave = "anova_una_via", nombre = "ANOVA a una vía",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    nodo = "130-anova/030-una-via",
    entrada = list(tipo = "matriz_numerica", min_p = 1L, min_n = 12L,
                   respuesta = TRUE, grupo = TRUE, faltantes = FALSE),
    optimizador = list(metodos = "descomposición de sumas de cuadrados",
                       traza = FALSE, paso_a_paso = FALSE),
    artefactos = c("f1.analisis.boxplot_grupos", "f4.desempeno.tabla_anova",
                   "f4.diagnostico.residuos", "f4.diagnostico.qq_normal",
                   "f4.diagnostico.homocedasticidad"),
    supuestos = c("independencia", "normalidad_por_grupo", "homocedasticidad"))

  registrar_metodo(
    clave = "tukey", nombre = "Comparaciones múltiples (Tukey HSD)",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    nodo = "130-anova/050-comparaciones-multiples/020-tukey",
    entrada = list(tipo = "matriz_numerica", min_p = 1L, min_n = 12L,
                   respuesta = TRUE, grupo = TRUE, faltantes = FALSE),
    hiper = list(
      nivel = list(tipo = "real", min = 0.80, max = 0.999, def = 0.95,
                   paso = 0.005, etiqueta = "Nivel de confianza familiar")),
    artefactos = "f4.desempeno.intervalos_tukey",
    supuestos = c("anova_previo_significativo", "homocedasticidad"))

  registrar_metodo(
    clave = "welch", nombre = "Welch y Brown-Forsythe",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    nodo = "130-anova/040-supuestos/030-no-parametricas",
    entrada = list(tipo = "matriz_numerica", min_p = 1L, min_n = 12L,
                   respuesta = TRUE, grupo = TRUE, faltantes = FALSE),
    hiper = list(
      alternativa = list(tipo = "opcion",
                         opciones = c("welch", "brown-forsythe", "kruskal"),
                         def = "welch", etiqueta = "Alternativa robusta")),
    artefactos = c("f4.desempeno.tabla_anova", "f4.diagnostico.homocedasticidad"),
    supuestos = c("independencia"))

  registrar_metodo(
    clave = "manova", nombre = "MANOVA",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    nodo = "130-anova/070-manova",
    entrada = list(tipo = "matriz_numerica", min_p = 2L, min_n = 20L,
                   respuesta = TRUE, grupo = TRUE, faltantes = FALSE),
    hiper = list(
      estadistico = list(tipo = "opcion",
                         opciones = c("Wilks", "Pillai", "Hotelling-Lawley", "Roy"),
                         def = "Pillai", etiqueta = "Estadístico de prueba")),
    artefactos = c("f4.desempeno.tabla_anova", "f4.diagnostico.qq_mahalanobis"),
    supuestos = c("normalidad_multivariada", "covarianzas_iguales",
                  "independencia"))

  registrar_metodo(
    clave = "rm_anova", nombre = "ANOVA de medidas repetidas",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    deps = c("afex", "ez"), wasm = FALSE,
    nodo = "130-anova/060-disenos/050-medidas-repetidas",
    entrada = list(tipo = "panel", min_p = 1L, respuesta = TRUE, grupo = TRUE,
                   faltantes = FALSE),
    artefactos = c("f4.desempeno.tabla_anova", "f4.diagnostico.esfericidad"),
    supuestos = c("esfericidad", "normalidad_por_grupo"))

  registrar_metodo(
    clave = "lmer", nombre = "Modelos mixtos (efectos aleatorios)",
    objetivo = "predecir", supervision = "supervisado", sesion = 8,
    deps = "lme4", wasm = FALSE,
    nodo = "130-anova/060-disenos/040-efectos-aleatorios",
    entrada = list(tipo = "panel", min_p = 2L, respuesta = TRUE, grupo = TRUE,
                   faltantes = FALSE),
    optimizador = list(metodos = c("REML", "ML"), traza = TRUE,
                       paso_a_paso = FALSE),
    artefactos = c("f3.analisis.convergencia", "f4.explicabilidad.efectos_aleatorios",
                   "f4.diagnostico.residuos"),
    supuestos = c("normalidad_efectos_aleatorios", "independencia_entre_grupos"))

  registrar_metodo(
    clave = "tamano_efecto", nombre = "Tamaño del efecto (η², ω²)",
    objetivo = "contrastar", supervision = "supervisado", sesion = 8,
    deps = "effectsize", wasm = FALSE,
    nodo = "130-anova/030-una-via/060-tamano-efecto",
    entrada = list(tipo = "matriz_numerica", min_p = 1L, respuesta = TRUE,
                   grupo = TRUE, faltantes = FALSE),
    artefactos = "f4.desempeno.tamano_efecto",
    supuestos = c("anova_previo"))

  registrar_metodo(
    clave = "chi_cuadrado", nombre = "Ji-cuadrado de independencia",
    objetivo = "contrastar", sesion = 8,
    nodo = "140-contingencia/020-independencia/010-chi-cuadrado",
    entrada = list(tipo = "categoricas", min_p = 2L, min_n = 20L,
                   faltantes = FALSE),
    artefactos = c("f1.analisis.mosaico", "f4.desempeno.tabla_contingencia",
                   "f4.diagnostico.residuos_estandarizados"),
    supuestos = c("frecuencias_esperadas_suficientes", "independencia"))

  invisible(TRUE)
}
