# learn/R/logica/metricas_reduccion.R
#
# Responsabilidad: traducir un ajuste de reducción de dimensión a las tablas
# que se dibujan.
#
# El ajuste devuelve matrices; los gráficos quieren data.frames largos. Que la
# traducción viva acá y no dentro del gráfico es lo que permite exportar la
# tabla que hay detrás de cada figura (S2) y probarla sin dibujar nada.
#
# Sirve para ACP y, sin cambios, para cualquier método que devuelva cargas,
# puntuaciones y valores propios: análisis factorial, ACP robusto, MDS métrico.
#
# Las funciones con sufijo `.ajuste_reduccion` son los métodos S3 de las
# genéricas de `metricas.R`: son la cara de esta familia hacia la UI, que no
# sabe ni tiene que saber qué método produjo el ajuste que está pintando. El
# sufijo es el de la FAMILIA y no el del método: el ACP y el ACM declaran los
# dos `ajuste_reduccion` en su clase y contestan por acá sin una vista nueva.

#' Las métricas de un ajuste de reducción, como lista plana.
#'
#' Es lo que va al JSON de la corrida y a las value boxes de la fase 4. Vive en
#' `logica/` y no en `run_headless.R` porque la app y el batch tienen que
#' reportar exactamente los mismos números: si cada uno arma su resumen, la
#' misma corrida da dos respuestas y ninguna se puede citar.
#'
#' Cuando entren métodos de otra familia tendrán su propia función hermana; el
#' nombre dice a qué familia pertenece esta.
metricas_de_corrida.ajuste_reduccion <- function(ajuste) {
  retenidas <- seq_len(ajuste$k)
  list(n = ajuste$n, p = ajuste$p, k = ajuste$k,
       varianza_acumulada = sum(ajuste$varianza_explicada[retenidas]),
       primer_valor_propio = unname(ajuste$valores_propios[1]),
       error_reconstruccion = ajuste$error_reconstruccion,
       error_relativo = ajuste$error_relativo,
       iteraciones = ajuste$iteraciones,
       convergio = isTRUE(ajuste$convergio))
}

#' Varianza explicada por componente y acumulada.
#'
#' @return data.frame(componente, etiqueta, valor_propio, proporcion, acumulada)
varianza_explicada <- function(ajuste) {
  valores <- ajuste$valores_propios
  proporcion <- ajuste$varianza_explicada
  data.frame(componente = seq_along(valores),
             etiqueta = names(valores) %||% paste0("CP", seq_along(valores)),
             valor_propio = as.numeric(valores),
             proporcion = as.numeric(proporcion),
             acumulada = cumsum(as.numeric(proporcion)))
}

#' Cargas en formato largo: qué pesa cada variable en cada componente.
#'
#' @param componentes cuáles mirar; NULL = las retenidas (`k`)
#' @return data.frame(variable, componente, etiqueta, carga)
cargas <- function(ajuste, componentes = NULL) {
  matriz <- ajuste$cargas
  componentes <- componentes %||% seq_len(ajuste$k)
  componentes <- intersect(componentes, seq_len(ncol(matriz)))
  partes <- lapply(componentes, function(j) {
    data.frame(variable = rownames(matriz), componente = j,
               etiqueta = colnames(matriz)[j], carga = as.numeric(matriz[, j]))
  })
  do.call(rbind, partes)
}

#' Correlación de cada variable con cada componente.
#'
#' Es la carga reescalada: r(xᵢ, CPⱼ) = vᵢⱼ · √λⱼ / sᵢ. Sobre R (datos
#' estandarizados) sᵢ vale 1 y la correlación cae dentro del círculo de radio 1,
#' que es lo que hace legible el círculo de correlaciones. Sobre S no: por eso
#' el gráfico avisa en vez de mentir con un círculo que no aplica.
#'
#' @return data.frame(variable, x, y, radio) para el par de ejes pedido
correlaciones_componentes <- function(ajuste, ejes = c(1L, 2L)) {
  ejes <- .ejes_validos(ajuste, ejes)
  escala <- if (identical(ajuste$matriz, "correlacion")) rep(1, ajuste$p)
            else ajuste$escala
  # Un ACM no tiene una escala por variable: sus coordenadas son de categorias y
  # no correlaciones. No declara esta vista, y si alguien la pide igual, mejor
  # que falle diciendolo que devolver numeros con forma de correlacion.
  if (is.null(escala))
    stop("este ajuste no define escala por variable: el circulo no aplica")
  cor_de <- function(j) ajuste$cargas[, j] * sqrt(ajuste$valores_propios[j]) / escala

  x <- cor_de(ejes[1]); y <- cor_de(ejes[2])
  data.frame(variable = rownames(ajuste$cargas), x = as.numeric(x),
             y = as.numeric(y), radio = sqrt(as.numeric(x)^2 + as.numeric(y)^2))
}

