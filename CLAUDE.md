# CLAUDE.md — `notes/`

Guidance for working inside the Quarto book that builds <https://bkenkel.com/mfpa>. The top-level `CLAUDE.md` has cross-cutting context; this file documents conventions specific to the book.

## Repo boundary

`notes/` is its **own git repository** with its own remote (<https://github.com/brentonk/mfpa>), nested inside the parent Dropbox folder. Treat it as a sibling project, not a subdirectory:
- Run `git` commands from inside `notes/`, not from the parent.
- The parent repo is not version-controlled, so changes outside `notes/` don't have a git safety net.

## Build, preview, deploy

```bash
quarto preview           # live-reload local preview (cheap)
quarto render            # rebuild whole book into _book/
quarto render logic.qmd  # render one chapter
```

**Deployment is unusual**: `.github/workflows/static.yml` uploads `_book/` directly to GitHub Pages with no `quarto render` step in CI. That means the committed `_book/` directory **is** the published site. After meaningful changes, run `quarto render` locally and commit the regenerated `_book/` along with the source.

## Chapter inclusion

Only chapters listed under `book.chapters` in `_quarto.yml` are part of the rendered book. `linear_algebra.qmd`, `summary.qmd`, and `intro.qmd` are unlisted stubs/placeholders — adding content to them does nothing until they're added to `_quarto.yml`.

## R chunks

Chapters use R via `{r}` chunks for plotting (ggplot2 + cowplot, with `theme_cowplot()` set as default), tikz diagrams, and data fetching from Dataverse. There is no Python engine — the project is R-only.

Standard R chunk setup at the top of a chapter:

```r
library("tidyverse"); library("cowplot"); theme_set(theme_cowplot())
```

Heavy chunks (Dataverse downloads, gganimate, tikz figures) carry `#| cache: true` (or `cache=TRUE` in inline form). The on-disk caches (`*_cache/`, `*_files/`) and `.quarto/` are gitignored.

## Concept glossary pattern

The glossary is built by a Lua filter (`_filters/concepts.lua`, registered in `_quarto.yml` with `at: pre-ast` so its output flows through Quarto's tabset transformer). Authors colocate the definition with the first prose mention of a term:

```
We can formulate this using the [set difference]{.concept definition="The set difference between $A$ and $B$, denoted $A \setminus B$, is the set of all elements that are in $A$ and are not in $B$."}.
```

Subsequent mentions in the same chapter use the bare class, which renders as a styled span without adding another glossary entry:

```
The [set difference]{.concept} between two sets...
```

The filter collects every `.concept` span that has a `definition` attribute, keyed by the span content. The glossary entry defaults to the span text with the first letter uppercased — so `[union]{.concept ...}` becomes "Union" in the glossary. Use an explicit `entry="..."` to override when the prose form doesn't match the canonical key (plurals, hyphenation, alternate forms):

```
[bijections]{.concept entry="Bijection" definition="..."}
[disjoint]{.concept entry="Disjoint sets" definition="..."}
[logically equivalent]{.concept entry="Logical equivalence" definition="..."}
```

Where the glossary should appear — typically at the end of the chapter — drop an empty marker div. The filter replaces it with a `## Concept review` section containing a `.panel-tabset` with "Conceptual order" (insertion order, i.e., the order definitions appear in prose) and "Alphabetical order" tabs:

```
::: {#concept-review}
:::
```

A `.concept` span with no `definition=` and no prior matching entry just passes through styled — no warning, no glossary entry. This is by design: many prose terms (`[Theorem]`, `[continuous]`, etc.) are styled for emphasis without being formal glossary entries.

For synonym/cross-reference entries, embed a nested `.concept` span inside the definition:

```
[injective]{.concept definition="Another name for [one-to-one]{.concept}."}
```

The inner span has no `definition`, so it doesn't create a duplicate glossary entry — it just renders as a styled cross-reference inside the glossary card.

**Hover/tap tooltips.** Beyond the glossary, the filter attaches each concept's definition to *every* mention as a tooltip. Spans whose key has a definition get a `.has-tip` class, `tabindex="0"`, and a nested `<span class="concept-tip">` holding the definition parsed as Markdown inlines (so its math typesets — don't stuff definitions into plain attributes, where `$…$` would show literally). Reveal is CSS-driven in `mfpa.scss` (hover / keyboard focus / a `.tip-open` class); `_includes/concept-tooltip.html` adds tap-to-toggle on touch and clamps the popover to the viewport. A bare later mention resolves its definition by its normalized text, or by an explicit `entry=` when the prose form differs from the canonical key.

## Custom span classes

Defined in `mfpa.scss`:
- `[term]{.concept}` — teal, bold, dotted underline; first introduction of vocabulary. Mentions of a term that has a `definition=` anywhere in the chapter also get a hover/tap tooltip (`.has-tip`; see the glossary section)
- `[true]{.tt}` / `[false]{.ff}` — green / red; used heavily in `logic.qmd` truth tables (no other chapter uses them)
- `[note]{.todo}` — yellow highlight that auto-prefixes "TODO:"; use as inline markers for self-notes

## Cross-referenced environments

Use Quarto's native theorem/exercise blocks with these prefixes (matching `quarto`'s defaults):
- `def-` definition, `thm-` theorem, `prp-` proposition, `cor-` corollary, `lem-` lemma
- `exr-` exercise, `exm-` example
- `fig-` figure, `tbl-` table, `sec-` section, `eq-` equation

