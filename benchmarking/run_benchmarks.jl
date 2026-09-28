#!/usr/bin/env julia
#
# Benchmark KEGGAPI.jl against KEGGREST, Bio.KEGG.REST, and raw curl.
#
#     julia --project=benchmarking benchmarking/run_benchmarks.jl
#
# Each runner emits one timing for every request in cases.tsv. Optional
# interfaces are skipped when their dependencies are unavailable.

const BENCHDIR = @__DIR__
const RUNNERS = joinpath(BENCHDIR, "runners")
const CASE_FILE = joinpath(BENCHDIR, "cases.tsv")
const OPERATIONS = Set(["info", "list", "find", "get", "getseq", "conv", "link", "ddi"])

function validate_cases(path)
    lines = readlines(path)
    first(lines) == "operation\targument1\targument2" || error("Unexpected header in $path")
    rows = [Tuple(split(line, '\t'; keepempty = true)) for line in Iterators.drop(lines, 1)]
    all(length(row) == 3 for row in rows) || error("Every benchmark case must have three fields")
    length(unique(rows)) == length(rows) || error("Benchmark cases must be unique")
    counts = Dict(operation => count(row -> first(row) == operation, rows) for operation in OPERATIONS)
    Set(first.(rows)) == OPERATIONS || error("Unexpected benchmark operations in $path")
    all(==(25), values(counts)) || error("Each operation must have exactly 25 benchmark cases")
    return nothing
end

function parse_args(args)
    nreps, pause = 1, 0.4
    only = Set(["julia", "r", "python", "curl"])
    output = joinpath(BENCHDIR, "benchmark_compare.csv")
    i = 1
    while i <= length(args)
        i == length(args) && error("Missing value for $(args[i])")
        if args[i] == "--nreps"
            nreps = parse(Int, args[i + 1])
        elseif args[i] == "--pause"
            pause = parse(Float64, args[i + 1])
        elseif args[i] == "--only"
            only = Set(split(args[i + 1], ','))
        elseif args[i] == "--output"
            output = abspath(args[i + 1])
        else
            error("Unknown argument: $(args[i])")
        end
        i += 2
    end
    nreps > 0 || error("--nreps must be positive")
    pause >= 0 || error("--pause must be nonnegative")
    valid = Set(["julia", "r", "python", "curl"])
    only ⊆ valid || error("--only accepts a comma-separated subset of $(join(sort!(collect(valid)), ", "))")
    return (; nreps, pause, only, output)
end

struct Interface
    key::String
    name::String
    probe::Cmd
    run::Cmd
end

const OPTIONS = parse_args(ARGS)
validate_cases(CASE_FILE)
const JULIA = get(ENV, "JULIA", "julia")
const RSCRIPT = get(ENV, "RSCRIPT", "Rscript")
const PYTHON = get(ENV, "PYTHON", "python3")

interfaces = [
    Interface(
        "julia",
        "KEGGAPI.jl",
        `$JULIA --version`,
        `$JULIA --project=$BENCHDIR $(joinpath(RUNNERS, "bench_julia.jl")) $(OPTIONS.nreps) $(OPTIONS.pause)`,
    ),
    Interface(
        "r",
        "KEGGREST (R)",
        `$RSCRIPT -e "suppressMessages(library(KEGGREST))"`,
        `$RSCRIPT $(joinpath(RUNNERS, "bench_r.R")) $(OPTIONS.nreps) $(OPTIONS.pause)`,
    ),
    Interface(
        "python",
        "Bio.KEGG.REST (Python)",
        `$PYTHON -c "import Bio.KEGG.REST"`,
        `$PYTHON $(joinpath(RUNNERS, "bench_python.py")) $(OPTIONS.nreps) $(OPTIONS.pause)`,
    ),
    Interface(
        "curl",
        "curl",
        `curl --version`,
        `bash $(joinpath(RUNNERS, "bench_curl.sh")) $(OPTIONS.nreps) $(OPTIONS.pause)`,
    ),
]

available(interface) = success(pipeline(interface.probe, stdout = devnull, stderr = devnull))

samples = NamedTuple{(:operation, :request, :language, :seconds), Tuple{String, String, String, Float64}}[]
for interface in interfaces
    interface.key in OPTIONS.only || continue
    if !available(interface)
        @warn "Skipping $(interface.name): dependencies not installed" probe = interface.probe
        continue
    end

    operation_count = interface.key in ("r", "python") ? 7 : 8
    expected_samples = 25 * operation_count * OPTIONS.nreps
    @info "Benchmarking $(interface.name)" requests = expected_samples
    output = read(interface.run, String)
    initial_length = length(samples)
    for line in eachline(IOBuffer(output))
        isempty(strip(line)) && continue
        fields = split(strip(line), ',')
        length(fields) == 4 || error("Malformed output from $(interface.name): $line")
        operation, request, language, seconds = fields
        language == interface.name || error("Unexpected interface label '$language'")
        elapsed = parse(Float64, seconds)
        isfinite(elapsed) && elapsed >= 0 || error("Invalid timing from $(interface.name): $seconds")
        push!(samples, (; operation = String(operation), request = String(request), language = String(language), seconds = elapsed))
    end
    length(samples) - initial_length == expected_samples ||
        error("Expected $expected_samples results from $(interface.name)")
end

isempty(samples) && error("No interface could be benchmarked")

# issue #45: retain every request timing so plots and CI use the distribution,
# rather than reducing repeated calls to one median before writing the file.
mkpath(dirname(OPTIONS.output))
open(OPTIONS.output, "w") do io
    println(io, "Function,Request,Language,Seconds")
    for sample in samples
        println(io, "$(sample.operation),$(sample.request),$(sample.language),$(sample.seconds)")
    end
end
@info "Wrote $(OPTIONS.output)" samples = length(samples)
