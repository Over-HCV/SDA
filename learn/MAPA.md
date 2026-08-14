<!-- GENERADO por learn/R/mapa.R. No editar a mano. -->

# MAPA — índice de artefactos y métodos

Traducción de lo que se ve en pantalla a los archivos que lo produjeron.
Si te preguntan por un resultado, empezá por acá: buscá la clave, abrí
primero la **lógica** (de ahí sale el número), después el **gráfico** (cómo
se dibuja) y por último el **texto** (qué se le dijo al usuario).

Todas las rutas son relativas a `learn/`.

## Resumen

- **Métodos**: 54 registrados — 0 activos, 48 pendientes, 6 bloqueados
- **Artefactos**: 71 registrados
- **Textos escritos**: 0 de 71
- **Fichas escritas**: 0 de 54

## Artefactos

Clave: `fase.subseccion.artefacto`. Un texto *pendiente* significa que el
`.md` todavía no está escrito; la UI lo avisa y no falla.

| Clave | Artefacto | Gráfico | Lógica | Texto |
|---|---|---|---|---|
| `f1.analisis.boxplot` | Diagrama de caja | `graficos/g_univariado.R::graficar_boxplot` | `logica/resumen_univariado.R::resumir_variable` | *pendiente* |
| `f1.analisis.boxplot_grupos` | Cajas comparadas por grupo | `graficos/g_univariado.R::graficar_boxplot_grupos` | `logica/resumen_univariado.R::resumir_por_grupo` | *pendiente* |
| `f1.analisis.coordenadas_paralelas` | Coordenadas paralelas | `graficos/g_multivariado.R::graficar_coordenadas_paralelas` | `logica/asociacion.R::normalizar_columnas` | *pendiente* |
| `f1.analisis.densidad` | Densidad kernel | `graficos/g_univariado.R::graficar_densidad` | `logica/densidad.R::estimar_densidad` | *pendiente* |
| `f1.analisis.densidad_conjunta` | Densidad conjunta | `graficos/g_bivariado.R::graficar_densidad_conjunta` | `logica/densidad.R::estimar_densidad_2d` | *pendiente* |
| `f1.analisis.dispersion` | Diagrama de dispersión | `graficos/g_bivariado.R::graficar_dispersion` | `logica/asociacion.R::medir_asociacion` | *pendiente* |
| `f1.analisis.elipsoide` | Elipsoide de concentración | `graficos/g_multivariado.R::graficar_elipsoide` | `logica/distancias.R::elipsoide_concentracion` | *pendiente* |
| `f1.analisis.heatmap_correlacion` | Mapa de calor de correlaciones | `graficos/g_multivariado.R::graficar_heatmap_correlacion` | `logica/asociacion.R::matriz_correlacion` | *pendiente* |
| `f1.analisis.histograma` | Histograma | `graficos/g_univariado.R::graficar_histograma` | `logica/resumen_univariado.R::resumir_variable` | *pendiente* |
| `f1.analisis.matriz_dispersion` | Matriz de dispersión | `graficos/g_multivariado.R::graficar_pares` | `logica/asociacion.R::matriz_correlacion` | *pendiente* |
| `f1.analisis.mosaico` | Gráfico de mosaico | `graficos/g_bivariado.R::graficar_mosaico` | `logica/contingencia.R::tabla_contingencia` | *pendiente* |
| `f1.analisis.qq_mahalanobis` | Q-Q de distancias de Mahalanobis | `graficos/g_multivariado.R::graficar_qq_mahalanobis` | `logica/distancias.R::mahalanobis_cuadrado` | *pendiente* |
| `f1.analisis.qq_normal_datos` | Q-Q normal de la variable | `graficos/g_univariado.R::graficar_qq` | `logica/normalidad.R::evaluar_normalidad` | *pendiente* |
| `f1.balanceo.frecuencias` | Frecuencias por clase | `graficos/g_calidad.R::graficar_balance` | `logica/datos_balanceo.R::resumir_balance` | *pendiente* |
| `f1.calidad.atipicos` | Atípicos detectados | `graficos/g_calidad.R::graficar_atipicos` | `logica/datos_calidad.R::detectar_atipicos` | *pendiente* |
| `f1.calidad.matriz_nulidad` | Matriz de nulidad | `graficos/g_calidad.R::graficar_nulidad` | `logica/datos_calidad.R::patron_faltantes` | *pendiente* |
| `f2.analisis.curva_potencia` | Curva de potencia | `graficos/g_modelo.R::graficar_potencia` | `logica/potencia.R::calcular_potencia` | *pendiente* |
| `f2.analisis.espacio_hipotesis` | Espacio de hipótesis | `graficos/g_modelo.R::graficar_espacio_hipotesis` | `logica/modelo_geometria.R::familia_candidatas` | *pendiente* |
| `f2.analisis.frontera_decision` | Frontera de decisión | `graficos/g_modelo.R::graficar_frontera` | `logica/modelo_geometria.R::malla_decision` | *pendiente* |
| `f2.analisis.modelo_manual` | Modelo manual | `graficos/g_modelo.R::graficar_modelo_manual` | `logica/modelo_geometria.R::evaluar_objetivo` | *pendiente* |
| `f2.analisis.presupuesto_parametros` | Presupuesto de parámetros | `graficos/g_modelo.R::graficar_presupuesto` | `logica/modelo_geometria.R::contar_parametros` | *pendiente* |
| `f2.analisis.superficie_perdida` | Superficie de pérdida | `graficos/g_modelo.R::graficar_superficie_perdida` | `logica/modelo_geometria.R::malla_objetivo` | *pendiente* |
| `f3.analisis.camino_superficie` | Camino sobre la superficie | `graficos/g_convergencia.R::graficar_camino` | `logica/traza.R::traza_a_tabla` | *pendiente* |
| `f3.analisis.convergencia` | Traza de convergencia | `graficos/g_convergencia.R::graficar_convergencia` | `logica/traza.R::registrar_iteracion` | *pendiente* |
| `f3.analisis.curva_aprendizaje` | Curva de aprendizaje | `graficos/g_convergencia.R::graficar_curva_aprendizaje` | `logica/validacion.R::curva_aprendizaje` | *pendiente* |
| `f3.analisis.perfil_verosimilitud` | Perfil de verosimilitud | `graficos/g_convergencia.R::graficar_perfil` | `logica/verosimilitud.R::perfil_parametro` | *pendiente* |
| `f3.analisis.ruta_regularizacion` | Ruta de regularización | `graficos/g_convergencia.R::graficar_ruta_lambda` | `logica/regularizacion.R::ruta_coeficientes` | *pendiente* |
| `f3.analisis.sensibilidad_semilla` | Sensibilidad a la semilla | `graficos/g_convergencia.R::graficar_reinicios` | `logica/traza.R::comparar_reinicios` | *pendiente* |
| `f3.analisis.trayectoria` | Trayectoria de parámetros | `graficos/g_convergencia.R::graficar_trayectoria` | `logica/traza.R::traza_a_tabla` | *pendiente* |
| `f4.comparacion.hiperparametros` | Hiperparámetros contra métrica | `graficos/g_comparacion.R::graficar_paralelas_hiper` | `logica/comparacion.R::rejilla_hiperparametros` | *pendiente* |
| `f4.comparacion.metricas` | Métricas lado a lado | `graficos/g_comparacion.R::tabla_comparacion` | `logica/comparacion.R::comparar_corridas` | *pendiente* |
| `f4.desempeno.ajuste` | Ajuste sobre los datos | `graficos/g_desempeno.R::graficar_ajuste` | `logica/metricas_regresion.R::metricas_regresion` | *pendiente* |
| `f4.desempeno.calibracion` | Curva de calibración | `graficos/g_desempeno.R::graficar_calibracion` | `logica/metricas_clasificacion.R::calibracion` | *pendiente* |
| `f4.desempeno.distribucion_bootstrap` | Distribución bootstrap | `graficos/g_desempeno.R::graficar_bootstrap` | `logica/remuestreo.R::distribucion_bootstrap` | *pendiente* |
| `f4.desempeno.distribucion_nula` | Distribución nula | `graficos/g_desempeno.R::graficar_nula` | `logica/remuestreo.R::distribucion_permutacion` | *pendiente* |
| `f4.desempeno.intervalos_tukey` | Intervalos de Tukey | `graficos/g_desempeno.R::graficar_tukey` | `logica/metricas_anova.R::comparaciones_multiples` | *pendiente* |
| `f4.desempeno.matriz_confusion` | Matriz de confusión | `graficos/g_desempeno.R::graficar_confusion` | `logica/metricas_clasificacion.R::matriz_confusion` | *pendiente* |
| `f4.desempeno.precision_exhaustividad` | Precisión-exhaustividad | `graficos/g_desempeno.R::graficar_pr` | `logica/metricas_clasificacion.R::calcular_pr` | *pendiente* |
| `f4.desempeno.region_confianza` | Región de confianza | `graficos/g_desempeno.R::graficar_region_confianza` | `logica/metricas_multivariada.R::region_hotelling` | *pendiente* |
| `f4.desempeno.roc` | Curva ROC | `graficos/g_desempeno.R::graficar_roc` | `logica/metricas_clasificacion.R::calcular_roc` | *pendiente* |
| `f4.desempeno.tabla_anova` | Tabla ANOVA | `graficos/g_desempeno.R::tabla_anova_formateada` | `logica/metricas_anova.R::descomponer_varianza` | *pendiente* |
| `f4.desempeno.tabla_contingencia` | Tabla de contingencia | `graficos/g_desempeno.R::tabla_contingencia_formateada` | `logica/contingencia.R::tabla_contingencia` | *pendiente* |
| `f4.desempeno.tamano_efecto` | Tamaño del efecto | `graficos/g_desempeno.R::graficar_tamano_efecto` | `logica/metricas_anova.R::tamano_efecto` | *pendiente* |
| `f4.diagnostico.bic` | BIC por modelo | `graficos/g_diagnostico.R::graficar_bic` | `logica/metricas_grupos.R::bic_mezclas` | *pendiente* |
| `f4.diagnostico.codo` | Codo de la inercia | `graficos/g_diagnostico.R::graficar_codo` | `logica/metricas_grupos.R::inercia_por_k` | *pendiente* |
| `f4.diagnostico.cofenetico` | Correlación cofenética | `graficos/g_diagnostico.R::graficar_cofenetico` | `logica/metricas_grupos.R::cofenetico` | *pendiente* |
| `f4.diagnostico.dendrograma` | Dendrograma | `graficos/g_diagnostico.R::graficar_dendrograma` | `logica/metricas_grupos.R::arbol_jerarquico` | *pendiente* |
| `f4.diagnostico.esfericidad` | Esfericidad | `graficos/g_diagnostico.R::graficar_esfericidad` | `logica/metricas_anova.R::prueba_esfericidad` | *pendiente* |
| `f4.diagnostico.homocedasticidad` | Escala-localización | `graficos/g_diagnostico.R::graficar_escala_localizacion` | `logica/diagnostico_regresion.R::prueba_homocedasticidad` | *pendiente* |
| `f4.diagnostico.indices_internos` | Índices internos | `graficos/g_diagnostico.R::graficar_indices` | `logica/metricas_grupos.R::indices_internos` | *pendiente* |
| `f4.diagnostico.influyentes` | Observaciones influyentes | `graficos/g_diagnostico.R::graficar_influyentes` | `logica/diagnostico_regresion.R::medidas_influencia` | *pendiente* |
| `f4.diagnostico.knn_distancias` | Distancias al k-ésimo vecino | `graficos/g_diagnostico.R::graficar_knn_distancias` | `logica/metricas_grupos.R::distancias_knn` | *pendiente* |
| `f4.diagnostico.qq_mahalanobis` | Q-Q de Mahalanobis (residual) | `graficos/g_diagnostico.R::graficar_qq_mahalanobis` | `logica/distancias.R::mahalanobis_cuadrado` | *pendiente* |
| `f4.diagnostico.qq_normal` | Q-Q normal de residuos | `graficos/g_diagnostico.R::graficar_qq_residuos` | `logica/normalidad.R::evaluar_normalidad` | *pendiente* |
| `f4.diagnostico.residuos` | Residuos contra ajustados | `graficos/g_diagnostico.R::graficar_residuos` | `logica/diagnostico_regresion.R::calcular_residuos` | *pendiente* |
| `f4.diagnostico.residuos_estandarizados` | Residuos estandarizados | `graficos/g_diagnostico.R::graficar_residuos_contingencia` | `logica/contingencia.R::residuos_estandarizados` | *pendiente* |
| `f4.diagnostico.scree` | Gráfico de sedimentación | `graficos/g_diagnostico.R::graficar_scree` | `logica/metricas_reduccion.R::varianza_explicada` | *pendiente* |
| `f4.diagnostico.silueta` | Silueta | `graficos/g_diagnostico.R::graficar_silueta` | `logica/metricas_grupos.R::silueta` | *pendiente* |
| `f4.diagnostico.vif` | Factor de inflación de varianza | `graficos/g_diagnostico.R::graficar_vif` | `logica/diagnostico_regresion.R::calcular_vif` | *pendiente* |
| `f4.explicabilidad.biplot` | Biplot | `graficos/g_explicabilidad.R::graficar_biplot` | `logica/metricas_reduccion.R::coordenadas_biplot` | *pendiente* |
| `f4.explicabilidad.cargas` | Cargas | `graficos/g_explicabilidad.R::graficar_cargas` | `logica/metricas_reduccion.R::cargas` | *pendiente* |
| `f4.explicabilidad.circulo_correlaciones` | Círculo de correlaciones | `graficos/g_explicabilidad.R::graficar_circulo` | `logica/metricas_reduccion.R::correlaciones_componentes` | *pendiente* |
| `f4.explicabilidad.coeficientes` | Coeficientes estimados | `graficos/g_explicabilidad.R::graficar_coeficientes` | `logica/metricas_regresion.R::tabla_coeficientes` | *pendiente* |
| `f4.explicabilidad.efectos_aleatorios` | Efectos aleatorios | `graficos/g_explicabilidad.R::graficar_efectos_aleatorios` | `logica/metricas_mixtos.R::efectos_aleatorios` | *pendiente* |
| `f4.explicabilidad.grafo` | Grafo de comunidades | `graficos/g_explicabilidad.R::graficar_grafo` | `logica/grafos.R::construir_grafo` | *pendiente* |
| `f4.explicabilidad.heatmap_bicluster` | Mapa de calor de biclusters | `graficos/g_explicabilidad.R::graficar_heatmap_bicluster` | `logica/metricas_grupos.R::biclusters` | *pendiente* |
| `f4.explicabilidad.importancia` | Importancia por permutación | `graficos/g_explicabilidad.R::graficar_importancia` | `logica/explicabilidad.R::importancia_permutacion` | *pendiente* |
| `f4.explicabilidad.local` | Explicación local (LIME / SHAP) | `graficos/g_explicabilidad.R::graficar_explicacion_local` | `logica/explicabilidad.R::explicar_observacion` | *pendiente* |
| `f4.explicabilidad.mapa_2d` | Mapa en dos dimensiones | `graficos/g_explicabilidad.R::graficar_mapa_2d` | `logica/metricas_reduccion.R::coordenadas_2d` | *pendiente* |
| `f4.explicabilidad.pdp` | Dependencia parcial (PDP / ICE) | `graficos/g_explicabilidad.R::graficar_pdp` | `logica/explicabilidad.R::dependencia_parcial` | *pendiente* |
| `f4.explicabilidad.series_por_grupo` | Series por grupo | `graficos/g_explicabilidad.R::graficar_series_grupo` | `logica/metricas_grupos.R::centroides_series` | *pendiente* |

