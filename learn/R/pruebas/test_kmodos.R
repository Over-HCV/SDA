# learn/R/pruebas/test_kmodos.R
#
# Responsabilidad: probar k-modas sin Shiny — el motor contra un caso hecho a
# mano, la traza, la semilla y la base Zoo del proyecto final.
#
# Uso:  Rscript learn/R/pruebas/test_kmodos.R
#
# Un archivo por método (C14). Lo que este aporta y test_kmeans.R no puede dar:
# un caso tan chico que la partición, las modas y el costo se calculan con lápiz,
# y una clase real (`tipo` en Zoo) contra la que medir la partición con el
# índice de Rand ajustado.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
# Por si el catálogo todavía no lo registra: la función pura no depende de eso.
if (!exists("ajustar_kmodos", mode = "function"))
  source(ruta_app("metodos", "kmodos.R"))

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

falla <- function(expresion) {
  inherits(tryCatch(expresion, error = function(e) e), "error")
}

# Índice de Rand ajustado (Hubert y Arabie, 1985), local a esta prueba: 1 es la
# misma partición, 0 es lo que daría repartir al azar con esos tamaños.
rand_ajustado <- function(a, b) {
  tabla <- table(a, b)
  pares <- function(x) sum(x * (x - 1) / 2)
  dentro <- pares(tabla)
  filas <- pares(rowSums(tabla))
  columnas <- pares(colSums(tabla))
  esperado <- filas * columnas / pares(sum(tabla))
  (dentro - esperado) / ((filas + columnas) / 2 - esperado)
}

# ---------------------------------------------------------------------------
# El caso hecho a mano
#
#   fila  v1 v2 v3
#    1    a  x  p      grupo A: moda (a, x, p); la fila 3 discrepa en v2
#    2    a  x  p
#    3    a  y  p      costo A = 0 + 0 + 1 = 1
#    4    b  z  q      grupo B: moda (b, z, q); la fila 6 discrepa en v2
#    5    b  z  q
#    6    b  w  q      costo B = 0 + 0 + 1 = 1      costo total = 2
#
# Cualquier otra partición en dos grupos cruza al menos una fila al grupo que
# no comparte ni v1 ni v3, y eso cuesta dos desacuerdos de golpe. Con tamaños
# iguales, el grupo de la fila 1 se llama g1.
# ---------------------------------------------------------------------------
juguete <- data.frame(v1 = c("a", "a", "a", "b", "b", "b"),
                      v2 = c("x", "x", "y", "z", "z", "w"),
                      v3 = c("p", "p", "p", "q", "q", "q"),
                      stringsAsFactors = FALSE)

cat("\n[kmodos · el caso hecho a mano]\n")

for (ini in c("Huang", "Cao", "aleatoria")) {
  a <- ajustar_kmodos(juguete, k = 2L, inicializacion = ini, reinicios = 5L)
  probar(sprintf("%s: la particion es {1,2,3} | {4,5,6}", ini),
         identical(a$grupos, c(1L, 1L, 1L, 2L, 2L, 2L)))
  probar(sprintf("%s: el costo es 2, uno por grupo", ini),
         a$costo == 2 && identical(a$costo_por_grupo, c(1, 1)))
}

a_juguete <- ajustar_kmodos(juguete, k = 2L)
probar("las modas son (a, x, p) y (b, z, q)",
       identical(vapply(a_juguete$modos, as.character, character(2)),
                 matrix(c("a", "b", "x", "z", "p", "q"), nrow = 2L,
                        dimnames = list(NULL, c("v1", "v2", "v3")))))
probar("las modas son factores con los mismos niveles que x",
       all(vapply(names(a_juguete$x), function(v)
         identical(levels(a_juguete$modos[[v]]), levels(a_juguete$x[[v]])),
         logical(1))) && identical(rownames(a_juguete$modos), c("g1", "g2")))

d <- disimilitud_emparejamiento(juguete)
probar("la disimilitud entre filas es un dist con los desacuerdos contados",
       inherits(d, "dist") && as.matrix(d)[1, 3] == 1 &&
         as.matrix(d)[1, 4] == 3 && as.matrix(d)[4, 6] == 1 &&
         as.matrix(d)[1, 2] == 0)
