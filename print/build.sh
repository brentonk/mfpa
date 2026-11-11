#!/usr/bin/env bash
# Build the printable PDF of the MFPA notes for distribution to students.
#
# Renders the Quarto book to PDF via Typst (bundled with Quarto — no LaTeX
# required), using the `print` profile (_quarto-print.yml).  That profile plus
# the guarded Lua filters (_filters/print-answers.lua and the print branches in
# concepts.lua / remark.lua) move exercise answers to a section at the back,
# flatten each chapter's interactive glossary to a plain list, and suppress the
# hover tooltips that only make sense on the website.
#
# The HTML website build is untouched — this only runs when you invoke it.
#
# Usage:
#   print/build.sh          # build the whole book
#   print/build.sh --open   # build, then open the PDF
#   print/build.sh --refresh-figures   # re-run R chunks for print first
#
# --refresh-figures clears the frozen Typst results (_freeze/*/…typ.json and
# figure-typst/), so every chapter re-executes and its figures pick up the
# current print settings (e.g. fig-dpi in _quarto-print.yml). The website's
# frozen HTML results are left alone. Options can be combined.
#
# Re-run it whenever you add or edit a chapter; R chunks are reused from the
# Quarto freeze cache, so it is cheap unless computational code changed.

set -euo pipefail

# Resolve the notes/ directory (parent of this script's dir) and work from it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTES_DIR="$(dirname "$SCRIPT_DIR")"
cd "$NOTES_DIR"

OPEN=0
REFRESH=0
for arg in "$@"; do
  case "$arg" in
    --open) OPEN=1 ;;
    --refresh-figures) REFRESH=1 ;;
    *) echo "!! Unknown option: $arg" >&2; exit 2 ;;
  esac
done

OUT_NAME="mfpa-lecture-notes"
DEST="$SCRIPT_DIR/${OUT_NAME}.pdf"

if [[ $REFRESH -eq 1 ]]; then
  echo ">> Clearing frozen Typst results so R chunks re-run…"
  rm -rf _freeze/*/execute-results/typ.json _freeze/*/figure-typst ./*_files/figure-typst
fi

echo ">> Rendering ${OUT_NAME}.pdf (Typst, print profile)…"
quarto render --to typst --profile print

SRC="_book/${OUT_NAME}.pdf"
if [[ ! -f "$SRC" ]]; then
  echo "!! Expected output not found at $SRC" >&2
  exit 1
fi

mkdir -p "$SCRIPT_DIR"
cp -f "$SRC" "$DEST"
echo ">> Wrote $DEST"

if [[ $OPEN -eq 1 ]]; then
  ( xdg-open "$DEST" >/dev/null 2>&1 || open "$DEST" >/dev/null 2>&1 ) || true
fi
