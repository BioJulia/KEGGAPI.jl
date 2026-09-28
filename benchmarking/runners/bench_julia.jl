# Julia runner: time KEGGAPI.jl calls and print one CSV row per request.
# Usage: julia --project=benchmarking bench_julia.jl <nreps> <pause_seconds>
using KEGGAPI

const NREPS = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 1
const PAUSE = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 0.4
const CASE_FILE = joinpath(@__DIR__, "..", "cases.tsv")
const LABEL = "KEGGAPI.jl"

struct BenchmarkCase
    operation::String
    argument1::String
    argument2::String
end

function load_cases(path)
    lines = readlines(path)
    first(lines) == "operation\targument1\targument2" || error("Unexpected case-file header")
    cases = BenchmarkCase[]
    for (index, line) in enumerate(Iterators.drop(lines, 1))
        fields = split(line, '\t'; keepempty = true)
        length(fields) == 3 || error("Invalid benchmark case on line $(index + 1)")
        push!(cases, BenchmarkCase(fields...))
    end
    return cases
end

function request_path(case)
    op, arg1, arg2 = case.operation, case.argument1, case.argument2
    op == "info" && return "info/$arg1"
    op == "list" && return "list/$arg1"
    op == "find" && return "find/$arg1/$arg2"
    op == "get" && return "get/$arg1"
    op == "getseq" && return "get/$arg1/aaseq"
    op == "conv" && return "conv/$arg1/$arg2"
    op == "link" && return "link/$arg1/$arg2"
    op == "ddi" && return "ddi/$arg1"
    error("Unknown benchmark operation: $op")
end

# The runner spaces calls itself. Disable KEGGAPI's internal batching delay so
# the measurement contains only request and parsing time.
function run_case(case)
    op, arg1, arg2 = case.operation, case.argument1, case.argument2
    op == "info" && return KEGGAPI.kegg_info(arg1)
    op == "list" && return KEGGAPI.kegg_list(arg1)
    op == "find" && return KEGGAPI.kegg_find(arg1, arg2)
    op == "get" && return KEGGAPI.kegg_get(arg1; request_delay = 0.0)
    op == "getseq" && return KEGGAPI.kegg_get(arg1, :aaseq; request_delay = 0.0)
    op == "conv" && return KEGGAPI.kegg_conv(arg1, arg2)
    op == "link" && return KEGGAPI.kegg_link(arg1, arg2)
    op == "ddi" && return KEGGAPI.kegg_ddi(arg1)
    error("Unknown benchmark operation: $op")
end

function timeit(f)
    t0 = time_ns()
    f()
    return (time_ns() - t0) / 1.0e9
end

const CASES = load_cases(CASE_FILE)

# Warm up each operation once so compilation is absent from measured calls.
warmed = Set{String}()
for case in CASES
    case.operation in warmed && continue
    run_case(case)
    push!(warmed, case.operation)
    sleep(PAUSE)
end

for _ in 1:NREPS, case in CASES
    println("$(case.operation),$(request_path(case)),$LABEL,", timeit(() -> run_case(case)))
    sleep(PAUSE)
end
