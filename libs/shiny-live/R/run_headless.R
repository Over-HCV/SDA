# libs/shiny-live/R/run_headless.R
#
# Entrada headless para el agente. NO usa Shiny. Llama a datos.R + modelo.R
# y escribe outputs/<escenario>.{png,json,csv} + append a run_log.csv conforme
# al contrato S2 del sdd.md.
#
# Ejemplo desde la raíz del proyecto:
#   Rscript -e 'source("libs/shiny-live/R/run_headless.R");
#                correr("demo-twins", dataset="twins")'
# ---------------------------------------------------------------------------

# Bootstrap auto-contenido (root-finder propio; evita chicken-and-egg).
.source_proyecto <- function() {
  raiz <- (function() {
    d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
    repeat {
      if (file.exists(file.path(d, "data", "charcoal.csv")) ||
          file.exists(file.path(d, "renv", "activate.R"))) return(d)
      p <- dirname(d); if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
      d <- p
    }
  })()
  for (f in c("datos.R", "metricas.R", "temas.R"))
    source(file.path(raiz, "libs", "_comun", "R", f))
  for (f in c("datos.R", "modelo.R"))
    source(file.path(raiz, "libs", "shiny-live", "R", f))
}

# ---------------------------------------------------------------------------
# correr: ejecuta un escenario ANOVA completo headless.
# Devuelve la lista escrita (invisiblemente) y deja huella en disco.
# ---------------------------------------------------------------------------
correr <- function(escenario = "anova-demo",
                   dataset = "twins",
                   flujo = "Production", anio = 2019,
                   k_grupos = 4, n_por_grupo = 30, efecto = 5, ruido = 1,
                   semilla = 42, balanceado = TRUE,
                   out_dir = "libs/shiny-live/outputs") {
  .source_proyecto()

  datos <- datos_anova(dataset = dataset, flujo = flujo, anio = anio,
                       k_grupos = k_grupos, n_por_grupo = n_por_grupo,
                       efecto = efecto, ruido = ruido, semilla = semilla,
                       balanceado = balanceado)
  if (nrow(datos) < 3 || length(unique(datos$grupo)) < 2)
    stop("Datos insuficientes para ANOVA en el escenario ", escenario,
         " (dataset=", dataset, ")")

  res <- correr_anova(datos, semilla = semilla)
  p_box <- graficar_boxplot(res)
  p_qq <- graficar_qq(res)

  escribir_salida(
    proyecto  = "shiny-live",
    escenario = escenario,
    params    = list(dataset = dataset, flujo = flujo, anio = anio,
                     k_grupos = k_grupos, n_por_grupo = n_por_grupo,
                     efecto = efecto, ruido = ruido, semilla = semilla,
                     balanceado = balanceado),
    metricas  = list(F = res$F, p = res$p,
                     shapiro_p = res$shapiro_p, levene_p = res$levene_p,
                     n = res$n, grupos = length(res$grupos)),
    plot_obj  = p_box,
    datos_df  = res$datos,
    notas     = sprintf("ANOVA one-way sobre dataset %s (%d obs, %d grupos)",
                        dataset, res$n, length(res$grupos)),
    out_dir   = out_dir
  )

  # Diagnóstico (QQ de residuales) como artefacto adicional.
  escribir_salida(
    proyecto  = "shiny-live",
    escenario = paste0(escenario, "-qq"),
    params    = list(escenario_origen = escenario),
    metricas  = list(shapiro_p = res$shapiro_p),
    plot_obj  = p_qq,
    datos_df  = NULL,
    notas     = "QQ de residuales del escenario principal",
    out_dir   = out_dir
  )

  cat(sprintf("[correr] %s: F=%.3f p=%.4g n=%d grupos=%d\n",
              escenario, res$F, res$p, res$n, length(res$grupos)))
  invisible(res)
}

# ---------------------------------------------------------------------------
# Ejecución directa con Rscript -e: solo define las funciones. Ejemplos:
#   correr("demo-twins",    dataset = "twins")
#   correr("demo-charcoal", dataset = "charcoal")
#   correr("demo-sint",     dataset = "sintetico", efecto = 10)
# ---------------------------------------------------------------------------
if (FALSE) {
  correr("demo-twins",    dataset = "twins")
  correr("demo-charcoal", dataset = "charcoal", flujo = "Production", anio = 2019)
  correr("demo-sint",     dataset = "sintetico", k_grupos = 4, efecto = 10)
}
