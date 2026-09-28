# learn/R/logica/supuestos.R
#
# Responsabilidad: evaluar sobre el dataset actual los supuestos que un método
# declara, ANTES de ajustar.
#
# `registrar_metodo(supuestos = c(...))` hasta ahora solo se imprimía en la
# ficha. Acá cada clave se convierte en una comprobación con veredicto, y el
# semáforo de la fase 2 se dibuja recorriendo el registro: añadir un supuesto a
# un método es añadir una fila, no una vista.
#
# Devuelve avisos con la MISMA forma que contratos.R
# (severidad/clave/mensaje/sugerencia), así que `lista_avisos()` los pinta sin
# una línea de UI nueva. La diferencia con validar_compatibilidad() es de
# momento y de tono: aquel dice si se PUEDE correr, este dice si CONVIENE.

#' Evalúa los supuestos declarados por un método sobre un dataset.
#'
#' @param clave    clave del método en el registro
#' @param dataset  objeto dataset de nucleo/estado.R
#' @param columnas columnas que entrarían al modelo; NULL = las numéricas
#' @return lista de avisos, vacía solo si el método no declara supuestos
evaluar_supuestos <- function(clave, dataset, columnas = NULL) {
  if (is.null(dataset)) return(list())
  m <- metodo(clave)
  if (!length(m$supuestos)) return(list())
  # Las candidatas por defecto las decide el TIPO que el método declara: para un
  # ACM son las cualitativas, y pasarle las numéricas haría fallar todas sus
  # comprobaciones por la razón equivocada.
  columnas <- intersect(
    columnas %||% columnas_admisibles(dataset, m$entrada$tipo %||% "matriz_numerica"),
    names(dataset$df))

  evaluados <- lapply(m$supuestos, function(supuesto) {
    comprobar <- .COMPROBACIONES_SUPUESTO[[supuesto]]
    if (is.null(comprobar)) return(.supuesto_sin_prueba(supuesto))
    comprobar(dataset, columnas)
  })
  Filter(Negate(is.null), evaluados)
}

#' Los supuestos de un método con su nombre legible, hayan o no comprobación.
#' Lo usa la ficha, que los lista aunque no haya dataset cargado.
nombre_supuesto <- function(supuesto) {
  legibles <- c(escalado_previo = "escalado previo",
                estructura_lineal = "estructura lineal",
                solo_cuantitativas = "variables cuantitativas",
                categorias_suficientes = "categorias con suficientes casos",
                sin_atipicos = "sin atipicos influyentes",
                grupos_esfericos = "grupos esfericos",
                tamanos_similares = "tamanos de grupo similares",
                normalidad = "normalidad",
                homocedasticidad = "homocedasticidad",
                independencia = "observaciones independientes")
  legibles[[supuesto]] %||% gsub("_", " ", supuesto)
}

.supuesto_sin_prueba <- function(supuesto) {
  .aviso("aviso", supuesto,
         sprintf("%s: sin comprobacion automatica todavia.",
                 nombre_supuesto(supuesto)),
         "Se declara en el registro; la prueba entra cuando el metodo la use.")
}

# ---------------------------------------------------------------------------
# Una comprobación por supuesto. Cada una devuelve un aviso, nunca lanza.
# ---------------------------------------------------------------------------

# Las comprobaciones que promedian, correlacionan o invierten una matriz solo
# tienen sentido sobre columnas numericas. Antes de que hubiera metodos
# cualitativos, `columnas` ya venia filtrada por la vista; ahora puede traer una
# nominal marcada por error, y el semaforo tiene que decirlo (lo hace
# .supuesto_cuantitativas) en vez de reventar con "'x' must be numeric".
# El nombre lleva el sufijo porque `.numericas_de(ds)` ya existe en la fase 1 y
# toma un solo argumento: dos privadas homonimas en carpetas distintas se
# sobrescriben en silencio al sourcear, y el error sale a 10 archivos de aqui.
.columnas_numericas_de <- function(dataset, columnas)
  intersect(columnas, columnas_numericas(dataset))

.supuesto_escalado <- function(dataset, columnas) {
  columnas <- .columnas_numericas_de(dataset, columnas)
  if (.esta_escalado(dataset))
    return(.aviso("ok", "escalado_previo",
                  "Escalado previo: el dataset esta estandarizado."))
  desviaciones <- vapply(dataset$df[columnas],
                         function(x) stats::sd(x, na.rm = TRUE), numeric(1))
  desviaciones <- desviaciones[is.finite(desviaciones) & desviaciones > 0]
  if (length(desviaciones) < 2L)
    return(.aviso("aviso", "escalado_previo",
                  "Escalado previo: no hay suficientes columnas para juzgarlo."))

  razon <- max(desviaciones) / min(desviaciones)
  if (razon < 3)
    return(.aviso("ok", "escalado_previo",
                  sprintf("Escalado previo: las desviaciones son comparables (la mayor es %.1f veces la menor).",
                          razon)))
  .aviso("aviso", "escalado_previo",
         sprintf("Escalado previo: %s varia %.0f veces mas que %s, y va a dominar el resultado.",
                 names(which.max(desviaciones)), razon,
                 names(which.min(desviaciones))),
         "Descomponer la correlacion (R) equivale a estandarizar, o aplica 'escalar' en Datos - Transformacion.")
}

