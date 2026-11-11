-- Build a per-chapter concept glossary from inline span definitions.
--
--   First mention:   [intersection]{.concept definition="The set ..."}
--   With slippage:   [intersections]{.concept entry="Intersection" definition="..."}
--   Later mentions:  [intersection]{.concept}
--   Glossary slot:   ::: {#concept-review} :::
--
-- Each #concept-review lists only the concepts defined in its own chapter. On
-- the website every chapter is a separate Pandoc run, but the print build
-- merges the whole book into one document, so we walk it in order and start a
-- new chapter at every level-1 header.

-- Per-chapter glossary entries, in order of first definition:
-- concepts[chapter] = { { entry = ..., definition = ... }, ... }
local concepts = {}
local seen = {}
-- Definitions by normalized key, across the whole document (for tooltips).
local def_by_key = {}

local function normalize(s)
  return s:lower()
end

-- True for any non-HTML target (the print/lecture PDF via Typst). The hover/tap
-- tooltip and the tabbed glossary are HTML-only affordances: in a non-HTML
-- writer the tooltip span would be dumped inline right after the term, and the
-- tabset would stack both orderings. So for print we suppress the tooltip and
-- emit a single plain definition list instead. HTML behaviour is unchanged.
local function is_print()
  if quarto and quarto.doc and quarto.doc.is_format then
    return not quarto.doc.is_format("html")
  end
  return FORMAT ~= "html"
end

-- Pandoc expands \newcommand macros while reading the chapter and drops the
-- definitions from the AST, so the separate pandoc.read calls below (tooltips,
-- glossary) never see them: a definition using \intr would show raw TeX.
-- Recover the one-line \newcommand / \renewcommand definitions from the source
-- and prepend them to every snippet we parse. On the website that's the
-- chapter's own file; the print build is one merged document, so there we scan
-- every .qmd in the project directory. Multi-line definitions and macros pulled
-- in via {{< include >}} are not picked up.
local macro_preamble = nil

local function source_files()
  if is_print() then
    local dir = quarto and quarto.project and quarto.project.directory
    if dir ~= nil then
      local ok, entries = pcall(pandoc.system.list_directory, dir)
      if ok then
        local files = {}
        for _, name in ipairs(entries) do
          if name:match("%.qmd$") then
            table.insert(files, pandoc.path.join({ dir, name }))
          end
        end
        table.sort(files)
        return files
      end
    end
  end
  local path = quarto and quarto.doc and quarto.doc.input_file
  if path == nil and PANDOC_STATE and PANDOC_STATE.input_files then
    path = PANDOC_STATE.input_files[1]
  end
  return { path }
end

local function chapter_macros()
  if macro_preamble ~= nil then
    return macro_preamble
  end
  macro_preamble = ""
  local defs = {}
  local have = {}
  for _, path in ipairs(source_files()) do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        if (line:match("^%s*\\newcommand%A") or line:match("^%s*\\renewcommand%A"))
            and not have[line] then
          have[line] = true
          table.insert(defs, line)
        end
      end
      f:close()
    end
  end
  if #defs > 0 then
    macro_preamble = table.concat(defs, "\n") .. "\n\n"
  end
  return macro_preamble
end

local function read_markdown(s)
  local doc = pandoc.read(chapter_macros() .. s, "markdown")
  -- The prepended definitions come back as leading raw TeX blocks; drop them
  -- so callers see only the snippet's own blocks.
  while #doc.blocks > 0 and doc.blocks[1].t == "RawBlock"
      and (doc.blocks[1].format == "tex" or doc.blocks[1].format == "latex") do
    doc.blocks:remove(1)
  end
  return doc
end

local function concept_span(el, chapter)
  if not el.classes:includes("concept") then
    return nil
  end

  local def = el.attributes["definition"]
  local entry = el.attributes["entry"]
  local key

  if def ~= nil then
    -- First mention: record the glossary entry.
    if entry == nil or entry == "" then
      entry = pandoc.utils.stringify(el.content)
      -- Glossary entries conventionally start with an uppercase letter, so cap
      -- the first character. Use `entry=` explicitly to override (e.g., "iPhone").
      entry = entry:sub(1, 1):upper() .. entry:sub(2)
    end
    key = normalize(entry)
    concepts[chapter] = concepts[chapter] or {}
    seen[chapter] = seen[chapter] or {}
    if not seen[chapter][key] then
      seen[chapter][key] = true
      table.insert(concepts[chapter], { entry = entry, definition = def })
    end
    def_by_key[key] = def
    el.attributes["definition"] = nil
    el.attributes["entry"] = nil
  else
    -- Later mention: resolve the definition by explicit entry= if given,
    -- otherwise by the span's own (normalized) text.
    if entry ~= nil and entry ~= "" then
      key = normalize(entry)
      el.attributes["entry"] = nil
    else
      key = normalize(pandoc.utils.stringify(el.content))
    end
  end

  -- Print target: no tooltips (they'd be dumped inline). Leave the term as a
  -- plain styled span; the definition still lives in the glossary.
  if is_print() then
    return el
  end

  -- Attach a hover/tap tooltip carrying the definition. The definition is
  -- parsed as Markdown inlines (not stuffed into an attribute) so its math
  -- typesets normally; CSS/JS reveal it. Only concepts with a known
  -- definition become interactive (.has-tip).
  local d = def_by_key[key]
  if d ~= nil then
    local blocks = read_markdown(d).blocks
    local tip_inlines = (blocks[1] and blocks[1].content) or pandoc.Inlines({})
    local tip = pandoc.Span(tip_inlines, pandoc.Attr("", { "concept-tip" }, { role = "tooltip" }))
    el.content:insert(tip)
    if not el.classes:includes("has-tip") then
      el.classes:insert("has-tip")
    end
    el.attributes["tabindex"] = "0"
  end

  return el
end

local function emit_list(items)
  local lines = {}
  for _, c in ipairs(items) do
    table.insert(lines, "[" .. c.entry .. "]{.concept}")
    table.insert(lines, ": " .. c.definition)
    table.insert(lines, "")
  end
  return table.concat(lines, "\n")
end

local function concept_review(concepts)
  if concepts == nil or #concepts == 0 then
    return {}
  end

  -- Print target: a tabset would render both orderings stacked, so emit just
  -- one definition list in the order the concepts were introduced.
  if is_print() then
    local md = table.concat({
      "## Concept review",
      "",
      emit_list(concepts),
    }, "\n")
    return read_markdown(md).blocks
  end

  local alphabetical = {}
  for _, c in ipairs(concepts) do
    table.insert(alphabetical, c)
  end
  table.sort(alphabetical, function(a, b)
    return normalize(a.entry) < normalize(b.entry)
  end)

  local md = table.concat({
    "## Concept review",
    "",
    "::: {.panel-tabset}",
    "",
    "## Conceptual order",
    "",
    emit_list(concepts),
    "## Alphabetical order",
    "",
    emit_list(alphabetical),
    ":::",
    "",
  }, "\n")

  return read_markdown(md).blocks
end

function Pandoc(doc)
  -- Pass 1, in document order: process concept spans, filing each definition
  -- under the current chapter, and tag each glossary slot with its chapter.
  local chapter = 0
  doc = doc:walk({
    traverse = "topdown",
    Header = function(el)
      if el.level == 1 then
        chapter = chapter + 1
      end
    end,
    Span = function(el)
      local out = concept_span(el, chapter)
      if out ~= nil then
        -- Don't descend into the tooltip we just attached.
        return out, false
      end
    end,
    Div = function(el)
      if el.identifier == "concept-review" then
        el.attributes["concept-chapter"] = tostring(chapter)
        return el, false
      end
    end,
  })

  -- Pass 2: fill each glossary slot with its own chapter's concepts.
  return doc:walk({
    Div = function(el)
      if el.identifier == "concept-review" then
        return concept_review(concepts[tonumber(el.attributes["concept-chapter"])])
      end
    end,
  })
end
