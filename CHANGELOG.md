# Changelog

All notable changes to this project will be documented here. The format
is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-24

### Added

- Python package `cfafi` published to PyPI via OIDC Trusted Publishing.
- `cfafi whoami` — verify the configured CloudFlare API token.
- `cfafi zones list` — list zones accessible to the token (paginated).
- `cfafi dns create ZONE TYPE NAME CONTENT` — create a DNS record;
  dry-run by default, `--apply` to commit, with `--proxied` / `--ttl` /
  `--comment` flags.
- `cfafi learn` — self-teaching prompt for agent consumers; `--json`
  emits a structured payload.
- `cfafi explain <path>...` — markdown docs by noun/verb path.
- `--json` opt-in on every verb; markdown (table or key-value) as the
  default output.
- Structured error envelope (`error: <msg>` / `hint: <remediation>`,
  or `{code, message, remediation}` under `--json`) — no Python
  tracebacks leak to stderr.
- Exit-code policy: 0 success; 1 user error; 2 env error; 3 auth; 4
  upstream CloudFlare API error.
- Vendored `version-bump` skill from `afi-cli` — the `version-check` CI
  job enforces a version bump on every PR.
- CI workflows: `tests.yml` (pytest + bats + shellcheck + markdownlint +
  version check), `publish.yml` (TestPyPI on PR, PyPI on push-to-main),
  `security-checks.yml` (weekly bandit + pylint).

### Changed

- `.claude/skills/cloudflare/` renamed to `.claude/skills/cfafi/`;
  `.claude/skills/cloudflare-write/` renamed to
  `.claude/skills/cfafi-write/`. Symlink updated.
- `CLAUDE.md` — lifted the "do not join the culture mesh from this
  repo" constraint (the actual mesh join lands in a follow-up PR).
- `README.md` — leads with `uv tool install cfafi`; bash skills are
  now the secondary "also available" path.
- `docs/SETUP.md` — credential guidance rewritten around env vars, 0600
  files, and `set -a; .; set +a`; added maintainer Trusted Publisher
  setup checklist.

### Notes

- Bash scripts under `.claude/skills/cfafi{,-write}/scripts/` are
  unchanged. Coexistence is intentional — each verb ports in its own
  follow-up PR with a patch bump. See
  `docs/superpowers/specs/2026-04-24-cfafi-v0.1.0-python-cli-design.md`
  § "Subsequent PRs".
