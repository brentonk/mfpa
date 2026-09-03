#!/usr/bin/env bash
# Build the printable, exercise-free lecture PDF of the MFPA notes.
#
# Renders the Quarto book to PDF via Typst (bundled with Quarto — no LaTeX
# required), using the `print` profile (_quarto-print.yml).  That profile plus
# the guarded Lua filters (_filters/strip-exercises.lua and the print branches
# in concepts.lua / remark.lua) drop exercises, flatten the interactive glossary
# to a plain list, and suppress the hover tooltips that only make sense on the
# website.
#
# The HTML website build is untouched — this only runs when you invoke it.
#
# Usage:
#   print/build.sh          # build the whole book
#   print/build.sh --open   # build, then open the PDF
#
# Re-run it whenever you add or edit a chapter; R chunks are reused from the
# Quarto freeze cache, so it is cheap unless computational code changed.

set -euo pipefail

# Resolve the notes/ directory (parent of this script's dir) and work from it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTES_DIR="$(dirname "$SCRIPT_DIR")"
cd "$NOTES_DIR"

OUT_NAME="mfpa-lecture-notes"
DEST="$SCRIPT_DIR/${OUT_NAME}.pdf"

echo ">> Rendering ${OUT_NAME}.pdf (Typst, print profile, exercises stripped)…"
quarto render --to typst --profile print

SRC="_book/${OUT_NAME}.pdf"
if [[ ! -f "$SRC" ]]; then
  echo "!! Expected output not found at $SRC" >&2
  exit 1
fi

mkdir -p "$SCRIPT_DIR"
cp -f "$SRC" "$DEST"
echo ">> Wrote $DEST"

if [[ "${1:-}" == "--open" ]]; then
  ( xdg-open "$DEST" >/dev/null 2>&1 || open "$DEST" >/dev/null 2>&1 ) || true
fi
