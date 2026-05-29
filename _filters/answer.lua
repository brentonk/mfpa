-- Turn `::: {.answer}` divs into a native collapsible disclosure for exercise
-- answers / hidden worked solutions, replacing the old blue note callout.
--
--   ::: {.answer}                -> <details> labelled "Answer"
--   ::: {.answer title="Part b"} -> <details> labelled "Part b"
--
-- Collapsed by default (native <details>, no JavaScript). The title is parsed
-- as Markdown inlines so cross-references / emphasis / math in it resolve
-- normally (e.g. title="Answer that uses @exr-lottery-limit"). Styling lives
-- in mfpa.scss under `details.answer-block`.

function Div(el)
  if not el.classes:includes("answer") then
    return nil
  end

  local title = el.attributes["title"]
  if title == nil or title == "" then
    title = "Answer"
  end

  -- Parse the label as Markdown so @refs etc. survive into Quarto's crossref
  -- pass instead of being frozen as literal text.
  local label = pandoc.utils.blocks_to_inlines(
    pandoc.read(title, "markdown").blocks
  )

  local summary = pandoc.List()
  summary:insert(pandoc.RawInline("html",
    '<summary class="answer-summary">' ..
    '<span class="answer-affordance" aria-hidden="true"></span>' ..
    '<span class="answer-label">'))
  summary:extend(label)
  summary:insert(pandoc.RawInline("html", '</span></summary>'))

  local blocks = pandoc.List()
  blocks:insert(pandoc.RawBlock("html", '<details class="answer-block">'))
  blocks:insert(pandoc.Plain(summary))
  blocks:insert(pandoc.RawBlock("html", '<div class="answer-body">'))
  blocks:extend(el.content)
  blocks:insert(pandoc.RawBlock("html", '</div></details>'))
  return blocks
end
