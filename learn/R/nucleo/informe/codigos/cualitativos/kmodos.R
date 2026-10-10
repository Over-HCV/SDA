# learn/R/nucleo/informe/codigos/cualitativos/kmodos.R
#
# Responsabilidad: el código R autónomo que ajusta k-modas en el cuaderno.
#
# Es el algoritmo de `metodos/kmodos.R` (Huang, 1998) sin la contabilidad
# que el lab lleva para sus vistas: las frecuencias por grupo que hacen O(1)
# cada mudanza se cambian por recalcular las modas, que con cien filas es
# instantáneo y se lee de un vistazo. El sorteo del arranque y el orden de
# los pasos son los mismos, así que con la misma semilla sale la misma
# partición (lo comprueba test_informe_cualitativo.R).
#
# Solo Huang: la inicialización de Cao y la aleatoria se quedan en el lab, y
# el cuaderno lo dice en vez de correr otra cosa en silencio.

.KMODAS_DEFINICION <- r"---(
# K-modas (Huang, 1998), escrito a mano. Es k-medias con dos piezas
# cambiadas: la distancia cuenta en cuántas variables difieren
# dos filas, y el centro de cada grupo es su moda, variable por
# variable.
kmodas_una <- function(codigos, niveles, k, semilla, maxit) {
  set.seed(semilla)
  # La moda de cada grupo: la categoría más frecuente de cada
  # variable (en un empate gana el primer nivel).
  modas_de <- function(g) t(sapply(seq_len(k), function(j)
    sapply(seq_len(ncol(codigos)), function(v)
      which.max(tabulate(codigos[g == j, v], niveles[v])))))
  costo <- function(g, m) sum(codigos != m[g, , drop = FALSE])
  # Arranque de Huang: sortear k filas candidatas (cada variable
  # según la frecuencia de sus categorías) y cambiar cada una por la
  # fila real distinta más parecida que nadie haya tomado.
  distintas <- codigos[!duplicated(codigos), , drop = FALSE]
  candidatas <- matrix(sapply(seq_len(ncol(codigos)), function(v) {
    tabla <- table(distintas[, v])
    as.integer(names(tabla))[sample.int(length(tabla), k,
      replace = TRUE, prob = as.numeric(tabla))]
  }), nrow = k)
  libres <- seq_len(nrow(distintas))
  modas <- matrix(0L, k, ncol(codigos))
  for (j in seq_len(k)) {
    lejania <- rowSums(distintas[libres, , drop = FALSE] !=
                       rep(candidatas[j, ], each = length(libres)))
    cercanas <- libres[lejania == min(lejania)]
    elegida <- cercanas[sample.int(length(cercanas), 1)]
    modas[j, ] <- distintas[elegida, ]
    libres <- setdiff(libres, elegida)
  }
  # Asignar cada fila a la moda con que menos discrepa y recalcular.
  lejos <- sapply(seq_len(k), function(j)
    rowSums(codigos != rep(modas[j, ], each = nrow(codigos))))
  grupos <- max.col(-lejos, ties.method = "first")
  modas <- modas_de(grupos)
  traza <- costo(grupos, modas)
  historia <- matrix(grupos)
  for (barrido in seq_len(maxit)) {
    movidas <- 0
    for (i in seq_len(nrow(codigos))) {
      d <- colSums(t(modas) != codigos[i, ])
      origen <- grupos[i]
      destino <- which.min(d)
      # Se muda solo si mejora ESTRICTAMENTE, y el último miembro
      # no se va: un grupo vacío no tendría moda.
      if (d[destino] >= d[origen] || sum(grupos == origen) == 1)
        next
      grupos[i] <- destino
      modas <- modas_de(grupos)  # las modas tocadas, en el acto
      movidas <- movidas + 1
    }
    traza <- c(traza, costo(grupos, modas))
    historia <- cbind(historia, grupos)
    if (movidas == 0) break  # un barrido sin mudanzas: convergió
  }
  list(grupos = grupos, modas = modas, costo = costo(grupos, modas),
       traza = traza, historia = historia)
}

# Varios arranques (semilla, semilla + 1, ...): k-modas cae en
# óptimos locales, y se queda el de menor costo.
kmodas <- function(x, k, reinicios = 10, semilla = 42,
                   maxit = 100) {
  codigos <- sapply(x, as.integer)  # cada categoría, su número
  niveles <- sapply(x, nlevels)
  intentos <- lapply(semilla + seq_len(reinicios) - 1, function(s)
    kmodas_una(codigos, niveles, k, s, maxit))
  mejor <- intentos[[which.min(sapply(intentos, `[[`, "costo"))]]
  # Los números de grupo son arbitrarios: g1 es el más grande y, a
  # igual tamaño, el que aparece primero (la regla del lab).
  orden <- order(-tabulate(mejor$grupos, k),
                 match(seq_len(k), mejor$grupos))
  modas <- as.data.frame(lapply(seq_along(x), function(v)
    levels(x[[v]])[mejor$modas[orden, v]]), col.names = names(x))
  list(grupos = setNames(match(mejor$grupos, orden), rownames(x)),
       k = k, x = x, modas = modas, costo = mejor$costo,
       traza = mejor$traza,
       trazas = lapply(intentos, `[[`, "traza"),
       criterio = "costo (desacuerdos con la moda)",
       eje = "barrido",
       asignaciones = matrix(match(mejor$historia, orden), nrow(x)))
}
)---"

#' @return list(definicion, objeto, llamada)
.cq_ajuste_kmodos <- function(k, reinicios, semilla, maxit) {
  objeto <- sprintf("kmodas%d", k)
  list(definicion = .cq_texto(.KMODAS_DEFINICION), objeto = objeto,
       llamada = c(sprintf("%s <- kmodas(cuali, k = %d, reinicios = %d,",
                           objeto, k, reinicios),
                   sprintf("%ssemilla = %d, maxit = %d)",
                           strrep(" ", nchar(objeto) + 11L), semilla,
                           maxit)))
}
