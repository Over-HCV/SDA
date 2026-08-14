e# learn/R/ui/fase1/datos.R
#
# Fase 1 · Datos. Todo lo que se le hace a los datos, en orden.
#
# Hito 1: las seis subsecciones más ▣ Análisis existen y se navegan, vacías.
# El contenido real llega en el Hito 2, una subsección por archivo dentro de
# esta misma carpeta (C2).

SUBSECCIONES_DATOS <- c("Fuente", "Diccionario", "Calidad", "Transformación",
                        "Partición", "Balanceo", ETIQUETA_ANALISIS)

DETALLE_DATOS <- list(
  "Fuente" = paste("Cargar charcoal o twins, generar datos sintéticos con",
                   "semilla, o subir un CSV."),
  "Diccionario" = paste("Una fila por columna: etiqueta, escala de medición,",
                        "clase y rol. La escala decide qué gráfico y qué",
                        "operación tienen sentido, así que desde acá se",
                        "habilita o deshabilita el resto de la UI."),
  "Calidad" = paste("Patrón de faltantes (MCAR/MAR/MNAR), imputación,",
                    "duplicados y atípicos por IQR, z o Mahalanobis."),
  "Transformación" = paste("Centrar, escalar, log, Box-Cox, dummies. Pila",
                           "ordenada con deshacer y comparación antes/después."),
  "Partición" = "Train/test, k-fold y estratificación, con su semilla.",
  "Balanceo" = paste("Sub y sobre-muestreo, SMOTE, bootstrap y pesos de clase,",
                     "con los sintéticos marcados en la nube."))
DETALLE_DATOS[[ETIQUETA_ANALISIS]] <- paste(
  "Univariado, bivariado y multivariado. Es donde vive la mayor parte de los",
  "gráficos del curso: histograma, densidad kernel, boxplot, dispersión,",
  "matriz de correlación, coordenadas paralelas, elipsoide y Q-Q de",
  "Mahalanobis.")

mod_datos_ui <- function(id) {
  fase_pendiente(SUBSECCIONES_DATOS, "Hito 2", DETALLE_DATOS)
}

mod_datos_server <- function(id, almacen) {
  servidor_pendiente(id)
}
