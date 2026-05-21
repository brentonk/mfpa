-- Build a per-chapter concept glossary from inline span definitions.
--
--   First mention:   [intersection]{.concept definition="The set ..."}
--   With slippage:   [intersections]{.concept entry="Intersection" definition="..."}
--   Later mentions:  [intersection]{.concept}
--   Glossary slot:   ::: {#concept-review} :::

local concepts = {}
local seen = {}

local function normalize(s)
  return s:lower()
end

function Span(el)
  if not el.classes:includes("concept") then
    return nil
  end

  local def = el.attributes["definition"]
  if def == nil then
    return nil
  end

  local entry = el.attributes["entry"]
  if entry == nil or entry == "" then
    entry = pandoc.utils.stringify(el.content)
    -- Glossary entries conventionally start with an uppercase letter, so cap
    -- the first character. Use `entry=` explicitly to override (e.g., "iPhone").
    entry = entry:sub(1, 1):upper() .. entry:sub(2)
  end

  local key = normalize(entry)
  if not seen[key] then
    seen[key] = true
    table.insert(concepts, { entry = entry, definition = def })
  end

  el.attributes["definition"] = nil
  el.attributes["entry"] = nil
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

function Div(el)
  if el.identifier ~= "concept-review" then
    return nil
  end
  if #concepts == 0 then
    return {}
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

  return pandoc.read(md, "markdown").blocks
end
