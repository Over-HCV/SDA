# learn/R/logica/datos/transformacion.R
#
# Responsabilidad: la pila de transformaciones y cómo se aplica.
#
# La pila es una lista ordenada de recetas, no de resultados: cada entrada dice
# qué hacer, sobre qué columnas y con qué parámetros. Deshacer es quitar la
# última y volver a aplicar la pila sobre el data.frame original — por eso el
# módulo guarda siempre los datos crudos aparte. Una pila serializable es lo
# que hace que la corrida se reproduzca desde el JSON (S2).

TRANSFORMACIONES <- c("centrar", "escalar", "estandarizar", "logaritmo",
                      "raiz", "boxcox", "dummies")

# El filtro de filas no toca columnas pero comparte pila con las demás
# recetas: es lo que hace que "deshacer", el JSON y el cuaderno exportado lo
# respeten sin casos especiales.
TIPOS_PILA <- c(TRANSFORMACIONES, "filtro")

#' Añade una receta al final de la pila. No toca los datos.
agregar_transformacion <- function(pila, tipo, columnas, params = list()) {
  if (!tipo %in% TIPOS_PILA) stop("transformacion desconocida: ", tipo)
  c(pila, list(list(tipo = tipo, columnas = columnas, params = params)))
}

#' Quita una receta (la última por defecto): el "deshacer" de la subsección.
quitar_transformacion <- function(pila, indice = length(pila)) {
  if (!length(pila) || indice < 1L || indice > length(pila)) return(pila)
  pila[-indice]
}

#' Aplica la pila entera, en orden, sobre los datos crudos.
#'
#' @return list(datos, avisos) — los avisos son de la misma forma que consume
#'   lista_avisos(), porque log de un negativo no puede pasar en silencio
aplicar_transformaciones <- function(datos, pila) {
  avisos <- list()
  for (entrada in pila) {
    resultado <- aplicar_transformacion(datos, entrada$tipo, entrada$columnas,
                                        entrada$params)
    datos <- resultado$datos
    avisos <- c(avisos, resultado$avisos)
  }
  list(datos = datos, avisos = avisos)
}

#' Una sola transformación. Las columnas que no son numéricas se saltan con
#' aviso en vez de romper: el usuario puede haber marcado la columna entera.
aplicar_transformacion <- function(datos, tipo, columnas, params = list()) {
  if (identical(tipo, "filtro"))
    return(aplicar_filtro(datos, columnas[1], params$valores %||% character(0)))
  avisos <- list()
  agregar <- function(severidad, mensaje, sugerencia = NA_character_)
    avisos[[length(avisos) + 1L]] <<-
      list(severidad = severidad, mensaje = mensaje, sugerencia = sugerencia)

  for (columna in intersect(columnas, names(datos))) {
    valores <- datos[[columna]]
    if (identical(tipo, "dummies")) {
      resultado <- .expandir_dummies(datos, columna, params$referencia)
      datos <- resultado$datos
      if (!is.na(resultado$aviso)) agregar("aviso", resultado$aviso)
      next
    }
    if (!is.numeric(valores)) {
      agregar("aviso", sprintf("'%s' no es numerica: se salto %s", columna, tipo),
              "Convertila en Calidad o usa dummies.")
      next
    }
    if (tipo %in% c("logaritmo", "raiz", "boxcox") &&
        any(valores <= 0, na.rm = TRUE)) {
      agregar("aviso", sprintf("'%s' tiene valores <= 0", columna),
              "Se desplazo la columna sumando el minimo + 1 antes de transformar.")
      valores <- valores - min(valores, na.rm = TRUE) + 1
    }
    datos[[columna]] <- switch(tipo,
      centrar = valores - mean(valores, na.rm = TRUE),
      escalar = .escalar(valores),
      estandarizar = .escalar(valores - mean(valores, na.rm = TRUE)),
      logaritmo = log(valores),
      raiz = sqrt(valores),
      boxcox = transformar_boxcox(valores, params$lambda %||% 0))
  }
  list(datos = datos, avisos = avisos)
}

#' Box-Cox con λ dado. λ = 0 es exactamente el logaritmo, y esa continuidad es
#' el punto de la familia.
transformar_boxcox <- function(x, lambda) {
  if (abs(lambda) < 1e-8) log(x) else (x^lambda - 1) / lambda
}

