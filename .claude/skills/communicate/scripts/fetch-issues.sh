#!/usr/bin/env bash
# Fetch GitHub issues with full body and comments. Thin wrapper around
# `agtag issue fetch` that keeps this skill's range/list expansion
# (agtag is single-issue per call).
#
# Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]
#   fetch-issues.sh 191-197                   # range
#   fetch-issues.sh 191                       # single
#   fetch-issues.sh 191 192 195               # list
#   fetch-issues.sh --repo foo/bar 5          # explicit repo (otherwise gh resolves it from the git remote)
#
# Exit codes: 0 success, 1 one or more fetches failed, 2 usage error.

set -euo pipefail
shopt -s inherit_errexit

REPO=""
NUMBERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --repo requires a value (OWNER/REPO)" >&2
        echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
        exit 2
      fi
      REPO="$2"
      shift 2 ;;
    *-*)  # range like 191-197
      if [[ ! "$1" =~ ^[0-9]+-[0-9]+$ ]]; then
        echo "Error: malformed range '$1' — expected START-END (e.g. 191-197)" >&2
        echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
        exit 2
      fi
      IFS='-' read -r start end <<< "$1"
      if (( start > end )); then
        echo "Error: range '$1' has START greater than END" >&2
        exit 2
      fi
      for ((i=start; i<=end; i++)); do NUMBERS+=("$i"); done
      shift ;;
    *)
      if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: '$1' is not an issue number or START-END range" >&2
        echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
        exit 2
      fi
      NUMBERS+=("$1"); shift ;;
  esac
done

if [[ ${#NUMBERS[@]} -eq 0 ]]; then
  echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
  exit 2
fi

if ! command -v agtag >/dev/null 2>&1; then
  echo "agtag not found on PATH. Install agtag (>=0.1) to use this skill." >&2
  exit 2
fi

# agtag fetch resolves the repo from the local git remote when --repo
# is omitted, matching the previous gh-based behavior.
REPO_ARGS=()
if [[ -n "$REPO" ]]; then
  REPO_ARGS=(--repo "$REPO")
fi

# Keep fetching the rest of the list even if one issue fails, but exit
# non-zero at the end so callers don't silently brief from partial state.
FAIL=0
for num in "${NUMBERS[@]}"; do
  echo "========================================"
  echo "ISSUE #${num}"
  echo "========================================"
  if ! agtag issue fetch "${REPO_ARGS[@]}" --number "$num" --json; then
    echo "ERROR: Could not fetch issue #${num}" >&2
    FAIL=1
  fi
  echo
done

exit "$FAIL"
