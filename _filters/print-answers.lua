-- Move exercise answers to the back of the book in the print PDF.
--
-- Exercises are authored as `::: {#exr-… }` divs (Quarto's exercise crossref
-- environment) with a nested `::: {.answer}` solution. On the website the
-- answer is a collapsed <details> block (see _filters/answer.lua). In print
-- there's no collapsing, so instead we:
--
--   * lift each exercise's answer out of the exercise,
--   * leave a linked "Answer: p. N" pointer at the end of the exercise
--     (`mfpa-answer-pointer`, defined in print/paper-override.typ), and
--   * collect the answers into an unnumbered section just before References,
--     grouped under each chapter's title and headed by a cross-reference to the
--     exercise ("Exercise 1.3"), which Quarto resolves and links.
--
-- The section heading comes from the `exercise-answers-title` metadata key
-- (set in _quarto-print.yml).
--
-- No-op for the HTML website. Runs at `pre-ast`, so it sees the raw `#exr-…`
-- identifiers before Quarto's crossref pass rewrites them, and so the moved
-- answers (which are no longer `.answer` divs) skip answer.lua's HTML-only
-- disclosure markup. In the merged print document every chapter starts with a
-- level-1 header, which is how answers are grouped by chapter.

local function is_print()
  if quarto and quarto.doc and quarto.doc.is_format then
    return not quarto.doc.is_format("html")
  end
  return FORMAT ~= "html"
end

local function is_exercise(el)
  return el.identifier ~= nil and el.identifier:match("^exr%-") ~= nil
end

local function is_answer(el)
  return el.t == "Div" and el.classes:includes("answer")
end

local DEFAULT_TITLES = { ["answer"] = true, ["answers"] = true }

local function md_inlines(s)
  return pandoc.utils.blocks_to_inlines(pandoc.read(s, "markdown").blocks)
end

local function section_title(meta)
  local t = meta["exercise-answers-title"]
  if t == nil then
    return md_inlines("TODO(BJK): title for the answers appendix")
  end
  if type(t) == "string" then
    return md_inlines(t)
  end
  return pandoc.Inlines(t)
end

-- Typst label name for an exercise's answer anchor.
local function anchor(id)
  return "ans-" .. id
end

-- Does this block contain the bibliography slot (`::: {#refs}`)?
local function holds_refs(block)
  if block.t ~= "Div" then
    return false
  end
  if block.identifier == "refs" then
    return true
  end
  local found = false
  pandoc.Div(block.content):walk({
    Div = function(d)
      if d.identifier == "refs" then
        found = true
      end
    end,
  })
  return found
end

function Pandoc(doc)
  if not is_print() then
    return nil
  end

  -- Answers grouped by chapter, in document order.
  local chapters = {}
  local current = nil

  doc = doc:walk({
    traverse = "topdown",
    Header = function(el)
      if el.level == 1 then
        current = { title = el.content, id = el.identifier, answers = {} }
        table.insert(chapters, current)
      end
    end,
    Div = function(el)
      if not is_exercise(el) then
        return nil
      end
      local kept = pandoc.List()
      local found = false
      for _, b in ipairs(el.content) do
        if is_answer(b) and current ~= nil then
          found = true
          table.insert(current.answers, {
            id = el.identifier,
            title = b.attributes["title"],
            blocks = b.content,
          })
        else
          kept:insert(b)
        end
      end
      if found then
        kept:insert(pandoc.RawBlock("typst",
          '#mfpa-answer-pointer(label("' .. anchor(el.identifier) .. '"))'))
        el.content = kept
      end
      return el, false
    end,
  })

  -- Any answer not sitting directly inside an exercise is left where it is.
  doc:walk({
    Div = function(el)
      if is_answer(el) then
        quarto.log.warning("print-answers.lua: an .answer div outside an "
          .. "#exr-… exercise was left in place")
      end
    end,
  })

  -- Build the answers section.
  local section = pandoc.List()
  section:insert(pandoc.Header(1, section_title(doc.meta),
    pandoc.Attr("exercise-answers", { "unnumbered" })))
  -- Display equations in the answers would otherwise be numbered under the
  -- last chapter's counter ("(7.1)"); nothing cross-references them, so turn
  -- numbering off from here to the end of the book.
  section:insert(pandoc.RawBlock("typst", "#set math.equation(numbering: none)"))
  local any = false
  for ci, ch in ipairs(chapters) do
    if #ch.answers > 0 then
      any = true
      local hid = "exercise-answers-" .. (ch.id ~= "" and ch.id or tostring(ci))
      section:insert(pandoc.Header(2, ch.title:clone(),
        pandoc.Attr(hid, { "unnumbered" })))
      for _, a in ipairs(ch.answers) do
        section:insert(pandoc.RawBlock("typst",
          '#metadata("exercise-answer") <' .. anchor(a.id) .. '>'))
        local lead = pandoc.List()
        lead:insert(pandoc.Strong({
          pandoc.Cite({ pandoc.Str("@" .. a.id) },
            { pandoc.Citation(a.id, "NormalCitation") }),
        }))
        local t = a.title
        if t ~= nil and t ~= "" and not DEFAULT_TITLES[t:lower()] then
          lead:insert(pandoc.Space())
          lead:insert(pandoc.Str("("))
          lead:extend(md_inlines(t))
          lead:insert(pandoc.Str(")"))
        end
        -- Wrapped in a block so neither the lead-in nor the answer's first
        -- paragraph picks up the template's first-line indent.
        section:insert(pandoc.RawBlock("typst", "#block(above: 1.2em, below: 0.7em)["))
        section:insert(pandoc.Para(lead))
        section:insert(pandoc.RawBlock("typst", "]"))
        section:extend(a.blocks)
      end
    end
  end
  if not any then
    return doc
  end

  -- Place it before the chapter holding the bibliography (References), or at
  -- the end if there is none.
  local blocks = doc.blocks
  local at = nil
  for i, b in ipairs(blocks) do
    if holds_refs(b) then
      at = i
      break
    end
  end
  if at ~= nil then
    for j = at, 1, -1 do
      if blocks[j].t == "Header" and blocks[j].level == 1 then
        at = j
        break
      end
    end
    for k = #section, 1, -1 do
      blocks:insert(at, section[k])
    end
  else
    blocks:extend(section)
  end
  doc.blocks = blocks
  return doc
end
