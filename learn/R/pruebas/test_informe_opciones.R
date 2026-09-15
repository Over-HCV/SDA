# learn/R/pruebas/test_informe_opciones.R
#
# Responsabilidad: probar que cada pieza del cuaderno entra y sale sola.
#
# Uso:  Rscript learn/R/pruebas/test_informe_opciones.R
#
# Vive aparte de test_informe.R (que prueba el armado y el catálogo de
# generadores) por C2: son dos responsabilidades y aquel ya rozaba el techo.

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

cat("\n[piezas del cuaderno]\n")

ds <- list(nombre = "ori", fuente = "ori", n = 118L, p = 18L, n_crudo = 4543L,
           transformaciones = list(list(tipo = "filtro", columnas = "Hora",
                                        params = list(valores = "12:00"))))
seleccion <- list(
  list(clave = "f1.analisis.boxplot", titulo = "Caja y bigotes",
       cuando = "12:00:00", params = list(variable = "Temperatura"),
       tabla = NULL, nota = "La caja es asimétrica a la izquierda."))

con <- function(...) armar_informe_exploracion(seleccion, ds, opciones = c(...))
sin <- function(pieza)
  armar_informe_exploracion(seleccion, ds,
                            opciones = setdiff(opciones_cuaderno(), pieza))

probar("de fábrica sale el cuaderno del taller: sin texto del lab ni ruido", {
  cuaderno <- armar_informe_exploracion(seleccion, ds)
  !any(grepl("^### ", cuaderno)) &&
    !any(grepl("marcado a las", cuaderno, fixed = TRUE)) &&
    !any(grepl("Parámetros:", cuaderno, fixed = TRUE)) &&
    !any(grepl("Cuaderno generado desde SDA Lab", cuaderno, fixed = TRUE)) &&
    !any(grepl("1 paneles|paneles · dataset", cuaderno))
})
probar("de fábrica el YAML es el de la plantilla y trae los campos a llenar", {
  cuaderno <- armar_informe_exploracion(seleccion, ds)
  any(grepl("template: ../template/taller-qmd-template.tex", cuaderno,
            fixed = TRUE)) &&
    any(grepl("^resumen: [|]", cuaderno)) &&
    any(grepl("^palabras: ", cuaderno))
})
probar("sin la plantilla vuelve el YAML de R Markdown", {
  cuaderno <- sin("plantilla_taller")
  any(grepl("output:", cuaderno, fixed = TRUE)) &&
    !any(grepl("taller-qmd-template", cuaderno, fixed = TRUE))
})
probar("la procedencia se prende sola", {
  any(grepl("marcado a las 12:00:00", con("procedencia"), fixed = TRUE)) &&
    !any(grepl("marcado a las", sin("procedencia"), fixed = TRUE))
})
probar("los parámetros se prenden solos",
       any(grepl("Parámetros:", con("parametros"), fixed = TRUE)))
probar("la ficha del dataset se apaga sola", {
  !any(grepl("Filas al cargar", sin("ficha_datos"), fixed = TRUE)) &&
    any(grepl("Filas al cargar", armar_informe_exploracion(seleccion, ds),
              fixed = TRUE))
})
probar("las lecturas se apagan solas", {
  !any(grepl("asimétrica a la izquierda", sin("notas"), fixed = TRUE)) &&
    any(grepl("asimétrica a la izquierda",
              armar_informe_exploracion(seleccion, ds), fixed = TRUE))
})
probar("el texto esencial deja Cuándo engaña y saca Para qué sirve", {
  esencial <- con("texto_esencial")
  !any(grepl("^### Para qué sirve", esencial)) &&
    any(grepl("^### Cuándo engaña", esencial))
})
probar("el texto ampliado trae las dos mitades", {
  ampliado <- con("texto_esencial", "texto_ampliado")
  any(grepl("^### Para qué sirve", ampliado)) &&
    any(grepl("^### Cuándo engaña", ampliado))
})
probar("los presets viejos siguen traduciendo a piezas", {
  setequal(opciones_cuaderno(texto = "completo"),
           c(PIEZAS_POR_DEFECTO, "texto_esencial", "texto_ampliado")) &&
    setequal(opciones_cuaderno(texto = "breve"),
             c(PIEZAS_POR_DEFECTO, "texto_esencial")) &&
    setequal(opciones_cuaderno(texto = "ninguno"), PIEZAS_POR_DEFECTO)
})
probar("una pieza inventada se rechaza en vez de ignorarse",
       inherits(tryCatch(opciones_cuaderno("inventada"),
                         error = function(e) e), "error"))
probar("una sesión vieja con nivel de texto abre con las piezas puestas", {
  # Version 1: traia `texto` y no las casillas. Al leerla, el preset se
  # traduce a piezas y el campo viejo desaparece.
  archivo <- tempfile(fileext = ".json")
  exportar_json(list(
    proyecto = "sda-lab", tipo = "sesion", version = 1L,
    fase1 = list(fuente = "ori", nombre = "ori", seleccion = list(),
                 texto = "breve")), archivo)
  fase1 <- importar_sesion_json(archivo)$fase1
  is.null(fase1$texto) &&
    setequal(fase1$cuaderno, c(PIEZAS_POR_DEFECTO, "texto_esencial"))
})

cat(sprintf("\n[piezas] %s\n",
            if (.FALLOS == 0L) "todo en orden" else
              sprintf("%d fallo(s)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
