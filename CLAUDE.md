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

## R + Python in the same chapter

Most chapters mix both engines. R chunks (`{r}`) handle plotting (ggplot2 + cowplot, with `theme_cowplot()` set as default), tikz diagrams, and data fetching from Dataverse. Python chunks (`{python}`) maintain the concept glossary. They don't share variable state — the only thing that crosses engines is the rendered output.

Standard R chunk setup at the top of a chapter:

```r
library("tidyverse"); library("cowplot"); theme_set(theme_cowplot())
```

Heavy chunks (Dataverse downloads, gganimate, tikz figures) carry `#| cache: true` (or `cache=TRUE` in inline form). The on-disk caches (`*_cache/`, `*_files/`) and `.quarto/` are gitignored.

## Concept glossary pattern

Every chapter builds a glossary inline. Setup at the top:

```python
concepts = {}
```

Then, as terms are introduced in prose, add them in a nearby chunk:

```python
concepts.update({
  "Term name": "Definition with $\\LaTeX$ allowed.",
})
```

In prose, mark the first occurrence of the term with `[term name]{.concept}` (custom span class, styled blue+bold in `mfpa.scss`).

At the very end of the chapter, render the dual-sorted glossary:

````
```{python, echo=FALSE, results="asis"}
from helpers import concept_table
print(concept_table(concepts))
```
````

`concept_table` (in `helpers.py`) emits a `.panel-tabset` with "Conceptual order" (insertion order) and "Alphabetical order" tabs.

## Custom span classes

Defined in `mfpa.scss`:
- `[term]{.concept}` — blue, bold; used for first introduction of vocabulary
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

## tikz figures (set theory chapter)

`set_theory.qmd` renders Venn diagrams via the LaTeX `venndiagram` package through `tikzDevice`. The setup chunk defines `eo` for engine.opts:

```r
library("tikzDevice")
eo <- list(extra.preamble="\\usepackage{venndiagram}")
```

Subsequent tikz chunks pass `engine="tikz", engine.opts=eo, cache=TRUE`. A working LaTeX install with `venndiagram.sty` is required for these to render.

## Styling

`mfpa.scss` extends the `cosmo` Bootswatch theme (set in `_quarto.yml`). Iosevka Web is loaded for monospace. Theorem/proof/exercise blocks get rounded borders in primary color; examples use success-green. If a block isn't styled the way you expect, check `mfpa.scss` for a class selector before adjusting markup.
