# Tasks

## 1. Renew the osv-scanner ignores

Kind: other.

- [x] 1.1 Set `effectiveUntil = 2026-11-30T00:00:00Z` on the 8 ignores of `python/osv-scanner.toml`, and add the renewal comment with semgrep 1.187.0 to each group of ignores
  - Verification: `$ osv-scanner scan source --lockfile npm/package-lock.json --lockfile requirements.txt:python/copier.txt --lockfile requirements.txt:python/pre-commit.txt --lockfile requirements.txt:python/semgrep.txt` exits 0
