-- Remove exercise blocks from the print/lecture build.
--
-- Exercises are authored as `::: {#exr-… }` divs (Quarto's exercise crossref
-- environment), often with a nested `::: {.answer}` solution. For the printable
-- lecture notes we drop them — removing an `#exr-…` div also removes any answer
-- nested inside it.
--
-- BUT: the exposition sometimes leans on an exercise by name ("As you saw in
-- @exr-pres-vp-functions, …"). Deleting such an exercise would leave a dangling
-- cross-reference in the surviving prose. So we keep any exercise that is still
-- referenced from non-exercise content, and strip the rest. (Cross-references
-- that live *inside* other exercises don't count — those blocks are removed
-- too.) Whichever exercises survive are renumbered consistently by Quarto, so
-- the references still resolve.
--
-- This filter is a no-op for the HTML book (the website keeps all exercises);
-- it only strips when rendering a non-HTML target, and runs at `pre-ast` so it
-- sees the raw `#exr-…` identifiers before Quarto's crossref pass rewrites them.

local function is_print()
  if quarto and quarto.doc and quarto.doc.is_format then
    return not quarto.doc.is_format("html")
  end
  return FORMAT ~= "html"
end

local function is_exercise(el)
  return el.identifier ~= nil and el.identifier:match("^exr%-") ~= nil
end

function Pandoc(doc)
  if not is_print() then
    return nil
  end

  -- Which exercise ids are cited from *outside* every exercise? Walk a copy of
  -- the document with all exercises removed, then collect the crossref ids it
  -- still cites.
  local referenced = {}
  local without_exercises = doc:walk({
    Div = function(el)
      if is_exercise(el) then
        return {}
      end
    end,
  })
  without_exercises:walk({
    Cite = function(c)
      for _, cit in ipairs(c.citations) do
        referenced[cit.id] = true
      end
    end,
  })

  -- Strip every exercise that nothing outside the exercises refers to.
  return doc:walk({
    Div = function(el)
      if is_exercise(el) and not referenced[el.identifier] then
        return {}
      end
    end,
  })
end
