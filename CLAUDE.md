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

**Deployment is server-side**: `.github/workflows/build-deploy.yml` runs on every push to `main` — it installs the system libraries, restores the pinned R packages from `renv.lock`, runs `quarto render`, and deploys the resulting `_book/` to GitHub Pages. So `_book/` (and `_freeze/`) are **gitignored and never committed**; you don't need to render locally before pushing. `quarto preview`/`quarto render` are just for checking your work. The only generated artifacts that *are* committed are the pre-rendered figure assets (the tikz PNGs in `images/`; see the tikz section) — those are built locally on purpose to keep LaTeX off the runner.

R package versions are pinned with `renv` (`renv.lock` + `renv/`). After adding or upgrading a package, run `renv::snapshot()` and commit the updated lockfile so CI installs the same set. The runner's system-dependency list in the workflow is derived from the lockfile via `pak::pkg_sysreqs(..., "ubuntu-24.04")`; regenerate it if a new package needs additional system libraries.

## Chapter inclusion

Only chapters listed under `book.chapters` in `_quarto.yml` are part of the rendered book. `linear_algebra.qmd`, `summary.qmd`, and `intro.qmd` are unlisted stubs/placeholders — adding content to them does nothing until they're added to `_quarto.yml`.

## R chunks

Chapters use R via `{r}` chunks for plotting (ggplot2 + cowplot, with `theme_cowplot()` set as default), tikz diagrams, and data fetching from Dataverse. There is no Python engine — the project is R-only.

Standard R chunk setup at the top of a chapter — one line, sourcing the shared setup file (packages, palette, default theme; see the ggplot styling section):

```r
source("_common.R")
```

Heavy chunks (Dataverse downloads, gganimate, tikz figures) carry `#| cache: true` (or `cache=TRUE` in inline form). The on-disk caches (`*_cache/`, `*_files/`) and `.quarto/` are gitignored.

## ggplot styling

Plots should read as part of the page, not as pasted-in R output: same palette, same warm neutrals, same sans face as the site chrome. The shared setup lives in `_common.R` (packages, the `mfpa` palette list, a `theme_set()` default, geom defaults, and a few annotation helpers); every chapter's setup chunk sources it. **Write plots plainly and let the defaults do the styling**: a bare `geom_line()` is already a teal curve at the house linewidth, `geom_vline()` is already dashed, `annotate("text", …)` is already ink/Archivo/size 5, and a mapped `colour = fn` already gets teal/red/green with no legend. Add arguments only to depart from a default, and take any colour from `mfpa$…` rather than hard-coding a hex string. The limits chapter is the reference implementation.

**Palette** — `mfpa$<name>` mirrors the `scss:defaults` block of `mfpa.scss`; keep the two in sync if either changes:

| `mfpa$` | Hex | SCSS | Use in plots |
|---|---|---|---|
| `teal` | `#0F6E6E` | `$primary` | the function/series of interest; default for a lone curve |
| `red` | `#B3261E` | `$danger` | a contrasting second series |
| `green` | `#2E7D46` | `$success` | a third series, if ever needed |
| `ink` | `#1E1B16` | `$body-color` | axes, axis text, dashed reference lines (theme default) |
| `muted` | `#6B645A` | `$mfpa-muted` | annotation text, de-emphasised reference lines, a low-salience third series |
| `rule` | `#E6DFD2` | `$mfpa-rule` | grid lines (theme default) |
| `paper` | `#FCFBF8` | `$body-bg` | fill for hollow markers, matching the page that shows through the transparent plot |