#' Perfil de verosimilitud de λ. El máximo de la curva es el λ sugerido, pero
#' la curva importa más que el punto: si es plana, cualquier λ cercano sirve y
#' conviene el redondo (0, 0.5, 1) porque se interpreta.
#'
#' @return list(curva = data.frame(lambda, loglik), optimo, redondeado)
perfil_boxcox <- function(x, lambdas = seq(-2, 2, by = 0.05)) {
  validos <- x[!is.na(x)]
  if (any(validos <= 0)) validos <- validos - min(validos) + 1
  n <- length(validos)
  if (n < 3L)
    return(list(curva = data.frame(lambda = numeric(0), loglik = numeric(0)),
                optimo = NA_real_, redondeado = NA_real_))

  suma_log <- sum(log(validos))
  loglik <- vapply(lambdas, function(lambda) {
    transformada <- transformar_boxcox(validos, lambda)
    varianza <- stats::var(transformada) * (n - 1) / n
    if (!is.finite(varianza) || varianza <= 0) return(-Inf)
    -n / 2 * log(varianza) + (lambda - 1) * suma_log
  }, numeric(1))

  optimo <- lambdas[which.max(loglik)]
  redondos <- c(-1, -0.5, 0, 0.5, 1, 2)
  list(curva = data.frame(lambda = lambdas, loglik = loglik), optimo = optimo,
       redondeado = redondos[which.min(abs(redondos - optimo))])
}

#' Texto de una entrada de la pila, para la tabla de "qué se aplicó".
describir_transformacion <- function(entrada) {
  if (identical(entrada$tipo, "filtro"))
    return(sprintf("filtro %s en [%s]", entrada$columnas[1],
                   paste(entrada$params$valores, collapse = ", ")))
  detalle <- if (length(entrada$params))
    paste0(" (", paste(names(entrada$params), unlist(entrada$params),
                       sep = "=", collapse = ", "), ")") else ""
  sprintf("%s%s sobre %s", entrada$tipo, detalle,
          paste(entrada$columnas, collapse = ", "))
}

#' Filtra filas por los valores de una columna. Devuelve los datos intactos y
#' un aviso de error cuando el resultado quedaría vacío: un data.frame sin
#' filas rompe todo lo que viene después y en silencio, que es peor.
#'
#' Las filas con NA en la columna quedan fuera del filtro: %in% las descarta.
#' Si eso pasa se avisa, porque "perdió filas" y "no aplicó" se ven igual.
aplicar_filtro <- function(datos, columna, valores) {
  if (!columna %in% names(datos))
    return(list(datos = datos, avisos = list(list(
      severidad = "error",
      mensaje = sprintf("la columna '%s' no existe en los datos", columna),
      sugerencia = "El filtro no se aplicó."))))
  if (!length(valores))
    return(list(datos = datos, avisos = list(list(
      severidad = "error",
      mensaje = "el filtro no trae valores",
      sugerencia = "Marcá al menos un valor en el selector."))))

  quedan <- datos[[columna]] %in% valores
  avisos <- list()
  if (!any(quedan)) return(list(datos = datos, avisos = list(list(
    severidad = "error",
    mensaje = sprintf("ninguna fila tiene %s en [%s]", columna,
                      paste(valores, collapse = ", ")),
    sugerencia = "El filtro no se aplicó: el dataset quedó como estaba."))))
  n_na <- sum(is.na(datos[[columna]]))
  if (n_na)
    avisos <- c(avisos, list(list(
      severidad = "aviso",
      mensaje = sprintf("%d filas con NA en '%s' quedaron fuera del filtro",
                        n_na, columna))))
  list(datos = datos[quedan, , drop = FALSE], avisos = avisos)
}

.escalar <- function(x) {
  desviacion <- stats::sd(x, na.rm = TRUE)
  if (!is.finite(desviacion) || desviacion == 0) x else x / desviacion
}

# Indicadoras con categoría de referencia explícita: k niveles dan k-1
# columnas, y la que falta es la referencia contra la que se leen las demás.
.expandir_dummies <- function(datos, columna, referencia = NULL) {
  niveles <- sort(unique(as.character(datos[[columna]][!is.na(datos[[columna]])])))
  if (length(niveles) < 2L)
    return(list(datos = datos,
                aviso = sprintf("'%s' tiene un solo nivel: no se expandio", columna)))
  if (length(niveles) > 30L)
    return(list(datos = datos,
                aviso = sprintf("'%s' tiene %d niveles: demasiadas dummies",
                                columna, length(niveles))))

  referencia <- referencia %||% niveles[1]
  copia <- datos
  for (nivel in setdiff(niveles, referencia))
    copia[[paste0(columna, "_", nivel)]] <-
      as.integer(as.character(datos[[columna]]) == nivel)
  copia[[columna]] <- NULL
  list(datos = copia, aviso = NA_character_)
}