contra_modos <- disimilitud_emparejamiento(a_juguete$x, a_juguete$modos)
probar("contra los modos da n x k, y la suma de los minimos es el costo",
       identical(dim(contra_modos), c(6L, 2L)) &&
         sum(apply(contra_modos, 1L, min)) == a_juguete$costo)

# ---------------------------------------------------------------------------
cat("\n[kmodos · la entrada]\n")

probar("k = 1 falla y explica", falla(ajustar_kmodos(juguete, k = 1L)))
probar("mas grupos que filas distintas falla en vez de duplicar modas",
       falla(ajustar_kmodos(juguete, k = 5L)))
probar("una inicializacion inexistente falla",
       falla(ajustar_kmodos(juguete, k = 2L, inicializacion = "k-means++")))
probar("las filas con faltantes se descartan y se cuentan", {
  con_na <- juguete; con_na$v2[3] <- NA
  a <- ajustar_kmodos(con_na, k = 2L)
  a$filas_descartadas == 1L && a$n == 5L && length(a$grupos) == 5L
})

zoo <- cargar_fuente("zoo")$datos
entrada_zoo <- setdiff(names(zoo), c("animal", "tipo"))

probar("zoo carga 101 x 18 con las quince binarias, patas y tipo como factor",
       identical(dim(zoo), c(101L, 18L)) && is.character(zoo$animal) &&
         all(vapply(zoo[entrada_zoo], is.factor, logical(1))) &&
         nlevels(zoo$tipo) == 7L && nlevels(zoo$patas) == 6L)
probar("zoo esta en el catalogo de fuentes",
       "zoo" %in% fuentes_disponibles()$clave)

probar("una numerica pasada a proposito entra como factor", {
  crudo <- zoo; crudo$patas <- as.integer(as.character(crudo$patas))
  a <- ajustar_kmodos(crudo, columnas = c("patas", "pelo"), k = 2L,
                      reinicios = 1L)
  is.factor(a$x$patas)
})
probar("sin columnas, el identificador sale de las variables y nombra las filas", {
  a <- ajustar_kmodos(zoo, k = 3L, reinicios = 1L)
  !"animal" %in% a$columnas && identical(rownames(a$x)[1:2],
                                         c("aardvark", "antelope"))
})

# ---------------------------------------------------------------------------
cat("\n[kmodos · la traza y la semilla]\n")

ajustes <- lapply(c("Huang", "Cao", "aleatoria"), function(ini)
  ajustar_kmodos(zoo, columnas = entrada_zoo, k = 7L, inicializacion = ini))
names(ajustes) <- c("Huang", "Cao", "aleatoria")
huang <- ajustes$Huang

probar("el costo nunca sube, en cada reinicio de cada inicializacion",
       all(vapply(ajustes, function(a)
         all(vapply(a$trazas_reinicios, traza_monotona, logical(1))),
         logical(1))))
probar("el objetivo de la traza se llama por lo que es",
       identical(huang$traza$objetivo, "disimilitud intra-grupo") &&
         identical(huang$traza$sentido, "desciende"))
probar("la traza arranca en la iteracion 0 y termina en el costo del ajuste", {
  tabla <- traza_a_tabla(huang$traza)
  tabla$iter[1] == 0L && tabla$objetivo[nrow(tabla)] == huang$costo
})
probar("la trayectoria trae una moda por grupo y variable", {
  par <- parametros_a_tabla(huang$traza)
  length(unique(par$parametro)) == 7L * length(entrada_zoo) &&
    "g1_pelo" %in% par$parametro
})
probar("hay una columna de asignaciones por iteracion registrada",
       ncol(huang$asignaciones_por_iter) == nrow(traza_a_tabla(huang$traza)) &&
         identical(huang$asignaciones_por_iter[, ncol(huang$asignaciones_por_iter)],
                   huang$grupos))
