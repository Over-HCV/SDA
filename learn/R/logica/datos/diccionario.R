# learn/R/logica/datos/diccionario.R
#
# Responsabilidad: hacer que la escala de medición mande sobre la UI.
#
# El diccionario nace en nucleo/estado.R (diccionario_inicial). Acá vive todo
# lo que se pregunta sobre él: qué operaciones tienen sentido para una escala,
# qué combinaciones son sospechosas, y cómo se edita una fila sin mutar nada.
#
# Sin esto, la app dejaría calcular la media de un código postal.

#' Qué se puede hacer con una columna según su escala de medición.
#'
#' El orden nominal < ordinal < intervalo < razón es acumulativo: lo que vale
#' para una escala vale para todas las de más arriba.
#'
#' @return list(estadisticos, graficos, razon)
operaciones_permitidas <- function(escala) {
  switch(escala,
    nominal = list(
      estadisticos = c("conteo", "moda", "proporcion"),
      graficos = c("barras", "mosaico", "contingencia"),
      razon = paste("Nominal: las categorías no tienen orden, solo identidad.",
                    "Promediarlas no significa nada.")),
    ordinal = list(
      estadisticos = c("conteo", "moda", "proporcion", "mediana", "cuantiles"),
      graficos = c("barras", "mosaico", "contingencia", "boxplot", "ojiva"),
      razon = paste("Ordinal: hay orden pero las distancias no son",
                    "comparables, así que la mediana sí y la media no.")),
    intervalo = list(
      estadisticos = c("conteo", "moda", "proporcion", "mediana", "cuantiles",
                       "media", "desviacion", "asimetria", "curtosis"),
      graficos = c("barras", "mosaico", "contingencia", "boxplot", "ojiva",
                   "histograma", "densidad", "dispersion", "qq"),
      razon = paste("Intervalo: las diferencias son comparables pero el cero",
                    "es convencional, así que un cociente no se interpreta.")),
    razon = list(
      estadisticos = c("conteo", "moda", "proporcion", "mediana", "cuantiles",
                       "media", "desviacion", "asimetria", "curtosis",
                       "coeficiente_variacion", "media_geometrica"),
      graficos = c("barras", "mosaico", "contingencia", "boxplot", "ojiva",
                   "histograma", "densidad", "dispersion", "qq", "violin"),
      razon = "Razón: hay cero absoluto, así que los cocientes se interpretan."),
    list(estadisticos = character(0), graficos = character(0),
         razon = paste0("Escala desconocida: ", escala)))
}

#' TRUE si la operación tiene sentido para esa escala. Lo que la UI consulta
#' antes de habilitar un control.
permite_operacion <- function(escala, operacion) {
  permitidas <- operaciones_permitidas(escala)
  operacion %in% c(permitidas$estadisticos, permitidas$graficos)
}

#' Por qué un control está deshabilitado. Nunca se deshabilita en silencio.
razon_de_bloqueo <- function(escala, operacion) {
  if (permite_operacion(escala, operacion)) return(NULL)
  sprintf("%s no aplica a una escala %s. %s", operacion, escala,
          operaciones_permitidas(escala)$razon)
}

#' Conflictos entre lo que el usuario declaró y lo que dicen los datos.
#'
#' Devuelve la misma forma que consume lista_avisos(): severidad, mensaje y
#' sugerencia. Vacío significa diccionario sano.
avisos_diccionario <- function(diccionario) {
  avisos <- list()
  agregar <- function(severidad, mensaje, sugerencia = NA_character_) {
    avisos[[length(avisos) + 1L]] <<-
      list(severidad = severidad, mensaje = mensaje, sugerencia = sugerencia)
  }
  if (is.null(diccionario) || !nrow(diccionario)) {
    agregar("error", "El diccionario está vacío.", "Cargá un dataset primero.")
    return(avisos)
  }

  for (i in seq_len(nrow(diccionario))) {
    fila <- diccionario[i, ]
    if (!fila$escala %in% ESCALAS)
      agregar("error", sprintf("'%s' tiene una escala desconocida: %s",
                               fila$columna, fila$escala),
              paste("Escalas válidas:", paste(ESCALAS, collapse = ", ")))
    if (!fila$clase %in% CLASES)
      agregar("error", sprintf("'%s' tiene una clase desconocida: %s",
                               fila$columna, fila$clase),
              paste("Clases válidas:", paste(CLASES, collapse = ", ")))
    if (!fila$rol %in% ROLES)
      agregar("error", sprintf("'%s' tiene un rol desconocido: %s",
                               fila$columna, fila$rol),
              paste("Roles válidos:", paste(ROLES, collapse = ", ")))
    if (fila$clase == "cualitativa" && fila$escala %in% c("intervalo", "razon"))
      agregar("aviso", sprintf("'%s' es cualitativa y la marcaste %s",
                               fila$columna, fila$escala),
              "Una cualitativa suele ser nominal u ordinal.")
    if (fila$clase == "discreta" && fila$escala == "razon" &&
        isTRUE(fila$n_unicos > 0) && grepl("(?i)ano|year|fecha", fila$columna, perl = TRUE))
      agregar("aviso", sprintf("marcaste '%s' como razón; parece un año",
                               fila$columna),
              "Un año es escala de intervalo: el cero no es ausencia.")
    if (fila$faltantes_pct >= 40)
      agregar("aviso", sprintf("'%s' tiene %.1f%% de faltantes",
                               fila$columna, fila$faltantes_pct),
              "Imputar tanto inventa estructura; considerá descartarla.")
    if (fila$rol == "predictor" && isTRUE(fila$n_unicos == 1L))
      agregar("aviso", sprintf("'%s' es constante", fila$columna),
              "Una constante no aporta información: rol 'ignorar'.")
  }

  respuestas <- sum(diccionario$rol == "respuesta")
  if (respuestas > 1L)
    agregar("aviso", sprintf("hay %d columnas marcadas como respuesta", respuestas),
            "Los métodos supervisados esperan una sola.")
  avisos
}

#' Edita una celda del diccionario sin mutar el original. Recalcula la clase
#' cuando cambia la escala, para que no queden pares imposibles.
actualizar_diccionario <- function(diccionario, columna, campo, valor) {
  fila <- which(diccionario$columna == columna)
  if (!length(fila)) stop("columna fuera del diccionario: ", columna)
  copia <- diccionario
  copia[fila, campo] <- valor
  if (identical(campo, "escala") && valor %in% c("nominal", "ordinal") &&
      copia$clase[fila] == "continua")
    copia$clase[fila] <- "cualitativa"
  copia
}
