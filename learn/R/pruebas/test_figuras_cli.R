# learn/R/pruebas/test_figuras_cli.R
#
# Responsabilidad: probar las figuras del lab por consola (`panel ... --salida
# x.png`, lab/figuras.R) y las piezas cualitativas que las presentaciones
# necesitaron: el codo de k-modas, la d de una partición contra la fórmula del
# cuaderno del curso y la concordancia entre dos métodos (`--comparar`).
#
# Uso:  Rscript learn/R/pruebas/test_figuras_cli.R

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/lab.R")

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

ZOO <- c("--fuente", "zoo", "--clase", "tipo")
carpeta <- file.path(tempdir(), "figuras_cli")
dir.create(carpeta, showWarnings = FALSE)

# Un PNG de verdad: existe, pesa y empieza con la firma del formato.
es_png <- function(ruta) {
  file.exists(ruta) && file.size(ruta) > 5000 &&
    identical(readBin(ruta, "raw", 4L), as.raw(c(0x89, 0x50, 0x4e, 0x47)))
}

# Corre el CLI como lo corre un usuario y devuelve la ruta pedida.
figura <- function(nombre, argumentos) {
  ruta <- file.path(carpeta, nombre)
  utils::capture.output(suppressMessages(
    correr_lab(c(argumentos, ZOO, "--salida", ruta, "--ancho", "6",
                 "--alto", "4", "--dpi", "100"))))
  ruta
}

cat("\n[panel --salida · una figura por fase]\n")
probar("f1: frecuencias de la clase real a PNG",
       es_png(figura("frecuencias.png", c("panel", "f1.balanceo.frecuencias",
                                          "tipo"))))
probar("f1: el mosaico (su gráfico recibe la lógica, no el data.frame)",
       es_png(figura("mosaico.png", c("panel", "f1.analisis.mosaico", "pelo",
                                      "leche"))))
probar("f3: la traza de convergencia de k-modas a PNG",
       es_png(figura("traza.png", c("panel", "f3.analisis.convergencia",
                                    "--metodo", "kmodos", "--hiper", "k=7"))))
probar("f4: los modos de k-modas a PNG",
       es_png(figura("modos.png", c("panel", "f4.explicabilidad.modos",
                                    "--metodo", "kmodos", "--hiper", "k=7"))))
probar("f4: también a PDF", {
  ruta <- figura("modos.pdf", c("panel", "f4.explicabilidad.modos",
                                "--metodo", "kmodos", "--hiper", "k=7"))
  file.exists(ruta) && file.size(ruta) > 1000
})
probar("sin --salida sigue imprimiendo la tabla de capas", {
  texto <- utils::capture.output(suppressMessages(correr_lab(c(
    "panel", "f4.diagnostico.codo", "--metodo", "kmodos", "--hiper", "k=7",
    "--k_max", "5", ZOO))))
  any(grepl("capa", texto)) && !any(grepl("figura escrita", texto))
})
probar("es la misma figura que la tabla: grafico_de_panel() comparte objeto", {
  ds <- armar_dataset(list(fuente = "zoo", clase = "tipo"))
  panel <- grafico_de_panel(ds, "f1.analisis.mosaico", c("pelo", "leche"))
  inherits(panel$grafico, "ggplot") &&
    grepl("V = 0.858", panel$grafico$labels$subtitle, fixed = TRUE)
})

cat("\n[codo cualitativo]\n")
ds <- armar_dataset(list(fuente = "zoo", clase = "tipo"))
kmodos <- ajustar_cli(ds, "kmodos", list(hiper = "k=7", reinicios = "10"))$ajuste
codo <- inercia_por_k(kmodos, k_max = 8L)
probar("k-modas: k = 1..8, con k = 1 = desacuerdos con el modo global", {
  global <- sum(vapply(kmodos$x, function(v) length(v) - max(table(v)), 0))
  identical(codo$k, 1:8) && codo$inercia[1] == global
})
probar("k-modas: el costo no sube al agregar un grupo",
       all(diff(codo$inercia) <= 0))
probar("k-modas: en k = 7 es el costo del ajuste",
       codo$inercia[7] == kmodos$costo)
probar("el eje dice qué se midió", grepl("desacuerdos", attr(codo, "criterio")))
probar("Gower jerárquico: la d sobre la matriz de Gower, k = 1 es el total", {
  gower <- ajustar_cli(ds, "gower", list(hiper = c("k=4",
                       "estrategia=jerarquico")))$ajuste
  tabla <- inercia_por_k(gower, k_max = 6L)
  total <- disimilitud_particion(gower$matriz_disimilitud, rep(1L, gower$n),
                                 "gower")
  abs(tabla$inercia[1] - total) < 1e-12 &&
    abs(tabla$inercia[4] - metricas_de_corrida(gower)$d_particion) < 1e-12
})

