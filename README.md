# CitationCounts

Retrieve citation counts from Google Scholar and add to bibliography.

Sort, filter and format for easy copy/paste to e.g. Word for CV to apply for grants from NRC (required to include citation count).

## Usage

All entries in bibtex file must have correct doi, and be written in unicode (no '\o' or similar)

```julia
using CitationCounts, Bibliography
const CC = CitationCounts

# Get citation count from Google Scholar:
bibfile = "original.bib"
mybib = CC.add_citation_count(bibfile)
export_bibtex("fixedbib.bib", mybib)

# Cache this file to avoid scraping over and over
bibfile = "fixedbib.bib" 
mybib = Bibliography.import_bibtex(bibfile)
test = mybib["bibtexkey"]

# Display as Markdown (e.g. in Pluto notebook)
# Highlight author Firstname Lastname
Markdown.parse(CC.export_md(test, "Firstname Lastname"))
```