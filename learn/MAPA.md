<!-- GENERADO por learn/R/mapa.R. No editar a mano. -->

# MAPA — índice de artefactos y métodos

Traducción de lo que se ve en pantalla a los archivos que lo produjeron.
Si te preguntan por un resultado, empezá por acá: buscá la clave, abrí
primero la **lógica** (de ahí sale el número), después el **gráfico** (cómo
se dibuja) y por último el **texto** (qué se le dijo al usuario).

Todas las rutas son relativas a `learn/`.

## Resumen

- **Métodos**: 54 registrados — 0 activos, 48 pendientes, 6 bloqueados
- **Artefactos**: 79 registrados
- **Textos escritos**: 2 de 79
- **Fichas escritas**: 3 de 54

## Artefactos

Clave: `fase.subseccion.artefacto`. Un texto *pendiente* significa que el
`.md` todavía no está escrito; la UI lo avisa y no falla.

| Clave | Artefacto | Gráfico | Lógica | Texto |
|---|---|---|---|---|
| `f1.analisis.boxplot` | Diagrama de caja | `R/graficos/g_univariado.R::graficar_boxplot` | `R/logica/resumen_univariado.R::resumir_variable` | *pendiente* |
| `f1.analisis.boxplot_grupos` | Cajas comparadas por grupo | `R/graficos/g_univariado.R::graficar_boxplot_grupos` | `R/logica/resumen_univariado.R::resumir_por_grupo` | *pendiente* |
| `f1.analisis.coordenadas_paralelas` | Coordenadas paralelas | `R/graficos/g_multivariado.R::graficar_coordenadas_paralelas` | `R/logica/asociacion.R::normalizar_columnas` | *pendiente* |
| `f1.analisis.densidad` | Densidad kernel | `R/graficos/g_univariado.R::graficar_densidad` | `R/logica/densidad.R::estimar_densidad` | *pendiente* |
| `f1.analisis.densidad_conjunta` | Densidad conjunta | `R/graficos/g_bivariado.R::graficar_densidad_conjunta` | `R/logica/densidad.R::estimar_densidad_2d` | *pendiente* |
| `f1.analisis.dispersion` | Diagrama de dispersión | `R/graficos/g_bivariado.R::graficar_dispersion` | `R/logica/asociacion.R::medir_asociacion` | *pendiente* |
| `f1.analisis.elipsoide` | Elipsoide de concentración | `R/graficos/g_multivariado.R::graficar_elipsoide` | `R/logica/distancias.R::elipsoide_concentracion` | *pendiente* |
| `f1.analisis.heatmap_correlacion` | Mapa de calor de correlaciones | `R/graficos/g_multivariado.R::graficar_heatmap_correlacion` | `R/logica/asociacion.R::matriz_correlacion` | *pendiente* |
| `f1.analisis.histograma` | Histograma | `R/graficos/g_univariado.R::graficar_histograma` | `R/logica/resumen_univariado.R::resumir_variable` | `textos/f1.analisis.histograma.md` |
| `f1.analisis.matriz_dispersion` | Matriz de dispersión | `R/graficos/g_multivariado.R::graficar_pares` | `R/logica/asociacion.R::matriz_correlacion` | *pendiente* |
| `f1.analisis.mosaico` | Gráfico de mosaico | `R/graficos/g_bivariado.R::graficar_mosaico` | `R/logica/contingencia.R::tabla_contingencia` | *pendiente* |
| `f1.analisis.qq_mahalanobis` | Q-Q de distancias de Mahalanobis | `R/graficos/g_multivariado.R::graficar_qq_mahalanobis` | `R/logica/distancias.R::mahalanobis_cuadrado` | *pendiente* |
| `f1.analisis.qq_normal_datos` | Q-Q normal de la variable | `R/graficos/g_univariado.R::graficar_qq` | `R/logica/normalidad.R::evaluar_normalidad` | *pendiente* |
| `f1.balanceo.frecuencias` | Frecuencias por clase | `R/graficos/g_calidad.R::graficar_balance` | `R/logica/datos_balanceo.R::resumir_balance` | *pendiente* |
| `f1.balanceo.nube_sinteticos` | Nube con filas remuestreadas | `R/graficos/g_preparacion.R::graficar_nube_sinteticos` | `R/logica/datos_balanceo.R::balancear` | *pendiente* |
| `f1.calidad.atipicos` | Atípicos detectados | `R/graficos/g_calidad.R::graficar_atipicos` | `R/logica/datos_calidad.R::detectar_atipicos` | *pendiente* |
| `f1.calidad.duplicados` | Filas duplicadas | `R/ui/f1/calidad.R::salida_duplicados` | `R/logica/datos_calidad.R::marcar_duplicados` | *pendiente* |
| `f1.calidad.matriz_nulidad` | Matriz de nulidad | `R/graficos/g_calidad.R::graficar_nulidad` | `R/logica/datos_calidad.R::patron_faltantes` | *pendiente* |
| `f1.diccionario.tabla` | Diccionario de columnas | `R/ui/f1/diccionario.R::salida_diccionario` | `R/logica/datos_diccionario.R::avisos_diccionario` | *pendiente* |
| `f1.fuente.vista_previa` | Vista previa del dataset | `R/ui/f1/fuente.R::salida_fuente` | `R/logica/datos_fuente.R::cargar_fuente` | *pendiente* |
| `f1.particion.balance` | Balance por partición | `R/graficos/g_preparacion.R::graficar_balance_particion` | `R/logica/datos_particion.R::balance_por_particion` | *pendiente* |
| `f1.particion.tamanos` | Tamaño de cada parte | `R/graficos/g_preparacion.R::graficar_particion` | `R/logica/datos_particion.R::resumir_particion` | *pendiente* |
| `f1.transformacion.antes_despues` | Antes y después | `R/graficos/g_preparacion.R::graficar_antes_despues` | `R/logica/datos_transformacion.R::aplicar_transformaciones` | *pendiente* |
| `f1.transformacion.perfil_boxcox` | Perfil de lambda (Box-Cox) | `R/graficos/g_preparacion.R::graficar_perfil_boxcox` | `R/logica/datos_transformacion.R::perfil_boxcox` | *pendiente* |
| `f2.analisis.curva_potencia` | Curva de potencia | `R/graficos/g_modelo.R::graficar_potencia` | `R/logica/potencia.R::calcular_potencia` | *pendiente* |
| `f2.analisis.espacio_hipotesis` | Espacio de hipótesis | `R/graficos/g_modelo.R::graficar_espacio_hipotesis` | `R/logica/modelo_geometria.R::familia_candidatas` | *pendiente* |
| `f2.analisis.frontera_decision` | Frontera de decisión | `R/graficos/g_modelo.R::graficar_frontera` | `R/logica/modelo_geometria.R::malla_decision` | *pendiente* |
| `f2.analisis.modelo_manual` | Modelo manual | `R/graficos/g_modelo.R::graficar_modelo_manual` | `R/logica/modelo_geometria.R::evaluar_objetivo` | *pendiente* |
| `f2.analisis.presupuesto_parametros` | Presupuesto de parámetros | `R/graficos/g_modelo.R::graficar_presupuesto` | `R/logica/modelo_geometria.R::contar_parametros` | *pendiente* |
| `f2.analisis.superficie_perdida` | Superficie de pérdida | `R/graficos/g_modelo.R::graficar_superficie_perdida` | `R/logica/modelo_geometria.R::malla_objetivo` | *pendiente* |
| `f3.analisis.camino_superficie` | Camino sobre la superficie | `R/graficos/g_convergencia.R::graficar_camino` | `R/logica/traza.R::traza_a_tabla` | *pendiente* |
| `f3.analisis.convergencia` | Traza de convergencia | `R/graficos/g_convergencia.R::graficar_convergencia` | `R/logica/traza.R::registrar_iteracion` | `textos/f3.analisis.convergencia.md` |
| `f3.analisis.curva_aprendizaje` | Curva de aprendizaje | `R/graficos/g_convergencia.R::graficar_curva_aprendizaje` | `R/logica/validacion.R::curva_aprendizaje` | *pendiente* |
| `f3.analisis.perfil_verosimilitud` | Perfil de verosimilitud | `R/graficos/g_convergencia.R::graficar_perfil` | `R/logica/verosimilitud.R::perfil_parametro` | *pendiente* |
| `f3.analisis.ruta_regularizacion` | Ruta de regularización | `R/graficos/g_convergencia.R::graficar_ruta_lambda` | `R/logica/regularizacion.R::ruta_coeficientes` | *pendiente* |
| `f3.analisis.sensibilidad_semilla` | Sensibilidad a la semilla | `R/graficos/g_convergencia.R::graficar_reinicios` | `R/logica/traza.R::comparar_reinicios` | *pendiente* |
| `f3.analisis.trayectoria` | Trayectoria de parámetros | `R/graficos/g_convergencia.R::graficar_trayectoria` | `R/logica/traza.R::traza_a_tabla` | *pendiente* |
| `f4.comparacion.hiperparametros` | Hiperparámetros contra métrica | `R/graficos/g_comparacion.R::graficar_paralelas_hiper` | `R/logica/comparacion.R::rejilla_hiperparametros` | *pendiente* |
| `f4.comparacion.metricas` | Métricas lado a lado | `R/graficos/g_comparacion.R::tabla_comparacion` | `R/logica/comparacion.R::comparar_corridas` | *pendiente* |
| `f4.desempeno.ajuste` | Ajuste sobre los datos | `R/graficos/g_desempeno.R::graficar_ajuste` | `R/logica/metricas_regresion.R::metricas_regresion` | *pendiente* |
| `f4.desempeno.calibracion` | Curva de calibración | `R/graficos/g_desempeno.R::graficar_calibracion` | `R/logica/metricas_clasificacion.R::calibracion` | *pendiente* |
| `f4.desempeno.distribucion_bootstrap` | Distribución bootstrap | `R/graficos/g_desempeno.R::graficar_bootstrap` | `R/logica/remuestreo.R::distribucion_bootstrap` | *pendiente* |
| `f4.desempeno.distribucion_nula` | Distribución nula | `R/graficos/g_desempeno.R::graficar_nula` | `R/logica/remuestreo.R::distribucion_permutacion` | *pendiente* |
| `f4.desempeno.intervalos_tukey` | Intervalos de Tukey | `R/graficos/g_desempeno.R::graficar_tukey` | `R/logica/metricas_anova.R::comparaciones_multiples` | *pendiente* |
| `f4.desempeno.matriz_confusion` | Matriz de confusión | `R/graficos/g_desempeno.R::graficar_confusion` | `R/logica/metricas_clasificacion.R::matriz_confusion` | *pendiente* |
| `f4.desempeno.precision_exhaustividad` | Precisión-exhaustividad | `R/graficos/g_desempeno.R::graficar_pr` | `R/logica/metricas_clasificacion.R::calcular_pr` | *pendiente* |
| `f4.desempeno.region_confianza` | Región de confianza | `R/graficos/g_desempeno.R::graficar_region_confianza` | `R/logica/metricas_multivariada.R::region_hotelling` | *pendiente* |
| `f4.desempeno.roc` | Curva ROC | `R/graficos/g_desempeno.R::graficar_roc` | `R/logica/metricas_clasificacion.R::calcular_roc` | *pendiente* |
| `f4.desempeno.tabla_anova` | Tabla ANOVA | `R/graficos/g_desempeno.R::tabla_anova_formateada` | `R/logica/metricas_anova.R::descomponer_varianza` | *pendiente* |
| `f4.desempeno.tabla_contingencia` | Tabla de contingencia | `R/graficos/g_desempeno.R::tabla_contingencia_formateada` | `R/logica/contingencia.R::tabla_contingencia` | *pendiente* |
| `f4.desempeno.tamano_efecto` | Tamaño del efecto | `R/graficos/g_desempeno.R::graficar_tamano_efecto` | `R/logica/metricas_anova.R::tamano_efecto` | *pendiente* |
| `f4.diagnostico.bic` | BIC por modelo | `R/graficos/g_diagnostico.R::graficar_bic` | `R/logica/metricas_grupos.R::bic_mezclas` | *pendiente* |
| `f4.diagnostico.codo` | Codo de la inercia | `R/graficos/g_diagnostico.R::graficar_codo` | `R/logica/metricas_grupos.R::inercia_por_k` | *pendiente* |
| `f4.diagnostico.cofenetico` | Correlación cofenética | `R/graficos/g_diagnostico.R::graficar_cofenetico` | `R/logica/metricas_grupos.R::cofenetico` | *pendiente* |
| `f4.diagnostico.dendrograma` | Dendrograma | `R/graficos/g_diagnostico.R::graficar_dendrograma` | `R/logica/metricas_grupos.R::arbol_jerarquico` | *pendiente* |
| `f4.diagnostico.esfericidad` | Esfericidad | `R/graficos/g_diagnostico.R::graficar_esfericidad` | `R/logica/metricas_anova.R::prueba_esfericidad` | *pendiente* |
| `f4.diagnostico.homocedasticidad` | Escala-localización | `R/graficos/g_diagnostico.R::graficar_escala_localizacion` | `R/logica/diagnostico_regresion.R::prueba_homocedasticidad` | *pendiente* |
| `f4.diagnostico.indices_internos` | Índices internos | `R/graficos/g_diagnostico.R::graficar_indices` | `R/logica/metricas_grupos.R::indices_internos` | *pendiente* |
| `f4.diagnostico.influyentes` | Observaciones influyentes | `R/graficos/g_diagnostico.R::graficar_influyentes` | `R/logica/diagnostico_regresion.R::medidas_influencia` | *pendiente* |
| `f4.diagnostico.knn_distancias` | Distancias al k-ésimo vecino | `R/graficos/g_diagnostico.R::graficar_knn_distancias` | `R/logica/metricas_grupos.R::distancias_knn` | *pendiente* |
| `f4.diagnostico.qq_mahalanobis` | Q-Q de Mahalanobis (residual) | `R/graficos/g_diagnostico.R::graficar_qq_mahalanobis` | `R/logica/distancias.R::mahalanobis_cuadrado` | *pendiente* |
| `f4.diagnostico.qq_normal` | Q-Q normal de residuos | `R/graficos/g_diagnostico.R::graficar_qq_residuos` | `R/logica/normalidad.R::evaluar_normalidad` | *pendiente* |
| `f4.diagnostico.residuos` | Residuos contra ajustados | `R/graficos/g_diagnostico.R::graficar_residuos` | `R/logica/diagnostico_regresion.R::calcular_residuos` | *pendiente* |
| `f4.diagnostico.residuos_estandarizados` | Residuos estandarizados | `R/graficos/g_diagnostico.R::graficar_residuos_contingencia` | `R/logica/contingencia.R::residuos_estandarizados` | *pendiente* |
| `f4.diagnostico.scree` | Gráfico de sedimentación | `R/graficos/g_diagnostico.R::graficar_scree` | `R/logica/metricas_reduccion.R::varianza_explicada` | *pendiente* |
| `f4.diagnostico.silueta` | Silueta | `R/graficos/g_diagnostico.R::graficar_silueta` | `R/logica/metricas_grupos.R::silueta` | *pendiente* |
| `f4.diagnostico.vif` | Factor de inflación de varianza | `R/graficos/g_diagnostico.R::graficar_vif` | `R/logica/diagnostico_regresion.R::calcular_vif` | *pendiente* |
| `f4.explicabilidad.biplot` | Biplot | `R/graficos/g_explicabilidad.R::graficar_biplot` | `R/logica/metricas_reduccion.R::coordenadas_biplot` | *pendiente* |
| `f4.explicabilidad.cargas` | Cargas | `R/graficos/g_explicabilidad.R::graficar_cargas` | `R/logica/metricas_reduccion.R::cargas` | *pendiente* |
| `f4.explicabilidad.circulo_correlaciones` | Círculo de correlaciones | `R/graficos/g_explicabilidad.R::graficar_circulo` | `R/logica/metricas_reduccion.R::correlaciones_componentes` | *pendiente* |
| `f4.explicabilidad.coeficientes` | Coeficientes estimados | `R/graficos/g_explicabilidad.R::graficar_coeficientes` | `R/logica/metricas_regresion.R::tabla_coeficientes` | *pendiente* |
| `f4.explicabilidad.efectos_aleatorios` | Efectos aleatorios | `R/graficos/g_explicabilidad.R::graficar_efectos_aleatorios` | `R/logica/metricas_mixtos.R::efectos_aleatorios` | *pendiente* |
| `f4.explicabilidad.grafo` | Grafo de comunidades | `R/graficos/g_explicabilidad.R::graficar_grafo` | `R/logica/grafos.R::construir_grafo` | *pendiente* |
| `f4.explicabilidad.heatmap_bicluster` | Mapa de calor de biclusters | `R/graficos/g_explicabilidad.R::graficar_heatmap_bicluster` | `R/logica/metricas_grupos.R::biclusters` | *pendiente* |
| `f4.explicabilidad.importancia` | Importancia por permutación | `R/graficos/g_explicabilidad.R::graficar_importancia` | `R/logica/explicabilidad.R::importancia_permutacion` | *pendiente* |
| `f4.explicabilidad.local` | Explicación local (LIME / SHAP) | `R/graficos/g_explicabilidad.R::graficar_explicacion_local` | `R/logica/explicabilidad.R::explicar_observacion` | *pendiente* |
| `f4.explicabilidad.mapa_2d` | Mapa en dos dimensiones | `R/graficos/g_explicabilidad.R::graficar_mapa_2d` | `R/logica/metricas_reduccion.R::coordenadas_2d` | *pendiente* |
| `f4.explicabilidad.pdp` | Dependencia parcial (PDP / ICE) | `R/graficos/g_explicabilidad.R::graficar_pdp` | `R/logica/explicabilidad.R::dependencia_parcial` | *pendiente* |
| `f4.explicabilidad.series_por_grupo` | Series por grupo | `R/graficos/g_explicabilidad.R::graficar_series_grupo` | `R/logica/metricas_grupos.R::centroides_series` | *pendiente* |

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
