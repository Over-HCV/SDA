# learn/R/nucleo/artefactos/preparacion.R
#
# Artefactos de las seis subsecciones de preparación de la fase 1: lo que se
# le HACE a los datos, antes de mirarlos en ▣ Análisis.
#
# Pertenecen a la fase y no a un método: se ven sin haber elegido nada en el
# catálogo, y por eso `artefactos_sin_metodo()` los lista sin que sea un error.

poblar_artefactos_preparacion <- function() {

  # --- Fuente ------------------------------------------------------------
  registrar_artefacto("f1.fuente.vista_previa", "Vista previa del dataset",
    grafico = "R/ui/f1/fuente.R::salida_fuente",
    logica  = "R/logica/datos_fuente.R::cargar_fuente",
    descripcion = "Las primeras filas de lo que se cargó, con su pie de conteo.")

  # --- Diccionario -------------------------------------------------------
  registrar_artefacto("f1.diccionario.tabla", "Diccionario de columnas",
    grafico = "R/ui/f1/diccionario.R::salida_diccionario",
    logica  = "R/logica/datos_diccionario.R::avisos_diccionario",
    descripcion = "Escala, clase y rol por columna. La escala decide qué operación tiene sentido.")

  # --- Calidad -----------------------------------------------------------
  registrar_artefacto("f1.calidad.matriz_nulidad", "Matriz de nulidad",
    grafico = "R/graficos/g_calidad.R::graficar_nulidad",
    logica  = "R/logica/datos_calidad.R::patron_faltantes",
    descripcion = "Dónde faltan datos y si los huecos van juntos (MCAR/MAR/MNAR).")

  registrar_artefacto("f1.calidad.atipicos", "Atípicos detectados",
    grafico = "R/graficos/g_calidad.R::graficar_atipicos",
    logica  = "R/logica/datos_calidad.R::detectar_atipicos",
    descripcion = "Puntos marcados por IQR, z o Mahalanobis. Atípico no es error.")

  registrar_artefacto("f1.calidad.duplicados", "Filas duplicadas",
    grafico = "R/ui/f1/calidad.R::salida_duplicados",
    logica  = "R/logica/datos_calidad.R::marcar_duplicados",
    descripcion = "Qué filas se repiten y cuántas veces. No se borra nada solo.")

  # --- Transformación ----------------------------------------------------
  registrar_artefacto("f1.transformacion.antes_despues", "Antes y después",
    grafico = "R/graficos/g_preparacion.R::graficar_antes_despues",
    logica  = "R/logica/datos_transformacion.R::aplicar_transformaciones",
    descripcion = "La misma variable con y sin la pila aplicada; se compara la forma.")

  registrar_artefacto("f1.transformacion.perfil_boxcox", "Perfil de lambda (Box-Cox)",
    grafico = "R/graficos/g_preparacion.R::graficar_perfil_boxcox",
    logica  = "R/logica/datos_transformacion.R::perfil_boxcox",
    descripcion = "Log-verosimilitud contra lambda; la curva importa más que el punto.")

  # --- Partición ---------------------------------------------------------
  registrar_artefacto("f1.particion.tamanos", "Tamaño de cada parte",
    grafico = "R/graficos/g_preparacion.R::graficar_particion",
    logica  = "R/logica/datos_particion.R::resumir_particion",
    descripcion = "Barra apilada de entrenamiento, prueba o pliegues, con su semilla.")

  registrar_artefacto("f1.particion.balance", "Balance por partición",
    grafico = "R/graficos/g_preparacion.R::graficar_balance_particion",
    logica  = "R/logica/datos_particion.R::balance_por_particion",
    descripcion = "La prueba de que la estratificación conservó la distribución.")

  # --- Balanceo ----------------------------------------------------------
  registrar_artefacto("f1.balanceo.frecuencias", "Frecuencias por clase",
    grafico = "R/graficos/g_calidad.R::graficar_balance",
    logica  = "R/logica/datos_balanceo.R::resumir_balance",
    descripcion = "Antes y después del remuestreo, con la razón de desbalance.")

  registrar_artefacto("f1.balanceo.nube_sinteticos", "Nube con filas remuestreadas",
    grafico = "R/graficos/g_preparacion.R::graficar_nube_sinteticos",
    logica  = "R/logica/datos_balanceo.R::balancear",
    descripcion = "Las filas repetidas marcadas: sobre-muestrear no consigue datos nuevos.")

  invisible(TRUE)
}
