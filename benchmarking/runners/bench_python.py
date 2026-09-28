"""Time Bio.KEGG.REST calls and print one CSV row per request.

Usage: python3 bench_python.py <nreps> <pause_seconds>
"""
import csv
import os
import sys
import time

import Bio.KEGG.REST as BK

NREPS = int(sys.argv[1]) if len(sys.argv) > 1 else 1
PAUSE = float(sys.argv[2]) if len(sys.argv) > 2 else 0.4
CASE_FILE = os.path.join(os.path.dirname(__file__), "..", "cases.tsv")
LABEL = "Bio.KEGG.REST (Python)"


def load_cases(path):
    with open(path, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def request_path(case):
    op = case["operation"]
    arg1 = case["argument1"]
    arg2 = case["argument2"]
    if op == "info":
        return "info/{}".format(arg1)
    if op == "list":
        return "list/{}".format(arg1)
    if op == "find":
        return "find/{}/{}".format(arg1, arg2)
    if op == "get":
        return "get/{}".format(arg1)
    if op == "getseq":
        return "get/{}/aaseq".format(arg1)
    if op == "conv":
        return "conv/{}/{}".format(arg1, arg2)
    if op == "link":
        return "link/{}/{}".format(arg1, arg2)
    raise ValueError("Unknown benchmark operation: {}".format(op))


def run_case(case):
    op = case["operation"]
    arg1 = case["argument1"]
    arg2 = case["argument2"]
    if op == "info":
        response = BK.kegg_info(arg1)
    elif op == "list":
        response = BK.kegg_list(arg1)
    elif op == "find":
        response = BK.kegg_find(arg1, arg2)
    elif op == "get":
        response = BK.kegg_get(arg1)
    elif op == "getseq":
        response = BK.kegg_get(arg1, "aaseq")
    elif op == "conv":
        response = BK.kegg_conv(arg1, arg2)
    elif op == "link":
        response = BK.kegg_link(arg1, arg2)
    else:
        raise ValueError("Unknown benchmark operation: {}".format(op))
    response.read()


def timeit(fn):
    start = time.perf_counter()
    fn()
    return time.perf_counter() - start


# Bio.KEGG.REST has no DDI wrapper.
CASES = [case for case in load_cases(CASE_FILE) if case["operation"] != "ddi"]

# Warm up each operation once so connection setup is absent from measurements.
warmed = set()
for case in CASES:
    if case["operation"] in warmed:
        continue
    run_case(case)
    warmed.add(case["operation"])
    time.sleep(PAUSE)

for _ in range(NREPS):
    for case in CASES:
        elapsed = timeit(lambda: run_case(case))
        print("{},{},{},{}".format(case["operation"], request_path(case), LABEL, elapsed))
        time.sleep(PAUSE)