## Métodos

| Clave | Método | Sesión | Objetivo | Estado | wasm | Ficha | Nodo teórico |
|---|---|---|---|---|---|---|---|
| `faltantes` | Diagnóstico de datos faltantes | 1 | describir | pendiente | sí | `fichas/faltantes.md` | `020-descriptiva/030-estructura-datos/010-faltantes` |
| `densidad_kernel` | Estimación de densidad kernel | 1 | describir | pendiente | sí | `fichas/densidad_kernel.md` | `040-variables-aleatorias/060-estimacion-densidad/020-kernel` |
| `resumen_univariado` | Resumen univariado | 1 | describir | pendiente | sí | `fichas/resumen_univariado.md` | `020-descriptiva/050-numerico` |
| `potencia` | Análisis de potencia | 2 | contrastar | pendiente | sí | `fichas/potencia.md` | `060-inferencia/050-pruebas-hipotesis/040-potencia` |
| `bootstrap` | Bootstrap | 2 | contrastar | pendiente | sí | `fichas/bootstrap.md` | `060-inferencia/060-remuestreo/010-bootstrap` |
| `permutacion` | Prueba de permutación | 2 | contrastar | pendiente | sí | `fichas/permutacion.md` | `060-inferencia/060-remuestreo/020-permutacion` |
| `normalidad` | Verificación de normalidad | 2 | contrastar | pendiente | sí | `fichas/normalidad.md` | `040-variables-aleatorias/050-normal-detalle/030-verificacion-normalidad` |
| `box_cox` | Transformación de Box-Cox | 2 | describir | pendiente | sí | `fichas/box_cox.md` | `120-regresion/040-multiple/090-transformaciones` |
| `gmm` | Mezclas gaussianas (EM) | 3 | agrupar | pendiente | no | `fichas/gmm.md` | `100-agrupamiento/040-otros-enfoques/020-mezclas-gaussianas` |
| `qda` | Análisis discriminante cuadrático | 3 | clasificar | pendiente | sí | `fichas/qda.md` | `110-clasificacion/020-basados-distribucion/030-qda` |
| `lda` | Análisis discriminante lineal | 3 | clasificar | pendiente | sí | `fichas/lda.md` | `110-clasificacion/020-basados-distribucion/020-lda` |
| `hotelling` | T² de Hotelling | 3 | contrastar | pendiente | sí | `fichas/hotelling.md` | `080-normal-multivariada/060-inferencia-mu/010-hotelling-una-muestra` |
| `copula` | Cópulas | 3 | describir | pendiente | no | `fichas/copula.md` | `050-bivariado/020-conjunta/010-conjunta` |
| `mahalanobis` | Distancia de Mahalanobis | 3 | describir | pendiente | sí | `fichas/mahalanobis.md` | `070-multivariado/050-distancias/030-mahalanobis` |
| `normal_multivariada` | Normal multivariada | 3 | describir | pendiente | sí | `fichas/normal_multivariada.md` | `080-normal-multivariada/020-modelo` |
| `cca` | Correlación canónica | 3 | reducir | pendiente | no | `fichas/cca.md` | `090-reduccion/030-emparentados/030-correlacion-canonica` |
| `acp_faltantes` | ACP con datos faltantes | 4 | reducir | pendiente | no | `fichas/acp_faltantes.md` | `090-reduccion/020-acp` |
| `fpca` | ACP funcional | 4 | reducir | pendiente | no | `fichas/fpca.md` | `150-extensiones/070-datos-funcionales` |
| `acp_robusto` | ACP robusto | 4 | reducir | pendiente | no | `fichas/acp_robusto.md` | `090-reduccion/020-acp/050-decisiones/020-outliers` |
| `acp` | Análisis de componentes principales | 4 | reducir | pendiente | sí | `fichas/acp.md` | `090-reduccion/020-acp` |
| `efa` | Análisis factorial exploratorio | 4 | reducir | pendiente | no | `fichas/efa.md` | `090-reduccion/030-emparentados/010-analisis-factorial` |
| `mds` | Escalamiento multidimensional | 4 | reducir | pendiente | sí | `fichas/mds.md` | `090-reduccion/030-emparentados/020-mds` |
| `kernel_pca` | Kernel PCA | 4 | reducir | pendiente | no | `fichas/kernel_pca.md` | `090-reduccion/030-emparentados/040-no-lineal` |
| `tsne` | t-SNE | 4 | reducir | pendiente | no | `fichas/tsne.md` | `090-reduccion/030-emparentados/040-no-lineal` |
| `umap` | UMAP | 4 | reducir | pendiente | no | `fichas/umap.md` | `090-reduccion/030-emparentados/040-no-lineal` |
| `dtw` | Agrupamiento de series con DTW | 5 | agrupar | pendiente | no | `fichas/dtw.md` | `150-extensiones/030-series-tiempo` |
| `espectral` | Agrupamiento espectral | 5 | agrupar | pendiente | no | `fichas/espectral.md` | `100-agrupamiento/040-otros-enfoques` |
| `jerarquico` | Agrupamiento jerárquico | 5 | agrupar | pendiente | sí | `fichas/jerarquico.md` | `100-agrupamiento/030-jerarquico` |
| `biclustering` | Biclustering | 5 | agrupar | pendiente | no | `fichas/biclustering.md` | `100-agrupamiento/040-otros-enfoques` |
| `dbscan` | DBSCAN | 5 | agrupar | pendiente | sí | `fichas/dbscan.md` | `100-agrupamiento/040-otros-enfoques/010-dbscan` |
| `comunidades` | Detección de comunidades | 5 | agrupar | pendiente | no | `fichas/comunidades.md` | `150-extensiones/090-no-estructurados` |
| `kmeans` | K-medias | 5 | agrupar | pendiente | sí | `fichas/kmeans.md` | `100-agrupamiento/020-kmeans` |
| `validacion_grupos` | Validación de grupos | 5 | agrupar | pendiente | sí | `fichas/validacion_grupos.md` | `100-agrupamiento/050-validacion` |
| `regresion_multiple` | Regresión lineal múltiple | 6 | predecir | pendiente | sí | `fichas/regresion_multiple.md` | `120-regresion/040-multiple` |
| `regresion_simple` | Regresión lineal simple | 6 | predecir | pendiente | sí | `fichas/regresion_simple.md` | `120-regresion/030-simple` |
| `knn` | K vecinos más cercanos | 7 | clasificar | pendiente | sí | `fichas/knn.md` | `110-clasificacion/040-no-parametricos/010-knn` |
| `logistica` | Regresión logística | 7 | clasificar | pendiente | sí | `fichas/logistica.md` | `110-clasificacion/030-basados-regresion/010-logistica` |
| `cuantilica` | Regresión cuantílica | 7 | predecir | pendiente | no | `fichas/cuantilica.md` | `120-regresion/070-extensiones/040-robusta` |
| `lasso` | Regresión regularizada (LASSO / Ridge) | 7 | predecir | pendiente | sí | `fichas/lasso.md` | `120-regresion/070-extensiones/010-regularizacion` |
| `step_aic` | Selección paso a paso (AIC / BIC) | 7 | predecir | pendiente | sí | `fichas/step_aic.md` | `120-regresion/060-seleccion/020-stepwise` |
| `anova_una_via` | ANOVA a una vía | 8 | contrastar | pendiente | sí | `fichas/anova_una_via.md` | `130-anova/030-una-via` |
| `rm_anova` | ANOVA de medidas repetidas | 8 | contrastar | pendiente | no | `fichas/rm_anova.md` | `130-anova/060-disenos/050-medidas-repetidas` |
| `tukey` | Comparaciones múltiples (Tukey HSD) | 8 | contrastar | pendiente | sí | `fichas/tukey.md` | `130-anova/050-comparaciones-multiples/020-tukey` |
| `chi_cuadrado` | Ji-cuadrado de independencia | 8 | contrastar | pendiente | sí | `fichas/chi_cuadrado.md` | `140-contingencia/020-independencia/010-chi-cuadrado` |
| `manova` | MANOVA | 8 | contrastar | pendiente | sí | `fichas/manova.md` | `130-anova/070-manova` |
| `tamano_efecto` | Tamaño del efecto (η², ω²) | 8 | contrastar | pendiente | no | `fichas/tamano_efecto.md` | `130-anova/030-una-via/060-tamano-efecto` |
| `welch` | Welch y Brown-Forsythe | 8 | contrastar | pendiente | sí | `fichas/welch.md` | `130-anova/040-supuestos/030-no-parametricas` |
| `lmer` | Modelos mixtos (efectos aleatorios) | 8 | predecir | pendiente | no | `fichas/lmer.md` | `130-anova/060-disenos/040-efectos-aleatorios` |
| `mlp` | Perceptrón multicapa | — | clasificar | bloqueado | no | `fichas/mlp.md` | `150-extensiones/080-aprendizaje-estadistico` |
| `cnn` | Red convolucional | — | clasificar | bloqueado | no | `fichas/cnn.md` | `150-extensiones/090-no-estructurados` |
| `fundacional` | Modelos fundacionales | — | predecir | bloqueado | no | `fichas/fundacional.md` | `150-extensiones/090-no-estructurados` |
| `bayes_brms` | Regresión bayesiana (MCMC) | — | predecir | bloqueado | no | `fichas/bayes_brms.md` | `150-extensiones/010-bayesiana` |
| `espacial` | Regresión espacial (SAR / SEM) | — | predecir | bloqueado | no | `fichas/espacial.md` | `100-agrupamiento/060-correlacion-espacial` |
| `transformer` | Transformer | — | predecir | bloqueado | no | `fichas/transformer.md` | `150-extensiones/090-no-estructurados` |

