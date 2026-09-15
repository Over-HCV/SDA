# learn/R/ui/f0/inicio.R
#
# Inicio · dónde estoy, qué hay hecho, por dónde sigo.
#
# Todo lo que muestra sale del estado vivo (dataset, paneles marcados,
# almacén) y del registro, nunca de constantes escritas a mano: si el catálogo
# crece o la sesión cambia, Inicio cambia solo. Las dos excepciones son la
# grilla del curso (TITULOS_SESION, ENTREGAS_SESION), que copian la guía de la
# asignatura, y qué paneles de ① Datos le tocan a cada sesión.

TITULOS_SESION <- c(
  "1" = "Herramientas básicas", "2" = "Herramientas básicas (II)",
  "3" = "Normal multivariada y visualización", "4" = "Componentes principales",
  "5" = "Agrupamiento", "6" = "Regresión múltiple",
  "7" = "Regresión múltiple (II)", "8" = "Análisis de varianza")

# guide-eda-26A.md, sección 8: en qué sesión se entrega cada cosa.
ENTREGAS_SESION <- c("1" = "Taller 0", "3" = "Taller 1", "5" = "Taller 2",
                     "7" = "Taller 3", "8" = "Proyecto")

# Los paneles de ① Datos que trabajan el tema de cada sesión. Las sesiones de
# métodos (4 en adelante) se miden con el catálogo, no con esta lista.
PANELES_SESION <- list(
  "1" = c("f1.fuente.vista_previa", "f1.filtro.filas", "f1.diccionario.tabla",
          "f1.analisis.resumen", "f1.analisis.histograma",
          "f1.analisis.densidad", "f1.analisis.boxplot",
          "f1.analisis.boxplot_grupos", "f1.analisis.qq_normal_datos",
          "f1.calidad.matriz_nulidad", "f1.calidad.atipicos",
          "f1.calidad.duplicados"),
  "2" = c("f1.analisis.dispersion", "f1.analisis.densidad_conjunta",
          "f1.analisis.mosaico", "f1.transformacion.antes_despues",
          "f1.transformacion.perfil_boxcox", "f1.balanceo.frecuencias",
          "f1.balanceo.nube_sinteticos", "f1.particion.tamanos",
          "f1.particion.balance"),
  "3" = c("f1.analisis.matriz_dispersion", "f1.analisis.heatmap_correlacion",
          "f1.analisis.coordenadas_paralelas", "f1.analisis.elipsoide",
          "f1.analisis.qq_mahalanobis"))

mod_inicio_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      bslib::card(
        bslib::card_header("Sesión"),
        bslib::card_body(controles_sesion(ns))),
      bslib::card(
        bslib::card_header("Estado de la sesión"),
        bslib::card_body(shiny::uiOutput(ns("estado")))),
      bslib::card(
        bslib::card_header("Por dónde empezar"),
        bslib::card_body(shiny::uiOutput(ns("ruta"))))
    ),
    bslib::card(
      class = "mt-3",
      bslib::card_header("Mapa del curso"),
      bslib::card_body(shiny::uiOutput(ns("mapa_curso"))),
      bslib::card_footer(
        class = "small text-muted",
        paste("Sesiones 1 a 3: paneles de ① Datos de ese tema que marcaste con",
              "Añadir. Sesiones 4 a 8: métodos del catálogo que ya corren; los",
              "bloqueados no cuentan como pendientes, no van a estar nunca."))
    ),
    bslib::card(
      class = "mt-3",
      bslib::card_header("Últimas corridas"),
      bslib::card_body(shiny::uiOutput(ns("corridas"))))
  )
}

#' Una línea "etiqueta: valor" del estado.
.renglon <- function(etiqueta, ...)
  shiny::tags$div(class = "mb-1",
                  shiny::tags$span(class = "text-muted small", etiqueta), " ", ...)

#' Columnas cuyo diccionario difiere de lo que se autodetecta: lo declarado.
.declaradas <- function(ds) {
  if (is.null(ds) || is.null(ds$diccionario)) return(character(0))
  auto <- diccionario_inicial(ds$df)
  dic <- ds$diccionario
  fila <- match(dic$columna, auto$columna)
  cambio <- (dic$escala != auto$escala[fila]) | (dic$rol != auto$rol[fila])
  dic$columna[!is.na(fila) & cambio]
}