.supuesto_lineal <- function(dataset, columnas) {
  columnas <- .columnas_numericas_de(dataset, columnas)
  if (length(columnas) < 2L)
    return(.aviso("aviso", "estructura_lineal",
                  "Estructura lineal: hacen falta al menos dos variables numericas."))
  matriz <- stats::cor(dataset$df[columnas], use = "pairwise.complete.obs")
  fuera <- abs(matriz[upper.tri(matriz)])
  fuera <- fuera[is.finite(fuera)]
  if (!length(fuera))
    return(.aviso("aviso", "estructura_lineal",
                  "Estructura lineal: no se pudo calcular la correlacion."))

  maxima <- max(fuera)
  if (maxima < 0.3)
    return(.aviso("aviso", "estructura_lineal",
                  sprintf("Estructura lineal: la correlacion mas alta es %.2f. Con variables casi independientes no hay redundancia que resumir.",
                          maxima),
                  "Mira el mapa de calor en Datos - Analisis: si no hay bloques, reducir no va a ganar mucho."))
  .aviso("ok", "estructura_lineal",
         sprintf("Estructura lineal: hay correlaciones que resumir (la mayor es %.2f).",
                 maxima))
}

.supuesto_atipicos <- function(dataset, columnas) {
  columnas <- .columnas_numericas_de(dataset, columnas)
  if (length(columnas) < 2L)
    return(.aviso("aviso", "sin_atipicos",
                  "Atipicos: hacen falta al menos dos variables numericas."))
  distancias <- mahalanobis_cuadrado(dataset$df, columnas)
  validas <- distancias[!is.na(distancias)]
  if (!length(validas))
    return(.aviso("aviso", "sin_atipicos",
                  "Atipicos: la covarianza es singular, hay colinealidad exacta.",
                  "Quita una de las columnas repetidas en Datos - Diccionario."))

  corte <- stats::qchisq(0.975, df = length(columnas))
  cuantos <- sum(validas > corte)
  proporcion <- cuantos / length(validas)
  if (proporcion <= 0.05)
    return(.aviso("ok", "sin_atipicos",
                  sprintf("Atipicos: %d de %d filas superan el corte chi-cuadrado (%.1f%%), dentro de lo esperable.",
                          cuantos, length(validas), 100 * proporcion)))
  .aviso("aviso", "sin_atipicos",
         sprintf("Atipicos: %d de %d filas (%.1f%%) quedan lejos del centro. La varianza es una media de cuadrados: un punto lejano puede torcer la primera componente el solo.",
                 cuantos, length(validas), 100 * proporcion),
         "Miralos en Datos - Calidad con el criterio de Mahalanobis antes de ajustar.")
}


# k-medias corta el espacio con esferas del mismo tamaño: asigna cada punto al
# centroide más cercano en distancia euclidiana. Si la nube es un cigarro, la
# frontera correcta no es una esfera y la partición sale cortando el cigarro a
# lo ancho. La razón entre el mayor y el menor valor propio de la correlación
# mide justamente eso.
.supuesto_esfericos <- function(dataset, columnas) {
  columnas <- .columnas_numericas_de(dataset, columnas)
  if (length(columnas) < 2L)
    return(.aviso("aviso", "grupos_esfericos",
                  "Grupos esfericos: hacen falta al menos dos variables numericas."))
  matriz <- stats::cor(dataset$df[columnas], use = "pairwise.complete.obs")
  valores <- tryCatch(eigen(matriz, symmetric = TRUE, only.values = TRUE)$values,
                      error = function(e) NULL)
  valores <- valores[is.finite(valores) & valores > 1e-10]
  if (length(valores) < 2L)
    return(.aviso("aviso", "grupos_esfericos",
                  "Grupos esfericos: la correlacion es singular, hay colinealidad exacta.",
                  "Quita una de las columnas repetidas en Datos - Diccionario."))

  razon <- max(valores) / min(valores)
  if (razon < 20)
    return(.aviso("ok", "grupos_esfericos",
                  sprintf("Grupos esfericos: la nube no esta muy alargada (razon de valores propios %.1f).",
                          razon)))
  .aviso("aviso", "grupos_esfericos",
         sprintf("Grupos esfericos: la nube es %.0f veces mas larga en una direccion que en otra. Las esferas de k-medias van a cortarla a lo ancho.",
                 razon),
         "Mira el elipsoide en Datos - Analisis - Multivariado, o reduce con ACP antes de agrupar.")
}

