#!/usr/bin/env bats

load test_helper

setup() {
  cf_bats_setup
}

# cf-status aggregates all the other cf-*.sh scripts in --json mode,
# so every test has to register mocks for every underlying endpoint.
_status_mocks() {
  cf_mock "/user/tokens/verify" "token_verify.json"
  cf_mock "/zones/zone-id-culture-dev-" "routes_culture.json"
  cf_mock "/zones/zone-id-agentirc-dev-" "routes_agentirc.json"
  cf_mock "/zones" "zones.json"
  cf_mock "/workers/scripts" "workers_scripts.json"
  cf_mock "/pages/projects" "pages_projects.json"
}

@test "cf-status.sh emits a top-level heading and every section" {
  _status_mocks
  run bash "$SKILL_SCRIPTS/cf-status.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# CloudFlare status"* ]]
  [[ "$output" == *"## Token"* ]]
  [[ "$output" == *"## Zones (2)"* ]]
  [[ "$output" == *"## Workers scripts"* ]]
  [[ "$output" == *"## Workers routes (2)"* ]]
  [[ "$output" == *"## Pages projects (2)"* ]]
}

@test "cf-status.sh markdown includes token id, zone names, and Pages projects" {
  _status_mocks
  run bash "$SKILL_SCRIPTS/cf-status.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **status:** active"* ]]
  [[ "$output" == *"culture.dev"* ]]
  [[ "$output" == *"agentirc.dev"* ]]
  [[ "$output" == *"culture-dev-site"* ]]
  [[ "$output" == *"agentirc-dev"* ]]
}

@test "cf-status.sh --json emits a unified envelope with one key per section" {
  _status_mocks
  run bash "$SKILL_SCRIPTS/cf-status.sh" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.success == true'
  echo "$output" | jq -e '.result | keys == ["pages_projects","token","workers_routes","workers_scripts","zones"]'
  echo "$output" | jq -e '.result.token.status == "active"'
  echo "$output" | jq -e '.result.zones | length == 2'
  echo "$output" | jq -e '.result.workers_routes | length == 2'
  echo "$output" | jq -e '.result.pages_projects | map(.name) | contains(["agentirc-dev"])'
  # No markdown scaffolding when --json
  [[ "$output" != *"# CloudFlare status"* ]]
}

@test "cf-status.sh exits 2 on unknown flag" {
  run bash "$SKILL_SCRIPTS/cf-status.sh" --bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown argument"* ]]
}

@test "cf-status.sh propagates child failure (no mocks → first child exits 1)" {
  # No mocks registered — the stubbed curl returns success:false, so
  # cf-whoami exits 1 and set -e in cf-status propagates.
  run bash "$SKILL_SCRIPTS/cf-status.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"CloudFlare API request failed"* ]]
}
