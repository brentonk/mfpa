-- Editorial asides — un-boxed "remark"/"pitfall" blocks and a collapsible
-- "optional" disclosure, replacing distracting Quarto callouts for content that
-- is the author's voice rather than formal mathematical structure. Boxes are
-- reserved for theorems/definitions/examples/exercises/proofs; these are not
-- boxes. Styling lives in mfpa.scss (`.remark` / `.pitfall`); `.optional`
-- reuses `details.answer-block` (see _filters/answer.lua).
--
--   ::: {.remark title="Doing the exercises..."}    -> ◆ teal title + left rule
--   ::: {.pitfall title="Inclusion $\in$ vs $\subseteq$"} -> ▲ red title + left rule
--   ::: {.optional title="Extension to..."}          -> collapsible <details>, "Optional"
--
-- The title is parsed as Markdown inlines so math / @refs / emphasis resolve,
-- mirroring _filters/answer.lua. Using `title=` (not a `## heading` inside the
-- div) keeps these out of the section TOC.

local function md_inlines(s)
  return pandoc.utils.blocks_to_inlines(pandoc.read(s, "markdown").blocks)
end

-- True for any non-HTML target (the print/lecture PDF via Typst). For print,
-- remark/pitfall asides are dropped entirely (the website is the canonical
-- distributed form; the PDF is a teaching copy), and `optional` blocks lose
-- their collapsible affordance in favor of a plain bold title. HTML behaviour
-- is unchanged.
local function is_print()
  if quarto and quarto.doc and quarto.doc.is_format then
    return not quarto.doc.is_format("html")
  end
  return FORMAT ~= "html"
end

function Div(el)
  local is_remark   = el.classes:includes("remark")
  local is_pitfall  = el.classes:includes("pitfall")
  local is_optional = el.classes:includes("optional")
  if not (is_remark or is_pitfall or is_optional) then
    return nil
  end

  local title = el.attributes["title"]

  if is_print() then
    -- The lecture PDF is a teaching copy, not a distribution copy (the website
    -- is canonical): drop the remark/pitfall asides entirely. `.optional`
    -- blocks are actual course content, so those are kept, expanded, with a
    -- plain bold title in place of the collapsible affordance.
    if is_remark or is_pitfall then
      return {}
    end
    local blocks = pandoc.List()
    if title == nil or title == "" then title = "Optional" end
    local titleline = pandoc.List()
    titleline:extend(md_inlines(title))
    blocks:insert(pandoc.Para({ pandoc.Strong(titleline) }))
    blocks:extend(el.content)
    return blocks
  end

  -- Collapsible "optional / technical" disclosure: same chassis as the answer
  -- block, defaulting to the label "Optional".
  if is_optional then
    if title == nil or title == "" then title = "Optional" end
    local summary = pandoc.List()
    summary:insert(pandoc.RawInline("html",
      '<summary class="answer-summary">' ..
      '<span class="answer-affordance" aria-hidden="true"></span>' ..
      '<span class="answer-label">'))
    summary:extend(md_inlines(title))
    summary:insert(pandoc.RawInline("html", '</span></summary>'))

    local blocks = pandoc.List()
    blocks:insert(pandoc.RawBlock("html", '<details class="answer-block optional">'))
    blocks:insert(pandoc.Plain(summary))
    blocks:insert(pandoc.RawBlock("html", '<div class="answer-body">'))
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock("html", '</div></details>'))
    return blocks
  end

  -- Un-boxed remark / pitfall: accent left rule + diamond-marked title.
  local cls = is_pitfall and "pitfall" or "remark"
  local blocks = pandoc.List()
  blocks:insert(pandoc.RawBlock("html", '<div class="' .. cls .. '">'))
  if title ~= nil and title ~= "" then
    local titleline = pandoc.List()
    titleline:insert(pandoc.RawInline("html", '<span class="remark-title">'))
    titleline:extend(md_inlines(title))
    titleline:insert(pandoc.RawInline("html", '</span>'))
    blocks:insert(pandoc.Plain(titleline))
  end
  blocks:extend(el.content)
  blocks:insert(pandoc.RawBlock("html", '</div>'))
  return blocks
end
