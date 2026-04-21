#!/usr/bin/env bash
# Unified CloudFlare inventory: token + zones + Workers scripts +
# Workers routes + Pages projects in a single markdown digest.
#
# Usage:
#   cf-status.sh            # markdown digest (all sections)
#   cf-status.sh --json     # structured JSON envelope with one key per section
#
# Internally calls the other cf-*.sh scripts in --json mode and composes
# their output. Fetch logic stays in the per-resource scripts; this one
# only formats. Fails fast if any child call fails — each child prints
# its own error to stderr before exiting, and set -e propagates here.
#
# Cost: one /user/tokens/verify call + one paginated /zones + one
# /accounts/:id/workers/scripts + n /zones/:id/workers/routes (n = zones)
# + one paginated /accounts/:id/pages/projects. Same API surface as
# running the five scripts individually; only the rendering is new.

set -euo pipefail

mode=md
for arg in "$@"; do
  case "$arg" in
    --json) mode=json ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//p' "$0" | head -18
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

token_json=$("$SCRIPT_DIR/cf-whoami.sh" --json)
zones_json=$("$SCRIPT_DIR/cf-zones.sh" --json)
workers_json=$("$SCRIPT_DIR/cf-workers.sh" --json)
routes_json=$("$SCRIPT_DIR/cf-workers-routes.sh" --json)
pages_json=$("$SCRIPT_DIR/cf-pages.sh" --json)

if [[ "$mode" == "json" ]]; then
  # shellcheck disable=SC2016  # single-quoted jq filter
  jq -n \
    --argjson token   "$token_json" \
    --argjson zones   "$zones_json" \
    --argjson workers "$workers_json" \
    --argjson routes  "$routes_json" \
    --argjson pages   "$pages_json" \
    '{success: true, errors: [], messages: [], result: {
        token:           ($token.result   // {}),
        zones:           ($zones.result   // []),
        workers_scripts: ($workers.result // []),
        workers_routes:  ($routes.result  // []),
        pages_projects:  ($pages.result   // [])
    }}'
  exit 0
fi

# Markdown mode: reuse _lib.sh output helpers for consistent rendering.
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

printf '# CloudFlare status\n\n'

printf '## Token\n\n'
# shellcheck disable=SC2016  # single-quoted jq filter
cf_output_kv "$token_json" md '
  .result as $r |
  [["id",         $r.id],
   ["status",     $r.status],
   ["expires_on", ($r.expires_on // "never")]]
  | .[] | @tsv
'

printf '\n## Zones (%s)\n\n' "$(printf '%s' "$zones_json" | jq -r '.result | length')"
# shellcheck disable=SC2016  # single-quoted jq filter
cf_output "$zones_json" md \
  '.result[] | [.name, .status, (.plan.name // "—")] | @tsv' \
  "$(printf 'NAME\tSTATUS\tPLAN')"

printf '\n## Workers scripts (%s)\n\n' "$(printf '%s' "$workers_json" | jq -r '.result | length')"
# shellcheck disable=SC2016  # single-quoted jq filter
cf_output "$workers_json" md \
  '.result[] | [.id, (.modified_on // "—")] | @tsv' \
  "$(printf 'NAME\tMODIFIED_ON')"

printf '\n## Workers routes (%s)\n\n' "$(printf '%s' "$routes_json" | jq -r '.result | length')"
# shellcheck disable=SC2016  # single-quoted jq filter
cf_output "$routes_json" md \
  '.result[] | [(.zone_name // "—"), .pattern, (.script // "—")] | @tsv' \
  "$(printf 'ZONE\tPATTERN\tSCRIPT')"

printf '\n## Pages projects (%s)\n\n' "$(printf '%s' "$pages_json" | jq -r '.result | length')"
# shellcheck disable=SC2016  # single-quoted jq filter
cf_output "$pages_json" md \
  '.result[] | [.name, (.production_branch // "—"), (.subdomain // "—"), (.latest_deployment.created_on // "—")] | @tsv' \
  "$(printf 'NAME\tBRANCH\tSUBDOMAIN\tLATEST')"
