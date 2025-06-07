def desc_list(terms: dict) -> str:
    """
    Generate a Markdown description list from a dictionary of terms.
    """

    out = ""
    for term, defn in terms.items():
        out += f"[{term}]{{.concept}}\n: {defn}\n\n"

    return out


def concept_table(terms: dict) -> str:
    """
    Generate a tabset with conceptually and alphabetically sorted terms.
    """
    terms_abc = dict(sorted(terms.items()))

    out = "## Concept review\n\n::: {.panel-tabset}\n\n"
    out += "## Conceptual order\n\n"
    out += desc_list(terms)
    out += "\n\n## Alphabetical order\n\n"
    out += desc_list(terms_abc)
    out += "\n\n:::\n"

    return out
