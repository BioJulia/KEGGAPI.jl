#!/usr/bin/env julia
# Render the request-time distributions in benchmark_compare.csv.
using DelimitedFiles
using Plots
using Plots.PlotMeasures
using StatsPlots

const BENCHDIR = @__DIR__
const CSV = joinpath(BENCHDIR, "benchmark_compare.csv")
const CANONICAL = ["info", "list", "find", "get", "getseq", "conv", "link", "ddi"]

isfile(CSV) || error("$CSV not found. Run run_benchmarks.jl first.")
raw, header = readdlm(CSV, ',', String, header = true)
vec(header) == ["Function", "Request", "Language", "Seconds"] || error("Unexpected columns in $CSV")

functions = strip.(raw[:, 1])
languages = strip.(raw[:, 3])
seconds = parse.(Float64, strip.(raw[:, 4]))
all(isfinite, seconds) && all(>=(0), seconds) ||
    error("Benchmark timings must be finite and nonnegative")

present = unique(functions)
fn_order = [function_name for function_name in CANONICAL if function_name in present]
append!(fn_order, sort([function_name for function_name in present if function_name ∉ CANONICAL]))
fn_index = Dict(function_name => index for (index, function_name) in enumerate(fn_order))
ordered_functions = [fn_index[function_name] for function_name in functions]

plt = groupedboxplot(
    ordered_functions,
    seconds;
    group = languages,
    label = permutedims(unique(languages)),
    xticks = (eachindex(fn_order), fn_order),
    xlabel = "KEGG operation",
    ylabel = "Request time (s)",
    title = "KEGG API request-time distributions",
    legend = :topleft,
    outliers = true,
    bar_width = 0.75,
    framestyle = :box,
    size = (1100, 600),
    dpi = 200,
    left_margin = 8mm,
    bottom_margin = 8mm,
)

for extension in ("svg", "png")
    output = joinpath(BENCHDIR, "benchmark.$extension")
    savefig(plt, output)
    @info "Wrote $output"
end
