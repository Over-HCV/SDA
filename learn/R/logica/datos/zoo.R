# learn/R/logica/datos/zoo.R
#
# Responsabilidad: leer la base Zoo (UCI) del proyecto final y dejarla con cada
# columna en el tipo que su escala pide.
#
# 101 animales, una fila por animal. Quince atributos binarios en "si"/"no",
# `patas` y `tipo`, la clase real (mamifero, ave, reptil, pez, anfibio, insecto,
# invertebrado). Es la base de prueba clásica del agrupamiento cualitativo: hay
# una respuesta conocida contra la que medir la partición, pero el algoritmo no
# la ve.
#
# Dos trampas del archivo, resueltas acá:
#   1. `patas` viene escrita como número (0, 2, 4, 5, 6, 8) y es nominal: un
#      animal de seis patas no es "el triple" de uno de dos, y promediar patas
#      entre una araña y un pez no describe a nadie. Se convierte a factor para
#      que el diccionario la clasifique como cualitativa.
#   2. El nombre "frog" aparecía dos veces en la base original (dos ranas con
#      atributos distintos). La copia de `data/` ya trae la segunda como
#      "frog_1", así que `animal` sirve de etiqueta única de fila.
#
# `tipo` queda como factor pero es la clase real: sirve para validar (índice de
# Rand ajustado, cruce grupo x clase), nunca para agrupar. Meterla como
# variable de entrada es hacer trampa con la respuesta.
#
# La fuente `zoo` la baja primero de Kaggle (overhcv/uci-zoo, descargar_zoo()
# en libs/_comun/R/datos.R) y, sin red, cae a la copia de data/ con un aviso:
# el mismo esquema que ORI y EIA.

#' Ruta a la copia de Zoo incluida en la app.
#'
#' Pasa por ruta_repo() y no por una ruta armada a mano: así resuelve igual en
#' el servidor (<raiz>/data/) y en el bundle wasm (<bundle>/data/).
ruta_zoo <- function() ruta_repo("data", "zoo.csv")

#' Carga Zoo con los tipos corregidos.
#'
#' @param ruta CSV con el esquema de data/zoo.csv
#' @return data.frame de 101 x 18: `animal` texto, el resto factores
cargar_zoo <- function(ruta = ruta_zoo()) {
  df <- utils::read.csv(ruta, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  binarias <- setdiff(names(df), c("animal", "patas", "tipo"))
  # Niveles fijos y en el mismo orden para las quince: con "no" primero, una
  # moda empatada se resuelve igual en todas las columnas.
  for (columna in binarias)
    df[[columna]] <- factor(df[[columna]], levels = c("no", "si"))
  df$patas <- factor(df$patas, levels = sort(unique(df$patas)))
  # El orden de la numeración original de UCI (1 = mamífero ... 7 =
  # invertebrado), para que las tablas de cruce se lean como en la literatura.
  df$tipo <- factor(df$tipo, levels = c("mamifero", "ave", "reptil", "pez",
                                        "anfibio", "insecto", "invertebrado"))
  df$animal <- as.character(df$animal)
  df
}
