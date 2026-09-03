// Print-profile overrides, injected at the top of the body via
// include-before-body (_quarto-print.yml) so they land AFTER the orange-book
// template's own show/set rules and win. See print/README.md.

// --- Page size -------------------------------------------------------------
// Quarto's `papersize` only reaches an early #set page, which the orange-book
// book template resets to a4; re-force US Letter here.
#set page(paper: "us-letter")

// --- Base font size --------------------------------------------------------
// Quarto's `fontsize` suffers the same fate: book.with() re-sets text to the
// template's font-size default (10pt). Re-force the lecture-notes size here.
#set text(size: 12pt)

// --- Line spacing ----------------------------------------------------------
// ~1.5 spacing for consulting on the fly while teaching (the template sets a
// tight leading of 0.5em). Typst's `leading` is the gap between lines, not the
// baseline-to-baseline multiple: 1em leading at 12pt lands near LaTeX's
// onehalfspacing. Paragraph spacing is bumped to keep breaks distinguishable.
#set par(leading: 1em, spacing: 1.4em)

// --- Theorem-type environments: left-aligned boxes -------------------------
// Quarto renders definition/theorem/etc. via theorion frames, which are Typst
// figures — and orange-book's blanket `show figure: set align(center)` centers
// their text. Restyle every theorem-ish kind as a left-aligned box: light
// teal-tinted fill with a teal left accent bar (echoing the website's palette;
// prints fine in grayscale). "lemma" and "example" have no frames in the book
// yet, but Quarto will generate them the first time a lem-/exm- block is used,
// so they're covered preemptively.
#let theorem-box(it) = {
  set align(left)
  block(
    width: 100%,
    fill: rgb("#0F6E6E").lighten(94%),
    stroke: (left: 2.5pt + rgb("#0F6E6E")),
    inset: (x: 12pt, y: 10pt),
    radius: (right: 3pt),
    breakable: true,
    spacing: 1.2em,
    it.body,
  )
}
#show figure.where(kind: "definition"): theorem-box
#show figure.where(kind: "theorem"): theorem-box
#show figure.where(kind: "proposition"): theorem-box
#show figure.where(kind: "corollary"): theorem-box
#show figure.where(kind: "lemma"): theorem-box
#show figure.where(kind: "example"): theorem-box
#show figure.where(kind: "exercise"): theorem-box
