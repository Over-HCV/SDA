# learn/R/nucleo/artefactos/exploracion.R
#
# Artefactos de las fases 1 (Datos), 2 (Modelado) y 3 (Ajuste).
#
# Los de la fase 1 pertenecen a la fase, no a un método: se pueden mirar sin
# haber elegido nada. Los de la fase 2 muestran el modelo ANTES de ajustarlo.
# Los de la fase 3 muestran el optimizador trabajando.

poblar_artefactos_exploracion <- function() {

  # --- Fase 1 · Análisis univariado -------------------------------------
  registrar_artefacto("f1.analisis.histograma", "Histograma",
    grafico = "graficos/g_univariado.R::graficar_histograma",
    logica  = "logica/resumen_univariado.R::resumir_variable",
    descripcion = "Frecuencias por intervalo. El ancho de clase cambia la historia.")

  registrar_artefacto("f1.analisis.densidad", "Densidad kernel",
    grafico = "graficos/g_univariado.R::graficar_densidad",
    logica  = "logica/densidad.R::estimar_densidad",
    descripcion = "Versión suavizada del histograma; h controla sesgo y varianza.")

  registrar_artefacto("f1.analisis.boxplot", "Diagrama de caja",
    grafico = "graficos/g_univariado.R::graficar_boxplot",
    logica  = "logica/resumen_univariado.R::resumir_variable",
    descripcion = "Resumen de cinco números más las cercas y los atípicos.")

  registrar_artefacto("f1.analisis.boxplot_grupos", "Cajas comparadas por grupo",
    grafico = "graficos/g_univariado.R::graficar_boxplot_grupos",
    logica  = "logica/resumen_univariado.R::resumir_por_grupo",
    descripcion = "La misma variable partida por un factor; el paso previo al ANOVA.")

  registrar_artefacto("f1.analisis.qq_normal_datos", "Q-Q normal de la variable",
    grafico = "graficos/g_univariado.R::graficar_qq",
    logica  = "logica/normalidad.R::evaluar_normalidad",
    descripcion = "Cuantiles observados contra los de una normal ajustada.")

  # --- Fase 1 · Análisis bivariado --------------------------------------
  registrar_artefacto("f1.analisis.dispersion", "Diagrama de dispersión",
    grafico = "graficos/g_bivariado.R::graficar_dispersion",
    logica  = "logica/asociacion.R::medir_asociacion",
    descripcion = "Dos variables cruzadas; con jitter y transparencia contra el sobreploteo.")

  registrar_artefacto("f1.analisis.densidad_conjunta", "Densidad conjunta",
    grafico = "graficos/g_bivariado.R::graficar_densidad_conjunta",
    logica  = "logica/densidad.R::estimar_densidad_2d",
    descripcion = "Curvas de nivel de la densidad bivariada.")

  registrar_artefacto("f1.analisis.mosaico", "Gráfico de mosaico",
    grafico = "graficos/g_bivariado.R::graficar_mosaico",
    logica  = "logica/contingencia.R::tabla_contingencia",
    descripcion = "Asociación entre dos categóricas; el área es la frecuencia.")

  # --- Fase 1 · Análisis multivariado -----------------------------------
  registrar_artefacto("f1.analisis.matriz_dispersion", "Matriz de dispersión",
    grafico = "graficos/g_multivariado.R::graficar_pares",
    logica  = "logica/asociacion.R::matriz_correlacion",
    descripcion = "Todos los pares a la vez; el primer vistazo a p > 2.")

  registrar_artefacto("f1.analisis.heatmap_correlacion", "Mapa de calor de correlaciones",
    grafico = "graficos/g_multivariado.R::graficar_heatmap_correlacion",
    logica  = "logica/asociacion.R::matriz_correlacion",
    descripcion = "La matriz R con reordenamiento; los bloques delatan redundancia.")

  registrar_artefacto("f1.analisis.coordenadas_paralelas", "Coordenadas paralelas",
    grafico = "graficos/g_multivariado.R::graficar_coordenadas_paralelas",
    logica  = "logica/asociacion.R::normalizar_columnas",
    descripcion = "Cada observación es una línea que cruza todos los ejes.")

  registrar_artefacto("f1.analisis.elipsoide", "Elipsoide de concentración",
    grafico = "graficos/g_multivariado.R::graficar_elipsoide",
    logica  = "logica/distancias.R::elipsoide_concentracion",
    descripcion = "La forma de la nube: ejes principales y estructura de correlación.")

  registrar_artefacto("f1.analisis.qq_mahalanobis", "Q-Q de distancias de Mahalanobis",
    grafico = "graficos/g_multivariado.R::graficar_qq_mahalanobis",
    logica  = "logica/distancias.R::mahalanobis_cuadrado",
    descripcion = "Chequeo de normalidad multivariada; las colas delatan atípicos.")

  # --- Fase 1 · Calidad --------------------------------------------------
  registrar_artefacto("f1.calidad.matriz_nulidad", "Matriz de nulidad",
    grafico = "graficos/g_calidad.R::graficar_nulidad",
    logica  = "logica/datos_calidad.R::patron_faltantes",
    descripcion = "Dónde faltan datos y si los huecos van juntos (MCAR/MAR/MNAR).")

  registrar_artefacto("f1.calidad.atipicos", "Atípicos detectados",
    grafico = "graficos/g_calidad.R::graficar_atipicos",
    logica  = "logica/datos_calidad.R::detectar_atipicos",
    descripcion = "Puntos marcados por IQR, z o Mahalanobis. Atípico no es error.")

  registrar_artefacto("f1.balanceo.frecuencias", "Frecuencias por clase",
    grafico = "graficos/g_calidad.R::graficar_balance",
    logica  = "logica/datos_balanceo.R::resumir_balance",
    descripcion = "Antes y después del remuestreo, con los sintéticos marcados.")

  # --- Fase 2 · Geometría antes de ajustar -------------------------------
  registrar_artefacto("f2.analisis.espacio_hipotesis", "Espacio de hipótesis",
    grafico = "graficos/g_modelo.R::graficar_espacio_hipotesis",
    logica  = "logica/modelo_geometria.R::familia_candidatas",
    descripcion = "El repertorio de curvas que el modelo PUEDE producir, sin ajustar nada.")

  registrar_artefacto("f2.analisis.modelo_manual", "Modelo manual",
    grafico = "graficos/g_modelo.R::graficar_modelo_manual",
    logica  = "logica/modelo_geometria.R::evaluar_objetivo",
    descripcion = "Vos movés los parámetros y ves subir y bajar el error. Sos el optimizador.")

  registrar_artefacto("f2.analisis.superficie_perdida", "Superficie de pérdida",
    grafico = "graficos/g_modelo.R::graficar_superficie_perdida",
    logica  = "logica/modelo_geometria.R::malla_objetivo",
    descripcion = "La objetivo sobre dos parámetros, con el mínimo marcado.")

  registrar_artefacto("f2.analisis.frontera_decision", "Frontera de decisión",
    grafico = "graficos/g_modelo.R::graficar_frontera",
    logica  = "logica/modelo_geometria.R::malla_decision",
    descripcion = "Dónde el clasificador cambia de opinión.")

  registrar_artefacto("f2.analisis.presupuesto_parametros", "Presupuesto de parámetros",
    grafico = "graficos/g_modelo.R::graficar_presupuesto",
    logica  = "logica/modelo_geometria.R::contar_parametros",
    descripcion = "Cuántos parámetros vas a estimar contra cuántas observaciones tenés.")

  registrar_artefacto("f2.analisis.curva_potencia", "Curva de potencia",
    grafico = "graficos/g_modelo.R::graficar_potencia",
    logica  = "logica/potencia.R::calcular_potencia",
    descripcion = "Potencia frente a n y al tamaño del efecto.")

  # --- Fase 3 · El optimizador trabajando --------------------------------
  registrar_artefacto("f3.analisis.convergencia", "Traza de convergencia",
    grafico = "graficos/g_convergencia.R::graficar_convergencia",
    logica  = "logica/traza.R::registrar_iteracion",
    descripcion = "La función objetivo por iteración. Responde: ¿convergió o se agotó?")

  registrar_artefacto("f3.analisis.trayectoria", "Trayectoria de parámetros",
    grafico = "graficos/g_convergencia.R::graficar_trayectoria",
    logica  = "logica/traza.R::traza_a_tabla",
    descripcion = "Cada parámetro contra la iteración; cuál tardó en estabilizarse.")

  registrar_artefacto("f3.analisis.camino_superficie", "Camino sobre la superficie",
    grafico = "graficos/g_convergencia.R::graficar_camino",
    logica  = "logica/traza.R::traza_a_tabla",
    descripcion = "El recorrido del optimizador dibujado sobre el mapa de pérdida.")

  registrar_artefacto("f3.analisis.sensibilidad_semilla", "Sensibilidad a la semilla",
    grafico = "graficos/g_convergencia.R::graficar_reinicios",
    logica  = "logica/traza.R::comparar_reinicios",
    descripcion = "N reinicios superpuestos. ¿Óptimo local o global?")

  registrar_artefacto("f3.analisis.ruta_regularizacion", "Ruta de regularización",
    grafico = "graficos/g_convergencia.R::graficar_ruta_lambda",
    logica  = "logica/regularizacion.R::ruta_coeficientes",
    descripcion = "Los coeficientes contra λ. Se ve cuándo muere cada variable.")

  registrar_artefacto("f3.analisis.perfil_verosimilitud", "Perfil de verosimilitud",
    grafico = "graficos/g_convergencia.R::graficar_perfil",
    logica  = "logica/verosimilitud.R::perfil_parametro",
    descripcion = "La log-verosimilitud barriendo un parámetro; el máximo es la estimación.")

  registrar_artefacto("f3.analisis.curva_aprendizaje", "Curva de aprendizaje",
    grafico = "graficos/g_convergencia.R::graficar_curva_aprendizaje",
    logica  = "logica/validacion.R::curva_aprendizaje",
    descripcion = "Error de ajuste y de validación contra n. ¿Faltan datos o falta modelo?")

  invisible(TRUE)
}