# Antes de ajustar no hay grupos cuyos tamaños comparar. Lo que sí se puede
# mirar es si el dataset da para los grupos que se van a pedir: con n < 2k, el
# tamaño medio de grupo es menor que dos y la partición no significa nada.
.supuesto_tamanos <- function(dataset, columnas) {
  n <- nrow(dataset$df)
  techo <- n %/% 2L
  if (techo < 2L)
    return(.aviso("error", "tamanos_similares",
                  sprintf("Tamanos de grupo similares: con %d filas no alcanza para dos grupos.",
                          n)))
  .aviso("ok", "tamanos_similares",
         sprintf("Tamanos de grupo similares: %d filas dan para k hasta %d sin que un grupo quede con menos de dos observaciones.",
                 n, techo),
         "k-medias parte antes un grupo grande que dejar uno pequeno: revisa los tamanos en Evaluacion - Desempeno.")
}

# El primer supuesto de la clase, y el único que no se puede negociar: una
# correlación sobre una cualitativa promedia códigos y no significa nada. No es
# un error del usuario, es una bifurcación del camino, así que el aviso nombra a
# dónde lleva la otra rama en vez de limitarse a decir que no.
.supuesto_cuantitativas <- function(dataset, columnas) {
  cualitativas <- columnas_cualitativas(dataset)
  if (!length(cualitativas))
    return(.aviso("ok", "solo_cuantitativas",
                  "Variables cuantitativas: todas las columnas lo son."))

  dentro <- intersect(cualitativas, columnas)
  if (length(dentro))
    return(.aviso("error", "solo_cuantitativas",
                  sprintf("Variables cuantitativas: %s son cualitativas y estan marcadas en la especificacion.",
                          paste(dentro, collapse = ", ")),
                  "Desmarcalas en Modelado - Especificacion, o corre un ACM con ellas."))
  .aviso("ok", "solo_cuantitativas",
         sprintf("Variables cuantitativas: %d columna(s) cualitativa(s) quedan fuera del ajuste (%s).",
                 length(cualitativas), paste(cualitativas, collapse = ", ")),
         "Para resumirlas hay un metodo propio: el analisis de correspondencias multiples (ACM).")
}

# El ACM no teme a los atípicos, teme a las categorías raras: una categoría con
# tres casos define un eje ella sola, porque su masa es mínima y su desviación
# respecto a la independencia, enorme.
.supuesto_categorias <- function(dataset, columnas) {
  cualitativas <- intersect(columnas_cualitativas(dataset), columnas)
  if (length(cualitativas) < 2L)
    cualitativas <- columnas_cualitativas(dataset)
  if (length(cualitativas) < 2L)
    return(.aviso("error", "categorias_suficientes",
                  "Categorias: hacen falta al menos dos variables cualitativas.",
                  "Marca la escala de las columnas en Datos - Diccionario."))

  conteos <- lapply(dataset$df[cualitativas], function(x) table(x[!is.na(x)]))
  escasas <- vapply(conteos, function(t) sum(t < 5L), integer(1))
  unicas <- vapply(conteos, length, integer(1))
  if (any(unicas < 2L))
    return(.aviso("error", "categorias_suficientes",
                  sprintf("Categorias: %s tiene una sola categoria y no aporta nada.",
                          paste(names(unicas)[unicas < 2L], collapse = ", ")),
                  "Quitala de la especificacion."))
  if (!sum(escasas))
    return(.aviso("ok", "categorias_suficientes",
                  sprintf("Categorias: %d categorias en %d variables, todas con 5 casos o mas.",
                          sum(unicas), length(cualitativas))))
  .aviso("aviso", "categorias_suficientes",
         sprintf("Categorias: %d categoria(s) con menos de 5 casos (%s). Una categoria rara puede definir un eje ella sola.",
                 sum(escasas), paste(names(escasas)[escasas > 0], collapse = ", ")),
         "Agrupa las categorias chicas en Datos - Transformacion antes de correr.")
}

.COMPROBACIONES_SUPUESTO <- list(
  escalado_previo = .supuesto_escalado,
  solo_cuantitativas = .supuesto_cuantitativas,
  categorias_suficientes = .supuesto_categorias,
  estructura_lineal = .supuesto_lineal,
  sin_atipicos = .supuesto_atipicos,
  grupos_esfericos = .supuesto_esfericos,
  tamanos_similares = .supuesto_tamanos)
