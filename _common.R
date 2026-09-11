# Shared R setup for every chapter: packages, the book's colour palette, and a
# ggplot2 default theme that matches mfpa.scss. Each chapter's setup chunk
# runs `source("_common.R")`. Conventions are documented in CLAUDE.md under
# "ggplot styling".
#
# NB: figure chunks are cached on their own code, so edits here do not
# re-render existing figures locally. Clear *_cache/ (or render with
# --cache-refresh) after changing anything below.

library("tidyverse")
library("cowplot")

# Palette. Mirrors the scss:defaults block of mfpa.scss -- keep the two in sync.
mfpa <- list(
  teal  = "#0F6E6E", # $primary      main series / the function of interest
  red   = "#B3261E", # $danger       contrasting second series
  green = "#2E7D46", # $success      third series, if ever needed
  ink   = "#1E1B16", # $body-color   axis lines & text, dashed reference lines
  muted = "#6B645A", # $mfpa-muted   annotation text, de-emphasised references
  rule  = "#E6DFD2", # $mfpa-rule    grid lines
  paper = "#FCFBF8"  # $body-bg      fill for hollow markers (page shows through)
)

# Archivo is the site's heading/chrome face. It is not a system font on most
# machines or on the CI runner, so fetch it from Google Fonts into the
# gitignored _fonts/ directory on first render; reuse the cached files after
# that; fall back to the system sans (aliased as "Archivo") if offline.
dir.create("_fonts", showWarnings = FALSE)
archivo_files <- list.files("_fonts", pattern = "^Archivo.*\\.ttf$", full.names = TRUE)
if (length(archivo_files) > 0) {
  systemfonts::add_fonts(archivo_files)
}
systemfonts::require_font(
  "Archivo",
  fallback = "sans",
  dir = "_fonts",
  error = FALSE,
  verbose = FALSE
)

# Default theme. The device background is already transparent (see _quarto.yml),
# so plots inherit the page's paper colour; text and axes use the page's ink;
# the major grid uses the page's hairline-rule colour (no need to call
# cowplot::background_grid()). Legends are off because every figure labels its
# series directly (opt back in per plot with theme(legend.position = ...)).
# The `geom` element (ggplot2 >= 4.0) makes unstyled geoms -- geom_vline(),
# annotate("text"), ... -- default to ink and Archivo without per-call
# arguments; `fontsize` makes annotation text come out at ggplot's size 5.
theme_set(
  theme_cowplot(font_family = "Archivo") +
    theme(
      plot.background = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA),
      text = element_text(colour = mfpa$ink),
      axis.text = element_text(colour = mfpa$ink),
      axis.line = element_line(colour = mfpa$ink),
      axis.ticks = element_line(colour = mfpa$ink),
      panel.grid.major = element_line(colour = mfpa$rule, linewidth = 0.5),
      legend.position = "none",
      geom = element_geom(
        ink = mfpa$ink,
        paper = mfpa$paper,
        accent = mfpa$teal,
        family = "Archivo",
        fontsize = 5 * .pt
      )
    )
)

# Geom defaults, so a bare geom_line() / geom_point() / geom_vline() comes out
# in the house style. Explicit per-call arguments still win.
#   - curves: teal at linewidth 1.3 (a second series gets its colour from the
#     discrete scale below, or from an explicit colour = mfpa$red)
#   - points: teal; size stays per call (helpers below use 4.5 for markers;
#     raw-data backdrops use 0.9)
#   - vertical / horizontal reference lines: dashed
update_geom_defaults("line", list(colour = mfpa$teal, linewidth = 1.3))
update_geom_defaults("point", list(colour = mfpa$teal))
update_geom_defaults("vline", list(linetype = "dashed"))
update_geom_defaults("hline", list(linetype = "dashed"))

# Discrete colour / fill scales: teal for the first series, red for the second,
# green for a third. Assignment follows level order, so put the series of
# interest first (e.g. in pivot_longer()). For a de-emphasised third series in
# `muted`, or any other departure, call scale_colour_manual() explicitly.
options(
  ggplot2.discrete.colour = c(mfpa$teal, mfpa$red, mfpa$green),
  ggplot2.discrete.fill = c(mfpa$teal, mfpa$red, mfpa$green)
)

# Helpers for the recurring figure idioms (documented in CLAUDE.md). Each
# returns a layer, so add it to a plot with `+` like any geom. x and y may be
# vectors to draw several markers in one call.

# Solid dot: the function's actual value at a point of interest.
mark_value <- function(x, y, colour = mfpa$teal) {
  annotate("point", x = x, y = y, colour = colour, size = 4.5)
}

# Hollow ring: a limit approached at a point, with the page showing through.
mark_limit <- function(x, y, colour = mfpa$teal) {
  annotate(
    "point",
    x = x, y = y,
    shape = 21, size = 4.5, stroke = 1.4,
    colour = colour, fill = mfpa$paper
  )
}

# Lightly shaded vertical band highlighting a window on the x-axis.
shade_window <- function(xmin, xmax, colour = mfpa$teal) {
  annotate(
    "rect",
    xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf,
    fill = colour, alpha = 0.08
  )
}

# Direct label for a curve, coloured to match it, in place of a legend. The
# label is parsed as plotmath by default (`"italic(h)(x)"`, `"2^x"`); pass
# parse = FALSE for plain text. Extra arguments (hjust, vjust, size, ...) go
# through to annotate().
label_curve <- function(x, y, label, colour = mfpa$teal, parse = TRUE, ...) {
  annotate("text", x = x, y = y, label = label, colour = colour, parse = parse, ...)
}
