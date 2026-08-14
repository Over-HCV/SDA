# libs/_comun/R/temas.R
#
# Tema ggplot2 y paletas compartidos por los 3 proyectos.
# Okabe-Ito para variables categóricas (amigable con daltonismo).
# Viridis-like para secuenciales (vía scales::viridis_pal).

# ---------------------------------------------------------------------------
# Tema base reutilizable
# ---------------------------------------------------------------------------
tema_ggplot <- function(base_size = 13, base_family = "") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", hjust = 0),
      plot.subtitle    = ggplot2::element_text(color = "grey40", hjust = 0),
      plot.caption     = ggplot2::element_text(color = "grey50", hjust = 1),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(linewidth = 0.3, color = "grey88"),
      axis.ticks       = ggplot2::element_line(linewidth = 0.3, color = "grey70"),
      strip.background = ggplot2::element_rect(fill = "grey92", color = NA),
      strip.text       = ggplot2::element_text(face = "bold")
    )
}

# ---------------------------------------------------------------------------
# Paleta Okabe-Ito (8 colores, daltónico-friendly).
# Uso: scale_color_manual(values = paleta_cat(8)) o con un n menor.
# ---------------------------------------------------------------------------
paleta_cat <- function(n = 8) {
  okabe_ito <- c(
    "#0072B2",  # azul
    "#E69F00",  # naranja
    "#009E73",  # verde
    "#CC79A7",  # rosa
    "#56B4E9",  # celeste
    "#D55E00",  # rojo-naranja
    "#F0E442",  # amarillo
    "#000000"   # negro
  )
  if (n <= length(okabe_ito)) okabe_ito[seq_len(n)] else okabe_ito
}

# Atajos listos para +ggplot
scale_color_cat <- function(n = 8, ...) ggplot2::scale_color_manual(values = paleta_cat(n), ...)
scale_fill_cat  <- function(n = 8, ...) ggplot2::scale_fill_manual(values = paleta_cat(n), ...)

# Secuenciales (vía viridis; viridisLite ya viene como dep de ggplot2)
scale_color_seq <- function(...) ggplot2::scale_color_viridis_c(...)
scale_fill_seq  <- function(...) ggplot2::scale_fill_viridis_c(...)

# ---------------------------------------------------------------------------
# Helper para aplicar tema + paleta de una vez a un ggplot existente.
# ---------------------------------------------------------------------------
estilizar <- function(p, n_cat = NULL) {
  p <- p + tema_ggplot()
  if (!is.null(n_cat)) p <- p + scale_color_cat(n_cat)
  p
}
