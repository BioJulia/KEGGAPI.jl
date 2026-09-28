#!/usr/bin/env julia
# Convert KEGGAPI.jl request timings to github-action-benchmark's custom JSON.
using DelimitedFiles
using Printf
using Statistics

length(ARGS) == 2 || error("Usage: write_ci_results.jl INPUT.csv OUTPUT.json")
input, output = ARGS
raw, header = readdlm(input, ',', String, header = true)
vec(header) == ["Function", "Request", "Language", "Seconds"] || error("Unexpected columns in $input")

samples = Dict{String, Vector{Float64}}()
for row in eachrow(raw)
    strip(row[3]) == "KEGGAPI.jl" || continue
    elapsed = parse(Float64, strip(row[4]))
    isfinite(elapsed) && elapsed >= 0 || error("Benchmark timings must be finite and nonnegative")
    push!(get!(samples, strip(row[1]), Float64[]), elapsed)
end
isempty(samples) && error("No KEGGAPI.jl timings found in $input")

const ORDER = ["info", "list", "find", "get", "getseq", "conv", "link", "ddi"]
operations = [operation for operation in ORDER if haskey(samples, operation)]
for operation in operations
    length(samples[operation]) >= 25 || error("Expected at least 25 '$operation' timings")
end

open(output, "w") do io
    println(io, "[")
    for (index, operation) in enumerate(operations)
        index > 1 && println(io, ",")
        @printf(
            io,
            "  {\"name\": \"%s request\", \"unit\": \"seconds\", \"value\": %.9g}",
            operation,
            median(samples[operation]),
        )
    end
    println(io, "\n]")
end
