# learn/R/pruebas/test_clases_latentes.R
#
# Responsabilidad: probar el modelo de clases latentes de punta a punta sin
# Shiny — el EM, el contrato del ajuste y la selección de k por BIC.
#
# Uso:  Rscript learn/R/pruebas/test_clases_latentes.R
#
# Un archivo por método (C14). Lo que este aporta y k-medias no podía dar:
#
#   · una vara externa. El EM está escrito a mano y poLCA es la referencia del
#     área; la verosimilitud, los parámetros y el BIC tienen que coincidir con
#     los suyos. poLCA se usa SOLO acá, nunca en el método.
#   · una verdad conocida: datos simulados desde un modelo de dos clases, donde
#     "recupera π y θ" es una aserción positiva y no una opinión.
#
# Al final imprime la tabla de BIC del zoológico y el ARI contra `tipo`: no
# son aserciones sino el número que el proyecto final cita.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)

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

# Índice de Rand ajustado, a mano: cero dependencias para un número de diez
# líneas (Hubert y Arabie, 1985).
rand_ajustado <- function(a, b) {
  tabla <- table(a, b)
  pares <- function(v) sum(choose(v, 2))
  indice <- pares(tabla)
  esperado <- pares(rowSums(tabla)) * pares(colSums(tabla)) /
    choose(sum(tabla), 2)
  maximo <- (pares(rowSums(tabla)) + pares(colSums(tabla))) / 2
  (indice - esperado) / (maximo - esperado)
}

# El zoológico, mientras la fuente `zoo` no exista: el CSV crudo, con `patas`
# como factor (0/2/4/5/6/8 patas son categorías, no una escala) y `animal`
# como nombre de fila.
zoo <- utils::read.csv("data/zoo.csv", stringsAsFactors = FALSE)
rownames(zoo) <- zoo$animal
zoo$animal <- NULL
zoo[] <- lapply(zoo, factor)
variables_zoo <- setdiff(names(zoo), "tipo")

# Dos clases conocidas, seis variables. Las probabilidades están separadas pero
# no son 0/1: así el EM tiene que estimarlas y no solo copiarlas.
set.seed(2024)
n_sim <- 3000L
pi_real <- c(0.65, 0.35)
theta_real <- list(
  a = rbind(c(0.85, 0.15), c(0.20, 0.80)),
  b = rbind(c(0.10, 0.90), c(0.75, 0.25)),
  c = rbind(c(0.70, 0.20, 0.10), c(0.10, 0.30, 0.60)),
  d = rbind(c(0.80, 0.20), c(0.30, 0.70)),
  e = rbind(c(0.60, 0.40), c(0.15, 0.85)),
  f = rbind(c(0.20, 0.30, 0.50), c(0.60, 0.30, 0.10)))
clase_real <- sample(1:2, n_sim, replace = TRUE, prob = pi_real)
simulado <- as.data.frame(lapply(theta_real, function(th) {
  valores <- vapply(clase_real, function(c)
    sample.int(ncol(th), 1L, prob = th[c, ]), integer(1))
  factor(letters[valores])
}))

sim <- ajustar_clases_latentes(simulado, k = 2L, reinicios = 5L, k_max = 3L)

# ---------------------------------------------------------------------------
cat("\n[clases latentes · recupera el modelo que genero los datos]\n")

probar("los pesos recuperados estan a menos de 0.03 de los reales",
       max(abs(sim$pesos - pi_real)) < 0.03)

probar("cada theta recuperado esta a menos de 0.06 del real",
       max(vapply(names(theta_real), function(v)
         max(abs(sim$probabilidades[[v]] - theta_real[[v]])),
         numeric(1))) < 0.06)

probar("la particion dura acierta mas del 80 % de las clases reales",
       mean(sim$grupos == clase_real) > 0.8)

probar("el BIC elige k = 2 entre 1 y 3",
       sim$seleccion$k[which.min(sim$seleccion$bic)] == 2L)

# ---------------------------------------------------------------------------
cat("\n[clases latentes · la traza]\n")

probar("la log-verosimilitud nunca baja: la traza es monotona",
       traza_monotona(sim$traza) &&
         all(vapply(sim$trazas_reinicios, traza_monotona, logical(1))))