#' Las observaciones en el plano de dos componentes.
#'
#' @param grupo vector con una entrada por fila usada en el ajuste, o NULL
#' @return data.frame(fila, x, y, grupo)
coordenadas_2d.ajuste_reduccion <- function(ajuste, ejes = c(1L, 2L),
                                            grupo = NULL, ...) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntuaciones <- ajuste$puntuaciones
  tabla <- data.frame(fila = seq_len(nrow(puntuaciones)),
                      x = puntuaciones[, ejes[1]],
                      y = puntuaciones[, ejes[2]])
  # Un color continuo no es un grupo. Si el vector entra numérico se conserva
  # numérico y el mapa lo pinta en degradado: colorear por millas por galón y
  # ver cómo se aclara a lo largo de CP1 es lo que demuestra que ese eje ES
  # rendimiento. Volverlo factor daría una leyenda de 32 niveles ilegible.
  recortado <- if (is.null(grupo)) NULL else grupo[seq_len(nrow(tabla))]
  tabla$grupo <- if (is.null(recortado)) factor("todas")
                 else if (is.numeric(recortado)) recortado
                 else factor(recortado)
  tabla
}

#' Puntos y flechas de un biplot, en la misma escala.
#'
#' El biplot superpone dos cosas con unidades distintas: observaciones
#' (puntuaciones) y variables (cargas). Para que se puedan mirar juntas hay que
#' reescalar las flechas; el factor es una decisión de dibujo, no un resultado,
#' así que sale acá y viaja al bloque de contexto.
#'
#' @return list(puntos, flechas, escala_flechas)
coordenadas_biplot <- function(ajuste, ejes = c(1L, 2L), grupo = NULL,
                               escala_flechas = NULL) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntos <- coordenadas_2d(ajuste, ejes, grupo)

  cargas_ejes <- ajuste$cargas[, ejes, drop = FALSE]
  extension_puntos <- max(abs(c(puntos$x, puntos$y)), na.rm = TRUE)
  extension_cargas <- max(abs(cargas_ejes), na.rm = TRUE)
  automatica <- if (extension_cargas > 0) extension_puntos / extension_cargas else 1
  factor <- escala_flechas %||% (automatica * 0.8)

  flechas <- data.frame(variable = rownames(ajuste$cargas),
                        x = as.numeric(cargas_ejes[, 1]) * factor,
                        y = as.numeric(cargas_ejes[, 2]) * factor)
  list(puntos = puntos, flechas = flechas, escala_flechas = factor)
}

#' Regla del umbral acumulado: la primera componente con la que se pasa el
#' umbral. No es una verdad, es una heurística, y el texto del scree lo dice.
#' Las otras dos reglas de la clase están en reglas_k().
componentes_sugeridas <- function(ajuste, umbral_acumulado = 0.8) {
  tabla <- varianza_explicada(ajuste)
  suficientes <- which(tabla$acumulada >= umbral_acumulado)
  if (!length(suficientes)) return(nrow(tabla))
  suficientes[1]
}

