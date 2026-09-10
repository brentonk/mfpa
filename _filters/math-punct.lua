-- Keep punctuation glued to adjacent inline math on the website.
--
-- KaTeX renders inline math as `display: inline-block` boxes, and browsers
-- treat the edge of an inline-block as a line-break opportunity regardless of
-- what comes next — so "$2 + 2 = 4$." can wrap with the period orphaned at the
-- start of the next line, and “$A$ is a set” can leave the opening quote
-- stranded at the end of one (verified in Chromium and Firefox). TeX never
-- breaks in either place. This filter wraps an inline Math element together
-- with the punctuation Str that immediately follows it (".", ",", ")", a
-- closing quote, …) or precedes it ("(", "[", an opening quote) in a
-- `.math-punct` span; mfpa.scss sets that span to `white-space: nowrap`, which
-- removes the break opportunity at the boundary while leaving KaTeX's own
-- internal break points (at relations and binary operators) alone.
--
-- The math may sit at the edge of an inline wrapper (emphasis, a concept span,
-- a link); the punctuation is glued to the wrapper in that case. Pandoc's
-- smart-quote `Quoted` elements are unwrapped into literal quote characters
-- when their content starts or ends with math, so the same rules reach them.
-- Only HTML output is touched: the Typst print target has no such problem.
--
-- Trade-off: `nowrap` also switches off KaTeX's internal break points, so a
-- glued expression sets as one unbreakable unit. Where that unit is wider than
-- its container (a long expression in a nested list on a phone), the small
-- script in _includes/math-punct.html un-glues it again so it can break
-- between KaTeX's boxes instead of spilling past the column edge.

local TRAILING = { ".", ",", ";", ":", "!", "?", ")", "]", "”", "’", '"', "'" }
local LEADING = { "(", "[", "“", "‘" }

local WRAPPERS = {
  Emph = true, Strong = true, Span = true, Link = true,
  Underline = true, SmallCaps = true, Strikeout = true,
}

local QUOTES = {
  DoubleQuote = { "“", "”" },
  SingleQuote = { "‘", "’" },
}

local function is_html()
  if quarto and quarto.doc and quarto.doc.is_format then
    return quarto.doc.is_format("html")
  end
  return FORMAT:match("html") ~= nil
end

local function starts_with_any(str, list)
  for _, p in ipairs(list) do
    if str.text:sub(1, #p) == p then
      return true
    end
  end
  return false
end

local function ends_with_any(str, list)
  for _, p in ipairs(list) do
    if #str.text >= #p and str.text:sub(-#p) == p then
      return true
    end
  end
  return false
end

local function is_inline_math(el)
  return el.t == "Math" and el.mathtype == "InlineMath"
end

local function ends_with_math(el)
  if is_inline_math(el) then
    return true
  end
  if WRAPPERS[el.t] then
    local c = el.content
    return #c > 0 and ends_with_math(c[#c])
  end
  return false
end

local function starts_with_math(el)
  if is_inline_math(el) then
    return true
  end
  if WRAPPERS[el.t] then
    local c = el.content
    return #c > 0 and starts_with_math(c[1])
  end
  return false
end

local function glue(a, b)
  return pandoc.Span({ a, b }, pandoc.Attr("", { "math-punct" }))
end

-- Replace `Quoted` elements whose content begins or ends with math by their
-- literal quote characters, so the gluing passes below can see them.
local function unquote(inlines)
  local out = pandoc.List()
  local changed = false
  for _, el in ipairs(inlines) do
    local c = el.t == "Quoted" and el.content or nil
    if c and #c > 0 and (starts_with_math(c[1]) or ends_with_math(c[#c])) then
      local q = QUOTES[el.quotetype]
      out:insert(pandoc.Str(q[1]))
      out:extend(c)
      out:insert(pandoc.Str(q[2]))
      changed = true
    else
      out:insert(el)
    end
  end
  return out, changed
end

-- Glue math to the punctuation Str that follows it: "$x$." → [$x$.]
local function glue_trailing(inlines)
  local out = pandoc.List()
  local changed = false
  local i = 1
  while i <= #inlines do
    local cur, nxt = inlines[i], inlines[i + 1]
    if nxt and nxt.t == "Str" and starts_with_any(nxt, TRAILING) and ends_with_math(cur) then
      out:insert(glue(cur, nxt))
      changed = true
      i = i + 2
    else
      out:insert(cur)
      i = i + 1
    end
  end
  return out, changed
end

-- Glue math to the opening bracket/quote Str that precedes it: "($x$" → [($x$]
local function glue_leading(inlines)
  local out = pandoc.List()
  local changed = false
  local i = 1
  while i <= #inlines do
    local cur, nxt = inlines[i], inlines[i + 1]
    if nxt and cur.t == "Str" and ends_with_any(cur, LEADING) and starts_with_math(nxt) then
      out:insert(glue(cur, nxt))
      changed = true
      i = i + 2
    else
      out:insert(cur)
      i = i + 1
    end
  end
  return out, changed
end

function Inlines(inlines)
  if not is_html() then
    return nil
  end
  local out, c1 = unquote(inlines)
  local c2, c3
  out, c2 = glue_trailing(out)
  out, c3 = glue_leading(out)
  if c1 or c2 or c3 then
    return out
  end
  return nil
end
