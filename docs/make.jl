using KEGGAPI
using Documenter

DocMeta.setdocmeta!(KEGGAPI, :DocTestSetup, :(using KEGGAPI); recursive = true)

makedocs(;
    modules = [KEGGAPI],
    authors = "Nicholas Geoffrion, Maria Victoria Aguilar Pontes, Carlos Vigil-Vásquez",
    repo = "https://github.com/BioJulia/KEGGAPI.jl/blob/{commit}{path}#{line}",
    sitename = "KEGGAPI.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://BioJulia.github.io/KEGGAPI.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Getting started" => "man/getting-started.md",
            "Examples" => "man/examples.md",
            "API reference" => "man/api.md",
        ],
        "Use cases" => Any[
            "Case 1: UniProt ID to KEGG information" => "man/usecases/case1.md",
            "Case 2: EC reaction information" => "man/usecases/case2.md",
            "Case 3: Identifying a compound" => "man/usecases/case3.md",
            "Case 4: Target molecule information" => "man/usecases/case4.md",
        ],
    ],
)

deploydocs(;
    repo = "github.com/BioJulia/KEGGAPI.jl",
    devbranch = "main",
)