probar("la traza dice que sube y se llama por lo que es",
       identical(sim$traza$sentido, "asciende") &&
         identical(sim$traza$objetivo, "log-verosimilitud"))

probar("la traza arranca en la iteracion 0 y termina en la verosimilitud final",
       {
         tabla <- traza_a_tabla(sim$traza)
         min(tabla$iter) == 0L &&
           abs(tabla$objetivo[nrow(tabla)] - sim$log_verosimilitud) < 1e-9
       })

probar("los pesos de la ultima iteracion son los pesos devueltos (ya reetiquetados)",
       {
         tabla <- parametros_a_tabla(sim$traza)
         ultima <- tabla[tabla$iter == max(tabla$iter), ]
         identical(ultima$parametro, c("pi_g1", "pi_g2")) &&
           max(abs(ultima$valor - sim$pesos)) < 1e-12
       })

probar("hay una columna de asignaciones por iteracion registrada",
       ncol(sim$asignaciones_por_iter) == sim$iteraciones + 1L &&
         identical(sim$asignaciones_por_iter[, ncol(sim$asignaciones_por_iter)],
                   sim$grupos))

probar("registrar_traza = FALSE no guarda nada y el ajuste sigue valiendo",
       {
         mudo <- ajustar_clases_latentes(simulado, k = 2L, reinicios = 5L,
                                         k_max = 1L, registrar_traza = FALSE)
         is.null(mudo$traza) && is.null(mudo$asignaciones_por_iter) &&
           abs(mudo$log_verosimilitud - sim$log_verosimilitud) < 1e-6
       })

# ---------------------------------------------------------------------------
cat("\n[clases latentes · el contrato]\n")

zoo3 <- ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 3L,
                                reinicios = 50L)

probar("devuelve exactamente los campos del contrato compartido",
       all(c("grupos", "k", "n", "p", "tamanos", "x", "columnas",
             "filas_descartadas", "semilla", "modos", "probabilidades",
             "pesos", "posterior", "log_verosimilitud", "n_parametros", "bic",
             "aic", "entropia_relativa", "seleccion", "reinicios", "maxit",
             "tol", "semilla_ganadora", "iteraciones", "convergio", "traza",
             "trazas_reinicios") %in% names(zoo3)))

probar("declara su familia con las cuatro clases",
       identical(class(zoo3), c("ajuste_clases_latentes", "ajuste_cualitativo",
                                "ajuste_agrupamiento", "ajuste_sda")))

probar("x son factores completos con el nombre del animal como fila",
       all(vapply(zoo3$x, is.factor, logical(1))) &&
         identical(rownames(zoo3$x), rownames(zoo)) && zoo3$p == 16L)

probar("cada fila de la posterior suma 1 y el grupo es su maximo",
       max(abs(rowSums(zoo3$posterior) - 1)) < 1e-10 &&
         identical(zoo3$grupos, unname(max.col(zoo3$posterior,
                                               ties.method = "first"))))

probar("las clases van ordenadas por tamano y los tamanos suman n",
       !is.unsorted(rev(zoo3$tamanos)) && sum(zoo3$tamanos) == zoo3$n)

probar("cada theta es k x R_j y sus filas suman 1",
       all(vapply(zoo3$probabilidades, function(m)
         nrow(m) == 3L && max(abs(rowSums(m) - 1)) < 1e-10, logical(1))) &&
         ncol(zoo3$probabilidades$patas) == 6L)

probar("los modos son la categoria de mayor theta",
       identical(as.character(zoo3$modos$plumas),
                 colnames(zoo3$probabilidades$plumas)[
                   max.col(zoo3$probabilidades$plumas)]) &&
         identical(rownames(zoo3$modos), c("g1", "g2", "g3")))

probar("n_parametros = (k-1) + k sum(R_j - 1), y BIC y AIC salen de ahi",
       zoo3$n_parametros == 2L + 3L * (15L + 5L) &&
         abs(zoo3$bic - (-2 * zoo3$log_verosimilitud + 62 * log(101))) < 1e-9 &&
         abs(zoo3$aic - (-2 * zoo3$log_verosimilitud + 124)) < 1e-9)

probar("la entropia relativa esta entre 0 y 1",
       zoo3$entropia_relativa >= 0 && zoo3$entropia_relativa <= 1)

