# learn/R/nucleo/artefactos/evaluacion.R
#
# Artefactos de la fase 4 (Evaluación), en sus cuatro subsecciones:
# desempeño, diagnóstico, explicabilidad y comparación.

poblar_artefactos_evaluacion <- function() {

  # --- Desempeño ---------------------------------------------------------
  registrar_artefacto("f4.desempeno.ajuste", "Ajuste sobre los datos",
    grafico = "R/graficos/g_desempeno.R::graficar_ajuste",
    logica  = "R/logica/metricas_regresion.R::metricas_regresion",
    descripcion = "Observado contra predicho, con la recta de identidad.")

  registrar_artefacto("f4.desempeno.roc", "Curva ROC",
    grafico = "R/graficos/g_desempeno.R::graficar_roc",
    logica  = "R/logica/metricas_clasificacion.R::calcular_roc",
    descripcion = "Sensibilidad contra 1 - especificidad al barrer el umbral.")

  registrar_artefacto("f4.desempeno.precision_exhaustividad", "Precisión-exhaustividad",
    grafico = "R/graficos/g_desempeno.R::graficar_pr",
    logica  = "R/logica/metricas_clasificacion.R::calcular_pr",
    descripcion = "Mejor que la ROC cuando las clases están desbalanceadas.")

  registrar_artefacto("f4.desempeno.matriz_confusion", "Matriz de confusión",
    grafico = "R/graficos/g_desempeno.R::graficar_confusion",
    logica  = "R/logica/metricas_clasificacion.R::matriz_confusion",
    descripcion = "Aciertos y errores por clase; cada celda es clicable.")

  registrar_artefacto("f4.desempeno.calibracion", "Curva de calibración",
    grafico = "R/graficos/g_desempeno.R::graficar_calibracion",
    logica  = "R/logica/metricas_clasificacion.R::calibracion",
    descripcion = "¿Cuando el modelo dice 0.8, acierta el 80 % de las veces?")

  registrar_artefacto("f4.desempeno.tabla_anova", "Tabla ANOVA",
    grafico = "R/graficos/g_desempeno.R::tabla_anova_formateada",
    logica  = "R/logica/metricas_anova.R::descomponer_varianza",
    descripcion = "Fuente, SC, gl, CM, F y p. La descomposición completa.")

  registrar_artefacto("f4.desempeno.intervalos_tukey", "Intervalos de Tukey",
    grafico = "R/graficos/g_desempeno.R::graficar_tukey",
    logica  = "R/logica/metricas_anova.R::comparaciones_multiples",
    descripcion = "Diferencias entre pares con el nivel familiar corregido.")

  registrar_artefacto("f4.desempeno.tamano_efecto", "Tamaño del efecto",
    grafico = "R/graficos/g_desempeno.R::graficar_tamano_efecto",
    logica  = "R/logica/metricas_anova.R::tamano_efecto",
    descripcion = "Significancia no es relevancia: esto mide cuánto, no si.")

  registrar_artefacto("f4.desempeno.tabla_contingencia", "Tabla de contingencia",
    grafico = "R/graficos/g_desempeno.R::tabla_contingencia_formateada",
    logica  = "R/logica/contingencia.R::tabla_contingencia",
    descripcion = "Observadas contra esperadas, con la contribución al ji-cuadrado.")

  registrar_artefacto("f4.desempeno.region_confianza", "Región de confianza",
    grafico = "R/graficos/g_desempeno.R::graficar_region_confianza",
    logica  = "R/logica/metricas_multivariada.R::region_hotelling",
    descripcion = "La elipse para el vector de medias; no es el rectángulo de dos IC.")

  registrar_artefacto("f4.desempeno.distribucion_nula", "Distribución nula",
    grafico = "R/graficos/g_desempeno.R::graficar_nula",
    logica  = "R/logica/remuestreo.R::distribucion_permutacion",
    descripcion = "Lo que pasaría si H0 fuera cierta, con el observado marcado.")

  registrar_artefacto("f4.desempeno.distribucion_bootstrap", "Distribución bootstrap",
    grafico = "R/graficos/g_desempeno.R::graficar_bootstrap",
    logica  = "R/logica/remuestreo.R::distribucion_bootstrap",
    descripcion = "La incertidumbre del estimador sin suponer una distribución.")

  # --- Diagnóstico -------------------------------------------------------
  registrar_artefacto("f4.diagnostico.residuos", "Residuos contra ajustados",
    grafico = "R/graficos/g_diagnostico.R::graficar_residuos",
    logica  = "R/logica/diagnostico_regresion.R::calcular_residuos",
    descripcion = "El gráfico que más supuestos revisa de una sola mirada.")

  registrar_artefacto("f4.diagnostico.qq_normal", "Q-Q normal de residuos",
    grafico = "R/graficos/g_diagnostico.R::graficar_qq_residuos",
    logica  = "R/logica/normalidad.R::evaluar_normalidad",
    descripcion = "Normalidad de los errores; las colas son lo que importa.")

  registrar_artefacto("f4.diagnostico.homocedasticidad", "Escala-localización",
    grafico = "R/graficos/g_diagnostico.R::graficar_escala_localizacion",
    logica  = "R/logica/diagnostico_regresion.R::prueba_homocedasticidad",
    descripcion = "Si la nube se abre en abanico, la varianza no es constante.")

  registrar_artefacto("f4.diagnostico.influyentes", "Observaciones influyentes",
    grafico = "R/graficos/g_diagnostico.R::graficar_influyentes",
    logica  = "R/logica/diagnostico_regresion.R::medidas_influencia",
    descripcion = "Apalancamiento y distancia de Cook: quién manda en el ajuste.")

  registrar_artefacto("f4.diagnostico.vif", "Factor de inflación de varianza",
    grafico = "R/graficos/g_diagnostico.R::graficar_vif",
    logica  = "R/logica/diagnostico_regresion.R::calcular_vif",
    descripcion = "Multicolinealidad: por qué los errores estándar se inflan.")

  registrar_artefacto("f4.diagnostico.scree", "Gráfico de sedimentación",
    grafico = "R/graficos/g_diagnostico.R::graficar_scree",
    logica  = "R/logica/metricas_reduccion.R::varianza_explicada",
    descripcion = "Autovalores ordenados; el codo sugiere cuántas componentes.")

  registrar_artefacto("f4.diagnostico.silueta", "Silueta",
    grafico = "R/graficos/g_diagnostico.R::graficar_silueta",
    logica  = "R/logica/metricas_grupos.R::silueta",
    descripcion = "Cohesión contra separación, observación por observación.")

  registrar_artefacto("f4.diagnostico.codo", "Codo de la inercia",
    grafico = "R/graficos/g_diagnostico.R::graficar_codo",
    logica  = "R/logica/metricas_grupos.R::inercia_por_k",
    descripcion = "W(K) contra K; la ganancia marginal decide dónde parar.")

  registrar_artefacto("f4.diagnostico.dendrograma", "Dendrograma",
    grafico = "R/graficos/g_diagnostico.R::graficar_dendrograma",
    logica  = "R/logica/metricas_grupos.R::arbol_jerarquico",
    descripcion = "El historial completo de fusiones, con el corte móvil.")

  registrar_artefacto("f4.diagnostico.cofenetico", "Correlación cofenética",
    grafico = "R/graficos/g_diagnostico.R::graficar_cofenetico",
    logica  = "R/logica/metricas_grupos.R::cofenetico",
    descripcion = "Cuánto distorsiona el dendrograma las distancias originales.")

  registrar_artefacto("f4.diagnostico.knn_distancias", "Distancias al k-ésimo vecino",
    grafico = "R/graficos/g_diagnostico.R::graficar_knn_distancias",
    logica  = "R/logica/metricas_grupos.R::distancias_knn",
    descripcion = "La forma honesta de elegir ε en DBSCAN: el codo de la curva.")

  registrar_artefacto("f4.diagnostico.indices_internos", "Índices internos",
    grafico = "R/graficos/g_diagnostico.R::graficar_indices",
    logica  = "R/logica/metricas_grupos.R::indices_internos",
    descripcion = "Silueta, Calinski-Harabasz y Davies-Bouldin, comparados.")

  registrar_artefacto("f4.diagnostico.bic", "BIC por modelo",
    grafico = "R/graficos/g_diagnostico.R::graficar_bic",
    logica  = "R/logica/metricas_grupos.R::bic_mezclas",
    descripcion = "Cómo el GMM elige número de componentes y forma de covarianza.")

  registrar_artefacto("f4.diagnostico.qq_mahalanobis", "Q-Q de Mahalanobis (residual)",
    grafico = "R/graficos/g_diagnostico.R::graficar_qq_mahalanobis",
    logica  = "R/logica/distancias.R::mahalanobis_cuadrado",
    descripcion = "Normalidad multivariada de los residuos multivariados.")

  registrar_artefacto("f4.diagnostico.esfericidad", "Esfericidad",
    grafico = "R/graficos/g_diagnostico.R::graficar_esfericidad",
    logica  = "R/logica/metricas_anova.R::prueba_esfericidad",
    descripcion = "El supuesto propio de medidas repetidas y su corrección.")

  registrar_artefacto("f4.diagnostico.residuos_estandarizados", "Residuos estandarizados",
    grafico = "R/graficos/g_diagnostico.R::graficar_residuos_contingencia",
    logica  = "R/logica/contingencia.R::residuos_estandarizados",
    descripcion = "En qué celdas está la asociación que el ji-cuadrado detectó.")

  # --- Explicabilidad ----------------------------------------------------
  registrar_artefacto("f4.explicabilidad.coeficientes", "Coeficientes estimados",
    grafico = "R/graficos/g_explicabilidad.R::graficar_coeficientes",
    logica  = "R/logica/metricas_regresion.R::tabla_coeficientes",
    descripcion = "Estimación, error estándar e intervalo, por variable.")

  registrar_artefacto("f4.explicabilidad.importancia", "Importancia por permutación",
    grafico = "R/graficos/g_explicabilidad.R::graficar_importancia",
    logica  = "R/logica/explicabilidad.R::importancia_permutacion",
    descripcion = "Cuánto empeora el modelo al barajar cada variable.")

  registrar_artefacto("f4.explicabilidad.pdp", "Dependencia parcial (PDP / ICE)",
    grafico = "R/graficos/g_explicabilidad.R::graficar_pdp",
    logica  = "R/logica/explicabilidad.R::dependencia_parcial",
    descripcion = "El efecto marginal de una variable, promediando el resto.")

  registrar_artefacto("f4.explicabilidad.local", "Explicación local (LIME / SHAP)",
    grafico = "R/graficos/g_explicabilidad.R::graficar_explicacion_local",
    logica  = "R/logica/explicabilidad.R::explicar_observacion",
    descripcion = "Por qué el modelo predijo ESO para ESTA observación.")

  registrar_artefacto("f4.explicabilidad.cargas", "Cargas",
    grafico = "R/graficos/g_explicabilidad.R::graficar_cargas",
    logica  = "R/logica/metricas_reduccion.R::cargas",
    descripcion = "Cuánto pesa cada variable original en cada componente.")

  registrar_artefacto("f4.explicabilidad.biplot", "Biplot",
    grafico = "R/graficos/g_explicabilidad.R::graficar_biplot",
    logica  = "R/logica/metricas_reduccion.R::coordenadas_biplot",
    descripcion = "Observaciones y variables en el mismo plano factorial.")

  registrar_artefacto("f4.explicabilidad.circulo_correlaciones", "Círculo de correlaciones",
    grafico = "R/graficos/g_explicabilidad.R::graficar_circulo",
    logica  = "R/logica/metricas_reduccion.R::correlaciones_componentes",
    descripcion = "Correlación de cada variable con las dos primeras componentes.")

  registrar_artefacto("f4.explicabilidad.mapa_2d", "Mapa en dos dimensiones",
    grafico = "R/graficos/g_explicabilidad.R::graficar_mapa_2d",
    logica  = "R/logica/metricas_reduccion.R::coordenadas_2d",
    descripcion = "La proyección al plano, coloreada por grupo o por etiqueta.")

  registrar_artefacto("f4.explicabilidad.series_por_grupo", "Series por grupo",
    grafico = "R/graficos/g_explicabilidad.R::graficar_series_grupo",
    logica  = "R/logica/metricas_grupos.R::centroides_series",
    descripcion = "Las curvas de cada grupo con su centroide superpuesto.")

  registrar_artefacto("f4.explicabilidad.grafo", "Grafo de comunidades",
    grafico = "R/graficos/g_explicabilidad.R::graficar_grafo",
    logica  = "R/logica/grafos.R::construir_grafo",
    descripcion = "Nodos coloreados por comunidad; el umbral cambia todo.")

  registrar_artefacto("f4.explicabilidad.heatmap_bicluster", "Mapa de calor de biclusters",
    grafico = "R/graficos/g_explicabilidad.R::graficar_heatmap_bicluster",
    logica  = "R/logica/metricas_grupos.R::biclusters",
    descripcion = "Bloques de filas y columnas que se comportan igual.")

  registrar_artefacto("f4.explicabilidad.efectos_aleatorios", "Efectos aleatorios",
    grafico = "R/graficos/g_explicabilidad.R::graficar_efectos_aleatorios",
    logica  = "R/logica/metricas_mixtos.R::efectos_aleatorios",
    descripcion = "Cuánto se desvía cada grupo del comportamiento promedio.")

  # --- Comparación entre corridas ----------------------------------------
  registrar_artefacto("f4.comparacion.metricas", "Métricas lado a lado",
    grafico = "R/graficos/g_comparacion.R::tabla_comparacion",
    logica  = "R/logica/comparacion.R::comparar_corridas",
    descripcion = "Las corridas seleccionadas, una fila cada una.")

  registrar_artefacto("f4.comparacion.hiperparametros", "Hiperparámetros contra métrica",
    grafico = "R/graficos/g_comparacion.R::graficar_paralelas_hiper",
    logica  = "R/logica/comparacion.R::rejilla_hiperparametros",
    descripcion = "Coordenadas paralelas de un barrido; qué combinación ganó.")

  invisible(TRUE)
}
