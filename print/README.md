# Printable notes

A repeatable pipeline that renders the book to a **print-friendly PDF** for
distributing to students, without touching the HTML website build. Exercises
stay in place; their answers are collected in a section at the back of the
book, and each exercise ends with a linked "Answer: p. N" pointer.

## Build it

```bash
print/build.sh          # -> print/mfpa-lecture-notes.pdf
print/build.sh --open   # build, then open the PDF
print/build.sh --refresh-figures   # re-run every chapter's R chunks first
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

For single-file formats like Typst, Quarto merges every chapter into **one**
Pandoc document, so the Lua filters see the whole book at once and use level-1
headers to tell chapters apart.

- **`_quarto-print.yml`** — the profile. Adds the `typst` format (US Letter,
  11pt, TOC, numbered sections, R figures at `fig-dpi: 300`), names the output `mfpa-lecture-notes.pdf`, and
  sets `exercise-answers-title`, the heading of the answers section. It's only
  merged when `--profile print` is passed, so ordinary `quarto render` /
  `quarto preview` / the CI deploy are untouched.
- **`print/paper-override.typ`** — Typst overrides injected at the top of the
  body (via `include-before-body`), where they beat the orange-book template's
  own rules: re-forces US Letter and 11pt (the template resets both), sets
  ordinary book spacing (`leading: 0.75em`, about 1.3× line height), restyles
  the theorem-type environments as left-aligned boxes with a teal accent bar
  (orange-book's blanket `show figure: set align(center)` otherwise centers
  them, since theorion theorems are Typst figures), and defines the helpers the
  filters emit: `mfpa-aside` / `mfpa-aside-title` for remarks and pitfalls, and
  `mfpa-answer-pointer` for the exercise → answer link.
- **`_filters/print-answers.lua`** — lifts each `#exr-…` exercise's nested
  `.answer` div out of the exercise, leaves the page pointer in its place, and
  inserts an unnumbered answers section just before References, grouped under
  each chapter's title. Each answer is headed by a cross-reference to its
  exercise ("Exercise 1.3"), plus the answer's `title=` if it isn't the default
  "Answer"/"Answers". Display equations in that section are unnumbered (they'd
  otherwise pick up the last chapter's counter). Runs `pre-ast`, before Quarto's
  crossref pass. An `.answer` outside an exercise is left in place with a
  warning.
- **`_filters/print-math-compat.lua`** — rewrites TeX-math macros the Typst
  writer can't translate (`\mathclap` and friends, `\textcolor`).
- Print branches in **`_filters/concepts.lua`** and **`_filters/remark.lua`**:
  suppress the hover tooltips (they'd otherwise be dumped inline), flatten each
  chapter's tabbed glossary to a single definition list of *that chapter's*
  concepts, render remark/pitfall asides with a coloured left rule and title
  (◆ / ▲, as on the website), and expand `.optional` blocks under a plain bold
  title. In print, `concepts.lua` gathers `\newcommand` macros from every `.qmd`
  in the project so glossary definitions (e.g. `\intr`) typeset.

Figure resolution: freeze keeps a separate Typst copy of each chapter's results
(`_freeze/<chapter>/execute-results/typ.json` + `figure-typst/`) and only
re-executes a chapter when its source changes, so a change to `fig-dpi` (or any
other figure setting in the profile) doesn't reach existing figures on its own.
`--refresh-figures` clears those Typst results so every chapter re-runs; the
website's frozen HTML results are untouched. Pre-rendered images in `images/`
(tikz PNGs, the derivatives GIF) are not affected — their resolution is set by
their own build scripts.

The output is **US Letter**. The `paper-override.typ` injection lands *after*
the template's cover + table of contents, so those first few front-matter pages
stay a4 (and template-sized type) while every content page is Letter at 11pt —
a cosmetic mix that prints fine (and not worth the brittle template surgery to
unify).

All of the print-specific behavior is guarded to fire on **non-HTML targets
only** (`is_format("html")`), so the website renders exactly as before. You can
confirm that: after a normal `quarto render`, the HTML still has its collapsed
answers, `.has-tip` tooltips, and the `.panel-tabset` glossary.
