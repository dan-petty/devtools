# Proposal

## Why

The 8 dated ignores of `python/osv-scanner.toml` expired on 2026-11-27 00:00 UTC, so the osv-scanner gate of the job "Build, test and scan" fails on each pull request and on the next push to `main` (#104). No released semgrep allows the fixed versions of mcp, opentelemetry-api and wcmatch, so the rule "A Finding with No Fix" renews each ignore for 3 days with new evidence.

## What Changes

- Set `effectiveUntil = 2026-11-30T00:00:00Z` on the 8 ignores of `python/osv-scanner.toml`.
- Add a comment to each group of ignores with the new evidence: semgrep 1.187.0, the newest release on 2026-11-27, still requires mcp==1.29.0, opentelemetry-api~=1.37.0 and wcmatch~=8.3.
- The change alters no behavior that a consumer observes: it edits the data file of a CI gate. It sets `skip_specs: true`.
- The change fits one pull request.

## Feasibility

- `https://pypi.org/pypi/semgrep/json` (read on 2026-11-27) gives the newest version 1.187.0 and its `requires_dist` lines `mcp==1.29.0`, `opentelemetry-api~=1.37.0` and `wcmatch~=8.3`. The fixed versions are mcp 1.30.0, opentelemetry-api 1.45.1 and 1.45.2, and wcmatch 11.2, so no released semgrep allows a fix.
- The first ignores started on 2026-11-19 (mcp, opentelemetry-api) and 2026-11-20 (wcmatch). The 14-day limit of the rule ends on 2026-12-03 and 2026-12-04, so 2026-11-30 is inside it.
- `osv-scanner scan source` (2.7.1) with the 4 lock files of the job (`npm/package-lock.json`, `python/copier.txt`, `python/pre-commit.txt`, `python/semgrep.txt`) filters 8 vulnerabilities and prints "No issues found" with the renewed file.

## Existing Tool Considered

osv-scanner (Apache-2.0, maintained) is the gate, and its `[[IgnoredVulns]]` entries with `effectiveUntil` are the tool's own form of a dated ignore. The change builds no code and deletes no internal code.
