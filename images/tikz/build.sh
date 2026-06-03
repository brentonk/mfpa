#!/usr/bin/env bash
# Build committed PNGs for the set-theory diagrams from the standalone .tex
# sources in this directory. Run locally only — CI never needs LaTeX.
#
# Requires: a LaTeX install with the `standalone` and `venndiagram` packages
# (latexmk + pdflatex) and a PDF->PNG rasterizer. We rasterize with a
# *transparent* background so the diagrams sit directly on the website's warm
# paper ($body-bg #FCFBF8 in mfpa.scss) instead of a white box; preference order
# is pdftocairo -transp (poppler), then ImageMagick `magick`/`convert` with
# `-background none`.
#
# Usage:  bash images/tikz/build.sh
# Output: images/<name>.png  (one per <name>.tex here)
set -euo pipefail
cd "$(dirname "$0")"
OUT=".."          # PNGs land in images/
DPI=300

render() {        # render <basename>.pdf -> ../<basename>.png at $DPI, transparent bg
  local name="$1"
  if command -v pdftocairo >/dev/null 2>&1; then
    pdftocairo -png -transp -r "$DPI" -singlefile "$name.pdf" "$OUT/$name"
  elif command -v magick >/dev/null 2>&1; then
    magick -density "$DPI" -background none "$name.pdf" "$OUT/$name.png"
  elif command -v convert >/dev/null 2>&1; then
    convert -density "$DPI" -background none "$name.pdf" "$OUT/$name.png"
  else
    echo "ERROR: need pdftocairo or ImageMagick to rasterize PDFs" >&2
    exit 1
  fi
}

for tex in *.tex; do
  name="${tex%.tex}"
  echo "==> $tex"
  latexmk -pdf -interaction=nonstopmode -halt-on-error "$tex" >/dev/null
  render "$name"
  echo "    wrote $OUT/$name.png"
done

latexmk -c >/dev/null 2>&1 || true   # clean .aux/.log/.fls etc.
rm -f ./*.pdf
echo "done."