probar("k = 1 en la seleccion es el modelo de independencia, sin EM que valga",
       {
         independencia <- sum(vapply(zoo3$x, function(v)
           sum(table(v) * log(prop.table(table(v)))), numeric(1)))
         abs(zoo3$seleccion$log_verosimilitud[1] - independencia) < 1e-8
       })

probar("en la seleccion, la fila del k pedido es el ajuste principal",
       zoo3$seleccion$log_verosimilitud[3] == zoo3$log_verosimilitud)

# ---------------------------------------------------------------------------
cat("\n[clases latentes · entradas]\n")

probar("por defecto se aparta el identificador y nombra las filas",
       {
         con_nombre <- utils::read.csv("data/zoo.csv", stringsAsFactors = TRUE)
         a <- ajustar_clases_latentes(con_nombre[, c("animal", "pelo", "plumas",
                                                     "leche", "aletas")],
                                      k = 2L, reinicios = 2L, k_max = 2L)
         !"animal" %in% a$columnas && rownames(a$x)[1] == "aardvark"
       })

probar("una columna numerica pedida a mano entra como factor",
       {
         crudo <- utils::read.csv("data/zoo.csv", stringsAsFactors = TRUE)
         a <- ajustar_clases_latentes(crudo, columnas = c("pelo", "leche",
                                                          "patas"),
                                      k = 2L, reinicios = 2L, k_max = 2L)
         is.factor(a$x$patas) && nlevels(a$x$patas) == 6L
       })

probar("las filas con faltantes se descartan y se cuentan",
       {
         con_hueco <- simulado; con_hueco$a[1:7] <- NA
         a <- ajustar_clases_latentes(con_hueco, k = 2L, reinicios = 2L,
                                      k_max = 1L)
         a$filas_descartadas == 7L && a$n == n_sim - 7L
       })

probar("k = 1 falla y explica", falla(ajustar_clases_latentes(simulado, k = 1L)))
probar("una sola variable falla",
       falla(ajustar_clases_latentes(simulado["a"], k = 2L)))
probar("un modelo con mas parametros que celdas falla (no identificable)",
       falla(ajustar_clases_latentes(simulado[c("a", "b")], k = 2L)))
# Como en k-modas: la fase 2 ofrece todas las cualitativas del diccionario,
# `animal` incluida, y el ajuste tiene que sobrevivir a la selección por defecto.
probar("el identificador se aparta aunque se pida, y nombra las filas",
       {
         a <- ajustar_clases_latentes(cargar_zoo(),
                                      columnas = c("animal", "pelo", "leche",
                                                   "plumas"),
                                      k = 2L, reinicios = 2L, k_max = 1L)
         identical(a$columnas, c("pelo", "leche", "plumas")) &&
           rownames(a$x)[3] == "bass"
       })

probar("la misma semilla da exactamente el mismo ajuste",
       identical(ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 4L,
                                         reinicios = 2L, k_max = 1L)$posterior,
                 ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 4L,
                                         reinicios = 2L, k_max = 1L)$posterior))

probar("mas reinicios nunca empeoran la verosimilitud",
       ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 4L,
                               reinicios = 10L, k_max = 1L)$log_verosimilitud >=
         ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 4L,
                                 reinicios = 1L, k_max = 1L)$log_verosimilitud)

# ---------------------------------------------------------------------------
cat("\n[clases latentes · contra poLCA]\n")

suppressPackageStartupMessages(library(poLCA))
codigos <- as.data.frame(lapply(zoo3$x, as.integer))
formula_polca <- stats::as.formula(
  paste("cbind(", paste(variables_zoo, collapse = ", "), ") ~ 1"))
polca <- function(k, ...) {
  set.seed(1)
  poLCA::poLCA(formula_polca, codigos, nclass = k, verbose = FALSE,
               calc.se = FALSE, ...)
}

zoo2 <- ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 2L,
                                reinicios = 20L, k_max = 1L)
polca2 <- polca(2L, nrep = 20)
polca3 <- polca(3L, nrep = 20, maxiter = 3000)
cat(sprintf("    k = 2 · propia %.4f · poLCA %.4f\n",
            zoo2$log_verosimilitud, polca2$llik))