probar("las modas de la ultima iteracion de la traza son las del ajuste", {
  par <- parametros_a_tabla(huang$traza)
  ultimo <- par[par$iter == max(par$iter) & grepl("^g2_", par$parametro), ]
  identical(as.integer(ultimo$valor),
            vapply(huang$modos, function(v) as.integer(v[2]), integer(1),
                   USE.NAMES = FALSE))
})
probar("registrar_traza = FALSE no guarda nada y el ajuste sigue valiendo", {
  a <- ajustar_kmodos(zoo, columnas = entrada_zoo, k = 7L,
                      registrar_traza = FALSE)
  is.null(a$traza) && is.null(a$asignaciones_por_iter) &&
    a$costo == huang$costo
})
probar("la misma semilla da exactamente la misma particion",
       identical(ajustar_kmodos(zoo, columnas = entrada_zoo, k = 7L)$grupos,
                 huang$grupos))
probar("con Huang, distintas semillas llegan a costos distintos",
       length(unique(comparar_reinicios(huang$trazas_reinicios)$objetivo_final)) > 1L)
probar("con Cao todos los reinicios arrancan igual y terminan igual",
       length(unique(comparar_reinicios(
         ajustes$Cao$trazas_reinicios)$objetivo_final)) == 1L)
probar("mas reinicios nunca empeoran el costo",
       huang$costo <= ajustar_kmodos(zoo, columnas = entrada_zoo, k = 7L,
                                     reinicios = 3L)$costo)
probar("la semilla ganadora es una de las que se probaron",
       huang$semilla_ganadora %in% (42L + 0:9))

# ---------------------------------------------------------------------------
cat("\n[kmodos · el resultado]\n")

probar("devuelve el contrato compartido de la familia cualitativa",
       all(c("grupos", "k", "n", "p", "tamanos", "x", "columnas",
             "filas_descartadas", "semilla", "modos", "costo",
             "costo_por_grupo", "disimilitud", "inicializacion", "reinicios",
             "maxit", "semilla_ganadora", "iteraciones", "convergio", "traza",
             "trazas_reinicios", "asignaciones_por_iter") %in% names(huang)) &&
         identical(class(huang), c("ajuste_kmodos", "ajuste_cualitativo",
                                   "ajuste_agrupamiento", "ajuste_sda")))
probar("los grupos se numeran por tamano, del mas grande al mas chico",
       !is.unsorted(rev(huang$tamanos)) && sum(huang$tamanos) == huang$n)
probar("el costo por grupo suma el costo", sum(huang$costo_por_grupo) == huang$costo)
probar("cada fila esta con la moda mas cercana (o empatada)", {
  dist_modos <- disimilitud_emparejamiento(huang$x, huang$modos)
  all(dist_modos[cbind(seq_len(huang$n), huang$grupos)] ==
        apply(dist_modos, 1L, min))
})
probar("la moda minimiza los desacuerdos: cambiar una categoria no mejora", {
  mejora <- FALSE
  for (j in seq_len(huang$k)) for (v in huang$columnas) {
    valores <- huang$x[[v]][huang$grupos == j]
    actual <- sum(valores != huang$modos[[v]][j])
    otras <- vapply(levels(valores), function(nivel) sum(valores != nivel),
                    numeric(1))
    if (any(otras < actual)) mejora <- TRUE
  }
  !mejora
})
probar("mas grupos nunca dejan mas costo",
       ajustar_kmodos(zoo, columnas = entrada_zoo, k = 9L)$costo <= huang$costo)

# ---------------------------------------------------------------------------
cat("\n[kmodos · zoo contra la clase real]\n")

for (ini in names(ajustes)) {
  a <- ajustes[[ini]]
  cat(sprintf("  ARI (k = 7, %s) = %.3f · costo %g · %d iteraciones\n",
              ini, rand_ajustado(a$grupos, zoo$tipo), a$costo, a$iteraciones))
}
print(table(tipo = zoo$tipo, grupo = huang$grupos))
probar("la particion de Huang recupera buena parte de la clase real (ARI > 0.5)",
       rand_ajustado(huang$grupos, zoo$tipo) > 0.5)
probar("el ARI de una particion consigo misma es 1",
       abs(rand_ajustado(zoo$tipo, zoo$tipo) - 1) < 1e-12)

cat(sprintf("\n[test_kmodos] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