**Theme.** `_common.R` sets `theme_cowplot(font_family = "Archivo")` plus: transparent plot/panel backgrounds (the graphics device is also transparent via `_quarto.yml`, so the page's paper shows through); text, axis lines, and ticks in `ink`; a major grid in `rule` — so **don't call `background_grid()`**; `legend.position = "none"`, because every figure labels its series directly (opt back in per plot if a legend is ever the right call); and ggplot2 ≥ 4.0 geom defaults (`element_geom`) so unstyled geoms come out in `ink` and Archivo, with annotation text at size 5.

**Geom defaults and scales.** Set in `_common.R` via `update_geom_defaults()` and the `ggplot2.discrete.colour` / `.fill` options; an explicit argument always wins over a default.

| You write | You get |
|---|---|
| `geom_line()` | `teal`, `linewidth = 1.3` |
| `geom_point()` | `teal`; size stays per call |
| `geom_vline()` / `geom_hline()` | dashed, in `ink` |
| `aes(colour = fn)` | `teal`, `red`, `green` in level order; no legend |
| `annotate("text", …)` | `ink`, Archivo, size 5 |

Level order decides which series is teal, so order the columns in `pivot_longer()` (or set factor levels) with the series of interest first. For a low-salience third series in `muted`, or any other departure, call `scale_colour_manual()` explicitly.

**Helpers.** Also in `_common.R`; each returns a layer to add with `+`, and `x` / `y` may be vectors to draw several markers at once. All take `colour = mfpa$red` for a second series.

- `mark_value(x, y)` — solid point (`size = 4.5`) for the function's actual value at a point of interest.
- `mark_limit(x, y)` — hollow ring (`shape = 21`, `paper` fill) for a limit approached at a point.
- `shade_window(xmin, xmax)` — highlighted band on the x-axis (`teal`, `alpha = 0.08`).
- `label_curve(x, y, label)` — direct label coloured to match its curve, parsed as plotmath by default (`"italic(h)(x)"`, `"2^x"`); pass `parse = FALSE` for plain text; `hjust`, `vjust`, `size` pass through to `annotate()`.

**Font.** Archivo is not a system font on the CI runner or most machines. `_common.R` fetches it from Google Fonts with `systemfonts::require_font()` into the gitignored `_fonts/` directory on the first render, reuses the cached files afterwards, and aliases the system sans to "Archivo" if offline. This only works because `_quarto.yml` sets `dev: ragg_png`: the `ragg` device resolves fonts via `systemfonts`, whereas the default cairo `png` device only sees fontconfig's system fonts and silently falls back to the system sans. Don't override `dev` per chunk.

**Conventions from the limits chapter:**
- Piecewise functions get a `group` column so the pieces don't join across a jump. Put a `geom_vline()` at the point of interest, with `mark_value()` for the function's value and `mark_limit()` for the limit.
- Prefer direct labels (`label_curve()`) over legends. Math in labels and axis breaks via plotmath strings / `expression()`.
- Raw-data backdrop points in `mfpa$muted` at `alpha = 0.35`, small (`size = 0.9`); binned/summary points on top in the series colours.
- De-emphasised side notes: `annotate("text", …, colour = mfpa$muted, size = 3.6)`.
- Never use base greys, `"black"`, or `"white"` — they're cool-toned and clash with the warm paper. Reach for `ink` / `muted` / `rule` / `paper` instead.

**Cache gotcha.** Figure chunks are `cache: true` and keyed on their own code, so a change to `_common.R` (palette, theme, font) does **not** re-render existing figures locally. Run `quarto render . --cache-refresh` (target first: with the flag first, Quarto forwards a trailing `.` to pandoc, which fails on a directory) or delete the chapter's `*_cache/` directory after editing it. CI has no cache and always picks the change up.

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

## tikz figures (set theory chapter) — pre-rendered PNGs

`set_theory.qmd`'s Venn and function diagrams are **pre-rendered to committed PNGs**, not compiled on the fly. This keeps LaTeX out of the CI render (see the deploy section): the chapter has no R/tikz chunks at all and renders with Quarto alone.

The sources live in `images/tikz/*.tex` — one standalone document per figure (`\documentclass{standalone}` + `venndiagram` or `tikz`/`arrows`). `images/tikz/build.sh` compiles each with `latexmk -pdf` and rasterizes to `images/<name>.png` (300 dpi via `pdftoppm`, falling back to ImageMagick). Run it **locally** after editing a diagram:

```bash
bash images/tikz/build.sh   # needs LaTeX with standalone+venndiagram, and pdftoppm/magick
```

The `.qmd` embeds the PNGs as ordinary figures, preserving the crossref ids — standalone figures keep their `{#fig-…}`, and Venn pairs sit in `::: {#fig-… layout-ncol=2}` panels with each image's alt text becoming the subfigure caption. When changing a diagram: edit its `.tex`, re-run `build.sh`, and commit both the `.tex` and the regenerated `.png`.

## Animated figures — pre-rendered GIFs

Animations follow the same pattern as the tikz diagrams: **rendered locally, committed, embedded as a markdown figure**. `gganimate` imports `transformr`, which imports `sf`, which needs GDAL/GEOS/PROJ/udunits on the runner — that whole chain was deliberately dropped from `renv.lock` and the workflow's apt list, so don't put `gganimate` in a chunk.

The source scripts live in `images/anim/*.R`, one per animation. Each sources `_common.R` (so the palette, theme, and Archivo apply), renders with `animate(..., device = "ragg_png", bg = mfpa$paper, renderer = gifski_renderer("images/<name>.gif"))`, and is run **from `notes/`**:

```bash
Rscript images/anim/derivative_approximation.R
```

Use a paper-coloured background rather than transparency: GIF transparency is 1-bit and leaves jagged anti-aliasing edges. The `.qmd` embeds the output as `![caption](images/<name>.gif){#fig-…}`, which keeps the crossref id. When changing an animation: edit the script, re-run it, and commit both the script and the regenerated GIF. `gganimate` and `gifski` need to be installed locally but are not tracked by `renv`.

## Styling & design

`mfpa.scss` extends the `cosmo` Bootswatch theme (set in `_quarto.yml`) into an editorial light theme. The design language lives in the `scss:defaults` block:

- **Type**: Source Serif 4 body + Archivo headings/sidebar/chrome; Iosevka Web monospace.
- **Palette**: deep teal `#0F6E6E` primary on near-white warm paper `#FCFBF8`; `$success` green / `$danger` red drive example boxes and the `.tt`/`.ff` truth values.

Conventions that aren't obvious from the markup:

- **Light theme only.** `_quarto.yml` sets `theme: [cosmo, mfpa.scss]` — a single light theme, no dark variant. `mfpa-dark.scss` sits on disk as groundwork for a later dark pass but is **not wired in**; don't re-add a `dark:` theme block until that palette is finished.
- **"CHAPTER N" eyebrow** is pure CSS: it restyles Quarto's `.chapter-number` span inside `#title-block-header h1.title` into an eyebrow (a `::before` adds the "Chapter " prefix). The rule is scoped to the title block — don't restyle `.chapter-number` / `.chapter-title` globally, since the sidebar and breadcrumb reuse the same spans. Unnumbered front matter (Preface, References) has no `.chapter-number` and just shows the bare title.
- **Folded TOC.** `_includes/sidebar-toc.html` (wired via `include-after-body`) relocates the right-hand page TOC into the left sidebar under the active chapter, with a small `IntersectionObserver` for active-section highlighting; the right margin sidebar (`#quarto-margin-sidebar`) is hidden in CSS. Keep `toc: true` so the list is still generated for relocation.
- **Single centred column + inline asides.** On wide screens (≥992px) `mfpa.scss` overrides the docked `.page-columns` grid to collapse the right margin and dead-centre the reading column (36rem on chapters — empirically ~76 chars/line in Source Serif 4 at the 18px root; the mockup's 40rem measured a too-wide 86 CPL). As a result, margin notes — `.column-margin` / `.margin-aside`, i.e. `::: {.aside}` content — are pulled **inline** into the text flow (Quarto's own narrow-screen mechanism) and styled as teal-ruled notes rather than margin floats.
- **Boxes.** theorem/lemma/proposition/corollary render as teal boxes, examples green, exercises a teal outline, proofs a subtle box; `.theorem-title` / `.proof-title` are forced onto their own line. Note callouts are retinted teal.
- **Definitions are deliberately un-boxed.** To distinguish *defining* something from making a *provable claim* (theorem/lemma/proposition/corollary, which keep the teal box), `.theorem.definition` is restyled in `mfpa.scss`: no box, instead bracketed top-and-bottom by teal hairline rules, symmetrically inset (`margin: … 1.75rem`), with the title set as a small-caps teal eyebrow (uppercase, letter-spaced). The trailing paragraph's bottom margin is zeroed so the bottom rule hugs the last line, governed by the block's own padding. Quarto already tags the type via `class="theorem definition"`, so this needs no `.qmd` markup change.

If a block isn't styled the way you expect, check `mfpa.scss` for a class selector before adjusting markup.
