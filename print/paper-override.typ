// Print-profile overrides, injected at the top of the body via
// include-before-body (_quarto-print.yml) so they land AFTER the orange-book
// template's own show/set rules and win. See print/README.md.

// --- Page size -------------------------------------------------------------
// Quarto's `papersize` only reaches an early #set page, which the orange-book
// book template resets to a4; re-force US Letter here.
#set page(paper: "us-letter")

// --- Base font size --------------------------------------------------------
// Quarto's `fontsize` suffers the same fate: book.with() re-sets text to the
// template's font-size default (10pt). Re-force the book's size here.
#set text(size: 11pt)

// --- Line spacing ----------------------------------------------------------
// Ordinary book spacing, a little looser than the template's tight 0.5em
// leading. Typst's `leading` is the gap between lines, not the baseline-to-
// baseline multiple: 0.75em at 11pt gives roughly 1.3x line height. Paragraph
// spacing is a bit larger so breaks stay distinguishable.
#set par(leading: 0.75em, spacing: 1.2em)

// --- House colours (mirror mfpa.scss / _common.R) -------------------------
#let mfpa-teal = rgb("#0F6E6E")
#let mfpa-red = rgb("#B3261E")
#let mfpa-muted = rgb("#6B645A")

// --- Remark / pitfall asides -----------------------------------------------
// Emitted by _filters/remark.lua as `#mfpa-aside("remark")[ … ]`. Un-boxed, as
// on the website: a coloured left rule, with a marker + title line set by
// mfpa-aside-title.
#let mfpa-aside-color(kind) = if kind == "pitfall" { mfpa-red } else { mfpa-teal }
#let mfpa-aside(kind, body) = block(
  width: 100%,
  breakable: true,
  stroke: (left: 1.5pt + mfpa-aside-color(kind)),
  inset: (left: 12pt, y: 3pt),
  spacing: 1.2em,
  {
    set text(size: 0.95em)
    body
  },
)
#let mfpa-aside-title(kind, body) = text(
  weight: "bold",
  fill: mfpa-aside-color(kind),
)[#(if kind == "pitfall" { "▲" } else { "◆" }) #body]

// --- Exercise answers ------------------------------------------------------
// _filters/print-answers.lua moves each exercise's answer to the answers
// section at the back, marks it with `#metadata(..) <ans-exr-…>`, and leaves a
// pointer at the end of the exercise: `#mfpa-answer-pointer(label("ans-exr-…"))`.
#let mfpa-answer-pointer(target) = context {
  let loc = locate(target)
  align(right, text(size: 0.9em, fill: mfpa-muted,
    link(loc)[Answer: p. #counter(page).at(loc).first()]))
}

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
