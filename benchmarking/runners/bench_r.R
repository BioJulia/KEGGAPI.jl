# Time KEGGREST calls and print one CSV row per request.
# Usage: Rscript bench_r.R <nreps> <pause_seconds>
suppressMessages(library(KEGGREST))

args <- commandArgs(trailingOnly = TRUE)
nreps <- if (length(args) >= 1) as.integer(args[1]) else 1
pause <- if (length(args) >= 2) as.numeric(args[2]) else 0.4
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) stop("bench_r.R must be run with Rscript")
script_path <- sub("^--file=", "", script_arg[[1]])
case_file <- file.path(dirname(normalizePath(script_path)), "..", "cases.tsv")
label <- "KEGGREST (R)"

cases <- read.delim(case_file, stringsAsFactors = FALSE, check.names = FALSE)
# KEGGREST has no DDI wrapper.
cases <- cases[cases$operation != "ddi", ]

request_path <- function(case) {
    op <- case$operation
    arg1 <- case$argument1
    arg2 <- case$argument2
    if (op == "info") return(sprintf("info/%s", arg1))
    if (op == "list") return(sprintf("list/%s", arg1))
    if (op == "find") return(sprintf("find/%s/%s", arg1, arg2))
    if (op == "get") return(sprintf("get/%s", arg1))
    if (op == "getseq") return(sprintf("get/%s/aaseq", arg1))
    if (op == "conv") return(sprintf("conv/%s/%s", arg1, arg2))
    if (op == "link") return(sprintf("link/%s/%s", arg1, arg2))
    stop(sprintf("Unknown benchmark operation: %s", op))
}

run_case <- function(case) {
    op <- case$operation
    arg1 <- case$argument1
    arg2 <- case$argument2
    result <- switch(
        op,
        info = keggInfo(arg1),
        list = keggList(arg1),
        find = keggFind(arg1, arg2),
        get = keggGet(arg1),
        getseq = keggGet(arg1, "aaseq"),
        conv = keggConv(arg1, arg2),
        link = keggLink(arg1, arg2),
        stop(sprintf("Unknown benchmark operation: %s", op))
    )
    invisible(result)
}

timeit <- function(fn) {
    start <- proc.time()[["elapsed"]]
    fn()
    proc.time()[["elapsed"]] - start
}

# Warm up each operation once so connection setup is absent from measurements.
warmed <- character()
for (i in seq_len(nrow(cases))) {
    case <- cases[i, ]
    if (case$operation %in% warmed) next
    run_case(case)
    warmed <- c(warmed, case$operation)
    Sys.sleep(pause)
}

for (rep in seq_len(nreps)) {
    for (i in seq_len(nrow(cases))) {
        case <- cases[i, ]
        elapsed <- timeit(function() run_case(case))
        cat(sprintf(
            "%s,%s,%s,%s\n",
            case$operation, request_path(case), label, elapsed
        ))
        Sys.sleep(pause)
    }
}
