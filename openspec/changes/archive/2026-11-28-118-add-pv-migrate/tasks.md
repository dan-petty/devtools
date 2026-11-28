# Tasks

## 1. Install pv-migrate with mise

Kind: other. Reads: `mise.toml`, `mise.lock`, `Dockerfile`, `test/tools.sh`, `test/manifests.sh`. Changes: `mise.toml`, `mise.lock`, `Dockerfile`, `test/tools.sh`.

- [x] 1.1 Add `"github:utkuozdemir/pv-migrate" = "3.8.0"` to `mise.toml` and run `mise lock github:utkuozdemir/pv-migrate --platform linux-x64,linux-arm64`. Add `pv-migrate` to the copy loop of the `Dockerfile`, and `run pv-migrate --version` after `run promtool --version` in `test/tools.sh`.
  - Verification: `$ bash test/manifests.sh`
