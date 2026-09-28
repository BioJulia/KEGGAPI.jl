# Benchmarking

This benchmark compares `KEGGAPI.jl`, `KEGGREST` for R, `Bio.KEGG.REST` for
Python, and raw `curl`. [`cases.tsv`](cases.tsv) defines 25 distinct requests for
each operation: `info`, `list`, `find`, `get`, amino-acid `get`, `conv`, `link`,
and `ddi`. Single-entry gene and drug requests keep response sizes bounded,
while the `info` and `find` cases span valid databases and search terms.
KEGGREST and Bio.KEGG.REST do not wrap `ddi`, so their distributions omit that
operation.

Each interface runs in one process, which excludes interpreter startup. One
warm-up call per operation precedes the measurements. Calls are spaced by
`--pause` seconds, 0.4 by default, to stay below KEGG's limit of three requests
per second. The CSV retains each request timing, and the plot shows its
distribution instead of reducing all requests to one value.

`KEGGAPI.jl`'s chunked `kegg_get` can wait between requests. The Julia runner
passes `request_delay = 0.0` because the runner already spaces calls.

## Running

One-time setup of the isolated benchmarking environment:

```bash
julia --project=benchmarking -e 'using Pkg; Pkg.develop(PackageSpec(path=".")); Pkg.instantiate()'
```

Run the benchmarks, which writes `benchmark_compare.csv`:

```bash
julia --project=benchmarking benchmarking/run_benchmarks.jl
```

Regenerate the SVG used in the main README and its PNG counterpart:

```bash
julia --project=benchmarking benchmarking/plot_benchmarks.jl
```

## Optional interfaces

Only Julia and `curl` are required. The script reports and skips interfaces
whose dependencies are missing. To include the others:

```bash
# R (KEGGREST via Bioconductor)
Rscript -e 'install.packages("BiocManager"); BiocManager::install("KEGGREST")'

# Python (Biopython). On PEP 668 "externally managed" installs, use a venv:
python3 -m venv /tmp/kegg_bench_venv
/tmp/kegg_bench_venv/bin/pip install biopython
```

### Nix-provided R

A Nix-provided R installs packages from source but does not expose its dependency
paths to those builds, so CRAN/Bioconductor sources fail to link (`library not found
for -lintl`, `zlib.h not found`, `-lldap`, `-lkrb5`). Point `R_MAKEVARS_USER` at
a Makevars supplying the paths. Adjust the store hashes to match your system.
Find them with `otool -L $(R RHOME)/lib/libR.dylib` and
`ls -d /nix/store/*<pkg>*`:

```make
GETTEXT  = /nix/store/...-gettext-0.22.5
ZLIB_DEV = /nix/store/...-zlib-1.3.1-dev
ZLIB     = /nix/store/...-zlib-1.3.1
PNG_DEV  = /nix/store/...-libpng-apng-1.6.46-dev
PNG      = /nix/store/...-libpng-apng-1.6.46
LDAP     = /nix/store/...-openldap-2.6.9
KRB5     = /nix/store/...-krb5-1.21.3-lib

CPPFLAGS += -I$(ZLIB_DEV)/include -I$(PNG_DEV)/include
LDFLAGS  += -L$(GETTEXT)/lib -L$(ZLIB)/lib -L$(PNG)/lib -L$(LDAP)/lib -L$(KRB5)/lib
```

```bash
R_MAKEVARS_USER=/path/to/Makevars \
  Rscript -e 'BiocManager::install("KEGGREST", ask = FALSE, update = FALSE)'
```

`R_MAKEVARS_USER` applies the settings only to this installation instead of
writing them to `~/.R/Makevars`. The benchmark does not need it after the
packages are built.

### Selecting interpreters

Set `JULIA`, `RSCRIPT`, or `PYTHON` to select an interpreter. For example, use
`PYTHON` to select a virtual environment:

```bash
PYTHON=/tmp/kegg_bench_venv/bin/python \
  julia --project=benchmarking benchmarking/run_benchmarks.jl
```

Use `--only julia,curl` to select interfaces. `--nreps N` repeats all 25 cases
for each selected operation.

## Layout

| Path                     | Purpose                                            |
|:-------------------------|:---------------------------------------------------|
| `cases.tsv`              | The 25 requests for each operation                  |
| `run_benchmarks.jl`      | Runs each interface and writes raw timings          |
| `plot_benchmarks.jl`     | Plots the request-time distributions                |
| `write_ci_results.jl`    | Converts Julia timings to CI benchmark JSON         |
| `runners/bench_julia.jl` | KEGGAPI.jl timings                                  |
| `runners/bench_r.R`      | KEGGREST timings                                    |
| `runners/bench_python.py`| Bio.KEGG.REST timings                               |
| `runners/bench_curl.sh`  | Raw REST timings via `curl -w %{time_total}`        |

Each runner prints one `Function,Request,Language,Seconds` row per call. Run an
individual runner with:

```bash
julia --project=benchmarking benchmarking/runners/bench_julia.jl 1 0.4
```

Network round-trip time to `rest.kegg.jp` dominates these results. Compare
interfaces within one run because location and server load vary between runs.
CI records the median Julia time for each operation and warns, without failing
the job, when it exceeds the previous value by the configured threshold.