Reference with `@prefix-name` (e.g., `@def-limit-function`). The `name="..."` attribute sets the displayed title.

**Collapsible answers** to exercises nest a callout inside the exercise block. Colon-fence depth must increase with nesting:

```
::: {#exr-some-exercise}
Question text.

:::: {.callout-note title="Answer" collapse="true"}
Answer text.
::::
:::
```

## Editorial asides (remark / pitfall / optional)

`_filters/remark.lua` provides un-boxed blocks for the author's *voice* — study advice, notation conventions, digressions, common pitfalls. The governing rule: **boxes mean formal mathematical structure** (theorem/definition/example/exercise/proof), so the author's voice gets an *un-boxed* aside instead of a callout. These replace most Quarto callouts.

- `[remark]` — `::: {.remark title="…"}` — accent left rule + a diamond-marked (◆), sentence-case Archivo title; body set in Archivo (a register shift from the Source Serif exposition) at 0.94rem, full-ink. For asides you should still read.
- `[pitfall]` — `::: {.pitfall title="…"}` — same chassis in `$danger` red with a ▲ marker; for common confusions/errors.
- `[optional]` — `::: {.optional title="…"}` — collapsible disclosure reusing `details.answer-block` (label defaults to "Optional"); for genuinely skippable technical material.

The `title=` is parsed as Markdown, so `$math$`, `@refs`, and emphasis resolve (mirrors `answer.lua`). Use `title=`, **not** a `## heading` inside the div, so the aside stays out of the section TOC. Styling lives in `mfpa.scss` under `.remark` / `.pitfall` / `.remark-title`.

**Gotcha:** `.remark` is a reserved Quarto proof-type environment (like `.proof` / `.solution`), so `remark.lua` is registered `at: pre-ast` in `_quarto.yml` to claim the div before Quarto's crossref pass rewrites it into a proof-style box.

**Crossref caveat:** a `.remark` / `.pitfall` div is *not* a crossref target. A callout referenced by `@id` (e.g. a `callout-note` cited elsewhere) can't be converted without rehoming the reference.

## tikz figures (set theory chapter)

`set_theory.qmd` renders Venn diagrams via the LaTeX `venndiagram` package through `tikzDevice`. The setup chunk defines `eo` for engine.opts:

```r
library("tikzDevice")
eo <- list(extra.preamble="\\usepackage{venndiagram}")
```

Subsequent tikz chunks pass `engine="tikz", engine.opts=eo, cache=TRUE`. A working LaTeX install with `venndiagram.sty` is required for these to render.

## Styling & design

`mfpa.scss` extends the `cosmo` Bootswatch theme (set in `_quarto.yml`) into an editorial light theme. The design language lives in the `scss:defaults` block:

- **Type**: Source Serif 4 body + Archivo headings/sidebar/chrome; Iosevka Web monospace.
- **Palette**: deep teal `#0F6E6E` primary on near-white warm paper `#FCFBF8`; `$success` green / `$danger` red drive example boxes and the `.tt`/`.ff` truth values.

Conventions that aren't obvious from the markup:

- **Light theme only.** `_quarto.yml` sets `theme: [cosmo, mfpa.scss]` — a single light theme, no dark variant. `mfpa-dark.scss` sits on disk as groundwork for a later dark pass but is **not wired in**; don't re-add a `dark:` theme block until that palette is finished.
- **"CHAPTER N" eyebrow** is pure CSS: it restyles Quarto's `.chapter-number` span inside `#title-block-header h1.title` into an eyebrow (a `::before` adds the "Chapter " prefix). The rule is scoped to the title block — don't restyle `.chapter-number` / `.chapter-title` globally, since the sidebar and breadcrumb reuse the same spans. Unnumbered front matter (Preface, References) has no `.chapter-number` and just shows the bare title.
- **Folded TOC.** `_includes/sidebar-toc.html` (wired via `include-after-body`) relocates the right-hand page TOC into the left sidebar under the active chapter, with a small `IntersectionObserver` for active-section highlighting; the right margin sidebar (`#quarto-margin-sidebar`) is hidden in CSS. Keep `toc: true` so the list is still generated for relocation.
- **Single centred column + inline asides.** On wide screens (≥992px) `mfpa.scss` overrides the docked `.page-columns` grid to collapse the right margin and dead-centre the reading column (~40rem on chapters, matching the design mockup in `_design_previews/`). As a result, margin notes — `.column-margin` / `.margin-aside`, i.e. `::: {.aside}` content — are pulled **inline** into the text flow (Quarto's own narrow-screen mechanism) and styled as teal-ruled notes rather than margin floats.
- **Boxes.** theorem/definition/proposition/corollary render as teal boxes, examples green, exercises a teal outline, proofs a subtle box; `.theorem-title` / `.proof-title` are forced onto their own line. Note callouts are retinted teal.

If a block isn't styled the way you expect, check `mfpa.scss` for a class selector before adjusting markup.