cat(sprintf("    k = 3 · propia %.4f · poLCA %.4f\n",
            zoo3$log_verosimilitud, polca3$llik))

probar("k = 2: la misma log-verosimilitud que poLCA (1e-6 relativo)",
       abs(zoo2$log_verosimilitud / polca2$llik - 1) < 1e-6)

# Con k = 3 la superficie del zoológico tiene decenas de máximos locales que
# difieren en décimas: poLCA llega a su mejor valor en uno de veinte arranques
# y nuestros cincuenta pueden quedarse un escalón abajo. Por eso la tolerancia
# es relativa y holgada, y la igualdad exacta se pide en k = 2 y en las dos
# pruebas de abajo, que no dependen de la suerte del arranque.
probar("k = 3: la mejor de 50 reinicios coincide con poLCA (1e-3 relativo)",
       abs(zoo3$log_verosimilitud / polca3$llik - 1) < 1e-3)

probar("n_parametros y BIC con la formula de poLCA",
       zoo3$n_parametros == polca3$npar && zoo2$n_parametros == polca2$npar &&
         abs(zoo2$bic - polca2$bic) < 1e-6 && abs(zoo2$aic - polca2$aic) < 1e-6)

# La verosimilitud de las dos implementaciones es la misma función: evaluada
# en los parámetros de poLCA, la nuestra da su número.
probar("evaluada en los parametros de poLCA, nuestra verosimilitud da la suya",
       {
         diseno <- .diseno_latente(zoo3$x)
         theta <- do.call(rbind, lapply(polca3$probs, t))
         e <- .paso_e_latente(diseno, list(pi = polca3$P, theta = theta))
         abs(e$log_verosimilitud - polca3$llik) < 1e-6
       })

probar("arrancado desde nuestro optimo, poLCA no se mueve de ahi",
       {
         inicio <- lapply(zoo2$probabilidades, unname)
         desde <- polca(2L, probs.start = inicio, nrep = 1)
         abs(desde$llik - zoo2$log_verosimilitud) < 1e-6
       })

# ---------------------------------------------------------------------------
cat("\n[clases latentes · el catalogo lo declara]\n")

registrado <- !is.null(tryCatch(metodo("clases_latentes"),
                                error = function(e) NULL))
if (!registrado) {
  cat("  (sin registrar todavia en catalogo/agrupamiento.R: se salta)\n")
} else {
  probar("esta activo y trae su funcion de ajuste",
         metodo("clases_latentes")$estado == "activo" &&
           identical(metodo("clases_latentes")$ajustar, ajustar_clases_latentes))
  probar("cada hiperparametro del registro es argumento de la funcion pura",
         all(names(metodo("clases_latentes")$hiper) %in%
               names(formals(ajustar_clases_latentes))))
  probar("cada artefacto que promete esta registrado",
         all(metodo("clases_latentes")$artefactos %in% claves_artefactos()))
}

# ---------------------------------------------------------------------------
cat("\n[clases latentes · el zoologico, para el informe]\n")

zoo_bic <- ajustar_clases_latentes(zoo, columnas = variables_zoo, k = 3L,
                                   reinicios = 20L, k_max = 8L)
tabla_bic <- zoo_bic$seleccion
k_bic <- tabla_bic$k[which.min(tabla_bic$bic)]
cat("    BIC por k (", nrow(zoo), "animales, 16 variables, 20 reinicios en el k",
    "pedido y 5 en los demas):\n")
print(format(tabla_bic, digits = 6), row.names = FALSE)

# Las filas de la tabla con cinco arranques son cotas inferiores de la
# verosimilitud: abajo, con veinte, el mismo k puede subir.
for (kk in unique(c(k_bic, 7L))) {
  a <- ajustar_clases_latentes(zoo, columnas = variables_zoo, k = kk,
                               reinicios = 20L, k_max = 1L)
  cat(sprintf("    k = %d · log-verosimilitud %.3f · ARI contra tipo = %.3f%s\n",
              kk, a$log_verosimilitud, rand_ajustado(a$grupos, zoo$tipo),
              if (kk == k_bic) " (elegido por BIC)" else ""))
}

probar("el BIC elige un k entre 2 y 7 en el zoologico", k_bic >= 2L && k_bic <= 7L)

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_clases_latentes] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
