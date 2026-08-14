# learn/R/logica/resumen_univariado.R
#
# Responsabilidad: describir UNA variable, respetando su escala de medición.
#
# Lo que devuelve es una tabla larga (estadistico, valor) en vez de una lista
# de campos, porque así la UI la pinta sin saber qué estadísticos hay: los que
# la escala permita. La media de una nominal no aparece porque no se calcula,
# no porque la UI la esconda.
#
# Siempre sobre el TOTAL de filas, nunca sobre la muestra de dibujo (C8).

#' Estadísticos de una variable, filtrados por escala.
#'
#' @param x vector de datos (con o sin NA)
#' @param escala una de ESCALAS; decide qué se calcula
#' @return data.frame(estadistico, valor, descripcion)
resumir_variable <- function(x, escala = "razon") {
  permitidos <- operaciones_permitidas(escala)$estadisticos
  validos <- x[!is.na(x)]
  n_faltantes <- sum(is.na(x))

  filas <- list(
    .fila_resumen("n", length(validos), "observaciones no faltantes"),
    .fila_resumen("faltantes", n_faltantes, "valores NA"))

  if ("moda" %in% permitidos)
    filas <- c(filas, list(.fila_resumen("moda", .moda(validos),
                                         "valor más frecuente")))
  if (length(validos) && is.numeric(validos)) {
    if ("mediana" %in% permitidos) {
      filas <- c(filas, list(
        .fila_resumen("mediana", stats::median(validos), "percentil 50"),
        .fila_resumen("q1", unname(stats::quantile(validos, 0.25)), "percentil 25"),
        .fila_resumen("q3", unname(stats::quantile(validos, 0.75)), "percentil 75"),
        .fila_resumen("rango_inter", stats::IQR(validos), "q3 - q1"),
        .fila_resumen("minimo", min(validos), "valor menor"),
        .fila_resumen("maximo", max(validos), "valor mayor")))
    }
    if ("media" %in% permitidos) {
      desviacion <- stats::sd(validos)
      filas <- c(filas, list(
        .fila_resumen("media", mean(validos), "promedio aritmetico"),
        .fila_resumen("desviacion", desviacion, "desviacion estandar"),
        .fila_resumen("asimetria", .asimetria(validos), "g1: cola larga"),
        .fila_resumen("curtosis", .curtosis(validos), "g2: exceso sobre normal")))
      if ("coeficiente_variacion" %in% permitidos && mean(validos) != 0)
        filas <- c(filas, list(.fila_resumen(
          "coef_variacion", desviacion / abs(mean(validos)),
          "dispersion relativa al centro")))
    }
  }
  do.call(rbind, filas)
}

#' El mismo resumen partido por una columna de grupo. Es lo que hace legible
#' un boxplot comparado: la caja se mira, la tabla se cita.
resumir_por_grupo <- function(datos, variable, grupo, escala = "razon") {
  niveles <- sort(unique(as.character(datos[[grupo]][!is.na(datos[[grupo]])])))
  filas <- lapply(niveles, function(nivel) {
    trozo <- datos[[variable]][as.character(datos[[grupo]]) == nivel &
                                 !is.na(datos[[grupo]])]
    resumen <- resumir_variable(trozo, escala)
    ancho <- as.list(stats::setNames(resumen$valor, resumen$estadistico))
    data.frame(grupo = nivel,
               n = as.numeric(ancho$n %||% 0),
               media = as.numeric(ancho$media %||% NA),
               mediana = as.numeric(ancho$mediana %||% NA),
               desviacion = as.numeric(ancho$desviacion %||% NA),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, filas)
}

#' Frecuencias de una cualitativa, con acumulada. La ojiva sale de acá.
tabla_frecuencias <- function(x, ordenar = TRUE) {
  conteo <- table(x, useNA = "no")
  if (ordenar) conteo <- sort(conteo, decreasing = TRUE)
  proporcion <- as.numeric(conteo) / sum(conteo)
  data.frame(categoria = names(conteo), n = as.integer(conteo),
             proporcion = proporcion, acumulada = cumsum(proporcion),
             stringsAsFactors = FALSE)
}

# La moda de una nominal es texto y todo lo demás es número: por eso van las
# dos columnas. `valor` es lo que se grafica o se compara; `mostrado` es lo que
# lee el usuario.
.fila_resumen <- function(estadistico, valor, descripcion) {
  numerico <- suppressWarnings(as.numeric(valor))
  data.frame(estadistico = estadistico, valor = numerico,
             mostrado = if (is.na(numerico)) as.character(valor)
                        else format(numerico, digits = 4),
             descripcion = descripcion, stringsAsFactors = FALSE)
}

.moda <- function(x) {
  if (!length(x)) return(NA)
  conteo <- table(x)
  nombre <- names(conteo)[which.max(conteo)]
  if (is.numeric(x)) as.numeric(nombre) else nombre
}

# Asimetría y curtosis muestrales (g1 y g2), sin traer moments ni psych.
.asimetria <- function(x) {
  n <- length(x)
  if (n < 3L) return(NA_real_)
  centrado <- x - mean(x)
  raiz <- sqrt(mean(centrado^2))
  if (raiz == 0) return(NA_real_)
  mean(centrado^3) / raiz^3
}

.curtosis <- function(x) {
  n <- length(x)
  if (n < 4L) return(NA_real_)
  centrado <- x - mean(x)
  raiz <- sqrt(mean(centrado^2))
  if (raiz == 0) return(NA_real_)
  mean(centrado^4) / raiz^4 - 3
}
