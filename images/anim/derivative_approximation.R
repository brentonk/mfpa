# Pre-renders the derivative-approximation animation for derivatives.qmd.
#
# Run from notes/ (paths are relative to the book root):
#   Rscript images/anim/derivative_approximation.R
#
# Output: images/derivative_approximation.gif, which is committed and embedded
# in derivatives.qmd as an ordinary markdown figure. Rendering it here rather
# than in a chunk keeps gganimate (and its transformr -> sf -> GDAL dependency
# chain) off the CI runner and out of renv.lock. Re-run after editing this
# file and commit both the script and the regenerated GIF.
#
# Styling follows CLAUDE.md "ggplot styling": palette + theme from _common.R,
# frames drawn with ragg so Archivo is used, paper-coloured background so the
# GIF matches the page (GIF transparency would leave jagged edges).

suppressPackageStartupMessages({
  source("_common.R")
  library("gganimate")
})

out <- "images/derivative_approximation.gif"

# g(x) = x^2 / 5, as in fig-nonlinear-function-comparison (red there too).
df_g <- tibble(x = seq(0, 5.2, by = 0.05), g = x^2 / 5)

# One state per approximation point z, from far (5) to near (0.5).
frames <- tibble(z = seq(0.5, 5, by = 0.25)) |>
  mutate(
    num = z^2 / 5,
    deriv = num / z,
    lbl = str_glue("Δg(x)/Δx = {round(deriv, 2)}"),
    lbl_x = str_glue("Δx = {z}"),
    lbl_y = str_glue("Δg(x) = {round(num, 2)}"),
    zz = factor(z, levels = rev(unique(z)))
  )

p <- ggplot(frames) +
  geom_line(aes(x = x, y = g), data = df_g, colour = mfpa$red, linewidth = 1.3) +
  # run and rise legs, de-emphasised
  geom_segment(
    aes(x = 0, xend = z, y = 0, yend = 0),
    linewidth = 0.4, colour = mfpa$muted
  ) +
  geom_segment(
    aes(x = z, xend = z, y = 0, yend = num),
    linewidth = 0.4, colour = mfpa$muted
  ) +
  # the secant whose slope is the approximation
  geom_segment(aes(x = 0, xend = z, y = 0, yend = num), linewidth = 0.8) +
  annotate("point", x = 0, y = 0, size = 3.5) +
  geom_point(aes(x = z, y = num), size = 3.5) +
  # labels are centred on the secant / run leg, but clamped away from the
  # left panel edge so they stay inside the plot at small z
  geom_text(aes(x = pmax(z / 2, 1), y = pmax(num, 1.5), label = lbl), size = 5) +
  geom_text(aes(x = z, y = num / 2, label = lbl_y), size = 5, hjust = -0.05) +
  geom_text(aes(x = pmax(z / 2, 0.5), y = -0.25, label = lbl_x), size = 5) +
  scale_x_continuous(limits = c(0, 6), breaks = 0:6) +
  scale_y_continuous(limits = c(-0.5, 5.5), breaks = seq(-1, 6)) +
  labs(x = "x", y = "Function value g(x)") +
  # wrap = FALSE: end (and hold, via end_pause) on the narrowest Δx rather
  # than tweening back to the widest one.
  transition_states(zz, wrap = FALSE)

# invisible(): the returned gif_image would otherwise auto-print and try to
# open a viewer, which errors under Rscript.
invisible(animate(
  p,
  nframes = 100, fps = 10, end_pause = 10,
  width = 7, height = 5, units = "in", res = 144,
  device = "ragg_png", bg = mfpa$paper,
  renderer = gifski_renderer(out)
))
cat("Wrote", out, "\n")
