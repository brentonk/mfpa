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
# cowplot::background_grid()). The `geom` element (ggplot2 >= 4.0) makes
# unstyled geoms -- geom_vline(), annotate("text"), ... -- default to ink and
# Archivo without per-call arguments.
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
      geom = element_geom(
        ink = mfpa$ink,
        paper = mfpa$paper,
        accent = mfpa$teal,
        family = "Archivo"
      )
    )
)