## Métodos bloqueados

No se pueden ejecutar aquí. Cada uno lleva un **puente**: la frase que
lo conecta con algo que sí corre en el lab.

| Clave | Método | Motivo | Puente |
|---|---|---|---|
| `bayes_brms` | Regresión bayesiana (MCMC) | rstan no compila a WebAssembly. En la versión de servidor sí puede correr, pero el muestreo MCMC tarda minutos. | El teorema de Bayes de la sesión 2 es el mismo que usa MCMC: previa × verosimilitud ∝ posterior. Lo único que cambia es que la posterior se aproxima muestreando en vez de resolverse en cerrado. |
| `cnn` | Red convolucional | Requiere torch, GPU y datos de imagen; nada de eso está disponible en este entorno. | Una convolución es un filtro local con pesos compartidos: el mismo promedio ponderado que hace un suavizado kernel, pero con los pesos aprendidos en vez de fijados. |
| `espacial` | Regresión espacial (SAR / SEM) | Necesita un shapefile de geometrías que el proyecto no incluye todavía. | El supuesto que rompe es la independencia de los errores. Corré una regresión múltiple sobre charcoal por país y mirá el I de Moran de sus residuos: ahí se ve el problema que este método resuelve. |
| `fundacional` | Modelos fundacionales | No son entrenables en un curso; solo se consumen preentrenados. | El borde real del mapa. Lo que sí se traslada es el método de evaluación: matriz de confusión, validación cruzada y sesgo-varianza valen igual para un modelo de mil millones de parámetros. |
| `mlp` | Perceptrón multicapa | torch no compila a WebAssembly y las redes neuronales quedan fuera del temario del curso. | Un MLP sin capa oculta y con activación sigmoide ES una regresión logística. Corré la logística en el lab, mirá sus coeficientes, y después imaginá una capa más. |
| `transformer` | Transformer | Escala de cómputo fuera del alcance de un curso de 24 horas. | La atención es un promedio ponderado donde los pesos salen de similitudes entre vectores. Mirá la similitud coseno en Distancias (sesión 3): es el mismo producto interno normalizado. |

---

Regenerar: `Rscript learn/R/mapa.R`
