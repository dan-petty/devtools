# Design

## Decisions

- **Renew each of the 8 ignores to 2026-11-30, 3 days ahead.**: The rule "A Finding with No Fix" gives 3 days for each renewal, with new evidence, up to 14 days in all.

## Rejected alternatives

- **Bump semgrep to drop the ignores (#2).**: semgrep 1.187.0, the newest release, still requires mcp==1.29.0, opentelemetry-api~=1.37.0 and wcmatch~=8.3, so a bump keeps the same locked versions.
- **Pin the fixed versions of mcp, opentelemetry-api and wcmatch over the requirements of semgrep.**: `pip` refuses a lock file that breaks `mcp==1.29.0` and `wcmatch~=8.3`, and semgrep is not tested with those versions.
- **Remove the ignores.**: The gate then fails every pull request for findings that no change of this repository can fix.
