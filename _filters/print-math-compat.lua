-- Smooth over TeX-math macros that Pandoc can't translate to Typst math, so the
-- print/lecture PDF doesn't fall back to dumping raw LaTeX source into the page.
--
-- Currently: \mathclap / \mathllap / \mathrlap (KaTeX spacing helpers used to
-- tighten over/underbrace annotations). KaTeX renders them on the website; the
-- Typst writer doesn't know them and bails on the whole equation. Stripping the
-- macro name leaves its `{…}` argument as an ordinary group — the brace/label
-- still typesets, only the zero-width clapping is lost (labels set at natural
-- width). HTML output is untouched.

local function is_print()
  if quarto and quarto.doc and quarto.doc.is_format then
    return not quarto.doc.is_format("html")
  end
  return FORMAT ~= "html"
end

function Math(el)
  if not is_print() then
    return nil
  end
  el.text = el.text:gsub("\\math[lr]?clap%s*", "")
  return el
end
