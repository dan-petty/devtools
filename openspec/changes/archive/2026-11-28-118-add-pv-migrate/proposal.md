# Proposal

## Why

dan-petty/devops-cli#7498 replaces the copy of `devops k8s volume move` with pv-migrate. The command starts `pv-migrate` from `PATH`, and the devcontainer of devops-cli builds FROM this image. The image has no `pv-migrate`, so the plan of a move refuses with "pv-migrate is not on PATH" (#118).

## What Changes

- Add `"github:utkuozdemir/pv-migrate" = "3.8.0"` to `mise.toml`, and its URL and checksum for `linux-x64` and `linux-arm64` to `mise.lock` (`mise lock --platform linux-x64,linux-arm64`).
- Add `pv-migrate` to the copy loop of the `Dockerfile`.
- Print the version of `pv-migrate` in `test/tools.sh`, beside the other tools of `mise.lock`.
- Carry no spec delta: the repository holds no `src/` package and no living spec, so no requirement can name code that a behavior test changes.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Code: `mise.toml`, `mise.lock`, `Dockerfile`, `test/tools.sh`
- Documents: none. `README.md` (Change a tool) already gives the steps for a mise tool.

## Feasibility

- pv-migrate v3.8.0 (2026-11-15), Apache-2.0, not archived, last push 2026-11-26 (GitHub API, 2026-11-28). The release has `pv-migrate_v3.8.0_linux_x86_64.tar.gz` and `pv-migrate_v3.8.0_linux_arm64.tar.gz`, a `checksums.txt` and GitHub build provenance attestations.
- The mise registry has no short name for pv-migrate, so `mise.toml` names it with the github backend, as it names gh-dash, tuicr and weaver.
- `mise lock github:utkuozdemir/pv-migrate --platform linux-x64,linux-arm64` (mise 2026.11.14) wrote the two platforms with `provenance = "github-attestations"`. The two checksums are equal to the lines of `checksums.txt` of the release.
- `mise install --locked github:utkuozdemir/pv-migrate` with an empty data folder installed it in 1.5 s, and `mise which pv-migrate` named the binary, which printed `pv-migrate version 3.8.0 (commit: 7ba089ec1d0d...)`.
- `bash test/manifests.sh` printed "The copy loop of the Dockerfile names the 28 tools of mise.toml.", and `hadolint Dockerfile test/*.Dockerfile` and `shellcheck test/*.sh` exited 0.
- The Renovate `mise` manager moves the version of `mise.toml` and runs `mise lock` (`README.md`, Change a tool), so a release of pv-migrate needs no other change.

## Existing Tool Considered

pv-migrate is itself the open tool that dan-petty/devops-cli#7498 adopts in place of its own copy code. The image installs it as it installs each other binary tool: mise, from `mise.lock`. The change builds no code of its own and deletes no code.

## Dependencies

None. dan-petty/devops-cli#7498 waits on a release of this image.
