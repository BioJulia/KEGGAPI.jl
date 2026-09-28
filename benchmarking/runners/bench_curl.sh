#!/usr/bin/env bash
# Time raw REST calls and print one CSV row per request.
# Usage: bash bench_curl.sh <nreps> <pause_seconds>
set -euo pipefail

NREPS="${1:-1}"
PAUSE="${2:-0.4}"
BASE="https://rest.kegg.jp"
CASE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cases.tsv"
LABEL="curl"

case_path() {
    local operation="$1" argument1="$2" argument2="$3"
    case "$operation" in
        info)   printf 'info/%s' "$argument1" ;;
        list)   printf 'list/%s' "$argument1" ;;
        find)   printf 'find/%s/%s' "$argument1" "$argument2" ;;
        get)    printf 'get/%s' "$argument1" ;;
        getseq) printf 'get/%s/aaseq' "$argument1" ;;
        conv)   printf 'conv/%s/%s' "$argument1" "$argument2" ;;
        link)   printf 'link/%s/%s' "$argument1" "$argument2" ;;
        ddi)    printf 'ddi/%s' "$argument1" ;;
        *)      echo "Unknown benchmark operation: $operation" >&2; return 1 ;;
    esac
}

timeit() {
    curl -fsS -o /dev/null -w '%{time_total}' "$1"
}

# Warm up each operation once so connection setup is absent from measurements.
previous_operation=""
while IFS=$'\t' read -r operation argument1 argument2; do
    [[ "$operation" == "operation" ]] && continue
    [[ "$operation" == "$previous_operation" ]] && continue
    path="$(case_path "$operation" "$argument1" "$argument2")"
    curl -fsS -o /dev/null "$BASE/$path"
    previous_operation="$operation"
    sleep "$PAUSE"
done < "$CASE_FILE"

for _ in $(seq 1 "$NREPS"); do
    while IFS=$'\t' read -r operation argument1 argument2; do
        [[ "$operation" == "operation" ]] && continue
        path="$(case_path "$operation" "$argument1" "$argument2")"
        echo "$operation,$path,$LABEL,$(timeit "$BASE/$path")"
        sleep "$PAUSE"
    done < "$CASE_FILE"
done
