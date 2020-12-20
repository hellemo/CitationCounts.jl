module CitationCounts

using Bibliography
using Cascadia
using Dates
using Gumbo
using HTTP 
using Markdown

"""
    Scrape number of citations from Google Scholar by doi
    Google doesn't like scraping, so better cache results somehow
"""
function scrape_citations(doi)
    @info doi
    r = HTTP.get("https://scholar.google.com/scholar?hl=en&as_sdt=0%2C5&q=$(doi)&btnG=")
    bdy = String(r.body)
    ff =  findfirst("Cited by",bdy)
    if ff === nothing
        return 0
    end
    m = match(r"w*\d+w*",bdy[ff.+5])
    if match === nothing
        return 0
    else
        return parse(Int,m.match)
    end
end

"""
    Utility to first scrape for citation count, then add to bibliography
"""
function scrape_add(entry)
    cit_count = scrape_citations(entry.access.doi)
    addcitations(entry, cit_count)
end


"""
    Simple citation print for copy/paste to e.g. Word
"""
function export_md(entry, author="Petter Sprett")

    if length(entry.in.journal) > 0
        published_in = entry.in.journal
    elseif length(entry.booktitle) > 0
        published_in = entry.booktitle
    else
        published_in = ""
    end

    authors = emph_author(removebibextra(Bibliography.names_to_strings(entry.authors)),author)
    published_in =removebibextra(published_in)
    title = "\"" * removebibextra(entry.title) * "\""

    md = "$(authors)
        $(title) *$(published_in)* ($(entry.date.year))
        [$(entry.access.doi)](https://doi.org/$(entry.access.doi)) ($(entry.fields["note"]))"
end

"""
    Sort bibliography by citation count, default to highest first. 
    Filter out citations older than maxyears.
"""
function bibs_by_citations(fixedbib; rev=true, maxyears=10)
    thisbib = sort(fixedbib; by=k->parse(Int,fixedbib[k].fields["note"][10:end]),rev)
    filter(x->parse(Int,x.second.date.year)>Dates.year(now())-maxyears, thisbib)
end

"""
    Sort bibliography by publication year, default to newest first.
    Filter out citations older than maxyears.
"""
function bibs_by_year(fixedbib; rev=true, maxyears=10)
    thisbib = sort(fixedbib; by=x->parse(Int,fixedbib[x].date.year),rev)
    filter(x->parse(Int,x.second.date.year)>Dates.year(now())-maxyears, thisbib)
end

"""
    Add citation count from Google Scholarfor all entries in bibfile 
    (looking up by doi, thus assuming they have correct doi)
"""
function add_citation_count(bibfile)
    mybib = Bibliography.import_bibtex(bibfile)

    for k in keys(mybib)
        mybib[k] = scrape_add(mybib[k])
        sleep(1+rand()*2) # Rate limiting
    end
    return mybib
end


"""
    Get bibfile from doi from CrossRef REST API
"""
function getbibfile(doi)
    url = "https://api.crossref.org/v1/works/$(doi)/transform/application/x-bibtex"
    
    r = HTTP.get(url)
    bdy = String(r.body)
end

"""
    Remove extra characters fro BibTex that won't render nicely as MD/HTML
"""
function removebibextra(text)
    strip(replace(replace(text, "{" => ""),"}" => ""))
end

"""
    Add emphasis to selected author (typically for cv use)
"""
function emph_author(authors, author)
    names = split(author)
    lnfirst = names[end] * ", " * names[1]
    short = names[end] * ", " * names[1][1] * "."
    replace(replace(replace(authors, author => "**"*author*"**"),short=>"**"*short*"**"),lnfirst => "**" * lnfirst * "**")
end

""" 
    Create new bibliography with citation count added
"""
function addcitations(entry, cit_count)

    new_fields = merge(entry.fields,Dict("note" => "cited by $cit_count"))

    Bibliography.BibInternal.Entry(
            entry.access,
            entry.authors,
            entry.booktitle,
            entry.date,
            entry.editors,
            entry.eprint,
            entry.id,
            entry.in,
            new_fields,
            entry.title,
            entry.type)
end


end # module