cat("\n[d de la partición]\n")
set.seed(7)
numeros <- matrix(stats::rnorm(90), ncol = 3)
grupos <- rep(1:3, each = 10)
# La función del cuaderno del curso (NB4_PRF): d² dentro de cada grupo.
calcular_d2 <- function(x, grupos) sum(vapply(unique(grupos), function(g) {
  vals <- x[grupos == g, , drop = FALSE]
  sum(stats::dist(vals)^2) / nrow(vals)
}, 0))
probar("euclidea2 reproduce calcular_d2 del profesor",
       abs(disimilitud_particion(numeros, grupos, "euclidea2") -
             calcular_d2(numeros, grupos)) < 1e-10)
probar("y coincide con la suma de withinss de k-medias", {
  medias <- stats::kmeans(numeros, 3, nstart = 5)
  abs(disimilitud_particion(numeros, medias$cluster, "euclidea2") -
        sum(medias$withinss)) < 1e-10
})
probar("emparejamiento cuenta variables distintas por par", {
  x <- data.frame(a = c("s", "s", "n"), b = c("s", "n", "n"))
  # grupo 1 = filas 1 y 2: difieren en b → 1 / 2
  disimilitud_particion(x, c(1, 1, 2), "emparejamiento") == 0.5
})
probar("la d entra a las métricas de la corrida",
       is.numeric(metricas_de_corrida(kmodos)$d_particion))

cat("\n[concordancia · --comparar]\n")
probar("un método contra sí mismo: ARI = 1", {
  ajustado <- ajustar_cli(ds, "kmodos", list(hiper = "k=7"))
  opciones <- list(metodo = "kmodos", hiper = "k=7", comparar = "kmodos")
  ajuste <- suppressMessages(adjuntar_comparacion(ds, ajustado, opciones))
  abs(cruce_con_clase(ajuste)$ari - 1) < 1e-12
})
probar("k-modas contra Gower jerárquico: tabla grupo x grupo y rótulos", {
  ds_c <- armar_dataset(list(fuente = "zoo", clase = "tipo"))
  panel <- suppressMessages(grafico_de_panel(ds_c, "f4.desempeno.cruce_clase",
    character(0), list(metodo = "kmodos", hiper = c("k=7",
    "estrategia=jerarquico"), comparar = "gower", en_juego = "gower")))
  grepl("^ARI = ", panel$grafico$labels$subtitle) &&
    grepl("gower", panel$grafico$labels$x)
})
probar("--semilla_comparar no se filtra al primer ajuste", {
  opciones <- list(hiper = "k=7", semilla_comparar = "456", reinicios = "1")
  is.null(sin_opciones_de_comparacion(opciones)$semilla) &&
    identical(.opciones_comparacion(opciones)$semilla, "456")
})

cat("\n[dendrograma de Gower + PAM]\n")
probar("dice que el árbol existe solo con estrategia jerárquica", {
  pam <- ajustar_cli(ds, "gower", list(hiper = "k=7"))$ajuste
  grafico <- graficar_dendrograma(arbol_jerarquico(pam))
  any(grepl("estrategia jerárquica", unlist(lapply(grafico$layers,
    function(capa) capa$aes_params$label)), fixed = TRUE))
})

cat("\n[dendrograma circular y radial]\n")
jer <- ajustar_cli(ds, "gower", list(hiper = c("k=7", "estrategia=jerarquico")))$ajuste
arbol <- arbol_jerarquico(jer)
probar("el árbol trae un nodo por hoja y por fusión, y un enlace por hijo",
       nrow(arbol$nodos) == 2L * arbol$n - 1L &&
         nrow(arbol$enlaces) == 2L * (arbol$n - 1L))
probar("hay exactamente una raíz por grupo",
       all(table(arbol$nodos$grupo[arbol$nodos$raiz_grupo]) == 1L) &&
         sum(arbol$nodos$raiz_grupo) == arbol$k)
for (forma in c("circular", "radial")) {
  probar(sprintf("la forma %s se dibuja en polares, con y sin nombres", forma), {
    con <- graficar_dendrograma(arbol, etiquetas = TRUE, forma = forma)
    sin <- graficar_dendrograma(arbol, etiquetas = FALSE, forma = forma)
    inherits(con$coordinates, "CoordPolar") &&
      length(con$layers) == length(sin$layers) + 1L &&
      !is.null(ggplot2::ggplot_build(con))
  })
}
probar("arboles_por_enlace rehace el árbol sin reajustar: mismas hojas, otro enlace", {
  tres <- arboles_por_enlace(jer, c("complete", "average", "single"))
  identical(names(tres), c("complete", "average", "single")) &&
    all(vapply(tres, function(a) a$n, 1L) == arbol$n) &&
    isTRUE(all.equal(tres$average$corte, arbol$corte))
})
probar("--enlaces junta los tres árboles en un solo PNG",
       es_png(figura("enlaces.png", c("panel", "f4.diagnostico.dendrograma",
                                      "--metodo", "gower", "--hiper", "k=7",
                                      "--hiper", "estrategia=jerarquico",
                                      "--enlaces", "complete,average,single"))))
probar("--forma radial guarda el PNG",
       es_png(figura("radial.png", c("panel", "f4.diagnostico.dendrograma",
                                     "--metodo", "gower", "--hiper", "k=7",
                                     "--hiper", "estrategia=jerarquico",
                                     "--forma", "radial", "--hojas", "FALSE"))))

cat(sprintf("\n[test_figuras_cli] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