#' Las tres reglas para decidir cuántas componentes se quedan.
#'
#' Ninguna gana: dan tres números que casi siempre coinciden, y cuando no
#' coinciden la discrepancia es el resultado. Se devuelven juntas para que la
#' decisión se tome mirando las tres y no la primera que apareció.
#'
#' - **umbral acumulado**: la convención del 80 %.
#' - **Kaiser**: quedarse con λ > 1 porque una variable estandarizada tiene
#'   varianza 1, y una componente que no llega a eso hace menos que una
#'   variable sola. Sobre S (covarianza) el 1 no significa nada y el referente
#'   pasa a ser la media de los valores propios; el detalle lo dice.
#' - **codo**: el vértice del quiebre, medido con la segunda diferencia de los
#'   valores propios — la componente donde la curva deja de caer. Es un juicio
#'   hecho aritmética, no una verdad, y con una caída muy abrupta señala la
#'   primera componente ya plana: una más de las que uno retendría a ojo.
#'
#' @return data.frame(regla, k, detalle)
reglas_k <- function(ajuste, umbral = 0.8) {
  valores <- as.numeric(ajuste$valores_propios)
  tabla <- varianza_explicada(ajuste)
  p <- length(valores)

  sobre_r <- identical(ajuste$matriz, "correlacion")
  corte <- if (sobre_r) 1 else mean(valores)
  k_kaiser <- max(1L, sum(valores > corte))

  fila <- function(regla, k, detalle)
    data.frame(regla = regla, k = as.integer(k), detalle = detalle)

  rbind(
    fila(sprintf("umbral acumulado (%.0f %%)", 100 * umbral),
         componentes_sugeridas(ajuste, umbral),
         sprintf("con esas componentes se acumula %.1f %%",
                 100 * tabla$acumulada[componentes_sugeridas(ajuste, umbral)])),
    fila("Kaiser", k_kaiser, .detalle_kaiser(ajuste, k_kaiser, corte)),
    fila("codo", .codo_valores(valores),
         sprintf("la curva se quiebra mas en la componente %d de %d",
                 .codo_valores(valores), p)))
}

# El 1 de Kaiser es la varianza de una variable estandarizada, así que solo
# significa algo sobre R. Sobre S y sobre la indicadora del ACM el referente es
# la media de los valores propios — que en un ACM vale exactamente 1/Q, el
# umbral que la literatura del método usa.
.detalle_kaiser <- function(ajuste, k, corte) {
  switch(ajuste$matriz %||% "",
    correlacion = sprintf("%d valores propios pasan de 1", k),
    indicadora = sprintf("en un ACM el corte es 1/Q = %.3f, la media", corte),
    sprintf("sobre S el 1 no aplica: el corte es la media (%.3f)", corte))
}

# La segunda diferencia mide cuánto cambia la pendiente; su máximo está en el
# vértice del quiebre. Con menos de tres valores propios no hay curvatura que
# medir y el codo es la primera componente.
.codo_valores <- function(valores) {
  if (length(valores) < 3L) return(1L)
  segundas <- diff(diff(valores))
  as.integer(which.max(segundas) + 1L)
}

.ejes_validos <- function(ajuste, ejes) {
  ejes <- as.integer(ejes)
  if (length(ejes) != 2L) stop("hacen falta exactamente dos ejes")
  if (any(ejes < 1L) || any(ejes > ajuste$k))
    stop(sprintf("solo hay %d componentes retenidas", ajuste$k))
  ejes
}

# ---------------------------------------------------------------------------
# La cara de la familia hacia la UI (genéricas de metricas.R)
# ---------------------------------------------------------------------------

#' El resultado principal de una reducción es cuánto conserva cada componente.
tabla_resultado.ajuste_reduccion <- function(ajuste) varianza_explicada(ajuste)

grafico_resultado.ajuste_reduccion <- function(ajuste, ...) {
  graficar_scree(varianza_explicada(ajuste), k = ajuste$k,
                 reglas = reglas_k(ajuste), ...)
}

resumen_ajuste.ajuste_reduccion <- function(ajuste) {
  retenidas <- seq_len(ajuste$k)
  list("componentes" = sprintf("%d de %d", ajuste$k, ajuste$p),
       "explicado" = sprintf("%.1f %%",
                             100 * sum(ajuste$varianza_explicada[retenidas])),
       "error relativo" = sprintf("%.1f %%", 100 * ajuste$error_relativo))
}

lectura_resultado.ajuste_reduccion <- function(ajuste, umbral = 0.8, ...) {
  umbral <- umbral %||% 0.8
  necesarias <- componentes_sugeridas(ajuste, umbral)
  tabla <- varianza_explicada(ajuste)
  sprintf(paste("Para llegar al %.0f %% hacen falta %d componentes; con las %d",
                "que retuviste llevas %.1f %%."),
          100 * umbral, necesarias, ajuste$k,
          100 * tabla$acumulada[ajuste$k])
}

etiquetas_ejes.ajuste_reduccion <- function(ajuste) {
  colnames(ajuste$cargas)[seq_len(ajuste$k)]
}
