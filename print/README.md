# Printable lecture notes

A repeatable pipeline that renders the book to a **print-friendly, exercise-free
PDF** you can lecture from, without touching the HTML website build.

## Build it

```bash
print/build.sh          # -> print/mfpa-lecture-notes.pdf
print/build.sh --open   # build, then open the PDF
```

Re-run it whenever you add or edit a chapter. R chunks are reused from Quarto's
freeze cache, so it's cheap unless computational code actually changed. The only
requirement is `quarto` — the PDF is produced with **Typst**, which ships inside
Quarto, so no LaTeX/TeX install is needed.

## How it works

The build renders the normal Quarto book to Typst under the `print` profile:

```bash
quarto render --to typst --profile print
```

- **`_quarto-print.yml`** — the profile. Adds the `typst` format (US Letter,
  1" margins, 12pt, TOC, numbered sections) and names the output
  `mfpa-lecture-notes.pdf`. It's only merged when `--profile print` is passed,
  so ordinary `quarto render` / `quarto preview` / the CI deploy are untouched.
- **`print/paper-override.typ`** — Typst overrides injected at the top of the
  body (via `include-before-body`), where they beat the orange-book template's
  own rules: re-forces US Letter and 12pt (the template resets both), sets
  ~1.5 line spacing (`leading: 1em`), and restyles the theorem-type
  environments (definition / theorem / proposition / corollary / lemma /
  example / exercise) as left-aligned boxes with a teal accent bar —
  orange-book's blanket `show figure: set align(center)` otherwise centers
  their text, since theorion theorems are Typst figures.
- **`_filters/strip-exercises.lua`** — drops `#exr-…` exercise blocks (and their
  nested answers). Runs `pre-ast`, before Quarto's crossref pass.
- **`_filters/print-math-compat.lua`** — rewrites TeX-math macros the Typst
  writer can't translate (currently `\mathclap` and friends).
- Print branches added to **`_filters/concepts.lua`** and
  **`_filters/remark.lua`**: suppress the hover tooltips (they'd otherwise be
  dumped inline), flatten the tabbed glossary to a single definition list,
  drop the remark/pitfall asides entirely (the website is the canonical
  distributed form; the PDF is a teaching copy), and expand `.optional` blocks
  under a plain bold title.

The output is **US Letter**. The `paper-override.typ` injection lands *after*
the template's cover + table of contents, so those first few front-matter pages
stay a4 (and template-sized type) while every content page is Letter at 12pt —
a cosmetic mix that prints fine (and not worth the brittle template surgery to
unify).

All of the print-specific behavior is guarded to fire on **non-HTML targets
only** (`is_format("html")`), so the website renders exactly as before. You can
confirm that: after a normal `quarto render`, the HTML still has its exercises,
`.has-tip` tooltips, and the `.panel-tabset` glossary.

## Exercises that are kept on purpose

`strip-exercises.lua` removes exercises **except** any that the surrounding
prose still refers to by cross-reference — deleting those would leave a dangling
`?@exr-…` link. As of this writing that's two exercises, kept because the
narrative leans on them:

- `exr-pres-vp-functions` — "As you saw in my answer to @exr-pres-vp-functions…"
  (`set_theory.qmd`)
- `exr-limit-linear-function` — referenced three times in
  `limits_and_continuity.qmd`

If you'd rather those be excised too, reword the referencing sentences so they
no longer cite the exercise, and they'll drop out automatically on the next
build. (Cross-references that span chapters aren't detected — the filter works
per chapter — so if you ever cite an exercise from a *different* chapter, keep an
eye out for a dangling-reference warning in the build log.)
