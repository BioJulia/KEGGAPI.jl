![plot](./assets/logo/keggapi-logo.jpg)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cvigilv.github.io/KEGGAPI.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cvigilv.github.io/KEGGAPI.jl/dev/)
[![Build Status](https://github.com/cvigilv/KEGGAPI.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cvigilv/KEGGAPI.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cvigilv/KEGGAPI.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cvigilv/KEGGAPI.jl)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)
[![DOI](https://zenodo.org/badge/667588694.svg)](https://doi.org/10.5281/zenodo.22282089)

KEGGAPI.jl is a Julia client for the [Kyoto Encyclopedia of Genes and Genomes](https://www.kegg.jp/) REST API.

## KEGG usage terms

KEGG makes its REST service at `rest.kegg.jp` available only for academic use by academic users. Read KEGG's [REST restriction notice](https://www.kegg.jp/kegg/rest/) and [legal terms](https://www.kegg.jp/kegg/legal.html), including its licensing requirements for non-academic use.

KEGGAPI.jl's MIT license covers only the Julia client code. It does not grant any rights to KEGG data or services.

## Installation

```julia
pkg> add KEGGAPI
```

## Usage

The package wraps the [KEGG REST API](https://www.kegg.jp/kegg/rest/keggapi.html)
operations:

| Function     | KEGG operation | Purpose                                          |
|:-------------|:---------------|:-------------------------------------------------|
| `kegg_info`  | `info`         | Database release information and statistics       |
| `kegg_list`  | `list`         | Entry identifiers and associated names            |
| `kegg_find`  | `find`         | Search entries by keyword or chemical data        |
| `kegg_get`   | `get`          | Retrieve entries, sequences, images, KGML, JSON   |
| `kegg_conv`  | `conv`         | Convert between KEGG and outside identifiers      |
| `kegg_link`  | `link`         | Find related entries via cross-references         |
| `kegg_ddi`   | `ddi`          | Adverse drug-drug interactions                    |

```julia
using KEGGAPI

result = kegg_find("compound", "glucose")
result.colnames    # column names
result.data        # retrieved data
```

The vector forms of `kegg_conv`, `kegg_get`, `kegg_link`, and `kegg_list` send
at most 10 entries per request. Set `request_delay` to control the pause between
requests:

```julia
entries = ["hsa:$id" for id in 10458:10468]
result = kegg_get(entries; request_delay = 0.5)
```

The deprecated `timeout` keyword remains available as an alias for `request_delay`.

## Documentation

- [Getting started](https://cvigilv.github.io/KEGGAPI.jl/dev/man/getting-started/)
- [Examples](https://cvigilv.github.io/KEGGAPI.jl/dev/man/examples/)
- [API reference](https://cvigilv.github.io/KEGGAPI.jl/dev/man/api/)

Worked use cases:

- [Case 1: From a UniProt ID to KEGG information](https://cvigilv.github.io/KEGGAPI.jl/dev/man/usecases/case1/)
- [Case 2: EC reaction information in KEGG](https://cvigilv.github.io/KEGGAPI.jl/dev/man/usecases/case2/)
- [Case 3: Identifying a compound in KEGG](https://cvigilv.github.io/KEGGAPI.jl/dev/man/usecases/case3/)
- [Case 4: Target molecule information at KEGG](https://cvigilv.github.io/KEGGAPI.jl/dev/man/usecases/case4/)

## Benchmarks

![KEGGAPI.jl Benchmarks](benchmark/benchmark.svg "KEGGAPI.jl Benchmarks")

Mean request time ± 1 SD over 25 requests per KEGG operation. KEGGREST and
Bio.KEGG.REST do not wrap `ddi`.

See [`benchmark/`](benchmark/README.md) for how to reproduce these numbers.

## Citation

_publication pending_