#' @param dataset,seleccion,cuaderno reactiveVal de app.R (pueden ser NULL)
#' @param guardado nuevo_estado_guardado(), o NULL
mod_inicio_server <- function(id, almacen, dataset = NULL, seleccion = NULL,
                              cuaderno = NULL, guardado = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ds_vivo <- function() if (is.null(dataset)) NULL else dataset()
    marcados <- function() if (is.null(seleccion)) list() else seleccion()

    servidor_sesion(input, output, session, almacen, dataset, seleccion,
                    cuaderno, guardado)

    output$estado <- shiny::renderUI({
      ds <- ds_vivo()
      entradas <- marcados()
      cuentas <- almacen()
      cobertura <- cobertura_textos()

      datos <- if (is.null(ds)) {
        .renglon("Dataset", shiny::tags$em("ninguno: empezá en ① Datos o abrí",
                                           " una sesión."))
      } else {
        n_crudo <- ds$n_crudo %||% ds$n
        pila <- vapply(ds$transformaciones %||% list(),
                       describir_transformacion, "")
        extra <- c(
          if (!is.null(ds$balanceo))
            sprintf("balanceo %s por %s (semilla %s)", ds$balanceo$metodo,
                    ds$balanceo$columna, ds$balanceo$semilla),
          if (!is.null(ds$particion))
            sprintf("partición %s (semilla %s)", ds$particion$tipo,
                    ds$particion$semilla))
        declaradas <- .declaradas(ds)
        con_unidad <- sum(nzchar(ds$diccionario$unidad %||% ""), na.rm = TRUE)
        shiny::tagList(
          .renglon("Dataset", shiny::tags$strong(ds$nombre %||% ds$fuente),
                   sprintf(" · %s de %s filas · %d columnas",
                           format(ds$n, big.mark = ".", decimal.mark = ","),
                           format(n_crudo, big.mark = ".", decimal.mark = ","), ds$p)),
          .renglon("Preparación",
                   if (length(c(pila, extra)))
                     shiny::tags$ul(class = "mb-0 ps-3 small",
                                    lapply(c(pila, extra), shiny::tags$li))
                   else "sin filtros ni transformaciones"),
          .renglon("Diccionario",
                   sprintf("%d declaradas a mano%s · %d con unidad",
                           length(declaradas),
                           if (length(declaradas))
                             paste0(" (", paste(utils::head(declaradas, 4),
                                                collapse = ", "),
                                    if (length(declaradas) > 4) ", …" else "",
                                    ")") else "",
                           con_unidad)))
      }

      con_lectura <- sum(vapply(entradas, function(e)
        nzchar(trimws(e$nota %||% "")), logical(1)))

      shiny::tagList(
        datos,
        .renglon("Informe", sprintf("%d paneles marcados · %d con lectura",
                                    length(entradas), con_lectura),
                 if (!is.null(cuaderno))
                   sprintf(" · cuaderno: %d piezas", length(cuaderno()))),
        franja_estado(list(
          "datasets" = almacen_contar(cuentas, "dataset"),
          "modelos"  = almacen_contar(cuentas, "modelo"),
          "recetas"  = almacen_contar(cuentas, "receta"),
          "corridas" = almacen_contar(cuentas, "corrida"))),
        # Avance del desarrollo del lab: útil para quien lo escribe, no para
        # quien lo usa. Plegado para que no sea lo primero que se lee.
        plegable("Avance del lab", shiny::tagList(
          barra_progreso(cobertura$fichas_escritas, cobertura$fichas_esperadas,
                         "Fichas de método escritas"),
          barra_progreso(cobertura$textos_escritos, cobertura$textos_esperados,
                         "Textos de gráficos escritos")))
      )
    })

    # Antes era una lista escrita a mano del Hito 1 ("54 métodos", "las fases
    # todavía no calculan") y quedó mintiendo en cuanto la fase 1 y los primeros
    # métodos corrieron. Las cuentas y los nombres salen del registro.
    output$ruta <- shiny::renderUI({
      catalogo <- metodos_df()
      activos <- catalogo[catalogo$estado == "activo", , drop = FALSE]
      bloqueados <- catalogo$clave[catalogo$estado == "bloqueado"]
      nombres_activos <- if (nrow(activos))
        paste(activos$nombre, collapse = " y ") else "ninguno todavía"
      shiny::tags$ol(
        class = "mb-0 ps-3",
        shiny::tags$li("¿Venís de antes? Abrí tu sesión en la card ",
                       shiny::tags$strong("Sesión"),
                       ", o la de ejemplo del Taller 01."),
        shiny::tags$li(shiny::tags$strong("① Datos"),
                       ": cargá una fuente (", shiny::tags$code("ori"),
                       " es la del Taller 01), filtrá, declará el diccionario",
                       " y mirá ▣ Análisis."),
        shiny::tags$li("Marcá ", shiny::tags$strong("Añadir"),
                       " en los paneles que quieras entregar y bajalos desde ",
                       shiny::tags$strong("Informe"),
                       " como un cuaderno .Rmd que corre solo."),
        shiny::tags$li(shiny::tags$strong("② Modelado → Catálogo"),
                       sprintf(": %d métodos registrados, %d corren hoy (%s).",
                               nrow(catalogo), nrow(activos), nombres_activos)),
        if (nrow(activos)) shiny::tags$li(
          shiny::tags$strong("③ Ajuste"), " y ", shiny::tags$strong("④ Evaluación"),
          ": corré uno de esos métodos sobre tu dataset y mirá sus diagnósticos."),
        if (length(bloqueados)) shiny::tags$li(
          "Abrí la ficha de ", shiny::tags$code(bloqueados[1]),
          " (bloqueado) y leé el puente: conecta un método inalcanzable con",
          " uno que sí corre acá."),
        shiny::tags$li("Antes de cerrar la pestaña, ",
                       shiny::tags$strong("Guardar JSON"),
                       ": el navegador no guarda nada por su cuenta.")
      )
    })

    output$mapa_curso <- shiny::renderUI({
      progreso <- progreso_por_sesion()
      if (!nrow(progreso)) return(shiny::tags$p("Catálogo vacío."))
      claves_marcadas <- unique(vapply(marcados(), function(e) e$clave %||% "", ""))
      registrados <- claves_artefactos()
      shiny::tagList(lapply(seq_len(nrow(progreso)), function(i) {
        fila <- progreso[i, ]
        sesion <- as.character(fila$sesion)
        etiqueta <- sprintf("Sesión %s · %s", sesion,
                            TITULOS_SESION[[sesion]] %||% "")
        entrega <- ENTREGAS_SESION[sesion]
        paneles <- intersect(PANELES_SESION[[sesion]] %||% character(0),
                             registrados)
        barra <- if (length(paneles))
          barra_progreso(length(intersect(paneles, claves_marcadas)),
                         length(paneles), "paneles marcados")
        else barra_progreso(fila$activos, fila$total, "métodos que corren")
        shiny::tags$div(
          class = "mb-2",
          shiny::tags$div(
            class = "d-flex align-items-center gap-2 small fw-semibold",
            etiqueta,
            if (!is.na(entrega))
              shiny::tags$span(class = "badge text-bg-secondary fw-normal",
                               entrega)),
          barra)
      }))
    })

    output$corridas <- shiny::renderUI({
      recientes <- corridas_recientes(almacen())
      if (!length(recientes))
        return(shiny::tags$p(class = "text-muted mb-0",
                             paste("Todavía no hay corridas. Se crean en la",
                                   "fase 4, componiendo un dataset, un modelo",
                                   "y una receta, o llegan al abrir una sesión",
                                   "que las traiga. Para conservarlas enteras",
                                   "guardá en RDS: el JSON las trae sin el",
                                   "objeto ajustado.")))
      shiny::tags$ul(class = "list-unstyled mb-0", lapply(recientes, function(cor)
        shiny::tags$li(class = "border-bottom py-1",
                       shiny::tags$code(cor$id), " ", resumen_objeto(cor),
                       shiny::tags$span(class = "text-muted small ms-2",
                                        cor$creado))))
    })
  })
}
